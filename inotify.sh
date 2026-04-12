#!/bin/bash
TARGET="..5.u.S"
TARGET1="/sdcard/${TARGET}"
TARGET2="/sdcard/Android/data/${TARGET}"
TARGET3="/sdcard/Android/media/${TARGET}"
TARGET4="/sdcard/Android/obb/${TARGET}"

while true; do
  [[ -e "${TARGET1}" ]] && rm -rf "${TARGET1}"
  [[ -e "${TARGET2}" ]] && rm -rf "${TARGET2}"
  [[ -e "${TARGET3}" ]] && rm -rf "${TARGET3}"
  [[ -e "${TARGET4}" ]] && rm -rf "${TARGET4}"

  sleep 1

  [[ ! -e "${TARGET1}" ]] && break
  [[ ! -e "${TARGET2}" ]] && break
  [[ ! -e "${TARGET3}" ]] && break
  [[ ! -e "${TARGET4}" ]] && break
done
