---@diagnostic disable: undefined-global
local utils = require("vuffers.buffer-utils")
local list = require("utils.list")
local constants = require("vuffers.constants")

describe("utils", function()
  describe("get_file_name_by_level", function()
    it("get filename when level = 1", function()
      local file = "a/b/c/d.test.ts"
      local level = 1

      local res = utils.get_name_by_level(file, level)

      assert.equals("d.test.ts", res)
    end)

    it("get filename when level = 1 and file does not have extension", function()
      local file = "a/b/c/Dockerfile"
      local level = 1

      local res = utils.get_name_by_level(file, level)

      assert.equals("Dockerfile", res)
    end)

    it("get filename when level = 1 and file starts with dot (.)", function()
      local file = "a/b/c/.eslintrc"
      local level = 1

      local res = utils.get_name_by_level(file, level)

      assert.equals(".eslintrc", res)
    end)

    it("get filename when level = 2", function()
      local file = "a/b/c/d.test.ts"
      local level = 2

      local res = utils.get_name_by_level(file, level)

      print(res)
      assert.equals("c/d.test.ts", res)
    end)

    it("get filename when level = 2 and file does not have extention", function()
      local file = "a/b/c/Dockerfile"
      local level = 2

      local res = utils.get_name_by_level(file, level)

      assert.equals("c/Dockerfile", res)
    end)

    it("get filename when level = 2 and file starts with dot (.)", function()
      local file = "a/b/c/.eslintrc"
      local level = 2

      local res = utils.get_name_by_level(file, level)

      assert.equals("c/.eslintrc", res)
    end)

    it("get the original filename when level is greater than the actual filename", function()
      local file = "d.test.ts"
      local level = 2

      local res = utils.get_name_by_level(file, level)

      assert.equals("d.test.ts", res)
    end)
  end)

  describe("get_file_names", function()
    it("returns correct folder depth", function()
      local res = utils.get_formatted_buffers({
        { path = "a/some.ts", buf = 1 },
        { path = "a/b/c/some.ts", buf = 2 },
        { path = "test.json", buf = 3 },
        { path = ".eslintrc", buf = 4 },
        { path = "Dockerfile", buf = 5 },
        { path = "a/b/c/d", buf = 6 },
        { path = "x/b/c/d", buf = 7 },
        { path = "b/c/d", buf = 8 },
      })

      table.sort(res, function(a, b)
        return a.buf < b.buf
      end)

      local extensions = list.map(res, function(item)
        return item._default_folder_depth
      end)

      assert.are.same({ 2, 2, 1, 1, 1, 4, 4, 3 }, extensions)
    end)

    it("returns correct extension", function()
      local res = utils.get_formatted_buffers({
        { path = "a/hi.ts", buf = 1 },
        { path = "a/b/c/d.lua", buf = 2 },
        { path = "test.json", buf = 3 },
        { path = ".eslintrc", buf = 4 },
        { path = "Dockerfile", buf = 5 },
      })

      table.sort(res, function(a, b)
        return a.buf < b.buf
      end)

      local extensions = list.map(res, function(item)
        return item.ext
      end)

      assert.are.same({ "ts", "lua", "json", "eslintrc", "" }, extensions)
    end)

    it("returns correct filenames when additional folder depth is specified", function()
      local res = utils.get_formatted_buffers({
        { path = "a/hi.ts", _additional_folder_depth = 1, buf = 1 },
        { path = "a/b/c/d.lua", _additional_folder_depth = 1, buf = 2 },
        { path = "test.json", _additional_folder_depth = 1, buf = 3 },
        { path = ".eslintrc", _additional_folder_depth = 1, buf = 4 },
        { path = "Dockerfile", _additional_folder_depth = 1, buf = 5 },
      })

      table.sort(res, function(a, b)
        return a.buf < b.buf
      end)

      local extensions = list.map(res, function(item)
        return item.name
      end)

      assert.are.same({ "a/hi", "c/d", "test", ".eslintrc", "Dockerfile" }, extensions)
    end)

    it("returns correct filenames when the filenames of the input is unique", function()
      local res = utils.get_formatted_buffers({
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

      assert.are.same({ "hi", "user", "user.test", "test", "test", ".eslintrc", "Dockerfile" }, filenames)
    end)

    it("returns correct filenames when the filenames of the input has duplicate. case 1", function()
      local res = utils.get_formatted_buffers({
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
      local res = utils.get_formatted_buffers({
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
      local res = utils.get_formatted_buffers({
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
      local res = utils.get_formatted_buffers({
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
      local res = utils.get_formatted_buffers({
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
      ---@type Buffer[]
      local bufs = {
        {
          buf = 4,
          _unique_name = "some.test",
          ext = "ts",
        },
        {
          buf = 6,
          _unique_name = "main",
          ext = "ts",
        },
        {
          buf = 5,
          _unique_name = "some",
          ext = "ts",
        },
      }

      local res =
        utils.sort_buffers(bufs, { type = constants.SORT_TYPE.FILENAME, direction = constants.SORT_DIRECTION.ASC })

      res = list.map(bufs, function(item)
        return item._unique_name
      end)

      assert.are.same(res, { "main", "some", "some.test" })
    end)
  end)
end)
