local utils = require("vuffers.buffer-utils")
local list = require("utils.list")
local config = require("vuffers.config")
local constants = require("vuffers.constants")
local events = require("vuffers.events")

local M = {}
---@type number | nil
local current = nil

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

---@param buffer {buf: number, file: string }
---@param file_type? string
function M.set_current_bufnr(buffer, file_type)
  if _is_invalid_file(buffer.file, file_type) then
    return
  end

  -- if buffer.buf == current then
  --   return
  -- end

  current = buffer.buf
  events.publish(events.names.ActiveFileChanged)
end

local function reset_active_buffer()
  current = nil
end

function M.get_current_bufnr()
  return current
end

---@class Buffer
---@field buf number
---@field name string
---@field path string: full path of

---@class NvimBuffer
---@field buf number
---@field file string
---@field event string
---@field group number
---@field id number
---@field match string

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

---@param buffer {buf: number, event: string, file: string, group: number, id: number, match: string}
---@param file_type string
function M.add_buffer(buffer, file_type)
  local should_ignore = _is_invalid_file(buffer.file, file_type) or _is_in_buf_list(buffer.file)

  if should_ignore then
    return
  end

  table.insert(_buf_list, {
    buf = buffer.buf,
    name = buffer.file,
    path = buffer.file,
  })

  _buf_list = _get_formatted_buffers()

  events.publish(events.names.BufferListChanged)
end

function M.debug_buffers()
  print("current", current)
  print("buffers", vim.inspect(_buf_list))
end

---@param args {bufnr?: number, index?: integer}
function M.remove_buffer(args)
  print("remove buffer", args.bufnr, args.index)
  if not args.bufnr and not args.index then
    return
  end

  local target_index = args.index or list.find_index(_buf_list, function(buf)
    return buf.buf == args.bufnr
  end)

  if not target_index then
    print("not found buffer to remove")
    return
  end

  if target_index ~= M.get_current_bufnr() then
    print("different buffer")
    table.remove(_buf_list, target_index)
    _buf_list = _get_formatted_buffers()
    events.publish(events.names.BufferListChanged)
    return
  end
  --
  ---@type {buf: number, name: string, index: number, path: string } | nil
  local next_active_buffer = _buf_list[target_index + 1] or _buf_list[target_index - 1]

  if next_active_buffer then
    M.set_current_bufnr({ buf = next_active_buffer.buf, file = next_active_buffer.path })
  else
    print("can not delete last buffer")
    return
  end

  table.remove(_buf_list, target_index)
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

function M.get_all_buffer_names()
  local buffers = M.get_all_buffers()

  return list.map(buffers, function(buf)
    return buf.name
  end)
end

---@param bufnr number
function M.get_buffer_by_id(bufnr)
  local buffers = M.get_all_buffers()

  return list.find(buffers, function(buf)
    return buf.buf == bufnr
  end)
end

---@param name string
function M.get_buffer_by_name(name)
  local buffers = M.get_all_buffers()

  return list.find(buffers, function(buf)
    return buf.path == name
  end)
end

---@param index integer
function M.get_buffer_by_index(index)
  local buffers = M.get_all_buffers()

  return buffers[index]
end

function M.get_current_buffer()
  local buffers = M.get_all_buffers()
  local bufnr = M.get_current_bufnr()

  return list.find(buffers, function(buf)
    return buf.buf == bufnr
  end)
end

function M.get_current_buffer_index()
  local buffers = M.get_all_buffers()
  local bufnr = M.get_current_bufnr()

  return list.find_index(buffers, function(buf)
    return buf.buf == bufnr
  end)
end

return M
