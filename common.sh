#!/system/bin/sh

SCRIPT_DIR=${0%/*}
LOGFILE="${SCRIPT_DIR}/reject_rules.log"
BAKLOG="${SCRIPT_DIR}/reject_rules.log.bak"

remove_block_rules() {
    local table="${1:-filter}"
    local chain="$2"
    local proto="${3:-ipv4}" # ipv4 或 ipv6

    local cmd=""
    case "$proto" in
        ipv4)
            cmd="iptables"
            ;;
        ipv6)
            cmd="ip6tables"
            ;;
        *)
            echo "[$(date)] 错误：不支持的协议 $proto" >> "$LOGFILE"
            return 1
            ;;
    esac

    if ! command -v "$cmd" > /dev/null 2>&1; then
        echo "[$(date)] 跳过 $proto：$cmd 命令不存在" >> "$LOGFILE"
        return 0
    fi

    # 获取所有包含 REJECT 或 DROP 的行号（从大到小排序，保证删除时行号不乱）
    local line_numbers
    line_numbers=$(
        $cmd -t "$table" -nvL "$chain" --line-numbers 2> /dev/null \
            | awk '/REJECT|DROP/ {print $1}' \
            | sort -rn
    )

    if [ -z "$line_numbers" ]; then
        echo "[$(date)] $proto: $chain 链中未发现 REJECT/DROP 规则" >> "$LOGFILE"
        return 0
    fi

    local deleted_count=0
    for line_num in $line_numbers; do
        # 获取要删除的规则内容（用于日志）
        local full_rule
        full_rule=$(
            $cmd -t "$table" -nvL "$chain" --line-numbers 2> /dev/null \
                | awk -v ln="$line_num" '
                $1 == ln {
                    sub(/^[ \t]*[0-9]+[ \t]+/, "");
                    print
                }
            '
        )

        if $cmd -t "$table" -D "$chain" "$line_num" 2> /dev/null; then
            echo "[$(date)] 已删除 ($proto) $chain 第 ${line_num} 行: ${full_rule:-REJECT/DROP规则}" >> "$LOGFILE"
            deleted_count=$((deleted_count + 1))
        else
            echo "[$(date)] 删除失败 ($proto) $chain 第 ${line_num} 行" >> "$LOGFILE"
        fi
    done

    echo "[$(date)] $proto: $chain 链共删除 ${deleted_count} 条 REJECT/DROP 规则" >> "$LOGFILE"
}
