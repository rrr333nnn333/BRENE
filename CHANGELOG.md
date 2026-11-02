# Changelog

# Supports SuSFS 2.2.0, 2.3.0 and 2.3.0+

- add: webui: "Check Play Integrity API" button
- add: new incompatible modules (Integrity Box, mountify)
- add: new incompatible modules (fgetpriority, Tricky Store OSS, Oh My Keymint, Yurikey Manager, ZNNext)
- add: SuSFS variant to module description
- improve: webui: move "Check Play Integrity API" button to HOME section
- add: webui: Material Files to Recommendations
- improve: update susfs_total_features value to 10 (CONFIG_KSU_SUSFS_PRIORITY_UID_FILTER)
- improve: webui: Check PI API: use "cmd activity" instead of "am" and use force-stop ${PKG} before start ${PKG}/.MainActivity
- improve: webui: use "cmd activity" instead of "am" for all code
- improve: webui: add Advanced separator
- improve: remove Termux and BakaSU/ReSukiSU app external directory
- improve: remove SukiSU Ultra app external directory
- improve: move update_config_date function call atfer /storage/emulated/0/Android is accessible
- drop: Spoof UTC/date/fingerprint properties
