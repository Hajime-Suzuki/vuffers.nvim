local logger = require("utils.logger")
local constants = require("vuffers.constants")
local events = require("vuffers.events")
local ui = require("vuffers.ui")
local buffers = require("vuffers.buffers")
local window = require("vuffers.window")
local key_bindings = require("vuffers.key-bindings")
local validations = require("vuffers.validations")

local M = {}

function M.create_auto_group()
  vim.api.nvim_create_augroup(constants.AUTO_CMD_GROUP, { clear = true })
  vim.api.nvim_create_autocmd("BufEnter", {
    pattern = "*",
    group = constants.AUTO_CMD_GROUP,
    callback = function(buffer)
      if not validations.is_valid_buf(buffer) then
        return
      end
      buffers.set_active_bufnr({ path = buffer.file, buf = buffer.buf })
    end,
  })

  vim.api.nvim_create_autocmd("BufAdd", {
    pattern = "*",
    group = constants.AUTO_CMD_GROUP,
    callback = function(buffer)
      if not validations.is_valid_buf(buffer) then
        return
      end

      buffers.add_buffer(buffer, vim.bo.filetype)
    end,
  })

  vim.api.nvim_create_autocmd({ "BufDelete" }, {
    pattern = "*",
    group = constants.AUTO_CMD_GROUP,
    callback = function(buffer)
      buffers.remove_buffer({ bufnr = buffer.buf })
    end,
  })

  vim.api.nvim_create_autocmd({ "BufModifiedSet" }, {
    pattern = "*",
    group = constants.AUTO_CMD_GROUP,
    callback = function(buffer)
      if not validations.is_valid_buf(buffer) then
        return
      end

      ui.update_modified_icon(buffer)
    end,
  })

  vim.api.nvim_create_autocmd("BufWritePost", {
    pattern = "*",
    group = constants.AUTO_CMD_GROUP,
    callback = function(buffer)
      if not validations.is_valid_buf(buffer) then
        return
      end

      ui.update_modified_icon(buffer)
    end,
  })

  vim.api.nvim_create_autocmd("TabEnter", {
    pattern = "*",
    group = constants.AUTO_CMD_GROUP,
    callback = function(buffer)
      -- reset view when switching tabs
      if window.is_hidden() then
        window.force_init()
        return
      end

      window.close()
      window.force_init()
      window.open()
      key_bindings.init(window.get_bufnr())
      buffers.reload_all_buffers()
    end,
  })

  vim.api.nvim_create_autocmd("TabLeave", {
    pattern = "*",
    group = constants.AUTO_CMD_GROUP,
    callback = function(buffer)
      key_bindings.destroy(window.get_bufnr())
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
      buffers.change_sort()
    end,
  })
end

function M.remove_auto_group()
  pcall(function()
    vim.api.nvim_del_augroup_by_name(constants.AUTO_CMD_GROUP)
  end)
end

return M
