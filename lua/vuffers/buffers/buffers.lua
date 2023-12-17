local logger = require("utils.logger")
local utils = require("vuffers.buffers.buffer-utils")
local list = require("utils.list")
local config = require("vuffers.config")

local active = function()
  return require("vuffers.buffers.active-buffer")
end

--------------types >>----------------

---@class Buffer
---@field buf Bufnr
---@field name string name that will be displayed in the buffer list, which considers additional folder depth //TODO: change it to display name
---@field path string
---@field ext string
---@field _custom_name string | nil set if user renames the file
---@field _unique_name string unique name (when "src/main" is `name`, then "main" is `_unique_name`)
---@field _filename string filename ("test" in "test.txt")
---@field _default_folder_depth number
---@field _additional_folder_depth number //TODO: make it custom_name if possible
---@field _max_folder_depth number

---@class NativeBuffer
---@field buf number
---@field file string
---@field event string
---@field group number
---@field id number
---@field match string

---@alias Bufnr integer
---@alias BufPath string
--------------<<types ----------------

local M = {}

---@type Buffer[]
local _buf_list = {}

---@param bufs Buffer[]
M.set_buffers = function(bufs)
  _buf_list = bufs
end

M.get_buffers = function()
  return _buf_list
end

---@type integer | nil How many more parents the UI shows. This can not go below 0
local _global_additional_folder_depth = 0

---@param buf_or_filename integer | string
---@return boolean
-- `buf_or_filename` can be buffer number of filename
local function _is_in_buf_list(buf_or_filename)
  return list.find(_buf_list, function(buffer)
    return buffer.buf == buf_or_filename or buffer.path == buf_or_filename
  end) ~= nil
end

function M.get_num_of_buffers()
  return #_buf_list
end

---@param buffer NativeBuffer
function M.add_buffer(buffer)
  local should_ignore = _is_in_buf_list(buffer.file)

  if should_ignore then
    return
  end

  logger.debug("add_buffer: buffer will be added", { file = buffer.file })

  table.insert(_buf_list, {
    buf = buffer.buf,
    name = buffer.file,
    path = buffer.file,
    _additional_folder_depth = _global_additional_folder_depth,
  })

  local buffers = utils.get_formatted_buffers(_buf_list)
  buffers = utils.sort_buffers(buffers, config.get_sort())
  _buf_list = buffers

  logger.debug("add_buffer: buffer is added", { file = buffer.file })

  return true
end

---@param args {index: number, new_name: string}
function M.rename_buffer(args)
  _buf_list[args.index]._custom_name = args.new_name
  local buffers = utils.get_formatted_buffers(_buf_list)
  buffers = utils.sort_buffers(buffers, config.get_sort())
  _buf_list = buffers
end

---@param args {index: number}
function M.reset_custom_display_name(args)
  local target = M.get_buffer_by_index(args.index)

  if not target or not target._custom_name then
    return
  end

  target._custom_name = nil

  local updated = utils.get_formatted_buffers({ target })
  _buf_list[args.index] = updated[1]

  return true
end

function M.reset_custom_display_names()
  local bufs = M.get_buffers()
  ---@diagnostic disable-next-line: cast-local-type
  local bufs_with_custom_name = list.filter(bufs or {}, function(buf)
    return buf._custom_name ~= nil
  end)

  if not bufs_with_custom_name or not next(bufs_with_custom_name) then
    return
  end

  list.for_each(bufs, function(buf, i)
    if buf._custom_name then
      buf._custom_name = nil
    end
  end)

  bufs = utils.get_formatted_buffers(bufs)
  bufs = utils.sort_buffers(bufs, config.get_sort())

  _buf_list = bufs

  return true
end

---@param args {bufnr?: number}
function M.remove_buffer(args)
  if not args.path then
    return
  end

  local target_index = list.find_index(_buf_list, function(buf)
    return buf.path == args.path
  end)

  if not target_index then
    -- TODO: debounce. buffer is deleted by UI action, first the buffer list is updated, then actual buffer is deleted by :bufwipeout, which triggers this function again
    logger.debug("remove_buffer: buffer not found", args)
    return
  end

  logger.debug("remove_buffer: buffer will be removed", args)

  local active_buf_path = active().get_active_buf_path()

  if args.path ~= active_buf_path then
    table.remove(_buf_list, target_index)
    local buffers = utils.get_formatted_buffers(_buf_list)
    buffers = utils.sort_buffers(buffers, config.get_sort())
    _buf_list = buffers

    logger.debug("remove_buffer: buffer is removed", args)

    return true
  end
  --
  ---@type Buffer | nil
  local next_active_buffer = _buf_list[target_index + 1] or _buf_list[target_index - 1]

  if next_active_buffer then
    active().set_active_buf(next_active_buffer)
  else
    logger.warn("remove_buffer: can not delete the last buffer", args)
    return
  end

  table.remove(_buf_list, target_index)
  logger.debug("remove_buffer: buffer is removed", args)

  return true
end

function M.change_sort()
  _buf_list = utils.sort_buffers(_buf_list, config.get_sort())
end

---@param args {origin_index: number, target_index: number}
function M.move_buffer(args)
  local origin_buf = _buf_list[args.origin_index]
  local target_buf = _buf_list[args.target_index]

  if args.target_index == args.origin_index then
    return logger.warn("move_buffer: target is the same as origin", args)
  end

  if not origin_buf or not target_buf then
    return logger.warn("move_buffer: buffer not found", args)
  end

  table.remove(_buf_list, args.origin_index)
  table.insert(_buf_list, args.target_index, origin_buf)

  return true
end

---@param new_level integer
local function _change_additional_folder_depth(new_level)
  if new_level == _global_additional_folder_depth then
    logger.debug("change_level: level is not changed")
    return
  end

  local bufs = list.map(_buf_list, function(buf)
    buf._additional_folder_depth = new_level
    return buf
  end)
  bufs = utils.get_formatted_buffers(bufs)
  bufs = utils.sort_buffers(bufs, config.get_sort())
  _buf_list = bufs

  _global_additional_folder_depth = new_level
  logger.debug("change_level: level changed", { new_level = new_level })

  return true
end

function M.increment_additional_folder_depth()
  local max_folder_depths = list.map(_buf_list, function(buf)
    return buf._max_folder_depth
  end)
  local max_additional_folder_depth = math.max(unpack(max_folder_depths)) - 1
  local new_level = math.min(_global_additional_folder_depth + 1, max_additional_folder_depth)
  return _change_additional_folder_depth(new_level)
end

function M.decrement_additional_folder_depth()
  local new_level = math.max(_global_additional_folder_depth - 1, 0)
  return _change_additional_folder_depth(new_level)
end

---@return {buf: Bufnr, name: string, path: string, filetype: string, _additional_folder_depth: integer}
local function _get_loaded_bufs()
  local bufs = vim.api.nvim_list_bufs()
  return list.map(bufs, function(buf)
    local name = vim.api.nvim_buf_get_name(buf)
    local filetype = vim.api.nvim_buf_get_option(buf, "filetype")
    return {
      buf = buf,
      name = name,
      path = name,
      filetype = filetype,
      _additional_folder_depth = _global_additional_folder_depth,
    }
  end)
end

---@param file_paths {path: string, _custom_name:string} []
---@return { path: BufPath }[] | nil
function M.add_buffer_by_file_path(file_paths)
  local bufs = _get_loaded_bufs()

  ---@type {[string]: { path: string, _custom_name:string }[]}
  local path_map = list.group_by(file_paths, function(file_path)
    return file_path.path
  end)

  ---@type ({ buf: Bufnr, name: string, path: string, filetype: string, _additional_folder_depth: integer } | nil)[]
  local bufs_to_add = list.map(bufs, function(buf)
    if not utils.is_valid_buf(buf) then
      return nil
    end

    local data = path_map[buf.path]
    if not data then
      return nil
    end

    return {
      buf = buf.buf,
      name = buf.name,
      path = buf.path,
      filetype = buf.filetype,
      _additional_folder_depth = buf._additional_folder_depth,
      _custom_name = data[1]._custom_name,
    }
  end)
  bufs_to_add = list.filter(bufs_to_add, function(buf)
    return buf ~= nil
  end)

  if bufs_to_add == nil then
    logger.warn("reload_all_buffers: no buffers found")
    return
  end

  local merged = list.merge_unique(bufs_to_add, _buf_list, {
    id = function(buf)
      return buf.path
    end,
  })

  bufs = utils.get_formatted_buffers(merged)
  bufs = utils.sort_buffers(bufs, config.get_sort())
  _buf_list = bufs

  return bufs_to_add
end

function M.reset_buffers()
  _buf_list = {}

  local bufs = _get_loaded_bufs()
  ---@diagnostic disable-next-line: cast-local-type
  bufs = list.filter(bufs, utils.is_valid_buf)

  if bufs == nil then
    logger.warn("reload_all_buffers: no buffers found")
    return
  end

  bufs = utils.get_formatted_buffers(bufs)
  bufs = utils.sort_buffers(bufs, config.get_sort())
  _buf_list = bufs

  return true
end

---@param index integer
function M.get_buffer_by_index(index)
  return _buf_list[index]
end

---@param path BufPath
---@return Buffer | nil buffer, integer | nil index
function M.get_buffer_by_path(path)
  local index = list.find_index(_buf_list, function(buf)
    return buf.path == path
  end)

  if not index then
    return
  end

  return _buf_list[index], index
end

return M
