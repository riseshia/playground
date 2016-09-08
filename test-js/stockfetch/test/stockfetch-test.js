const { expect } = require("chai")
const sinon = require("sinon")
const fs = require("fs")
const Stockfetch = require("../src/stockfetch")

describe("Stockfetch tests", () => {
  let stockfetch, sandbox

  beforeEach(() => {
    stockfetch = new Stockfetch()
    sandbox = sinon.sandbox.create()
  })

  afterEach(() => {
    sandbox.restore()
  })

  it("should pass this canary test", () => {
    expect(true).to.be.true
  })

  it("read should invoke error handler for invalid file", done => {
    const onError = err => {
      expect(err).to.be.eql("Error reading file: InvalidFile")
      done()
    }
    sandbox.stub(fs, "readFile", (fileName, callback) => {
      callback(new Error("failed"))
    })
    stockfetch.readTickersFile("InvalidFile", onError)
  })
})
