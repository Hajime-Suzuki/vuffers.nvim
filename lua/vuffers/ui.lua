local list = require("utils.list")
local window = require("vuffers.window")
local bufs = require("vuffers.buffers")
local is_devicon_ok, devicon = pcall(require, "nvim-web-devicons")
local logger = require("utils.logger")

if not is_devicon_ok then
  print("devicon not found")
end

---@param filename string
---@return string, string
local function _get_icon(filename)
  if not is_devicon_ok or not devicon.has_loaded() then
    return "", ""
  end

  local extension = string.match(filename, "%.(%w+)$")

  local icon, color = devicon.get_icon_color(filename, extension)
  return icon, color
end

---@param buffers Buffer[]
local function _generate_line(buffers)
  -- local max_length = 0
  -- for _, buffer in pairs(buffers) do
  --   max_length = math.max(max_length, #buffer.name)
  -- end

  return list.map(buffers, function(buffer)
    local icon, color = _get_icon(buffer.name)
    -- local padded_name = string.rep(" ", max_length - #buffer.name) .. buffer.name .. " "

    return icon .. " " .. buffer.name
  end)
end

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
  local lines = _generate_line(buffers)
  _render_lines(split_bufnr, lines)
end

return M
