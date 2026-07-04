#!/bin/bash
# Retro-Go 编译脚本（支持 Docker 和本地构建）
# 作者：mrcong
# 用法：./build.sh [docker|local] [target] [apps]
# 示例：
#   ./build.sh docker xiaomiao launcher
#   ./build.sh docker xiaomiao
#   ./build.sh local

set -e  # 遇错立即退出

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_NAME="Retro-Go"

# 默认配置
BUILD_MODE="${1:-docker}"
TARGET="${2:-xiaomiao}"
APPS="${3:-all}"

# 获取可用的目标设备列表
AVAILABLE_TARGETS=()
for t in "$PROJECT_ROOT/components/retro-go/targets"/*/; do
    t_name=$(basename "$t")
    if [ "$t_name" != "*" ] && [ -d "$t" ]; then
        AVAILABLE_TARGETS+=("$t_name")
    fi
done

echo "=========================================="
echo "  ${PROJECT_NAME} 构建工具"
echo "=========================================="
echo "📂 项目路径: $PROJECT_ROOT"
echo "📦 构建模式: $BUILD_MODE"
echo "🎯 目标设备: $TARGET"
echo "🚀 应用列表: $APPS"
echo ""

# 检查目标设备是否有效
if [ ! -d "$PROJECT_ROOT/components/retro-go/targets/$TARGET" ]; then
    echo "❌ 目标设备 '$TARGET' 不存在！"
    echo "可用的目标设备：${AVAILABLE_TARGETS[*]}"
    exit 1
fi

# 确保输出目录存在
mkdir -p "$PROJECT_ROOT/build"

if [ "$BUILD_MODE" = "docker" ]; then
    echo "🐳 使用 Docker 构建..."

    # 检查 Docker 镜像是否存在
    if ! docker image inspect thingsflow-esp-builder:v5.5.1 > /dev/null 2>&1; then
        echo "❌ Docker 镜像 thingsflow-esp-builder:v5.5.1 不存在"
        exit 1
    fi

    # 环境变量传递给 Docker
    docker run --rm \
        -v "$PROJECT_ROOT:/home/esp/workspace" \
        -e "TARGET=$TARGET" \
        -e "APPS=$APPS" \
        thingsflow-esp-builder:v5.5.1 \
        /bin/bash -c '
            set -e
            source /opt/esp/esp-idf/export.sh
            cd /home/esp/workspace

            echo "=========================================="
            echo "  步骤 1: 清理旧的构建文件"
            echo "=========================================="
            if [ "$APPS" = "all" ]; then
                python3 rg_tool.py --target "$TARGET" clean
            else
                for app in $APPS; do
                    python3 rg_tool.py --target "$TARGET" clean "$app"
                done
            fi
            echo ""

            echo "=========================================="
            echo "  步骤 2: 构建固件"
            echo "=========================================="
            if [ "$APPS" = "all" ]; then
                python3 rg_tool.py --target "$TARGET" build-img
            else
                python3 rg_tool.py --target "$TARGET" build-img $APPS
            fi
            echo ""

            echo "=========================================="
            echo "  步骤 3: 整理输出文件"
            echo "=========================================="
            mkdir -p build
            # 查找生成的固件文件
            IMG_FILE=$(ls -t retro-go_*.img 2>/dev/null | head -n1)
            if [ -n "$IMG_FILE" ]; then
                echo "✅ 找到固件: $IMG_FILE"
                mv -f "$IMG_FILE" build/
                echo "✅ 固件已移动到 build/$IMG_FILE"
            else
                echo "⚠️  未找到 .img 文件，检查是否有其他输出..."
                ls -la retro-go_*.fw 2>/dev/null || true
            fi

            # 复制编译好的二进制文件到 build 目录
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

    echo "✅ Docker 构建完成！"

elif [ "$BUILD_MODE" = "local" ]; then
    echo "💻 使用本地 ESP-IDF 构建..."

    # 检查是否在 ESP-IDF 环境中
    if [ -z "$IDF_PATH" ]; then
        echo "❌ 未检测到 ESP-IDF 环境！"
        echo "请先运行: . /path/to/esp-idf/export.sh"
        exit 1
    fi

    cd "$PROJECT_ROOT"

    echo "=========================================="
    echo "  步骤 1: 清理旧的构建文件"
    echo "=========================================="
    if [ "$APPS" = "all" ]; then
        python3 rg_tool.py --target "$TARGET" clean
    else
        for app in $APPS; do
            python3 rg_tool.py --target "$TARGET" clean "$app"
        done
    fi
    echo ""

    echo "=========================================="
    echo "  步骤 2: 构建固件"
    echo "=========================================="
    if [ "$APPS" = "all" ]; then
        python3 rg_tool.py --target "$TARGET" build-img
    else
        python3 rg_tool.py --target "$TARGET" build-img $APPS
    fi
    echo ""

    echo "=========================================="
    echo " 步骤 3: 整理输出文件"
    echo "=========================================="
    # 查找生成的固件文件
    IMG_FILE=$(ls -t retro-go_*.img 2>/dev/null | head -n1)
    if [ -n "$IMG_FILE" ]; then
        echo "✅ 找到固件: $IMG_FILE"
        mv -f "$IMG_FILE" build/
        echo "✅ 固件已移动到 build/$IMG_FILE"
    else
        echo "⚠️ 未找到 .img 文件，检查是否有其他输出..."
        ls -la retro-go_*.fw 2>/dev/null || true
    fi

    # 复制编译好的二进制文件到 build 目录
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
    echo "🎉 构建完成！"
    echo "=========================================="
    ls -lh build/

else
    echo "用法: $0 [docker|local] [target] [apps]"
    echo ""
    echo "参数说明："
    echo "  docker: 使用 Docker 容器构建（默认）"
    echo "  local:  使用本地 ESP-IDF 环境构建"
    echo "  target: 目标设备（默认: xiaomiao）"
    echo "  apps:   应用列表（默认: all）"
    echo ""
    echo "可用的目标设备：${AVAILABLE_TARGETS[*]}"
    echo ""
    echo "示例："
    echo "  $0 docker xiaomiao"
    echo "  $0 docker xiaomiao launcher"
    echo "  $0 local xiaomiao"
    echo "  $0 local"
    exit 1
fi
