mixin = {
  applyName: function(config) {
    return Factory(config, this.getName());
  },
  applyNumber: function(config) {
    return Factory(config, this.getNumber());
  },
}
