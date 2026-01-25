# BRENE - A SuSFS/KernelSU module for SuSFS patched kernels

More information soon.

## Supported Versions

- `KernelSU` v3.0.0+
- `susfs4ksu` v2.0.0+

## Features

- Hide all paths in `/data/local/tmp`
- Hide all leaking app paths in `/sdcard/Android/data`
- Hide some folder paths of `Rooted Apps`
- Hide some folder paths of `Custom Recoveries`
- Hide some traces caused by some `Custom Kernels`
- Hide some map traces caused by some `Font Modules`
- Hide some map traces caused by some `Zygisk Modules`
- Spoof some `Android System Properties`
- Spoof the sus `'su'` tcontext shown in avc log
<!-- - Hide the exposed /proc interface of ext4 loop and jdb2 when mounting `modules.img` -->

## Tip

- Kernel umount must be enabled

## Credits

- [`Magisk`](https://github.com/topjohnwu/Magisk)
- [`KernelSU`](https://github.com/tiann/KernelSU)
- [`susfs4ksu`](https://gitlab.com/simonpunk/susfs4ksu)
- [`susfs4ksu-module`](https://github.com/sidex15/susfs4ksu-module)
- [`KOWX712`](https://github.com/KOWX712)
