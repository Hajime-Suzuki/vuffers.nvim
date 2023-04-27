local logger = require("utils.logger")
local constants = require("vuffers.constants")
local events = require("vuffers.events")
local ui = require("vuffers.ui")
local buffers = require("vuffers.buffers")
local window = require("vuffers.window")
local validations = require("vuffers.validations")
local keymaps = require("vuffers.key-bindings")

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

      -- when buffer is open on the vuffer window, open it in another window
      if window.is_open() then
        local current_win = vim.api.nvim_get_current_win()
        local vuffer_win = window.get_window_number()
        local bufnr = window.get_buffer_number()

        if current_win and vuffer_win and bufnr and current_win == vuffer_win then
          logger.debug("opening another buffer in vuffer window")
          vim.api.nvim_win_set_buf(vuffer_win, bufnr)
          vim.api.nvim_command("wincmd l" .. "|" .. "buffer " .. buffer.buf)
        end
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

      buffers.add_buffer(buffer)
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

  vim.api.nvim_create_autocmd("WinClosed", {
    pattern = "*",
    group = constants.AUTO_CMD_GROUP,
    callback = function(buffer)
      -- TODO: check if this is needed
      if tonumber(buffer.match) == window.get_window_number() then
        logger.debug("closing vuffer window", { buffer = buffer })
        window.close()
      end
    end,
  })
end

function M.remove_auto_group()
  pcall(function()
    vim.api.nvim_del_augroup_by_name(constants.AUTO_CMD_GROUP)
  end)
end

return M
