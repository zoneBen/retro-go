#!/bin/bash
# 快速构建脚本 - 仅构建 launcher（测试用）
# 作者：mrcong

set -e

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TARGET="xiaomiao"

echo "=========================================="
echo "  快速构建：仅 Launcher"
echo "=========================================="
echo ""

cd "$PROJECT_ROOT"

# 检查 Docker 镜像
if ! docker image inspect thingsflow-esp-builder:v5.5.1 > /dev/null 2>&1; then
    echo "❌ Docker 镜像不存在！"
    exit 1
fi

echo "🐳 Docker 构建 Launcher..."

docker run --rm \
    -v "$PROJECT_ROOT:/home/esp/workspace" \
    thingsflow-esp-builder:v5.5.1 \
    /bin/bash -c '
        set -e
        source /opt/esp/esp-idf/export.sh
        cd /home/esp/workspace

        echo "步骤 1: 清理..."
        python3 rg_tool.py --target xiaomiao clean launcher
        echo ""

        echo "步骤 2: 构建 Launcher..."
        python3 rg_tool.py --target xiaomiao build launcher
        echo ""

        echo "✅ Launcher 构建完成！"
        ls -lh launcher/build/
    '

echo ""
if [ -f "$PROJECT_ROOT/launcher/build/launcher.bin" ]; then
    echo "🎉 成功！"
    echo "文件位置: $PROJECT_ROOT/launcher/build/launcher.bin"
    ls -lh "$PROJECT_ROOT/launcher/build/"
else
    echo "⚠️  未找到 launcher.bin"
fi
