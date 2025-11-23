#!/system/bin/sh

SCRIPT_DIR=${0%/*}
LOGFILE="${SCRIPT_DIR}/reject_rules.log"
BAKLOG="${SCRIPT_DIR}/reject_rules.log.bak"

remove_reject_rules() {
    table=$1 # "filter"
    chain=$2 # "fw_INPUT" / "fw_OUTPUT"
    proto=$3 # "ipv4" or "ipv6"

    case "$proto" in
        ipv4)
            cmd="iptables"
            ;;
        ipv6)
            cmd="ip6tables"
            ;;
    esac

    if ! command -v "$cmd" > /dev/null 2>&1; then
        echo "[$(date)] 跳过 $proto：$cmd 命令不存在" >> "$LOGFILE"
        return 0
    fi

    reject_lines=$($cmd -t "$table" -nvL "$chain" --line-numbers 2> /dev/null | grep 'REJECT')

    if [ -z "$reject_lines" ]; then
        echo "[$(date)] $proto: $chain 链中未发现包含 REJECT 的规则" >> "$LOGFILE"
        return 0
    fi

    echo "$reject_lines" | awk '{print $1}' | sort -nr | while read -r line_num; do
        if [ -n "$line_num" ] && [ "$line_num" -gt 0 ]; then
            full_rule=$($cmd -t "$table" -nvL "$chain" --line-numbers 2> /dev/null \
                | awk -v ln="$line_num" '$1 == ln { sub(/^[ \t]*[0-9]+[ \t]*/, ""); print }')

            if [ -n "$full_rule" ]; then
                if $cmd -t "$table" -D "$chain" "$line_num" 2> /dev/null; then
                    echo "[$(date)] 已删除 ($proto) $chain 第 $line_num 行: $full_rule" >> "$LOGFILE"
                else
                    echo "[$(date)] 删除失败 ($proto) $chain 第 $line_num 行: $full_rule" >> "$LOGFILE"
                fi
            else
                echo "[$(date)] 警告：($proto) $chain 第 $line_num 行规则已不存在" >> "$LOGFILE"
            fi
        fi
    done
}
