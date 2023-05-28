local config = require("vuffers.config")
local logger = require("utils.logger")
local constants = require("vuffers.constants")
local event_bus = require("vuffers.event-bus")
local list = require("utils.list")

local M = {}

---@alias TabNumber number

---@class VufferWindow
---@field winnr number
---@field bufnr number
---@field is_open boolean

---@type table<TabNumber, VufferWindow>
local view_by_tab = {}

local buffer_options = {
  swapfile = false,
  buftype = "nofile",
  modifiable = true,
  filetype = constants.VUFFERS_FILE_TYPE,
  bufhidden = "hide",
}

local window_options = {
  relativenumber = false,
  number = true,
  list = false,
  winfixwidth = true,
  winfixheight = true,
  foldenable = false,
  spell = false,
  signcolumn = "no",
  cursorcolumn = false,
  cursorline = false,
  colorcolumn = "0",
  winhighlight = "Normal:" .. constants.HIGHLIGHTS.WINDOW_BG,
}

local function _create_window()
  vim.api.nvim_command("topleft vs")
  local win = vim.api.nvim_get_current_win()

  local width = config.get_view_config().window.width
  vim.api.nvim_win_set_width(win, width)

  for option, value in pairs(window_options) do
    vim.api.nvim_win_set_option(win, option, value)
  end

  return win
end

local function _create_buffer()
  local bufnr = vim.api.nvim_create_buf(false, false)

  for option, value in pairs(buffer_options) do
    vim.bo[bufnr][option] = value
  end

  logger.debug("window buffer option is set initiated " .. bufnr)

  return bufnr
end

---@param args {winnr: number, bufnr: number}
local function _set_view(args)
  local tab = vim.api.nvim_get_current_tabpage()
  view_by_tab[tab] = { winnr = args.winnr, bufnr = args.bufnr }
end

local function _reset_view()
  local tab = vim.api.nvim_get_current_tabpage()
  view_by_tab[tab] = nil
end

---@return VufferWindow | nil
local function _get_view()
  local tab = vim.api.nvim_get_current_tabpage()

  if view_by_tab[tab] then
    return view_by_tab[tab]
  end

  return nil
end

function M.get_buffer_number()
  local view = _get_view()
  if view then
    return view.bufnr
  end

  return nil
end

function M.get_window_number()
  local view = _get_view()
  if view then
    return view.winnr
  end

  return nil
end

function M.is_open()
  local window = _get_view()
  return window ~= nil
end

function M.open()
  local view = _get_view()

  if view then
    logger.debug("view is already open")
    return
  end

  local winnr = _create_window()
  local bufnr = _create_buffer()
  _set_view({ winnr = winnr, bufnr = bufnr })

  logger.debug("window and buffer is initiated ", { winnr = winnr, bufnr = bufnr })

  vim.api.nvim_win_set_buf(winnr, bufnr)
  vim.api.nvim_command("wincmd p")
  event_bus.publish_vuffers_window_opened({ buffer_number = bufnr })
end

function M.close()
  local view = _get_view()
  if not view then
    return
  end

  -- NOTE: delete buffer, then window is closed. Otherwise, an error is thrown.
  vim.api.nvim_buf_delete(view.bufnr, { force = true })
  _reset_view()
end

function M.toggle()
  if M.is_open() then
    M.close()
  else
    M.open()
  end
end

---@param width string | number
--width: string such as "+10" or "-10", or number
function M.resize(width)
  logger.debug("M.resize")
  local view = _get_view()
  if not M.is_open or not view then
    logger.warn("resize only works when vuffers window is open")
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

  config.set_window_width(new_width)
  vim.api.nvim_win_set_width(view.winnr, new_width)
end

local LENGTH_BEFORE_BUFFER_NAME = 3
local EDIT_ICON_LENGTH = 2

function M.auto_resize()
  if not config.get_view_config().window.auto_resize then
    return
  end

  local view = _get_view()
  if not view then
    return
  end

  local buf = vim.api.nvim_win_get_buf(view.winnr)
  local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)

  local max_text_length = list.fold(lines, 0, function(fold_val, line)
    return math.max(fold_val, line:len())
  end)

  M.resize(max_text_length + LENGTH_BEFORE_BUFFER_NAME + EDIT_ICON_LENGTH)
end

return M
