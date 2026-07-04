# Retro-Go 移植指南

本文档详细介绍如何将 Retro-Go 移植到新的 ESP32 设备上。

## 目录

- [前提条件](#前提条件)
- [项目概述](#项目概述)
- [移植步骤](#移植步骤)
- [配置文件详解](#配置文件详解)
- [构建和测试](#构建和测试)
- [常见问题](#常见问题)

---

## 前提条件

### 硬件要求

- **ESP32 芯片**：支持 ESP32、ESP32-S2、ESP32-S3、ESP32-P4 等
- **PSRAM（外部 RAM）**：至少 2MB，推荐 8MB
- **显示屏**：推荐 ILI9341 或 ST7789（320x240）
- **输入设备**：按键（GPIO、ADC、I2C 扩展器等）
- **存储**：SD 卡（SPI 或 SDMMC 模式）
- **音频**：内部 DAC 或外部 I2S DAC
- **USB 串口**：用于烧录和调试

### 软件要求

- **ESP-IDF**：版本 4.4 到 5.3（推荐 4.4.8）
- **Python 3**：用于构建工具 `rg_tool.py`
- **Git**：用于获取源代码

### 准备工作

1. 安装 ESP-IDF 并设置好环境
2. 克隆 Retro-Go 仓库：
   ```bash
   git clone https://github.com/ducalex/retro-go.git
   cd retro-go
   ```
3. 确保您的设备在 ESP-IDF 示例中能正常工作（例如：hello_world、sd_card、lcd 等）

---

## 项目概述

### 现有目标设备

Retro-Go 已经支持 17 个目标设备，位于 `components/retro-go/targets/`：

- `odroid-go` - 官方支持的参考设备
- `mrgc-g32` - MyRetroGameCase G32
- `esp32-s3-devkit` - ESP32-S3 开发板
- `redroid-go` - REDROID-GO
- `esplay-micro` - ESPlay Micro
- `sdl2` - PC 模拟器（用于开发测试）
- 等等...

### 项目结构

```
retro-go/
├── components/
│   └── retro-go/
│       ├── config.h              # 主配置文件（目标选择）
│       ├── targets/              # 各设备配置
│       │   ├── your-device/      # 你的设备配置
│       │   │   ├── config.h      # 硬件配置
│       │   │   ├── env.py        # 构建环境配置
│       │   │   └── sdkconfig     # ESP-IDF 配置
│       ├── drivers/              # 驱动程序
│       │   ├── display/          # 显示驱动
│       │   └── audio/            # 音频驱动
│       └── rg_input.h            # 输入系统定义
├── launcher/                     # 启动器应用
├── retro-core/                   # 核心模拟器（NES、PCE、SMS 等）
├── prboom-go/                    # DOOM 模拟器
├── gwenesis/                     # Genesis 模拟器
├── fmsx/                         # MSX 模拟器
├── rg_tool.py                    # 构建工具
└── BUILDING.md                   # 构建说明
```

---

## 移植步骤

### 第一步：选择参考设备

首先，找到与您的设备最相似的现有目标设备作为起点：

- **通用开发板**：参考 `esp32-s3-devkit` 或 `odroid-go`
- **小型掌机**：参考 `mrgc-g32` 或 `esplay-micro`
- **桌面测试**：使用 `sdl2` 目标在 PC 上测试

### 第二步：创建新目标目录

```bash
cd components/retro-go/targets/
cp -r odroid-go xiaomiao          # 复制参考设备配置
cd xiaomiao
```

### 第三步：修改配置文件

需要修改三个核心文件：

1. **`config.h`** - 硬件配置（GPIO、显示屏、按键等）
2. **`env.py`** - 构建环境配置（芯片类型等）
3. **`sdkconfig`** - ESP-IDF 配置

### 第四步：更新主配置文件

在 `components/retro-go/config.h` 中添加新目标：

```c
#elif defined(RG_TARGET_XIAOMIAO)
#include "targets/xiaomiao/config.h"
```

---

## 配置文件详解

### 1. config.h - 硬件配置

这是最重要的配置文件。以下是详细说明：

#### 目标定义

```c
#define RG_TARGET_NAME             "XIAOMIAO"
```

#### 存储配置

```c
// 选择 SPI 模式或 SDMMC 模式
#define RG_STORAGE_ROOT             "/sd"

// SPI 模式（大多数设备）
#define RG_STORAGE_SDSPI_HOST       SPI2_HOST
#define RG_STORAGE_SDSPI_SPEED      SDMMC_FREQ_DEFAULT

// SDMMC 模式（更快，需要特定引脚）
// #define RG_STORAGE_SDMMC_HOST       SDMMC_HOST_SLOT_1
// #define RG_STORAGE_SDMMC_SPEED      SDMMC_FREQ_DEFAULT

// Flash 模式（如果没有 SD 卡）
// #define RG_STORAGE_FLASH_PARTITION  "vfs"
```

#### 音频配置

```c
// 内部 DAC（ESP32 GPIO25/GPIO26）
#define RG_AUDIO_USE_INT_DAC        3   // 0=禁用, 1=GPIO25, 2=GPIO26, 3=两者

// 外部 I2S DAC
#define RG_AUDIO_USE_EXT_DAC        1   // 0=禁用, 1=启用
```

#### 显示屏配置

```c
// 显示驱动选择
#define RG_SCREEN_DRIVER            0   // 0=ILI9341/ST7789, 2=自定义, 99=SDL2

// SPI 配置
#define RG_SCREEN_HOST              SPI2_HOST
#define RG_SCREEN_SPEED             SPI_MASTER_FREQ_40M

// 显示规格
#define RG_SCREEN_WIDTH             320
#define RG_SCREEN_HEIGHT            240
#define RG_SCREEN_ROTATE            0   // 0, 90, 180, 270
#define RG_SCREEN_BACKLIGHT         1

// 显示初始化序列（非常重要！）
// 从您的显示屏数据手册或现有代码中获取
#define RG_SCREEN_INIT() \
    ILI9341_CMD(0xCF, 0x00, 0xc3, 0x30); \
    ILI9341_CMD(0xED, 0x64, 0x03, 0x12, 0x81); \
    // ... 更多命令
```

**获取初始化序列的方法**：
- 查看设备的原厂示例代码
- 查找显示屏的数据手册
- 参考相似设备的配置
- 使用 LCD 初始化序列提取工具

#### 输入配置

Retro-Go 支持多种输入方式，可以混合使用：

**GPIO 按键**（直接连接到 GPIO 引脚）：
```c
#define RG_GAMEPAD_GPIO_MAP {\
    {RG_KEY_SELECT, .num = GPIO_NUM_27, .pullup = 1, .level = 0},\
    {RG_KEY_START,  .num = GPIO_NUM_39, .pullup = 0, .level = 0},\
    {RG_KEY_MENU,   .num = GPIO_NUM_13, .pullup = 1, .level = 0},\
    {RG_KEY_OPTION, .num = GPIO_NUM_0,  .pullup = 0, .level = 0},\
    {RG_KEY_A,      .num = GPIO_NUM_32, .pullup = 1, .level = 0},\
    {RG_KEY_B,      .num = GPIO_NUM_33, .pullup = 1, .level = 0},\
}
```

**ADC 按键**（多个按键通过电阻分压连接到一个 ADC 引脚）：
```c
#define RG_GAMEPAD_ADC_MAP {\
    {RG_KEY_UP,    ADC_UNIT_1, ADC_CHANNEL_7, ADC_ATTEN_DB_11, 3072, 4096},\
    {RG_KEY_DOWN,  ADC_UNIT_1, ADC_CHANNEL_7, ADC_ATTEN_DB_11, 1024, 3071},\
    {RG_KEY_LEFT,  ADC_UNIT_1, ADC_CHANNEL_6, ADC_ATTEN_DB_11, 3072, 4096},\
    {RG_KEY_RIGHT, ADC_UNIT_1, ADC_CHANNEL_6, ADC_ATTEN_DB_11, 1024, 3071},\
}
```

**I2C GPIO 扩展器**：
```c
#define RG_I2C_GPIO_DRIVER          3   // 1=AW9523, 2=PCF9539, 3=MCP23017
#define RG_I2C_GPIO_ADDR            0x20
```

**可用的按键定义**（在 `rg_input.h` 中）：
- `RG_KEY_UP`, `RG_KEY_DOWN`, `RG_KEY_LEFT`, `RG_KEY_RIGHT`
- `RG_KEY_A`, `RG_KEY_B`, `RG_KEY_X`, `RG_KEY_Y`
- `RG_KEY_SELECT`, `RG_KEY_START`
- `RG_KEY_MENU`, `RG_KEY_OPTION`
- `RG_KEY_L`, `RG_KEY_R`

#### 电池配置

```c
#define RG_BATTERY_DRIVER           1
#define RG_BATTERY_ADC_UNIT         ADC_UNIT_1
#define RG_BATTERY_ADC_CHANNEL      ADC_CHANNEL_0

// 电压计算公式（根据您的分压电路调整）
#define RG_BATTERY_CALC_PERCENT(raw) (((raw) * 2.f - 3500.f) / (4200.f - 3500.f) * 100.f)
#define RG_BATTERY_CALC_VOLTAGE(raw) ((raw) * 2.f * 0.001f)
```

#### GPIO 引脚配置

**SPI 显示屏引脚**：
```c
#define RG_GPIO_LCD_MISO            GPIO_NUM_19
#define RG_GPIO_LCD_MOSI            GPIO_NUM_23
#define RG_GPIO_LCD_CLK             GPIO_NUM_18
#define RG_GPIO_LCD_CS              GPIO_NUM_5
#define RG_GPIO_LCD_DC              GPIO_NUM_21
#define RG_GPIO_LCD_BCKL            GPIO_NUM_14
#define RG_GPIO_LCD_RST             GPIO_NUM_NC   // 不用的话设为 NC
```

**SPI SD 卡引脚**：
```c
#define RG_GPIO_SDSPI_MISO          GPIO_NUM_19
#define RG_GPIO_SDSPI_MOSI          GPIO_NUM_23
#define RG_GPIO_SDSPI_CLK           GPIO_NUM_18
#define RG_GPIO_SDSPI_CS            GPIO_NUM_22
```

**外部 I2S DAC 引脚**：
```c
#define RG_GPIO_SND_I2S_BCK         GPIO_NUM_4
#define RG_GPIO_SND_I2S_WS          GPIO_NUM_12
#define RG_GPIO_SND_I2S_DATA        GPIO_NUM_15
```

**其他引脚**：
```c
#define RG_GPIO_LED                 GPIO_NUM_2     // 状态 LED

// I2C 总线（如果使用 I2C GPIO 扩展器）
// #define RG_GPIO_I2C_SDA             GPIO_NUM_15
// #define RG_GPIO_I2C_SCL             GPIO_NUM_4
```

#### 更新器配置（可选）

```c
#define RG_UPDATER_ENABLE               1
#define RG_UPDATER_APPLICATION          RG_APP_FACTORY
#define RG_UPDATER_DOWNLOAD_LOCATION    RG_STORAGE_ROOT "/xiaomiao/firmware"
```

### 2. env.py - 构建环境配置

```python
# 设备使用的 ESP32 芯片类型
IDF_TARGET = "esp32"      # 可选: "esp32", "esp32s2", "esp32s3", "esp32p4"

# .fw 文件格式（如果设备支持）
FW_FORMAT = "odroid"      # 或 None

# 默认构建的应用
# DEFAULT_APPS = "launcher prboom-go retro-core"
```

### 3. sdkconfig - ESP-IDF 配置

这个文件通过以下步骤生成和配置：

1. 先使用默认配置构建一次：
   ```bash
   cd ../../../..
   python rg_tool.py --target=xiaomiao build launcher
   ```

2. 进入 launcher 目录配置：
   ```bash
   cd launcher
   idf.py menuconfig
   ```

3. 关键配置项：

   **CPU 频率和电源管理**：
   ```
   Component config → ESP32-specific → CPU frequency → 240 MHz
   Component config → Power Management → Support for power management → 禁用
   ```

   **PSRAM 配置**：
   ```
   Component config → ESP32-specific → Support for external, SPI-connected RAM → 启用
   Component config → ESP32-specific → SPI RAM config → SPI RAM access method → "Cache"
   Component config → ESP32-specific → SPI RAM config → Maximum malloc() size → 最大
   ```

   **Flash 配置**：
   ```
   Serial flasher config → Flash size → 根据您的设备选择（4MB+）
   Serial flasher config → Flash SPI mode → QIO
   Serial flasher config → Flash SPI speed → 80MHz
   ```

   **主任务栈大小**：
   ```
   Component config → Common ESP-related → Main task stack size → 8192+
   ```

   **FAT 文件系统**：
   ```
   Component config → FAT Filesystem support → Long filename support → 启用
   Component config → FAT Filesystem support → API encoding → UTF-8
   ```

4. 保存配置并复制回目标目录：
   ```bash
   cd ..
   mv -f launcher/sdkconfig components/retro-go/targets/xiaomiao/sdkconfig
   ```

---

## 构建和测试

### 完整构建

```bash
# 清理
python rg_tool.py clean

# 构建 .img 文件（用于首次烧录）
python rg_tool.py --target=xiaomiao build-img

# 或构建 .fw 文件（如果设备支持）
python rg_tool.py --target=xiaomiao build-fw
```

### 烧录固件

```bash
# 使用 rg_tool.py 烧录
python rg_tool.py --target=xiaomiao --port=/dev/ttyUSB0 install

# 或使用 esptool.py
esptool.py write_flash --flash_size detect 0x0 retro-go_xiaomiao.img
```

### 开发测试

首次完整烧录后，可以单独构建和烧录单个应用以加快开发：

```bash
# 仅烧录启动器
python rg_tool.py --target=xiaomiao --port=/dev/ttyUSB0 flash launcher

# 烧录并监控启动器
python rg_tool.py --target=xiaomiao --port=/dev/ttyUSB0 run launcher
```

### 测试清单

- [ ] 显示屏正常工作
- [ ] 按键响应正确
- [ ] SD 卡能挂载和读写
- [ ] 音频输出正常
- [ ] 电池电量显示正确
- [ ] 模拟器能加载和运行 ROM
- [ ] 保存状态功能正常

---

## 常见问题

### 1. 显示屏不亮或显示异常

**可能原因**：
- 初始化序列不正确
- SPI 引脚配置错误
- 旋转角度不对
- 背光引脚未配置

**解决方法**：
- 检查显示屏的数据手册
- 使用逻辑分析仪观察 SPI 信号
- 尝试不同的初始化序列
- 调整 RG_SCREEN_ROTATE

### 2. 按键不响应

**可能原因**：
- GPIO 引脚配置错误
- 上拉/下拉配置错误
- ADC 阈值不正确

**解决方法**：
- 使用 ESP-IDF 的 gpio_example 或 adc_example 测试
- 打印原始 ADC 值查看实际范围
- 检查是否需要上拉电阻

### 3. SD 卡无法挂载

**可能原因**：
- SPI 引脚配置错误
- SD 卡速度太高
- CS 引脚问题

**解决方法**：
- 先测试 ESP-IDF 的 sd_card 示例
- 降低 SPI 速度
- 检查 SD 卡是否支持 SPI 模式

### 4. 内存不足

**可能原因**：
- PSRAM 未正确配置
- 应用占用内存太多

**解决方法**：
- 检查 sdkconfig 中的 PSRAM 配置
- 减少同时加载的应用
- 调整应用的内存分配

### 5. 编译错误

**可能原因**：
- ESP-IDF 版本不匹配
- config.h 配置错误
- 目标未在主 config.h 中注册

**解决方法**：
- 确认使用支持的 ESP-IDF 版本
- 检查 config.h 语法
- 确认在 components/retro-go/config.h 中添加了目标

---

## 高级主题

### 自定义显示驱动

如果您的显示屏不是 ILI9341/ST7789，需要编写自定义驱动：

1. 复制 `components/retro-go/drivers/display/ili9341.h` 作为模板
2. 修改驱动代码适配您的显示屏
3. 在 `components/retro-go/rg_display.c` 中添加：
   ```c
   #elif RG_SCREEN_DRIVER == 2
   #include "drivers/display/your-driver.h"
   ```
4. 在 config.h 中设置 `#define RG_SCREEN_DRIVER 2`

### 打补丁

如果需要添加特定设备的特殊代码，可以使用条件编译：

```c
#ifdef RG_TARGET_XIAOMIAO
// 仅在您的设备上执行的代码
#endif
```

### 贡献

如果您成功移植到新设备，欢迎向 Retro-Go 项目提交 Pull Request！

---

## 参考资源

- [PORTING.md](PORTING.md) - 官方移植指南（英文）
- [BUILDING.md](BUILDING.md) - 构建说明
- [ESP-IDF 编程指南](https://docs.espressif.com/projects/esp-idf/)
- [Retro-Go GitHub](https://github.com/ducalex/retro-go)

---

祝移植顺利！如有问题，欢迎在 GitHub 提交 Issue。
