# shellcheck shell=ash

if [ "$KSU" = "true" ] || ! command -v ui_print >/dev/null 2>&1; then
  ui_print() {
    echo "$1"
  }
  abort() {
    ui_print "Error: $1"
    exit 1
  }
fi

ui_print "正在安装 OpenList Magisk 模块..."

# 检测设备架构
ARCH=$(getprop ro.product.cpu.abi)
ui_print "检测到架构: $ARCH"

# 定义二进制文件名
BINARY_NAME="openlist"

# Code from NGA SDK (https://github.com/TianwanTW/NGA-SDK/blob/nga/src/shell/nga-utils.sh)
until_key() {
    local eventCode
    while :; do
        eventCode=$(getevent -qlc 1 | awk '{if ($2=="EV_KEY" && $4=="DOWN") {print $3; exit}}')
        case "$eventCode" in
        KEY_VOLUMEUP)
            printf up
            return
            ;;
        KEY_VOLUMEDOWN)
            printf down
            return
            ;;
        KEY_POWER)
            echo -n power
            return
            ;;
        KEY_F[1-9] | KEY_F1[0-9] | KEY_F2[0-4])
            echo -n "$eventCode" | sed 's/KEY_F/f/g'
            return
            ;;
        esac
    done
}

# 显示菜单选项
show_binary_menu() {
    local current=$1
    ui_print " "
    ui_print "📂 选择安装位置 (默认: 1)"
    ui_print "1、data/adb/openlist/bin"
    ui_print "2、$MODDIR/bin"
    ui_print "3、$MODDIR/system/bin"
    ui_print "━━━━━━━━━━━━━━━━━━━━━━"
    ui_print "音量+ 确认  |  音量- 切换"
    ui_print "━━━━━━━━━━━━━━━━━━━━━━"
    ui_print "👉 当前选择：选项 $current"
}

show_data_menu() {
    local current=$1
    ui_print " "
    ui_print "📁 选择数据目录 (默认: 1)"
    ui_print "1、data/adb/openlist"
    ui_print "2、Android/openlist"
    ui_print "━━━━━━━━━━━━━━━━━━━━━━"
    ui_print "音量+ 确认  |  音量- 切换"
    ui_print "━━━━━━━━━━━━━━━━━━━━━━"
    ui_print "👉 当前选择：选项 $current"
}

show_password_menu() {
    local current=$1
    ui_print " "
    ui_print "🔐 初始密码设置 (默认: 1)"
    ui_print "询问是否修改初始密码为admin？"
    ui_print "（后续请到管理面板自行修改）"
    ui_print "1、不修改"
    ui_print "2、修改"
    ui_print "━━━━━━━━━━━━━━━━━━━━━━"
    ui_print "音量+ 确认  |  音量- 切换"
    ui_print "━━━━━━━━━━━━━━━━━━━━━━"
    ui_print "👉 当前选择：选项 $current"
}

# 选择函数 with timeout
make_selection() {
    local menu_type="$1"
    local max_options="$2"
    local default_option=1 # Default option is always 1
    local current=$default_option

    # Display initial menu
    case "$menu_type" in
        "binary") show_binary_menu "$current" ;;
        "data") show_data_menu "$current" ;;
        "password") show_password_menu "$current" ;;
    esac

    local key_input=""
    local countdown=10

    ui_print " "
    ui_print "将在 $countdown 秒后自动选择默认选项 (选项 $default_option)..."

    # Use a temporary file for IPC between background process and this script
    local KEY_FILE="/data/local/tmp/key_input.$$"
    rm -f "$KEY_FILE"

    # Start the key listener in the background. It will write 'up' or 'down' to the file and exit.
    ( until_key > "$KEY_FILE" ) &
    local listener_pid=$!

    # Wait for up to 10 seconds, checking for the result file each second
    while [ $countdown -gt 0 ]; do
        if [ -s "$KEY_FILE" ]; then
            # File has content, meaning a key was pressed
            key_input=$(cat "$KEY_FILE")
            break
        fi
        sleep 1
        countdown=$((countdown - 1))
    done

    # Cleanup: kill the listener process and remove the temp file
    # This ensures no stray processes are left.
    kill $listener_pid 2>/dev/null
    wait $listener_pid 2>/dev/null
    rm -f "$KEY_FILE"

    # If key_input is still empty, it means we timed out
    if [ -z "$key_input" ]; then
        ui_print "⌛️ 超时，自动选择默认选项 $default_option"
        return $default_option
    fi

    # A key was pressed. Enter the interactive selection loop.
    # The first key press is already in $key_input.
    ui_print " "
    ui_print "已检测到按键，进入手动选择模式。"
    while true; do
        case "$key_input" in
            "up")
                ui_print "✅ 已确认选项 $current"
                return $current
                ;;
            "down")
                current=$((current + 1))
                [ $current -gt $max_options ] && current=1
                # Show the menu again with the updated selection
                case "$menu_type" in
                    "binary") show_binary_menu "$current" ;;
                    "data") show_data_menu "$current" ;;
                    "password") show_password_menu "$current" ;;
                esac
                ;;
        esac
        # Wait for the next key press (blocking)
        key_input=$(until_key)
    done
}


# 安装流程开始
ui_print "⚙️ 开始配置..."

# 选择二进制安装路径
make_selection "binary" "3"
INSTALL_OPTION=$?

# 定义安装路径和service.sh中的路径
case $INSTALL_OPTION in
    1)
        BINARY_PATH="/data/adb/openlist/bin"
        BINARY_SERVICE_PATH="/data/adb/openlist/bin/openlist"  # 绝对路径
        ;;
    2)
        BINARY_PATH="$MODPATH/bin"
        BINARY_SERVICE_PATH="\$MODDIR/bin/openlist"  # 使用 MODDIR 变量
        ;;
    3)
        BINARY_PATH="$MODPATH/system/bin"
        BINARY_SERVICE_PATH="\$MODDIR/system/bin/openlist"  # 使用 MODDIR 变量
        ;;
esac

# 创建安装目录
mkdir -p "$BINARY_PATH"

# 安装二进制文件
if echo "$ARCH" | grep -q "arm64"; then
    ui_print "📦 安装 ARM64 版本..."
    if [ -f "$MODPATH/openlist-arm64" ]; then
        mv "$MODPATH/openlist-arm64" "$BINARY_PATH/$BINARY_NAME"
        rm -f "$MODPATH/openlist-arm"
    else
        abort "❌ 错误：未找到 ARM64 版本文件"
    fi
else
    ui_print "📦 安装 ARM 版本..."
    if [ -f "$MODPATH/openlist-arm" ]; then
        mv "$MODPATH/openlist-arm" "$BINARY_PATH/$BINARY_NAME"
        rm -f "$MODPATH/openlist-arm64"
    else
        abort "❌ 错误：未找到 ARM 版本文件"
    fi
fi

chmod 755 "$BINARY_PATH/$BINARY_NAME"

[ "$BINARY_PATH" = "$MODPATH/system/bin" ] && chcon -R u:object_r:system_file:s0 "$BINARY_PATH/$BINARY_NAME"

# 选择数据目录
make_selection "data" "2"
DATA_DIR_OPTION=$?

case $DATA_DIR_OPTION in
    1) DATA_DIR="/data/adb/openlist" ;;
    2) DATA_DIR="/sdcard/Android/openlist" ;;
esac

# 数据迁移提示
ui_print " "
ui_print "📢 数据目录设置"
ui_print "━━━━━━━━━━━━━━━━━━━━━━"
ui_print "✓ 已选择: $DATA_DIR"
ui_print "⚠️ 注意事项："
ui_print "1. 新数据目录将在重启后生效"
ui_print "2. 请手动将现有数据迁移到新目录"
ui_print "3. 迁移后更新 config.json 中的路径"
ui_print "━━━━━━━━━━━━━━━━━━━━━━"

# 更新 service.sh
if [ -f "$MODPATH/service.sh" ]; then
    # 仅替换占位符，保留其他所有内容
    sed -i "s|^DATA_DIR=.*|DATA_DIR=\"$DATA_DIR\"|" "$MODPATH/service.sh"
    sed -i "s|^OPENLIST_BINARY=.*|OPENLIST_BINARY=\"$BINARY_SERVICE_PATH\"|" "$MODPATH/service.sh"

    # 验证更新是否成功
    if grep -q "^OPENLIST_BINARY=\"$BINARY_SERVICE_PATH\"" "$MODPATH/service.sh" && \
       grep -q "^DATA_DIR=\"$DATA_DIR\"" "$MODPATH/service.sh"; then
        ui_print "✅ 配置更新成功"
    else
        abort "❌ 配置更新失败"
    fi
else
    abort "❌ 错误：未找到 service.sh"
fi

# 完成安装
ui_print " "
ui_print "✨ 安装完成"
ui_print "━━━━━━━━━━━━━━━━━━━━━━"
ui_print "📍 二进制: $BINARY_PATH/$BINARY_NAME"
ui_print "📁 数据目录: $DATA_DIR"

# 选择是否修改密码
make_selection "password" "2"
PASSWORD_OPTION=$?

if [ "$PASSWORD_OPTION" = "2" ]; then
    ui_print " "
    ui_print "🔄 正在修改初始密码..."

    # 使用绝对路径执行命令
    COMMAND_SUCCESS=0
    case $INSTALL_OPTION in
        1)
            # 二进制文件在 /data/adb/openlist/bin
            /data/adb/openlist/bin/openlist admin set admin --data "$DATA_DIR"
            COMMAND_SUCCESS=$?
            ;;
        2)
            # 二进制文件在$MODDIR/bin
            "$MODPATH/bin/openlist" admin set admin --data "$DATA_DIR"
            COMMAND_SUCCESS=$?
            ;;
        3)
            # 二进制文件在 $MODDIR/system/bin/
            "$MODPATH/system/bin/openlist" admin set admin --data "$DATA_DIR"
            COMMAND_SUCCESS=$?
            ;;
    esac

    if [ $COMMAND_SUCCESS -eq 0 ]; then
        ui_print "✅ 密码已修改为：admin"

        # 确保数据目录存在
        mkdir -p "$DATA_DIR"

        # 写入密码到初始密码.txt
        if echo "admin" > "$DATA_DIR/初始密码.txt"; then
            ui_print "✅ 已将密码保存到：$DATA_DIR/初始密码.txt"
        else
            ui_print "❌ 密码文件写入失败"
        fi
    else
        ui_print "❌ 密码修改失败"
    fi
else
    ui_print "✓ 跳过密码修改"
fi

ui_print " "
ui_print "👋 安装完成，请重启设备"
ui_print "━━━━━━━━━━━━━━━━━━━━━━"
