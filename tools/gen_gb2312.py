#!/usr/bin/env python3
import os

def generate_font_chars():
    # 确保 build 目录存在
    os.makedirs('build', exist_ok=True)
    
    chars = []
    
    # 1. 基础 ASCII 字符 (32-126，包含英文字母、数字、英文标点符号)
    for code in range(32, 127):
        chars.append(chr(code))
        
    # 2. GB2312 符号区 (01-09区，包含中文标点如 ，。《》、特殊符号等)
    # 高位 0xA1-0xA9, 低位 0xA1-0xFE
    for high in range(0xA1, 0xAA):
        for low in range(0xA1, 0xFF):
            try:
                char = bytes([high, low]).decode('gb2312')
                chars.append(char)
            except UnicodeDecodeError:
                pass
                
    # 3. GB2312 汉字区 (16-87区，6763个常用汉字)
    # 高位 0xB0-0xF7, 低位 0xA1-0xFE
    for high in range(0xB0, 0xF8):
        for low in range(0xA1, 0xFF):
            try:
                char = bytes([high, low]).decode('gb2312')
                chars.append(char)
            except UnicodeDecodeError:
                pass
                
    # 去重并保持原有顺序 (ASCII -> 符号 -> 汉字)
    unique_chars = list(dict.fromkeys(chars))
    
    # 保存字符文件
    ui_chars_path = 'build/ui_chars.txt'
    with open(ui_chars_path, 'w', encoding='utf-8') as f:
        f.write(''.join(unique_chars))
        
    # 自动配置 chinese_ranges.txt
    ranges_path = 'build/chinese_ranges.txt'
    with open(ranges_path, 'w', encoding='utf-8') as f:
        f.write(f'file:{ui_chars_path}\n')
        
    print(f"✅ 成功生成 {len(unique_chars)} 个字符（含 ASCII + 中文符号 + 6763 汉字）！")
    print(f"📄 字符文件已保存至: {ui_chars_path}")
    print(f"⚙️  范围配置已自动写入: {ranges_path}")
    print("👉 接下来请直接运行: python3 tools/generate_chinese_font.py")

if __name__ == '__main__':
    generate_font_chars()
	