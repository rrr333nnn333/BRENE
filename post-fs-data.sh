MODDIR=${0%/*}
DEST_BIN_DIR=/data/adb/ksu/bin
SUSFS_BIN=/data/adb/ksu/bin/ksu_susfs
PERSISTENT_DIR=/data/adb/brene
# Load config
[ -f ${PERSISTENT_DIR}/config.sh ] && . ${PERSISTENT_DIR}/config.sh

cp -f ${MODDIR}/tools/ksu_susfs ${DEST_BIN_DIR}
cp -f ${MODDIR}/tools/ksu_susfs ${DEST_BIN_DIR}/susfs # For development
chmod 755 ${DEST_BIN_DIR}/susfs
chmod 755 ${DEST_BIN_DIR}/ksu_susfs

. ${MODDIR}/utils.sh

## Important Notes:
## - The following command can be run at other stages like service.sh, boot-completed.sh etc..,
## - This module is just an demo showing how to use ksu_susfs tool to commuicate with kernel
##

#### Hide target path and all its sub-paths from all user app processes which have no root permission granted ####
## Make sure the target file/directory has no more overlay/mount operation on going. Or add it after it is done being overlayed or mounted ##
# For some custom ROM #
[ -d /system/addon.d ] && ${SUSFS_BIN} add_sus_path /system/addon.d
[ -f /vendor/bin/install-recovery.sh ] && ${SUSFS_BIN} add_sus_path /vendor/bin/install-recovery.sh
[ -f /system/bin/install-recovery.sh ] && ${SUSFS_BIN} add_sus_path /system/bin/install-recovery.sh
[ -f /system/vendor/bin/install-recovery.sh ] && ${SUSFS_BIN} add_sus_path /system/vendor/bin/install-recovery.sh


#### Spoof the stat of file/directory dynamically ####
## Important Note: 
##  - It is stronly suggested to use dynamically if the target path will be mounted
# cat <<EOF >/dev/null
# # First, clone the permission before adding to sus_kstat
# susfs_clone_perm "$MODDIR/hosts" /system/etc/hosts

# # Second, before bind mount your file/directory, use 'add_sus_kstat' to add the path #
# ${SUSFS_BIN} add_sus_kstat '/system/etc/hosts'

# # Now bind mount or overlay your path #
# mount -o bind "$MODDIR/hosts" /system/etc/hosts

# # Finally use 'update_sus_kstat' to update the path again for the changed ino and device number #
# # update_sus_kstat updates ino, but blocks and size are remained the same as current stat #
# ${SUSFS_BIN} update_sus_kstat '/system/etc/hosts'

# # Or if you want to fully clone the stat value from the original stat, use update_sus_kstat_full_clone instead #
# #${SUSFS_BIN} update_sus_kstat_full_clone '/system/etc/hosts'
# EOF

#### Spoof the stat of file/directory statically ####
## Important Note:
##  - It is suggested to use statically if you don't need to mount anything but simply change the stat of a target path
# cat <<EOF >/dev/null
# Usage: ksu_susfs add_sus_kstat_statically </path/of/file_or_directory> \
#                         <ino> <dev> <nlink> <size> <atime> <atime_nsec> <mtime> <mtime_nsec> <ctime> <ctime_nsec> \
#                         <blocks> <blksize>
# ${SUSFS_BIN} add_sus_kstat_statically '/system/framework/services.jar' 'default' 'default' 'default' 'default' '1230768000' '0' '1230768000' '0' '1230768000' '0' 'default' 'default'
# EOF


#### Redirect path  ####
# redirect hosts file to other hosts file somewhere else #
# cat <<EOF >/dev/null
# # plesae be reminded that only process with uid < 2000 is effective #
# # and before doing that, make sure you setup proper permission and selinux for your redirected file #
# susfs_clone_perm '/data/local/tmp/my_hosts' '/system/etc/hosts'
# ${SUSFS_BIN} add_path_redirect '/system/etc/hosts' '/data/local/tmp/my_hosts'
# EOF

#### Spoof /proc/cmdline or /proc/bootconfig ####
# No root process detects it for now, and this spoofing won't help much actually #
# /proc/bootconfig #
# cat <<EOF >/dev/null
# FAKE_BOOTCONFIG=${MODDIR}/fake_bootconfig.txt
# cat /proc/bootconfig > ./fake_bootconfig.txt
# sed -i 's/^androidboot.bootreason.*$/androidboot.bootreason = "reboot"/g' ${FAKE_BOOTCONFIG}
# sed -i 's/^androidboot.vbmeta.device_state.*$/androidboot.vbmeta.device_state = "locked"/g' ${FAKE_BOOTCONFIG}
# sed -i 's/^androidboot.verifiedbootstate.*$/androidboot.verifiedbootstate = "green"/g' ${FAKE_BOOTCONFIG}
# sed -i '/androidboot.verifiedbooterror/d' ${FAKE_BOOTCONFIG}
# sed -i '/androidboot.verifyerrorpart/d' ${FAKE_BOOTCONFIG}
# ${SUSFS_BIN} set_cmdline_or_bootconfig /data/adb/modules/susfs4ksu/fake_bootconfig.txt
# EOF

# /proc/cmdline #
# cat <<EOF >/dev/null
# FAKE_PROC_CMDLINE_FILE=${MODDIR}/fake_proc_cmdline.txt
# cat /proc/cmdline > ${FAKE_PROC_CMDLINE_FILE}
# sed -i 's/androidboot.verifiedbootstate=orange/androidboot.verifiedbootstate=green/g' ${FAKE_PROC_CMDLINE_FILE}
# sed -i 's/androidboot.vbmeta.device_state=unlocked/androidboot.vbmeta.device_state=locked/g' ${FAKE_PROC_CMDLINE_FILE}
# ${SUSFS_BIN} set_cmdline_or_bootconfig ${FAKE_PROC_CMDLINE_FILE}
# EOF

if [[ $config_proc_cmdline_bootconfig_spoofing == 1 ]]; then
	susfs_variant=$(${SUSFS_BIN} show variant)

	if [[ $susfs_variant == "GKI" ]]; then
		FAKE_BOOTCONFIG=${PERSISTENT_DIR}/fake_bootconfig.txt
		
		cat /proc/bootconfig > ${FAKE_BOOTCONFIG}
		sed -i 's/androidboot.warranty_bit = "1"/androidboot.warranty_bit = "0"/' ${FAKE_BOOTCONFIG}
		sed -i 's/androidboot.verifiedbootstate = "orange"/androidboot.verifiedbootstate = "green"/' ${FAKE_BOOTCONFIG}
		${SUSFS_BIN} set_cmdline_or_bootconfig ${FAKE_BOOTCONFIG}
	else
		FAKE_CMDLINE=${PERSISTENT_DIR}/fake_cmdline.txt
		
		cat /proc/cmdline > ${FAKE_CMDLINE}
		sed -i 's/androidboot.warranty_bit=1/androidboot.warranty_bit=0/' ${FAKE_CMDLINE}
		sed -i 's/androidboot.verifiedbootstate=orange/androidboot.verifiedbootstate=green/' ${FAKE_CMDLINE}
		${SUSFS_BIN} set_cmdline_or_bootconfig ${FAKE_CMDLINE}
	fi
fi


#### Hiding the exposed /proc interface of ext4 loop and jdb2 when mounting modules.img using sus_path ####
# if [[ $config_hide_modules_img == 1 ]]; then
# 	for device in $(ls -Ld /proc/fs/jbd2/loop*8 | sed 's|/proc/fs/jbd2/||; s|-8||'); do
# 		${SUSFS_BIN} add_sus_path /proc/fs/jbd2/${device}-8
# 		${SUSFS_BIN} add_sus_path /proc/fs/ext4/${device}
# 	done
# fi


#### Enable avc log spoofing to bypass 'su' domain detection via /proc/<pid> enumeration ####
[[ $config_enable_avc_log_spoofing == 1 ]] && ${SUSFS_BIN} enable_avc_log_spoofing 1 || ${SUSFS_BIN} enable_avc_log_spoofing 0

## disable it when users want to do some debugging with the permission issue or selinux issue ##
#ksu_susfs enable_avc_log_spoofing 0


#### Hide all sus mounts for non-su processes in this stage just to prevent zygote from caching them in memory ####
## This should be mainly applied if you have ReZygisk enabled but without TreatWheel module ##
## Or it is up to you to keep it enabled since su process can still see the mounts ##
[[ $config_hide_sus_mnts_for_non_su_procs == 1 ]] && ${SUSFS_BIN} hide_sus_mnts_for_non_su_procs 1 || ${SUSFS_BIN} hide_sus_mnts_for_non_su_procs 0


echo "EOF" > "${PERSISTENT_DIR}/log.txt"
# EOF
