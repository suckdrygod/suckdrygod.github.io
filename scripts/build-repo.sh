#!/usr/bin/env bash
set -euo pipefail
export LC_ALL=C
umask 022

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SITE_DIR="${ROOT_DIR}/_site"
REPO_NAME="${REPO_NAME:-SuckDryGod Repo}"
REPO_ORIGIN="${REPO_ORIGIN:-SuckDryGod}"
REPO_DESCRIPTION="${REPO_DESCRIPTION:-A personal iOS jailbreak package repository.}"

if [[ -z "${ROOT_DIR}" || "${SITE_DIR}" != "${ROOT_DIR}/_site" ]]; then
  echo "Refusing to build with an unexpected output path." >&2
  exit 1
fi

rm -rf "${SITE_DIR}"
mkdir -p "${SITE_DIR}/pool" "${SITE_DIR}/depictions"

cp "${ROOT_DIR}/index.html" "${SITE_DIR}/index.html"
cp "${ROOT_DIR}/index.html" "${SITE_DIR}/404.html"
cp "${ROOT_DIR}/.nojekyll" "${SITE_DIR}/.nojekyll"
cp "${ROOT_DIR}/CydiaIcon.png" "${SITE_DIR}/CydiaIcon.png"
cp -R "${ROOT_DIR}/assets" "${SITE_DIR}/assets"

if [[ -d "${ROOT_DIR}/depictions" ]]; then
  cp -R "${ROOT_DIR}/depictions/." "${SITE_DIR}/depictions/"
  rm -f "${SITE_DIR}/depictions/.gitkeep"
fi

shopt -s nullglob
deb_files=("${ROOT_DIR}"/pool/*.deb)
if (( ${#deb_files[@]} > 0 )); then
  cp "${deb_files[@]}" "${SITE_DIR}/pool/"
  (
    cd "${SITE_DIR}"
    dpkg-scanpackages --multiversion pool /dev/null
  ) > "${SITE_DIR}/Packages"
else
  : > "${SITE_DIR}/Packages"
fi

gzip -n -9 -c "${SITE_DIR}/Packages" > "${SITE_DIR}/Packages.gz"
bzip2 -9 -c "${SITE_DIR}/Packages" > "${SITE_DIR}/Packages.bz2"
xz -9e -c "${SITE_DIR}/Packages" > "${SITE_DIR}/Packages.xz"

cmp -s "${SITE_DIR}/Packages" <(gzip -dc "${SITE_DIR}/Packages.gz")
cmp -s "${SITE_DIR}/Packages" <(bzip2 -dc "${SITE_DIR}/Packages.bz2")
cmp -s "${SITE_DIR}/Packages" <(xz -dc "${SITE_DIR}/Packages.xz")

release_body="$(mktemp)"
trap 'rm -f "${release_body}"' EXIT
(
  cd "${SITE_DIR}"
  apt-ftparchive \
    -o "APT::FTPArchive::Release::Origin=${REPO_ORIGIN}" \
    -o "APT::FTPArchive::Release::Label=${REPO_NAME}" \
    -o "APT::FTPArchive::Release::Suite=stable" \
    -o "APT::FTPArchive::Release::Version=1.0" \
    -o "APT::FTPArchive::Release::Codename=ios" \
    -o "APT::FTPArchive::Release::Architectures=iphoneos-arm iphoneos-arm64 iphoneos-arm64e" \
    -o "APT::FTPArchive::Release::Components=main" \
    -o "APT::FTPArchive::Release::Description=${REPO_DESCRIPTION}" \
    release .
) > "${release_body}"
mv "${release_body}" "${SITE_DIR}/Release"
trap - EXIT

echo "Repository built at ${SITE_DIR}"
