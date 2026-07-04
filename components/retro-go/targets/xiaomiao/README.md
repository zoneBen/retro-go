# XIAOMIAO 设备移植说明

## 硬件配置

### 引脚分配

| 功能 | 引脚 | 说明 |
|------|------|------|
| 上 | GPIO2 | 内部上拉 |
| 下 | GPIO13 | 内部上拉 |
| 左 | GPIO27 | 内部上拉 |
| 右 | GPIO35 | 仅输入，需要外部上拉 |
| A | GPIO34 | 仅输入，需要外部上拉 |
| B | GPIO12 | 启动敏感，需要外部上拉 |
| TFT CS | GPIO5 | |
| TFT DC | GPIO4 | |
| TFT SCK | GPIO18 | 与 SD 卡共享 |
| TFT MOSI | GPIO23 | 与 SD 卡共享 |
| TFT MISO/RST | GPIO19 | 与 SD 卡 MISO 共享，不使用软件 RST |
| SD CS | GPIO22 | |
| 蜂鸣器 | GPIO14 | PWM |
| I2C SDA | GPIO21 | |
| I2C SCL | GPIO15 | |
| UART0 TX | GPIO1 | |
| UART0 RX | GPIO3 | |
| 光照传感器 | GPIO36 | ADC1_CH0 |
| 温度传感器 | GPIO39 | ADC1_CH3 |

### 显示屏

- 型号：ST7735 或兼容
- 分辨率：160x128
- 颜色：16-bit RGB565
- 接口：SPI

### 存储

- MicroSD 卡 (SPI 模式)
- 与 TFT 共享 SPI 总线

## 按键映射

| 物理按键 | Retro-Go 功能 |
|----------|--------------|
| 上 | UP |
| 下 | DOWN |
| 左 | LEFT |
| 右 | RIGHT |
| A | A |
| B | B |
| 上 + 下 | SELECT |
| 左 + 右 | START |
| A + B | MENU |

## 已知问题和注意事项

### 1. GPIO12 启动敏感

GPIO12 在启动时如果检测到高电平可能会导致启动失败。确保：
- 按键使用低电平触发
- 或在启动时不按下 B 键

### 2. GPIO34/35 仅输入

这两个引脚不支持内部上拉/下拉，需要外部上拉电阻。

### 3. TFT RST 与 MISO 共享

显示屏的 RST 引脚和 SD 卡的 MISO 都连接到 GPIO19。
- 不使用软件控制 RST
- 依赖硬件复位或上电复位

### 4. 音频

硬件有蜂鸣器 (GPIO14)，但 Retro-Go 使用内部 DAC (GPIO25/26)。
- 如需音频，可将 GPIO25/26 连接到扩音器
- 或编写蜂鸣器驱动

### 5. 显示屏初始化

当前使用 ST7735 初始化序列，可能需要根据实际显示屏调整：
- 旋转角度 (0/90/180/270)
- RGB/BGR 顺序
- 初始化命令

## 构建和烧录

### 1. 设置 ESP-IDF

确保已安装 ESP-IDF 4.4-5.3，并激活环境：

```bash
. $HOME/esp/esp-idf/export.sh
```

### 2. 配置 sdkconfig

首次需要生成并配置 sdkconfig：

```bash
python rg_tool.py --target xiaomiao build launcher
cd launcher
idf.py menuconfig
cd ..
# 配置完成后，复制 sdkconfig 到目标目录
cp launcher/sdkconfig components/retro-go/targets/xiaomiao/
```

关键配置项：
- Component config → ESP32-specific → Support for external, SPI-connected RAM: 启用
- Component config → FAT Filesystem support → Long filename support: 启用

### 3. 构建固件

```bash
python rg_tool.py --target xiaomiao build-img
```

### 4. 烧录固件

```bash
python rg_tool.py --target xiaomiao --port /dev/ttyUSB0 install
```

或使用 esptool：

```bash
esptool.py write_flash --flash_size detect 0x0 retro-go_xiaomiao.img
```

## 调试

### 查看日志

```bash
python rg_tool.py --target xiaomiao --port /dev/ttyUSB0 monitor launcher
```

### 测试显示屏

如果显示不正常，检查：
1. 初始化序列是否正确
2. 旋转角度 (RG_SCREEN_ROTATE)
3. RGB/BGR 顺序 (0x36 命令中的 0x08 位)

### 测试按键

如果按键不工作，检查：
1. 外部上拉电阻是否存在 (GPIO34/35)
2. 按键触发电平是否正确
3. GPIO12 是否导致启动问题

## 下一步改进

1. 添加背光控制 (如果硬件支持)
2. 实现蜂鸣器音频驱动
3. 添加传感器读取功能
4. 优化显示屏初始化序列
5. 调整虚拟按键组合 (如果需要)
6. 添加电池检测 (如果硬件支持)

## 参考

- [Retro-Go 官方移植指南](../../../../PORTING.md)
- [ESP-IDF 编程指南](https://docs.espressif.com/projects/esp-idf/)
- [ST7735 数据手册](https://www.displayfuture.com/Display/datasheet/controller/ST7735.pdf)
