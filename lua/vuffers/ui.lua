local list = require("utils.list")
local window = require("vuffers.window")
local bufs = require("vuffers.buffers")
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
local spacing_ns = vim.api.nvim_create_namespace("VuffersSpacing")

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

---@class LineGenInfo
---@field buffer Buffer
---@field idx_text string

---@class Highlight
---@field color string
---@field start_col integer
---@field end_col integer
---@field namespace number

---@class Line
---@field text string
---@field modified boolean
---@field highlights Highlight[]
---@field active_highlight Highlight

---@param line_gen_info LineGenInfo
---@return Line
local function _generate_line(line_gen_info)
  local view_config = config.get_view_config()
  local text = ""
  local modified = vim.bo[line_gen_info.buffer.buf].modified
  local hls = {}

  local padding_text = string.rep(" ", view_config.padding)
  text = text .. padding_text
  table.insert(hls, {
    color = constants.HIGHLIGHTS.WINDOW_BG,
    start_col = 0,
    end_col = view_config.padding,
    namespace = spacing_ns,
  })

  text = text .. line_gen_info.idx_text .. " "
  table.insert(hls, {
    color = constants.HIGHLIGHTS.INDEX,
    start_col = hls[#hls].end_col,
    end_col = hls[#hls].end_col + string.len(line_gen_info.idx_text),
    namespace = index_ns }
  )
  table.insert(hls, {
    color = constants.HIGHLIGHTS.WINDOW_BG,
    start_col = hls[#hls].end_col,
    end_col = hls[#hls].end_col + 1,
    namespace = spacing_ns,
  })

  if bufs.is_pinned(line_gen_info.buffer) then
    local pinned_icon = view_config.pinned_icon
    text = text .. view_config.pinned_icon .. " "
    table.insert(hls, {
      color = constants.HIGHLIGHTS.PINNED_ICON,
      start_col = hls[#hls].end_col,
      end_col = hls[#hls].end_col + string.len(pinned_icon),
      namespace = pinned_icon_ns,
    })
    table.insert(hls, {
      color = constants.HIGHLIGHTS.WINDOW_BG,
      start_col = hls[#hls].end_col,
      end_col = hls[#hls].end_col + 1,
      namespace = spacing_ns,
    })
  end

  local icon, icon_color = _get_icon(line_gen_info.buffer)
  if icon ~= "" then
    text = text .. icon .. " "
    table.insert(hls, {
      color = icon_color,
      start_col = hls[#hls].end_col,
      end_col = hls[#hls].end_col + string.len(icon),
      namespace = icon_ns,
    })
    table.insert(hls, {
      color = constants.HIGHLIGHTS.WINDOW_BG,
      start_col = hls[#hls].end_col,
      end_col = hls[#hls].end_col + 1,
      namespace = spacing_ns,
    })
  else
    text = text .. "  "
    table.insert(hls, {
      color = constants.HIGHLIGHTS.WINDOW_BG,
      start_col = hls[#hls].end_col,
      end_col = hls[#hls].end_col + 2,
      namespace = spacing_ns,
    })
  end

  local buffer_text = view_config.create_buffer_text(line_gen_info.buffer)
  text = text .. view_config.create_buffer_text(line_gen_info.buffer)
  local active_hl = {
    color = constants.HIGHLIGHTS.ACTIVE,
    start_col = hls[#hls].end_col,
    end_col = hls[#hls].end_col + string.len(buffer_text),
    namespace = active_buffer_ns,
  }

  return {
    text = text,
    modified = modified,
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
    local start = {line_number, hl.start_col}
    local finish = {line_number, hl.end_col}
    vim.hl.range(window_bufnr, hl.namespace, hl.color, start, finish)
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

  local idx_gutter_length = #tostring(bufs.get_num_of_buffers())
  local view_config = config.get_view_config()
  local hl_start = view_config.padding + idx_gutter_length + 1
  if payload.prev_index then
    vim.api.nvim_buf_clear_namespace(window_nr, active_pinned_buffer_ns, payload.prev_index - 1, payload.prev_index)
    vim.api.nvim_buf_add_highlight(
      window_nr,
      pinned_icon_ns,
      constants.HIGHLIGHTS.PINNED_ICON,
      payload.prev_index - 1,
      hl_start,
      string.len(view_config.pinned_icon)
    )
  end

  vim.api.nvim_buf_clear_namespace(window_nr, pinned_icon_ns, payload.current_index - 1, payload.current_index)
  vim.api.nvim_buf_add_highlight(
    window_nr,
    active_pinned_buffer_ns,
    constants.HIGHLIGHTS.ACTIVE_PINNED_ICON,
    payload.current_index - 1,
    hl_start,
    string.len(view_config.pinned_icon)
  )
end

---@param buffer NativeBuffer
function M.update_modified_icon(buffer)
  local window_nr = window.get_buffer_number()

  if not window.is_open() or not window_nr then
    return
  end

  local new_modified = vim.bo[buffer.buf].modified
  local target, index = bufs.get_buffer_by_path(buffer.file)

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

  if not next(buffers) then
    vim.api.nvim_buf_set_lines(window_nr, 0, -1, false, {})
    return
  end

  local idx_gutter_length = #tostring(#buffers)
  local lines = list.map(buffers, function(buffer, idx)
    local idx_length = #tostring(idx)
    local idx_text = string.rep(" ", idx_gutter_length - idx_length) .. idx
    local line_gen_info = {
      buffer = buffer,
      idx_text = idx_text,
    }
    return _generate_line(line_gen_info)
  end)

  _render_lines(
    window_nr,
    list.map(lines, function(line)
      return line.text
    end)
  )

  active_highlights = {}
  for i, line in ipairs(lines) do
    local buf_nr = buffers[i].buf
    if line.modified then
      _set_modified_icon(window_nr, i - 1, buf_nr, true)
    elseif _ext[buf_nr] then
      _delete_modified_icon(window_nr, buf_nr)
    end

    logger.debug("highlights", line.highlights)
    apply_line_highlights(window_nr, i - 1, line.highlights)
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
