# XIAOMIAO 4MB Flash 优化配置

## 当前优化

### 1. 精简应用列表
**只保留核心功能：**
- ✅ launcher - 启动器
- ✅ retro-core - NES/SMS/GG/PC Engine 模拟器

**移除：**
- ❌ prboom-go (DOOM) - 占用空间大
- ❌ gwenesis (Genesis) - 占用空间大
- ❌ fmsx (MSX)

这样可以从约 4.3MB 减少到约 2MB。

### 2. sdkconfig 优化
- ✅ Flash size 设置为 4MB
- ✅ 禁用 WiFi
- ✅ 禁用 Bluetooth
- ✅ 禁用日志输出（LOG_DEFAULT_LEVEL=0）
- ✅ 优化大小编译（CONFIG_COMPILER_OPTIMIZATION_SIZE=y）
- ✅ 禁用断言（节省空间）

### 3. 分区大小
- launcher: 1MB
- retro-core: 1MB
- **总计：约 2MB**（剩余空间留作 SPI flash 缓存）

## 构建命令

### 快速测试（仅 launcher）
```bash
./build_xiaomiao.sh quick
```

### 完整构建（优化版）
```bash
./build_xiaomiao.sh
```

### 清理
```bash
./build_xiaomiao.sh clean
```

## 如果需要更多模拟器

### 方案1：分阶段构建
只构建需要的模拟器，例如：
```bash
# 只构建 launcher + retro-core
python3 rg_tool.py --target xiaomiao build-img launcher retro-core
```

### 方案2：添加 DOOM（如果空间足够）
修改 `env.py`：
```python
DEFAULT_APPS = "launcher retro-core prboom-go"
```
但是这可能接近 3MB，需要检查是否还能放得下。

### 方案3：使用 OTA 或 SD 卡加载
需要修改固件架构，比较复杂。

## 验证固件大小

构建完成后检查：
```bash
ls -lh build/
```

理想情况下：
- `.img` 文件大小应该在 2-2.5MB 之间
- 每个 `.bin` 文件：
  - launcher.bin: ~500KB
  - retro-core.bin: ~800KB

## 更多优化建议

如果还需要更多空间：

### 1. 编译优化
在 sdkconfig 中：
```
CONFIG_COMPILER_OPTIMIZATION_SIZE=y
CONFIG_COMPILER_OPTIMIZATION_ASSERTIONS_DISABLE=y
```

### 2. 移除调试信息
在 CMakeLists.txt 中添加：
```cmake
target_compile_options(${COMPONENT_LIB} PRIVATE -g0)
```

### 3. 禁用 Retro-Go 功能
在 config.h 中：
```c
#define RG_ENABLE_NETWORKING 0
#define RG_ENABLE_PROFILING 0
```
