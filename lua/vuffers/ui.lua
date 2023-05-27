local list = require("utils.list")
local window = require("vuffers.window")
local bufs = require("vuffers.buffers")
local is_devicon_ok, devicon = pcall(require, "nvim-web-devicons")
local logger = require("utils.logger")
local constants = require("vuffers.constants")
local config = require("vuffers.config")

local M = {}

local active_pinned_buffer_ns = vim.api.nvim_create_namespace("VuffersActivePinnedBuffer") -- namespace id
local pinned_icon_ns = vim.api.nvim_create_namespace("VuffersPinnedBuffer") -- namespace id
local active_buffer_ns = vim.api.nvim_create_namespace("VuffersActiveFileNamespace") -- namespace id
local icon_ns = vim.api.nvim_create_namespace("VufferIconNamespace") -- namespace id

if not is_devicon_ok then
  print("devicon not found")
end

---@param buffer Buffer
---@return string, string -- icon, highlight name
local function _get_icon(buffer)
  local buffer_name_with_extension = string.match(buffer.name, "^%..+$") and buffer.name
    or buffer.name .. "." .. buffer.ext

  if not is_devicon_ok or not devicon.has_loaded() then
    return "", ""
  end

  local icon, color = devicon.get_icon(buffer_name_with_extension, buffer.ext, { default = true })
  return icon or " ", color or ""
end

---@class Highlight
---@field color string
---@field size integer
---@field namespace number

---@class Line
---@field text string
---@field modified boolean
---@field highlights Highlight[]

---@param buffer Buffer
---@return Line
local function _generate_line(buffer)
  local icon, icon_color = _get_icon(buffer)
  local pinned_icon = config.get_view_config().pinned_icon
  local pinned_icon_text = bufs.is_pinned(buffer) and pinned_icon .. " " or ""
  local icon_text = icon ~= "" and icon .. " " or "  "
  local text = pinned_icon_text .. icon_text .. buffer.name

  ---@type Highlight[]
  local highlights = {}

  if bufs.is_pinned(buffer) then
    table.insert(
      highlights,
      { color = constants.HIGHLIGHTS.PINNED_ICON, size = string.len(pinned_icon), namespace = pinned_icon_ns }
    )
  end
  if icon ~= "" then
    table.insert(highlights, { color = icon_color, size = string.len(icon), namespace = icon_ns })
  end

  local modified = vim.bo[buffer.buf].modified

  return { text = text, modified = modified, highlights = highlights }
end

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
---@return fun(highlight: Highlight)
local function create_icon_highlighter(window_bufnr, line_number)
  local last_end_col = 0

  ---@param highlight Highlight
  return function(highlight)
    local SPACE = 1
    local start = last_end_col + SPACE
    local finish = start + highlight.size

    logger.debug("highlight", { start = start, finish = finish, line_number = line_number })

    local ok = pcall(function()
      vim.api.nvim_buf_add_highlight(window_bufnr, highlight.namespace, highlight.color, line_number, start, finish)
    end)

    last_end_col = finish

    if not ok then
      logger.error("Error: Could not set highlight for file icon " .. window_bufnr)
    end
  end
end
---@param window_bufnr integer
---@param line_number integer
local function _highlight_active_buffer(window_bufnr, line_number)
  local ok = pcall(function()
    vim.api.nvim_buf_clear_namespace(window_bufnr, active_buffer_ns, 0, -1)
    vim.api.nvim_buf_add_highlight(window_bufnr, active_buffer_ns, constants.HIGHLIGHTS.ACTIVE, line_number, 0, -1)
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

---@param payload {index: integer}
function M.highlight_active_buffer(payload)
  local window_nr = window.get_buffer_number()

  if not window.is_open() or not window_nr then
    return
  end

  _highlight_active_buffer(window_nr, payload.index - 1)
end

---@param payload {current_index: integer, prev_index?: integer}
function M.highlight_active_pinned_buffer(payload)
  local window_nr = window.get_buffer_number()

  if not window.is_open() or not window_nr then
    return
  end

  if payload.prev_index then
    vim.api.nvim_buf_clear_namespace(window_nr, active_pinned_buffer_ns, payload.prev_index - 1, payload.prev_index)
    vim.api.nvim_buf_add_highlight(
      window_nr,
      pinned_icon_ns,
      constants.HIGHLIGHTS.PINNED_ICON,
      payload.prev_index - 1,
      0,
      string.len(config.get_view_config().pinned_icon) + 1
    )
  end

  vim.api.nvim_buf_clear_namespace(window_nr, pinned_icon_ns, payload.current_index - 1, payload.current_index)
  vim.api.nvim_buf_add_highlight(
    window_nr,
    active_pinned_buffer_ns,
    constants.HIGHLIGHTS.ACTIVE_PINNED_ICON,
    payload.current_index - 1,
    0,
    string.len(config.get_view_config().pinned_icon) + 1
  )
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

---@param payload BufferListChangedPayload
function M.render_buffers(payload)
  local window_nr = window.get_buffer_number()

  if not window.is_open() or not window_nr then
    return
  end

  local buffers = payload.buffers

  if not #buffers then
    return
  end

  local lines = list.map(buffers, function(buffer)
    return _generate_line(buffer)
  end)

  _render_lines(
    window_nr,
    list.map(lines, function(line)
      return line.text
    end)
  )

  for i, line in ipairs(lines) do
    local buf_nr = buffers[i].buf
    if line.modified then
      _set_modified_icon(window_nr, i - 1, buf_nr, true)
    elseif _ext[buf_nr] then
      _delete_modified_icon(window_nr, buf_nr)
    end

    logger.debug("highlights", line.highlights)

    local highlight_icon = create_icon_highlighter(window_nr, i - 1)

    for _, highlight in ipairs(line.highlights) do
      highlight_icon(highlight)
    end
  end

  logger.debug("Rendered buffers")

  --- TODO:move into _generate_line
  if payload.active_buffer_index then
    M.highlight_active_buffer({ index = payload.active_buffer_index })
  end

  --- TODO:move into _generate_line
  if payload.active_pinned_buffer_index then
    M.highlight_active_pinned_buffer({ current_index = payload.active_pinned_buffer_index })
  end
end

return M
