PATH=/data/adb/ksu/bin:$PATH

## susfs_clone_perm <file/or/dir/perm/to/be/changed> <file/or/dir/to/clone/from>
susfs_clone_perm() {
	TO=$1
	FROM=$2
	if [ -z "${TO}" -o -z "${FROM}" ]; then
		return
	fi
	## stat https://github.com/backslashxx/bindhosts/commit/427f18fe0b212ef2754e79c8aaaa72cb59ad253d#diff-8cb0da3b1680ce3a9f3263622042aa6f0250431fa5069513664650a17c48fdabR15
	CLONED_PERM_STRING=$(stat -c "%a %U %G" ${FROM})
	set ${CLONED_PERM_STRING}
	chmod $1 ${TO}
	chown $2:$3 ${TO}
	busybox chcon --reference=${FROM} ${TO}
}

# USAGE: susfs_hexpatch_prop_name <prop name> <search value> <replace value>
#
#        <search value> and <replace value> must have the same length
# Credit: 
#   osm0sis - https://github.com/osm0sis/PlayIntegrityFork/blob/main/module/common_func.sh
#   changhuapeng - https://github.com/changhuapeng for making LOSPropsGoAway
susfs_hexpatch_prop_name() {
	local NAME="$1"
	local CURVALUE="$2"
	local NEWVALUE="$3"
	[ ${#CURVALUE} -ne ${#NEWVALUE} ] && return 1

	if [ -f /dev/__properties__ ]; then
		local PROPFILE=/dev/__properties__
	else
		local PROPFILE="/dev/__properties__/$(resetprop -Z "$NAME")"
	fi

	if [ -f "$PROPFILE" ]; then
		## need only the last node ##
		NAME=${NAME##*.}
		## Loop and remove all matched name ##
		while true; do
			local NAMEOFFSET=$(echo $(strings -t d "$PROPFILE" | grep "$NAME") | cut -d ' ' -f 1)
			## here we need to make sure the NAMEOFFSET is not empty ##
			if [ -z "${NAMEOFFSET}" ]; then
				break
			fi
			local NEWSTR=$(echo "$NAME" | sed 's/'"$CURVALUE"'/'"$NEWVALUE"'/g')
			local NAMELEN=${#NAME}
			local NEWHEX=$(printf "$NEWSTR" | od -A n -t x1 -v | tr -d ' \n')
			echo -ne $(printf "$NEWHEX" | sed -e 's/.\{2\}/&\\x/g' -e 's/^/\\x/' -e 's/\\x$//') | dd obs=1 count=$NAMELEN seek=$NAMEOFFSET conv=notrunc of="$PROPFILE"
		done
	fi
}

resetprop_n() {
	resetprop -n $1 $2
}

if_prop_value_exits_resetprop_n() {
	local PROP_NAME=$1
  local EXPECTED_VALUE=$2
  local CURRENT_VALUE=$(resetprop "${PROP_NAME}")

	[ -z "${CURRENT_VALUE}" ] || [ "${CURRENT_VALUE}" = "${EXPECTED_VALUE}" ] || resetprop -n "${PROP_NAME}" "${EXPECTED_VALUE}"
}

# if_contains_resetprop_n() {
# 	local PROP_NAME=$1
#   local CONTAINS_VALUE=$2
#   local NEW_VALUE=$3

#   [[ "$(resetprop ${PROP_NAME})" = *"${CONTAINS_VALUE}"* ]] && resetprop -n "${PROP_NAME}" "${NEW_VALUE}"
# }

# EOF
