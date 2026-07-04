#!/bin/bash
# XIAOMIAO 专用构建脚本 - 优化版（4MB Flash）
# 作者：mrcong
# 用法：
#   ./build_xiaomiao.sh          - 完整构建（launcher + retro-core）
#   ./build_xiaomiao.sh quick    - 仅构建 launcher
#   ./build_xiaomiao.sh clean    - 清理

set -e

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TARGET="xiaomiao"

if [ "$1" = "quick" ]; then
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
            python3 rg_tool.py --target xiaomiao --no-networking build launcher
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
    exit 0
fi

if [ "$1" = "clean" ]; then
    echo "🧹 清理构建文件..."
    rm -rf "$PROJECT_ROOT/build"
    for app_dir in "$PROJECT_ROOT"/*/; do
        app_name=$(basename "$app_dir")
        if [ -d "$app_dir/build" ]; then
            rm -rf "$app_dir/build"
        fi
        rm -f "$app_dir/sdkconfig" "$app_dir/sdkconfig.old" 2>/dev/null
    done
    rm -f "$PROJECT_ROOT"/retro-go_*.img "$PROJECT_ROOT"/retro-go_*.fw 2>/dev/null
    echo "✅ 清理完成！"
    exit 0
fi

# 优化版完整构建 - 仅包含 launcher 和 retro-core
echo "=========================================="
echo "  XIAOMIAO 优化构建（4MB Flash）"
echo "=========================================="
echo "  包含: launcher, retro-core"
echo "  预计大小: ~2MB"
echo "  已禁用: 网络、音频、更新功能"
echo "  ⏱️  预计需要 10-15 分钟"
echo "=========================================="
read -p "继续？(y/n) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    exit 1
fi
echo ""

cd "$PROJECT_ROOT"

# 检查 Docker 镜像
if ! docker image inspect thingsflow-esp-builder:v5.5.1 > /dev/null 2>&1; then
    echo "❌ Docker 镜像不存在！"
    exit 1
fi

# 确保输出目录存在
mkdir -p "$PROJECT_ROOT/build"

docker run --rm \
    -v "$PROJECT_ROOT:/home/esp/workspace" \
    thingsflow-esp-builder:v5.5.1 \
    /bin/bash -c '
        set -e
        source /opt/esp/esp-idf/export.sh
        cd /home/esp/workspace

        echo "=========================================="
        echo "  步骤 1: 清理"
        echo "=========================================="
        python3 rg_tool.py --target xiaomiao clean
        echo ""

        echo "=========================================="
        echo "  步骤 2: 构建"
        echo "=========================================="
        echo "仅构建: launcher retro-core"
        echo "已禁用: 网络功能"
        echo ""
        python3 rg_tool.py --target xiaomiao --no-networking build-img launcher retro-core
        echo ""

        echo "=========================================="
        echo "  步骤 3: 整理输出"
        echo "=========================================="
        mkdir -p build
        IMG_FILE=$(ls -t retro-go_*.img 2>/dev/null | head -n1)
        if [ -n "$IMG_FILE" ]; then
            echo "✅ 找到固件: $IMG_FILE"
            mv -f "$IMG_FILE" build/
            echo "✅ 固件已移动到 build/$IMG_FILE"
            ls -lh build/
        else
            echo "⚠️  未找到 .img 文件"
            ls -la retro-go_*.fw 2>/dev/null || true
        fi

        for app_dir in */; do
            app_name=$(basename "$app_dir")
            if [ -f "$app_dir/build/$app_name.bin" ]; then
                mkdir -p build/$app_name
                cp -f "$app_dir/build/$app_name.bin" build/$app_name/
                echo "✅ 已复制: $app_name.bin"
            fi
        done

        echo ""
        echo "=========================================="
        echo "  🎉 构建完成！"
        echo "=========================================="
        ls -lh build/
    '
