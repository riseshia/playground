# Ractor::Port Backport

A backport implementation of Ruby 3.5's `Ractor::Port` for Ruby 3.3/3.4.

## Overview

`Ractor::Port` is a class that enables message-based communication between Ractors. This backport provides the same functionality for Ruby 3.3/3.4.

## Project Structure

```
ractor-port/
├── lib/
│   └── ractor_port.rb           # Backport implementation
├── test/
│   ├── spec_helper.rb           # Version-agnostic test loader
│   ├── test_ractor_port.rb      # Basic functionality tests (13 tests)
│   └── test_spec_compliance.rb  # Specification compliance tests (15 tests)
├── examples/
│   └── basic_usage.rb           # Usage examples
├── README.md                     # This file
└── SPEC_VALIDATION.md           # Validation strategy documentation
```

## Key Features

- **Infinite-size queue**: Message sending never blocks
- **Ownership-based receiving**: Only the creator Ractor can receive messages from the port
- **Universal sending**: Any Ractor can send messages to the port
- **Blocking receive**: `receive` waits until a message arrives when the queue is empty

## Installation

Copy the file to your project:

```bash
cp lib/ractor_port.rb your_project/lib/
```

Then require it in your code:

```ruby
require_relative 'lib/ractor_port'
```

## Usage

### Basic Usage

```ruby
require_relative 'lib/ractor_port'

# Create a port
port = Ractor::Port.new

# Send a message from another Ractor
Ractor.new(port) do |p|
  p << "Hello from another Ractor!"
end

# Receive a message in the creator Ractor
message = port.receive
puts message  # => "Hello from another Ractor!"
```

### Multiple Messages

```ruby
port = Ractor::Port.new

Ractor.new(port) do |p|
  5.times do |i|
    p.send("Message #{i + 1}")
  end
end

5.times do
  puts port.receive
end
```

### Multiple Senders

```ruby
port = Ractor::Port.new

# Create 3 worker Ractors
3.times do |i|
  Ractor.new(port, i) do |p, worker_id|
    p << "Worker #{worker_id} says hello"
  end
end

# Receive all messages
3.times do
  puts port.receive
end
```

### Closing a Port

```ruby
port = Ractor::Port.new

# Send messages
Ractor.new(port) do |p|
  p << "Message 1"
  p << "Message 2"
end

# Receive messages
puts port.receive  # => "Message 1"
puts port.receive  # => "Message 2"

# Close the port
port.close

# Attempting to send to a closed port
port.send("fail")  # => Ractor::Port::ClosedError
```

### Producer-Consumer Pattern

```ruby
port = Ractor::Port.new

# Producer
producer = Ractor.new(port) do |p|
  10.times do |i|
    p << i * i  # Send squares
  end
end

# Consumer (main Ractor)
10.times do
  value = port.receive
  puts "Processing: #{value}"
end

producer.take
```

## API

### `Ractor::Port.new`

Creates a new port. Only the creator Ractor can receive from this port.

### `port.send(obj)` / `port << obj`

Sends a message to the port. This operation never blocks.

- **Parameters**: `obj` - The object to send
- **Returns**: `self`
- **Raises**: `Ractor::Port::ClosedError` - When the port is closed

### `port.receive`

Receives a message from the port. Blocks until a message arrives if the queue is empty.

- **Returns**: The received object
- **Raises**:
  - `Ractor::Port::PermissionError` - When called from a non-creator Ractor
  - `Ractor::Port::ClosedError` - When the port is closed and the queue is empty

### `port.close`

Closes the port. Only the creator Ractor can call this method.

- **Returns**: `nil`
- **Raises**: `Ractor::Port::PermissionError` - When called from a non-creator Ractor

### `port.closed?`

Checks if the port is closed.

- **Returns**: `Boolean`

## Testing

### Basic Tests

To run the basic functionality tests:

```bash
ruby test/test_ractor_port.rb
# 13 tests, 25 assertions
```

### Specification Compliance Tests

To verify compliance with Ruby 3.5's Ractor::Port specification:

```bash
ruby test/test_spec_compliance.rb
# 15 tests, 1000+ assertions
```

These tests validate that the backport behaves identically to the native implementation across all documented behaviors.

### Validation Strategy

The test suite uses a version-agnostic approach that automatically detects the Ruby version:
- **Ruby 3.5+**: Tests run against native `Ractor::Port`
- **Ruby 3.3/3.4**: Tests run against the backported implementation

This ensures the backport maintains specification compliance. For details, see [SPEC_VALIDATION.md](SPEC_VALIDATION.md).

## Examples

See `examples/basic_usage.rb` for more examples:

```bash
ruby examples/basic_usage.rb
```

## Implementation Details

This backport is implemented using Ruby 3.3/3.4's existing Ractor features:

- Each port creates an internal manager Ractor
- All state (queue, closed status) is managed inside the manager Ractor
- No unshareable objects like Mutex or ConditionVariable are used
- All communication occurs through Ractor's `send`/`receive` mechanisms

## Limitations

- Ractor is an experimental feature in Ruby 3.0+
- Performance may be lower than Ruby 3.5's native implementation
- Uses polling (0.001 second intervals) when `receive` is waiting

## License

This code is freely available for use.

## References

- [Ruby 3.5 Ractor::Port Documentation](https://docs.ruby-lang.org/en/master/ractor_md.html)
- [Ruby Ractor Guide](https://docs.ruby-lang.org/en/master/doc/ractor_md.html)
