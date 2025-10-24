# RactorRegistry

Elixir Registry에서 영감을 받아 Ruby Ractor로 구현한 실험적 레지스트리 시스템입니다.

## 개요

RactorRegistry는 Ractor 인스턴스를 이름으로 관리할 수 있는 중앙 레지스트리를 제공합니다. Elixir의 Registry 모듈과 유사하게, 프로세스(Ractor)를 이름으로 등록하고 조회할 수 있습니다.

## 특징

- ✅ **Unique 키 지원**: 하나의 이름에 하나의 Ractor만 등록
- ✅ **메시지 패싱 기반**: Ractor 간 안전한 통신
- ✅ **Thread-safe**: Ractor 기반이므로 기본적으로 안전
- ✅ **동시성 지원**: 여러 Ractor에서 동시에 접근 가능
- ✅ **간단한 API**: register, lookup, unregister

## 요구사항

- Ruby 3.0 이상 (Ractor 지원)
- 테스트 환경: Ruby 3.4.2

## 사용법

### 기본 사용

```ruby
require_relative 'ractor_registry'

# Registry 생성
registry = RactorRegistry.new

# Worker Ractor 생성
worker = Ractor.new do
  loop do
    msg = Ractor.receive
    Ractor.yield("Processed: #{msg}")
  end
end

# 등록
registry.register(:my_worker, worker)

# 조회
found = registry.lookup(:my_worker)
found.send("Hello")
puts found.take  # => "Processed: Hello"

# 등록 해제
registry.unregister(:my_worker)

# Registry 종료
registry.stop
```

### API

#### `register(name, ractor)`
Ractor를 이름으로 등록합니다.
- 중복 등록 시 `AlreadyRegisteredError` 발생

#### `lookup(name)`
이름으로 Ractor를 조회합니다.
- 찾을 수 없으면 `nil` 반환

#### `lookup!(name)`
이름으로 Ractor를 조회합니다 (raising version).
- 찾을 수 없으면 `NotFoundError` 발생

#### `unregister(name)`
등록된 Ractor를 제거합니다.
- 성공하면 `true`, 찾을 수 없으면 `false` 반환

#### `list_all`
등록된 모든 이름을 반환합니다.

#### `count`
등록된 Ractor 수를 반환합니다.

#### `stop`
Registry를 종료합니다.

## 예제 실행

### 1. 기본 예제
```bash
ruby example.rb
```

다음을 테스트합니다:
- Worker Ractor 등록
- 이름으로 조회 및 사용
- 중복 등록 에러 처리
- 등록 해제
- 존재하지 않는 키 조회

### 2. 동시성 테스트
```bash
ruby concurrent_example.rb
```

다음을 테스트합니다:
- 여러 Client Ractor에서 동시 접근
- Worker 풀 관리
- 다른 Ractor에서 등록
- 병렬 작업 처리

## Elixir Registry와의 비교

### 유사점
- ✅ 이름 기반 프로세스 조회
- ✅ 중앙화된 레지스트리
- ✅ 동시성 안전

### 차이점
- ❌ **Duplicate 키 미지원**: 현재 구현은 unique 키만 지원
- ❌ **메타데이터 미지원**: Ractor와 함께 추가 데이터 저장 불가
- ❌ **프로세스 모니터링 미지원**: Ractor 종료 시 자동 해제 없음
- ❌ **파티셔닝 미지원**: 단일 Registry Ractor만 사용

### 기술적 차이

| 특징 | Elixir Registry | RactorRegistry |
|------|----------------|----------------|
| 백엔드 | ETS (Erlang Term Storage) | Ruby Hash |
| 동시성 모델 | Actor (BEAM) | Ractor (Ruby) |
| 메모리 공유 | 없음 (메시지 복사) | 제한적 (불변 객체만) |
| 성능 | 매우 높음 (네이티브) | 실험적 단계 |

## 제한사항

1. **Ractor 실험적 기능**: Ruby의 Ractor는 아직 실험 단계
2. **단순 구현**: 프로덕션용이 아닌 실험용
3. **에러 처리**: Ractor 종료 시 자동 정리 없음
4. **확장성**: 단일 Registry Ractor가 병목될 수 있음

## 학습 포인트

### 1. Ractor 간 통신
```ruby
# 메시지 전송
ractor.send(message)

# 메시지 수신
Ractor.receive

# 결과 반환
Ractor.yield(result)

# 결과 받기
ractor.take
```

### 2. Ractor 공유 가능한 객체
- Ractor 자체는 공유 가능
- 불변 객체 (Frozen String, Symbol, 숫자 등)
- Shareable 객체

### 3. 메시지 패싱 패턴
```ruby
# 요청-응답 패턴
sender = Ractor.current
registry_ractor.send([:command, args, sender])
result = Ractor.receive
```

## 향후 개선 가능 사항

- [ ] Duplicate 키 지원
- [ ] 메타데이터 저장
- [ ] Ractor 모니터링 및 자동 정리
- [ ] 파티셔닝으로 성능 개선
- [ ] 패턴 기반 조회
- [ ] 통계 및 모니터링 기능

## 라이센스

실험용 코드로 자유롭게 사용 가능합니다.

## 참고

- [Ruby Ractor Documentation](https://docs.ruby-lang.org/en/master/Ractor.html)
- [Elixir Registry](https://hexdocs.pm/elixir/Registry.html)
