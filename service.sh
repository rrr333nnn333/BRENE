MODDIR=${0%/*}
SUSFS_BIN=/data/adb/ksu/bin/susfs
PERSISTENT_DIR=/data/adb/brene
# Load config
[ -f ${PERSISTENT_DIR}/config.sh ] && . ${PERSISTENT_DIR}/config.sh

. ${MODDIR}/utils.sh

## Hexpatch prop name for newer pixel device ##
# cat <<EOF >/dev/null
# # Remember the length of search value and replace value has to be the same #
# resetprop -n "ro.boot.verifiedbooterror" "0"
# susfs_hexpatch_prop_name "ro.boot.verifiedbooterror" "verifiedbooterror" "hello_my_newworld"

# resetprop -n "ro.boot.verifyerrorpart" "true"
# susfs_hexpatch_prop_name "ro.boot.verifyerrorpart" "verifyerrorpart" "letsgopartyyeah"

# resetprop --delete "crashrecovery.rescue_boot_count"
# EOF


## Props ##
resetprop -w sys.boot_completed 0

resetprop_n "init.svc.adbd" "stopped"
resetprop_n "init.svc_debug_pid.adbd" ""
resetprop_n "persist.sys.usb.config" "mtp"
resetprop_n "sys.oem_unlock_allowed" "0"
resetprop_n "ro.adb.secure" "1"
resetprop_n "ro.crypto.state" "encrypted"
resetprop_n "ro.debuggable" "0"
resetprop_n "ro.force.debuggable" "0"
resetprop_n "ro.kernel.qemu" ""
resetprop_n "ro.secure" "1"
resetprop_n "ro.build.selinux" "1"
resetprop_n "ro.build.selinux.enforce" "1"
resetprop_n "ro.secureboot.lockstate" "locked"
resetprop_n "ro.is_ever_orange" "0"
resetprop_n "ro.bootmode" "normal"
resetprop_n "ro.bootimage.build.tags" "release-keys"

resetprop_n "ro.build.type" "user"
resetprop_n "ro.build.tags" "release-keys"

resetprop_n "vendor.boot.vbmeta.device_state" "locked"
resetprop_n "vendor.boot.verifiedbootstate" "green"

resetprop_n "ro.boot.flash.locked" "1"
resetprop_n "ro.boot.realme.lockstate" "1"
resetprop_n "ro.boot.realmebootstate" "green"
resetprop_n "ro.boot.verifiedbooterror" ""
resetprop_n "ro.boot.verifiedbootstate" "green"
resetprop_n "ro.boot.veritymode" "enforcing"
resetprop_n "ro.boot.veritymode.managed" "yes"

resetprop_n "ro.boot.vbmeta.size" "4096"
resetprop_n "ro.boot.vbmeta.hash_alg" "sha256"
resetprop_n "ro.boot.vbmeta.avb_version" "1.3"
resetprop_n "ro.boot.vbmeta.device_state" "locked"
resetprop_n "ro.boot.vbmeta.invalidate_on_error" "yes"

if_prop_value_exits_resetprop_n "ro.warranty_bit" "0"
if_prop_value_exits_resetprop_n "ro.vendor.boot.warranty_bit" "0"
if_prop_value_exits_resetprop_n "ro.vendor.warranty_bit" "0"
if_prop_value_exits_resetprop_n "ro.boot.warranty_bit" "0"

fingerprint=$(resetprop ro.build.fingerprint)
resetprop_n "ro.build.fingerprint" "${fingerprint//userdebug/user}"

resetprop -c 2>/dev/null || true

echo "EOF" >> "${PERSISTENT_DIR}/log.txt"
# EOF
