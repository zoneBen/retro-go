#!/bin/bash
# 简单测试脚本 - 仅构建 launcher 进行测试
# 作者：mrcong

set -e

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "=========================================="
echo "  测试构建：仅 Launcher"
echo "=========================================="
echo ""

cd "$PROJECT_ROOT"

# 清理
echo "🧹 清理..."
rm -rf build launcher/build launcher/sdkconfig launcher/sdkconfig.old retro-go_*.img

# 检查 Docker 镜像
if ! docker image inspect thingsflow-esp-builder:v5.5.1 > /dev/null 2>&1; then
    echo "❌ Docker 镜像不存在！"
    exit 1
fi

echo "🐳 Docker 构建 Launcher..."

docker run --rm \
    -v "$PROJECT_ROOT:/home/esp/workspace" \
    -e "TARGET=xiaomiao" \
    thingsflow-esp-builder:v5.5.1 \
    /bin/bash -c '
        set -e
        source /opt/esp/esp-idf/export.sh
        cd /home/esp/workspace

        echo "清理..."
        python3 rg_tool.py --target "$TARGET" clean launcher
        echo ""

        echo "构建 Launcher..."
        python3 rg_tool.py --target "$TARGET" build launcher
        echo ""

        echo "✅ Launcher 构建完成！"
        ls -la launcher/build/
    '

echo ""
echo "🎉 测试完成！"
if [ -f "$PROJECT_ROOT/launcher/build/launcher.bin" ]; then
    echo "✅ launcher.bin 已生成！"
    ls -lh "$PROJECT_ROOT/launcher/build/"
else
    echo "⚠️  未找到 launcher.bin，请检查日志"
fi
