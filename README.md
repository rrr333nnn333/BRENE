# BRENE - A SuSFS/KernelSU module for SuSFS patched kernels

This module is used for installing a userspace helper tool called ksu_susfs and susfs (They are the same binary) into /data/adb/ksu/bin/ to communicate with SUSFS kernel.

More information soon.

## Supported Versions

- `KernelSU` v3.0.0+
- `susfs4ksu` v2.0.0+

## Hiding Features

- Hide All Items in `/data/local/tmp`
- Hide All Items in `/sdcard/Android/data`
- Hide Folders of `Rooted Apps`
- Hide Folders of `Custom Recovery`
- Hide some traces caused by some `Custom Kernels`
- Hide some map traces caused by `Font Modules`
- Hide some map traces caused by `Zygisk Modules`
- Hide Suspicious Mounts For Non Su Processes

## Spoofing Features
- Spoof some `Android System Properties`

- Spoof the sus `'su'` tcontext shown in avc log
<!-- - Hide the exposed /proc interface of ext4 loop and jdb2 when mounting `modules.img` -->

## Credits

- [`Magisk`](https://github.com/topjohnwu/Magisk)
- [`KernelSU`](https://github.com/tiann/KernelSU)
- [`susfs4ksu`](https://gitlab.com/simonpunk/susfs4ksu)
- [`susfs4ksu-module`](https://github.com/sidex15/susfs4ksu-module)
- [`KOWX712`](https://github.com/KOWX712)
