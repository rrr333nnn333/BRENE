# shellcheck disable=SC2154
# shellcheck disable=SC2148
sleep 1

remove_directory() {
	if [[ -z "$1" ]]; then
		return 1
	fi

	local TARGET1="/storage/emulated/0/Android/data/$1"
	local TARGET2="/storage/emulated/0/Android/media/$1"
	local TARGET3="/storage/emulated/0/Android/obb/$1"
	rm -rf "${TARGET1}" "${TARGET2}" "${TARGET3}"
}

remove_directory "me.weishu.kernelsu"
remove_directory "com.rifsxd.ksunext"
remove_directory "com.resukisu.resukisu"
remove_directory "com.sukisu.ultra"
remove_directory "org.frknkrc44.hma_oss"
remove_directory "com.termux"
