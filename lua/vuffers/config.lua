local M = {}

---@class Exclude
---@field filenames string[]
---@field filetypes string[]

---@class Handlers
---@field on_delete_buffer fun(bufnr: number)

---@class DebugConfig
---@field enabled boolean
---@field level LogLevel

---@class SortOrder
---@field type SortType
---@field direction SortDirection

---@class View
---@field modified_icon string
---@field window {width: number, focus_on_open: boolean }

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

---@param width number
M.set_window_width = function(width)
  config.view.window.width = width
end

---@param level LogLevel
M.set_log_level = function(level)
  config.debug.level = level
end

---@param user_config Config
function M.setup(user_config)
  ---@type Config
  local default = {
    debug = {
      enabled = true,
      level = "error",
    },
    exclude = {
      filenames = { "term://" },
      filetypes = { "lazygit", "NvimTree", "qf" },
    },
    handlers = {
      on_delete_buffer = function(bufnr)
        vim.api.nvim_command(":bwipeout " .. bufnr)
      end,
    },
    sort = {
      type = "none",
      direction = "asc",
    },
    view = {
      modified_icon = "󰛿",
      window = { width = 35, focus_on_open = false },
    },
  }

  config = vim.tbl_deep_extend("force", default, user_config or {})
end

return M
