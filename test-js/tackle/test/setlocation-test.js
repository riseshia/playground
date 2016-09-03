describe('setLocation test', function() {
  it('should set the URL into location of window', function() {
    var windowStub = {};
    var url = 'http://example.com';
    setLocation(windowStub, url);

    expect(windowStub.location).to.be.eql(url);
  });
});
