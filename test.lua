local colors = require "colors"
local component = require "component"
local gpu = component.gpu

local pixel_char = "▀"

gpu.setForeground(colors.white)
gpu.setBackground(colors.black)

gpu.fill(1, 1, 10, 10, " ")
