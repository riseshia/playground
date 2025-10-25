# frozen_string_literal: true

require_relative 'spec_helper'
require 'test/unit'

class TestRactorPort < Test::Unit::TestCase
  def test_basic_send_and_receive
    port = Ractor::Port.new

    Ractor.new(port) do |p|
      p.send(42)
    end

    result = port.receive
    assert_equal 42, result
  end

  def test_send_with_shovel_operator
    port = Ractor::Port.new

    Ractor.new(port) do |p|
      p << "hello"
    end

    result = port.receive
    assert_equal "hello", result
  end

  def test_multiple_messages
    port = Ractor::Port.new

    Ractor.new(port) do |p|
      p << 1
      p << 2
      p << 3
    end

    # Give the ractor time to send all messages
    sleep 0.1

    assert_equal 1, port.receive
    assert_equal 2, port.receive
    assert_equal 3, port.receive
  end

  def test_multiple_senders
    port = Ractor::Port.new

    3.times do |i|
      Ractor.new(port, i) do |p, num|
        p << num
      end
    end

    # Give ractors time to send messages
    sleep 0.1

    results = []
    3.times { results << port.receive }
    assert_equal [0, 1, 2].sort, results.sort
  end

  def test_close_port
    port = Ractor::Port.new
    assert_equal false, port.closed?

    port.close
    assert_equal true, port.closed?
  end

  def test_send_to_closed_port_raises_error
    port = Ractor::Port.new
    port.close

    assert_raise(Ractor::Port::ClosedError) do
      port.send(42)
    end
  end

  def test_receive_from_closed_empty_port_raises_error
    port = Ractor::Port.new
    port.close

    assert_raise(Ractor::Port::ClosedError) do
      port.receive
    end
  end

  def test_receive_from_closed_port_with_messages
    port = Ractor::Port.new

    Ractor.new(port) do |p|
      p << 1
      p << 2
    end

    sleep 0.1
    port.close

    # Should still be able to receive queued messages
    assert_equal 1, port.receive
    assert_equal 2, port.receive

    # Now it should raise an error
    assert_raise(Ractor::Port::ClosedError) do
      port.receive
    end
  end

  def test_only_owner_can_receive
    port = Ractor::Port.new

    r = Ractor.new(port) do |p|
      begin
        p.receive
      rescue Ractor::Port::PermissionError => e
        e.message
      end
    end

    result = r.take
    assert_match(/Only the creator Ractor/, result)
  end

  def test_only_owner_can_close
    port = Ractor::Port.new

    r = Ractor.new(port) do |p|
      begin
        p.close
      rescue Ractor::Port::PermissionError => e
        e.message
      end
    end

    result = r.take
    assert_match(/Only the creator Ractor/, result)
  end

  def test_receive_blocks_until_message_arrives
    port = Ractor::Port.new
    received = nil
    start_time = Time.now

    receiver = Thread.new do
      received = port.receive
    end

    # Let the receiver start waiting
    sleep 0.1

    # Send a message after a delay
    Ractor.new(port) do |p|
      sleep 0.2
      p << "delayed message"
    end

    receiver.join
    elapsed = Time.now - start_time

    assert_equal "delayed message", received
    assert elapsed >= 0.2, "receive should have blocked"
  end

  def test_shareable_objects
    port = Ractor::Port.new

    # Numbers, symbols, true, false, nil are shareable
    Ractor.new(port) do |p|
      p << 42
      p << :symbol
      p << true
      p << false
      p << nil
    end

    sleep 0.1

    assert_equal 42, port.receive
    assert_equal :symbol, port.receive
    assert_equal true, port.receive
    assert_equal false, port.receive
    assert_equal nil, port.receive
  end

  def test_complex_objects
    port = Ractor::Port.new

    # Arrays and hashes will be copied
    Ractor.new(port) do |p|
      p << [1, 2, 3]
      p << {a: 1, b: 2}
      p << "string"
    end

    sleep 0.1

    assert_equal [1, 2, 3], port.receive
    assert_equal({a: 1, b: 2}, port.receive)
    assert_equal "string", port.receive
  end
end
