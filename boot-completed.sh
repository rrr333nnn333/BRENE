#!/system/bin/sh
MODDIR=${0%/*}
KSU_BIN=/data/adb/ksu/bin/ksud
SUSFS_BIN=/data/adb/ksu/bin/ksu_susfs

# Update Description
text1='Kernel: ❌, Module: ❌, Hiding: ❌ SuSFS module for custom kernels with SuSFS patches'
text2='Kernel: ✅, Module: ✅, Hiding: ✅ SuSFS module for custom kernels with SuSFS patches'
if ksu_susfs show version 2>/dev/null; then
	sed -i "s/$text1/$text2/" ${MODDIR}/module.prop
else
	sed -i "s/$text2/$text1/" ${MODDIR}/module.prop
fi

# Enable kernel umount
${KSU_BIN} feature set 1 1

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
${SUSFS_BIN} add_sus_map /data/adb/rezygisk/lib/libzygisk.so
${SUSFS_BIN} add_sus_map /data/adb/rezygisk/lib64/libzygisk.so
${SUSFS_BIN} add_sus_map /data/adb/modules/zygisk_lsposed/zygisk/arm64-v8a.so
${SUSFS_BIN} add_sus_map /data/adb/modules/zygisk_lsposed/zygisk/armeabi-v7a.so
${SUSFS_BIN} add_sus_map /data/adb/modules/treat_wheel/zygisk/arm64-v8a.so
${SUSFS_BIN} add_sus_map /data/adb/modules/treat_wheel/zygisk/armeabi-v7a.so
${SUSFS_BIN} add_sus_map /data/adb/modules/playintegrityfix/zygisk/arm64-v8a.so
${SUSFS_BIN} add_sus_map /data/adb/modules/playintegrityfix/zygisk/armeabi-v7a.so
${SUSFS_BIN} add_sus_map /data/adb/modules/zygisk-sui/zygisk/arm64-v8a.so
${SUSFS_BIN} add_sus_map /data/adb/modules/zygisk-sui/zygisk/armeabi-v7a.so

## Hide some map traces caused by some font modules ##
${SUSFS_BIN} add_sus_map /system/fonts/Roboto-Regular.ttf
${SUSFS_BIN} add_sus_map /system/fonts/RobotoStatic-Regular.ttf


#### For path that needs to be re-flagged as SUS_PATH on each non-root user app / isolated service starts via add_sus_path_loop ####
## - Path added via add_sus_path_loop will be re-flagged as SUS_PATH on each non-root process / isolated service starts ##
## - This can help ensure some path that keep its inode status reset for whatever reason to be flagged as SUS_PATH again ##
## - Please also note that only paths NOT inside '/sdcard/' or '/storage/' can be added via add_sus_path_loop ##
## - ONLY USE THIS WHEN NECCESSARY !!! ##
# ${SUSFS_BIN} add_sus_path_loop /sys/block/loop0
for i in $(ls /data/local/tmp); do
	${SUSFS_BIN} add_sus_path_loop "/data/local/tmp/$i"
done


## Please note that sometimes the path needs to be added twice or above to be effective ##
## Besides, all user apps without root access cannot see the hidden path '/sdcard/<hidden_path>' unless you grant it root access ##
## First we need to wait until files are accessible in /sdcard ##
until [ -d "/sdcard/Android/data" ]; do sleep 1; done

while true; do
	## Next we need to set the path of /sdcard/ to tell kernel where the actual /sdcard is ##
	${SUSFS_BIN} set_sdcard_root_path /sdcard
	## Next we need to set the path of /sdcard/ to tell kernel where the actual /sdcard/Android/data is ##
	${SUSFS_BIN} set_android_data_root_path /sdcard/Android/data

	#### Hide the leaking app path like /sdcard/Android/data/<app_package_name> from syscall ####
	## Now we can add the path ##
	for i in $(ls /sdcard/Android/data); do
		${SUSFS_BIN} add_sus_path "/sdcard/Android/data/$i"
	done
	for i in $(ls /sdcard/Android/media); do
		${SUSFS_BIN} add_sus_path "/sdcard/Android/media/$i"
	done
	for i in $(ls /sdcard/Android/obb); do
		${SUSFS_BIN} add_sus_path "/sdcard/Android/obb/$i"
	done

	#### Hide path like /sdcard/<target_root_dir> from all user app processes without root access ####
	## Now we can add the path ##
	${SUSFS_BIN} add_sus_path /sdcard/TWRP
	${SUSFS_BIN} add_sus_path /storage/emulated/TWRP
	${SUSFS_BIN} add_sus_path /sdcard/Fox
	${SUSFS_BIN} add_sus_path /sdcard/MT2
	${SUSFS_BIN} add_sus_path /sdcard/AppManager
	${SUSFS_BIN} add_sus_path /sdcard/OhMyFont

	sleep 10
done

# EOF
