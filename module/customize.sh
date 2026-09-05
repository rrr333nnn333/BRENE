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
ln -sf "${DEST_BIN_DIR}/susfs" "${DEST_BIN_DIR}/sus"       # For development
ln -sf "${DEST_BIN_DIR}/susfs" "${DEST_BIN_DIR}/ksu_susfs" # For compatibility

susfs_version=$(${SUSFS_BIN} show version)
if [[ "${susfs_version}" == "v2"* ]]; then
	echo "[✅] Detected SuSFS version: ${susfs_version}"
else
	abort "[❌] Not supported SuSFS version ${susfs_version}!"
fi

# Reset module description
susfs_variant=$(${SUSFS_BIN} show variant)
susfs_features_number=$(${SUSFS_BIN} show enabled_features | wc -l)
description="A SuSFS/KernelSU module for SuSFS patched kernels"
status="Waiting for reboot ⏱️"
${KSU_BIN} module config set override.description "[Status: ${status} | SuSFS: ${susfs_version} (${susfs_variant}) | SuSFS Features: ${susfs_features_number} enabled] ${description}"

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
custom_kernel_umount.txt
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

# Remove fake_files folder
[[ -d "${PERSISTENT_DIR}/fake_files" ]] && rm -rf "${PERSISTENT_DIR}/fake_files"

# zygisk_shamiko
# zygisk-assistant
# zygisk-maphide
# zygisk_nohello
# safetynet-fix
# MagiskHidePropsConf
# tsupport
# tsupport-advance
# BetterKnownInstalled

# Drop useless modules
modules="
ReSuSFS
"
for module in ${modules}; do
	[[ -e "/data/adb/modules/${module}" ]] && touch "/data/adb/modules/${module}/remove"
done

if [[ -e "/data/adb/modules/playintegrityfix" ]] && grep -q "Integrity-Box" "/data/adb/modules/playintegrityfix/module.prop"; then
	touch "/data/adb/modules/playintegrityfix/remove"
fi

# Enable WebUI without reboot
MODDIR="/data/adb/modules/brene"
MODULES_PATH="/data/adb/modules"

rm -rf "${MODDIR}"
cp -rp "${MODPATH}" "${MODULES_PATH}"

(
	sleep 3
	rm -rf "${MODPATH}"
	rm "${MODDIR}/update"
) & # fork in background

echo '[✅] WebUI is ready!'
