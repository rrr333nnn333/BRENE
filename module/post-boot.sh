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

until [[ -e "/storage/emulated/0/Android" ]]; do sleep 3; done

## System Property Spoofing
# Spoof System Properties
if [[ "${config_spoof_system_properties}" == "1" ]]; then
	spoof_system_properties

	# set after vold settles so the encrypted transition still reaches vendor init triggers
	if_prop_exits_resetprop_n "ro.crypto.state" "encrypted"
fi
# Spoof OS Security Patch Level Property
if [[ "${config_spoof_os_security_patch_level_property}" == "1" ]]; then
	spoof_os_security_patch_level_property
fi
# Spoof Vendor Security Patch Level Property
if [[ "${config_spoof_vendor_security_patch_level_property}" == "1" ]]; then
	spoof_vendor_security_patch_level_property
fi

# Remove "..5.u.S"
TARGET="..5.u.S"
TARGET1="/storage/emulated/0/${TARGET}"
TARGET2="/storage/emulated/0/Android/data/${TARGET}"
TARGET3="/storage/emulated/0/Android/media/${TARGET}"
TARGET4="/storage/emulated/0/Android/obb/${TARGET}"
rm -rf "${TARGET1}" "${TARGET2}" "${TARGET3}" "${TARGET4}"
inotifyd "${MODDIR}/inotify.sh" /storage/emulated/0:n &

# Hide KernelSU directories
if [[ "${config_hide_ksu_directories}" == "1" ]]; then
	sh "${MODDIR}/remove_ksu_directory.sh"
	inotifyd "${MODDIR}/remove_ksu_directory.sh" /storage/emulated/0/Android/data:n &
	inotifyd "${MODDIR}/remove_ksu_directory.sh" /storage/emulated/0/Android/media:n &
	inotifyd "${MODDIR}/remove_ksu_directory.sh" /storage/emulated/0/Android/obb:n &
fi

# Remove suspicious directories in /sdcard/Android/[data | media | obb]
if [[ -e "${PERSISTENT_DIR}/remove_sus_dir_sdcard_android_data_media_obb.txt" ]]; then
	sh "${MODDIR}/remove_sus_dir.sh"
	inotifyd "${MODDIR}/remove_sus_dir.sh" /storage/emulated/0/Android/data:n &
	inotifyd "${MODDIR}/remove_sus_dir.sh" /storage/emulated/0/Android/media:n &
	inotifyd "${MODDIR}/remove_sus_dir.sh" /storage/emulated/0/Android/obb:n &
fi

## For paths that are frequently modified, we can add them via 'add_sus_path_loop' ##
## Be reminded that without HMA's vold app data enabled, added sus_paths are still vulnerable to zwc exploit, so in this case users also have to add its underlying path as well ##

# Paths Hiding

# Hide Custom Recovery
if [[ "${config_hide_custom_recovery}" == "1" ]]; then
	if [[ "${config_brene_logs}" == "1" ]]; then
		{
			echo ""
			echo "####################"
			echo "Hide Custom Recovery"
			echo "####################"
		} >> "${PERSISTENT_DIR}/logs.txt"
	fi

	[[ -e "/storage/emulated/0/Fox" ]] && brene_sus_path_loop "/storage/emulated/0/Fox"
	[[ -e "/storage/emulated/0/TWRP" ]] && brene_sus_path_loop "/storage/emulated/0/TWRP"
	[[ -e "/data/recovery" ]] && brene_sus_path_loop "/data/recovery"
	[[ -e "/vendor/bin/install-recovery.sh" ]] && brene_sus_path_loop "/vendor/bin/install-recovery.sh"
	[[ -e "/system/bin/install-recovery.sh" ]] && brene_sus_path_loop "/system/bin/install-recovery.sh"
fi

# Hide non-standard /sdcard paths
if [[ "${config_paths_hiding__non_standard_sdcard}" == "1" ]]; then
	if [[ "${config_brene_logs}" == "1" ]]; then
		{
			echo ""
			echo "###############################"
			echo "Hide non-standard /sdcard paths"
			echo "###############################"
		} >> "${PERSISTENT_DIR}/logs.txt"
	fi

	EXCEPTIONS_FILE="${PERSISTENT_DIR}/hide_non_standard_sdcard_paths_exceptions.txt"
	STANDARD_PATHS="Alarms Android Audiobooks DCIM Documents Download Movies Music Notifications Pictures Podcasts Recordings Ringtones"

	for i in /storage/emulated/0/*; do
		pass=0
		for x in ${STANDARD_PATHS}; do
			if [[ "/storage/emulated/0/${x}" == "${i}" ]]; then
				pass=1
				break
			fi
		done

		[[ "${pass}" == "1" ]] && continue

		is_excluded() {
			[ -f "${EXCEPTIONS_FILE}" ] || return 1

			local target="$1"
			local line

			while IFS= read -r line || [ -n "$line" ]; do
				# Skip empty lines or comments
				[[ -z "${line// /}" || "${line// /}" == "#"* ]] && continue

				# shellcheck disable=SC2254
				case "$target" in
					$line)
						return 0
						;;
				esac
			done < "$EXCEPTIONS_FILE"

			return 1
		}

		name=$(basename "${i}")
		if is_excluded "$name"; then
			continue
		fi

		brene_sus_path_loop "${i}"
	done
fi

# Hide non-standard /sdcard/Android paths
if [[ "${config_paths_hiding__non_standard_sdcard_android}" == "1" ]]; then
	if [[ "${config_brene_logs}" == "1" ]]; then
		{
			echo ""
			echo "#######################################"
			echo "Hide non-standard /sdcard/Android paths"
			echo "#######################################"
		} >> "${PERSISTENT_DIR}/logs.txt"
	fi

	STANDARD_PATHS="data media obb"
	for i in /storage/emulated/0/Android/*; do
		pass=0
		for x in ${STANDARD_PATHS}; do
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
		[ -e "${i}" ] || continue

		EXCEPTIONS_FILE="${PERSISTENT_DIR}/hide_data_local_tmp_exceptions.txt"
		name=$(basename "${i}")

		is_excluded() {
			[ -f "${EXCEPTIONS_FILE}" ] || return 1

			local target="$1"
			local line

			while IFS= read -r line || [ -n "$line" ]; do
				# Skip empty lines or comments
				[[ -z "${line// /}" || "${line// /}" == "#"* ]] && continue

				# shellcheck disable=SC2254
				case "$target" in
					$line)
						return 0
						;;
				esac
			done < "$EXCEPTIONS_FILE"

			return 1
		}

		if is_excluded "$name"; then
			continue
		fi

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

# Load custom_sus_path_uid_filter.txt
if [[ -e "${PERSISTENT_DIR}/custom_sus_path_uid_filter.txt" ]]; then
	while IFS= read -r i; do
		# Skip empty lines or comments
		[[ -z "${i// /}" || "${i// /}" == "#"* ]] && continue

		${SUSFS_BIN} set_sus_path_uid_filter "${i}"
	done < "${PERSISTENT_DIR}/custom_sus_path_uid_filter.txt"
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

# Spoof /system/etc/hosts
if [[ "${config_spoof_hosts}" == "1" ]]; then
	path=/system/etc/hosts
	file_name=$(basename "${path}")
	fake_file_path="${PERSISTENT_DIR}/fake_files/${file_name}"

	[[ ! -f "${fake_file_path}" ]] && {
		cat <<- EOF > "${fake_file_path}"
			127.0.0.1       localhost
			::1             ip6-localhost

		EOF
	}

	brene_open_redirect "${path}" "${fake_file_path}" '3'

	# add_sus_kstat_statically </path/of/file_or_directory> <ino> <dev> <nlink> <size> <atime> <atime_nsec> <mtime> <mtime_nsec> <ctime> <ctime_nsec> <blocks> <blksize>
	# ino -> %i, dev -> %d, nlink -> %h, atime -> %X, mtime -> %Y, ctime -> %Z, size -> %s, blocks -> %b, blksize -> %B
	# Example: stat -c %i <path>
	${SUSFS_BIN} add_sus_kstat_statically "${path}" '100' 'default' 'default' '56' 'default' 'default' 'default' 'default' 'default' 'default' '1' '4096'
fi

# Hide /system/addon.d
if [[ "${config_hide_addon_d}" == "1" ]]; then
	brene_sus_map "/system/addon.d"
	brene_sus_path_loop "/system/addon.d"
fi

# Hide Gapps
if [[ "${config_hide_gapps}" == "1" ]]; then
	keyword="gapps"

	find /system /system_ext /vendor /product -iname "*${keyword}*" | while read -r path; do
		brene_sus_map "${path}"
		brene_sus_path_loop "${path}"
	done

	find /data -maxdepth 1 -iname "*${keyword}*" | while read -r path; do
		brene_sus_map "${path}"
		brene_sus_path_loop "${path}"
	done

	find /data/misc /data/dalvik-cache /data/resource-cache -iname "*${keyword}*" | while read -r path; do
		brene_sus_map "${path}"
		brene_sus_path_loop "${path}"
	done
fi

# Hide Custom ROM Paths
if [[ "${config_hide_custom_rom_paths}" == "1" ]]; then
	for i in ${CUSTOM_ROM_NAMES//|/ }; do
		find /system /system_ext /vendor /product -iname "*${i}*" | while read -r path; do
			brene_sus_map "${path}"
			brene_sus_path_loop "${path}"
		done

		find /data -maxdepth 1 -iname "*${i}*" | while read -r path; do
			brene_sus_map "${path}"
			brene_sus_path_loop "${path}"
		done
	done
fi

# Hide Custom ROM Paths (Extended)
if [[ "${config_hide_custom_rom_paths_2}" == "1" ]]; then
	for i in ${CUSTOM_ROM_NAMES//|/ }; do
		find /data/misc /data/dalvik-cache /data/resource-cache -iname "*${i}*" | while read -r path; do
			brene_sus_map "${path}"
			brene_sus_path_loop "${path}"
		done
	done
fi

# Hide Suspicious PTYs
if [[ "${config_hide_suspicious_pty}" == "1" ]]; then
	if [[ "${config_brene_logs}" == "1" ]]; then
		{
			echo ""
			echo "####################"
			echo "Hide Suspicious PTYs"
			echo "####################"
		} >> "${PERSISTENT_DIR}/logs.txt"
	fi

	for i in $(seq 0 5); do
		brene_sus_path_loop "/dev/pts/${i}"
	done
fi

# Hide third party apps
if [[ "${config_hide_third_party_apps}" == "1" ]]; then
	packages=$(cmd package list packages -3 | awk -F: '{pkg = pkg (pkg ? "," : "") $2} END {print pkg}')
	${SUSFS_BIN} set_priority_uid_filter "${packages}"
fi

# Hide all apps with uid >= 10000
if [[ "${config_hide_all_apps_with_uid_10000_and_above}" == "1" ]]; then
	packages=$(awk '$2 >= 10000 {pkg = pkg (pkg ? "," : "") $1} END {print pkg}' /data/system/packages.list)
	${SUSFS_BIN} set_priority_uid_filter "${packages}"
fi

update_config_date
resetprop -c --force

if [[ "${config_brene_logs}" == "1" ]]; then
	echo "✅ post-boot.sh" >> "${PERSISTENT_DIR}/log.txt"
fi
