TARGET="/sdcard/..5.u.S"

while true; do
	rm -rf "${TARGET}"
	sleep 1
	if [[ ! -e "${TARGET}" ]]; then
		break
	fi
done
