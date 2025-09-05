#!/bin/bash

# 批量过滤多个pcap文件中特定NGAP ID的报文并合并结果
# 使用方法：chmod +x filter_ngap_pcaps.sh && ./filter_ngap_pcaps.sh

# 配置参数
INPUT_FILES="amf.pcap*"  # 匹配所有以amf.pcap开头的文件，可根据需要修改
OUTPUT_FILE="filtered_ngap_result.pcap"  # 输出文件名称
TARGET_NGAP_ID="901599545869"  # 目标AMF UE NGAP ID，可根据需要修改

# 检查tshark是否安装
if ! command -v tshark &> /dev/null; then
    echo "错误：未找到tshark命令，请先安装Wireshark工具包"
    exit 1
fi

# 清除已有输出文件（避免追加到旧文件）
> "$OUTPUT_FILE"

# 统计符合条件的文件数量
file_count=$(ls -1 $INPUT_FILES 2>/dev/null | wc -l)
if [ $file_count -eq 0 ]; then
    echo "警告：未找到符合'$INPUT_FILES'模式的pcap文件"
    exit 1
fi

echo "找到$file_count个pcap文件，开始过滤处理..."
echo "目标NGAP ID: $TARGET_NGAP_ID"
echo "输出文件: $OUTPUT_FILE"

# 循环处理每个pcap文件
count=1
for file in $INPUT_FILES; do
    echo "正在处理第$count/$file_count个文件: $file"
    
    # 过滤并追加到输出文件
    tshark -r "$file" \
           -Y "ngap && ngap.AMF_UE_NGAP_ID == $TARGET_NGAP_ID" \
           -w - >> "$OUTPUT_FILE"
    
    # 检查上一条命令是否执行成功
    if [ $? -ne 0 ]; then
        echo "警告：处理文件$file时出现错误，已跳过"
    fi
    
    count=$((count + 1))
done

echo "处理完成！"
echo "已将所有符合条件的报文保存到: $OUTPUT_FILE"
echo "文件大小: $(du -h "$OUTPUT_FILE" | awk '{print $1}')"

