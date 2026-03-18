MODDIR=${0%/*}
DEST_BIN_DIR=/data/adb/ksu/bin
KSU_BIN=/data/adb/ksu/bin/ksud
SUSFS_BIN=/data/adb/ksu/bin/susfs
PERSISTENT_DIR=/data/adb/brene
# Load config
[ -f ${PERSISTENT_DIR}/config.sh ] && . ${PERSISTENT_DIR}/config.sh

#### Spoof the uname, effective for all processes ####
# you can get your uname args by running 'uname {-r|-v}' on your stock ROM #
# pass 'default' to tell susfs to use the default value by uname #
# ${SUSFS_BIN} set_uname 'default' 'default'
if [[ $config_custom_uname_spoofing == 1 ]]; then
	${SUSFS_BIN} set_uname "${config_custom_uname_kernel_release}" "${config_custom_uname_kernel_version}"
elif [[ $config_uname_spoofing == 1 ]]; then
	kernel_version=$(uname -r | cut -d'-' -f1)
	android_release=$(${KSU_BIN} boot-info current-kmi | cut -d'-' -f1)
	${SUSFS_BIN} set_uname "${kernel_version}-${android_release}-9-g690101101069" "#1 SMP PREEMPT $(resetprop ro.build.date)"
fi


echo "EOF" >> "${PERSISTENT_DIR}/log.txt"
# EOF
