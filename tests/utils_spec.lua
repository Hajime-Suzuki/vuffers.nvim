local utils = require("vuffers.utils")
describe("utils", function()
  describe("get_file_names", function()
    it("returns correct filenames when the filenames of the input is unique", function()
      local res = utils.get_file_names({ "a/hi.ts", "b/user.ts", "a/test.ts", "test.json" })

      assert.equal(#res, 4)
      assert.are.same(res, { "hi.ts", "user.ts", "test.ts", "test.json" })
    end)

    it("returns correct filenames when the filenames of the input has duplicate", function()
      local res = utils.get_file_names({ "hi.ts", "b/user.ts", "a/test.ts", "a/user.ts" })

      assert.equal(#res, 4)
      assert.are.same(res, { "hi.ts", "b/user.ts", "test.ts", "a/user.ts" })
    end)
  end)
end)
