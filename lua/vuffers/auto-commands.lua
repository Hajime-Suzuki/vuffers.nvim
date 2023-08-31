local logger = require("utils.logger")
local constants = require("vuffers.constants")
local ui = require("vuffers.ui")
local buffers = require("vuffers.buffers")
local window = require("vuffers.window")
local buf_utils = require("vuffers.buffers.buffer-utils")

local M = {}

function M.create_auto_group()
  vim.api.nvim_create_augroup(constants.AUTO_CMD_GROUP, { clear = true })
  vim.api.nvim_create_autocmd("BufEnter", {
    pattern = "*",
    group = constants.AUTO_CMD_GROUP,
    ---@param buffer NativeBuffer
    callback = function(buffer)
      if not buf_utils.is_valid_buf(buffer) then
        return
      end

      logger.debug("BufEnter", { buffer = buffer })

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

      buffers.set_active_buf(buffer)
      buffers.set_active_pinned_bufnr(buffer)
    end,
  })

  vim.api.nvim_create_autocmd("BufAdd", {
    pattern = "*",
    group = constants.AUTO_CMD_GROUP,
    callback = function(buffer)
      if not buf_utils.is_valid_buf(buffer) then
        return
      end

      logger.debug("BufAdd", { buffer = buffer })

      buffers.add_buffer(buffer)
    end,
  })

  vim.api.nvim_create_autocmd({ "BufDelete" }, {
    pattern = "*",
    group = constants.AUTO_CMD_GROUP,
    ---@param buffer NativeBuffer
    callback = function(buffer)
      -- for BufDelete, buffer.file is relative path unlike ones in other autocmd.
      buffer = {
        buf = buffer.buf,
        event = buffer.event,
        file = buffer.match, -- buffer.file is not full path
        group = buffer.group,
        id = buffer.id,
        match = buffer.match,
      }

      logger.debug("BufDelete", { buffer = buffer })

      if buffers.is_pinned(buffer) then
        vim.cmd("edit " .. buffer.file)
        buffers.set_active_buf(buffer)
        buffers.set_active_pinned_bufnr(buffer)
        return
      end

      buffers.remove_buffer({ path = buffer.file })
    end,
  })

  vim.api.nvim_create_autocmd({ "BufModifiedSet" }, {
    pattern = "*",
    group = constants.AUTO_CMD_GROUP,
    callback = function(buffer)
      if not buf_utils.is_valid_buf(buffer) then
        return
      end
      logger.debug("BufModifiedSet", { buffer = buffer })

      ui.update_modified_icon(buffer)
    end,
  })

  vim.api.nvim_create_autocmd("BufWritePost", {
    pattern = "*",
    group = constants.AUTO_CMD_GROUP,
    callback = function(buffer)
      if not buf_utils.is_valid_buf(buffer) then
        return
      end
      logger.debug("BufWritePost", { buffer = buffer })

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

  vim.api.nvim_create_autocmd("VimLeavePre", {
    pattern = "*",
    group = constants.AUTO_CMD_GROUP,
    callback = function()
      buffers.persist_pinned_buffers()
      if buffers.is_restored_from_session() then
        buffers.persist_buffers()
      end
    end,
  })
end

return M
