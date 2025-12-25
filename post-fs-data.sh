#!/system/bin/sh
MODDIR=${0%/*}
SUSFS_BIN=/data/adb/ksu/bin/ksu_susfs

. ${MODDIR}/utils.sh

## Important Notes:
## - The following command can be run at other stages like service.sh, boot-completed.sh etc..,
## - This module is just an demo showing how to use ksu_susfs tool to commuicate with kernel
##

#### Hide target path and all its sub-paths from all user app processes which have no root permission granted ####
## Make sure the target file/directory has no more overlay/mount operation on going. Or add it after it is done being overlayed or mounted ##
# For some custom ROM #
${SUSFS_BIN} add_sus_path /system/addon.d
${SUSFS_BIN} add_sus_path /vendor/bin/install-recovery.sh
${SUSFS_BIN} add_sus_path /system/bin/install-recovery.sh
${SUSFS_BIN} add_sus_path /system/vendor/bin/install-recovery.sh


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

#### Spoof the uname ####
# you can get your uname args by running 'uname {-r|-v}' on your stock ROM #
# pass 'default' to tell susfs to use the default value by uname #
kernel_release=$(uname -r)
kernel_release="${kernel_release,,}"
kernel_release="${kernel_release/sultan/}"
kernel_release="${kernel_release/lineage/}"
kernel_release="${kernel_release/wild/}"
kernel_release="${kernel_release/ksu/}"
kernel_release="${kernel_release/sukisu/}"
kernel_release="${kernel_release/+/}"
kernel_release="${kernel_release/🟢/}"
kernel_release="${kernel_release/✅/}"
kernel_release="${kernel_release}-BRENE"
${SUSFS_BIN} set_uname "${kernel_release}" '#1 SMP PREEMPT Mon Jan 1 18:00:00 UTC 2024'


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

#### Hiding the exposed /proc interface of ext4 loop and jdb2 when mounting modules.img using sus_path ####
for device in $(ls -Ld /proc/fs/jbd2/loop*8 | sed 's|/proc/fs/jbd2/||; s|-8||'); do
	${SUSFS_BIN} add_sus_path /proc/fs/jbd2/${device}-8
	${SUSFS_BIN} add_sus_path /proc/fs/ext4/${device}
done


#### Enable avc log spoofing to bypass 'su' domain detection via /proc/<pid> enumeration ####
${SUSFS_BIN} enable_avc_log_spoofing 1

## disable it when users want to do some debugging with the permission issue or selinux issue ##
#ksu_susfs enable_avc_log_spoofing 0

# EOF
