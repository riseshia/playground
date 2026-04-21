# ruby-type-guess 아키텍처 설계

## 목표

Ruby / Rails 코드의 타입 정보를 **정적 어노테이션 없이** 실시간에 가깝게 에디터에 제공한다.

- Sorbet / Steep 처럼 RBS · RBI 를 작성하지 않는다
- `has_many`, `belongs_to`, 동적 속성 등 **Rails 의 메타프로그래밍 산출물** 을 타입으로 취급한다
- 메서드 본문 안의 로컬 변수 타입까지 제공한다
- 코드 작성 중에도 실용적인 속도로 정보가 갱신된다

## 핵심 원칙

### 1. World 가 유일한 사실의 원천 (Single Source of Truth)

프로젝트 전체를 격리된 메모리 공간에 eval 해서 만든 **World** 가 모든 타입 정보를 담는다.

- 클래스 · 조상 체인 · 메서드 시그니처 (reflection)
- `has_many` · `belongs_to` · 스키마 (Rails introspection)
- **각 메서드의 반환 타입** (빌드 타임에 미리 계산)
- **각 메서드의 로컬 변수 타입 맵** (빌드 타임에 미리 계산)

에디터의 호버 요청은 World 에 좌표를 던져 lookup 하는 것으로 끝난다. 런타임에 AST 를 해석하지 않는다.

### 2. AST 순회는 "빌드 도구" 이지 "추론 엔진" 이 아니다

AST 는 World 를 채우기 위한 수단일 뿐이다. 빌드 중에 메서드 본문을 훑으면서도 **모든 타입 사실은 World 에 질의** 해서 얻는다. AST 해석기 안에 "`42` 는 Integer" 같은 하드코딩 규칙은 없다.

### 3. 추가는 monotonic, 제거만 World 를 오염시킨다

- **추가 · 재정의** 는 즉시 반영 가능 (기존 참조 무효화 없음)
- **제거 · rename** 은 실행해봐야 알 수 있음 → 감지 시 전체 재빌드

사전 AST diff 는 사용하지 않는다. "일단 load 해보고, 위험 연산이 감지되면 escalate" 하는 낙관적 방식을 쓴다.

### 4. Lucene 스타일의 불변 스냅샷 + 원자적 교체

World 는 불변. 새 World 가 빌드되면 포인터 하나를 바꿔 교체한다. 빌드 중에도 에디터는 이전 World 로 계속 응답한다.

## 전체 흐름

```
┌──────────────────────────────────────────────────────────┐
│                    ruby-lsp addon                        │
│                                                          │
│   ┌──────────────┐    ┌──────────────────────────────┐  │
│   │ Hover /      │ ─→ │ WorldHolder#current          │  │
│   │ Definition   │    │   .lookup(file, line, col)   │  │
│   └──────────────┘    └──────────────────────────────┘  │
│                               ↑                          │
│                               │ swap (atomic)            │
│                       ┌──────────────────────────┐      │
│                       │ Build Coordinator        │      │
│                       │ (background thread)      │      │
│                       └──────────────────────────┘      │
└───────────────────────────────┬──────────────────────────┘
                                │ spawn
                                ↓
          ┌────────────────────────────────────────┐
          │  Collector (외부 프로세스)               │
          │                                        │
          │  1. Rails 부팅 · eager_load            │
          │  2. DangerHook armed                    │
          │  3. load(changed_file)                  │
          │     - 성공 → 4 로                        │
          │     - RequireReworld → 전체 재부팅 모드 │
          │  4. Reflection 수집                     │
          │     - 클래스 · 메서드 · 관계 · 스키마    │
          │  5. 메서드 본문 분석                      │
          │     - Prism AST + World 질의            │
          │     - 반환 타입 · 로컬 변수 타입 계산     │
          │  6. Marshal → stdout                    │
          └────────────────────────────────────────┘
```

## 데이터 모델 (World)

World 는 불변 스냅샷. `Data.define` 으로 표현.

```ruby
# Ruby 3.3+ 전제
module RubyLsp
  module RuntimeType
    # World = 한 시점의 타입 정보 전체
    World = Data.define(
      :generation,       # Integer: 단조 증가
      :classes,          # Hash<String, ClassInfo>
      :method_types,     # Hash<String, MethodTypeInfo>   key = "User#full_name"
      :local_type_maps,  # Hash<String, LocalTypeMap>     key = "User#full_name"
      :schema,           # Hash<Symbol, TableInfo>
    )

    ClassInfo = Data.define(
      :name,             # String: "User"
      :superclass,       # String: "ApplicationRecord"
      :ancestors,        # Array<String>: ["User", "ApplicationRecord", ..., "Object"]
      :methods,          # Hash<Symbol, MethodInfo>        (인스턴스 메서드)
      :singleton_methods,# Hash<Symbol, MethodInfo>
      :associations,     # Hash<Symbol, AssociationInfo>
      :columns,          # Hash<Symbol, ColumnInfo>
      :source_file,      # String
    )

    MethodInfo = Data.define(
      :name, :owner, :parameters, :visibility, :source_location,
    )

    # 빌드 타임 분석으로 얻어지는 타입 정보
    MethodTypeInfo = Data.define(
      :return_type,      # TypeExpr
      :param_types,      # Hash<Symbol, TypeExpr>
    )

    # 메서드 본문 안의 좌표 → 식 · 타입
    LocalTypeMap = Data.define(
      :entries,          # Array<Entry>
    )
    Entry = Data.define(
      :file, :line, :column,
      :expression,       # String: "user.posts.first"
      :type,             # TypeExpr
    )

    AssociationInfo = Data.define(:kind, :name, :class_name, :source_location)
    ColumnInfo     = Data.define(:name, :sql_type, :ruby_type, :null, :default)
    TableInfo      = Data.define(:name, :columns)

    # 타입 표현. Union · Generic 을 섞어 표현
    module TypeExpr
      Simple    = Data.define(:name)                    # "Integer"
      Union     = Data.define(:members)                 # [Post, NilClass]
      Generic   = Data.define(:base, :args)             # Array<Post>
      Unknown   = Data.define
      Nil       = Data.define
    end
  end
end
```

## World 질의 API

에디터 호버 시 사용되는 유일한 경로.

```ruby
class World
  # 커서 위치의 식 타입
  def type_at(file:, line:, column:)
    map = find_method_map(file, line) or return TypeExpr::Unknown.new
    map.entries.find { _1.line == line && _1.column == column }&.type ||
      TypeExpr::Unknown.new
  end

  # 메서드의 반환 타입
  def return_type_of(class_name, method_name)
    method_types["#{class_name}##{method_name}"]&.return_type || TypeExpr::Unknown.new
  end

  # 호출식 receiver.method(...) 의 반환 타입을 따지는 헬퍼
  def dispatch(receiver_type, method_name)
    case receiver_type
    in TypeExpr::Simple(name: cname)
      class_info = classes[cname] or return TypeExpr::Unknown.new
      class_info.ancestors.each do |anc|
        info = method_types["#{anc}##{method_name}"] and return info.return_type
      end
      TypeExpr::Unknown.new
    in TypeExpr::Union(members:)
      TypeExpr::Union.new(members: members.map { dispatch(_1, method_name) }).normalize
    in TypeExpr::Generic(base: "Array", args: [elem])
      # Array 의 메서드는 내장 테이블로 (별도 정의)
      BuiltinArrayDispatch.call(method_name, elem)
    else
      TypeExpr::Unknown.new
    end
  end
end
```

포인트: 하드코딩된 타입 규칙은 없다. `dispatch` 는 World 에 저장된 `method_types` 를 따라갈 뿐.

## World 빌드: Collector

Collector 는 ruby-lsp 와 별도 프로세스. Rails 가 부팅된 격리 공간에서 동작.

```ruby
# lib/ruby_lsp/runtime_type/collector.rb
# 실행: ruby collector.rb RAILS_ROOT [--incremental FILE]

require "bundler/setup"
require "prism"
require File.join(ARGV[0], "config/environment")
Rails.application.eager_load!

if (idx = ARGV.index("--incremental"))
  file = ARGV[idx + 1]
  DangerHook.armed { load(file) }  # RequireReworld → 예외로 이탈
end

world = build_world
STDOUT.binmode
STDOUT.write(Marshal.dump(world))
```

### 빌드 단계

```
1. Reflection 수집 (ClassInfo · columns · associations)
2. 메서드 시그니처 1 차 계산 (associations · columns 로부터)
3. 메서드 본문 분석 (Prism + World 질의)
   - 고정점 도달까지 반복 (서로 호출하는 메서드)
4. 완성된 World 를 Marshal
```

### 메서드 시그니처 1 차 계산

Reflection 에서 직접 얻어지는 타입 정보:

| 소스 | 생성되는 메서드 | 반환 타입 |
|---|---|---|
| `has_many :posts` | `#posts` | `Array<Post>` (엄밀히는 `CollectionProxy<Post>`) |
| `belongs_to :user` | `#user` | `User \| nil` |
| `has_one :profile` | `#profile` | `Profile \| nil` |
| `columns_hash[:name]` (string) | `#name`, `#name=` | `String \| nil` |
| `columns_hash[:created_at]` | `#created_at` | `Time \| nil` |
| `enum status: {...}` | `#active?` etc | `Boolean` |
| `scope :recent, -> {...}` | `.recent` | `Relation<Self>` |

이게 World 에 먼저 채워진다. 사용자 정의 메서드는 다음 단계에서.

### 메서드 본문 분석 (빌드 타임 AST 순회)

Prism 으로 메서드 본문을 훑되, **모든 타입 사실은 World 질의** 로 결정.

```ruby
class MethodAnalyzer
  def initialize(world_builder)
    @wb = world_builder
  end

  def analyze(class_name, method_name, def_node)
    env = Env.new(receiver_type: TypeExpr::Simple.new(name: class_name))
    seed_param_types(env, def_node, class_name, method_name)

    return_type = visit(def_node.body, env)

    @wb.record_method_type(class_name, method_name,
      return_type: return_type,
      param_types: env.params_snapshot)
    @wb.record_local_types(class_name, method_name, env.type_map)
  end

  private

  # 각 Prism 노드를 타입으로 평가. 모든 결정은 World 질의로.
  def visit(node, env)
    case node
    in Prism::IntegerNode
      @wb.world.class_of_instance("Integer")   # 하드코딩 아님: World 안에 있는 Integer
    in Prism::StringNode
      @wb.world.class_of_instance("String")
    in Prism::ArrayNode(elements:)
      elem_types = elements.map { visit(_1, env) }
      TypeExpr::Generic.new(base: "Array", args: [union_of(elem_types)])
    in Prism::LocalVariableReadNode(name:)
      env.lookup(name) || TypeExpr::Unknown.new
    in Prism::LocalVariableWriteNode(name:, value:)
      t = visit(value, env)
      env.assign(name, t)
      env.record(node.location, node.slice, t)
      t
    in Prism::CallNode(receiver:, name:)
      recv_type = receiver ? visit(receiver, env) : env.receiver_type
      t = @wb.world.dispatch(recv_type, name)   # ← 핵심: World 질의
      env.record(node.location, node.slice, t)
      t
    in Prism::IfNode(predicate:, statements:, subsequent:)
      visit(predicate, env)
      then_env = env.branch
      else_env = env.branch
      then_t = visit(statements, then_env)
      else_t = visit(subsequent, else_env) if subsequent
      env.merge(then_env, else_env)
      union_of([then_t, else_t].compact)
    # ... (나머지 노드)
    end
  end
end
```

핵심: `visit(Prism::CallNode)` 에서 `world.dispatch(recv_type, name)` 로 World 에 타입을 묻는다. 분석기는 "AST 를 타입으로 사상" 만 하고, 실제 타입 정보는 전부 World 안에 있다.

### 고정점 반복

메서드 A 가 메서드 B 를 호출하고 B 가 A 를 호출하는 경우, 1 회 순회로는 안 끝난다. 간단한 고정점 반복:

```ruby
loop do
  changed = false
  classes.each do |cls|
    cls.methods.each do |m, def_node|
      before = world_builder.method_types["#{cls.name}##{m}"]
      analyzer.analyze(cls.name, m, def_node)
      after = world_builder.method_types["#{cls.name}##{m}"]
      changed ||= before != after
    end
  end
  break unless changed
  break if (iter += 1) > 5   # 수렴 상한
end
```

수렴하지 않는 메서드는 `Unknown` 으로 둔다.

### 내장 클래스 (Integer, Array, String, ...)

Reflection 으로는 반환 타입을 알 수 없으므로 작은 내장 디스패치 테이블을 가진다. 이건 **World 에 주입되는 값** 이지 추론기 안의 하드코딩 규칙이 아니다.

```ruby
# lib/ruby_lsp/runtime_type/builtins.rb
BUILTIN_METHOD_TYPES = {
  "Integer#+" => ->(recv, args) { TypeExpr::Simple.new(name: "Integer") },
  "Array#size" => ->(recv, args) { TypeExpr::Simple.new(name: "Integer") },
  "Array#first" => ->(recv, args) {
    case recv
    in TypeExpr::Generic(base: "Array", args: [elem])
      TypeExpr::Union.new(members: [elem, TypeExpr::Nil.new]).normalize
    else
      TypeExpr::Unknown.new
    end
  },
  # ...
}
```

World 빌드 초기에 이 테이블을 `world.method_types` 에 병합. 이후 `world.dispatch` 는 이 항목도 자연스럽게 찾는다.

## 갱신 전략

사전 AST diff 로 Tier 를 나누지 않는다. **항상 한 가지 절차** 로 시도하고, 위험이 감지되면 에스컬레이션.

```
파일 변경 감지
  ↓
┌──────────────────────────────────────────┐
│ Incremental Build 요청                   │
│   - spawn Collector --incremental FILE   │
└──────────────────────────────────────────┘
  ↓
Collector 내부에서:
  DangerHook.armed { load(file) }
  ↓
  ├─ 성공 → 해당 파일이 정의하는 클래스만 재수집
  │         + 그 클래스의 메서드 본문 재분석
  │         → 부분 World 패치를 Marshal 로 송신
  │
  └─ RequireReworld → 현재 Collector 프로세스 종료
                     → 새 Collector 프로세스를 띄워 전체 재빌드
```

Addon 측에서:

```ruby
def on_file_change(path)
  @build_queue << path
end

def build_worker
  loop do
    path = @build_queue.pop
    result = run_collector(incremental: path)
    case result
    in { patch: }
      @holder.swap(@holder.current.merge(patch))
    in { full_world: }
      @holder.swap(full_world)
    in { error: }
      @logger.error(error)
    end
  end
end
```

### 유령 (Ghost) 관리

`load` 만으로는 Ruby 에서 제거된 메서드 · 상수가 남는다. Incremental build 는 이를 모른다.

- 주기적으로 (idle 30 초 · N 회 incremental 후) 전체 재빌드 예약 → sweep
- `DangerHook` 가 잡아낸 "제거 시도" 는 즉시 전체 재빌드 트리거

## DangerHook

Collector 프로세스에서만 prepend. `load` 실행 중에만 armed.

```ruby
module RubyLsp
  module RuntimeType
    class RequireReworld < StandardError
      attr_reader :operation, :target
      def initialize(operation:, target:)
        @operation = operation
        @target = target
        super("RequireReworld: #{operation} on #{target}")
      end
    end

    module DangerHook
      KEY = :runtime_type_armed

      def self.armed
        Thread.current[KEY] = true
        yield
      ensure
        Thread.current[KEY] = false
      end

      def self.armed? = Thread.current[KEY] == true

      module Hooks
        def remove_const(name)
          raise RequireReworld.new(operation: :remove_const, target: "#{self}::#{name}") \
            if DangerHook.armed?
          super
        end

        def remove_method(*names)
          raise RequireReworld.new(operation: :remove_method, target: "#{self}##{names.first}") \
            if DangerHook.armed?
          super
        end

        def undef_method(*names)
          raise RequireReworld.new(operation: :undef_method, target: "#{self}##{names.first}") \
            if DangerHook.armed?
          super
        end
      end
    end
  end
end

Module.prepend(RubyLsp::RuntimeType::DangerHook::Hooks)
```

주의: 이 hook 은 Collector 프로세스에서만 유효하게 한다. LSP 프로세스에 들어가면 ruby-lsp 자체가 `remove_const` 같은 걸 쓸 때 잘못 터진다.

## 프로세스 · 스레드 구조

```
LSP 프로세스 (ruby-lsp)
├─ Main 스레드 (LSP 프로토콜)
│    └─ Hover 요청 → WorldHolder#current.type_at(...)  [순수 lookup]
├─ WorldHolder (공유 객체, atomic swap)
└─ Build 스레드
     └─ Queue pop → Collector 프로세스 spawn → Marshal 수신 → swap

Collector 프로세스 (격리된 Rails 공간)
├─ Rails 부팅 · eager_load
├─ DangerHook prepend
├─ load(changed_file) armed 블록
├─ Reflection 수집
├─ Prism AST 기반 메서드 분석 (World 질의 주도)
└─ Marshal.dump(world) → stdout
```

포인트:
- LSP 스레드는 World 를 **읽기만** 한다. 락 불필요 (MRI 의 ivar read 는 atomic)
- Build 스레드만이 `@holder.swap` 으로 교체
- Collector 는 프로세스 단위로 격리. 죽어도 LSP 는 살아남음

## WorldHolder

```ruby
class WorldHolder
  def initialize
    @world = World.empty
    @mutex = Mutex.new
  end

  # 읽기는 락 없음
  def current = @world

  # 쓰기만 직렬화
  def swap(new_world)
    @mutex.synchronize { @world = new_world }
  end
end
```

## Addon 엔트리포인트

```ruby
module RubyLsp
  module RuntimeType
    class Addon < ::RubyLsp::Addon
      def activate(global_state, message_queue)
        @global_state = global_state
        @holder = WorldHolder.new
        @rails_root = detect_rails_root(global_state.workspace_uri)
        @build_queue = Queue.new
        @incremental_count = 0

        install_hover
        start_build_worker
        @build_queue << { type: :full, reason: "initial boot" }
      end

      def deactivate
        @build_queue << :stop
        @worker&.join(5)
      end

      def name = "RuntimeType"
      def version = RuntimeType::VERSION

      def workspace_did_change_watched_files(changes)
        changes.each do |c|
          next unless c.uri.end_with?(".rb")
          path = URI(c.uri).path
          next unless target_file?(path)
          @build_queue << { type: :incremental, file: path }
        end
      end

      private

      def install_hover
        # ruby-lsp 의 hover 가 호출하는 type_inferrer 를 우리 것으로 교체
        custom = HoverTypeInferrer.new(@holder)
        @global_state.instance_variable_set(:@type_inferrer, custom)
      end

      def start_build_worker
        @worker = Thread.new do
          Thread.current.name = "runtime_type_build"
          loop do
            job = @build_queue.pop
            break if job == :stop
            handle(job)
          rescue => e
            @global_state.logger.error(e.full_message)
          end
        end
      end

      def handle(job)
        case job[:type]
        when :full
          coalesce_pending_full!
          world = CollectorClient.new(@rails_root).full_build(
            generation: @holder.current.generation + 1)
          @holder.swap(world)
          @incremental_count = 0
        when :incremental
          result = CollectorClient.new(@rails_root).incremental(job[:file])
          case result
          in { patch: }
            @holder.swap(@holder.current.merge_patch(patch))
            @incremental_count += 1
          in :escalate
            @build_queue << { type: :full, reason: "RequireReworld" }
          end
          @build_queue << { type: :full, reason: "ghost sweep" } if @incremental_count >= 20
        end
      end

      def coalesce_pending_full!
        count = 0
        while !@build_queue.empty? && @build_queue.first.is_a?(Hash) && @build_queue.first[:type] == :full
          @build_queue.pop; count += 1
        end
        @global_state.logger.info("coalesced #{count} full jobs") if count > 0
      end

      def target_file?(path)
        path.include?("/app/") || path.end_with?("/db/schema.rb") || path.include?("/lib/")
      end

      def detect_rails_root(uri)
        path = URI(uri).path
        raise "not a Rails project: #{path}" unless File.exist?(File.join(path, "config/environment.rb"))
        path
      end
    end
  end
end
```

## HoverTypeInferrer

ruby-lsp 본체와 같은 인터페이스를 만족하되, 내부는 **순수 World lookup**.

```ruby
class HoverTypeInferrer
  def initialize(holder)
    @holder = holder
  end

  # ruby-lsp 는 커서 위치를 주며 타입을 물음
  def infer_receiver_type(node_context)
    world = @holder.current
    type = world.type_at(
      file: node_context.uri.path,
      line: node_context.location.start_line,
      column: node_context.location.start_column,
    )
    to_ruby_lsp_type(type)
  end
end
```

AST 순회 없음. 단순 lookup.

## CollectorClient

Addon 과 Collector 프로세스 사이의 어댑터.

```ruby
class CollectorClient
  COLLECTOR_PATH = File.expand_path("collector.rb", __dir__)

  def initialize(rails_root)
    @rails_root = rails_root
  end

  def full_build(generation:)
    run(args: [])
      .then { |payload| World.from_payload(payload, generation: generation) }
  end

  def incremental(file)
    payload = run(args: ["--incremental", file])
    return :escalate if payload[:escalate]
    { patch: WorldPatch.from_payload(payload) }
  end

  private

  def run(args:)
    stdout_r, stdout_w = IO.pipe
    stderr_r, stderr_w = IO.pipe

    pid = Process.spawn(
      { "BUNDLE_GEMFILE" => File.join(@rails_root, "Gemfile") },
      RbConfig.ruby, COLLECTOR_PATH, @rails_root, *args,
      out: stdout_w, err: stderr_w,
      chdir: @rails_root,
    )
    stdout_w.close; stderr_w.close

    out_t = Thread.new { stdout_r.binmode.read }
    err_t = Thread.new { stderr_r.read }
    _, status = Process.wait2(pid)

    raise CollectorError, err_t.value unless status.success?
    Marshal.load(out_t.value)
  end
end

class CollectorError < StandardError; end
```

## 파일 구성

```
poc/ruby_lsp_runtime_type/
├── lib/ruby_lsp/runtime_type/
│   ├── addon.rb                # Addon 엔트리, 빌드 큐 · 워커
│   ├── world.rb                # World · ClassInfo · TypeExpr 등 데이터
│   ├── world_holder.rb         # atomic swap
│   ├── hover_type_inferrer.rb  # 순수 lookup
│   ├── collector_client.rb     # 외부 프로세스 어댑터
│   ├── collector.rb            # 외부 프로세스 엔트리 (Rails 공간)
│   ├── method_analyzer.rb      # 빌드 타임 AST 순회 (World 질의 주도)
│   ├── env.rb                  # 메서드 본문 분석용 타입 환경
│   ├── builtins.rb             # 내장 클래스 디스패치 테이블
│   ├── danger_hook.rb          # RequireReworld 발생기
│   └── type_expr.rb            # Simple · Union · Generic · Unknown · Nil
└── ruby_lsp_runtime_type.gemspec
```

## 성능 목표

| 작업 | 소요 시간 | 비고 |
|---|---|---|
| Hover lookup | < 1 ms | 순수 Hash 조회 |
| Incremental build (수렴 1 회) | 200 ms ~ 1 s | Rails 미부팅 + 1 파일 load |
| Full build (cold) | 3 ~ 10 s | Rails 부팅 포함 |
| World swap | < 1 ms | 포인터 교체 |

최적화 여지: **상주 Collector** (Unix Socket 으로 persistent 하게 유지) → incremental 이 수십 ms 로 내려감.

## 의존성

```ruby
# ruby_lsp_runtime_type.gemspec
Gem::Specification.new do |spec|
  spec.name = "ruby_lsp_runtime_type"
  spec.version = "0.1.0"
  spec.required_ruby_version = ">= 3.3.0"

  spec.add_dependency "ruby-lsp", "~> 0.26"
  spec.add_dependency "prism", "~> 1.0"
  # Rails 는 타겟 프로젝트가 가지고 있음
end
```

## 테스트 전략

```
test/
├── unit/
│   ├── type_expr_test.rb         # TypeExpr 조작 (union 정규화 등)
│   ├── world_test.rb             # lookup · dispatch
│   ├── method_analyzer_test.rb   # 고정된 World 를 주고 AST 분석 검증
│   ├── danger_hook_test.rb       # armed 블록 안팎 동작
│   └── world_holder_test.rb      # concurrent swap/read
├── integration/
│   ├── collector_test.rb         # 실제 sample_app 으로 Full build
│   ├── incremental_test.rb       # 파일 수정 → patch 적용
│   └── escalation_test.rb        # remove_const → 전체 재빌드
└── fixtures/
    └── sample_app/               # 기존 Rails 앱 재사용
```

`MethodAnalyzer` 는 **Rails 없이** 고정 World 를 주고 테스트 가능 → 가장 로직이 복잡한 부분을 빠르게 보호.

## 향후 과제

- **상주 Collector** — Unix Socket 기반 persistent 프로세스로 incremental 을 수십 ms 대로
- **타입 표현 정교화** — `ActiveRecord::Relation<Post>` 같은 Rails 특화 제네릭, Keyword 인자 · 블록 타입
- **`db/schema.rb` 변경 감지** — 스키마 재로드 → 영향받는 AR 모델의 컬럼 타입 갱신
- **부분 Full rebuild** — 의존 그래프 기반으로 "영향 범위만" 재빌드 (Lucene 세그먼트 머지 참고)
- **gem 라이브러리 타입** — `lib/` 밖 gem 의 타입. RBS 가 있으면 병용, 없으면 reflection 만
- **에디터 통합 확장** — Hover 외에 Completion · Definition · Diagnostics 에 World 연결
