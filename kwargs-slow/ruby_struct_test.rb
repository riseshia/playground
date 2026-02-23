require "minitest/autorun"
require_relative "ruby_struct"

class RubyStructNewTest < Minitest::Test
  # クラス生成の基本テスト
  def test_creates_new_class
    klass = RubyStruct.new(:name, :age)
    assert_kind_of Class, klass
  end

  def test_members_returns_attribute_names
    klass = RubyStruct.new(:name, :age)
    assert_equal [:name, :age], klass.members
  end

  def test_members_is_frozen_copy
    klass = RubyStruct.new(:name)
    m1 = klass.members
    m2 = klass.members
    refute_same m1, m2
  end

  def test_string_members_converted_to_symbols
    klass = RubyStruct.new("name", "age")
    assert_equal [:name, :age], klass.members
  end

  def test_first_string_arg_sets_constant_name
    klass = RubyStruct.new("TestPoint", :x, :y)
    assert_equal [:x, :y], klass.members
    assert_equal klass, RubyStruct::TestPoint
  end

  def test_no_members_raises_error
    assert_raises(ArgumentError) { RubyStruct.new }
  end

  def test_duplicate_members_raises_error
    assert_raises(ArgumentError) { RubyStruct.new(:a, :b, :a) }
  end

  def test_block_adds_methods
    klass = RubyStruct.new(:x, :y) do
      def sum
        x + y
      end
    end
    obj = klass.new(3, 7)
    assert_equal 10, obj.sum
  end

  def test_bracket_shortcut_creates_instance
    klass = RubyStruct.new(:a, :b)
    obj = klass[1, 2]
    assert_equal 1, obj.a
    assert_equal 2, obj.b
  end
end

class RubyStructInitializeTest < Minitest::Test
  # 位置引数コンストラクタのテスト
  def setup
    @klass = RubyStruct.new(:name, :age)
  end

  def test_positional_args
    obj = @klass.new("Alice", 30)
    assert_equal "Alice", obj.name
    assert_equal 30, obj.age
  end

  def test_missing_args_default_to_nil
    obj = @klass.new("Bob")
    assert_equal "Bob", obj.name
    assert_nil obj.age
  end

  def test_no_args_all_nil
    obj = @klass.new
    assert_nil obj.name
    assert_nil obj.age
  end

  def test_too_many_args_raises_error
    assert_raises(ArgumentError) { @klass.new("a", 1, "extra") }
  end
end

class RubyStructKeywordInitTest < Minitest::Test
  # keyword_init: true のテスト
  def setup
    @klass = RubyStruct.new(:x, :y, keyword_init: true)
  end

  def test_keyword_init
    obj = @klass.new(x: 10, y: 20)
    assert_equal 10, obj.x
    assert_equal 20, obj.y
  end

  def test_keyword_init_partial
    obj = @klass.new(x: 5)
    assert_equal 5, obj.x
    assert_nil obj.y
  end

  def test_keyword_init_no_args
    obj = @klass.new
    assert_nil obj.x
    assert_nil obj.y
  end

  def test_keyword_init_unknown_key_raises
    assert_raises(ArgumentError) { @klass.new(x: 1, z: 99) }
  end

  def test_keyword_init_query
    assert_equal true, @klass.keyword_init?
    normal = RubyStruct.new(:a)
    assert_equal false, normal.keyword_init?
  end
end

class RubyStructAccessorTest < Minitest::Test
  # ゲッター・セッターのテスト
  def setup
    @klass = RubyStruct.new(:name, :age)
    @obj = @klass.new("Alice", 30)
  end

  def test_getter
    assert_equal "Alice", @obj.name
    assert_equal 30, @obj.age
  end

  def test_setter
    @obj.name = "Bob"
    @obj.age = 25
    assert_equal "Bob", @obj.name
    assert_equal 25, @obj.age
  end
end

class RubyStructBracketAccessTest < Minitest::Test
  # [] / []= のテスト
  def setup
    @klass = RubyStruct.new(:a, :b, :c)
    @obj = @klass.new(1, 2, 3)
  end

  def test_access_by_index
    assert_equal 1, @obj[0]
    assert_equal 2, @obj[1]
    assert_equal 3, @obj[2]
  end

  def test_access_by_negative_index
    assert_equal 3, @obj[-1]
    assert_equal 2, @obj[-2]
    assert_equal 1, @obj[-3]
  end

  def test_access_by_symbol
    assert_equal 1, @obj[:a]
    assert_equal 2, @obj[:b]
  end

  def test_access_by_string
    assert_equal 3, @obj["c"]
  end

  def test_index_out_of_range_raises
    assert_raises(IndexError) { @obj[3] }
    assert_raises(IndexError) { @obj[-4] }
  end

  def test_unknown_symbol_raises
    assert_raises(NameError) { @obj[:z] }
  end

  def test_assign_by_index
    @obj[0] = 99
    assert_equal 99, @obj.a
  end

  def test_assign_by_symbol
    @obj[:b] = 88
    assert_equal 88, @obj.b
  end

  def test_assign_by_string
    @obj["c"] = 77
    assert_equal 77, @obj.c
  end

  def test_assign_index_out_of_range_raises
    assert_raises(IndexError) { @obj[3] = 0 }
  end

  def test_assign_unknown_symbol_raises
    assert_raises(NameError) { @obj[:z] = 0 }
  end
end

class RubyStructConversionTest < Minitest::Test
  # to_a / to_h のテスト
  def setup
    @klass = RubyStruct.new(:x, :y)
    @obj = @klass.new(10, 20)
  end

  def test_to_a
    assert_equal [10, 20], @obj.to_a
  end

  def test_values_alias
    assert_equal @obj.to_a, @obj.values
  end

  def test_to_h
    assert_equal({ x: 10, y: 20 }, @obj.to_h)
  end

  def test_to_h_with_block
    result = @obj.to_h { |k, v| [k.to_s, v * 2] }
    assert_equal({ "x" => 20, "y" => 40 }, result)
  end

  def test_deconstruct
    assert_equal [10, 20], @obj.deconstruct
  end

  def test_deconstruct_keys_all
    assert_equal({ x: 10, y: 20 }, @obj.deconstruct_keys(nil))
  end

  def test_deconstruct_keys_subset
    assert_equal({ x: 10 }, @obj.deconstruct_keys([:x]))
  end

  def test_deconstruct_keys_ignores_unknown
    assert_equal({}, @obj.deconstruct_keys([:z]))
  end
end

class RubyStructEqualityTest < Minitest::Test
  # 等値比較のテスト
  def setup
    @klass = RubyStruct.new(:a, :b)
  end

  def test_equal_values
    obj1 = @klass.new(1, 2)
    obj2 = @klass.new(1, 2)
    assert_equal obj1, obj2
  end

  def test_different_values
    obj1 = @klass.new(1, 2)
    obj2 = @klass.new(1, 3)
    refute_equal obj1, obj2
  end

  def test_different_class_not_equal
    klass2 = RubyStruct.new(:a, :b)
    obj1 = @klass.new(1, 2)
    obj2 = klass2.new(1, 2)
    refute_equal obj1, obj2
  end

  def test_not_equal_to_non_struct
    obj = @klass.new(1, 2)
    refute_equal obj, [1, 2]
  end

  def test_eql
    obj1 = @klass.new(1, 2)
    obj2 = @klass.new(1, 2)
    assert obj1.eql?(obj2)
  end

  def test_hash_equal_for_equal_objects
    obj1 = @klass.new(1, 2)
    obj2 = @klass.new(1, 2)
    assert_equal obj1.hash, obj2.hash
  end

  def test_can_be_used_as_hash_key
    obj1 = @klass.new(1, 2)
    obj2 = @klass.new(1, 2)
    h = { obj1 => "found" }
    assert_equal "found", h[obj2]
  end
end

class RubyStructIterationTest < Minitest::Test
  # イテレーションのテスト
  def setup
    @klass = RubyStruct.new(:a, :b, :c)
    @obj = @klass.new(10, 20, 30)
  end

  def test_each
    collected = []
    @obj.each { |v| collected << v }
    assert_equal [10, 20, 30], collected
  end

  def test_each_returns_self
    result = @obj.each { |_| }
    assert_same @obj, result
  end

  def test_each_without_block_returns_enumerator
    assert_kind_of Enumerator, @obj.each
  end

  def test_each_pair
    collected = []
    @obj.each_pair { |k, v| collected << [k, v] }
    assert_equal [[:a, 10], [:b, 20], [:c, 30]], collected
  end

  def test_each_pair_returns_self
    result = @obj.each_pair { |_, _| }
    assert_same @obj, result
  end

  def test_each_pair_without_block_returns_enumerator
    assert_kind_of Enumerator, @obj.each_pair
  end
end

class RubyStructDigTest < Minitest::Test
  # dig のテスト
  def test_dig_simple
    klass = RubyStruct.new(:a, :b)
    obj = klass.new(1, 2)
    assert_equal 1, obj.dig(:a)
  end

  def test_dig_nested_struct
    inner = RubyStruct.new(:val)
    outer = RubyStruct.new(:child)
    obj = outer.new(inner.new(42))
    assert_equal 42, obj.dig(:child, :val)
  end

  def test_dig_nested_hash
    klass = RubyStruct.new(:data)
    obj = klass.new({ key: "value" })
    assert_equal "value", obj.dig(:data, :key)
  end

  def test_dig_nil_intermediate
    klass = RubyStruct.new(:a)
    obj = klass.new(nil)
    assert_nil obj.dig(:a)
  end
end

class RubyStructSelectTest < Minitest::Test
  # select / filter のテスト
  def setup
    @klass = RubyStruct.new(:a, :b, :c)
    @obj = @klass.new(1, 20, 3)
  end

  def test_select
    result = @obj.select { |v| v > 5 }
    assert_equal [20], result
  end

  def test_filter_alias
    result = @obj.filter { |v| v < 10 }
    assert_equal [1, 3], result
  end

  def test_select_without_block_returns_enumerator
    assert_kind_of Enumerator, @obj.select
  end
end

class RubyStructSizeTest < Minitest::Test
  # size / length のテスト
  def test_size
    klass = RubyStruct.new(:a, :b, :c)
    obj = klass.new
    assert_equal 3, obj.size
  end

  def test_length_alias
    klass = RubyStruct.new(:x)
    obj = klass.new(1)
    assert_equal 1, obj.length
  end
end

class RubyStructValuesAtTest < Minitest::Test
  # values_at のテスト
  def setup
    @klass = RubyStruct.new(:a, :b, :c, :d)
    @obj = @klass.new(10, 20, 30, 40)
  end

  def test_values_at_indices
    assert_equal [10, 30], @obj.values_at(0, 2)
  end

  def test_values_at_negative_index
    assert_equal [40, 10], @obj.values_at(-1, 0)
  end

  def test_values_at_range
    assert_equal [20, 30], @obj.values_at(1..2)
  end
end

class RubyStructMembersInstanceTest < Minitest::Test
  # インスタンスの members メソッドのテスト
  def test_instance_members
    klass = RubyStruct.new(:x, :y)
    obj = klass.new(1, 2)
    assert_equal [:x, :y], obj.members
  end
end

class RubyStructInspectTest < Minitest::Test
  # inspect / to_s のテスト
  def test_inspect_contains_values
    klass = RubyStruct.new(:name, :age)
    obj = klass.new("Alice", 30)
    result = obj.inspect
    assert_includes result, 'name="Alice"'
    assert_includes result, "age=30"
  end

  def test_to_s_same_as_inspect
    klass = RubyStruct.new(:a)
    obj = klass.new(1)
    assert_equal obj.inspect, obj.to_s
  end
end
