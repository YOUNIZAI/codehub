#!/bin/bash
## 脚本作用: 过滤当前目录下面*pcap* 文件 匹配特定NGAP ID（动态输入), 并输出合并到一个文件
# 定义输出文件
OUTPUT_FILE="filtered-result.pcap"

# 检查tshark是否安装
if ! command -v tshark &> /dev/null; then
    echo "错误: tshark未安装，请先安装tshark"
    exit 1
fi

# 提示用户输入NGAP ID
read -p "请输入要过滤的NGAP ID: " NGAP_ID

# 验证输入是否为空
if [ -z "$NGAP_ID" ]; then
    echo "错误: NGAP ID不能为空"
    exit 1
fi

# 验证输入是否为数字
if ! [[ "$NGAP_ID" =~ ^[0-9]+$ ]]; then
    echo "错误: NGAP ID必须是数字"
    exit 1
fi

# 检查并删除已存在的输出文件
if [ -f "$OUTPUT_FILE" ]; then
    echo "发现已存在的输出文件，正在删除..."
    rm -f "$OUTPUT_FILE"
fi

# 遍历当前目录下所有.pcap文件，排除输出文件本身
echo "正在查找当前目录下的pcap文件..."
PCAP_FILES=$(find . -maxdepth 1 -type f -name "*.pcap*" ! -name "$OUTPUT_FILE" -print0 | xargs -0)

# 检查是否找到pcap文件
if [ -z "$PCAP_FILES" ]; then
    echo "警告: 未在当前目录找到任何.pcap文件"
    exit 0
fi

# 循环处理每个pcap文件
for file in $PCAP_FILES; do
    file=$(basename "$file")
    echo "正在处理文件: $file"
    tshark -r "$file" -Y "ngap && ngap.AMF_UE_NGAP_ID == $NGAP_ID" -w - >> "$OUTPUT_FILE"
done

echo "处理完成，结果已保存到: $OUTPUT_FILE"
    

    
