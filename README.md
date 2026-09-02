# SuckDryGod Repo

这是一个托管在 GitHub Pages 上的个人 iOS 越狱 APT 软件源，同时支持传统 rootful、现代 rootless 与 rootHide 软件包。

## 添加软件源

软件源地址：

```text
https://suckdrygod.github.io/jailbreak-repo/
```

在已越狱设备上打开上述网页，或把地址粘贴到 Sileo、Zebra、Cydia、Installer 中。

## 发布软件包

1. 构建一个有效的 Debian 软件包（`.deb`）。
2. 把它放进 [`pool`](./pool) 目录。
3. 提交并推送到 `main`。
4. GitHub Actions 会重新生成 `Packages`、压缩索引和 `Release`，随后自动发布。

一个最小的 `control` 文件通常包含：

```text
Package: com.example.package
Name: Example Package
Version: 1.0.0
Architecture: iphoneos-arm64
Description: A short description.
Maintainer: Your Name
Author: Your Name
Section: Tweaks
```

三种目标环境使用不同架构：

- 传统 rootful：`iphoneos-arm`
- 现代 rootless：`iphoneos-arm64`
- rootHide：`iphoneos-arm64e`

软件包内部目录必须已经适配目标越狱环境；本软件源只负责识别和分发，不会自动在 rootful、rootless 与 rootHide 之间转换软件包。同一软件可以把三种构建产物都放进 `pool/`，构建流程会保留多架构条目，客户端再按当前环境筛选。

### rootHide 构建要点

rootHide 版本应使用 [roothide/theos](https://github.com/roothide/theos) 构建，在 Makefile 中加入：

```make
THEOS_PACKAGE_SCHEME = roothide
```

也可以运行 `make package THEOS_PACKAGE_SCHEME=roothide`。在不同 scheme 之间切换前先运行 `make clean`。

rootHide 的 `.deb` 架构应为 `iphoneos-arm64e`，但这不代表每个 Mach-O 都只能编译为 arm64e。不要把普通 rootless 包只改架构名后上传：rootHide 使用随机 jbroot，不能硬编码 `/var/jb` 或某个展开后的 jbroot 路径。源码若要访问越狱文件，应按 [rootHide 开发文档](https://github.com/roothide/Developer) 使用 `jbroot()` 等 API，并确认所有第三方依赖都有 rootHide 兼容版本。

同一软件包若发布新内容，请务必提升 `Version`，不要用相同版本号覆盖旧 `.deb`，否则客户端可能继续使用缓存。

## 目录结构

- `pool/` — `.deb` 软件包
- `depictions/` — 可选的软件包介绍页
- `scripts/build-repo.sh` — APT 索引生成脚本
- `.github/workflows/deploy.yml` — GitHub Pages 自动发布流程
- `index.html` — 软件源首页

请只发布自己制作或已获得再分发许可的软件包。
