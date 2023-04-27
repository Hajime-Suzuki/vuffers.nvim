local logger = require("utils.logger")
local list = require("utils.list")
local events = require("vuffers.events")

local M = {}

---@type table<string, {handler: function, label: string}[]>
local _subscribers = {}

--- only for testing
function M._delete_all_subscriptions()
  _subscribers = {}
end

---@param event Event
---@param handler function
---@param opts {label: string}
function M.subscribe(event, handler, opts)
  if not _subscribers[event] then
    _subscribers[event] = {}
  end

  table.insert(_subscribers[event], { handler = handler, label = opts.label })

  local label = opts.label
  logger.debug("subscribed to event: " .. event .. " (" .. label .. ")")
end

---@param event Event
---@param payload? any
function M.publish(event, payload)
  logger.debug("receiving event: " .. event, { event = event, payload = payload })

  local handlers = _subscribers[event]
  if not handlers or not #handlers then
    logger.debug("no handler found", { event = event })
    return
  end

  list.for_each(handlers, function(handler)
    logger.debug("handling event: " .. event, { target = handler.label, payload = payload })
    handler.handler(payload)
  end)
end

-- NOTE: for typing purpose, publish function is created per event type

---@alias ActiveBufferChangedPayload { index: integer }
---@alias BufferListChangedPayload { buffers: Buffer[], active_buffer_index: integer }
---@alias VuffersWindowOpenedPayload {buffer_number: integer }

---@param payload ActiveBufferChangedPayload
function M.publish_active_buffer_changed(payload)
  M.publish(events.names.ActiveBufferChanged, payload)
end

---@param payload BufferListChangedPayload
function M.publish_buffer_list_changed(payload)
  M.publish(events.names.BufferListChanged, payload)
end

---@param payload VuffersWindowOpenedPayload
function M.publish_vuffers_window_opened(payload)
  M.publish(events.names.VuffersWindowOpened, payload)
end

return M
