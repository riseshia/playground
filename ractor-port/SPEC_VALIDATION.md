# Specification Validation Strategy

This document describes how we ensure that the backported `Ractor::Port` implementation complies with the Ruby 3.5 specification.

## Overview

The validation strategy uses **version-agnostic tests** that can run against both:
- **Native Ractor::Port** (Ruby 3.5+)
- **Backported Ractor::Port** (Ruby 3.3/3.4)

This approach allows us to verify that both implementations behave identically under the same test conditions.

## Architecture

### 1. Specification Helper (`test/spec_helper.rb`)

The spec helper automatically detects the Ruby version and loads the appropriate implementation:

```ruby
# Ruby 3.5+ → Use native Ractor::Port
# Ruby 3.3/3.4 → Load backported Ractor::Port

RUBY_VERSION_PARTS = RUBY_VERSION.split('.').map(&:to_i)
if RUBY_MAJOR < 3 || (RUBY_MAJOR == 3 && RUBY_MINOR < 5)
  require_relative '../lib/ractor_port'  # Backport
else
  # Use native Ractor::Port
end
```

All test files use `require_relative 'spec_helper'` instead of directly requiring the backport.

### 2. Specification Compliance Tests (`test/test_spec_compliance.rb`)

This test suite validates compliance with the official Ruby 3.5 Ractor::Port specification:

#### Core Specifications Tested

1. **Creation**: `Ractor::Port.new` creates a new port
2. **Ownership**: Only creator Ractor can receive/close
3. **Universal Sending**: Any Ractor can send to the port
4. **Non-blocking Send**: Send never blocks (infinite queue)
5. **Blocking Receive**: Receive blocks when queue is empty
6. **Closed Port Behavior**:
   - Send to closed port raises `ClosedError`
   - Receive from closed empty port raises `ClosedError`
   - Can still receive queued messages after close
7. **Alias**: `<<` is an alias for `send`
8. **State Query**: `closed?` returns correct state
9. **FIFO Ordering**: Messages maintain order per sender
10. **Shareable Objects**: Integers, symbols, booleans, nil work
11. **Non-shareable Objects**: Arrays, hashes are copied
12. **Method Chaining**: `send` returns `self`

### 3. Implementation Tests (`test/test_ractor_port.rb`)

Additional tests for edge cases and implementation-specific behavior:
- Multiple senders
- Permission errors
- Complex object handling
- Thread blocking behavior

## Running the Tests

### On Ruby 3.3/3.4 (Backport)

```bash
ruby test/test_spec_compliance.rb
# Output: Ruby 3.4.2 detected: Loading backported Ractor::Port
# 15 tests, 1036 assertions, 0 failures

ruby test/test_ractor_port.rb
# 13 tests, 25 assertions, 0 failures
```

### On Ruby 3.5+ (Native)

```bash
ruby test/test_spec_compliance.rb
# Output: Ruby 3.5.0 detected: Using native Ractor::Port
# Same tests should pass with native implementation
```

## Validation Checklist

- [x] All specification compliance tests pass on Ruby 3.3/3.4 with backport
- [ ] All specification compliance tests pass on Ruby 3.5+ with native implementation
- [x] Backport handles ownership correctly (creator-only receive/close)
- [x] Backport handles closed port states correctly
- [x] Backport maintains FIFO ordering
- [x] Backport never blocks on send
- [x] Backport blocks on receive when queue is empty
- [x] Error types match specification (ClosedError, PermissionError)

## How to Add New Specification Tests

When Ruby 3.5 adds new features or clarifies behavior:

1. Add test to `test/test_spec_compliance.rb`
2. Document the specification being tested in comments
3. Run against both implementations
4. Fix backport if behavior differs

Example:

```ruby
# Specification: New feature description
def test_spec_new_feature
  port = Ractor::Port.new
  # Test implementation
  assert_equal expected, actual
end
```

## Known Differences

### Performance

The backport uses polling (0.001s intervals) for blocking receive, while the native implementation likely uses OS-level blocking primitives. This means:

- **Backport**: Higher CPU usage when waiting
- **Native**: More efficient blocking

Both are functionally correct, but performance characteristics differ.

### Error Messages

Error messages may differ slightly between implementations, but error **types** are consistent:
- `Ractor::Port::ClosedError`
- `Ractor::Port::PermissionError`

### Internal Implementation

- **Backport**: Uses an internal manager Ractor
- **Native**: Likely uses C-level primitives

These differences don't affect the external API or behavior.

## Continuous Validation

To maintain specification compliance:

1. **Before releases**: Run all tests on supported Ruby versions
2. **CI Pipeline**: Test against Ruby 3.3, 3.4, and 3.5 (when available)
3. **Documentation**: Keep tests synchronized with official Ruby docs

## References

- [Ruby 3.5 Ractor::Port Specification](https://docs.ruby-lang.org/en/master/ractor_md.html)
- [Ruby Ractor Documentation](https://docs.ruby-lang.org/en/master/Ractor.html)

## Testing Against Ruby 3.5 (When Available)

Once Ruby 3.5 is released with native `Ractor::Port`:

```bash
# Install Ruby 3.5
rbenv install 3.5.0
rbenv shell 3.5.0

# Run validation
ruby test/test_spec_compliance.rb
# Should show: "Ruby 3.5.0 detected: Using native Ractor::Port"
# All tests should pass
```

This validates that the backport accurately replicates native behavior.
