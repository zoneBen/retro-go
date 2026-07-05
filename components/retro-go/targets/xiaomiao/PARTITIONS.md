# XIAOMIAO 4MB Flash 分区布局

## 总 Flash 大小: 4MB (0x400000)

## 分区分配方案

| 分区名称 | 类型 | 偏移 | 大小 | 说明 |
|---------|------|------|------|------|
| nvs | data | 0x9000 | 0x4000 (16KB) | NVS 配置存储 |
| otadata | data | 0xD000 | 0x2000 (8KB) | OTA 数据 |
| phy_init | data | 0xF000 | 0x1000 (4KB) | PHY 初始化数据 |
| launcher | app | 0x10000 | 0x100000 (1MB) | 启动器 |
| retro-core | app | 0x110000 | 0x1C0000 (1.75MB) |  retro-core 模拟器 |
| (保留) | - | 0x2D0000 | 0x130000 (1.1875MB) | 未来扩展 |

## 当前使用情况

- retro-core 固件大小: ~0x16b7d0 (1.42MB)
- 分配给 retro-core: 0x1C0000 (1.75MB)
- 剩余空间: ~0x54830 (346KB)

## 注意事项

1. 保留的空间可用于未来添加其他应用（如 prboom-go、gwenesis 等）
2. 如需添加更多应用，需要重新调整分区大小
3. 总大小不能超过 4MB (0x400000)
