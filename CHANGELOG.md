# Changelog

# Supports SUSFS 2.2.0, 2.3.0, 2.4.0 and 2.4.0+ (2.5.0?)

- add: webui: "Zygisk Next, NeoZygisk, NyaZygisk, OnyxZygisk, YukiZygisk" (Incompatible/Untested modules)
- drop: persist.logd.size prop
- add: webui: "LSPosed, ReLSPosed, LSPosed-Irena" (Incompatible/Untested modules)
- improve: update susfs binary to support the new feature "sus_path_uid_filter"
- improve: replace strings "SuSFS" with "SUSFS"
- add: webui: sus_path_uid_filter support
- add: new toggle "Hide OEM unlocking toggle"
- add: new toggle "Hide Vector Injection (Xposed Framework)"
- add: new toggle "Hide all apps with uid >= 10000"
- improve: spoof ro.build.fingerprint prop to remove detection vectors
