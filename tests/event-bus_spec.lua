---@diagnostic disable: undefined-global
local events = require("vuffers.events")
local event_bus = require("vuffers.event-bus")

describe("event-bus", function()
  describe("subscribe/publish", function()
    before_each(function()
      event_bus._delete_all_subscriptions()
    end)

    it("should call handler without arg if when subscribed event is published without arg", function()
      local _called = false
      local _arg
      local f = function(arg)
        _called = true
        _arg = arg
      end

      event_bus.subscribe(events.names.ActiveFileChanged, f, { label = "test" })
      event_bus.publish(events.names.ActiveFileChanged)

      assert.are.same(_called, true)
      assert.are.same(_arg, nil)
    end)

    it("should call handler with arg if when subscribed event is published with arg", function()
      local _called = false
      local _arg
      local f = function(arg)
        _called = true
        _arg = arg
      end

      event_bus.subscribe(events.names.ActiveFileChanged, f, { label = "test" })
      event_bus.publish(events.names.ActiveFileChanged, { test = true })

      assert.are.same(_called, true)
      assert.are.same(_arg, { test = true })
    end)

    it("should call multiple handlers if registered", function()
      local _f_called = false
      local _f_arg
      local f = function(arg)
        _f_called = true
        _f_arg = arg
      end

      local _g_called = false
      local _g_arg
      local g = function(arg)
        _g_called = true
        _g_arg = arg
      end

      event_bus.subscribe(events.names.ActiveFileChanged, f, { label = "test" })
      event_bus.subscribe(events.names.ActiveFileChanged, g, { label = "test2" })
      event_bus.publish(events.names.ActiveFileChanged, { test = true })

      assert.are.same(_f_called, true)
      assert.are.same(_g_called, true)
      assert.are.same(_f_arg, { test = true })
      assert.are.same(_g_arg, { test = true })
    end)

    it("should do break when event is published without subscription", function()
      event_bus.publish(events.names.ActiveFileChanged, { test = true })
    end)
  end)
end)
