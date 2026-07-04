#!/bin/bash
MODDIR=${0%/*}
KSU_BIN=/data/adb/ksud
KSU_MODULES_DIR=/data/adb/modules
SUSFS_BIN=/data/adb/ksu/bin/susfs
PERSISTENT_DIR=/data/adb/brene
DEST_BIN_DIR=/data/adb/ksu/bin

# Load utils
[[ -e "${MODDIR}/utils.sh" ]] && source "${MODDIR}/utils.sh"
# Load config
[[ -e "${PERSISTENT_DIR}/config.sh" ]] && source "${PERSISTENT_DIR}/config.sh"

# Update Description
description="A SuSFS/KernelSU module for SuSFS patched kernels"
susfs_ver=$(${SUSFS_BIN} show version 2> /dev/null)
if [[ -n "${susfs_ver}" ]]; then
	status="[Module Status: ✅ | SuSFS Patches: ✅ ${susfs_ver}+]\\\\n"
else
	status="[Module Status: ❌ | SuSFS Patches: ❌]\\\\n"
fi
sed -i "s#^description=.*#description=${status}${description}#" "${MODDIR}/module.prop"

# Kernel Umount
[[ -n "${config_kernel_umount}" ]] && ${KSU_BIN} feature set kernel_umount "${config_kernel_umount}"
# SU Compat
[[ -n "${config_su_compat}" ]] && ${KSU_BIN} feature set su_compat "${config_su_compat}"
${KSU_BIN} feature save

# Android Verified Boot Hash Spoofing
if [[ "${config_verified_boot_hash}" != '' ]]; then
	resetprop_n "ro.boot.vbmeta.digest" "${config_verified_boot_hash}"
fi

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

# SELinux Enforcing
if [[ "${config_selinux}" == "1" ]]; then
	[[ "$(getenforce)" != "Enforcing" ]] && setenforce 1
fi

# Remove Custom ROM Properties
if [[ "${config_rom_props}" == "1" ]]; then
	crom="lineage|infinity|evolution|crdroid|arrow|mistos|axion|pixelos|rising|lunaris|halcyon|havoc|alphadroid|avium|bliss|calyx|derpfest|graphene|lmodroid|lumine|matrixx|superior|clover|yaap"
	resetprop | grep -iE "${crom}" | awk -F'[][]' '{print $2}' | while read -r prop; do
		resetprop -d "${prop}"
	done

	resetprop -d "ro.modversion"
fi

# Remove Play Integrity Fix Properties
if [[ "${config_pif_props}" == "1" ]]; then
	resetprop | grep -iE "pihook|pixelprops|spoof" | awk -F'[][]' '{print $2}' | while read -r prop; do
		resetprop -d "${prop}"
	done
fi

#### Hide some sus paths, effective only for processes that are marked umounted with uid >= 10000 ####
## First we need to wait until files are accessible in /sdcard ##
until [[ -e "/sdcard/Android" ]]; do sleep 1; done

## Remove the '..5.u.S' leftover ##
## THe reason why this sus file is created is because users have grant the MANAGE_EXTERNAL_STORAGE permission for the apps that detecting sus files in /sdcard, or in /sdcard/Android/data where the apps are exploiting the unicode bugs to create files arbitrary.
## susfs redirects the sus path to a supposed not-existing path named '..5.u.S', and this is the only way to settle the cross check of returned errno from various syscalls, but one disadvantage is that if the path itself can be written/created by the app (MANAGE_EXTERNAL_STORAGE granted), then it is futile to hide it, but at least here we automatically delete them on each boot.
## The best practise is to revoke MANAGE_EXTERNAL_STORAGE permission for all third party apps.
# [ -e "/sdcard/..5.u.S" ] && rm -rf "/sdcard/..5.u.S"
# [ -e "/sdcard/Android/data/..5.u.S" ] && rm -rf "/sdcard/Android/data/..5.u.S"
# [ -e "/sdcard/Android/media/..5.u.S" ] && rm -rf "/sdcard/Android/media/..5.u.S"

# Remove "..5.u.S"
TARGET="..5.u.S"
TARGET1="/sdcard/${TARGET}"
TARGET2="/sdcard/Android/data/${TARGET}"
TARGET3="/sdcard/Android/media/${TARGET}"
TARGET4="/sdcard/Android/obb/${TARGET}"
rm -rf "${TARGET1}" "${TARGET2}" "${TARGET3}" "${TARGET4}"
inotifyd "${MODDIR}/inotify.sh" /sdcard:n &

## For paths that are frequently modified, we can add them via 'add_sus_path_loop' ##
## Be reminded that without HMA's vold app data enabled, added sus_paths are still vulnerable to zwc exploit, so in this case users also have to add its underlying path as well ##

# Suspicious Paths Hiding

# Non-standard /sdcard
if [[ "${config_paths_hiding__non_standard_sdcard}" == "1" ]]; then
	if [[ "${config_brene_logs}" == "1" ]]; then
		{
			echo ""
			echo "####################"
			echo "Non-standard /sdcard"
			echo "####################"
		} >> "${PERSISTENT_DIR}/logs.txt"
	fi

	if [[ -z "$(resetprop ro.miui.ui.version.name)" ]]; then
		standard_paths="Alarms Android Audiobooks DCIM Documents Download Movies Music Notifications Pictures Podcasts Recordings Ringtones"
	else
		standard_paths="Alarms Android Audiobooks DCIM Documents Download Movies Music Notifications Pictures Podcasts Recordings Ringtones MIUI"
	fi

	for i in /sdcard/*; do
		pass=0
		for x in ${standard_paths}; do
			if [[ "/sdcard/${x}" == "${i}" ]]; then
				pass=1
				break
			fi
		done

		[[ "${pass}" == "1" ]] && continue

		brene_sus_path_loop "${i}"
	done
fi

# Non-standard /sdcard/Android
if [[ "${config_paths_hiding__non_standard_sdcard_android}" == "1" ]]; then
	if [[ "${config_brene_logs}" == "1" ]]; then
		{
			echo ""
			echo "############################"
			echo "Non-standard /sdcard/Android"
			echo "############################"
		} >> "${PERSISTENT_DIR}/logs.txt"
	fi

	standard_paths="data media obb"
	for i in /sdcard/Android/*; do
		pass=0
		for x in ${standard_paths}; do
			if [[ "/sdcard/Android/${x}" == "${i}" ]]; then
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

# /sdcard/Android/[data | media | obb]
if [[ "${config_paths_hiding__sdcard_android_data_media_obb}" == "1" ]]; then
	if [[ "${config_brene_logs}" == "1" ]]; then
		{
			echo ""
			echo "####################################"
			echo "/sdcard/Android/[data | media | obb]"
			echo "####################################"
		} >> "${PERSISTENT_DIR}/logs.txt"
	fi

	packages="
	io.github.muntashirakon.AppManager
	com.github.capntrips.kernelflasher
	com.machiav3lli.backup
	"

	for i in ${packages}; do
		path1=/sdcard/Android
		full_path1="${path1}/data/${i}"
		full_path2="${path1}/media/${i}"
		full_path3="${path1}/obb/${i}"
		[[ -e "${full_path1}" ]] && brene_sus_path_loop "${full_path1}"
		[[ -e "${full_path2}" ]] && brene_sus_path_loop "${full_path2}"
		[[ -e "${full_path3}" ]] && brene_sus_path_loop "${full_path3}"
	done

	# path1=/sdcard/Android/data
	# path2=/sdcard/Android/media
	# path3=/sdcard/Android/obb
	# for i in $(pm list packages -3 | cut -d':' -f2); do
	# 	full_path1="${path1}/${i}"
	# 	full_path2="${path2}/${i}"
	# 	full_path3="${path3}/${i}"
	# 	[[ -e "${full_path1}" ]] && brene_sus_path_loop "${full_path1}"
	# 	[[ -e "${full_path2}" ]] && brene_sus_path_loop "${full_path2}"
	# 	[[ -e "${full_path3}" ]] && brene_sus_path_loop "${full_path3}"
	# done
fi

## For paths that are read-only all the time, add them via 'add_sus_path' ##
if [[ "${config_brene_logs}" == "1" ]]; then
	{
		echo ""
		echo "#############################"
		echo "Other Suspicious Paths Hiding"
		echo "#############################"
	} >> "${PERSISTENT_DIR}/logs.txt"
fi
# brene_sus_path "/sys/block/loop0"
brene_sus_path "/system/addon.d"
brene_sus_path "/vendor/bin/install-recovery.sh"
brene_sus_path "/system/bin/install-recovery.sh"

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

# Injections Hiding
if [[ "${config_hide_injections}" == "1" ]]; then
	if [[ "${config_brene_logs}" == "1" ]]; then
		{
			echo ""
			echo "#################"
			echo "Injections Hiding"
			echo "#################"
		} >> "${PERSISTENT_DIR}/logs.txt"
	fi

	for i in /data/adb/modules/*; do
		if [[ -e "${i}/system" ]]; then
			for x in $(find "${i}/system" -type f); do
				brene_sus_map "${x}"
			done
		fi
	done

	for i in $(find /data/adb/modules -name "*.so"); do
		brene_sus_map "${i}"
	done
fi

# Uname Spoofing
kernel_version=$(uname -r | cut -d'-' -f1)
android_release=$(${KSU_BIN} boot-info current-kmi | cut -d'-' -f1)
config_uname_kernel_release="${kernel_version}-${android_release}-9-g690101101069"
config_uname_kernel_version="#1 SMP PREEMPT $(resetprop ro.build.date)"
sed -i "s/^config_uname_kernel_release=.*/config_uname_kernel_release='${config_uname_kernel_release}'/" ${PERSISTENT_DIR}/config.sh
sed -i "s/^config_uname_kernel_version=.*/config_uname_kernel_version='${config_uname_kernel_version}'/" ${PERSISTENT_DIR}/config.sh

#### Adding sus mounts to umount list via built-in KernelSU kernel umount (not via add_try_umount from old susfs) ####
# cat <<EOF >/dev/null
# ## Don't forget to notify KernelSU that all ksu modules all mounted and ready ##
# /data/adb/ksu/bin/ksud kernel notify-module-mounted

# ## This is just an example to add the sus mounts to kernel umount ##
# if [ ! -f "/data/adb/susfs_no_auto_add_kernel_umount" ]; then
# 	cat /proc/1/mountinfo | grep -E "^2[0-9]{9,} .*$|KSU" | awk '{print $5}' | while read -r LINE; do /data/adb/ksu/bin/ksud kernel umount add --flags 2 "${LINE}" 2>/dev/null; done
# fi
# EOF

#### Adding sus mounts to umount list via built-in KernelSU kernel umount (not via add_try_umount from old susfs) ####
# Umount Suspicious Mounts

if [[ "${config_umount_suspicious_mounts}" == "1" ]]; then
	## Don't forget to notify KernelSU that all ksu modules all mounted and ready ##
	${KSU_BIN} kernel notify-module-mounted

	cat /proc/1/mountinfo | grep -E "^2[0-9]{9,} .*$|KSU" | awk '{print $5}' | while read -r mount; do
		${KSU_BIN} kernel umount add -f 2 "${mount}" 2> /dev/null
	done
fi

# Hide Suspicious PTYs
if [[ "${config_hide_suspicious_ptys}" == "1" ]]; then
	if [[ "${config_brene_logs}" == "1" ]]; then
		{
			echo ""
			echo "####################"
			echo "Hide Suspicious PTYs"
			echo "####################"
		} >> "${PERSISTENT_DIR}/logs.txt"
	fi

	for i in $(seq 0 9); do
		brene_sus_path_loop "/dev/pts/${i}"
	done
fi

# Hide framework-res.apk
if [[ "${config_hide_framework_res_apk}" == "1" ]]; then
	find /system -iname "*framework-res.apk" | while read -r path; do
		brene_sus_map "${path}"
	done
fi

resetprop -c --force

if [[ "${config_brene_logs}" == "1" ]]; then
	echo "boot-completed.sh ✅" >> "${PERSISTENT_DIR}/log.txt"
fi
