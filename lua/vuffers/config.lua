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

---@class DebugConfig
---@field enabled boolean
---@field log_level 'debug' | 'info' | 'warn' | 'error'
local default_debug_config = {
  enabled = true,
  log_level = "debug",
}

---@class Config
---@field debug DebugConfig
---@field exclude Exclude
---@field handlers Handlers
local config = {}

M.get_config = function()
  return config
end

M.get_exclude = function()
  return config.exclude
end

M.get_handlers = function()
  return config.handlers
end

---@param user_config Config
function M.setup(user_config)
  local debug_config = vim.tbl_deep_extend("force", default_debug_config, user_config.debug or {})

  config = {
    debug = debug_config,
    exclude = exclude,
    handlers = handlers,
  }
end

return M
