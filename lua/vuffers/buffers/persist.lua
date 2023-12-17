local file = require("utils.file")
local logger = require("utils.logger")
local str = require("utils.string")
local list = require("utils.list")
local bufs = require("vuffers.buffers.buffers")
local pinned = require("vuffers.buffers.pinned-buffers")
local constants = require("vuffers.constants")

local M = {}

local _is_restored_from_session = false
M.is_restored_from_session = function()
  return _is_restored_from_session
end

---@param value boolean
M.set_is_restored_from_session = function(value)
  _is_restored_from_session = value
end

--------------pinned buffers ----------------
local function _get_pinned_buffers_filename()
  local filename = file.cwd_name()
  return constants.VUFFERS_FILE_LOCATION .. "/" .. filename .. ".json"
end

function M.persist_pinned_buffers()
  local buffers = bufs.get_buffers()

  local to_save = list.filter(buffers, function(buf)
    return pinned.is_pinned(buf.path)
  end)
  to_save = list.map(to_save or {}, function(buf)
    return { path = buf.path }
  end)
  if not next(to_save) then
    return
  end

  local ok, err = pcall(function()
    local filename = _get_pinned_buffers_filename()

    file.write_json_file(filename, to_save)
  end)

  if not ok then
    logger.error("persist_pinned_buffer: ", err)
  end
end

function M.restore_pinned_buffers()
  local filename = _get_pinned_buffers_filename()
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
    pinned.pin_buffer(buf)
  end)
end

--------------buffers ----------------

---@return string
local function _get_buffers_filename()
  local filename = file.cwd_name() .. "_buffers"
  return constants.VUFFERS_FILE_LOCATION .. "/" .. filename .. ".json"
end

function M.persist_buffers()
  local ok, err = pcall(function()
    local filename = _get_buffers_filename()

    local data = list.map(bufs.get_buffers(), function(buf)
      return {
        path = buf.path,
        _custom_name = buf._custom_name,
      }
    end)

    file.write_json_file(filename, data)
  end)

  if not ok then
    logger.error("persist_pinned_buffer: ", err)
  end
end

function M.restore_buffers_from_file()
  local filename = _get_buffers_filename()

  ---@type boolean, { path: string, _custom_name: string }[]
  local ok, buffers = pcall(function()
    return file.read_json_file(filename)
  end)

  if not ok then
    logger.error("restore_buffers_from_file failed", { filename = filename, err = buffers })
    return
  end

  if not next(buffers) then
    return
  end

  -- add buffers so that buffer gets buffer number
  list.for_each(buffers or {}, function(buf)
    if vim.fn.filereadable(buf.path) == 1 then
      vim.cmd("badd " .. buf.path)
    end
  end)

  return bufs.add_buffer_by_file_path(buffers)
end

return M
