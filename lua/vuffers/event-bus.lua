local logger = require("utils.logger")
local list = require("utils.list")

local M = {}

---@type table<string, {handler: function, label: string}[]>
local _subscribers = {}

---@param event Event
---@param handler function
---@param opts {label: string}
function M.subscribe(event, handler, opts)
  if _subscribers[event] then
    _subscribers[event] = {}
  end

  table.insert(_subscribers[event], handler)

  local label = opts.label
  logger.debug("subscribed to event: " .. event .. " (" .. label .. ")")
end

---@param event Event
---@param payload? any
function M.publish(event, payload)
  logger.debug("receiving event: " .. event, { event = event, payload = payload })

  local handlers = _subscribers[event]
  if not #handlers then
    logger.debug("no handler found", { event = event })
    return
  end

  list.for_each(handlers, function(handler)
    handler.handler(payload)
    logger.debug("publish event: " .. event, { target = handler.label, payload = payload })
  end)
end

return M
