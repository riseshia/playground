# TypeWorld: eval + reflection で構築された「世界」を保持する
# クラス、メソッド、アソシエーション等の型情報レジストリ

module TypeGuess
  # メソッド情報
  MethodInfo = Struct.new(
    :name,            # Symbol
    :owner,           # String (クラス/モジュール名)
    :kind,            # :instance / :singleton
    :parameters,      # [[kind, name], ...] (Method#parameters 形式)
    :source_location,  # [file, line] or nil
    keyword_init: true
  )

  # アソシエーション情報（ランタイムから収集）
  AssociationInfo = Struct.new(
    :macro,        # :has_many / :has_one / :belongs_to
    :name,         # Symbol
    :target_class, # String (推定されるクラス名)
    keyword_init: true
  )

  # クラス/モジュール情報
  ClassInfo = Struct.new(
    :name,              # String
    :superclass,        # String or nil
    :ancestors,         # [String, ...]
    :instance_methods,  # { Symbol => MethodInfo }
    :singleton_methods, # { Symbol => MethodInfo }
    :constants,         # { Symbol => String (型名) }
    :associations,      # { Symbol => AssociationInfo }
    :column_types,      # { String => String } (カラム名 → 型)
    keyword_init: true
  )

  class TypeWorld
    attr_reader :classes

    def initialize
      @classes = {}
    end

    # 指定クラスの情報を取得
    def class_info(name)
      @classes[name.to_s]
    end

    # メソッドの情報を取得（祖先チェーンを辿る）
    def resolve_method(class_name, method_name, kind: :instance)
      info = class_info(class_name)
      return nil unless info

      methods = kind == :instance ? info.instance_methods : info.singleton_methods
      return methods[method_name.to_sym] if methods[method_name.to_sym]

      # 祖先チェーンを辿る
      info.ancestors.each do |ancestor_name|
        ancestor = class_info(ancestor_name)
        next unless ancestor
        methods = kind == :instance ? ancestor.instance_methods : ancestor.singleton_methods
        return methods[method_name.to_sym] if methods[method_name.to_sym]
      end

      nil
    end

    # Ruby のランタイムオブジェクト空間から世界を構築
    def build_from_runtime(target_classes)
      target_classes.each do |klass|
        collect_class_info(klass)
      end
      self
    end

    private

    def collect_class_info(klass)
      name = klass.name
      return unless name # 匿名クラスはスキップ

      instance_methods = {}
      klass.instance_methods(false).each do |mname|
        method_obj = klass.instance_method(mname)
        instance_methods[mname] = MethodInfo.new(
          name: mname,
          owner: name,
          kind: :instance,
          parameters: method_obj.parameters,
          source_location: method_obj.source_location
        )
      end

      singleton_methods = {}
      klass.singleton_methods(false).each do |mname|
        method_obj = klass.method(mname)
        singleton_methods[mname] = MethodInfo.new(
          name: mname,
          owner: name,
          kind: :singleton,
          parameters: method_obj.parameters,
          source_location: method_obj.source_location
        )
      end

      constants = {}
      klass.constants(false).each do |cname|
        val = klass.const_get(cname)
        constants[cname] = val.is_a?(Module) ? val.name : val.class.name
      end

      # アソシエーション情報を収集
      associations = {}
      if klass.respond_to?(:reflect_on_all_associations)
        # ActiveRecord の reflection API
        klass.reflect_on_all_associations.each do |assoc|
          target = assoc.klass.name rescue assoc.class_name rescue estimate_target_class(assoc.name, assoc.macro)
          associations[assoc.name] = AssociationInfo.new(
            macro: assoc.macro,
            name: assoc.name,
            target_class: target
          )
        end
      elsif klass.respond_to?(:associations)
        # MiniActiveRecord 用フォールバック
        klass.associations.each do |assoc|
          target = estimate_target_class(assoc.name, assoc.macro)
          associations[assoc.name] = AssociationInfo.new(
            macro: assoc.macro,
            name: assoc.name,
            target_class: target
          )
        end
      end

      # カラム型情報を収集
      column_types = {}
      if klass.respond_to?(:columns_hash)
        # ActiveRecord の場合: columns_hash を使う
        klass.columns_hash.each do |col_name, col|
          column_types[col_name] = ruby_type_for_column(col.type)
        end
      elsif klass.respond_to?(:columns)
        klass.columns.each do |col|
          column_types[col.name] = ruby_type_for_column(col.type)
        end
      end

      @classes[name] = ClassInfo.new(
        name: name,
        superclass: klass.superclass&.name,
        ancestors: klass.ancestors.map(&:name).compact,
        instance_methods: instance_methods,
        singleton_methods: singleton_methods,
        constants: constants,
        associations: associations,
        column_types: column_types
      )
    end

    # アソシエーション名からターゲットクラス名を推定
    def estimate_target_class(name, macro)
      case macro
      when :has_many
        name.to_s.chomp("s").capitalize
      when :has_one, :belongs_to
        name.to_s.capitalize
      else
        name.to_s.capitalize
      end
    end

    # カラム型 → Ruby型名
    def ruby_type_for_column(col_type)
      case col_type
      when :string, :text then "String"
      when :integer       then "Integer"
      when :float         then "Float"
      when :boolean       then "Boolean"
      when :datetime      then "Time"
      else "Object"
      end
    end
  end
end
