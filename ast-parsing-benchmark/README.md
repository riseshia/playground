# Ruby Prism AST Parsing Benchmark

이 벤치마크는 Ruby의 Prism 파서를 사용하여 AST를 파싱하고 로컬 변수를 추출하는 작업을 Thread와 Ractor를 사용한 병렬화 방식으로 비교합니다.

## 구성

- `sample.rb`: 파싱할 샘플 Ruby 파일
- `local_var_extractor.rb`: Prism을 사용하여 로컬 변수를 추출하는 클래스
- `thread_parallel.rb`: Thread를 사용한 병렬 처리 구현
- `ractor_parallel.rb`: Ractor를 사용한 병렬 처리 구현
- `benchmark.rb`: benchmark-ips를 사용한 벤치마크 스크립트

## 설치

```bash
bundle install
```

## 실행

```bash
bundle exec ruby benchmark.rb
```

## 벤치마크 내용

- **반복 횟수**: 5,000회
- **Thread 개수**: 8개
- **Ractor 개수**: 8개

각 반복마다 다음 작업을 수행합니다:
1. Ruby 파일을 읽기
2. Prism으로 파싱
3. AST를 순회하며 로컬 변수 추출

## 결과 해석

benchmark-ips는 초당 실행 가능한 반복 횟수(iterations per second)를 측정합니다. 더 높은 값이 더 빠른 성능을 의미합니다.

비교 결과에서는:
- 각 방식의 절대적인 성능
- 두 방식 간의 상대적인 속도 차이
- 통계적 유의성

등을 확인할 수 있습니다.
