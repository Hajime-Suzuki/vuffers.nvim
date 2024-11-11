local M = {}

M.AUTO_CMD_GROUP = "VeffersAutoCmdsGroup"
M.VUFFERS_FILE_TYPE = "vuffers"

---@enum SortType
M.SORT_TYPE = {
  NONE = "none",
  FILENAME = "filename",
  UNIQUE_NAME = "unique-name",
  LAST_USED = "last-used",
  __CUSTOM = "custom",
}

---@enum SortDirection
M.SORT_DIRECTION = {
  ASC = "asc",
  DESC = "desc",
}

---@enum LogLevel
M.LOG_LEVEL = {
  TRACE = "trace",
  DEBUG = "debug",
  INFO = "info",
  WARN = "warn",
  ERROR = "error",
}

M.HIGHLIGHTS = {
  WINDOW_BG = "VuffersWindowBackground",
  ACTIVE = "VuffersActiveBuffer",
  MODIFIED_ICON = "VuffersModifiedIcon",
  PINNED_ICON = "VuffersPinnedIcon",
  ACTIVE_PINNED_ICON = "VuffersActivePinnedIcon",
}

M.VUFFERS_FILE_LOCATION = vim.fn.stdpath("data") .. "/vuffers"

return M
