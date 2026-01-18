MODDIR=${0%/*}
KSU_BIN=/data/adb/ksu/bin/ksud
SUSFS_BIN=/data/adb/ksu/bin/ksu_susfs
PERSISTENT_DIR=/data/adb/brene
# Load config
[ -f ${PERSISTENT_DIR}/config.sh ] && . ${PERSISTENT_DIR}/config.sh


# Update Description
description=", A SuSFS module for custom kernels with SuSFS patches"
susfs_ver=$(${SUSFS_BIN} show version 2>/dev/null)
if [ -n ${susfs_ver} ]; then
	if [ -d "/data/adb/modules/rezygisk" ] && [ ! -f "/data/adb/modules/rezygisk/disable" ]; then
		new_description="Kernel: ${susfs_ver} ✅, Module: ✅, Hiding: ✅, ReZygisk: ✅${description}"
	else
		new_description="Kernel: ${susfs_ver} ✅, Module: ✅, Hiding: ✅${description}"
	fi
else
	new_description="Kernel: ❌, Module: ❌, Hiding: ❌${description}"
fi
sed -i "s/^description=.*/description=${new_description}/" ${MODDIR}/module.prop

# Enable kernel umount
${KSU_BIN} feature set kernel_umount $config_kernel_umount
${KSU_BIN} feature save


# - Two scenarios:
#   1. No any zygisk enabled => Turn it on in post-fs-data.sh and turn it off in boot-completed.sh
#   2. Zygisk enabled => No need to do anything and DO NOT turn it on before zygote, but it is fine to turn it on after zygote is fully started
[[ $config_hide_sus_mnts_for_all_procs == 1 ]] && ${SUSFS_BIN} hide_sus_mnts_for_all_procs 1 || ${SUSFS_BIN} hide_sus_mnts_for_all_procs 0


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
	[ -f /data/adb/modules/zygisk_lsposed/zygisk/arm64-v8a.so ] && ${SUSFS_BIN} add_sus_map /data/adb/modules/zygisk_lsposed/zygisk/arm64-v8a.so
	[ -f /data/adb/modules/zygisk_lsposed/zygisk/armeabi-v7a.so ] && ${SUSFS_BIN} add_sus_map /data/adb/modules/zygisk_lsposed/zygisk/armeabi-v7a.so
	[ -f /data/adb/modules/treat_wheel/zygisk/arm64-v8a.so ] && ${SUSFS_BIN} add_sus_map /data/adb/modules/treat_wheel/zygisk/arm64-v8a.so
	[ -f /data/adb/modules/treat_wheel/zygisk/armeabi-v7a.so ] && ${SUSFS_BIN} add_sus_map /data/adb/modules/treat_wheel/zygisk/armeabi-v7a.so
	[ -f /data/adb/modules/playintegrityfix/zygisk/arm64-v8a.so ] && ${SUSFS_BIN} add_sus_map /data/adb/modules/playintegrityfix/zygisk/arm64-v8a.so
	[ -f /data/adb/modules/playintegrityfix/zygisk/armeabi-v7a.so ] && ${SUSFS_BIN} add_sus_map /data/adb/modules/playintegrityfix/zygisk/armeabi-v7a.so
	[ -f /data/adb/modules/zygisk-sui/zygisk/arm64-v8a.so ] && ${SUSFS_BIN} add_sus_map /data/adb/modules/zygisk-sui/zygisk/arm64-v8a.so
	[ -f /data/adb/modules/zygisk-sui/zygisk/armeabi-v7a.so ] && ${SUSFS_BIN} add_sus_map /data/adb/modules/zygisk-sui/zygisk/armeabi-v7a.so
fi

## Hide some map traces caused by some font modules ##
if [[ $config_hide_font_modules == 1 ]]; then
	[ -f /system/fonts/Roboto-Regular.ttf ] && ${SUSFS_BIN} add_sus_map /system/fonts/Roboto-Regular.ttf
	[ -f /system/fonts/RobotoStatic-Regular.ttf ] && ${SUSFS_BIN} add_sus_map /system/fonts/RobotoStatic-Regular.ttf
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
until [ -d "/storage/emulated/0/Android/data" ]; do sleep 1; done

while true; do
	items=$(ls /storage/emulated/0/Android/data | wc -l)
	sleep 5
	[[ "${items}" -eq "$(ls /storage/emulated/0/Android/data | wc -l)" ]] && break
done

## Next we need to set the path of /sdcard/ to tell kernel where the actual /sdcard is ##
${SUSFS_BIN} set_sdcard_root_path /storage/emulated/0
## Next we need to set the path of /sdcard/ to tell kernel where the actual /sdcard/Android/data is ##
${SUSFS_BIN} set_android_data_root_path /storage/emulated/0/Android/data

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

#### Hide the leaking app path like /sdcard/Android/data/<app_package_name> from syscall ####
## Now we can add the path ##
if [[ $config_hide_sdcard_android_data == 1 ]]; then
	for i in $(ls /storage/emulated/0/Android/data); do
		${SUSFS_BIN} add_sus_path "/storage/emulated/0/Android/data/${i}"
	done
fi

#### Hide path like /sdcard/<target_root_dir> from all user app processes without root access ####
## Now we can add the path ##
if [[ $config_hide_custom_recovery_folders == 1 ]]; then
	[ -d /storage/emulated/TWRP ] && ${SUSFS_BIN} add_sus_path /storage/emulated/TWRP
	[ -d /storage/emulated/0/Fox ] && ${SUSFS_BIN} add_sus_path /storage/emulated/0/Fox
	[ -d /storage/emulated/0/TWRP ] && ${SUSFS_BIN} add_sus_path /storage/emulated/0/TWRP
fi

if [[ $config_hide_rooted_app_folders == 1 ]]; then
	[ -d /storage/emulated/0/MT2 ] && ${SUSFS_BIN} add_sus_path /storage/emulated/0/MT2
	[ -d /storage/emulated/0/OhMyFont ] && ${SUSFS_BIN} add_sus_path /storage/emulated/0/OhMyFont
	[ -d /storage/emulated/0/AppManager ] && ${SUSFS_BIN} add_sus_path /storage/emulated/0/AppManager
fi

#### Unhide all sus mounts ####
## This is up to you to unhide them all or not in this stage ##
# cat <<EOF >/dev/null
# ksu_susfs hide_sus_mnts_for_all_procs 0
# EOF

echo "EOF" >> "${PERSISTENT_DIR}/log.txt"
# EOF
