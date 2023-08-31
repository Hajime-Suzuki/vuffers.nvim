---@diagnostic disable: undefined-global
local utils = require("vuffers.buffers.buffer-utils")
local str = require("utils.string")
local list = require("utils.list")
local constants = require("vuffers.constants")
local pinned = require("vuffers.buffers.pinned-buffers")

local function shuffle(tbl)
  local output = vim.deepcopy(tbl)

  for i = #output, 2, -1 do
    local j = math.random(i)
    output[i], output[j] = output[j], output[i]
  end

  return output
end

describe("utils", function()
  describe("get_file_name_by_level", function()
    it("get filename when level = 1", function()
      local file = str.split("a/b/c/d.test.ts", "/")
      local level = 1

      local res = utils._get_name_by_level(file, level)

      assert.equals("d.test.ts", res)
    end)

    it("get filename when level = 1 and file does not have extension", function()
      local file = str.split("a/b/c/Dockerfile", "/")
      local level = 1

      local res = utils._get_name_by_level(file, level)

      assert.equals("Dockerfile", res)
    end)

    it("get filename when level = 1 and file starts with dot (.)", function()
      local file = str.split("a/b/c/.eslintrc", "/")
      local level = 1

      local res = utils._get_name_by_level(file, level)

      assert.equals(".eslintrc", res)
    end)

    it("get filename when level = 2", function()
      local file = str.split("a/b/c/d.test.ts", "/")
      local level = 2

      local res = utils._get_name_by_level(file, level)

      print(res)
      assert.equals("c/d.test.ts", res)
    end)

    it("get filename when level = 2 and file does not have extention", function()
      local file = str.split("a/b/c/Dockerfile", "/")
      local level = 2

      local res = utils._get_name_by_level(file, level)

      assert.equals("c/Dockerfile", res)
    end)

    it("get filename when level = 2 and file starts with dot (.)", function()
      local file = str.split("a/b/c/.eslintrc", "/")
      local level = 2

      local res = utils._get_name_by_level(file, level)

      assert.equals("c/.eslintrc", res)
    end)

    it("get the original filename when level is greater than the actual filename", function()
      local file = str.split("d.test.ts", "/")
      local level = 2

      local res = utils._get_name_by_level(file, level)

      assert.equals("d.test.ts", res)
    end)
  end)

  describe("get_formatted_buffers", function()
    describe("folder depth", function()
      it("returns correct default folder depth", function()
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
    end)

    describe("extension", function()
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
    end)

    describe("display name", function()
      it("returns correct filenames when additional folder depth is specified", function()
        local res = utils.get_formatted_buffers({
          { path = "a/hi.ts", _additional_folder_depth = 100, buf = 1 },
          { path = "a/test.ts", _additional_folder_depth = -100, buf = 2 },
          { path = "a/b/c/d.lua", _additional_folder_depth = 3, buf = 3 },
          { path = "test.json", _additional_folder_depth = 1, buf = 4 },
          { path = ".eslintrc", _additional_folder_depth = 1, buf = 5 },
          { path = "Dockerfile", _additional_folder_depth = 1, buf = 6 },
        })

        table.sort(res, function(a, b)
          return a.buf < b.buf
        end)

        local extensions = list.map(res, function(item)
          return item.name
        end)

        assert.are.same({ "a/hi", "test", "a/b/c/d", "test", ".eslintrc", "Dockerfile" }, extensions)
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
  end)

  describe("sort_buffers", function()
    it("should sort by unique_name", function()
      ---@type Buffer[]
      local bufs = {
        {
          buf = 6,
          _filename = "main",
          _unique_name = "c/d/main",
          ext = "ts",
        },
        {
          buf = 5,
          _filename = "some",
          _unique_name = "z/some",
          ext = "ts",
        },
        {
          buf = 4,
          _filename = "some.test",
          _unique_name = "a/some.test",
          ext = "ts",
        },
      }

      local res =
        utils.sort_buffers(bufs, { type = constants.SORT_TYPE.UNIQUE_NAME, direction = constants.SORT_DIRECTION.ASC })

      res = list.map(bufs, function(item)
        return item._unique_name
      end)

      assert.are.same(res, { "a/some.test", "c/d/main", "z/some" })
    end)

    it("should sort by filename", function()
      ---@type Buffer[]
      local bufs = {
        {
          buf = 6,
          _filename = "main",
          _unique_name = "c/d/main",
          ext = "ts",
        },
        {
          buf = 5,
          _filename = "some",
          _unique_name = "z/some",
          ext = "ts",
        },
        {
          buf = 4,
          _filename = "some.test",
          _unique_name = "a/some.test",
          ext = "ts",
        },
      }

      local res =
        utils.sort_buffers(bufs, { type = constants.SORT_TYPE.FILENAME, direction = constants.SORT_DIRECTION.ASC })

      res = list.map(bufs, function(item)
        return item._filename
      end)

      assert.are.same(res, { "main", "some", "some.test" })
    end)

    it("should sort pinned buffers first", function()
      pinned.__set_pinned_bufnrs({ "z/some", "c/d/main" })
      ---@type Buffer[]
      local bufs = {
        {
          buf = 4,
          _filename = "some.test",
          _unique_name = "a/some.test",
          ext = "ts",
          is_pinned = false,
        },
        {
          buf = 6,
          _filename = "some",
          _unique_name = "c/d/main",
          ext = "ts",
          is_pinned = true,
          path = "c/d/main",
        },
        {
          buf = 2,
          _filename = "foo",
          _unique_name = "b/foo.ts",
          ext = "ts",
          is_pinned = false,
        },
        {
          buf = 3,
          _filename = "another",
          _unique_name = "a/another.ts",
          ext = "ts",
          is_pinned = false,
        },
        {
          buf = 5,
          _filename = "main",
          _unique_name = "z/some",
          ext = "ts",
          is_pinned = true,
          path = "z/some",
        },
      }

      local failed = false
      for _ = 1, 20 do
        local data = shuffle(bufs)
        local input = vim.deepcopy(data)

        local res =
          utils.sort_buffers(data, { type = constants.SORT_TYPE.FILENAME, direction = constants.SORT_DIRECTION.ASC })

        res = list.map(res, function(item)
          return item.buf
        end)

        local ok, err = pcall(function()
          assert.are.same({ 5, 6, 3, 2, 4 }, res)
        end)

        if not ok then
          failed = true
          print(err)
          print("input: ", vim.inspect(input))
          break
        end
      end

      if failed then
        assert.fail("failed")
      end
    end)
  end)
end)
