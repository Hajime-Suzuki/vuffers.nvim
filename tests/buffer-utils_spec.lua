local utils = require("vuffers.buffer-utils")
local list = require("utils.list")
describe("utils", function()
  describe("get_file_names", function()
    it("returns correct filenames when the filenames of the input is unique", function()
      local res = utils.get_file_names({
        { path = "a/hi.ts", buf = 1 },
        { path = "b/user.ts", buf = 2 },
        { path = "a/test.ts", buf = 3 },
        { path = "test.json", buf = 4 },
      })

      table.sort(res, function(a, b)
        return a.buf < b.buf
      end)

      res = list.map(res, function(item)
        return item.name
      end)

      assert.are.same(res, { "hi.ts", "user.ts", "test.ts", "test.json" })
    end)

    it("returns correct filenames when the filenames of the input has duplicate. case 1", function()
      local res = utils.get_file_names({
        { path = "hi.ts", buf = 1 },
        { path = "b/user.ts", buf = 2 },
        { path = "a/test.ts", buf = 3 },
        { path = "a/user.ts", buf = 4 },
      })

      table.sort(res, function(a, b)
        return a.buf < b.buf
      end)

      res = list.map(res, function(item)
        return item.name
      end)

      assert.are.same({ "hi.ts", "b/user.ts", "test.ts", "a/user.ts" }, res)
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
        return item.name
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
        return item.name
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
        return item.name
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
        return item.name
      end)

      assert.are.same({ "a/b.ts", "x/a/b.ts", "n/b.ts", "c/b.ts" }, res)
    end)
  end)
end)
