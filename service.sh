MODDIR=${0%/*}
SUSFS_BIN=/data/adb/ksu/bin/ksu_susfs
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


# # Disable susfs kernel log ##
[[ $config_enable_log == 1 ]] && ${SUSFS_BIN} enable_log 1 || ${SUSFS_BIN} enable_log 0


echo "EOF" >> "${PERSISTENT_DIR}/log.txt"
# EOF
