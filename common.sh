#!/system/bin/sh

SCRIPT_DIR=${0%/*}
LOGFILE="${SCRIPT_DIR}/reject_rules.log"
BAKLOG="${SCRIPT_DIR}/reject_rules.log.bak"

remove_reject_rules() {
    chain=$1

    rules=$(iptables -t filter -nvL "$chain" --line-numbers 2>/dev/null | grep 'REJECT')
    
    if [ -z "$rules" ]; then
        echo "$chain 链中未发现包含REJECT的规则" >> "$LOGFILE"
        return
    fi
    
    # 提取行号并倒序排序
    echo "$rules" | awk '{print $1}' | sort -nr | while read -r line_num; do
        if [ -n "$line_num" ] && [ "$line_num" -gt 0 ]; then
            if iptables -t filter -D "$chain" "$line_num" 2>/dev/null; then
                echo "[$(date)] 已删除 $chain 链第 $line_num 行的REJECT规则" >> "$LOGFILE"
            else
                echo "[$(date)] 删除 $chain 链第 $line_num 行规则失败" >> "$LOGFILE"
            fi
        fi
    done
}
