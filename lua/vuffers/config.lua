local M = {}

---@class Exclude
---@field file_names string[]
---@field file_types string[]
local exclude = {
  file_names = { "term://" },
  file_types = { "lazygit", "NvimTree" },
}

---@class Handlers
---@field on_delete_buffer fun(bufnr: number)
local handlers = {
  on_delete_buffer = function(bufnr)
    vim.api.nvim_command(":bwipeout " .. bufnr)
  end,
}

---@class Config
---@field exclude Exclude
---@field handlers Handlers
local config = {
  exclude = exclude,
  handlers = handlers,
}

M.get_config = function()
  return config
end

M.get_exclude = function()
  return config.exclude
end

M.get_handlers = function()
  return config.handlers
end

return M
