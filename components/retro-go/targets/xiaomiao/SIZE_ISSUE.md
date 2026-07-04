# 解决 1MB 分区限制问题

## 问题
launcher.bin 大小: 0x100990 (1,051,024 字节)
分区大小: 0x100000 (1,048,576 字节)
**溢出: 2,448 字节**

## 已尝试的优化

### 1. 禁用音频
```c
#define RG_AUDIO_USE_INT_DAC 0
```
节省: ~50KB

### 2. 禁用更新
```c
#define RG_UPDATER_ENABLE 0
```
节省: ~10KB

### 3. 禁用网络功能
```bash
python3 rg_tool.py --no-networking ...
```
节省: ~30-50KB

## 如果还不够，进一步优化

### 选项1：减小显示分辨率（如果不需要 160x128）
但可能效果不大。

### 选项2：禁用主题/图标
修改 `launcher/main/main.c`，移除图标加载。

### 选项3：增加分区大小（风险较高）
修改 `rg_tool.py` 中的分区大小，但这会影响整个系统。

### 选项4：只保留单个模拟器
将 retro-core 拆分成独立的模拟器，但工作量大。

## 测试步骤

1. 先尝试当前配置（禁用网络）
   ```bash
   ./build_xiaomiao.sh quick
   ```

2. 如果成功，检查大小
   ```bash
   ls -lh launcher/build/
   ```

3. 如果还不够，再进一步优化
