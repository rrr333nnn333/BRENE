#!/system/bin/sh
MODDIR=${0%/*}
SUSFS_BIN=/data/adb/ksu/bin/ksu_susfs

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

## Do not hide sus mounts for all processes but only non ksu process ##
# cat <<EOF >/dev/null
# # - By default the kernel hides all sus mounts for all processes,
# #   and some rooted app may rely on mounts mounted by ksu process,
# #   so here we can make it hide for non ksu process only.
# # - Though it is still recommended to set it to 0 after screen is unlocked rathn than in service.sh
# ${SUSFS_BIN} hide_sus_mnts_for_all_procs 0
# EOF

# # Disable susfs kernel log ##
${SUSFS_BIN} enable_log 0

## Props ##
resetprop -w sys.boot_completed 0

check_missing_prop "ro.boot.vbmeta.hash_alg" "sha256"
check_missing_prop "ro.boot.vbmeta.avb_version" "1.3"
check_missing_prop "ro.boot.vbmeta.invalidate_on_error" "yes"

check_missing_match_prop "ro.boot.vbmeta.device_state" "locked"
check_missing_match_prop "ro.boot.verifiedbootstate" "green"
check_missing_match_prop "ro.boot.flash.locked" "1"
check_missing_match_prop "ro.boot.veritymode" "enforcing"
check_missing_match_prop "ro.boot.warranty_bit" "0"

check_reset_prop "vendor.boot.vbmeta.device_state" "locked"
check_reset_prop "vendor.boot.verifiedbootstate" "green"
check_reset_prop "ro.warranty_bit" "0"
check_reset_prop "ro.debuggable" "0"
check_reset_prop "ro.force.debuggable" "0"
check_reset_prop "ro.secure" "1"
check_reset_prop "ro.adb.secure" "1"
check_reset_prop "ro.build.type" "user"
check_reset_prop "ro.build.tags" "release-keys"
check_reset_prop "ro.vendor.boot.warranty_bit" "0"
check_reset_prop "ro.vendor.warranty_bit" "0"
check_reset_prop "sys.oem_unlock_allowed" "0"
check_reset_prop "ro.boot.verifiedbooterror" "0"
check_reset_prop "ro.secureboot.lockstate" "locked"
check_reset_prop "ro.crypto.state" "encrypted"

# Realme
check_reset_prop "ro.boot.realme.lockstate" "1"
check_reset_prop "ro.boot.realmebootstate" "green"

# Hide that we booted from recovery when magisk is in recovery mode
contains_reset_prop "ro.bootmode" "recovery" "unknown"
contains_reset_prop "ro.boot.bootmode" "recovery" "unknown"
contains_reset_prop "vendor.boot.bootmode" "recovery" "unknown"

# Hide cloudphone detection
[ -n "$(resetprop ro.kernel.qemu)" ] && resetprop ro.kernel.qemu ""

# EOF
