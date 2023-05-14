local bufs = require("vuffers.buffers.buffers")
local pinned = require("vuffers.buffers.pinned-buffers")
local M = {}

M.add_buffer = bufs.add_buffer
M.change_sort = bufs.change_sort
M.debug_buffers = bufs.debug_buffers
M.decrement_additional_folder_depth = bufs.decrement_additional_folder_depth
M.get_active_buffer = bufs.get_active_buffer
M.get_active_bufnr = bufs.get_active_bufnr
M.get_buffer_by_bufnr = bufs.get_buffer_by_bufnr
M.get_buffer_by_index = bufs.get_buffer_by_index
M.get_buffers = bufs.get_buffers
M.get_num_of_buffers = bufs.get_num_of_buffers
M.increment_additional_folder_depth = bufs.increment_additional_folder_depth
M.reload_buffers = bufs.reload_buffers
M.remove_buffer = bufs.remove_buffer
M.reset_buffers = bufs.reset_buffers
M.set_active_bufnr = bufs.set_active_bufnr
M.set_buffers = bufs.set_buffers
M._get_buffer_list_changed_event_payload = bufs._get_buffer_list_changed_event_payload
M._set_active_bufnr = bufs._set_active_bufnr

M.get_active_pinned_buffer = pinned.get_active_pinned_buffer
M.get_active_pinned_bufnr = pinned.get_active_pinned_bufnr
M.get_next_or_prev_pinned_buffer = pinned.get_next_or_prev_pinned_buffer
M.pin_buffer = pinned.pin_buffer
M.remove_unpinned_buffers = pinned.remove_unpinned_buffers
M.set_active_pinned_bufnr = pinned.set_active_pinned_bufnr
M.unpin_buffer = pinned.unpin_buffer

return M
