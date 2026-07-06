# Table of contents
- [Description](#description)
- [Installation](#installation)
- [Usage](#usage)
- [Issues](#issues)
- [Development](#development)
- [Acknowledgements](#acknowledgements)
- [License](#license)

# Description
Retro-Go is a firmware to play retro games on ESP32-based devices (officially supported are
ODROID-GO and MRGC-G32, check [this list for other devices](components/retro-go/README.md)).
The project consists of a launcher and half a dozen applications that have been heavily
optimized to reduce their cpu, memory, and flash needs without reducing compatibility!

### Supported Devices
- ODROID-GO (Official)
- MRGC-G32 (Official)
- XIAOMIAO (160x128 ST7735 display, 6 keys + virtual combos)
- And many more, check the full list [here](components/retro-go/README.md)

---

## XIAOMIAO 分支改动 (xiaomiao branch)

### 硬件配置
| 组件 | 规格 |
|------|------|
| **主控** | ESP32 |
| **显示屏** | ST7735 160x128 (SPI2, 与 SD 卡共享) |
| **按键** | 6个物理按键 + 虚拟组合按键 |
| **存储** | MicroSD 卡 (SPI2) |
| **音频** | 内部 DAC (GPIO25/26) |
| **蜂鸣器** | GPIO14 (PWM) |
| **传感器** | 光照 (GPIO36)、温度 (GPIO39) |
| **总线** | I2C (GPIO15/21), UART0 (GPIO1/3) |

### 按键映射
| 按键 | 引脚 | 说明 |
|------|------|------|
| UP | GPIO2 | 内部上拉 |
| DOWN | GPIO13 | 内部上拉 |
| LEFT | GPIO27 | 内部上拉 |
| RIGHT | GPIO35 | 仅输入，需外部上拉 |
| A | GPIO34 | 仅输入，需外部上拉 |
| B | GPIO12 | 启动敏感，内部上拉 |

### 虚拟按键组合
| 组合 | 功能 |
|------|------|
| UP + DOWN | SELECT |
| LEFT + RIGHT | START |
| A + B | MENU |

### 硬件注意事项
- GPIO34/35 需要外部上拉电阻
- GPIO12 启动时避免高电平
- TFT RST 与 SD MISO 共享 (GPIO19)
- 显示与 SD 卡共享 SPI2 总线 (SCK:18, MOSI:23, MISO:19)

### 最近改动 (xiaomiao branch)
- `6f694283` 关于小喵 - 添加关于页面
- `9f85fb28` 新增关于页面
- `21a8eaf7` 中文汉化
- `e950d127` 新增声音
- `24308035` 初步移植
- `89a84df5` Add xiaomiao target device support

---
下面信息来源  https://github.com/ZyoungInc/xueersi-idf



# 小喵掌机硬件与底层协议

## 1. 总体架构

```text
PC USB
  │
  │ USB CDC / 下载串口
  ▼
GD32F350G8
  ├─ USB 转 ESP32 UART0
  ├─ ESP32 自动下载 / 自动复位控制
  ├─ I2C 从机地址 0x40
  ├─ 控制双路电机驱动 HR8833 / DRV8833
  └─ 控制板载 LED1 / LED2

ESP32-WROVER-B
  ├─ SPI TFT 显示屏
  ├─ MicroSD 卡
  ├─ 6 个按键
  ├─ 蜂鸣器 PWM
  ├─ 光照 ADC
  ├─ 热敏 ADC
  ├─ I2C 主机
  │   ├─ GD32F350G8：0x40
  │   └─ MPU6050：0x68
  └─ 预留扩展 IO
```

核心关系：

```text
ESP32 = 主控 / UI / Python 运行环境 / 屏幕 / SD / 按键 / 传感器
GD32  = USB 串口桥 / ESP32 自动烧录控制 / 电机与 LED 控制器
0x40  = GD32 的 I2C 从机地址
```

***

## 2. ESP32 引脚分配

### 2.1 TFT 显示屏

| 功能             | ESP32 引脚   |
| -------------- | ---------- |
| SPI SCK        | GPIO18     |
| SPI MOSI       | GPIO23     |
| SPI MISO       | GPIO19     |
| TFT DC         | GPIO4      |
| TFT CS         | GPIO5      |
| TFT RES / 相关复用 | GPIO19     |

显示对象信息：

```text
显示分辨率：160 × 128
SPI：SPI2
SPI 频率：40 MHz
SCK：GPIO18
MOSI：GPIO23
MISO：GPIO19
DC：GPIO4
```

屏幕底层通过 `FrameBuffer` 和 `SCREEN` 对象刷新。

***

### 2.2 MicroSD 卡

| 功能         | ESP32 引脚   |
| ---------- | ---------- |
| SPI SCK    | GPIO18     |
| SPI MOSI   | GPIO23     |
| SPI MISO   | GPIO19     |
| SD CS      | GPIO22     |

TFT 与 MicroSD 共用 SPI2，通过不同 CS 分时使用。

***

### 2.3 按键

| 按键         | ESP32 引脚   |
| ---------- | ---------- |
| 上          | GPIO2      |
| 下          | GPIO13     |
| 左          | GPIO27     |
| 右          | GPIO35     |
| A          | GPIO34     |
| B          | GPIO12     |

注意：

```text
GPIO34、GPIO35 是输入专用脚。
GPIO12 是启动相关敏感脚。
```

***

### 2.4 ADC 传感器

| 功能         | ESP32 引脚   |
| ---------- | ---------- |
| 光照传感器      | GPIO36     |
| 热敏电阻       | GPIO39     |

已确认：

```text
sensor.getLight() = ADC(GPIO36).read()
sensor.getTemp()  = ADC(GPIO39) 后换算
```

***

### 2.5 蜂鸣器

| 功能         | ESP32 引脚   |
| ---------- | ---------- |
| 无源蜂鸣器      | GPIO14     |

底层对象：

```text
PWM(14, freq=440, duty=0)
```

也就是：

```text
GPIO14 → PWM → 无源蜂鸣器
```

***

### 2.6 I2C 总线

| 功能         | ESP32 引脚   |
| ---------- | ---------- |
| I2C SCL    | GPIO15     |
| I2C SDA    | GPIO21     |

I2C 设备：

| 地址         | 设备         |
| ---------- | ---------- |
| 0x40       | GD32F350G8 |
| 0x68       | MPU6050    |

当前已确认：

```text
GD32：0x40
MPU6050：0x68，未安装时不会出现在 scan 结果中
```

***

### 2.7 UART0

| 功能         | ESP32 引脚   |
| ---------- | ---------- |
| UART0 TX   | GPIO1      |
| UART0 RX   | GPIO3      |

该 UART0 通过 GD32 转 USB 与电脑通信，用于 Python 终端、程序上传、ESP32 自动下载。

***

## 3. GD32F350G8 连接关系

GD32F350G8 在板上承担以下功能：

```text
1. USB CDC 串口桥
2. ESP32 自动复位 / 自动下载控制
3. I2C 从机 0x40
4. LED1 / LED2 控制
5. 双路电机控制
6. HR8833 / DRV8833 控制信号输出
```

已知相关连接：

| 功能          | 连接对象                     |
| ----------- | ------------------------ |
| USB D+ / D- | USB 接口                   |
| UART 桥      | ESP32 GPIO1 / GPIO3      |
| 自动下载控制      | ESP32 IO0 / 复位相关线路       |
| I2C         | ESP32 GPIO15 / GPIO21    |
| 电机 PWM      | HR8833 / DRV8833         |
| LED 控制      | LED1 / LED2              |
| SWD         | TMS / TCK / RST / GND 焊盘 |

***

## 4. I2C 地址与设备

### 4.1 I2C 总线

```text
I2C 控制器：ESP32 I2C(0)
SCL：GPIO15
SDA：GPIO21
频率：100 kHz
```

### 4.2 地址表

| I2C 地址     | 设备         | 说明         |
| ---------- | ---------- | ---------- |
| 0x40       | GD32F350G8 | LED、电机控制   |
| 0x68       | MPU6050    | 加速度计 / 陀螺仪 |

***

## 5. GD32 0x40 协议

## 5.1 LED 协议

GD32 的 LED 控制使用 I2C memory write 形式。

| 功能         | I2C 地址     | 寄存器        | 数据         |
| ---------- | ---------- | ---------- | ---------- |
| LED1 关闭    | 0x40       | 0xA0       | 0          |
| LED1 打开    | 0x40       | 0xA0       | 1          |
| LED2 关闭    | 0x40       | 0xA1       | 0          |
| LED2 打开    | 0x40       | 0xA1       | 1          |

LED 对象内部状态：

```text
LED1:
  reg = 0xA0

LED2:
  reg = 0xA1
```

***

## 5.2 电机协议概览

电机控制通过 I2C 向 0x40 写入一组 PWM 寄存器格式数据。

基本格式：

```text
I2C 地址：0x40

数据格式：
[
  起始寄存器,
  通道A_ON_L,
  通道A_ON_H,
  通道A_OFF_L,
  通道A_OFF_H,
  通道B_ON_L,
  通道B_ON_H,
  通道B_OFF_L,
  通道B_OFF_H
]
```

每个电机占两个 PWM 通道：

```text
一个通道控制一个方向输入。
另一个通道控制反方向输入。
```

方向逻辑：

```text
方向 1：
  IN_A = PWM
  IN_B = 0

方向 0：
  IN_A = 0
  IN_B = PWM
```

***

## 5.3 电机编号与寄存器

| 电机编号       | 起始寄存器      | 占用通道         |
| ---------- | ---------- | ------------ |
| Motor 2    | 0x06       | PWM 通道 0 / 1 |
| Motor 1    | 0x0E       | PWM 通道 2 / 3 |

***

## 5.4 速度映射

速度参数范围：

```text
speed = 0 ~ 255
```

转换关系：

```text
PWM_12bit = speed × 16
PWM_12bit = speed << 4
```

示例：

| speed      | PWM 十进制    | PWM 十六进制   | 低字节        | 高字节        |
| ---------- | ---------- | ---------- | ---------- | ---------- |
| 0          | 0          | 0x0000     | 0x00       | 0x00       |
| 1          | 16         | 0x0010     | 0x10       | 0x00       |
| 10         | 160        | 0x00A0     | 0xA0       | 0x00       |
| 50         | 800        | 0x0320     | 0x20       | 0x03       |
| 100        | 1600       | 0x0640     | 0x40       | 0x06       |
| 128        | 2048       | 0x0800     | 0x00       | 0x08       |
| 200        | 3200       | 0x0C80     | 0x80       | 0x0C       |
| 255        | 4080       | 0x0FF0     | 0xF0       | 0x0F       |

***

## 5.5 电机 1 数据格式

### Motor 1，方向 1

```text
[
  0x0E,
  0x00, 0x00, PWM_L, PWM_H,
  0x00, 0x00, 0x00, 0x00
]
```

### Motor 1，方向 0

```text
[
  0x0E,
  0x00, 0x00, 0x00, 0x00,
  0x00, 0x00, PWM_L, PWM_H
]
```

***

## 5.6 电机 2 数据格式

### Motor 2，方向 1

```text
[
  0x06,
  0x00, 0x00, PWM_L, PWM_H,
  0x00, 0x00, 0x00, 0x00
]
```

### Motor 2，方向 0

```text
[
  0x06,
  0x00, 0x00, 0x00, 0x00,
  0x00, 0x00, PWM_L, PWM_H
]
```

***

## 5.7 全部电机停止

全停命令：

```text
I2C 地址：0x40
数据：[0x00, 0x00, 0x00, 0x00, 0x00]
```

***

## 6. MPU6050

### 6.1 总线连接

| 功能         | ESP32 引脚   |
| ---------- | ---------- |
| SCL        | GPIO15     |
| SDA        | GPIO21     |

### 6.2 地址

```text
MPU6050 I2C 地址：0x68
```

### 6.3 传感器对象内部字段

```text
addr = 104 = 0x68
imuReady = True / False
imu = 14 字节缓存
```

### 6.4 数据类型

MPU6050 提供：

```text
accX
accY
accZ
gyroX
gyroY
gyroZ
pitch
roll
gesture
```

***

## 7. SugarASR 扩展占用

`sugar_asr.py` 使用：

```text
UART1
TX = GPIO21
RX = GPIO15
波特率 = 115200
```

这与板载 I2C 引脚重合：

```text
GPIO21 = I2C SDA
GPIO15 = I2C SCL
```

因此：

```text
使用 SugarASR 时，GPIO15 / GPIO21 会作为 UART1 使用。
使用 LED、电机、MPU6050 时，GPIO15 / GPIO21 会作为 I2C 使用。
```

***

## 8. 板载扩展 IO

板上预留扩展 IO：

| ESP32 GPIO | 类型               | 说明           |
| ---------- | ---------------- | ------------ |
| GPIO33     | GPIO / ADC       | 可作输入、输出、ADC  |
| GPIO32     | GPIO / ADC       | 可作输入、输出、ADC  |
| GPIO26     | GPIO / DAC / PWM | 可作输出、PWM、DAC |
| GPIO25     | GPIO / DAC / PWM | 可作输出、PWM、DAC |

推荐作为普通扩展口使用的 ESP32 引脚：

```text
GPIO25
GPIO26
GPIO32
GPIO33
```

***

## 9. ESP32 引脚占用总表

| GPIO       | 当前功能                  | 备注               |
| ---------- | --------------------- | ---------------- |
| GPIO1      | UART0 TX              | 经 GD32 转 USB 串口  |
| GPIO2      | 上键                    | 输入               |
| GPIO3      | UART0 RX              | 经 GD32 转 USB 串口  |
| GPIO4      | TFT DC                | 显示               |
| GPIO5      | TFT CS                | 显示               |
| GPIO12     | B 键                   | 启动相关敏感脚          |
| GPIO13     | 下键                    | 输入               |
| GPIO14     | 蜂鸣器                   | PWM              |
| GPIO15     | I2C SCL / SugarASR RX | 与 GPIO21 成组复用    |
| GPIO18     | SPI SCK               | TFT / SD 共用      |
| GPIO19     | SPI MISO / TFT 相关     | TFT / SD 相关      |
| GPIO21     | I2C SDA / SugarASR TX | 与 GPIO15 成组复用    |
| GPIO22     | SD CS                 | MicroSD          |
| GPIO23     | SPI MOSI              | TFT / SD 共用      |
| GPIO25     | 预留扩展                  | GPIO / DAC / PWM |
| GPIO26     | 预留扩展                  | GPIO / DAC / PWM |
| GPIO27     | 左键                    | 输入               |
| GPIO32     | 预留扩展                  | GPIO / ADC       |
| GPIO33     | 预留扩展                  | GPIO / ADC       |
| GPIO34     | A 键                   | 输入专用             |
| GPIO35     | 右键                    | 输入专用             |
| GPIO36     | 光照 ADC                | 输入专用             |
| GPIO39     | 热敏 ADC                | 输入专用             |

***

## 10. 开发用对象映射

| Python 对象 / 模块       | 底层硬件               |
| -------------------- | ------------------ |
| `screen`             | FrameBuffer + TFT  |
| `display`            | 160 × 128 TFT 显示封装 |
| `tft`                | 底层 SCREEN 对象       |
| `fb` / `fbuf`        | FrameBuffer        |
| `vspi`               | SPI2，40 MHz        |
| `i2c`                | I2C0，SCL=15，SDA=21 |
| `led1`               | GD32 0x40，寄存器 0xA0 |
| `led2`               | GD32 0x40，寄存器 0xA1 |
| `buzzer`             | GPIO14 PWM         |
| `sensor.adcLight`    | GPIO36 ADC         |
| `sensor.adcTemp`     | GPIO39 ADC         |
| `sensor.btns`        | 6 个 ESP32 GPIO 按键  |
| `motor.Motor`        | GD32 0x40 电机协议     |
| `sugar_asr.SugarASR` | UART1，TX=21，RX=15  |

***

## 11. 开发时可直接使用的底层信息

### 11.1 I2C

```text
I2C0:
  SCL = GPIO15
  SDA = GPIO21
  freq = 100000

设备：
  0x40 = GD32
  0x68 = MPU6050
```

### 11.2 LED

```text
LED1:
  addr = 0x40
  reg  = 0xA0
  value 0 = off
  value 1 = on

LED2:
  addr = 0x40
  reg  = 0xA1
  value 0 = off
  value 1 = on
```

### 11.3 电机

```text
Motor 1:
  起始寄存器 = 0x0E

Motor 2:
  起始寄存器 = 0x06

speed:
  0 ~ 255
  PWM = speed << 4

direction:
  1 = 第一方向通道 PWM，第二方向通道 0
  0 = 第一方向通道 0，第二方向通道 PWM
```

### 11.4 蜂鸣器

```text
GPIO14
PWM 输出
无源蜂鸣器
```

### 11.5 光照 / 温度

```text
光照：
  GPIO36
  ADC

热敏：
  GPIO39
  ADC
```

### 11.6 按键

```text
up    = GPIO2
down  = GPIO13
left  = GPIO27
right = GPIO35
a     = GPIO34
b     = GPIO12
```

### 11.7 显示

```text
分辨率：160 × 128
SPI：SPI2
SCK：GPIO18
MOSI：GPIO23
MISO：GPIO19
DC：GPIO4
CS：GPIO5
```

### Supported systems:
- Nintendo: **NES, SNES (slow), Gameboy, Gameboy Color, Game & Watch**
- Sega: **SG-1000, Master System, Mega Drive / Genesis, Game Gear**
- Coleco: **Colecovision**
- NEC: **PC Engine**
- Atari: **Lynx**
- Others: **DOOM** (including mods!)

### Retro-Go features:
- In-game menu
- Favorites and recently played
- GB color palettes, RTC adjust and save
- NES color palettes, PAL roms, NSF support
- More emulators and applications
- Scaling and filtering options
- Better performance and compatibility
- Turbo Speed/Fast forward
- Customizable launcher
- Cover art and save state previews
- Multiple save slots per game
- Wifi file manager
- And more!

### Screenshots
![Preview](assets/retro-go-preview.jpg)


# Installation

### ODROID-GO
  1. Download `retro-go_1.x_odroid-go.fw` from the [release page](https://github.com/ducalex/retro-go/releases/) and copy it to `/odroid/firmware` on your sdcard.
  2. Power up the device while holding down B.
  3. Select retro-go in the files list and flash it.

### MyRetroGameCase G32 (GBC)
  1. Download `retro-go_1.x_mrgc-g32.fw` from the [release page](https://github.com/ducalex/retro-go/releases/) and copy it to `/espgbc/firmware` on your sdcard.
  2. Power up the device while holding down MENU (the volume knob).
  3. Select retro-go in the files list and flash it.

### Other devices
  1. Download the .img for your device from the [release page](https://github.com/ducalex/retro-go/releases/).
  2. Connect your device to a computer with a USB cable.
  3. Flash the image with esptool:
     - [Command line](https://github.com/espressif/esptool/releases/): Run `esptool.py write_flash --flash_size detect 0x0 retro-go_*.img`
     - [Web version](https://espressif.github.io/esptool-js/): Connect your device, click Erase Flash, then select your .img file and set address to 0x0, finally click Program)

Your particular device may require extra steps (like holding a button during power up) or different esptool flags or a special cable. If the above steps fail, you might need to ask the manufacturer for instructions on how to flash new firmware!

If your device is not already supported or if a prebuilt version isn't available for it you can check the [development section](#Development) for more information on how to build for your device.


# Usage

## Game covers / artwork
Game covers should be placed in the `romart` folder at the base of your sd card. You can obtain a pre-made pack [here](https://github.com/ducalex/retro-go-covers). Retro-Go is also compatible with the older Go-Play romart pack.

You can add missing cover art by creating a PNG image (160x168, 8bit). Two naming schemes are supported:
- Filename-based: `/romart/nes/Super Mario.png` (notice the rom extension is *not* included)
- CRC32-based: `/romart/nes/A/ABCDE123.png` where `nes` is the same as the rom folder, and `ABCDE123` is the CRC32 of the game (press A -> Properties in the launcher to find it), and `A` is the first character of the CRC32

_Note: CRC32-based, which is what is used in the pre-made pack, is much slower than name-based! This type is useful because filenames vary greatly despite having identical CRCs, but if you generate your own art I suggest you use filename-based format and delete all CRC-based art from your SD Card to improve responsiveness._


## BIOS files
Some emulators support loading a BIOS. The files should be placed as follows:
- GB: `/retro-go/bios/gb_bios.bin`
- GBC: `/retro-go/bios/gbc_bios.bin`
- FDS: `/retro-go/bios/fds_bios.bin`
- MSX: In folder `/retro-go/bios/msx/` put: `MSX.ROM` `MSX2.ROM` `MSX2EXT.ROM` `MSX2P.ROM` `MSX2PEXT.ROM` `FMPAC.ROM` `DISK.ROM` `MSXDOS2.ROM` `PAINTER.ROM` `KANJI.ROM`


## Game & Watch
The roms must be packed with [LCD-Game-Shrinker](https://github.com/bzhxx/LCD-Game-Shrinker) and a tutorial can be [found here](https://gist.github.com/DNA64/16fed499d6bd4664b78b4c0a9638e4ef).


## Wifi
To use wifi you will need to create a `/retro-go/config/wifi.json` config file. You can define up to 4 different networks, then selectable in the menu. Its content should look like this:

````json
{
  "ssid0": "my-network",
  "password0": "my-password",
  "ssid1": "my-other-network",
  "password1": "my-password",
  "ssid2": "my-third-network",
  "password2": "my-password",
  "ssid3": "my-last-network",
  "password3": "my-password"
}
````

### Time synchronization
Time synchronization happens in the launcher immediately after a successful connection to the network.
This is done via NTP by contacting `pool.ntp.org` and cannot be disabled at this time.
Timezone can be configured in the launcher's options menu.

### File manager
You can find the IP of your device in the *about* menu of retro-go. Then on your PC navigate to
http://192.168.x.x/ to access the file manager.


## External DAC (headphones)

Retro-Go supports [the external DAC mod for the ODROID-GO](https://github.com/backofficeshow/odroid-go-audio-hat)
which allows high quality audio through headphones. You can switch to it in the menu `Audio Out: Ext DAC`.

<details>
  <summary>Pinout</summary>

  | GO PIN | PCM5102A PIN |
  |--------|---------|
  | 1 | GND |
  | 2 | - |
  | 3 | LCK |
  | 4 | DIN |
  | 5 | BCK |
  | 6 | VIN |
  | 7 | - |
  | 8 | - |
  | 9 | - |
  | 10 | - |
</details>


# Issues

### Black screen / Boot loops
Retro-Go typically detects and resolves application crashes and freezes automatically. However, if you do
get stuck in a boot loop, you can hold `DOWN` while powering up the device to return to the launcher.

### Sound quality
The volume isn't correctly attenuated on the GO, resulting in upper volume levels that are too loud and
lower levels that are distorted due to DAC resolution. A quick way to improve the audio is to cut one
of the speaker wire and add a `33 Ohm (or thereabout)` resistor in series. Soldering is better but not
required, twisting the wires tightly will work just fine.
[A more involved solution can be seen here.](https://wiki.odroid.com/odroid_go/silent_volume)
Alternatively you can use the headphones DAC mod mentioned earlier in this document.

### Game Boy SRAM *(aka Save/Battery/Backup RAM)*
In Retro-Go, save states will provide you with the best and most reliable save experience. That being said, please
read on if you need or want SRAM saves. The SRAM format is compatible with VisualBoyAdvance so it may be used to
import or export saves.

You can configure automatic SRAM saving in the options menu. A longer delay will reduce stuttering at the cost
of losing data when powering down too quickly. Also note that when *resuming* a game, Retro-Go will give priority
to a save state if present.

### ZIP files
Most Retro-Go applications now support ZIP files. ZIP archives should contain only one ROM file and nothing else. ZIP support also depends on available memory and larger ROMs may fail to load on some devices unfortunately.


# Development
If you wish to build or modify Retro-Go, you can find help in the following documents:

- Build instructions in [BUILDING.md](BUILDING.md)
- Theming instructions [THEMING.md](THEMING.md)
- Porting instructions in [PORTING.md](PORTING.md)
- Translating instructions in [LOCALIZATION.md](LOCALIZATION.md)


# Acknowledgements
- The NES/GBC/SMS emulators and base library were originally from the "Triforce" fork of the [official Go-Play firmware](https://github.com/othercrashoverride/go-play) by crashoverride, Nemo1984, and many others.
- The design of the launcher was originally inspired/copied from [pelle7's go-emu](https://github.com/pelle7/odroid-go-emu-launcher).
- PCE-GO is a fork of [HuExpress](https://github.com/kallisti5/huexpress) and [pelle7's port](https://github.com/pelle7/odroid-go-pcengine-huexpress/) was used as reference.
- The Lynx emulator is a port of [libretro-handy](https://github.com/libretro/libretro-handy).
- The SNES emulator is a port of [Snes9x 2005](https://github.com/libretro/snes9x2005).
- The DOOM engine is a port of [PrBoom 2.5.0](http://prboom.sourceforge.net/).
- The Genesis emulator is a port of [Gwenesis](https://github.com/bzhxx/gwenesis/) by bzhxx.
- The Game & Watch emulator is a port of [lcd-game-emulator](https://github.com/bzhxx/lcd-game-emulator) by bzhxx.
- The MSX emulator is a port of [fMSX](https://fms.komkon.org/fMSX/) by Marat Fayzullin.
- PNG support is provided by [lodepng](https://github.com/lvandeve/lodepng/).
- PCE cover art is from [Christian_Haitian](https://github.com/christianhaitian).
- Some icons from [Rokey](https://iconarchive.com/show/seed-icons-by-rokey.html).
- Background images from [es-theme-gbz35](https://github.com/rxbrad/es-theme-gbz35).
- Special thanks to [RGHandhelds](https://www.rghandhelds.com/) and [MyRetroGamecase](https://www.myretrogamecase.com/) for sending me a [G32](https://www.myretrogamecase.com/products/game-mini-g32-esp32-retro-gaming-console-1) device.
- The [ODROID-GO](https://forum.odroid.com/viewtopic.php?f=159&t=37599) community for encouraging the development of retro-go!

# License
Everything in this project is licensed under the [GPLv2 license](COPYING) with the exception of the following components:
- fmsx/components/fmsx (MSX Emulator, custom non-commercial license)
- handy-go/components/handy (Lynx emulator, zlib)


