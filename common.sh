#!/system/bin/sh

SCRIPT_DIR=${0%/*}
LOGFILE="${SCRIPT_DIR}/reject_rules.log"
BAKLOG="${SCRIPT_DIR}/reject_rules.log.bak"

remove_reject_rules() {
    chain=$1
    reject_lines=$(iptables -t filter -nvL "$chain" --line-numbers 2>/dev/null | grep 'REJECT')

    if [ -z "$reject_lines" ]; then
        echo "[$(date)] $chain 链中未发现包含 REJECT 的规则" >> "$LOGFILE"
        return
    fi

    # 按行号倒序处理（避免删除后行号变动）
    echo "$reject_lines" | awk '{print $1}' | sort -nr | while read line_num; do
        if [ -n "$line_num" ] && [ "$line_num" -gt 0 ]; then
            full_rule=$(iptables -t filter -nvL "$chain" --line-numbers 2>/dev/null | \
                        awk -v ln="$line_num" '$1 == ln { sub(/^[ \t]*[0-9]+[ \t]*/, ""); print }')
            
            if [ -n "$full_rule" ]; then
                if iptables -t filter -D "$chain" "$line_num" 2>/dev/null; then
                    echo "[$(date)] 已删除 $chain 第 $line_num 行: $full_rule" >> "$LOGFILE"
                else
                    echo "[$(date)] 删除失败 $chain 第 $line_num 行: $full_rule" >> "$LOGFILE"
                fi
            else
                echo "[$(date)] 警告：$chain 第 $line_num 行规则已不存在（可能已被其他进程删除）" >> "$LOGFILE"
            fi
        fi
    done
}
