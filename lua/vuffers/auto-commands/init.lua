local logger = require("utils.logger")
local autocmd_buffers = require("vuffers.auto-commands.buffers")
local constants = require("vuffers.constants")
local events = require("vuffers.events")
local ui = require("vuffers.ui")

local M = {}

function M.create_auto_group()
  vim.api.nvim_create_augroup(constants.AUTO_CMD_GROUP, { clear = true })
  vim.api.nvim_create_autocmd("BufEnter", {
    pattern = "*",
    group = constants.AUTO_CMD_GROUP,
    callback = function(buffer)
      autocmd_buffers.on_buf_enter(buffer, vim.bo.filetype)
    end,
  })

  vim.api.nvim_create_autocmd("BufAdd", {
    pattern = "*",
    group = constants.AUTO_CMD_GROUP,
    callback = function(buffer)
      autocmd_buffers.on_buf_add(buffer, vim.bo.filetype)
    end,
  })

  vim.api.nvim_create_autocmd({ "BufDelete" }, {
    pattern = "*",
    group = constants.AUTO_CMD_GROUP,
    callback = function(buffer)
      autocmd_buffers.on_buf_delete(buffer)
    end,
  })

  vim.api.nvim_create_autocmd("User", {
    pattern = events.names.BufferListChanged,
    group = constants.AUTO_CMD_GROUP,
    callback = function()
      logger.debug(events.names.BufferListChanged)
      ui.render_buffers()
      ui.highlight_active_buffer()
    end,
  })

  vim.api.nvim_create_autocmd("User", {
    pattern = events.names.ActiveFileChanged,
    group = constants.AUTO_CMD_GROUP,
    callback = function()
      logger.debug(events.names.ActiveFileChanged)
      ui.highlight_active_buffer()
    end,
  })

  vim.api.nvim_create_autocmd("User", {
    pattern = events.names.SortChanged,
    group = constants.AUTO_CMD_GROUP,
    callback = function()
      logger.debug(events.names.SortChanged)
    end,
  })
end

function M.remove_auto_group()
  pcall(function()
    vim.api.nvim_del_augroup_by_name(constants.AUTO_CMD_GROUP)
  end)
end

return M
