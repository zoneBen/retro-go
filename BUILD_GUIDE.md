# Retro-Go 构建指南

## 🐳 使用 Docker 构建（推荐）

### 前置条件
- Docker 已安装并运行
- Docker 镜像 `thingsflow-esp-builder:v5.5.1` 已存在

### 快速开始

#### 1. 完整构建 XIAOMIAO 固件
```bash
./build_xiaomiao.sh
```

#### 2. 仅构建 launcher（开发测试）
```bash
./build_xiaomiao.sh launcher
```

#### 3. 构建特定应用
```bash
./build_xiaomiao.sh "launcher retro-core"
```

### 使用通用 build.sh

```bash
# 完整构建 xiaomiao
./build.sh docker xiaomiao

# 仅构建 launcher
./build.sh docker xiaomiao launcher

# 构建多个应用
./build.sh docker xiaomiao "launcher retro-core prboom-go"

# 构建其他目标
./build.sh docker odroid-go
```

## 💻 本地构建

### 前置条件
- 已安装 ESP-IDF（v4.4-v5.3）
- 已激活 ESP-IDF 环境

### 构建命令

```bash
# 激活 ESP-IDF
. $HOME/esp/esp-idf/export.sh

# 方式 1: 使用专用脚本
./build_xiaomiao.sh local

# 方式 2: 使用通用脚本
./build.sh local xiaomiao

# 方式 3: 直接使用 rg_tool.py
python3 rg_tool.py --target xiaomiao build-img
```

## 🧹 清理构建

```bash
# 清理所有构建文件
./build_xiaomiao.sh clean
```

## 📂 输出文件

构建完成后，固件文件位于 `build/` 目录：

```
build/
├── retro-go_<version>_xiaomiao.img   # 完整固件镜像
├── launcher/
│   └── launcher.bin                  # launcher 二进制
├── retro-core/
│   └── retro-core.bin                # retro-core 二进制
├── prboom-go/
│   └── prboom-go.bin                 # DOOM 模拟器二进制
└── ...
```

## 🔧 烧录固件

### 使用 rg_tool.py（推荐）
```bash
# 完整烧录（需先构建）
python3 rg_tool.py --target xiaomiao --port /dev/ttyUSB0 install

# 仅烧录特定应用
python3 rg_tool.py --target xiaomiao --port /dev/ttyUSB0 flash launcher
```

### 使用 esptool.py
```bash
esptool.py write_flash --flash_size detect 0x0 build/retro-go_*.img
```

## 📋 rg_tool.py 命令参考

```bash
# 查看帮助
python3 rg_tool.py --help

# 清理
python3 rg_tool.py --target xiaomiao clean

# 构建应用
python3 rg_tool.py --target xiaomiao build launcher

# 构建完整固件 (.img)
python3 rg_tool.py --target xiaomiao build-img

# 构建完整固件 (.fw，支持的设备)
python3 rg_tool.py --target xiaomiao build-fw

# 完整构建并烧录
python3 rg_tool.py --target xiaomiao --port /dev/ttyUSB0 install

# 烧录并监控
python3 rg_tool.py --target xiaomiao --port /dev/ttyUSB0 run launcher
```

## ⚙️ 配置 sdkconfig

如果需要调整 ESP-IDF 配置：

```bash
# 1. 先构建一次 launcher
python3 rg_tool.py --target xiaomiao build launcher

# 2. 进入 launcher 目录配置
cd launcher
idf.py menuconfig

# 3. 复制配置到目标目录
cd ..
cp launcher/sdkconfig components/retro-go/targets/xiaomiao/sdkconfig

# 4. 清理并重新构建
python3 rg_tool.py --target xiaomiao clean
python3 rg_tool.py --target xiaomiao build-img
```

## 🔍 调试

如果构建失败，检查：

1. Docker 镜像是否正确：
   ```bash
   docker images | grep thingsflow-esp-builder
   ```

2. ESP-IDF 环境是否正常（本地构建）：
   ```bash
   echo $IDF_PATH
   idf.py --version
   ```

3. 目标设备配置是否完整：
   ```bash
   ls -la components/retro-go/targets/xiaomiao/
   ```

## 📝 可用的目标设备

查看所有可用目标：
```bash
ls -la components/retro-go/targets/
```

常见目标：
- `odroid-go` - ODROID-GO
- `xiaomiao` - XIAOMIAO (当前分支)
- `esp32-s3-devkit` - ESP32-S3 开发板
- `esplay-micro` - ESPLAY Micro
- 等等...

## 🎯 快速参考

### 日常开发流程
```bash
# 1. 清理并构建 launcher
./build_xiaomiao.sh launcher

# 2. 烧录并测试
python3 rg_tool.py --target xiaomiao --port /dev/ttyUSB0 run launcher

# 3. 如果正常，完整构建
./build_xiaomiao.sh
```

### 完整发布流程
```bash
# 1. 清理
./build_xiaomiao.sh clean

# 2. 完整构建
./build_xiaomiao.sh

# 3. 烧录测试
python3 rg_tool.py --target xiaomiao --port /dev/ttyUSB0 install
```
