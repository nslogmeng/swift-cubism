#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$SCRIPT_DIR/.."

SRC_DIR="$PROJECT_ROOT/Sources/CubismFramework/src"
INCLUDE_DIR="$PROJECT_ROOT/Sources/CubismFramework/include"

# 配置要生成的渲染类型
RENDER_TYPE="Metal"

echo "==> 清理旧的 include 目录"
rm -rf "$INCLUDE_DIR"
mkdir -p "$INCLUDE_DIR"

echo "==> 生成头文件软链接到 include/"

# 遍历 src 下所有 .h/.hpp 文件
find "$SRC_DIR" -type f \( -name "*.h" -o -name "*.hpp" \) | while read -r file; do
    rel_path="${file#$SRC_DIR/}"

    # 判断是否属于渲染类型目录
    if [[ "$rel_path" == Rendering/* ]]; then
        # 如果不属于指定的渲染类型，跳过
        if [[ "$rel_path" != "Rendering/$RENDER_TYPE"* ]]; then
            continue
        fi
    fi

    # 创建目标目录
    dest_dir="$INCLUDE_DIR/$(dirname "$rel_path")"
    mkdir -p "$dest_dir"

    # 创建软链接
    ln -sf "$file" "$dest_dir/$(basename "$file")"
    echo "Linked $dest_dir/$(basename "$file") -> $file"
done

echo "==> 完成，public headers 已生成在 $INCLUDE_DIR"
