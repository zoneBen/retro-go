# This file is injected late into rg_tool.py, you can run arbitrary python code here
# For example override python variables or set environment variables with os.putenv

# Espressif chip in the device
# TODO: 根据您的芯片类型修改：esp32, esp32s2, esp32s3, esp32p4
IDF_TARGET = "esp32"
# .fw file format, if supported by the device
FW_FORMAT = None
# Default apps to build when none is specified (comment to build all)
# DEFAULT_APPS = "launcher prboom-go retro-core"
