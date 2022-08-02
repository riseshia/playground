import User from "../src/User"

describe("User", () => {
  describe("find", () => {
    it("returns user", () => {
      expect(User.find(1).name).toEqual("John")
    })
  })
})
