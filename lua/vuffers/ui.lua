local list = require("utils.list")
local window = require("vuffers.window")
local bufs = require("vuffers.buffers")
local pinned = require("vuffers.buffers.pinned-buffers")
local is_devicon_ok, devicon = pcall(require, "nvim-web-devicons")
local logger = require("utils.logger")
local constants = require("vuffers.constants")
local config = require("vuffers.config")

local active_highlights = {}
local M = {}

local active_pinned_buffer_ns = vim.api.nvim_create_namespace("VuffersActivePinnedBuffer") -- namespace id
local pinned_icon_ns = vim.api.nvim_create_namespace("VuffersPinnedBuffer") -- namespace id
local active_buffer_ns = vim.api.nvim_create_namespace("VuffersActiveFileNamespace") -- namespace id
local icon_ns = vim.api.nvim_create_namespace("VufferIconNamespace") -- namespace id
local index_ns = vim.api.nvim_create_namespace("VuffersIndex")

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
---@field start_col integer
---@field end_col integer
---@field namespace number

---@class Line
---@field text string
---@field highlights Highlight[]
---@field active_highlight Highlight

---@param idx integer
---@return Line
local function _generate_line(idx)
  local view_config = config.get_view_config()
  local left_text = ""
  local hls = {}

  local padding_text = string.rep(" ", view_config.padding)
  left_text = left_text .. padding_text
  local next_hl_col = view_config.padding

  local buffer_count = bufs.get_num_of_buffers()
  local idx_gutter_length = #tostring(buffer_count)
  local idx_length = #tostring(idx)
  local idx_text = string.rep(" ", idx_gutter_length - idx_length) .. idx
  left_text = left_text .. idx_text .. " "
  table.insert(hls, {
    color = constants.HIGHLIGHTS.INDEX,
    start_col = next_hl_col,
    end_col = next_hl_col + idx_gutter_length,
    namespace = index_ns
  })
  next_hl_col = hls[#hls].end_col + 1

  local buffer = bufs.get_buffer_by_index(idx)
  if bufs.is_pinned(buffer) then
    local pinned_icon = view_config.pinned_icon
    left_text = left_text .. view_config.pinned_icon .. " "
    table.insert(hls, {
      color = constants.HIGHLIGHTS.PINNED_ICON,
      start_col = next_hl_col,
      end_col = next_hl_col + string.len(pinned_icon),
      namespace = pinned_icon_ns,
    })
    next_hl_col = hls[#hls].end_col + 1
  end

  local icon, icon_color = _get_icon(buffer)
  if icon ~= "" then
    left_text = left_text .. icon .. " "
    table.insert(hls, {
      color = icon_color,
      start_col = next_hl_col,
      end_col = next_hl_col + string.len(icon),
      namespace = icon_ns,
    })
    next_hl_col = hls[#hls].end_col + 1
  else
    left_text = left_text .. "  "
    next_hl_col = hls[#hls].end_col + 2
  end

  local right_text = ""
  if vim.bo[buffer.buf].modified then
    right_text = " " .. view_config.modified_icon
  end
  right_text = right_text .. padding_text

  local buffer_text = view_config.create_buffer_text(buffer)
  if view_config.trim_buffer_text then
    local window_width = vim.api.nvim_win_get_width(window.get_window_number())
    local l_text_length = vim.str_utfindex(left_text)
    local r_text_length = vim.str_utfindex(right_text)
    local b_text_length = vim.str_utfindex(buffer_text)
    local total_text_length = l_text_length + b_text_length + r_text_length
    if total_text_length > window_width then
      local trim_icon_length = vim.str_utfindex(view_config.trim_icon)
      local trim_amount = (total_text_length - window_width) + trim_icon_length
      local trimmed_buffer_text = string.sub(buffer_text, trim_amount + 1)
      buffer_text = view_config.trim_icon .. trimmed_buffer_text
    end
  end
  local text = left_text .. buffer_text .. right_text

  local active_hl = {
    color = constants.HIGHLIGHTS.ACTIVE,
    start_col = next_hl_col,
    end_col = next_hl_col + string.len(buffer_text),
    namespace = active_buffer_ns,
  }
  next_hl_col = active_hl.end_col + 1

  table.insert(hls, {
    color = constants.HIGHLIGHTS.MODIFIED_ICON,
    start_col = next_hl_col,
    end_col = next_hl_col + string.len(view_config.modified_icon),
    namespace = icon_ns,
  })

  return {
    text = text,
    highlights = hls,
    active_highlight = active_hl,
  }
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
---@param highlights Highlight
local function apply_line_highlights(window_bufnr, line_number, highlights)
  for _, hl in ipairs(highlights) do
    local start = {line_number, hl.start_col}
    local finish = {line_number, hl.end_col}
    local ok = pcall(function()
      vim.hl.range(window_bufnr, hl.namespace, hl.color, start, finish)
    end)
    if not ok then
      logger.error("Error: Could not set highlight in " .. window_bufnr)
    end
  end
end

---@param window_bufnr integer
---@param line_number integer
local function _highlight_active_buffer(window_bufnr, line_number)
  local ok = pcall(function()
    vim.api.nvim_buf_clear_namespace(window_bufnr, active_buffer_ns, 0, -1)
    local hl = active_highlights[line_number + 1]
    if config.get_view_config().highlight_entire_active_line then
      vim.api.nvim_buf_set_extmark(
        window_bufnr,
        hl.namespace,
        line_number,
        -1,
        {line_hl_group = hl.color}
      )
    else
      local start = {line_number, hl.start_col}
      local finish = {line_number, hl.end_col}
      vim.hl.range(window_bufnr, hl.namespace, hl.color, start, finish)
    end
  end)

  if not ok then
    logger.error("Error: Could not set highlight for active buffer " .. window_bufnr)
  end
end

---@param payload {index: integer}
function M.highlight_active_buffer(payload)
  local vuffers_bufnr = window.get_buffer_number()

  if not window.is_open() or not vuffers_bufnr then
    return
  end

  _highlight_active_buffer(vuffers_bufnr, payload.index - 1)
end

---@param payload {current_index: integer, prev_index?: integer}
function M.highlight_active_pinned_buffer(payload)
  local vuffers_bufnr = window.get_buffer_number()

  if not window.is_open() or not vuffers_bufnr then
    return
  end

  local idx_gutter_length = #tostring(bufs.get_num_of_buffers())
  local view_config = config.get_view_config()
  local hl_start = view_config.padding + idx_gutter_length + 1
  local hl_end = hl_start + string.len(view_config.pinned_icon)
  if payload.prev_index then
    vim.api.nvim_buf_clear_namespace(vuffers_bufnr, active_pinned_buffer_ns, payload.prev_index - 1, payload.prev_index)
    local start = {payload.prev_index - 1, hl_start}
    local finish = {payload.prev_index - 1, hl_end}
    vim.hl.range(
      vuffers_bufnr,
      pinned_icon_ns,
      constants.HIGHLIGHTS.PINNED_ICON,
      start,
      finish
    )
  end

  vim.api.nvim_buf_clear_namespace(vuffers_bufnr, pinned_icon_ns, payload.current_index - 1, payload.current_index)
  local start = {payload.current_index - 1, hl_start}
  local finish = {payload.current_index - 1, hl_end}
  vim.hl.range(
    vuffers_bufnr,
    active_pinned_buffer_ns,
    constants.HIGHLIGHTS.ACTIVE_PINNED_ICON,
    start,
    finish
  )
end

---@param buffer NativeBuffer
function M.update_modified_icon(buffer)
  local vuffers_bufnr = window.get_buffer_number()
  if not window.is_open() or not vuffers_bufnr then
    return
  end

  local _, index = bufs.get_buffer_by_path(buffer.file)
  if index == nil then
    return
  end

  local new_line = _generate_line(index)
  vim.api.nvim_buf_set_lines(vuffers_bufnr, index - 1, index, false, {new_line.text})
  apply_line_highlights(vuffers_bufnr, index - 1, new_line.highlights)
  active_highlights[index] = new_line.active_highlight

  local _, active_idx = bufs.get_active_buffer()
  if active_idx ~= nil and index == active_idx then
    M.highlight_active_buffer({index = active_idx})
  end
  local _, active_pinned_idx = pinned.get_active_pinned_buffer()
  if active_pinned_idx ~= nil and index == active_pinned_idx then
    M.highlight_active_pinned_buffer({current_index = active_pinned_idx})
  end
end

---@param payload BufferListChangedPayload
function M.render_buffers(payload)
  local vuffers_bufnr = window.get_buffer_number()

  if not window.is_open() or not vuffers_bufnr then
    return
  end

  local buffers = payload.buffers

  if not next(buffers) then
    vim.api.nvim_buf_set_lines(vuffers_bufnr, 0, -1, false, {})
    return
  end

  local lines = {}
  for idx=1,bufs.get_num_of_buffers() do
    table.insert(lines, _generate_line(idx))
  end

  _render_lines(
    vuffers_bufnr,
    list.map(lines, function(line)
      return line.text
    end)
  )

  active_highlights = {}
  for i, line in ipairs(lines) do
    logger.debug("highlights", line.highlights)
    apply_line_highlights(vuffers_bufnr, i - 1, line.highlights)
    table.insert(active_highlights, line.active_highlight)
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
