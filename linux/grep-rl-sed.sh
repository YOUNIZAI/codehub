#!/usr/bin/env bash
set -euo pipefail

usage() {
  echo "用法: $0 <src> <dst> [dir]"
  echo "示例: $0 old new ./"
}

if [[ ${1-} == "" || ${2-} == "" ]]; then
  usage
  exit 1
fi

srcStr=$1
dstStr=$2
filedir=${3:-./}

if [[ ! -d "$filedir" ]]; then
  echo "错误: 目录不存在 -> $filedir" >&2
  exit 1
fi

# 使用 ripgrep 列出匹配文件，避免 grep -rl 的边界与性能问题
mapfile -t files < <(rg -I -l --fixed-strings -- "$srcStr" "$filedir" || true)

if [[ ${#files[@]} -eq 0 ]]; then
  echo "未找到包含目标字符串的文件: $srcStr"
  exit 0
fi

# 逐个文件安全替换，使用 Python 做字节级安全替换，避免 sed 转义坑
for f in "${files[@]}"; do
  if [[ -f "$f" ]]; then
    python3 - "$srcStr" "$dstStr" "$f" <<'PY'
import sys
src, dst, path = sys.argv[1], sys.argv[2], sys.argv[3]
with open(path, 'rb') as fh:
    data = fh.read()
new = data.replace(src.encode('utf-8'), dst.encode('utf-8'))
if new != data:
    with open(path, 'wb') as fh:
        fh.write(new)
PY
  fi
done

echo "完成: 将 '$srcStr' 替换为 '$dstStr' 于目录 '$filedir'"
