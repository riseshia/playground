# Ruby Prism AST Parsing Benchmark

이 벤치마크는 Ruby의 Prism 파서를 사용하여 AST를 파싱하고 로컬 변수를 추출하는 작업을 Thread와 Ractor를 사용한 병렬화 방식으로 비교합니다.

## 구성

- `sample.rb`: 파싱할 샘플 Ruby 파일 (약 600줄)
- `local_var_extractor.rb`: Prism을 사용하여 로컬 변수를 추출하는 클래스
- `thread_parallel.rb`: Thread를 사용한 병렬 처리 구현
- `ractor_parallel.rb`: Ractor를 사용한 병렬 처리 구현
- `benchmark.rb`: 표준 Benchmark를 사용한 벤치마크 스크립트

## 설치

```bash
bundle install
```

## 실행

```bash
bundle exec ruby benchmark.rb
```

## 벤치마크 내용

- **총 반복 횟수**: 5,000회
- **Thread 개수**: 8개
- **Ractor 개수**: 8개

각 반복마다 다음 작업을 수행합니다:
1. Ruby 파일을 읽기
2. Prism으로 AST 파싱
3. AST를 순회하며 로컬 변수 추출

## 결과 해석

벤치마크는 Thread 기반과 Ractor 기반 각각의 총 실행 시간을 측정하고 비교합니다:
- 각 방식의 절대적인 실행 시간 (초)
- 두 방식 간의 속도 배율
- 어느 방식이 더 빠른지 표시
