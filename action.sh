#!/system/bin/sh

SCRIPT_DIR=${0%/*}

. ${SCRIPT_DIR}/common.sh

chains="fw_INPUT fw_OUTPUT fw_OUTPUT_oplus_dns zte_fw_gms"

echo "[$(date)] 开始手动清理 IPv4 和 IPv6 中的 REJECT 规则..." >> "$LOGFILE"

for chain in $chains; do
    remove_block_rules "filter" "$chain" "ipv4"
    remove_block_rules "filter" "$chain" "ipv6"
done

echo "[$(date)] 手动清理完成" >> "$LOGFILE"
