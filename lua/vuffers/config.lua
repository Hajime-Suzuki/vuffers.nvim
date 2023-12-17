local constants = require("vuffers.constants")
local file = require("utils.file")

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
---@field pinned_icon string
---@field window { auto_resize: boolean, width: number, focus_on_open: boolean }

---@class Keymaps
---@field use_default boolean
---@field view KeymapView

--- @class KeymapView
--- @field open string
--- @field delete string
--- @field pin string
--- @field unpin string
--- @field rename string
--- @field reset_custom_display_name string
--- @field reset_custom_display_names string
--- @field move_up string
--- @field move_down string

---@class Config
---@field debug DebugConfig
---@field exclude Exclude
---@field handlers Handlers
---@field sort SortOrder
---@field view View
---@field keymaps Keymaps
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

M.get_keymaps = function()
  return config.keymaps
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

---@param auto_resize boolean
M.set_auto_resize = function(auto_resize)
  config.view.window.auto_resize = auto_resize
end

M.persist_config = function()
  local filename = file.cwd_name() .. "_config"
  local path = constants.VUFFERS_FILE_LOCATION .. "/" .. filename .. ".json"
  local config_data = {
    sort = config.sort,
  }

  local ok, err = pcall(function()
    file.write_json_file(path, config_data)
  end)

  if not ok then
    print("persist_config: ", err)
  end
end

M.load_saved_config = function()
  local filename = file.cwd_name() .. "_config"
  local path = constants.VUFFERS_FILE_LOCATION .. "/" .. filename .. ".json"
  local ok, data = pcall(function()
    return file.read_json_file(path)
  end)

  if not ok then
    print("load_config: ", data)
    return nil
  end

  config = vim.tbl_deep_extend("force", config, { sort = data.sort })
end

---@param user_config Config
function M.setup(user_config)
  ---@type Config
  local default = {
    debug = {
      enabled = true,
      level = "error", -- "error" | "warn" | "info" | "debug" | "trace"
    },
    exclude = {
      -- do not show them on the vuffers list
      filenames = { "term://" },
      filetypes = { "lazygit", "NvimTree", "qf" },
    },
    handlers = {
      -- when deleting a buffer via vuffers list (by default triggered by "d" key)
      on_delete_buffer = function(bufnr)
        vim.api.nvim_command(":bwipeout " .. bufnr)
      end,
    },
    keymaps = {
      use_default = true,
      -- key maps on the vuffers list
      view = {
        open = "<CR>",
        delete = "d",
        pin = "p",
        unpin = "P",
        rename = "r",
        reset_custom_display_name = "R",
        reset_custom_display_names = "<leader>R",
        move_up = "U",
        move_down = "D",
      },
    },
    sort = {
      type = "none", -- "none" | "filename"
      direction = "asc", -- "asc" | "desc"
    },
    view = {
      modified_icon = "󰛿", -- when a buffer is modified, this icon will be shown
      pinned_icon = "󰃀",
      window = {
        auto_resize = false,
        width = 35,
        focus_on_open = false,
      },
    },
  }

  config = vim.tbl_deep_extend("force", default, user_config or {})
  M.load_saved_config()
end

return M
