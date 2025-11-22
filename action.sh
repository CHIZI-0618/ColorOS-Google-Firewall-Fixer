#!/system/bin/sh

SCRIPT_DIR=${0%/*}

source ${SCRIPT_DIR}/common.sh

echo "[$(date)] 手动处理防火墙规则..." >> "$LOGFILE"

remove_reject_rules "fw_INPUT"

remove_reject_rules "fw_OUTPUT"

echo "[$(date)] 防火墙规则手动处理完成" >> "$LOGFILE"
