local logger = require("utils.logger")
local list = require("utils.list")
local str = require("utils.string")
local file = require("utils.file")

local PINNED_BUFFER_LOCATION = vim.fn.stdpath("data") .. "/vuffers"

local bufs = function()
  return require("vuffers.buffers.buffers")
end

local active = function()
  return require("vuffers.buffers.active-buffer")
end

local M = {}

---@type table<Bufnr, boolean>
local _buf_map = {}

M.get_pinned_bufnrs = function()
  return _buf_map
end

M.is_empty = function()
  return list.find_index(_buf_map, function(is_pinned)
    return is_pinned
  end) == nil
end

--- only for testing!
M.__set_pinned_bufnrs = function(data)
  for _, n in pairs(data) do
    _buf_map[n] = true
  end
end

M.__reset_pinned_bufnrs = function()
  _buf_map = {}
end

M.is_pinned = function(bufnr)
  return _buf_map[bufnr] == true
end

---@type integer[] first one is last, and the second one is current
local _pinned_bufnrs = {}

---@return Bufnr | nil
function M.get_last_visited_pinned_bufnr()
  return _pinned_bufnrs[1]
end

---@return Bufnr | nil
function M.get_active_pinned_bufnr()
  return _pinned_bufnrs[2]
end

---@param bufnr Bufnr
function M.set_active_pinned_bufnr(bufnr)
  local _buf_list = bufs().get_buffers()
  local prev_pos = 1
  local current_pos = 2

  local is_buf_pinned = list.find_index(_buf_list, function(b)
    return M.is_pinned(bufnr) and b.buf == bufnr
  end) ~= nil

  if not is_buf_pinned then
    return
  end

  _pinned_bufnrs[prev_pos] = _pinned_bufnrs[current_pos] or bufnr
  _pinned_bufnrs[current_pos] = bufnr

  return true
end

---@return string
local function _get_filename()
  local cwd = vim.loop.cwd()
  local filename = str.replace(cwd, "/", "_")
  return PINNED_BUFFER_LOCATION .. "/" .. filename .. ".json"
end

---@param buffer Buffer
local function _persist_pinned_buffer(buffer)
  local ok, err = pcall(function()
    local filename = _get_filename()

    ---@type {path: string}[]
    local pinned_buffers = file.read_json_file(filename)
    local is_pinned = list.find_index(pinned_buffers, function(item)
      return item.path == buffer.path
    end)

    if is_pinned then
      return
    end

    table.insert(pinned_buffers, { path = buffer.path })
    file.write_json_file(filename, pinned_buffers)
  end)

  if not ok then
    logger.error("persist_pinned_buffer: ", err)
  end
end

---@param buffer Buffer
local function _remove_persisted_pinned_buffer(buffer)
  local ok, err = pcall(function()
    local filename = _get_filename()

    ---@type {path: string}[]
    local pinned_buffers = file.read_json_file(filename)

    local updated = list.filter(pinned_buffers, function(item)
      return item.path ~= buffer.path
    end)

    if #updated == #pinned_buffers then
      return
    end

    file.write_json_file(filename, updated or {})
  end)

  if not ok then
    logger.error("persist_pinned_buffer: ", err)
  end
end

---@param buffer Buffer
function M.pin_buffer(buffer)
  _buf_map[buffer.buf] = true
  M.set_active_pinned_bufnr(buffer.buf)
  _persist_pinned_buffer(buffer)
end

---@param buffer Buffer
function M.unpin_buffer(buffer)
  local _buf_list = bufs().get_buffers()

  local target_index = list.find_index(_buf_list, function(buf)
    return M.is_pinned(buffer.buf) and buf.buf == buffer.buf
  end)

  -- pinned buffers are always next to each other
  local next_pinned = list.find({ _buf_list[target_index + 1] or {}, _buf_list[target_index - 1] or {} }, function(item)
    return M.is_pinned(item.buf)
  end)

  logger.debug("unpin_buffer: next pinned buffer", next_pinned)
  if not next_pinned then
    -- there is no pinned buffer any more
    _pinned_bufnrs = {}
  else
    logger.debug("unpin_buffer: next pinned buffer found", { next_pinned = next_pinned })

    M.set_active_pinned_bufnr(next_pinned.buf)
  end

  _buf_map[buffer.buf] = nil

  _remove_persisted_pinned_buffer(buffer)
end

local function _get_pinned_bufs()
  local _buf_list = bufs().get_buffers()
  return list.filter(_buf_list, function(buf)
    return M.is_pinned(buf.buf)
  end)
end

local function _get_unpinned_bufs()
  local _buf_list = bufs().get_buffers()
  return list.filter(_buf_list, function(buf)
    return not M.is_pinned(buf.buf)
  end)
end

function M.get_active_pinned_buffer()
  local bufnr = M.get_active_pinned_bufnr()

  if not bufnr then
    return nil, nil
  end

  return bufs().get_buffer_by_bufnr(bufnr)
end

---@param type 'next' | 'prev'
function M.get_next_or_prev_pinned_buffer(type)
  local currently_pinned_bufnr = M.get_active_pinned_bufnr()

  if not currently_pinned_bufnr then
    return
  end

  local pinned_buffers = _get_pinned_bufs()

  if not pinned_buffers then
    return
  end

  local currently_pinned_buf_index = list.find_index(pinned_buffers, function(buf)
    return buf.buf == currently_pinned_bufnr
  end)

  if not currently_pinned_buf_index then
    return
  end

  local target_buf_index = currently_pinned_buf_index + (type == "next" and 1 or -1)
  return pinned_buffers[target_buf_index]
end

local loaded = true
local cwd = vim.loop.cwd()
function M.restore_pinned_buffers()
  if not loaded or cwd == vim.loop.cwd() then
    return
  end

  loaded = true
  cwd = vim.loop.cwd()

  local filename = _get_filename()
  local ok, pinned_bufs = pcall(function()
    return file.read_json_file(filename)
  end)

  if not ok then
    logger.error("restore_pinned_buffers failed", { filename = filename, err = pinned_bufs })
    return
  end

  list.for_each(pinned_bufs or {}, function(buf)
    if vim.fn.filereadable(buf.path) == 1 then
      vim.cmd("badd " .. buf.path)
    end
  end)

  local paths = list.map(pinned_bufs or {}, function(buf)
    return buf.path
  end)

  local pinned_bufnrs = bufs().add_buffer_by_file_path(paths)

  if pinned_bufnrs then
    list.for_each(pinned_bufnrs, function(buf)
      _buf_map[buf.buf] = true
    end)
  end
end

return M
