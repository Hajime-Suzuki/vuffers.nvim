local logger = require("utils.logger")
local constants = require("vuffers.constants")
local M = {}

local window_by_tab = {}

local default_option = {
  swapfile = false,
  buftype = "nofile",
  modifiable = true,
  filetype = constants.VUFFERS_FILE_TYPE,
  bufhidden = "hide",
}

function M.open()
  local tab = vim.api.nvim_get_current_tabpage()

  if window_by_tab[tab] then
    return logger.debug("window is already open")
  end

  local bufnr = vim.api.nvim_create_buf(false, false)

  logger.debug("window buffer is initiated " .. bufnr)

  window_by_tab[tab] = bufnr

  vim.api.nvim_buf_set_name(bufnr, constants.VUFFERS_FILE_TYPE)

  for option, value in pairs(default_option) do
    vim.bo[bufnr][option] = value
  end

  logger.debug("window buffer option is set initiated " .. bufnr)

  vim.api.nvim_command("vsp")
end

return M
