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

---@type table<BufPath, boolean>
local _buf_map = {}

M.get_pinned_bufs = function()
  return _buf_map
end

M.is_empty = function()
  return list.find_index(_buf_map, function(is_pinned)
    return is_pinned
  end) == nil
end

--- only for testing!
--- @param data BufPath[]
M.__set_pinned_bufnrs = function(data)
  for _, n in pairs(data) do
    _buf_map[n] = true
  end
end

M.__reset_pinned_bufnrs = function()
  _buf_map = {}
end

---@param path BufPath | nil
M.is_pinned = function(path)
  return _buf_map[path] == true
end

---@type BufPath[] first one is last, and the second one is current
local _pinned_bufnrs = {}

---@return BufPath | nil
function M.get_last_visited_pinned_buf_path()
  return _pinned_bufnrs[1]
end

---@return BufPath | nil
function M.get_active_pinned_buf_path()
  return _pinned_bufnrs[2]
end

---@param buf {path: BufPath}
function M.set_active_pinned_buf(buf)
  local _buf_list = bufs().get_buffers()
  local prev_pos = 1
  local current_pos = 2

  local is_buf_pinned = list.find_index(_buf_list, function(b)
    return M.is_pinned(buf.path) and b.path == buf.path
  end) ~= nil

  if not is_buf_pinned then
    return
  end

  _pinned_bufnrs[prev_pos] = _pinned_bufnrs[current_pos] or buf.path
  _pinned_bufnrs[current_pos] = buf.path

  return true
end

---@return string
local function _get_filename()
  local cwd = vim.loop.cwd()
  local filename = str.replace(cwd, "/", "_")
  return PINNED_BUFFER_LOCATION .. "/" .. filename .. ".json"
end

---@param buffer Buffer
function M.pin_buffer(buffer)
  _buf_map[buffer.path] = true
  M.set_active_pinned_buf(buffer)
end

---@param buffer Buffer
function M.unpin_buffer(buffer)
  local _buf_list = bufs().get_buffers()

  local target_index = list.find_index(_buf_list, function(buf)
    return M.is_pinned(buffer.path) and buf.path == buffer.path
  end)

  -- pinned buffers are always next to each other
  local next_pinned = list.find({ _buf_list[target_index + 1] or {}, _buf_list[target_index - 1] or {} }, function(item)
    return M.is_pinned(item.path)
  end)

  logger.debug("unpin_buffer: next pinned buffer", next_pinned)
  if not next_pinned then
    -- there is no pinned buffer any more
    _pinned_bufnrs = {}
  else
    logger.debug("unpin_buffer: next pinned buffer found", { next_pinned = next_pinned })

    M.set_active_pinned_buf(next_pinned)
  end

  _buf_map[buffer.path] = nil
end

local function _get_pinned_bufs()
  local _buf_list = bufs().get_buffers()
  return list.filter(_buf_list, function(buf)
    return M.is_pinned(buf.path)
  end)
end

-- local function _get_unpinned_bufs()
--   local _buf_list = bufs().get_buffers()
--   return list.filter(_buf_list, function(buf)
--     return not M.is_pinned(buf.path)
--   end)
-- end

function M.get_active_pinned_buffer()
  local path = M.get_active_pinned_buf_path()

  if not path then
    return nil, nil
  end

  return bufs().get_buffer_by_path(path)
end

---@param type 'next' | 'prev'
function M.get_next_or_prev_pinned_buffer(type)
  local currently_pinned_path = M.get_active_pinned_buf_path()

  if not currently_pinned_path then
    return
  end

  local pinned_buffers = _get_pinned_bufs()

  if not pinned_buffers then
    return
  end

  local currently_pinned_buf_index = list.find_index(pinned_buffers, function(buf)
    return buf.path == currently_pinned_path
  end)

  if not currently_pinned_buf_index then
    return
  end

  local target_buf_index = currently_pinned_buf_index + (type == "next" and 1 or -1)
  return pinned_buffers[target_buf_index]
end

-- TODO: move to buffers.init
function M.persist_pinned_buffers()
  local buffers = bufs().get_buffers()

  -- TODO: remove. pinned_buffers is a list of paths
  local to_save = list.filter(buffers, function(buf)
    return M.is_pinned(buf.path)
  end)
  to_save = list.map(to_save or {}, function(buf)
    return { path = buf.path }
  end)

  if not #to_save then
    return
  end

  local ok, err = pcall(function()
    local filename = _get_filename()

    file.write_json_file(filename, to_save)
  end)

  if not ok then
    logger.error("persist_pinned_buffer: ", err)
  end
end

function M.restore_pinned_buffers()
  local filename = _get_filename()
  local ok, pinned_bufs = pcall(function()
    return file.read_json_file(filename)
  end)

  if not ok then
    logger.error("restore_pinned_buffers failed", { filename = filename, err = pinned_bufs })
    return
  end

  -- this is necessary only when session is not loaded
  list.for_each(pinned_bufs or {}, function(buf)
    if vim.fn.filereadable(buf.path) == 1 then
      vim.cmd("badd " .. buf.path)
    end
  end)

  list.for_each(pinned_bufs or {}, function(buf)
    _buf_map[buf.path] = true
  end)
  -- local pinned_bufnrs = bufs().add_buffer_by_file_path(pinned_bufs)

  -- if pinned_bufnrs then
  --   list.for_each(pinned_bufnrs, function(buf)
  --     _buf_map[buf.path] = true
  --   end)
  -- end
end

return M
