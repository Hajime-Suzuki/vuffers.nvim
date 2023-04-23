local logger = require("utils.logger")
local constants = require("vuffers.constants")
local config = require("vuffers.config")

local M = {}
local split

function M.init(opts)
  local Split = require("nui.split")

  local view_config = config.get_view_config()
  split = Split({
    relative = "editor",
    position = "left",
    size = view_config.window.width,
    enter = view_config.window.focus_on_open,
    win_options = {
      relativenumber = false,
      number = true,
      list = false,
      winfixwidth = true,
      winfixheight = true,
      foldenable = false,
      spell = false,
      signcolumn = "yes",
      foldmethod = "manual",
      foldcolumn = "0",
      cursorcolumn = false,
      cursorline = false,
      colorcolumn = "0",
      winhighlight = "Normal:VerticalBuffers",
    },

    buf_options = {
      swapfile = false,
      buftype = "nofile",
      modifiable = true,
      filetype = constants.VUFFERS_FILE_TYPE,
      bufhidden = "hide",
    },
  })

  split:mount()

  split:hide()

  -- print("window is initiated" .. split.bufnr)
  return split
end

function M.force_init()
  split = nil
  return M.init()
end

local function get_split()
  if not M.is_valid() then
    return M.init()
  end

  if split then
    return split
  end

  print("this should not happen...")
  return M.init()
end

function M.get_window_id()
  return vim.fn.bufwinid(M.get_bufnr())
end

function M.is_valid()
  if not (split and split.bufnr) then
    -- TODO: check why split is nil right after init
    return false
  end

  if not vim.api.nvim_buf_is_valid(split.bufnr) then
    print("split has invalid buffer")
    return false
  end

  return true
end

local is_open = false

function M.open()
  local s = get_split()
  s:show()
  is_open = true
end

function M.close()
  local s = get_split()

  s:hide()
  is_open = false
end

function M.is_hidden()
  return not is_open
end

---@return number
function M.get_bufnr()
  local s = get_split()

  return s.bufnr
end

function M.get_id()
  local s = get_split()

  return s.winid
end

---@param width string | number
--width: string such as "+10" or "-10", or number
function M.resize(width)
  if not is_open then
    return
  end

  local window_config = config.get_view_config().window

  local new_width
  if type(width) == "string" then
    local w = vim.trim(width)
    if w:match("^[+-]") then
      new_width = window_config.width + tonumber(w)
    end
  else
    new_width = width
  end

  local s = get_split()
  s:update_layout({ size = { width = new_width } })
  config.set_window_width(new_width)
end

return M
