local constants = require("vuffers.constants")

local M = {}
local split

function M.init(opts)
  local Split = require("nui.split")

  split = Split({
    relative = "editor",
    position = "left",
    size = "20%",
    win_options = {
      relativenumber = false,
      number = true,
      list = false,
      winfixwidth = true,
      winfixheight = true,
      foldenable = false,
      spell = false,
      signcolumn = "yes",
      foldmethod = "manual",
      foldcolumn = "0",
      cursorcolumn = true,
      cursorline = true,
      colorcolumn = "0",
      winhighlight = "Normal:VerticalBuffers",
    },

    buf_options = {
      swapfile = false,
      buftype = "nofile",
      modifiable = true,
      filetype = constants.FILE_TYPE,
      bufhidden = "hide",
    },
  })

  split:mount()

  split:hide()

  -- print("window is initiated" .. split.bufnr)
  return split
end

local function get_split()
  if not M.is_valid() then
    return M.init()
  end

  if split then
    return split
  end

  print("this should not happen...")
  return M.init()
end

function M.get_window_id()
  return vim.fn.bufwinid(M.get_split_buf_num())
end

function M.is_valid()
  if not (split and split.bufnr) then
    return false
  end

  if not vim.api.nvim_buf_is_valid(split.bufnr) then
    print("split has invalid buffer")
    return false
  end

  return true
end

local is_open = false

function M.open()
  local s = get_split()
  s:show()
  is_open = true
end

function M.close()
  local s = get_split()

  s:hide()
  is_open = false
end

function M.is_hidden()
  return not is_open
end

---@return number
function M.get_split_buf_num()
  local s = get_split()

  return s.bufnr
end

return M
