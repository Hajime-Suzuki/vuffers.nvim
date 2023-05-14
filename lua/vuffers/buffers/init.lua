local bufs = require("vuffers.buffers.buffers")
local pinned = require("vuffers.buffers.pinned-buffers")
local M = vim.tbl_deep_extend("force", {}, bufs, pinned)

return M
