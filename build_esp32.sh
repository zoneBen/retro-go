#!/bin/bash
# 通用 ESP32-C3 编译脚本（支持 2MB Flash）
# 作者：mrcong
# 用法：./build_esp32c3.sh [docker|local]

set -e  # 遇错立即退出

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BUILD_DIR="$PROJECT_ROOT/build"
OUTPUT_BIN="$BUILD_DIR/firmware.bin"

# 默认使用 Docker 构建
BUILD_MODE="${1:-docker}"

# 检测项目名称（从 CMakeLists.txt 或目录名）
if [ -f "$PROJECT_ROOT/CMakeLists.txt" ]; then
    PROJECT_NAME=$(grep -oP 'project\(\K[^ )]+' "$PROJECT_ROOT/CMakeLists.txt" | head -n1)
fi
PROJECT_NAME=${PROJECT_NAME:-$(basename "$PROJECT_ROOT")}

echo "🔧 项目名称: $PROJECT_NAME"
echo "📂 项目路径: $PROJECT_ROOT"
echo "📦 构建模式: $BUILD_MODE"

# 清理旧固件（避免混淆）
if [ -f "$OUTPUT_BIN" ]; then
    echo "🗑️  删除旧固件: $OUTPUT_BIN"
    rm -f "$OUTPUT_BIN"
fi

if [ "$BUILD_MODE" = "docker" ]; then
    echo "🐳 使用 Docker 构建..."

    # 检查 Docker 镜像是否存在
    if ! docker image inspect thingsflow-esp-builder:v5.5.1 > /dev/null 2>&1; then
        echo "❌ Docker 镜像 thingsflow-esp-builder:v5.5.1 不存在，请先构建或拉取"
        exit 1
    fi

    docker run --rm -v "$PROJECT_ROOT:/home/esp/workspace" thingsflow-esp-builder:v5.5.1 bash -c "
        set -e
        source /opt/esp/esp-idf/export.sh
        cd /home/esp/workspace
        idf.py set-target esp32c3
        idf.py fullclean  # 可选：确保干净构建（首次可注释）
        idf.py build
        APP_BIN=\$(find build -maxdepth 1 -name '*.bin' ! -name '*bootloader*' ! -name '*partition*' ! -name 'firmware.bin' | head -n1)
        if [ -z \"\$APP_BIN\" ]; then
            echo '❌ 未找到应用程序二进制文件！'
            exit 1
        fi
        echo \"✅ 找到应用固件: \$(basename \$APP_BIN)\"
        python -m esptool --chip esp32c3 merge_bin \
            -o build/firmware.bin \
            --flash_mode dio \
            --flash_freq 40m \
            --flash_size 2MB \
            0x0 build/bootloader/bootloader.bin \
            0x8000 build/partition_table/partition-table.bin \
            0x10000 \"\$APP_BIN\"
        echo '✅ 固件生成成功: build/firmware.bin'
    "

elif [ "$BUILD_MODE" = "local" ]; then
    echo "💻 使用本地 ESP-IDF 构建..."

    if ! command -v idf.py &> /dev/null; then
        echo "❌ 未找到 idf.py，请确保已安装 ESP-IDF 并配置环境"
        exit 1
    fi

    cd "$PROJECT_ROOT"
    idf.py set-target esp32c3
    idf.py build

    APP_BIN=$(find build -maxdepth 1 -name '*.bin' ! -name '*bootloader*' ! -name '*partition*' ! -name 'firmware.bin' | head -n1)
    if [ -z "$APP_BIN" ]; then
        echo "❌ 未找到应用程序二进制文件！"
        exit 1
    fi

    echo "✅ 找到应用固件: $(basename "$APP_BIN")"
    python -m esptool --chip esp32c3 merge_bin \
        -o "$OUTPUT_BIN" \
        --flash_mode dio \
        --flash_freq 40m \
        --flash_size 2MB \
        0x0 "$BUILD_DIR/bootloader/bootloader.bin" \
        0x8000 "$BUILD_DIR/partition_table/partition-table.bin" \
        0x10000 "$APP_BIN"

    echo "✅ 固件生成成功: $OUTPUT_BIN"

else
    echo "用法: $0 [docker|local]"
    echo "  docker: 使用 Docker 容器构建（默认）"
    echo "  local:  使用本地 ESP-IDF 环境构建"
    exit 1
fi

echo "🎉 构建完成！固件路径: $OUTPUT_BIN"