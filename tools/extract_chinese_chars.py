#!/usr/bin/env python3
import re

def extract_chinese_chars(text):
    """提取所有中文字符"""
    chinese_pattern = re.compile(r'[一-鿿]+')
    return set(''.join(chinese_pattern.findall(text)))

def main():
    # 读取翻译文件
    with open('components/retro-go/translations.h', 'r', encoding='utf-8') as f:
        content = f.read()

    # 提取所有中文字符
    chinese_chars = extract_chinese_chars(content)

    # 排序
    sorted_chars = sorted(chinese_chars)

    # 打印统计信息
    print(f'发现 {len(sorted_chars)} 个不同的汉字:')
    print(''.join(sorted_chars))

    # 保存到文件
    with open('build/chinese_chars.txt', 'w', encoding='utf-8') as f:
        for char in sorted_chars:
            f.write(char)

    print(f'\n已保存到 build/chinese_chars.txt')

    # 创建一个范围字符串供 font_converter.py 使用
    char_codes = [str(ord(c)) for c in sorted_chars]
    # 尝试合并为范围
    ranges = []
    if char_codes:
        start = int(char_codes[0])
        end = start
        for code in char_codes[1:]:
            code = int(code)
            if code == end + 1:
                end = code
            else:
                if start == end:
                    ranges.append(str(start))
                else:
                    ranges.append(f"{start}-{end}")
                start = code
                end = code
        # 添加最后一个范围
        if start == end:
            ranges.append(str(start))
        else:
            ranges.append(f"{start}-{end}")

    print(f'\n字符编码范围: {", ".join(ranges)}')

    with open('build/chinese_ranges.txt', 'w', encoding='utf-8') as f:
        f.write(", ".join(ranges))

    print(f'已保存到 build/chinese_ranges.txt')

if __name__ == '__main__':
    main()
