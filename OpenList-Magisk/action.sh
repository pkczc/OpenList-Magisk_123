#!/system/bin/sh
# shellcheck shell=ash
# action.sh for OpenList Magisk Module

MODDIR="${0%/*}"
MODULE_PROP="$MODDIR/module.prop"
SERVICE_SH="$MODDIR/service.sh"
REPO_URL="https://github.com/pkczc/OpenList-Magisk_123"

check_openlist_status() {
    if pgrep -f openlist >/dev/null; then
        return 0
    else
        return 1
    fi
}

update_module_prop_stopped() {
    sed -i "s|^description=.*|description=【已停止】请点击\"操作\"启动程序。项目地址：${REPO_URL}|" "$MODULE_PROP"
}

if check_openlist_status; then
    pkill -f openlist
    sleep 1
    if check_openlist_status; then
        echo "无法停止 OpenList 服务"
        exit 1
    else
        echo "OpenList 服务已停止"
        update_module_prop_stopped
    fi
else
    if [ -f "$SERVICE_SH" ]; then
        sh "$SERVICE_SH"
        sleep 1
        if check_openlist_status; then
            echo "OpenList 服务启动成功"
        else
            echo "无法启动 OpenList 服务"
            exit 1
        fi
    else
        echo "错误：service.sh 不存在"
        exit 1
    fi
fi