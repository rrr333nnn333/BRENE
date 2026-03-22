KSU_BIN=/data/adb/ksu/bin/ksud
DEST_BIN_DIR=/data/adb/ksu/bin
SUSFS_BIN=/data/adb/ksu/bin/susfs
PERSISTENT_DIR=/data/adb/brene

# Disable outdated modules
# echo "[✅] Disabling outdated modules"
# modules="
# zygisk_shamiko
# zygisk-assistant
# zygisk-maphide
# zygisk_nohello
# playintegrity
# integritybox
# IntegrityBox
# Integrity-Box
# safetynet-fix
# MagiskHidePropsConf
# tsupport
# tsupport-advance
# BetterKnownInstalled
# "
# for i in ${modules}; do
# 	[ -d "/data/adb/modules/${i}" ] && touch "/data/adb/modules/${i}/remove"
# done

if [ -z ${KSU} ]; then
	abort '[❌] SuSFS is only for KernelSU or forks!'
fi

if [ ${KSU_KERNEL_VER_CODE} -ge 32336 ]; then
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

cp -f ${MODPATH}/tools/susfs ${DEST_BIN_DIR}
chmod 755 ${DEST_BIN_DIR}/susfs
chmod 644 ${MODPATH}/post-fs-data.sh ${MODPATH}/service.sh ${MODPATH}/uninstall.sh ${MODPATH}/boot-completed.sh
ln -f -s ${DEST_BIN_DIR}/susfs ${DEST_BIN_DIR}/sus # For development

susfs_ver=$(${SUSFS_BIN} show version 2>/dev/null)
if [ -n ${susfs_ver} ]; then
	echo "[✅] Detected SuSFS version: ${susfs_ver}"
else
	abort "[❌] Not detected SuSFS version!"
fi

# Disable other SuSFS modules
[ -d "/data/adb/modules/susfs4ksu" ] && touch "/data/adb/modules/susfs4ksu/disable" && echo '[✅] Disabling another SuSFS module'
[ -d "/data/adb/modules/susfs_manager" ] && touch "/data/adb/modules/susfs_manager/disable" && echo '[✅] Disabling another SuSFS module'

echo '[✅] Preparing brene persistent directory, the path is /data/adb/brene'
mkdir -p "${PERSISTENT_DIR}"

[ ! -f ${PERSISTENT_DIR}/custom_sus_map.txt ] && cp ${MODPATH}/custom_sus_map.txt ${PERSISTENT_DIR} && echo '[✅] Added custom_sus_map.txt'
[ ! -f ${PERSISTENT_DIR}/custom_sus_path.txt ] && cp ${MODPATH}/custom_sus_path.txt ${PERSISTENT_DIR} && echo '[✅] Added custom_sus_path.txt'
[ ! -f ${PERSISTENT_DIR}/custom_sus_path_loop.txt ] && cp ${MODPATH}/custom_sus_path_loop.txt ${PERSISTENT_DIR} && echo '[✅] Added custom_sus_path_loop.txt'

if [ ! -f ${PERSISTENT_DIR}/config.sh ]; then
	cp ${MODPATH}/config.sh ${PERSISTENT_DIR} && echo '[✅] Added config.sh'
else
	while IFS='=' read -r key value; do

		grep -q "^${key}=" ${PERSISTENT_DIR}/config.sh || echo "${key}=${value}" >> ${PERSISTENT_DIR}/config.sh

	done < ${MODPATH}/config.sh
fi


# Uname Spoofing
kernel_version=$(uname -r | cut -d'-' -f1)
android_release=$(${KSU_BIN} boot-info current-kmi | cut -d'-' -f1)
config_uname_kernel_release="${kernel_version}-${android_release}-9-g690101101069"
config_uname_kernel_version="#1 SMP PREEMPT $(resetprop ro.build.date)"
sed -i "s/^config_uname_kernel_release=.*/config_uname_kernel_release='${config_uname_kernel_release}'/" ${PERSISTENT_DIR}/config.sh
sed -i "s/^config_uname_kernel_version=.*/config_uname_kernel_version='${config_uname_kernel_version}'/" ${PERSISTENT_DIR}/config.sh

# EOF
