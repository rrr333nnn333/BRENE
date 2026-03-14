MODDIR=${0%/*}
KSU_BIN=/data/adb/ksu/bin/ksud
SUSFS_BIN=/data/adb/ksu/bin/susfs
PERSISTENT_DIR=/data/adb/brene
# Load config
[ -f ${PERSISTENT_DIR}/config.sh ] && . ${PERSISTENT_DIR}/config.sh

. ${MODDIR}/utils.sh

# Update Description
description="A SuSFS/KernelSU module for SuSFS patched kernels"
susfs_ver=$(${SUSFS_BIN} show version 2>/dev/null)
if [ -n ${susfs_ver} ]; then
	# if [ -d "/data/adb/modules/rezygisk" ] && [ ! -f "/data/adb/modules/rezygisk/disable" ]; then
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


#### Unhide all sus mounts from /proc/self/[mounts|mountinfo|mountstat] for non-su processes ####
## It is suggested to unhide it in this stage, and let kernel or zygisk to umount them for user processes, but this is up to you ##
# cat <<EOF >/dev/null
# ksu_susfs hide_sus_mnts_for_non_su_procs 0
# EOF


#### Hide the mmapped real file from various maps in /proc/self/ ####
## - Please note that it is better to do it in boot-completed starge
##   Since some target path may be mounted by ksu, and make sure the
##   target path has the same dev number as the one in global mnt ns,
##   otherwise the sus map flag won't be seen on the umounted process.
## - To debug with this, users can do this in a root shell:
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
		if [ -d "/data/adb/modules/${i}/system" ]; then
			for x in $(find "/data/adb/modules/${i}/system" -type f -name "*.*"); do
				${SUSFS_BIN} add_sus_map "${x}"
			done
		fi
	done
fi

#### For path that needs to be re-flagged as SUS_PATH on each non-root user app / isolated service starts via add_sus_path_loop ####
## - Path added via add_sus_path_loop will be re-flagged as SUS_PATH on each non-root process / isolated service starts ##
## - This can help ensure some path that keep its inode status reset for whatever reason to be flagged as SUS_PATH again ##
## - Please also note that only paths NOT inside '/sdcard/' or '/storage/' can be added via add_sus_path_loop ##
## - ONLY USE THIS WHEN NECCESSARY !!! ##
# ${SUSFS_BIN} add_sus_path_loop /sys/block/loop0
if [[ $config_hide_data_local_tmp == 1 ]]; then
	for i in $(ls /data/local/tmp); do
		${SUSFS_BIN} add_sus_path_loop "/data/local/tmp/${i}"
	done
fi


## Please note that sometimes the path needs to be added twice or above to be effective ##
## Besides, all user apps without root access cannot see the hidden path '/sdcard/<hidden_path>' unless you grant it root access ##
## First we need to wait until files are accessible in /sdcard ##
until [ -d /sdcard/Android ]; do sleep 1; done

## Next we need to set the path of /sdcard/ to tell kernel where the actual /sdcard is ##
${SUSFS_BIN} set_sdcard_root_path /sdcard
## Next we need to set the path of /sdcard/ to tell kernel where the actual /sdcard/Android/data is ##
${SUSFS_BIN} set_android_data_root_path /sdcard/Android/data

# Load custom_sus_map.txt
if [ -f "${PERSISTENT_DIR}/custom_sus_map.txt" ]; then
	while IFS= read -r i; do
		# Skip empty lines or comments
		[[ -z "${i}" || "${i}" == "#"* ]] && continue
		[ -f "${i}" ] && ${SUSFS_BIN} add_sus_map "${i}"
	done < "${PERSISTENT_DIR}/custom_sus_map.txt"
fi

# Load custom_sus_path.txt
if [ -f "${PERSISTENT_DIR}/custom_sus_path.txt" ]; then
	while IFS= read -r i; do
		# Skip empty lines or comments
		[[ -z "${i}" || "${i}" == "#"* ]] && continue
		[ -d "${i}" ] && ${SUSFS_BIN} add_sus_path "${i}"
		[ -f "${i}" ] && ${SUSFS_BIN} add_sus_path "${i}"
	done < "${PERSISTENT_DIR}/custom_sus_path.txt"
fi

# Load custom_sus_path_loop.txt
if [ -f "${PERSISTENT_DIR}/custom_sus_path_loop.txt" ]; then
	while IFS= read -r i; do
		# Skip empty lines or comments
		[[ -z "${i}" || "${i}" == "#"* ]] && continue
		[ -d "${i}" ] && ${SUSFS_BIN} add_sus_path_loop "${i}"
		[ -f "${i}" ] && ${SUSFS_BIN} add_sus_path_loop "${i}"
	done < "${PERSISTENT_DIR}/custom_sus_path_loop.txt"
fi

#### Hide path like /sdcard/<target_root_dir> from all user app processes without root access ####
## Now we can add the path ##
if [[ $config_hide_rooted_app_folders == 1 ]]; then
	[ -d /sdcard/MT2 ] && ${SUSFS_BIN} add_sus_path_loop /sdcard/MT2
	[ -d /sdcard/rlgg ] && ${SUSFS_BIN} add_sus_path_loop /sdcard/rlgg
	[ -d /sdcard/xinhao ] && ${SUSFS_BIN} add_sus_path_loop /sdcard/xinhao
	[ -d /sdcard/OhMyFont ] && ${SUSFS_BIN} add_sus_path_loop /sdcard/OhMyFont
	[ -d /sdcard/AppManager ] && ${SUSFS_BIN} add_sus_path_loop /sdcard/AppManager
	[ -d /sdcard/DataBackup ] && ${SUSFS_BIN} add_sus_path_loop /sdcard/DataBackup
	[ -d /sdcard/KernelFlasher ] && ${SUSFS_BIN} add_sus_path_loop /sdcard/KernelFlasher
	[ -d /sdcard/Android/fas-rs ] && ${SUSFS_BIN} add_sus_path_loop /sdcard/Android/fas-rs
fi

if [[ $config_hide_custom_recovery_folders == 1 ]]; then
	[ -d /sdcard/Fox ] && ${SUSFS_BIN} add_sus_path_loop /sdcard/Fox
	[ -d /sdcard/PBRP ] && ${SUSFS_BIN} add_sus_path_loop /sdcard/PBRP
	[ -d /sdcard/TWRP ] && ${SUSFS_BIN} add_sus_path_loop /sdcard/TWRP
	[ -d /storage/emulated/TWRP ] && ${SUSFS_BIN} add_sus_path_loop /storage/emulated/TWRP
fi


# Remove Play Integrity Fix Props (EXPERIMENTAL)
if [[ $config_pif_props == 1 ]]; then
	resetprop | grep -E "pihook|pixelprops" | sed -E "s/^\[(.*)\]:.*/\1/" | while IFS= read -r prop; do resetprop -p -d "$prop"; done
fi

# Remove Custom ROM Props (EXPERIMENTAL)
if [[ $config_rom_props == 1 ]]; then
	resetprop | grep -E "lineage|crdroid" | sed -E "s/^\[(.*)\]:.*/\1/" | while IFS= read -r prop; do resetprop -p -d "$prop"; done
fi


#### Hide the leaking app path like /sdcard/Android/data/<app_package_name> from syscall ####
## Now we can add the path ##
if [[ $config_hide_sdcard_android_data == 1 ]]; then
	while true; do
		items=$(ls /sdcard/Android/data | wc -l)
		sleep 10
		[[ "${items}" -eq "$(ls /sdcard/Android/data | wc -l)" ]] && break
	done

	for i in $(pm list packages -3 | cut -d':' -f2); do
		[ -d "/sdcard/Android/data/$i" ] && ${SUSFS_BIN} add_sus_path "/sdcard/Android/data/$i"
	done
fi


echo "EOF" >> "${PERSISTENT_DIR}/log.txt"
# EOF
