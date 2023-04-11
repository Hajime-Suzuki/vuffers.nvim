local utils = require("vuffers.buffer-utils")
describe("utils", function()
  describe("get_file_names", function()
    it("returns correct filenames when the filenames of the input is unique", function()
      local res = utils.get_file_names({ "a/hi.ts", "b/user.ts", "a/test.ts", "test.json" })

      assert.equal(#res, 4)
      assert.are.same(res, { "hi.ts", "user.ts", "test.ts", "test.json" })
    end)

    it("returns correct filenames when the filenames of the input has duplicate", function()
      local res = utils.get_file_names({ "hi.ts", "b/user.ts", "a/test.ts", "a/user.ts" })

      assert.are.same({ "hi.ts", "b/user.ts", "test.ts", "a/user.ts" }, res)
    end)

    it("returns correct filenames when the filenames of the input has duplicate", function()
      local res = utils.get_file_names({ "b/user.ts", "user.ts" })

      assert.are.same({ "b/user.ts", "user.ts" }, res)
    end)

    it("returns correct filenames when the filenames of the input has duplicate", function()
      local res = utils.get_file_names({ "user.ts", "b/user.ts" })

      assert.are.same({ "user.ts", "b/user.ts" }, res)
    end)

    it("returns correct filenames when the filenames of the input has multiple duplicate", function()
      local res = utils.get_file_names({ "a/user.ts", "b/user.ts", "x/a/test.ts" })

      assert.are.same({ "a/user.ts", "b/user.ts", "x/a/test.ts" }, res)
    end)

    it("returns correct filenames when the filenames of the input has multiple duplicate", function()
      local res = utils.get_file_names({ "a/b.ts", "x/a/b.ts", "m/n/b.ts", "c/b.ts" })

      assert.are.same({ "a/b.ts", "x/a/b.ts", "n/b.ts", "c/b.ts" }, res)
    end)
  end)
end)
