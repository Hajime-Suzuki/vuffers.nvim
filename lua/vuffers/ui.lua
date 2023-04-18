local list = require("utils.list")
local window = require("vuffers.window")
local bufs = require("vuffers.buffers")

local M = {}

local ns_id = vim.api.nvim_create_namespace("my_namespace") -- namespace id

---@param bufnr integer
---@param lines string[]
local function _render_lines(bufnr, lines)
  local ok = pcall(function()
    vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, lines)
  end)

  if not ok then
    print("Error: Could not set lines in buffer " .. bufnr)
  end
end

---@param bufnr integer
---@param line_number integer
local function _set_highlight(bufnr, line_number)
  local ok = pcall(function()
    vim.api.nvim_buf_clear_namespace(bufnr, ns_id, 0, -1)
    vim.api.nvim_buf_add_highlight(bufnr, ns_id, "VuffersSelectedBuffer", line_number, 0, -1)
  end)

  if not ok then
    print("Error: Could not set highlight in buffer " .. bufnr)
  end
end

function M.highlight_active_buffer()
  local split_bufnr = window.get_split_buf_num()
  local active_line = bufs.get_active_buffer_index()

  if active_line == nil then
    return
  end

  _set_highlight(split_bufnr, active_line - 1)
end

function M.render_buffers()
  if window.is_hidden() then
    return
  end

  local buffers = bufs.get_all_buffers()
  local split_bufnr = window.get_split_buf_num()

  local lines = list.map(buffers, function(buffer)
    return buffer.name
  end)

  _render_lines(split_bufnr, lines)
end

return M
