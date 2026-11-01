#!/bin/bash
# shellcheck disable=SC2154
KSU_BIN=/data/adb/ksud
KSU_MODULES_DIR=/data/adb/modules
SUSFS_BIN=/data/adb/ksu/bin/susfs
PERSISTENT_DIR=/data/adb/brene
DEST_BIN_DIR=/data/adb/ksu/bin

# Load utils
[[ -e "${MODPATH}/utils.sh" ]] && source "${MODPATH}/utils.sh"

echo ""
echo "██████╗ ██████╗ ███████╗███╗   ██╗███████╗"
echo "██╔══██╗██╔══██╗██╔════╝████╗  ██║██╔════╝"
echo "██████╔╝██████╔╝█████╗  ██╔██╗ ██║█████╗  "
echo "██╔══██╗██╔══██╗██╔══╝  ██║╚██╗██║██╔══╝  "
echo "██████╔╝██║  ██║███████╗██║ ╚████║███████╗"
echo "╚═════╝ ╚═╝  ╚═╝╚══════╝╚═╝  ╚═══╝╚══════╝"
echo ""

# Check Compatibility
if [[ -z "${KSU}" ]]; then
	abort '[❌] SuSFS is only for KernelSU or forks!'
fi

if [[ "${ARCH}" != "arm64" ]]; then
	abort '[❌] Only arm64 is supported!'
fi

# if [[ "${KSU_KERNEL_VER_CODE}" -ge 32336 ]]; then
# 	echo "[✅] Detected KernelSU kernel version: ${KSU_KERNEL_VER_CODE}"
# else
# 	abort "[❌] Unsupported KernelSU kernel version: ${KSU_KERNEL_VER_CODE}!"
# fi

if [[ ! -d "${DEST_BIN_DIR}" ]]; then
	abort "[❌] '${DEST_BIN_DIR}' not existed, installation aborted!"
fi

cp -f "${MODPATH}/tools/susfs" "${DEST_BIN_DIR}"
chmod +x "${MODPATH}/inotify.sh"
chmod +x "${MODPATH}/remove_ksu_directory.sh"
chmod 755 "${DEST_BIN_DIR}/susfs"
ln -sf "${DEST_BIN_DIR}/susfs" "${DEST_BIN_DIR}/sus"       # For development
ln -sf "${DEST_BIN_DIR}/susfs" "${DEST_BIN_DIR}/ksu_susfs" # For compatibility

susfs_version=$(${SUSFS_BIN} show version)
if [[ "${susfs_version}" == "v2.4.0" || "${susfs_version}" == "v2.3.0" || "${susfs_version}" == "v2.2.0" ]]; then
	echo "[✅] Detected SuSFS version: ${susfs_version}"
else
	abort "[❌] Not supported SuSFS version ${susfs_version}!"
fi

# Reset module description
susfs_total_features=10
susfs_variant=$(${SUSFS_BIN} show variant)
susfs_features_number=$(${SUSFS_BIN} show enabled_features | wc -l)
kernel_version=$(cat /proc/version | awk '{print $3}' | grep -oE '^[0-9]+\.[0-9]+\.[0-9]+')
description="KernelSU module with SuSFS support and more"
status="Waiting for reboot ⏱️"
${KSU_BIN} module config set override.description "[Status: ${status} | Kernel Version: ${kernel_version} | SuSFS: ${susfs_version} (${susfs_variant}) | SuSFS Kernel Features: ${susfs_features_number}/${susfs_total_features} enabled] ${description}"

# Disable other SuSFS modules
[[ -e "${KSU_MODULES_DIR}/susfs4ksu" ]] && {
	touch "${KSU_MODULES_DIR}/susfs4ksu/disable" && echo '[✅] Disabling other SuSFS module'
}
[[ -e "${KSU_MODULES_DIR}/susfs_manager" ]] && {
	touch "${KSU_MODULES_DIR}/susfs_manager/disable" && echo '[✅] Disabling other SuSFS module'
}
[[ -e "${KSU_MODULES_DIR}/ReSuSFS" ]] && {
	touch "${KSU_MODULES_DIR}/ReSuSFS/disable" && echo '[✅] Disabling other SuSFS module'
}

echo "[✅] Preparing brene persistent directory (${PERSISTENT_DIR})"
mkdir -p "${PERSISTENT_DIR}"

# Backup SuSFS binary
cp -pf "${DEST_BIN_DIR}/susfs" "${PERSISTENT_DIR}"

files="
custom_sus_map.txt
custom_kernel_umount.txt
custom_sus_path.txt
custom_sus_path_loop.txt
custom_open_redirect.txt
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

update_config_date

# Reset fake_files folder
[[ -d "${PERSISTENT_DIR}/fake_files" ]] && rm -rf "${PERSISTENT_DIR}/fake_files"
mkdir -p "${PERSISTENT_DIR}/fake_files"

# Hot install support
if [[ "${KSU_HAS_HOT_INSTALL}" == true ]]; then
	export MODULE_HOT_INSTALL_REQUEST=true
fi
