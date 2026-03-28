MODDIR=${0%/*}
KSU_BIN=/data/adb/ksu/bin/ksud
SUSFS_BIN=/data/adb/ksu/bin/susfs
PERSISTENT_DIR=/data/adb/brene
# Load config
[ -e ${PERSISTENT_DIR}/config.sh ] && source ${PERSISTENT_DIR}/config.sh
source ${MODDIR}/utils.sh

# Update Description
description="A SuSFS/KernelSU module for SuSFS patched kernels"
susfs_ver=$(${SUSFS_BIN} show version 2>/dev/null)
if [ -n ${susfs_ver} ]; then
	# if [ -e "/data/adb/modules/rezygisk" ] && [ ! -f "/data/adb/modules/rezygisk/disable" ]; then
	# else
	# fi
	status="[Module Status: ✅, SuSFS Patches: ${susfs_ver}+]\\\\n"
else
	status="[Module Status: ❌, SuSFS Patches: ❌]\\\\n"
fi
sed -i "s|^description=.*|description=${status}${description}|" ${MODDIR}/module.prop


# Enable kernel umount
${KSU_BIN} feature set kernel_umount ${config_kernel_umount}
${KSU_BIN} feature save


# Verified Boot Hash
if [[ $config_verified_boot_hash != '' ]]; then
	resetprop_n "ro.boot.vbmeta.digest" "${config_verified_boot_hash}"
fi


# Developer options
[[ $config_developer_options == 1 ]] && settings put global development_settings_enabled 1 || settings put global development_settings_enabled 0


# USB debugging
[[ $config_usb_debugging == 1 ]] && settings put global adb_enabled 1 || settings put global adb_enabled 0


# Wireless Debugging
[[ $config_wireless_debugging == 1 ]] && settings put global adb_wifi_enabled 1 || settings put global adb_wifi_enabled 0


# SELinux
if [[ $config_selinux == 1 ]]; then
	[[ $(getenforce) == "Permissive" ]] && setenforce 1
else
	[[ $(getenforce) == "Enforcing" ]] && setenforce 0
fi


# Remove Play Integrity Fix Props (EXPERIMENTAL)
if [[ $config_pif_props == 1 ]]; then
	resetprop | grep -E "pihook|pixelprops" | sed -E "s/^\[(.*)\]:.*/\1/" | while IFS= read -r prop; do resetprop -p -d "$prop"; done
fi

# Remove Custom ROM Props (EXPERIMENTAL)
if [[ $config_rom_props == 1 ]]; then
	resetprop | grep -E "lineage|crdroid" | sed -E "s/^\[(.*)\]:.*/\1/" | while IFS= read -r prop; do resetprop -p -d "$prop"; done
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
# ${SUSFS_BIN} add_sus_map /data/adb/modules/my_module/zygisk/arm64-v8a.so
if [[ $config_hide_zygisk_modules == 1 ]]; then
	for i in $(find /data/adb/modules -name *.so | grep /zygisk/); do
		${SUSFS_BIN} add_sus_map "${i}"
	done
fi

if [[ $config_hide_injections == 1 ]]; then
	for i in $(ls /data/adb/modules); do
		if [ -e "/data/adb/modules/${i}/system" ]; then
			for x in $(find "/data/adb/modules/${i}/system" -type f -name "*.*"); do
				${SUSFS_BIN} add_sus_map "${x}"
			done
		fi
	done
fi


#### Hide some sus paths, effective only for processes that are marked umounted with uid >= 10000 ####
## First we need to wait until files are accessible in /sdcard ##
until [ -e "/sdcard/Android" ]; do sleep 1; done

## For paths that are frequently modified, we can add them via 'add_sus_path_loop' ##
if [[ $config_non_standard_sdcard_paths_hiding == 1 ]]; then
	standard_paths="Alarms Android Audiobooks DCIM Documents Download Movies Music Notifications Pictures Podcasts Recordings Ringtones"
	
	for i in /sdcard/*; do
		pass=0
		for x in $standard_paths; do
			if [[ "/sdcard/$x" == "$i" ]]; then
				pass=1
				break
			fi
		done

		if [[ "$pass" == "1" ]]; then
			continue
		fi

		${SUSFS_BIN} add_sus_path_loop "$i"
	done
fi

if [[ $config_non_standard_sdcard_android_paths_hiding == 1 ]]; then
	standard_paths="data media obb"
	
	for i in /sdcard/Android/*; do
		pass=0
		for x in $standard_paths; do
			if [[ "/sdcard/Android/$x" == "$i" ]]; then
				pass=1
				break
			fi
		done

		if [[ "$pass" == "1" ]]; then
			continue
		fi

		${SUSFS_BIN} add_sus_path_loop "$i"
	done
fi


if [[ $config_hide_data_local_tmp == 1 ]]; then
	for i in $(ls /data/local/tmp); do
		${SUSFS_BIN} add_sus_path_loop "/data/local/tmp/${i}"
	done
fi


## For paths that are read-only all the time, add them via 'add_sus_path' ##
# ${SUSFS_BIN} add_sus_path /sys/block/loop0
${SUSFS_BIN} add_sus_path /system/addon.d
${SUSFS_BIN} add_sus_path /vendor/bin/install-recovery.sh
${SUSFS_BIN} add_sus_path /system/bin/install-recovery.sh

if [[ $config_hide_sdcard_android_data == 1 ]]; then
	while true; do
		items=$(ls /sdcard/Android/data | wc -l)
		sleep 10
		[[ "${items}" -eq "$(ls /sdcard/Android/data | wc -l)" ]] && break
	done

	for i in $(pm list packages -3 | cut -d':' -f2); do
		[ -e "/sdcard/Android/data/$i" ] && ${SUSFS_BIN} add_sus_path "/sdcard/Android/data/$i"
	done
fi


# Load custom_sus_map.txt
if [ -e "${PERSISTENT_DIR}/custom_sus_map.txt" ]; then
	while IFS= read -r i; do
		# Skip empty lines or comments
		[[ -z "${i}" || "${i}" == "#"* ]] && continue
		[ -e "${i}" ] && ${SUSFS_BIN} add_sus_map "${i}"
	done < "${PERSISTENT_DIR}/custom_sus_map.txt"
fi

# Load custom_sus_path.txt
if [ -e "${PERSISTENT_DIR}/custom_sus_path.txt" ]; then
	while IFS= read -r i; do
		# Skip empty lines or comments
		[[ -z "${i}" || "${i}" == "#"* ]] && continue
		[ -e "${i}" ] && ${SUSFS_BIN} add_sus_path "${i}"
	done < "${PERSISTENT_DIR}/custom_sus_path.txt"
fi

# Load custom_sus_path_loop.txt
if [ -e "${PERSISTENT_DIR}/custom_sus_path_loop.txt" ]; then
	while IFS= read -r i; do
		# Skip empty lines or comments
		[[ -z "${i}" || "${i}" == "#"* ]] && continue
		[ -e "${i}" ] && ${SUSFS_BIN} add_sus_path_loop "${i}"
	done < "${PERSISTENT_DIR}/custom_sus_path_loop.txt"
fi


resetprop -c 2>/dev/null || true

echo "EOF" >> "${PERSISTENT_DIR}/log.txt"
# EOF
