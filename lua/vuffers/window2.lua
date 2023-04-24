local list = require("utils.list")
local logger = require("utils.logger")
local constants = require("vuffers.constants")
local M = {}

---@class VufferWindow
---@field winnr number
---@field bufnr number
---@field is_open boolean

---@type table<number, VufferWindow>
local window_by_tab = {}

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

function M.open()
  local tab = vim.api.nvim_get_current_tabpage()

  if window_by_tab[tab] then
    logger.debug("window is already open")
    logger.debug("window and buffer: ", window_by_tab[tab])
    vim.api.nvim_win_close(window_by_tab[tab].winnr, true)
    vim.api.nvim_buf_delete(window_by_tab[tab].bufnr, { force = true })
    window_by_tab[tab] = nil

    logger.debug("window and buffer cleaned up")
    return
  end

  -- create window and buffer
  local winnr = _create_window()
  local bufnr = _create_buffer()

  logger.debug("window buffer is initiated ", { winnr = winnr, bufnr = bufnr })

  window_by_tab[tab] = { bufnr = bufnr, winnr = winnr, is_open = true }

  -- open buffer in the window
  vim.api.nvim_win_set_buf(winnr, bufnr)
  vim.api.nvim_command("wincmd p")
end

return M
