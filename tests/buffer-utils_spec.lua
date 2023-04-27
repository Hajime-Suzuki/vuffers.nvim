---@diagnostic disable: undefined-global
local utils = require("vuffers.buffer-utils")
local list = require("utils.list")
local constants = require("vuffers.constants")

describe("utils", function()
  describe("get_file_names", function()
    it("returns correct filenames when the filenames of the input is unique", function()
      local res = utils.get_file_names({
        { path = "a/hi.ts", buf = 1 },
        { path = "b/user.ts", buf = 2 },
        { path = "b/user.test.ts", buf = 3 },
        { path = "a/test.js", buf = 4 },
        { path = "test.json", buf = 5 },
        { path = ".eslintrc", buf = 6 },
        { path = "Dockerfile", buf = 7 },
      })

      table.sort(res, function(a, b)
        return a.buf < b.buf
      end)

      local filenames = list.map(res, function(item)
        return item.name
      end)

      local extensions = list.map(res, function(item)
        return item.ext
      end)

      assert.are.same({ "hi", "user", "user.test", "test", "test", ".eslintrc", "Dockerfile" }, filenames)
      assert.are.same({ "ts", "ts", "ts", "js", "json", "eslintrc", nil }, extensions)
    end)

    it("returns correct filenames when the filenames of the input has duplicate. case 1", function()
      local res = utils.get_file_names({
        { path = "hi.ts", buf = 1 },
        { path = "b/user.ts", buf = 2 },
        { path = "a/test.ts", buf = 3 },
        { path = "a/user.ts", buf = 4 },
        { path = ".eslintrc", buf = 5 },
      })

      table.sort(res, function(a, b)
        return a.buf < b.buf
      end)

      res = list.map(res, function(item)
        return item.name
      end)

      assert.are.same({ "hi", "b/user", "test", "a/user", ".eslintrc" }, res)
    end)

    it("returns correct filenames when the filenames of the input has duplicate. case 2", function()
      local res = utils.get_file_names({
        { path = "b/user.ts", buf = 1 },
        { path = "user.ts", buf = 2 },
      })

      table.sort(res, function(a, b)
        return a.buf < b.buf
      end)

      res = list.map(res, function(item)
        return item.name .. "." .. item.ext
      end)

      assert.are.same({ "b/user.ts", "user.ts" }, res)
    end)

    it("returns correct filenames when the filenames of the input has duplicate. case 3", function()
      local res = utils.get_file_names({
        { path = "user.ts", buf = 1 },
        { path = "b/user.ts", buf = 2 },
      })

      table.sort(res, function(a, b)
        return a.buf < b.buf
      end)

      res = list.map(res, function(item)
        return item.name .. "." .. item.ext
      end)

      assert.are.same({ "user.ts", "b/user.ts" }, res)
    end)

    it("returns correct filenames when the filenames of the input has multiple duplicate. case 4", function()
      local res = utils.get_file_names({
        { path = "a/user.ts", buf = 1 },
        { path = "b/user.ts", buf = 2 },
        { path = "x/a/test.ts", buf = 3 },
      })

      table.sort(res, function(a, b)
        return a.buf < b.buf
      end)

      res = list.map(res, function(item)
        return item.name .. "." .. item.ext
      end)

      assert.are.same({ "a/user.ts", "b/user.ts", "test.ts" }, res)
    end)

    it("returns correct filenames when the filenames of the input has multiple duplicate. case 5", function()
      local res = utils.get_file_names({
        { path = "a/b.ts", buf = 1 },
        { path = "x/a/b.ts", buf = 2 },
        { path = "m/n/b.ts", buf = 3 },
        { path = "c/b.ts", buf = 4 },
      })

      table.sort(res, function(a, b)
        return a.buf < b.buf
      end)

      res = list.map(res, function(item)
        return item.name .. "." .. item.ext
      end)

      assert.are.same({ "a/b.ts", "x/a/b.ts", "n/b.ts", "c/b.ts" }, res)
    end)
  end)

  describe("sort_buffers", function()
    it("should sort by filename", function()
      local bufs = {
        {
          buf = 4,
          name = "some.test",
          ext = "ts",
        },
        {
          buf = 6,
          name = "main",
          ext = "ts",
        },
        {
          buf = 5,
          name = "some",
          ext = "ts",
        },
      }

      local res =
        utils.sort_buffers(bufs, { type = constants.SORT_TYPE.FILENAME, direction = constants.SORT_DIRECTION.ASC })

      res = list.map(bufs, function(item)
        return item.name
      end)

      assert.are.same(res, { "main", "some", "some.test" })
    end)
  end)
end)
