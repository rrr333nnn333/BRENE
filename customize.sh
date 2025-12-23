#!/system/bin/sh
KSU_BIN=/data/adb/ksu/bin/ksud
DEST_BIN_DIR=/data/adb/ksu/bin
# PERSISTENT_DIR=/data/adb/susfs4ksu

if [ -z "$KSU" ]; then
	abort '[❌] SUSFS is only for KernelSU or forks!'
fi

if [[ "$KSU_KERNEL_VER_CODE" -ge 20000 ]]; then
	echo "[✅] Detected KernelSU Kernel Version: $KSU_KERNEL_VER_CODE"
else
	abort "[❌] Unsupported KernelSU Kernel Version: $KSU_KERNEL_VER_CODE!"
fi

if [[ "$ARCH" != "arm64" ]]; then
	abort '[❌] Only arm64 is supported!'
fi

if [ ! -d ${DEST_BIN_DIR} ]; then
	rm -rf ${MODPATH}
	abort "[❌] '${DEST_BIN_DIR}' not existed, installation aborted!"
fi

unzip ${ZIPFILE} -d ${TMPDIR}/susfs
cp ${TMPDIR}/susfs/tools/ksu_susfs_arm64 ${DEST_BIN_DIR}/ksu_susfs
chmod 755 ${DEST_BIN_DIR}/ksu_susfs
chmod 644 ${MODPATH}/post-fs-data.sh ${MODPATH}/service.sh ${MODPATH}/uninstall.sh ${MODPATH}/boot-completed.sh

susfsver=$(ksu_susfs show version 2>/dev/null)
if [ -n "$susfsver" ]; then
	echo "[✅] Detected SUSFS Version: $susfsver"
else
	abort "[❌] Not Detected SUSFS Version!"
fi

# Disable other SuSFS modules
if [ -d "/data/adb/modules/susfs4ksu" ]; then
	touch "/data/adb/modules/susfs4ksu/disable"
fi
if [ -d "/data/adb/modules/susfs_manager" ]; then
	touch "/data/adb/modules/susfs_manager/disable"
fi

# echo '[✅] Preparing susfs4ksu persistent directory'
# mkdir -p "$PERSISTENT_DIR"

rm -rf ${MODPATH}/tools
rm -f ${MODPATH}/README.md ${MODPATH}/customize.sh

# reboot

# EOF
