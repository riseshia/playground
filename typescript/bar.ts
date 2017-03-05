import foo = require('./foo');

export function loadFoo() {
  var _foo: typeof foo = require('./foo');
  // This is lazy loading `foo` and using the original module *only* as a type annotation
  // Now use `_foo` as a variable instead of `foo`.
}
