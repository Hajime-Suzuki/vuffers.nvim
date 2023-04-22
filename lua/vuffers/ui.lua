local list = require("utils.list")
local window = require("vuffers.window")
local bufs = require("vuffers.buffers")
local is_devicon_ok, devicon = pcall(require, "nvim-web-devicons")
local logger = require("utils.logger")
local constants = require("vuffers.constants")

local ICON_START_COL = 1
local ICON_END_COL = 3

if not is_devicon_ok then
  print("devicon not found")
end

---@param filename string
---@return string, string -- icon, highlight name
local function _get_icon(filename)
  if not is_devicon_ok or not devicon.has_loaded() then
    return "", ""
  end

  local extension = string.match(filename, "%.(%w+)$")

  local icon, color = devicon.get_icon(filename, extension)
  return icon or " ", color or ""
end

---@class Line
---@field text string
---@field icon string
---@field icon_highlight string

---@param buffer Buffer
---@return Line
local function _generate_line(buffer)
  local icon, color = _get_icon(buffer.name)

  local filename = icon .. " " .. string.gsub(buffer.name, "%.%w+$", "")
  return { text = filename, icon = icon, icon_highlight = color }
end

local M = {}

local active_buffer_ns = vim.api.nvim_create_namespace("VuffersActiveFileNamespace") -- namespace id
local icon_ns = vim.api.nvim_create_namespace("VufferIconNamespace") -- namespace id

---@param window_bufnr integer
local function _render_line(window_bufnr, lines)
  local ok = pcall(function()
    vim.api.nvim_buf_set_lines(window_bufnr, 0, -1, false, lines)
  end)

  if not ok then
    print("Error: Could not set lines in buffer " .. window_bufnr)
  end
end

---@param window_bufnr integer
---@param line_number integer
---@param buffer Buffer
local function highlight_file_icon(window_bufnr, line_number, buffer)
  local _, icon_highlight = _get_icon(buffer.name)
  local ok = pcall(function()
    vim.api.nvim_buf_add_highlight(window_bufnr, icon_ns, icon_highlight, line_number, ICON_START_COL, ICON_END_COL)
  end)

  if not ok then
    logger.error("Error: Could not set highlight for file icon " .. window_bufnr)
  end
end

---@param window_bufnr integer
---@param line_number integer
local function _highlight_active_buffer(window_bufnr, line_number)
  local ok = pcall(function()
    vim.api.nvim_buf_clear_namespace(window_bufnr, active_buffer_ns, 0, -1)
    vim.api.nvim_buf_add_highlight(
      window_bufnr,
      active_buffer_ns,
      constants.HIGHLIGHTS.ACTIVE,
      line_number,
      ICON_END_COL,
      -1
    )
  end)

  if not ok then
    logger.error("Error: Could not set highlight for active buffer " .. window_bufnr)
  end
end

function M.highlight_active_buffer()
  local split_bufnr = window.get_split_buf_num()
  local active_line = bufs.get_active_buffer_index()
  local active_buffer = bufs.get_active_buffer()

  if active_line == nil or active_buffer == nil then
    return
  end

  _highlight_active_buffer(split_bufnr, active_line - 1)
end

function M.render_buffers()
  if window.is_hidden() then
    return
  end

  local buffers = bufs.get_all_buffers()
  local split_bufnr = window.get_split_buf_num()

  local lines = list.map(buffers, function(buffer)
    return _generate_line(buffer)
  end)

  _render_line(
    split_bufnr,
    list.map(lines, function(line)
      return line.text
    end)
  )

  for i, line in ipairs(lines) do
    if line.icon ~= "" then
      logger.debug(
        "Adding highlight for line " .. i .. " with icon " .. line.icon .. " and color " .. line.icon_highlight
      )
      highlight_file_icon(split_bufnr, i - 1, buffers[i])
    end
  end

  logger.debug("Rendered buffers")
end

return M
