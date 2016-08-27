const { expect } = require('chai')
const Util = require('../src/util')

describe('util tests', function() {
  it('should pass this canary test', function() {
    expect(true).to.eql(true)
  })

  let util
  beforeEach(function() {
    util = new Util()
  })

  it('should pass if f2c returns 0C for 32F', function() {
    const fahrenheit = 32
    const celsius = util.f2c(fahrenheit)
    expect(celsius).to.eql(0)
  })

  it('should pass if f2c returns 10C for 50F', function() {
    const fahrenheit = 50
    const celsius = util.f2c(fahrenheit)
    expect(celsius).to.eql(10)
  })
})
