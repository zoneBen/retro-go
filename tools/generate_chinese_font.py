#!/usr/bin/env python3
"""
Generate Chinese font for Retro-Go
Uses the same format as font_converter.py
"""
import os
import sys
from PIL import Image, ImageDraw, ImageFont


def get_char_list(ranges_str):
    """Parse character ranges string"""
    if isinstance(ranges_str, str):
        ranges_str = ranges_str.replace(" ", "").split(',')
    list_char = []
    for intervals in ranges_str:
        first = intervals.split('-')[0]
        try:
            second = intervals.split('-')[1]
        except IndexError:
            list_char.append(int(first, 0))
        else:
            second = intervals.split('-')[1]
            for char in range(int(first, 0), int(second, 0) + 1):
                list_char.append(char)
    return sorted(set(list_char))


def find_bounding_box(image):
    """Find the bounding box of non-zero pixels"""
    pixels = image.load()
    width, height = image.size
    x_min, y_min = width, height
    x_max, y_max = 0, 0

    for y in range(height):
        for x in range(width):
            if pixels[x, y] >= 1:  # Looking for 'on' pixels
                x_min = min(x_min, x)
                y_min = min(y_min, y)
                x_max = max(x_max, x)
                y_max = max(y_max, y)

    if x_min > x_max or y_min > y_max:  # No target pixels found
        return None
    return (x_min, y_min, x_max + 1, y_max + 1)


def find_chinese_font():
    """Find a suitable Chinese font"""
    # Common font paths
    font_dirs = [
        "/usr/share/fonts/truetype/noto",
        "/usr/share/fonts/opentype/noto",
        "/usr/share/fonts/noto",
        "/usr/share/fonts/truetype/wqy",
        "/usr/share/fonts/wqy",
        "/usr/share/fonts/opentype",
        "/usr/share/fonts/truetype",
        "/usr/share/fonts",
        "/Library/Fonts",
        "C:\\Windows\\Fonts",
    ]

    # Font patterns to look for
    font_patterns = [
        "NotoSansCJK",
        "Noto Sans CJK",
        "wqy",
        "WenQuanYi",
        "SimHei",
        "SimSun",
        "Microsoft YaHei",
        "SourceHanSans",
    ]

    for font_dir in font_dirs:
        if not os.path.exists(font_dir):
            continue
        for root, _, files in os.walk(font_dir):
            for font_file in files:
                if font_file.endswith(('.ttf', '.ttc', '.otf')):
                    if any(pattern.lower() in font_file.lower() for pattern in font_patterns):
                        try:
                            font_path = os.path.join(root, font_file)
                            ImageFont.truetype(font_path, 12)
                            print(f"Found font: {font_path}")
                            return font_path
                        except Exception:
                            continue

    # Fallback to whatever we can find
    print("Looking for any TTF font...")
    for font_dir in font_dirs:
        if not os.path.exists(font_dir):
            continue
        for root, _, files in os.walk(font_dir):
            for font_file in files:
                if font_file.endswith(('.ttf', '.otf')):
                    try:
                        font_path = os.path.join(root, font_file)
                        ImageFont.truetype(font_path, 12)
                        print(f"Using fallback font: {font_path}")
                        return font_path
                    except Exception:
                        continue

    return None


def load_ttf_font(font_path, font_size, char_ranges):
    """Load TTF font and convert to Retro-Go format"""
    try:
        pil_font = ImageFont.truetype(font_path, font_size)
    except Exception as e:
        print(f"Error loading font: {e}")
        sys.exit(1)

    font_name = ' '.join(pil_font.getname())
    font_data = []

    for char_code in get_char_list(char_ranges):
        try:
            char = chr(char_code)
        except:
            continue

        # Generate mono bitmap
        image = Image.new("1", (font_size * 2, font_size * 2), 0)  # 0 = black
        draw = ImageDraw.Draw(image)
        # Draw at pos 1 to avoid clipping
        draw.text((1, 0), char, font=pil_font, fill=255)

        bbox = find_bounding_box(image)

        if bbox is None:  # Control character / space
            width, height = 0, 0
            offset_x, offset_y = 0, 0
        else:
            x0, y0, x1, y1 = bbox
            width, height = x1 - x0, y1 - y0
            offset_x, offset_y = x0, y0
            if offset_x:
                offset_x -= 1

        # Get real glyph width
        try:
            adv_w = int(draw.textlength(char, font=pil_font))
            adv_w = max(adv_w, width + offset_x)
        except:
            adv_w = width + offset_x

        # Extract bitmap data
        bitmap = []
        if bbox is not None and width > 0 and height > 0:
            cropped_image = image.crop(bbox)
            row = 0
            i = 0
            for y in range(height):
                for x in range(width):
                    if i == 8:
                        bitmap.append(row)
                        row = 0
                        i = 0
                    pixel = 1 if cropped_image.getpixel((x, y)) else 0
                    row = (row << 1) | pixel
                    i += 1
            bitmap.append(row << 8 - i)  # Fill remaining bits
            bitmap = bitmap[0:int((width * height + 7) / 8)]

        # Create glyph entry
        glyph_data = {
            "char_code": char_code,
            "ofs_y": int(offset_y),
            "box_w": int(width),
            "box_h": int(height),
            "ofs_x": int(offset_x),
            "adv_w": int(adv_w),
            "bitmap": bitmap,
        }
        font_data.append(glyph_data)

    # Adjust vertical alignment
    max_height = max(g["ofs_y"] + g["box_h"] for g in font_data) if font_data else font_size
    if max_height > font_size:
        min_ofs_y = min((g["ofs_y"] if g["box_h"] > 0 else 1000) for g in font_data)
        for key, glyph in enumerate(font_data):
            offset = glyph["ofs_y"]
            if min_ofs_y > 0 and offset >= min_ofs_y:
                offset -= min_ofs_y
            font_data[key]["ofs_y"] = offset
        max_height = max(g["ofs_y"] + g["box_h"] for g in font_data)

    print(f"Glyphs: {len(font_data)}, font_size: {font_size}, max_height: {max_height}")
    return (font_name, font_size, font_data)


def get_ranges_list(char_codes):
    """Convert list of char codes to range string"""
    char_codes = sorted(set(char_codes))
    if not char_codes:
        return ""
    ranges = []
    start = char_codes[0]
    for i in range(1, len(char_codes)):
        if char_codes[i] != char_codes[i - 1] + 1:
            ranges.append(f"{start}-{char_codes[i - 1]}" if start != char_codes[i - 1] else str(start))
            start = char_codes[i]
    ranges.append(f"{start}-{char_codes[-1]}" if start != char_codes[-1] else str(start))
    return ranges


def generate_c_font(font_name, font_size, font_data):
    """Generate C font file in Retro-Go format"""
    normalized_name = f"Chinese{font_size}"
    max_height = max(font_size, max(g["ofs_y"] + g["box_h"] for g in font_data)) if font_data else font_size
    memory_usage = sum(len(g["bitmap"]) + 8 for g in font_data) if font_data else 0
    char_ranges = ", ".join(get_ranges_list([g["char_code"] for g in font_data])) if font_data else ""

    file_data = "#include \"../rg_gui.h\"\n\n"
    file_data += "// File generated with generate_chinese_font.py\n\n"
    file_data += f"// Font           : {font_name}\n"
    file_data += f"// Point Size     : {font_size}\n"
    file_data += f"// Memory usage   : {memory_usage} bytes\n"
    file_data += f"// Characters     : {len(font_data)} ({char_ranges})\n\n"
    file_data += f"const rg_font_t font_{normalized_name} = {{\n"
    file_data += f"    .name = \"Chinese {font_size}\",\n"
    file_data += f"    .type = 1,\n"
    file_data += f"    .width = 0,\n"
    file_data += f"    .height = {max_height},\n"
    file_data += f"    .chars = {len(font_data)},\n"
    file_data += f"    .data = {{\n"

    for glyph in font_data:
        char_code = glyph['char_code']
        header_data = [char_code & 0xFF, char_code >> 8, glyph['ofs_y'], glyph['box_w'],
                      glyph['box_h'], glyph['ofs_x'], glyph['adv_w']]
        try:
            display_char = chr(char_code)
        except:
            display_char = "?"
        file_data += f"        /* U+{char_code:04X} '{display_char}' */\n        "
        file_data += ", ".join([f"0x{byte:02X}" for byte in header_data])
        file_data += f",\n        "
        if len(glyph["bitmap"]) > 0:
            file_data += ", ".join([f"0x{byte:02X}" for byte in glyph["bitmap"]])
            file_data += f","
        file_data += "\n"

    file_data += "\n"
    file_data += "        // Terminator\n"
    file_data += "        0x00, 0x00,\n"
    file_data += "    },\n"
    file_data += "};\n"

    return file_data


def main():
    # Read the extracted character ranges
    ranges_file = "build/chinese_ranges.txt"
    if not os.path.exists(ranges_file):
        print(f"Error: {ranges_file} not found. Run extract_chinese_chars.py first.")
        sys.exit(1)

    with open(ranges_file, 'r', encoding='utf-8') as f:
        char_ranges = f.read().strip()

    # Also add basic ASCII for convenience
    char_ranges = "32-127, " + char_ranges

    print(f"Character ranges: {char_ranges}")

    # Find font
    font_path = find_chinese_font()
    if not font_path:
        print("Error: Could not find a suitable font.")
        print("Please install fonts-noto-cjk or fonts-wqy-microhei")
        sys.exit(1)

    # Generate font
    font_size = 12
    print(f"Generating Chinese font (size {font_size})...")
    font_name, font_size, font_data = load_ttf_font(font_path, font_size, char_ranges)

    # Save the output
    output_file = "components/retro-go/fonts/Chinese12.c"
    c_code = generate_c_font(font_name, font_size, font_data)

    with open(output_file, 'w', encoding='utf-8') as f:
        f.write(c_code)

    print(f"Font saved to: {output_file}")
    print(f"Generated {len(font_data)} glyphs")


if __name__ == "__main__":
    main()
