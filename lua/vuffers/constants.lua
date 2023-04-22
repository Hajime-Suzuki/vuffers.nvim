local M = {}

M.AUTO_CMD_GROUP = "VeffersAutoCmdsGroup"
M.FILE_TYPE = "vuffers"

---@enum SortType
M.SORT_TYPE = {
  NONE = "none",
  FILENAME = "filename",
}

---@enum SortDirection
M.SORT_DIRECTION = {
  ASC = "asc",
  DESC = "desc",
}

M.HIGHLIGHTS = {
  ACTIVE = "VuffersSelectedBuffer",
  WINDOW_BG = "VerticalBuffersBackground",
  MODIFIED = "VuffersModifiedBuffer",
}

return M
