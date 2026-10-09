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

update_config_date

# Update Description
susfs_total_features=9
susfs_version=$(${SUSFS_BIN} show version)
susfs_features_number=$(${SUSFS_BIN} show enabled_features | wc -l)
kernel_version=$(cat /proc/version | awk '{print $3}' | grep -oE '^[0-9]+\.[0-9]+\.[0-9]+')
description="A SuSFS/KernelSU module for SuSFS patched kernels"
if [[ "${susfs_version}" == "v2"* ]]; then
	status="Active ✅"
	${KSU_BIN} module config set override.description "[Status: ${status} | Kernel Version: ${kernel_version} | SuSFS: ${susfs_version} | SuSFS Kernel Features: ${susfs_features_number}/${susfs_total_features} enabled] ${description}"
else
	status="Not Working ❌"
	${KSU_BIN} module config set override.description "[Status: ${status} | Kernel Version: ${kernel_version} | SuSFS: ${susfs_version} | SuSFS Kernel Features: ${susfs_features_number}/${susfs_total_features} enabled] ${description}"
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
	resetprop_n persist.sys.fflag.override.settings_enable_monitor_phantom_procs false
fi

# Max Saturation
if [[ "${config_saturation}" == "1" ]]; then
	service call SurfaceFlinger 1022 f 2.0
fi

# Show Refresh Rate
if [[ "${config_show_refresh_rate}" == "1" ]]; then
	service call SurfaceFlinger 1034 i32 1
fi

# SELinux Enforcing
if [[ "${config_selinux}" == "1" ]]; then
	[[ "$(getenforce)" != "Enforcing" ]] && setenforce 1
fi

# Remove Custom ROM Properties
if [[ "${config_rom_props}" == "1" ]]; then
	resetprop | grep -iE "${CUSTOM_ROM_NAMES}" | awk -F'[][]' '{print $2}' | while read -r prop; do
		resetprop -d "${prop}"
	done

	resetprop -d "ro.modversion"
fi

# Remove Play Integrity Fix Properties
if [[ "${config_pif_props}" == "1" ]]; then
	resetprop | grep -iE "pihook|pixelprops|spoof" | awk -F'[][]' '{print $2}' | while read -r prop; do
		resetprop -d -p "${prop}"
	done
fi

# Spoof /system/lib64/libstagefright.so
if [[ "${config_spoof_libstagefright}" == "1" ]]; then
	path=/system/lib64/libstagefright.so
	file_name=$(basename "${path}")
	fake_file_path="${PERSISTENT_DIR}/fake_files/${file_name}"

	[[ ! -d "${PERSISTENT_DIR}/fake_files" ]] && mkdir -p "${PERSISTENT_DIR}/fake_files"
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

		[[ ! -d "${PERSISTENT_DIR}/fake_files" ]] && mkdir -p "${PERSISTENT_DIR}/fake_files"
		[[ ! -f "${fake_file_path}" ]] && {
			touch "${fake_file_path}"
		}

		brene_open_redirect "${path}" "${fake_file_path}" '3'
	done

	find /system /system_ext /vendor /product -iname "*.rc" | while read -r path; do
		if grep -iq "lineage" "${path}"; then
			file_name=$(basename "${path}")
			fake_file_path="${PERSISTENT_DIR}/fake_files/${file_name}"

			[[ ! -d "${PERSISTENT_DIR}/fake_files" ]] && mkdir -p "${PERSISTENT_DIR}/fake_files"
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

#### Hide some sus paths, effective only for processes that are marked umounted with uid >= 10000 ####
## First we need to wait until files are accessible in /storage/emulated/0/Android ##
until [[ -e "/storage/emulated/0/Android" ]]; do sleep 1; done

## System Property Spoofing
# Spoof System Properties
if [[ "${config_spoof_system_properties}" == "1" ]]; then
	spoof_system_properties

	# set after vold settles so the encrypted transition still reaches vendor init triggers
	if_prop_exits_resetprop_n "ro.crypto.state" "encrypted"
fi
# Spoof Fingerprint Properties
if [[ "${config_spoof_fingerprint_properties}" == "1" ]]; then
	spoof_fingerprint_properties
fi
# Spoof UTC Properties
if [[ "${config_spoof_utc_properties}" == "1" ]]; then
	spoof_utc_properties
fi
# Spoof Date Properties
if [[ "${config_spoof_date_properties}" == "1" ]]; then
	spoof_date_properties
fi
# Spoof OS Security Patch Level Property
if [[ "${config_spoof_os_security_patch_level_property}" == "1" ]]; then
	spoof_os_security_patch_level_property
fi
# Spoof Vendor Security Patch Level Property
if [[ "${config_spoof_vendor_security_patch_level_property}" == "1" ]]; then
	spoof_vendor_security_patch_level_property
fi
# Spoof System Properties Every Minute
if [[ "${config_spoof_system_properties_repeat}" == "1" ]]; then
	while true; do
		sleep 60
		spoof_system_properties
	done &
fi

## Remove the '..5.u.S' leftover ##
## THe reason why this sus file is created is because users have grant the MANAGE_EXTERNAL_STORAGE permission for the apps that detecting sus files in /storage/emulated/0, or in /storage/emulated/0/Android/data where the apps are exploiting the unicode bugs to create files arbitrary.
## susfs redirects the sus path to a supposed not-existing path named '..5.u.S', and this is the only way to settle the cross check of returned errno from various syscalls, but one disadvantage is that if the path itself can be written/created by the app (MANAGE_EXTERNAL_STORAGE granted), then it is futile to hide it, but at least here we automatically delete them on each boot.
## The best practise is to revoke MANAGE_EXTERNAL_STORAGE permission for all third party apps.
# [ -e "/storage/emulated/0/..5.u.S" ] && rm -rf "/storage/emulated/0/..5.u.S"
# [ -e "/storage/emulated/0/Android/data/..5.u.S" ] && rm -rf "/storage/emulated/0/Android/data/..5.u.S"
# [ -e "/storage/emulated/0/Android/media/..5.u.S" ] && rm -rf "/storage/emulated/0/Android/media/..5.u.S"

# Remove "..5.u.S"
TARGET="..5.u.S"
TARGET1="/storage/emulated/0/${TARGET}"
TARGET2="/storage/emulated/0/Android/data/${TARGET}"
TARGET3="/storage/emulated/0/Android/media/${TARGET}"
TARGET4="/storage/emulated/0/Android/obb/${TARGET}"
rm -rf "${TARGET1}" "${TARGET2}" "${TARGET3}" "${TARGET4}"
inotifyd "${MODDIR}/inotify.sh" /storage/emulated/0:n &

## For paths that are frequently modified, we can add them via 'add_sus_path_loop' ##
## Be reminded that without HMA's vold app data enabled, added sus_paths are still vulnerable to zwc exploit, so in this case users also have to add its underlying path as well ##

# Paths Hiding

# Hide Custom Recovery Paths
if [[ "${config_hide_custom_recovery}" == "1" ]]; then
	if [[ "${config_brene_logs}" == "1" ]]; then
		{
			echo ""
			echo "##########################"
			echo "Hide Custom Recovery Paths"
			echo "##########################"
		} >> "${PERSISTENT_DIR}/logs.txt"
	fi

	[[ -e "/storage/emulated/0/Fox" ]] && brene_sus_path_loop "/storage/emulated/0/Fox"
	[[ -e "/storage/emulated/0/TWRP" ]] && brene_sus_path_loop "/storage/emulated/0/TWRP"
	[[ -e "/data/recovery" ]] && brene_sus_path_loop "/data/recovery"
	[[ -e "/vendor/bin/install-recovery.sh" ]] && brene_sus_path_loop "/vendor/bin/install-recovery.sh"
	[[ -e "/system/bin/install-recovery.sh" ]] && brene_sus_path_loop "/system/bin/install-recovery.sh"
fi

# Non-standard /storage/emulated/0
if [[ "${config_paths_hiding__non_standard_sdcard}" == "1" ]]; then
	if [[ "${config_brene_logs}" == "1" ]]; then
		{
			echo ""
			echo "####################"
			echo "Non-standard /storage/emulated/0"
			echo "####################"
		} >> "${PERSISTENT_DIR}/logs.txt"
	fi

	if [[ -z "$(resetprop ro.miui.ui.version.name)" ]]; then
		standard_paths="Alarms Android Audiobooks DCIM Documents Download Movies Music Notifications Pictures Podcasts Recordings Ringtones"
	else
		standard_paths="Alarms Android Audiobooks DCIM Documents Download Movies Music Notifications Pictures Podcasts Recordings Ringtones MIUI"
	fi

	for i in /storage/emulated/0/*; do
		pass=0
		for x in ${standard_paths}; do
			if [[ "/storage/emulated/0/${x}" == "${i}" ]]; then
				pass=1
				break
			fi
		done

		[[ "${pass}" == "1" ]] && continue

		brene_sus_path_loop "${i}"
	done
fi

# Non-standard /storage/emulated/0/Android
if [[ "${config_paths_hiding__non_standard_sdcard_android}" == "1" ]]; then
	if [[ "${config_brene_logs}" == "1" ]]; then
		{
			echo ""
			echo "############################"
			echo "Non-standard /storage/emulated/0/Android"
			echo "############################"
		} >> "${PERSISTENT_DIR}/logs.txt"
	fi

	standard_paths="data media obb"
	for i in /storage/emulated/0/Android/*; do
		pass=0
		for x in ${standard_paths}; do
			if [[ "/storage/emulated/0/Android/${x}" == "${i}" ]]; then
				pass=1
				break
			fi
		done

		[[ "${pass}" == "1" ]] && continue

		brene_sus_path_loop "${i}"
	done
fi

# /data/local/tmp
if [[ "${config_paths_hiding__data_local_tmp}" == "1" ]]; then
	if [[ "${config_brene_logs}" == "1" ]]; then
		{
			echo ""
			echo "###############"
			echo "/data/local/tmp"
			echo "###############"
		} >> "${PERSISTENT_DIR}/logs.txt"
	fi

	for i in /data/local/tmp/*; do
		brene_sus_path_loop "${i}"
	done
fi

# Load custom_sus_map.txt
if [[ -e "${PERSISTENT_DIR}/custom_sus_map.txt" ]]; then
	while IFS= read -r i; do
		# Skip empty lines or comments
		[[ -z "${i// /}" || "${i// /}" == "#"* ]] && continue

		brene_sus_map "${i}"
	done < "${PERSISTENT_DIR}/custom_sus_map.txt"
fi

# Load custom_sus_path.txt
if [[ -e "${PERSISTENT_DIR}/custom_sus_path.txt" ]]; then
	while IFS= read -r i; do
		# Skip empty lines or comments
		[[ -z "${i// /}" || "${i// /}" == "#"* ]] && continue

		brene_sus_path "${i}"
	done < "${PERSISTENT_DIR}/custom_sus_path.txt"
fi

# Load custom_sus_path_loop.txt
if [[ -e "${PERSISTENT_DIR}/custom_sus_path_loop.txt" ]]; then
	while IFS= read -r i; do
		# Skip empty lines or comments
		[[ -z "${i// /}" || "${i// /}" == "#"* ]] && continue

		brene_sus_path_loop "${i}"
	done < "${PERSISTENT_DIR}/custom_sus_path_loop.txt"
fi

# Load custom_kernel_umount.txt
if [[ -e "${PERSISTENT_DIR}/custom_kernel_umount.txt" ]]; then
	while IFS= read -r i; do
		# Skip empty lines or comments
		[[ -z "${i// /}" || "${i// /}" == "#"* ]] && continue

		brene_kernel_umount "${i}"
	done < "${PERSISTENT_DIR}/custom_kernel_umount.txt"
fi

# Load custom_open_redirect.txt
if [[ -e "${PERSISTENT_DIR}/custom_open_redirect.txt" ]]; then
	while read -r path new_path uid_scheme; do
		# Skip empty lines or comments
		[[ -z "${path}" || "${path}" == "#"* ]] && continue

		brene_open_redirect "${path}" "${new_path}" "${uid_scheme}"
	done < "${PERSISTENT_DIR}/custom_open_redirect.txt"
fi

#### Hide the mmapped real file from various maps in /proc/self/, effective only for processes that are marked umounted with uid >= 10000 ####
## - *Please note that it is better to do it in boot-completed starge
##   Since some target path may be mounted by ksu, and make sure the
##   target path has the same dev number as the one in global mnt ns,
##   otherwise the sus map flag won't be seen on the umounted proocess.
## - *Besides, if the source files get umounted and stay only in like zygote's memory maps,
##   then it will not work as well since sus_map checks for real file's inode.
## - To debug the namespace issue, users can do this in a root shell:
##   1. Find the pid and uid of a opened umounted app by running
##      ps -enf | grep myapp
##   2. cat /proc/<pid_of_myapp>/maps | grep "<added/sus_map/path>"'
##   3. In other root shell, run
##      cat /proc/1/mountinfo | grep "<added/sus_map/path>"'
##   4. Finally compare the dev number with both output and see if they are consistent,
##      if so, then it should be working, but if not, then the added sus_map path
##      is probably not working, and you have to find out which mnt ns the dev number
##      from step 2 belongs to, and add the path from that mnt ns:
##         busybox nsenter -t <pid_of_mnt_ns_the_target_dev_number_belongs_to> -m ksu_susfs add_sus_map <target_path>
## Hide some zygisk modules ##
# brene_sus_map /data/adb/modules/my_module/zygisk/arm64-v8a.so

#### Adding sus mounts to umount list via built-in KernelSU kernel umount (not via add_try_umount from old susfs) ####
# cat <<EOF >/dev/null
# ## Don't forget to notify KernelSU that all ksu modules all mounted and ready ##
# /data/adb/ksu/bin/ksud kernel notify-module-mounted

# ## This is just an example to add the sus mounts to kernel umount ##
# if [ ! -f "/data/adb/susfs_no_auto_add_kernel_umount" ]; then
# 	cat /proc/1/mountinfo | grep -E "^2[0-9]{9,} .*$|KSU" | awk '{print $5}' | while read -r LINE; do /data/adb/ksu/bin/ksud kernel umount add --flags 2 "${LINE}" 2>/dev/null; done
# fi
# EOF

# Hide framework-res.apk
if [[ "${config_hide_framework_res_apk}" == "1" ]]; then
	find /system -iname "*framework-res.apk" | while read -r path; do
		brene_sus_map "${path}"
	done
fi

# Spoof Android Verified Boot Hash Property
if [[ "${config_spoof_verified_boot_hash}" != '' ]]; then
	resetprop_n "ro.boot.vbmeta.digest" "${config_spoof_verified_boot_hash}"
fi

# Fix /data/local/tmp Inconsistencies
if [[ "${config_fix_data_local_tmp_inconsistencies}" == "1" ]]; then
	target_folder="/data/local/tmp"

	mkdir -p "${target_folder}"
	chmod 0771 "${target_folder}"
	chown shell:shell "${target_folder}"
	chcon u:object_r:shell_data_file:s0 "${target_folder}"
	# add_sus_kstat_statically </path/of/file_or_directory> <ino> <dev> <nlink> <size> <atime> <atime_nsec> <mtime> <mtime_nsec> <ctime> <ctime_nsec> <blocks> <blksize>
	# ino -> %i, dev -> %d, nlink -> %h, atime -> %X, mtime -> %Y, ctime -> %Z, size -> %s, blocks -> %b, blksize -> %B
	# Example: stat -c %i <path>
	${SUSFS_BIN} add_sus_kstat_statically "${target_folder}" '100' 'default' 'default' '4096' 'default' 'default' 'default' 'default' 'default' 'default' '8' '4096'
fi

resetprop -c --force

if [[ "${config_brene_logs}" == "1" ]]; then
	echo "boot-completed.sh ✅" >> "${PERSISTENT_DIR}/log.txt"
fi
