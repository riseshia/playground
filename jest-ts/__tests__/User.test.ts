import User from "@/User"
import SomeClient from "@/SomeClient"

jest.mock("@/SomeClient");

describe("User", () => {
  describe("find", () => {
    it("returns user", () => {
      expect(User.find(1).name).toEqual("John11")
    })
  })
})
