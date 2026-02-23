# RubyのStructをプレーンRubyで再実装したクラス
# class_eval による文字列ベースのメソッド生成でVMネイティブ最適化パスに乗せる
# フラット化された case/when と identity チェックで高速ディスパッチを実現
class RubyStruct
  def self.new(*members, keyword_init: false, &block)
    class_name = nil
    if members.first.is_a?(String) && members.first.match?(/\A[A-Z]/)
      class_name = members.shift
    end

    members = members.map(&:to_sym)
    raise ArgumentError, "wrong number of arguments (given 0, expected 1+)" if members.empty?

    if members.uniq.length != members.length
      dup = members.detect { |m| members.count(m) > 1 }
      raise ArgumentError, "duplicate member: #{dup}"
    end

    members.each do |m|
      unless m.to_s.match?(/\A[a-zA-Z_][a-zA-Z0-9_]*\z/)
        raise NameError, "identifier #{m} needs to be a valid constant name"
      end
    end

    klass = Class.new
    member_count = members.length
    members_literal = "[#{members.map { |m| ":#{m}" }.join(', ')}]"

    # 全メソッド定義を単一文字列にまとめ、一括 class_eval でパース・コンパイルオーバーヘッドを削減
    code = +""

    # クラスメソッド: members, keyword_init?
    code << "def self.members; #{members_literal}; end\n"
    code << "def self.keyword_init?; #{keyword_init}; end\n"

    # クラスメソッド: [] ショートカット
    if keyword_init
      kw_params = members.map { |m| "#{m}: nil" }.join(", ")
      kw_pass = members.map { |m| "#{m}: #{m}" }.join(", ")
      code << "def self.[](#{kw_params}); new(#{kw_pass}); end\n"
    else
      pos_params = members.map { |m| "#{m}=nil" }.join(", ")
      pos_pass = members.join(", ")
      code << "def self.[](#{pos_params}); new(#{pos_pass}); end\n"
    end

    # initialize: 固定引数シグネチャで splat オーバーヘッドを回避
    if keyword_init
      kw_params = members.map { |m| "#{m}: nil" }.join(", ")
      kw_assigns = members.map { |m| "@#{m} = #{m}" }.join("; ")
      code << "def initialize(#{kw_params}); #{kw_assigns}; end\n"
    else
      pos_params = members.map { |m| "#{m}=nil" }.join(", ")
      pos_assigns = members.map { |m| "@#{m} = #{m}" }.join("; ")
      code << "def initialize(#{pos_params}); #{pos_assigns}; end\n"
    end

    # アクセサ: ゲッター・セッター（VM インライン化対象）
    members.each do |m|
      code << "def #{m}; @#{m}; end\n"
      code << "def #{m}=(v); @#{m} = v; end\n"
    end

    # [] メソッド: フラット化 case/when でシンボルアクセスを高速化
    # シンボルをトップレベルに配置し、型チェックのネストを除去
    sym_get = members.map { |m| "when :#{m} then @#{m}" }.join("\n")
    idx_get = members.each_with_index.map { |m, i|
      "when #{i}, #{i - member_count} then @#{m}"
    }.join("\n")
    str_get = members.map { |m| "when '#{m}' then @#{m}" }.join("\n")

    code << <<~RUBY
      def [](key)
        case key
        #{sym_get}
        #{idx_get}
        #{str_get}
        else
          if key.is_a?(Integer)
            raise IndexError, "offset \#{key} too large for struct(size:#{member_count})"
          elsif key.is_a?(Symbol) || key.is_a?(String)
            raise NameError, "no member '\#{key}' in struct"
          else
            raise TypeError, "no implicit conversion of \#{key.class} into Integer"
          end
        end
      end
    RUBY

    # []= メソッド: 同様にフラット化
    sym_set = members.map { |m| "when :#{m} then @#{m} = value" }.join("\n")
    idx_set = members.each_with_index.map { |m, i|
      "when #{i}, #{i - member_count} then @#{m} = value"
    }.join("\n")
    str_set = members.map { |m| "when '#{m}' then @#{m} = value" }.join("\n")

    code << <<~RUBY
      def []=(key, value)
        case key
        #{sym_set}
        #{idx_set}
        #{str_set}
        else
          if key.is_a?(Integer)
            raise IndexError, "offset \#{key} too large for struct(size:#{member_count})"
          elsif key.is_a?(Symbol) || key.is_a?(String)
            raise NameError, "no member '\#{key}' in struct"
          else
            raise TypeError, "no implicit conversion of \#{key.class} into Integer"
          end
        end
      end
    RUBY

    # to_a / values / deconstruct
    to_a_body = "[#{members.map { |m| "@#{m}" }.join(', ')}]"
    code << "def to_a; #{to_a_body}; end\n"
    code << "alias values to_a\n"
    code << "alias deconstruct to_a\n"

    # to_h: ブロック版は中間ハッシュなしで直接 yield してアロケーション削減
    to_h_literal = "{#{members.map { |m| "#{m}: @#{m}" }.join(', ')}}"
    to_h_block_body = members.map { |m|
      "k, v = yield :#{m}, @#{m}; h[k] = v"
    }.join("; ")
    code << <<~RUBY
      def to_h
        if block_given?
          h = {}; #{to_h_block_body}; h
        else
          #{to_h_literal}
        end
      end
    RUBY

    # deconstruct_keys
    dk_cases = members.map { |m|
      "h[:#{m}] = @#{m} if keys.include?(:#{m})"
    }.join("; ")
    code << <<~RUBY
      def deconstruct_keys(keys)
        if keys.nil?
          #{to_h_literal}
        else
          h = {}; #{dk_cases}; h
        end
      end
    RUBY

    # ==: other.class.equal?(self.class) でポインタ比較（is_a? の祖先チェーン走査を回避）
    eq_body = members.empty? ? "true" : members.map { |m| "@#{m} == other.#{m}" }.join(" && ")
    eql_body = members.empty? ? "true" : members.map { |m| "@#{m}.eql?(other.#{m})" }.join(" && ")
    hash_body = "[self.class, #{members.map { |m| "@#{m}" }.join(', ')}].hash"

    code << <<~RUBY
      def ==(other)
        other.class.equal?(self.class) && #{eq_body}
      end
      def eql?(other)
        other.class.equal?(self.class) && #{eql_body}
      end
      def hash; #{hash_body}; end
    RUBY

    # each / each_pair: yield を直接使いブロック呼び出しオーバーヘッドを削減
    each_body = members.map { |m| "yield @#{m}" }.join("; ")
    each_pair_body = members.map { |m| "yield :#{m}, @#{m}" }.join("; ")

    code << <<~RUBY
      def each
        return to_enum(:each) unless block_given?
        #{each_body}
        self
      end
      def each_pair
        return to_enum(:each_pair) unless block_given?
        #{each_pair_body}
        self
      end
    RUBY

    # dig
    code << <<~RUBY
      def dig(key, *rest)
        value = self[key]
        if rest.empty?
          value
        elsif value.respond_to?(:dig)
          value.dig(*rest)
        else
          raise TypeError, "\#{value.class} does not have #dig method"
        end
      end
    RUBY

    # select / filter: to_a を避けてインスタンス変数から直接 yield
    select_body = members.map { |m| "r << @#{m} if yield(@#{m})" }.join("; ")
    code << <<~RUBY
      def select
        return to_enum(:select) unless block_given?
        r = []; #{select_body}; r
      end
      alias filter select
    RUBY

    # size / length
    code << "def size; #{member_count}; end\n"
    code << "alias length size\n"

    # values_at
    code << <<~RUBY
      def values_at(*indices)
        ary = to_a
        indices.flat_map { |idx| ary.values_at(idx) }
      end
    RUBY

    # インスタンスメソッド: members
    code << "def members; #{members_literal}; end\n"

    # inspect / to_s: ローカル変数代入を省略して直接インライン化
    inspect_parts = members.map { |m|
      "#{m}=\#{@#{m}.inspect}"
    }.join(', ')
    code << <<~RUBY
      def inspect
        "#<\#{self.class.name || 'struct'} #{inspect_parts}>"
      end
      alias to_s inspect
    RUBY

    # 一括評価: 全メソッドを一度の class_eval でパース・コンパイル
    klass.class_eval(code, __FILE__, __LINE__ + 1)

    klass.class_eval(&block) if block

    if class_name
      const_set(class_name, klass)
    end

    klass
  end
end
