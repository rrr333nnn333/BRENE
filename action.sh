#!/system/bin/sh

PACKAGES="com.resukisu.resukisu com.sukisu.ultra"
CONFIG_FILE="shared_prefs/susfs_config.xml"
TARGET_DIR="/data/adb/brene"

BLOCKS="sus_loop_paths:custom_sus_path_loop.txt
sus_paths:custom_sus_path.txt
sus_maps:custom_sus_map.txt"

FOUND=""
for pkg in $PACKAGES; do
    FILE_PATH="/data/user/0/$pkg/$CONFIG_FILE"
    if [ -f "$FILE_PATH" ]; then
        FOUND="$FILE_PATH"
        break
    fi
done

if [ -z "$FOUND" ]; then
    echo "错误：未找到 susfs_config.xml"
    echo "Error: susfs_config.xml not found"
    exit 1
fi

echo "作者：Guxin12"
echo "Author: Guxin12"

echo "使用配置文件：$FOUND"
echo "Using config file: $FOUND"

mkdir -p "$TARGET_DIR" || {
    echo "错误：无法创建 $TARGET_DIR"
    echo "Error: cannot create $TARGET_DIR"
    exit 1
}

echo "$BLOCKS" | while IFS=':' read -r block_name out_file; do
    [ -z "$block_name" ] && continue
    TARGET_FILE="$TARGET_DIR/$out_file"

    BLOCK=$(sed -n "/<set name=\"$block_name\"/,/<\/set>/p" "$FOUND")
    if [ -z "$BLOCK" ]; then
        continue
    fi

    EXTRACTED=$(echo "$BLOCK" | grep -oE '<string[^>]*>[^<]*</string>' | sed -E 's/<\/?string[^>]*>//g')
    if [ -z "$EXTRACTED" ]; then
        continue
    fi

    touch "$TARGET_FILE" 2>/dev/null

    while IFS= read -r path; do
        [ -z "$path" ] && continue
        if grep -qxF "$path" "$TARGET_FILE" 2>/dev/null; then
            echo "跳过👿 [$block_name] -> $path"
            echo "Skipped👿 [$block_name] -> $path"
        else
            echo "$path" >> "$TARGET_FILE"
            echo "添加😄 [$block_name] -> $path"
            echo "Added😄 [$block_name] -> $path"
        fi
    done <<EOF
$EXTRACTED
EOF
done

echo "处理完成"
echo "Done"
exit 0