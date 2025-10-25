# frozen_string_literal: true

require_relative 'spec_helper'
require 'test/unit'

# Specification Compliance Tests
# These tests verify that the implementation (backport or native)
# complies with the Ractor::Port specification from Ruby 3.5
#
# Based on: https://docs.ruby-lang.org/en/master/ractor_md.html
class TestSpecCompliance < Test::Unit::TestCase
  def setup
    @impl_info = port_implementation_info
  end

  # Specification: Ractor::Port can be created with Ractor::Port.new
  def test_spec_port_creation
    port = Ractor::Port.new
    assert_instance_of Ractor::Port, port
  end

  # Specification: Only the creator Ractor can receive from the port
  def test_spec_only_creator_can_receive
    port = Ractor::Port.new

    r = Ractor.new(port) do |p|
      begin
        p.receive
        :should_not_reach_here
      rescue => e
        e.class.name
      end
    end

    result = r.take
    # The error class name might differ between implementations
    # but it should indicate a permission/access error
    assert_match(/Permission|Access|Error/, result,
                 "Non-creator should not be able to receive")
  end

  # Specification: Any Ractor can send to the port
  def test_spec_any_ractor_can_send
    port = Ractor::Port.new

    # Multiple ractors sending
    ractors = 5.times.map do |i|
      Ractor.new(port, i) do |p, id|
        p.send(id)
      end
    end

    # Collect all messages
    results = []
    5.times { results << port.receive }

    # All ractors should have completed without errors
    ractors.each(&:take)

    assert_equal [0, 1, 2, 3, 4].sort, results.sort
  end

  # Specification: send (or <<) never blocks (infinite queue)
  def test_spec_send_never_blocks
    port = Ractor::Port.new

    # Send many messages without receiving
    start_time = Time.now
    1000.times { |i| port.send(i) }
    elapsed = Time.now - start_time

    # Should complete very quickly (< 1 second even for 1000 messages)
    assert elapsed < 1.0, "Sending should not block"

    # Verify all messages are queued
    1000.times { |i| assert_equal i, port.receive }
  end

  # Specification: receive blocks when queue is empty
  def test_spec_receive_blocks_when_empty
    port = Ractor::Port.new
    received = nil
    thread = Thread.new { received = port.receive }

    # Give thread time to start waiting
    sleep 0.05

    # Thread should still be alive (blocked)
    assert thread.alive?, "receive should block when queue is empty"

    # Send a message to unblock
    Ractor.new(port) { |p| p.send(42) }

    thread.join(1.0)
    assert_equal 42, received
  end

  # Specification: Closed port raises error on send
  def test_spec_closed_port_raises_on_send
    port = Ractor::Port.new
    port.close

    assert_raise(Ractor::Port::ClosedError) do
      port.send(1)
    end
  end

  # Specification: Closed empty port raises error on receive
  def test_spec_closed_empty_port_raises_on_receive
    port = Ractor::Port.new
    port.close

    assert_raise(Ractor::Port::ClosedError) do
      port.receive
    end
  end

  # Specification: Closed port with queued messages allows receiving them
  def test_spec_closed_port_can_receive_queued_messages
    port = Ractor::Port.new

    # Queue some messages
    Ractor.new(port) do |p|
      3.times { |i| p.send(i) }
    end

    sleep 0.05

    # Close the port
    port.close

    # Should still be able to receive queued messages
    assert_equal 0, port.receive
    assert_equal 1, port.receive
    assert_equal 2, port.receive

    # Now it should raise
    assert_raise(Ractor::Port::ClosedError) do
      port.receive
    end
  end

  # Specification: << is an alias for send
  def test_spec_shovel_operator_is_send_alias
    port = Ractor::Port.new

    # Test that << works like send
    Ractor.new(port) do |p|
      p << "via shovel"
      p.send("via send")
    end

    sleep 0.05

    assert_equal "via shovel", port.receive
    assert_equal "via send", port.receive
  end

  # Specification: closed? returns the closed state
  def test_spec_closed_query_method
    port = Ractor::Port.new
    assert_equal false, port.closed?

    port.close
    assert_equal true, port.closed?
  end

  # Specification: Only creator can close the port
  def test_spec_only_creator_can_close
    port = Ractor::Port.new

    r = Ractor.new(port) do |p|
      begin
        p.close
        :should_not_reach_here
      rescue => e
        e.class.name
      end
    end

    result = r.take
    assert_match(/Permission|Access|Error/, result,
                 "Non-creator should not be able to close")
  end

  # Specification: Messages maintain FIFO order from same sender
  def test_spec_fifo_order_per_sender
    port = Ractor::Port.new

    Ractor.new(port) do |p|
      10.times { |i| p.send(i) }
    end

    sleep 0.05

    # Messages from same sender should be in order
    10.times do |i|
      assert_equal i, port.receive
    end
  end

  # Specification: Shareable objects can be sent
  def test_spec_shareable_objects
    port = Ractor::Port.new

    Ractor.new(port) do |p|
      # Integers, symbols, true, false, nil are shareable
      p.send(42)
      p.send(:symbol)
      p.send(true)
      p.send(false)
      p.send(nil)
    end

    sleep 0.05

    assert_equal 42, port.receive
    assert_equal :symbol, port.receive
    assert_equal true, port.receive
    assert_equal false, port.receive
    assert_equal nil, port.receive
  end

  # Specification: Non-shareable objects are copied
  def test_spec_non_shareable_objects_copied
    port = Ractor::Port.new

    original_array = [1, 2, 3]
    Ractor.new(port, original_array.dup) do |p, arr|
      p.send(arr)
    end

    sleep 0.05

    received = port.receive
    assert_equal [1, 2, 3], received
    # Should be a different object (copied)
    assert_not_equal original_array.object_id, received.object_id
  end

  # Specification: send returns self for chaining
  def test_spec_send_returns_self
    port = Ractor::Port.new

    result = port.send(1)
    assert_same port, result

    result2 = port << 2
    assert_same port, result2
  end

  # Print implementation info after tests
  def teardown
    # Only print once
    if self.class.count == 1
      puts "\n--- Testing with: #{@impl_info} ---"
    end
  end

  def self.count
    @count ||= 0
    @count += 1
  end
end
