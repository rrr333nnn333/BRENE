MODDIR=${0%/*}
DEST_BIN_DIR=/data/adb/ksu/bin
SUSFS_BIN=/data/adb/ksu/bin/ksu_susfs
PERSISTENT_DIR=/data/adb/brene
# Load config
[ -f ${PERSISTENT_DIR}/config.sh ] && . ${PERSISTENT_DIR}/config.sh

#### Spoof the uname ####
# you can get your uname args by running 'uname {-r|-v}' on your stock ROM #
# pass 'default' to tell susfs to use the default value by uname #
# ${SUSFS_BIN} set_uname 'default' 'default'
if [[ $config_uname_spoofing == 1 ]]; then
	kernel_release=$(uname -r | tr '[:upper:]' '[:lower:]')
	string1=$(echo ${kernel_release} | cut -d'-' -f1)
	string2=$(echo ${kernel_release} | cut -d'-' -f2)
	[[ ${string2} == android* ]] && kernel_release="${string1}-${string2}" || kernel_release="${string1}"

	kernel_release="${kernel_release/sultan/}"
	kernel_release="${kernel_release/lineage/}"
	kernel_release="${kernel_release/wild/}"
	kernel_release="${kernel_release/ksu/}"
	kernel_release="${kernel_release/sukisu/}"
	kernel_release="${kernel_release/🟢/}"
	kernel_release="${kernel_release/✅/}"
	kernel_release="${kernel_release}-BRENE-$(grep '^version=' ${MODDIR}/module.prop | cut -d'=' -f2)"
	${SUSFS_BIN} set_uname "${kernel_release}" '#1 SMP PREEMPT Mon Jan 1 18:00:00 UTC 2010'
fi








echo "EOF" >> "${PERSISTENT_DIR}/log.txt"
# EOF
