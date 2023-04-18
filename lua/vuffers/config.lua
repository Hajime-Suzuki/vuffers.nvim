local M = {}

---@class Exclude
---@field file_names string[]
---@field file_types string[]
local default_exclude = {
  file_names = { "term://" },
  file_types = { "lazygit", "NvimTree" },
}

---@class Handlers
---@field on_delete_buffer fun(bufnr: number)
local default_handlers = {
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

---@class Sort
---@field type 'none' | 'filename'
---@field direction 'asc' | 'desc'
local default_sort = {
  type = "none",
  direction = "asc",
}

---@class Config
---@field debug DebugConfig
---@field exclude Exclude
---@field handlers Handlers
---@field sort Sort
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

M.get_sort = function()
  return config.sort
end

---@param sort {type: Sort['direction'], direction: Sort['direction']}
M.set_sort = function(sort)
  config.sort = vim.tbl_deep_extend("keep", config.sort, sort)
end

---@param user_config Config
function M.setup(user_config)
  local debug_config = vim.tbl_deep_extend("force", default_debug_config, user_config.debug or {})

  config = {
    debug = debug_config,
    exclude = default_exclude,
    handlers = default_handlers,
    sort = default_sort,
  }
end

return M
