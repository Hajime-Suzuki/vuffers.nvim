local list = require("utils.list")
local window = require("vuffers.window")
local bufs = require("vuffers.buffers")
local is_devicon_ok, devicon = pcall(require, "nvim-web-devicons")
local logger = require("utils.logger")
local constants = require("vuffers.constants")
local config = require("vuffers.config")

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
---@field modified_icon string
---@field icon_highlight string

---@param buffer Buffer
---@return Line
local function _generate_line(buffer)
  local icon, color = _get_icon(buffer.name)

  local filename = icon .. " " .. string.gsub(buffer.name, "%.%w+$", "")
  local modified_icon = vim.bo[buffer.buf].modified and "M" or ""
  return { text = filename, icon = icon, icon_highlight = color, modified_icon = modified_icon }
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

local _ext = {}

---@param window_bufnr integer
---@param line_number integer
---@param bufnr integer
local function _set_modified_icon(window_bufnr, line_number, bufnr)
  local modified_icon = config.get_view_config().modified_icon
  local ext_id = vim.api.nvim_buf_set_extmark(window_bufnr, icon_ns, line_number, -1, {
    virt_text = { { modified_icon, constants.HIGHLIGHTS.MODIFIED } },
    virt_text_pos = "eol",
  })

  _ext[bufnr] = ext_id
end

---@param window_bufnr integer
---@param bufnr integer
local function _delete_modified_icon(window_bufnr, bufnr)
  local ext_id = _ext[bufnr]
  if not ext_id then
    return
  end

  vim.api.nvim_buf_del_extmark(window_bufnr, icon_ns, ext_id)
  _ext[bufnr] = nil
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

---@param buffer NativeBuffer
function M.update_modified_icon(buffer)
  local new_modified = vim.bo[buffer.buf].modified
  logger.debug("mod", { new_modified = new_modified, file = buffer.file })

  local window_nr = window.get_split_buf_num()
  local target, index = bufs.get_buffer_by_bufnr(buffer.buf)

  if target == nil then
    return
  end

  if new_modified then
    _set_modified_icon(window_nr, index - 1, buffer.buf)
    return
  elseif _ext[buffer.buf] then
    _delete_modified_icon(window_nr, buffer.buf)
    return
  end
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
    local buf_nr = buffers[i].buf
    if line.modified_icon ~= "" then
      _set_modified_icon(split_bufnr, i - 1, buf_nr)
    elseif _ext[buf_nr] then
      _delete_modified_icon(split_bufnr, buf_nr)
    end

    if line.icon ~= "" then
      highlight_file_icon(split_bufnr, i - 1, buffers[i])
    end
  end

  logger.debug("Rendered buffers")
end

return M
