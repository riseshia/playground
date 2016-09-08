const Stockfetch = function () {
  this.readTickersFile = (filename, onError) => {
    onError(`Error reading file: ${filename}`)
  }
}

module.exports = Stockfetch
