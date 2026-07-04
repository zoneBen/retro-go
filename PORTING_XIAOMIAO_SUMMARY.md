# Retro-Go XIAOMIAO 移植完成总结

## 已完成的工作

### 1. 分支创建
- 从 master 分支创建了 xiaomiao 分支

### 2. 目标设备配置
创建了 `components/retro-go/targets/xiaomiao/` 目录，包含：

#### `config.h`
- 目标名称：XIAOMIAO
- 显示配置：160x128 ST7735，SPI2 总线
- 按键配置：6个 GPIO 按键 + 虚拟按键组合
- 存储配置：SPI SD 卡，与显示共享 SPI2
- 音频配置：内部 DAC (GPIO25/26)
- 特殊处理：
  - GPIO34/35 (仅输入) 不设置内部上拉
  - GPIO12 (启动敏感) 配置为内部上拉
  - RST 与 MISO 共享，禁用软件 RST

#### `env.py`
- 芯片类型：ESP32
- FW 格式：None (使用 .img)

#### `sdkconfig`
- 基于 odroid-go 的配置
- 启用 PSRAM
- 启用长文件名支持 (UTF-8)
- 240MHz CPU 频率
- 优化大小编译

#### `README.md`
- 详细的硬件说明
- 引脚分配表
- 已知问题和注意事项
- 构建和烧录指南
- 调试建议

#### `HARDWARE.md`
- 完整的硬件资源说明
- 引脚分配总表
- 关键限制和注意事项

### 3. 主配置更新
- 在 `components/retro-go/config.h` 中添加了 `RG_TARGET_XIAOMIAO` 支持

### 4. 中文移植指南
- 创建了 `PORTING_GUIDE.md`，提供详细的中文移植说明

## 硬件配置回顾

### 按键映射
| 按键 | 引脚 | 类型 |
|------|------|------|
| UP | GPIO2 | 普通，内部上拉 |
| DOWN | GPIO13 | 普通，内部上拉 |
| LEFT | GPIO27 | 普通，内部上拉 |
| RIGHT | GPIO35 | 仅输入，需外部上拉 |
| A | GPIO34 | 仅输入，需外部上拉 |
| B | GPIO12 | 启动敏感，内部上拉 |

### 虚拟按键
| 组合 | 功能 |
|------|------|
| UP + DOWN | SELECT |
| LEFT + RIGHT | START |
| A + B | MENU |

### SPI 共享
显示屏和 SD 卡共享 SPI2 总线：
- SCK: GPIO18
- MOSI: GPIO23
- MISO/RST: GPIO19
- TFT CS: GPIO5
- SD CS: GPIO22

## 下一步操作

### 1. 硬件检查
确保：
- [ ] GPIO34/35 有外部上拉电阻 (10kΩ)
- [ ] GPIO12 有外部上拉电阻
- [ ] 其他按键电路正常
- [ ] 显示屏连接正确

### 2. 软件环境设置
```bash
# 克隆项目 (如果还没)
git clone https://github.com/ducalex/retro-go.git
cd retro-go

# 切换到 xiaomiao 分支
git checkout xiaomiao

# 激活 ESP-IDF 环境
. $HOME/esp/esp-idf/export.sh
```

### 3. 首次构建和测试
```bash
# 尝试构建 launcher
python rg_tool.py --target xiaomiao build launcher

# 如果成功，进入 launcher 目录配置 sdkconfig
cd launcher
idf.py menuconfig

# 关键配置检查：
# - 启用 PSRAM (如果硬件有)
# - 启用长文件名支持

# 复制回目标目录
cp sdkconfig ../components/retro-go/targets/xiaomiao/
cd ..

# 完整构建
python rg_tool.py --target xiaomiao build-img
```

### 4. 调试和调整
1. 测试显示屏是否正常
2. 测试按键是否响应
3. 测试 SD 卡能否挂载
4. 根据需要调整显示初始化序列
5. 根据需要调整按键映射

## 可能需要的调整

### 1. 显示初始化
如果显示异常，尝试调整 `config.h` 中的：
- `RG_SCREEN_ROTATE` (0/90/180/270)
- `0x36` 命令中的 RGB/BGR 位 (0x08)
- 整个初始化序列

### 2. 按键配置
如果按键不工作：
- 检查外部上拉
- 调整 `.level` (0 或 1)
- 调整触发方式

### 3. 添加更多功能
可选的增强：
- 蜂鸣器音频驱动
- 背光控制
- 传感器读取
- 自定义主题

## 参考文档

- `PORTING_GUIDE.md` - 详细的中文移植指南
- `components/retro-go/targets/xiaomiao/README.md` - 设备特定说明
- `BUILDING.md` - 构建说明
- `PORTING.md` - 官方移植指南

## 注意事项

⚠️ **GPIO12 启动问题**：确保启动时不按下 B 键，或确保 GPIO12 电平正确

⚠️ **GPIO34/35 上拉**：必须有外部上拉电阻

⚠️ **RST/MISO 共享**：如果显示不稳定，考虑硬件修改

⚠️ **PSRAM 需求**：Retro-Go 需要 PSRAM 才能正常工作

## 贡献

如果这个移植成功工作，欢迎提交 PR 到 Retro-Go 主仓库！
