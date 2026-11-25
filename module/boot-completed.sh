#!/bin/bash
# shellcheck disable=SC2154
MODDIR=${0%/*}
KSU_BIN=/data/adb/ksud
KSU_MODULES_DIR=/data/adb/modules
SUSFS_BIN=/data/adb/ksu/bin/susfs
PERSISTENT_DIR=/data/adb/brene
DEST_BIN_DIR=/data/adb/ksu/bin
CUSTOM_ROM_NAMES="lineage|infinity|evolution|crdroid|mistos|axion|pixelos|rising|lunaris|halcyon|havoc|alphadroid|bliss|calyx|derpfest|graphene|lmodroid|lumine|matrixx|clover|yaap|aospa"

# Load utils
[[ -e "${MODDIR}/utils.sh" ]] && source "${MODDIR}/utils.sh"
# Load config
[[ -e "${PERSISTENT_DIR}/config.sh" ]] && source "${PERSISTENT_DIR}/config.sh"

# Update Description
susfs_total_features=10
susfs_variant=$(${SUSFS_BIN} show variant)
susfs_version=$(${SUSFS_BIN} show version)
susfs_features_number=$(${SUSFS_BIN} show enabled_features | wc -l)
kernel_version=$(cat /proc/version | awk '{print $3}' | grep -oE '^[0-9]+\.[0-9]+\.[0-9]+')
description="KernelSU module with SUSFS support and more"
if [[ "${susfs_version}" == "v2"* ]]; then
	status="Active ✅"
	${KSU_BIN} module config set override.description "[Status: ${status} | Kernel Version: ${kernel_version} | SUSFS: ${susfs_version} (${susfs_variant}) | SUSFS Kernel Features: ${susfs_features_number}/${susfs_total_features} enabled] ${description}"
else
	status="Not Working ❌"
	${KSU_BIN} module config set override.description "[Status: ${status} | Kernel Version: ${kernel_version} | SUSFS: ${susfs_version} (${susfs_variant}) | SUSFS Kernel Features: ${susfs_features_number}/${susfs_total_features} enabled] ${description}"
fi

# SU Compat
if [[ "${config_su_compat}" == "1" ]]; then
	${KSU_BIN} feature set su_compat 1
elif [[ "${config_su_compat}" == "0" ]]; then
	${KSU_BIN} feature set su_compat 0
fi

# Kernel Umount
if [[ "${config_kernel_umount}" == "1" ]]; then
	${KSU_BIN} feature set kernel_umount 1
elif [[ "${config_kernel_umount}" == "0" ]]; then
	${KSU_BIN} feature set kernel_umount 0
fi

# Hide SELinux modification
if [[ "${config_selinux_hide}" == "1" ]]; then
	${KSU_BIN} feature set selinux_hide 1
elif [[ "${config_selinux_hide}" == "0" ]]; then
	${KSU_BIN} feature set selinux_hide 0
fi

${KSU_BIN} feature save

# Developer Options
if [[ "${config_developer_options}" == "1" ]]; then
	settings put global development_settings_enabled 1
elif [[ "${config_developer_options}" == "0" ]]; then
	settings put global development_settings_enabled 0
fi

# USB Debugging
if [[ "${config_usb_debugging}" == "1" ]]; then
	settings put global adb_enabled 1
elif [[ "${config_usb_debugging}" == "0" ]]; then
	settings put global adb_enabled 0
fi

# Wireless Debugging
if [[ "${config_wireless_debugging}" == "1" ]]; then
	settings put global adb_wifi_enabled 1
elif [[ "${config_wireless_debugging}" == "0" ]]; then
	settings put global adb_wifi_enabled 0
fi

# Disable Child Process Restrictions
if [[ "${config_disable_child_process_restrictions}" == "1" ]]; then
	resetprop -n persist.sys.fflag.override.settings_enable_monitor_phantom_procs false
fi

# Max Saturation
if [[ "${config_saturation}" == "1" ]]; then
	service call SurfaceFlinger 1022 f 2.0
fi

# Show Refresh Rate
if [[ "${config_show_refresh_rate}" == "1" ]]; then
	service call SurfaceFlinger 1034 i32 1
fi

# Set logcat buffer to 64KiB
if [[ "${config_shrink_buffer_size}" == "1" ]]; then
	logcat -G 64K
fi

# Hide OEM unlocking toggle
if [[ "${config_hide_oem_unlocking_toggle}" == "1" ]]; then
	if_prop_exits_resetprop_n "ro.oem_unlock_supported" "0"
fi

# Hide Vector Injection (Xposed Framework)
if [[ "${config_hide_vector_injection}" == "1" ]]; then
	brene_sus_map "/data/adb/modules/zygisk_vector/zygisk/arm64-v8a.so"
	brene_sus_map "/data/adb/modules/zygisk_vector/zygisk/armeabi-v7a.so"
fi

# Spoof /system/lib64/libstagefright.so
if [[ "${config_spoof_libstagefright}" == "1" ]]; then
	path=/system/lib64/libstagefright.so
	file_name=$(basename "${path}")
	fake_file_path="${PERSISTENT_DIR}/fake_files/${file_name}"

	[[ ! -f "${fake_file_path}" ]] && {
		touch "${fake_file_path}"
	}

	brene_open_redirect "${path}" "${fake_file_path}" '3'
fi

# Hide LineageOS Strings
if [[ "${config_hide_lineage_strings}" == "1" ]]; then
	find /system /system_ext /vendor /product \( -iname "*sepolicy.cil" -o -iname "*file_contexts" \) | while read -r path; do
		file_name=$(basename "${path}")
		fake_file_path="${PERSISTENT_DIR}/fake_files/${file_name}"

		[[ ! -f "${fake_file_path}" ]] && {
			touch "${fake_file_path}"
		}

		brene_open_redirect "${path}" "${fake_file_path}" '3'
	done

	find /system /system_ext /vendor /product -iname "*.rc" | while read -r path; do
		if grep -iq "lineage" "${path}"; then
			file_name=$(basename "${path}")
			fake_file_path="${PERSISTENT_DIR}/fake_files/${file_name}"

			[[ ! -f "${fake_file_path}" ]] && {
				touch "${fake_file_path}"
			}

			brene_open_redirect "${path}" "${fake_file_path}" '3'
		fi
	done

	path=/system_ext/etc/permissions/Updater.xml
	file_name=$(basename "${path}")
	fake_file_path="${PERSISTENT_DIR}/fake_files/${file_name}"
	[[ ! -f "${fake_file_path}" ]] && touch "${fake_file_path}"
	brene_open_redirect "${path}" "${fake_file_path}" '3'
fi

# Run post-boot stage
sh "${MODDIR}/post-boot.sh" &

if [[ "${config_brene_logs}" == "1" ]]; then
	echo "✅ boot-completed.sh" >> "${PERSISTENT_DIR}/log.txt"
fi
