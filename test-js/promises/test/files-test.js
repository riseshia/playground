var expect = require('chai').expect;
require('chai').use(require('chai-as-promised'));
var linesCount = require('../src/files');

describe('test promises', function() {
  it('should return correct lines count for a valid file', function(done) {
    var checkCount = function(count) {
      expect(count).to.be.eql(15);
      done();
    };
    
    linesCount('src/files.js')
      .then(checkCount);
  });

  // always true
  it('should return correct lines count - using return', function() {
    var callback = function(count) {
      expect(count).to.be.eql(15);
    };
    
    return linesCount('src/files.js')
             .then(callback);
  });

  it('should return correct lines count - using eventually', function() {
    return expect(linesCount('src/files.js')).to.eventually.eql(15);
  });

  it('should return correct lines count - using no return', function(done) {
    expect(linesCount('src/files.js')).to.eventually.eql(15).notify(done);
  });

  it('should report error for an invalid file name', function(done) {
    return expect(linesCount('src/flies.js')).to.be.rejected.notify(done);
  });

  it('should report error for an invalid file name - using with',
    function(done) {
    expect(linesCount('src/flies.js'))
      .to.be.rejectedWith('unable to open file src/flies.js').notify(done);
  });
});
