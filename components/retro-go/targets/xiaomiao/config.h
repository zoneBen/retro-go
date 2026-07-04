// Target definition
#define RG_TARGET_NAME             "XIAOMIAO"

// Storage
#define RG_STORAGE_ROOT             "/sd"
#define RG_STORAGE_SDSPI_HOST       SPI2_HOST
#define RG_STORAGE_SDSPI_SPEED      SDMMC_FREQ_DEFAULT

// GPIO Extender
// #define RG_I2C_GPIO_DRIVER          0   // 1 = AW9523, 2 = PCF9539, 3 = MCP23017
// #define RG_I2C_GPIO_ADDR            0x00

// Audio
// 注意：此硬件使用 GPIO14 蜂鸣器，Retro-Go 使用内部 DAC
// 将使用 GPIO25/26 作为音频输出（如果需要音频）
#define RG_AUDIO_USE_INT_DAC        0   // 0 = Disable, 1 = GPIO25, 2 = GPIO26, 3 = Both
#define RG_AUDIO_USE_EXT_DAC        0   // 0 = Disable, 1 = Enable

// Video - 160x128 ST7735/ST7789 显示屏
#define RG_SCREEN_DRIVER            0   // 0 = ILI9341/ST7789
#define RG_SCREEN_HOST              SPI2_HOST
#define RG_SCREEN_SPEED             SPI_MASTER_FREQ_40M
#define RG_SCREEN_BACKLIGHT         0   // 无背光控制或常亮
#define RG_SCREEN_WIDTH             160
#define RG_SCREEN_HEIGHT            128
#define RG_SCREEN_ROTATE            3   // 试试这个值: 0,1,2,3
#define RG_SCREEN_RGB_BGR           0   // 0 = RGB, 1 = BGR
#define RG_SCREEN_VISIBLE_AREA      {0, 0, 0, 0}
#define RG_SCREEN_SAFE_AREA         {0, 0, 0, 0}

// ST7735 160x128 初始化序列（根据您的显示屏可能需要调整）
#define RG_SCREEN_INIT()                                                                                         \
    ILI9341_CMD(0x01);                                                                                          \
    ILI9341_CMD(0x11);                                                                                          \
    ILI9341_CMD(0xB1, 0x01, 0x2C, 0x2D);                                                                       \
    ILI9341_CMD(0xB2, 0x01, 0x2C, 0x2D);                                                                       \
    ILI9341_CMD(0xB3, 0x01, 0x2C, 0x2D, 0x01, 0x2C, 0x2D);                                                     \
    ILI9341_CMD(0xB4, 0x07);                                                                                   \
    ILI9341_CMD(0xC0, 0xA2, 0x02, 0x84);                                                                       \
    ILI9341_CMD(0xC1, 0xC5);                                                                                   \
    ILI9341_CMD(0xC2, 0x0A, 0x00);                                                                             \
    ILI9341_CMD(0xC3, 0x8A, 0x2A);                                                                             \
    ILI9341_CMD(0xC4, 0x8A, 0xEE);                                                                             \
    ILI9341_CMD(0xC5, 0x0E);                                                                                   \
    \
    ILI9341_CMD(0x3A, 0x05);         /* 像素格式: 16-bit/pixel */                                             \
    ILI9341_CMD(0xE0, 0x0F, 0x1A, 0x0F, 0x18, 0x2F, 0x28, 0x20, 0x22, 0x1F, 0x1B, 0x23, 0x37, 0x00, 0x07, 0x02, 0x10); \
    ILI9341_CMD(0xE1, 0x0F, 0x1B, 0x0F, 0x17, 0x33, 0x2C, 0x29, 0x2E, 0x30, 0x30, 0x39, 0x3F, 0x00, 0x07, 0x03, 0x10); \
    ILI9341_CMD(0x29);

// Input - 6 按键 GPIO 配置
// 注意：GPIO34/35 是仅输入引脚，不能配置 pullup（需要外部上拉）
// 注意：GPIO12 是启动敏感引脚，确保有外部上拉
#define RG_GAMEPAD_GPIO_MAP {\
    {RG_KEY_UP,     .num = GPIO_NUM_2,  .pullup = 1, .pulldown = 0, .level = 0},\
    {RG_KEY_DOWN,   .num = GPIO_NUM_13, .pullup = 1, .pulldown = 0, .level = 0},\
    {RG_KEY_LEFT,   .num = GPIO_NUM_27, .pullup = 1, .pulldown = 0, .level = 0},\
    {RG_KEY_RIGHT,  .num = GPIO_NUM_35, .pullup = 0, .pulldown = 0, .level = 0},\
    {RG_KEY_A,      .num = GPIO_NUM_34, .pullup = 0, .pulldown = 0, .level = 0},\
    {RG_KEY_B,      .num = GPIO_NUM_12, .pullup = 1, .pulldown = 0, .level = 0},\
}

// 虚拟按键映射 - 使用组合键模拟菜单等功能
#define RG_GAMEPAD_VIRT_MAP {\
    {RG_KEY_SELECT, .src = RG_KEY_UP | RG_KEY_DOWN},\
    {RG_KEY_START,  .src = RG_KEY_LEFT | RG_KEY_RIGHT},\
    {RG_KEY_MENU,   .src = RG_KEY_A | RG_KEY_B},\
}

// Battery - 此硬件无电池检测，禁用
#define RG_BATTERY_DRIVER           0

// Status LED - 无专用 LED，可复用蜂鸣器或禁用
// #define RG_GPIO_LED                 GPIO_NUM_14

// I2C BUS - 可用但当前无用途
#define RG_GPIO_I2C_SDA             GPIO_NUM_21
#define RG_GPIO_I2C_SCL             GPIO_NUM_15

// SPI Display - TFT 显示屏引脚
#define RG_GPIO_LCD_MISO            GPIO_NUM_19  // 与 SD 卡共享
#define RG_GPIO_LCD_MOSI            GPIO_NUM_23  // 与 SD 卡共享
#define RG_GPIO_LCD_CLK             GPIO_NUM_18  // 与 SD 卡共享
#define RG_GPIO_LCD_CS              GPIO_NUM_5
#define RG_GPIO_LCD_DC              GPIO_NUM_4
// RST 与 MISO 共享 GPIO19，不通过软件控制 RST
// #define RG_GPIO_LCD_RST             GPIO_NUM_NC
// #define RG_GPIO_LCD_BCKL            GPIO_NUM_NC  // 无背光控制

// SPI SD Card - MicroSD 卡引脚
#define RG_GPIO_SDSPI_MISO          GPIO_NUM_19
#define RG_GPIO_SDSPI_MOSI          GPIO_NUM_23
#define RG_GPIO_SDSPI_CLK           GPIO_NUM_18
#define RG_GPIO_SDSPI_CS            GPIO_NUM_22

// External I2S DAC - 此硬件无
// #define RG_GPIO_SND_I2S_BCK         GPIO_NUM_NC
// #define RG_GPIO_SND_I2S_WS          GPIO_NUM_NC
// #define RG_GPIO_SND_I2S_DATA        GPIO_NUM_NC
// #define RG_GPIO_SND_AMP_ENABLE      GPIO_NUM_NC

// Updater - 禁用
#define RG_UPDATER_ENABLE           0

// Default language - 默认语言为中文
// (This overrides the default in the main config.h)
#define RG_LANG_DEFAULT             RG_LANG_ZH

// Default font - use Chinese font
#define RG_FONT_DEFAULT             RG_FONT_CHINESE_12
