local keymaps = require("vuffers.key-bindings")
local logger = require("utils.logger")
local constants = require("vuffers.constants")
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
  -- signcolumn = "no",
  cursorcolumn = false,
  cursorline = false,
  colorcolumn = "0",
}

local function _create_window()
  vim.api.nvim_command("topleft vs")
  local win = vim.api.nvim_get_current_win()

  vim.api.nvim_win_set_width(win, 30)

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

  vim.api.nvim_buf_set_name(bufnr, constants.VUFFERS_FILE_TYPE)

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

function M.get_bufnr()
  local view = _get_view()
  if view then
    return view.bufnr
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

  keymaps.init(bufnr)
  vim.api.nvim_win_set_buf(winnr, bufnr)
  vim.api.nvim_command("wincmd p")
end

function M.toggle()
  if M.is_open() then
    M.close()
  else
    M.open()
  end
end

function M.close()
  local view = _get_view()
  if not view then
    return
  end

  keymaps.destroy(view.bufnr)
  -- NOTE: delete all buffers, then window is closed. Otherwise, window is not closed and throws an error.
  vim.api.nvim_buf_delete(view.bufnr, { force = true })
  _reset_view()
end

return M
