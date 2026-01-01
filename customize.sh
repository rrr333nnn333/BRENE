KSU_BIN=/data/adb/ksu/bin/ksud
DEST_BIN_DIR=/data/adb/ksu/bin
SUSFS_BIN=/data/adb/ksu/bin/ksu_susfs
PERSISTENT_DIR=/data/adb/brene

# Remove outdated/useless modules
modules="
zygisk_shamiko
zygisk-assistant
zygisk-maphide
zygisk_nohello
playintegrity
integritybox
IntegrityBox
Integrity-Box
safetynet-fix
MagiskHidePropsConf
tsupport
tsupport-advance
BetterKnownInstalled
"
for i in ${modules}; do
	[ -d "/data/adb/modules/${i}" ] && touch "/data/adb/modules/${i}/remove"
done

if [ -z ${KSU} ]; then
	abort '[❌] SuSFS is only for KernelSU or forks!'
fi

if [ ${KSU_KERNEL_VER_CODE} -ge 20000 ]; then
	echo "[✅] Detected KernelSU kernel version: ${KSU_KERNEL_VER_CODE}"
else
	abort "[❌] Unsupported KernelSU kernel version: ${KSU_KERNEL_VER_CODE}!"
fi

if [[ ${ARCH} != "arm64" ]]; then
	abort '[❌] Only arm64 is supported!'
fi

if [ ! -d ${DEST_BIN_DIR} ]; then
	rm -rf ${MODPATH}
	abort "[❌] '${DEST_BIN_DIR}' not existed, installation aborted!"
fi

cp -f ${MODPATH}/tools/ksu_susfs ${DEST_BIN_DIR}
cp -f ${MODPATH}/tools/ksu_susfs ${DEST_BIN_DIR}/susfs # For development
chmod 755 ${DEST_BIN_DIR}/susfs
chmod 755 ${DEST_BIN_DIR}/ksu_susfs
chmod 644 ${MODPATH}/post-fs-data.sh ${MODPATH}/service.sh ${MODPATH}/uninstall.sh ${MODPATH}/boot-completed.sh

susfs_ver=$(${SUSFS_BIN} show version 2>/dev/null)
if [ -n ${susfs_ver} ]; then
	echo "[✅] Detected SuSFS version: ${susfs_ver}"
else
	abort "[❌] Not detected SuSFS version!"
fi

# Disable other SuSFS modules
[ -d "/data/adb/modules/susfs4ksu" ] && touch "/data/adb/modules/susfs4ksu/disable" && echo '[✅] Disabling another SuSFS module'
[ -d "/data/adb/modules/susfs_manager" ] && touch "/data/adb/modules/susfs_manager/disable" && echo '[✅] Disabling another SuSFS module'

echo '[✅] Preparing brene persistent directory'
mkdir -p "${PERSISTENT_DIR}"
[ ! -f ${PERSISTENT_DIR}/config.sh ] && cp ${MODPATH}/config.sh ${PERSISTENT_DIR}

# EOF
