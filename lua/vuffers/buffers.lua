local logger = require("utils.logger")
local utils = require("vuffers.buffer-utils")
local list = require("utils.list")
local config = require("vuffers.config")
local constants = require("vuffers.constants")
local events = require("vuffers.events")
--------------types >>----------------

---@class Buffer
---@field buf number
---@field name string
---@field path string: full path of

---@class NativeBuffer
---@field buf number
---@field file string
---@field event string
---@field group number
---@field id number
---@field match string

--------------<<types ----------------

local M = {}
---@type number | nil
local active_bufnr = nil

---@param filename string
---@param file_type? string
local function _is_invalid_file(filename, file_type)
  if filename == "" or filename == "/" or filename == " " then
    return true
  end

  local file_names_to_ignore = config.get_exclude().file_names

  for _, pattern in pairs(file_names_to_ignore) do
    if filename:match(pattern) then
      return true
    end
  end

  if file_type then
    if file_type == constants.FILE_TYPE then
      return true
    end

    local file_types_to_ignore = config.get_exclude().file_types

    for _, ft in pairs(file_types_to_ignore) do
      if file_type == ft then
        return true
      end
    end
  end
end

---@param buffer {path: string, buf: integer}
---@param file_type? string
function M.set_active_bufnr(buffer, file_type)
  if _is_invalid_file(buffer.path, file_type) then
    return
  end

  active_bufnr = buffer.buf
  events.publish(events.names.ActiveFileChanged)
end

local function _get_active_bufnr()
  return active_bufnr
end

---@type Buffer[]
local _buf_list = {}

local function reset_buffers()
  _buf_list = {}
end

local function _get_formatted_buffers()
  return utils.get_file_names(_buf_list)
end

---@param buf_or_filename integer | string
---@return boolean
-- `buf_or_filename` can be buffer number of filename
local function _is_in_buf_list(buf_or_filename)
  return list.find(_buf_list, function(buffer)
    return buffer.buf == buf_or_filename or buffer.name == buf_or_filename
  end) ~= nil
end

function M.get_num_of_buffers()
  return #_buf_list
end

---@param buffer NativeBuffer
---@param file_type string
function M.add_buffer(buffer, file_type)
  local should_ignore = _is_invalid_file(buffer.file, file_type) or _is_in_buf_list(buffer.file)

  logger.debug("add_buffer: buffer will be added", { file = buffer.file, file_type = file_type })

  if should_ignore then
    return
  end

  table.insert(_buf_list, {
    buf = buffer.buf,
    name = buffer.file,
    path = buffer.file,
  })

  _buf_list = _get_formatted_buffers()

  logger.debug("add_buffer: buffer is added", { file = buffer.file, file_type = file_type })

  events.publish(events.names.BufferListChanged)
end

---@param args {bufnr?: number, index?: integer}
function M.remove_buffer(args)
  if not args.bufnr and not args.index then
    return
  end

  logger.debug("remove_buffer: buffer will be removed", args)

  local target_index = args.index or list.find_index(_buf_list, function(buf)
    return buf.buf == args.bufnr
  end)

  if not target_index then
    -- TODO: debounce. buffer is deleted by UI action, first the buffer list is updated, then actual buffer is deleted by :bufwipeout, which triggers thsi function again
    logger.warn("remove_buffer: buffer not found", args)
    return
  end

  if target_index ~= _get_active_bufnr() then
    table.remove(_buf_list, target_index)
    _buf_list = _get_formatted_buffers()
    logger.debug("remove_buffer: buffer is removed", args)

    events.publish(events.names.BufferListChanged)
    return
  end
  --
  ---@type Buffer | nil
  local next_active_buffer = _buf_list[target_index + 1] or _buf_list[target_index - 1]

  if next_active_buffer then
    logger.warn("remove_buffer: found new active buffer " .. next_active_buffer.name, arg)

    M.set_active_bufnr(next_active_buffer)
  else
    logger.warn("remove_buffer: can not delete the last buffer", args)
    return
  end

  table.remove(_buf_list, target_index)
  logger.debug("remove_buffer: buffer is removed", args)

  events.publish(events.names.BufferListChanged)
end

function M.reload_all_buffers()
  reset_buffers()

  local bufs = vim.api.nvim_list_bufs()

  for i, buf in ipairs(bufs) do
    local name = vim.api.nvim_buf_get_name(buf)
    local file_type = vim.api.nvim_buf_get_option(buf, "filetype")

    if not _is_invalid_file(name, file_type) then
      table.insert(_buf_list, { buf = buf, name = name, index = i, path = name })
    end
  end

  _buf_list = _get_formatted_buffers()

  events.publish(events.names.BufferListChanged)
  events.publish(events.names.ActiveFileChanged)
end

function M.get_all_buffers()
  return _buf_list
end

---@param index integer
function M.get_buffer_by_index(index)
  local buffers = M.get_all_buffers()

  return buffers[index]
end

function M.get_active_buffer()
  local buffers = M.get_all_buffers()
  local bufnr = _get_active_bufnr()

  return list.find(buffers, function(buf)
    return buf.buf == bufnr
  end)
end

function M.get_active_buffer_index()
  local buffers = M.get_all_buffers()
  local bufnr = _get_active_bufnr()

  return list.find_index(buffers, function(buf)
    return buf.buf == bufnr
  end)
end

function M.debug_buffers()
  print("active", active_bufnr)
  print("buffers", vim.inspect(_buf_list))
end

return M
