local M = {}

---@class Exclude
---@field file_names string[]
---@field file_types string[]
local exclude = {
  file_names = { "term://" },
  file_types = { "lazygit" },
}

---@class Config
---@field exclude Exclude
local config = {
  exclude = exclude,
}

M.get_config = function()
  return config
end

M.get_exclude = function()
  return config.exclude
end

return M
