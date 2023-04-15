local utils = require("vuffers.buffer-utils")
local list = require("utils.list")

local M = {}
---@type number | nil
local current = nil

function M.set_current_bufnr(bufnr)
  current = bufnr
end

function M.get_current_bufnr()
  return current
end

---@type {buf: number, name: string, index: number, path: string }[]
local _buffers = {}

local function get_formatted_buffers()
  return utils.get_file_names(_buffers)

  -- return list.map(buffers_with_unique_names, function(buffer)
  --   return {
  --     buf = buffer.buf,
  --     name = buffer.name,
  --     index = buffer.index,
  --     path = buffer.path,
  --     -- active = buffer.buf == get_current_bufnr(),
  --   }
  -- end)
end

---@param buffer {buf: number, event: string, file: string, group: number, id: number, match: string}
function M.add_buffer(buffer)
  local is_duplicated = list.find(_buffers, function(buf)
    return buf.buf == buffer.buf
  end) ~= nil

  if is_duplicated then
    return
  end

  table.insert(_buffers, {
    buf = buffer.buf,
    name = buffer.file,
    index = #buffer + 1,
    path = buffer.file,
  })

  _buffers = get_formatted_buffers()
end

---@param bufnr number
function M.remove_buffer(bufnr)
  local index = list.find_index(_buffers, function(buf)
    return buf.buf == bufnr
  end)

  if index then
    table.remove(_buffers, index)
  end

  _buffers = get_formatted_buffers()
end

local function reset_buffers()
  _buffers = {}
end

function M.reload_all_buffers()
  reset_buffers()

  local bufs = vim.api.nvim_list_bufs()

  for i, buf in ipairs(bufs) do
    local name = vim.api.nvim_buf_get_name(buf)

    if name ~= "" and name ~= "/" then
      table.insert(_buffers, { buf = buf, name = name, index = i, path = name })
    end
  end

  _buffers = get_formatted_buffers()
end

function M.get_all_buffers()
  return _buffers
end

function M.get_all_buffer_names()
  local buffers = M.get_all_buffers()

  return list.map(buffers, function(buf)
    return buf.name .. " (#" .. buf.buf .. ")"
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

function M.get_current_buffer()
  local buffers = M.get_all_buffers()
  local bufnr = M.get_current_bufnr()

  return list.find(buffers, function(buf)
    return buf.buf == bufnr
  end)
end

return M
