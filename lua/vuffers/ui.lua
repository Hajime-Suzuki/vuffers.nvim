local list = require("utils.list")
local window = require("vuffers.window")
local bufs = require("vuffers.buffers")
local is_devicon_ok, devicon = pcall(require, "nvim-web-devicons")
local logger = require("utils.logger")
local constants = require("vuffers.constants")
local config = require("vuffers.config")
local validations = require("vuffers.validations")

local M = {}

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

  local icon, color = devicon.get_icon(filename, extension, { default = true })
  return icon or " ", color or ""
end

---@class Line
---@field text string
---@field icon string
---@field modified boolean

---@param buffer Buffer
---@return Line
local function _generate_line(buffer)
  local icon = _get_icon(buffer.name)

  local filename = icon .. " " .. string.gsub(buffer.name, "%.%w+$", "")
  local modified = vim.bo[buffer.buf].modified
  return { text = filename, icon = icon, modified = modified }
end

local active_buffer_ns = vim.api.nvim_create_namespace("VuffersActiveFileNamespace") -- namespace id
local icon_ns = vim.api.nvim_create_namespace("VufferIconNamespace") -- namespace id

---@param window_bufnr integer
---@param lines string[]
local function _render_lines(window_bufnr, lines)
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
local function _highlight_file_icon(window_bufnr, line_number, buffer)
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
---@param force? boolean
local function _set_modified_icon(window_bufnr, line_number, bufnr, force)
  if _ext[bufnr] and not force then
    return
  end

  local modified_icon = config.get_view_config().modified_icon
  local ext_id = vim.api.nvim_buf_set_extmark(window_bufnr, icon_ns, line_number, -1, {
    virt_text = { { modified_icon, constants.HIGHLIGHTS.MODIFIED_ICON } },
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

---@param payload ActiveBufferChangedPayload
function M.highlight_active_buffer(payload)
  local window_nr = window.get_buffer_number()

  if not window.is_open() or not window_nr then
    return
  end

  _highlight_active_buffer(window_nr, payload.index - 1)
end

---@param buffer NativeBuffer
function M.update_modified_icon(buffer)
  local window_nr = window.get_buffer_number()

  if not window.is_open() or not window_nr then
    return
  end

  local new_modified = vim.bo[buffer.buf].modified
  local target, index = bufs.get_buffer_by_bufnr(buffer.buf)

  if target == nil then
    return
  end

  if new_modified then
    logger.debug("Setting modified icon for " .. buffer.file)
    _set_modified_icon(window_nr, index - 1, buffer.buf)
  elseif _ext[buffer.buf] then
    logger.debug("Deleting modified icon for " .. buffer.file)
    _delete_modified_icon(window_nr, buffer.buf)
  end
end

function M.render_buffers()
  local window_nr = window.get_buffer_number()

  if not window.is_open() or not window_nr then
    return
  end

  local buffers = bufs.get_all_buffers()

  local valid_buffers = list.filter(buffers, validations.is_valid_buf)

  if not valid_buffers then
    return
  end

  local lines = list.map(valid_buffers, function(buffer)
    return _generate_line(buffer)
  end)

  _render_lines(
    window_nr,
    list.map(lines, function(line)
      return line.text
    end)
  )

  for i, line in ipairs(lines) do
    local buf_nr = valid_buffers[i].buf
    if line.modified then
      _set_modified_icon(window_nr, i - 1, buf_nr, true)
    elseif _ext[buf_nr] then
      _delete_modified_icon(window_nr, buf_nr)
    end

    if line.icon ~= "" then
      _highlight_file_icon(window_nr, i - 1, valid_buffers[i])
    end
  end

  logger.debug("Rendered buffers")
end

return M
