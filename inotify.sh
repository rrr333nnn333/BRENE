TARGET="/sdcard/..5.u.S"

while true; do
	[[ -e "${TARGET}" ]] && rm -rf "${TARGET}"
	sleep 1
	[[ ! -e "${TARGET}" ]] && break
done
