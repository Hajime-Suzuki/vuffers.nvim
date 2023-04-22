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

---@class SortOrder
---@field type SortType
---@field direction SortDirection
local default_sort = {
  type = "none",
  direction = "asc",
}

---@class View
---@field modified_icon string
local default_view = {
  modified_icon = "󰛿",
}

---@class Config
---@field debug DebugConfig
---@field exclude Exclude
---@field handlers Handlers
---@field sort SortOrder
---@field view View
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

M.get_view_config = function()
  return config.view
end

---@param sort {type: SortType, direction: SortDirection}
M.set_sort = function(sort)
  config.sort = vim.tbl_deep_extend("force", config.sort, sort)
end

---@param user_config Config
function M.setup(user_config)
  local debug_config = vim.tbl_deep_extend("force", default_debug_config, user_config.debug or {})
  local view_config = vim.tbl_deep_extend("force", default_view, user_config.view or {})
  local exclude_config = vim.tbl_deep_extend("force", default_exclude, user_config.view or {})
  local handlers_config = vim.tbl_deep_extend("force", default_handlers, user_config.view or {})
  local sort_config = vim.tbl_deep_extend("force", default_sort, user_config.view or {})

  config = {
    debug = debug_config,
    exclude = exclude_config,
    handlers = handlers_config,
    sort = sort_config,
    view = view_config,
  }
end

return M
