#!/bin/bash
##############################################################################
# 脚本名称：ngap_filter_complete.sh
# 功能描述：过滤当前目录下含"pcap"的文件，提取指定NGAP ID数据包，
#           基于输出文件大小变化判断匹配，清晰展示结果
##############################################################################

# 基础配置
OUTPUT_FILE="filtered-result.pcap"
TEMP_LOG=".ngap_filter_temp.log"
COLOR_SUCCESS="\033[32m"
COLOR_ERROR="\033[31m"
COLOR_INFO="\033[34m"
COLOR_HIGHLIGHT="\033[33m"
COLOR_RESET="\033[0m"

# 依赖工具检查
check_dependencies() {
    local missing_tools=()
    
    if ! command -v tshark &> /dev/null; then
        missing_tools+=("tshark（安装：sudo apt install tshark）")
    fi
    if ! command -v stat &> /dev/null; then
        missing_tools+=("stat")
    fi
    if ! command -v grep &> /dev/null; then
        missing_tools+=("grep")
    fi
    if ! command -v ls &> /dev/null; then
        missing_tools+=("ls")
    fi

    if [ ${#missing_tools[@]} -gt 0 ]; then
        echo -e "${COLOR_ERROR}错误：缺少必要工具，请安装：${COLOR_RESET}"
        for tool in "${missing_tools[@]}"; do
            echo "  - $tool"
        done
        exit 1
    fi
}

# 输入验证与解析
validate_and_parse_ids() {
    local input="$1"
    local id_type="$2"

    if [ "$input" = "0" ]; then
        echo ""
        return
    fi

    if ! [[ "$input" =~ ^[0-9]+(;[0-9]+)*$ ]]; then
        echo -e "${COLOR_ERROR}错误：${id_type} 格式无效！${COLOR_RESET}"
        echo -e "  正确示例：703775515860;703775525756（数字+分号分隔）"
        exit 1
    fi

    echo "$input" | tr ';' ' '
}

# 构建过滤条件
build_filter() {
    local amf_ids="$1"
    local ran_ids="$2"
    local filter=""

    if [ -n "$amf_ids" ]; then
        local amf_sub=""
        for id in $amf_ids; do
            [ -n "$amf_sub" ] && amf_sub+=" || "
            amf_sub+="ngap.AMF_UE_NGAP_ID == $id"
        done
        filter="$amf_sub"
    fi

    if [ -n "$ran_ids" ]; then
        local ran_sub=""
        for id in $ran_ids; do
            [ -n "$ran_sub" ] && ran_sub+=" || "
            ran_sub+="ngap.RAN_UE_NGAP_ID == $id"
        done
        [ -n "$filter" ] && filter+=" || "
        filter+="$ran_sub"
    fi

    echo "ngap && ($filter)"
}

# 查找PCAP文件（核心：用grep匹配含pcap的文件）
find_pcap_files() {
    # 列出当前目录所有文件（排除目录），匹配含pcap的，排除输出文件
    local all_files=$(ls -p | grep -v /)  # 排除目录
    local pcap_files=$(echo "$all_files" | grep -i "pcap")  # 匹配含pcap的文件
    if [ -n "$pcap_files" ]; then
        pcap_files=$(echo "$pcap_files" | grep -v "^$OUTPUT_FILE$")  # 排除输出文件
    fi
    echo "$pcap_files" | sort -u  # 去重
}

# 主函数
main() {
    # 初始化清理
    [ -f "$OUTPUT_FILE" ] && rm -f "$OUTPUT_FILE"
    [ -f "$TEMP_LOG" ] && rm -f "$TEMP_LOG"
    touch "$OUTPUT_FILE"

    # 检查依赖
    check_dependencies

    # 获取用户输入
    echo -e "${COLOR_INFO}===== NGAP ID 过滤工具 =====${COLOR_RESET}"
    read -p "请输入要过滤的AMF_UE_NGAP_ID（多个用分号分隔，0表示不指定）：" AMF_INPUT
    read -p "请输入要过滤的RAN_UE_NGAP_ID（多个用分号分隔，0表示不指定）：" RAN_INPUT

    # 验证输入
    echo -e "\n[1/4] 验证输入格式..."
    AMF_IDS=$(validate_and_parse_ids "$AMF_INPUT" "AMF_UE_NGAP_ID")
    RAN_IDS=$(validate_and_parse_ids "$RAN_INPUT" "RAN_UE_NGAP_ID")

    if [ -z "$AMF_IDS" ] && [ -z "$RAN_IDS" ]; then
        echo -e "${COLOR_ERROR}错误：不能同时将两个ID都设为0！${COLOR_RESET}"
        rm -f "$OUTPUT_FILE"
        exit 1
    fi

    # 构建过滤条件
    echo -e "[2/4] 构建过滤条件..."
    filter_expr=$(build_filter "$AMF_IDS" "$RAN_IDS")
    echo -e "  过滤条件：${COLOR_HIGHLIGHT}$filter_expr${COLOR_RESET}"

    # 查找PCAP文件
    echo -e "[3/4] 查找PCAP文件..."
    PCAP_FILES=$(find_pcap_files)
    pcap_count=$(echo "$PCAP_FILES" | wc -w | tr -d ' ')

    if [ "$pcap_count" -eq 0 ]; then
        echo -e "${COLOR_ERROR}警告：未找到含'pcap'的文件（已排除输出文件）${COLOR_RESET}"
        rm -f "$OUTPUT_FILE"
        exit 0
    fi

    echo -e "  找到 $pcap_count 个文件：${COLOR_HIGHLIGHT}$(echo "$PCAP_FILES" | tr '\n' ' ')${COLOR_RESET}"

    # 处理文件
    echo -e "\n[4/4] 处理文件（大小增加=匹配）："
    matched_files=()

    for file in $PCAP_FILES; do
        echo -n "  - 处理 $file ... "
        
        pre_size=$(stat -c "%s" "$OUTPUT_FILE")
        tshark -r "$file" -Y "$filter_expr" -w - >> "$OUTPUT_FILE" 2>> "$TEMP_LOG"
        post_size=$(stat -c "%s" "$OUTPUT_FILE")

        if [ "$post_size" -gt "$pre_size" ]; then
            size_inc=$((post_size - pre_size))
            echo -e "${COLOR_SUCCESS}✅ 匹配（新增：${size_inc}字节）${COLOR_RESET}"
            matched_files+=("$file")
        else
            echo -e "${COLOR_ERROR}❌ 无匹配${COLOR_RESET}"
        fi
    done

    # 结果汇总
    echo -e "\n${COLOR_INFO}===== 结果汇总 =====${COLOR_RESET}"
    final_size=$(stat -c "%s" "$OUTPUT_FILE")
    if [ "$final_size" -eq 0 ]; then
        rm -f "$OUTPUT_FILE"
        echo "1. 过滤结果：无（已清理空文件）"
    else
        echo "1. 过滤结果：$OUTPUT_FILE（大小：${final_size}字节）"
    fi

    echo -e "2. 匹配文件（共 ${#matched_files[@]} 个）："
    if [ ${#matched_files[@]} -gt 0 ]; then
        for idx in "${!matched_files[@]}"; do
            echo "   $((idx + 1)). ${matched_files[$idx]}"
        done
    else
        echo "   无匹配文件"
    fi

    # 处理日志
    if [ -f "$TEMP_LOG" ] && [ -s "$TEMP_LOG" ]; then
        echo -e "\n3. 警告：处理中有错误，详情见 $TEMP_LOG"
    else
        rm -f "$TEMP_LOG"
    fi

    echo -e "\n${COLOR_SUCCESS}处理完成！${COLOR_RESET}"
}

# 启动主函数
main
    
