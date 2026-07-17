#!/bin/bash
KSU_BIN=/data/adb/ksud
KSU_MODULES_DIR=/data/adb/modules
SUSFS_BIN=/data/adb/ksu/bin/susfs
PERSISTENT_DIR=/data/adb/brene
DEST_BIN_DIR=/data/adb/ksu/bin

# Hot Install Support
export MODULE_HOT_INSTALL_REQUEST="true"

# Check Compatibility
if [[ -z "${KSU}" ]]; then
	abort '[❌] SuSFS is only for KernelSU or forks!'
fi

if [[ "${ARCH}" != "arm64" ]]; then
	abort '[❌] Only arm64 is supported!'
fi

if [[ "${KSU_KERNEL_VER_CODE}" -ge 32336 ]]; then
	echo "[✅] Detected KernelSU kernel version: ${KSU_KERNEL_VER_CODE}"
else
	abort "[❌] Unsupported KernelSU kernel version: ${KSU_KERNEL_VER_CODE}!"
fi

if [[ ! -d "${DEST_BIN_DIR}" ]]; then
	abort "[❌] '${DEST_BIN_DIR}' not existed, installation aborted!"
fi

cp -f "${MODPATH}/tools/susfs" "${DEST_BIN_DIR}"
chmod +x "${MODPATH}/inotify.sh"
chmod 755 "${DEST_BIN_DIR}/susfs"
ln -f -s "${DEST_BIN_DIR}/susfs" "${DEST_BIN_DIR}/sus" 2> /dev/null || true       # For development
ln -f -s "${DEST_BIN_DIR}/susfs" "${DEST_BIN_DIR}/ksu_susfs" 2> /dev/null || true # For compatibility

# susfs_ver=$(${SUSFS_BIN} show version 2> /dev/null)
# if [[ -n "${susfs_ver}" ]]; then
# 	if [[ "${susfs_ver}" == "v2.0.0" || "${susfs_ver}" == "v2.1.0" ]]; then
# 		abort "[❌] Not supported SuSFS version ${susfs_ver}!"
# 	else
# 		echo "[✅] Detected SuSFS version: ${susfs_ver}"
# 	fi
# else
# 	abort "[❌] Not detected SuSFS version!"
# fi

# Disable other SuSFS modules
[[ -e "${KSU_MODULES_DIR}/susfs4ksu" ]] && {
	touch "${KSU_MODULES_DIR}/susfs4ksu/disable" && echo '[✅] Disabling other SuSFS module'
}
[[ -e "${KSU_MODULES_DIR}/susfs_manager" ]] && {
	touch "${KSU_MODULES_DIR}/susfs_manager/disable" && echo '[✅] Disabling other SuSFS module'
}

echo '[✅] Preparing brene persistent directory (/data/adb/brene)'
mkdir -p "${PERSISTENT_DIR}"

files="
custom_sus_map.txt
custom_sus_mount.txt
custom_sus_path.txt
custom_sus_path_loop.txt
"
for file in ${files}; do
	if [[ ! -f "${PERSISTENT_DIR}/${file}" ]]; then
		touch "${PERSISTENT_DIR}/${file}" && echo "[✅] Added ${file}"
	fi
done

if [[ ! -f "${PERSISTENT_DIR}/config.sh" ]]; then
	cp "${MODPATH}/config.sh" "${PERSISTENT_DIR}" && echo '[✅] Added config.sh'
else
	while IFS='=' read -r key value || [[ -n "${key}" ]]; do

		# Skip empty lines or comments
		[[ -z "${key// /}" || "${key// /}" == "#"* ]] && continue

		if grep -q "^${key}=" "${PERSISTENT_DIR}/config.sh"; then
			:
		else
			echo "${key}=${value}" >> "${PERSISTENT_DIR}/config.sh"
			echo "[➕] Added missing key=value: ${key}=${value}"
		fi

	done < "${MODPATH}/config.sh"
fi

# Uname Spoofing
kernel_version=$(uname -r | cut -d'-' -f1)
android_release=$(${KSU_BIN} boot-info current-kmi | cut -d'-' -f1)
config_uname_kernel_release="${kernel_version}-${android_release}-9-g690101101069"
config_uname_kernel_version="#1 SMP PREEMPT $(resetprop ro.build.date)"
sed -i "s/^config_uname_kernel_release=.*/config_uname_kernel_release='${config_uname_kernel_release}'/" ${PERSISTENT_DIR}/config.sh
sed -i "s/^config_uname_kernel_version=.*/config_uname_kernel_version='${config_uname_kernel_version}'/" ${PERSISTENT_DIR}/config.sh

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
# 	[[ -e "/data/adb/modules/${i}" ]] && touch "/data/adb/modules/${i}/remove"
# done
