#!/system/bin/sh

until [ $(getprop sys.boot_completed) -eq 1 ]; do
    sleep 2
done

# 不做检测函数，等待一分钟，等待系统完整加载默认 iptables 规则
sleep 60

SCRIPT_DIR=${0%/*}

source ${SCRIPT_DIR}/common.sh

if [ -f "$LOGFILE" ]; then
    cp -f "$LOGFILE" "$BAKLOG"
    echo "[$(date)] 日志已备份，开始新日志记录" > "$LOGFILE"
else
    echo "[$(date)] 日志开始记录" > "$LOGFILE"
fi

chains="fw_INPUT fw_OUTPUT"

echo "[$(date)] 开始清理 IPv4 和 IPv6 中的 REJECT 规则..." >> "$LOGFILE"

for chain in $chains; do
    remove_reject_rules "filter" "$chain" "ipv4"
    remove_reject_rules "filter" "$chain" "ipv6"
done

echo "[$(date)] 清理完成" >> "$LOGFILE"
