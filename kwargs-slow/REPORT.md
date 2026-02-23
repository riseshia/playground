# RubyStruct 最適化レポート

## ベースライン

### ベンチマーク (benchmark/ips)
```
=== インスタンス生成 ===
ruby 3.4.8 (2025-12-17 revision 995b59f666) +PRISM [arm64-darwin25]
Warming up --------------------------------------
         new 1-field     1.116M i/100ms
         new 4-field   911.565k i/100ms
         new 8-field   738.101k i/100ms
         kw  1-field   718.138k i/100ms
         kw  4-field   475.025k i/100ms
         kw  8-field   311.603k i/100ms
Calculating -------------------------------------
         new 1-field     11.099M (± 1.2%) i/s   (90.10 ns/i) -     55.808M in   5.029161s
         new 4-field      8.746M (± 2.5%) i/s  (114.34 ns/i) -     43.755M in   5.006182s
         new 8-field      6.967M (± 2.1%) i/s  (143.53 ns/i) -     35.429M in   5.087367s
         kw  1-field      7.346M (± 1.5%) i/s  (136.14 ns/i) -     37.343M in   5.084913s
         kw  4-field      4.673M (± 1.3%) i/s  (213.98 ns/i) -     23.751M in   5.083223s
         kw  8-field      3.011M (± 1.9%) i/s  (332.14 ns/i) -     15.269M in   5.073183s

Comparison:
         new 1-field: 11098516.8 i/s
         new 4-field:  8745915.6 i/s - 1.27x  slower
         kw  1-field:  7345544.9 i/s - 1.51x  slower
         new 8-field:  6967417.0 i/s - 1.59x  slower
         kw  4-field:  4673386.1 i/s - 2.37x  slower
         kw  8-field:  3010773.1 i/s - 3.69x  slower


=== ゲッター ===
ruby 3.4.8 (2025-12-17 revision 995b59f666) +PRISM [arm64-darwin25]
Warming up --------------------------------------
              getter     1.775M i/100ms
           [] symbol   485.359k i/100ms
            [] index   611.799k i/100ms
Calculating -------------------------------------
              getter     17.666M (± 1.3%) i/s   (56.61 ns/i) -     88.750M in   5.024675s
           [] symbol      4.820M (± 0.8%) i/s  (207.47 ns/i) -     24.268M in   5.035176s
            [] index      6.023M (± 1.9%) i/s  (166.03 ns/i) -     30.590M in   5.080838s

Comparison:
              getter: 17665739.6 i/s
            [] index:  6023033.5 i/s - 2.93x  slower
           [] symbol:  4819982.6 i/s - 3.67x  slower


=== セッター ===
ruby 3.4.8 (2025-12-17 revision 995b59f666) +PRISM [arm64-darwin25]
Warming up --------------------------------------
              setter     1.232M i/100ms
          []= symbol   441.828k i/100ms
           []= index   562.910k i/100ms
Calculating -------------------------------------
              setter     12.256M (± 1.5%) i/s   (81.59 ns/i) -     61.616M in   5.028637s
          []= symbol      4.403M (± 1.1%) i/s  (227.10 ns/i) -     22.091M in   5.017658s
           []= index      5.429M (± 1.8%) i/s  (184.19 ns/i) -     27.583M in   5.082092s

Comparison:
              setter: 12255766.2 i/s
           []= index:  5429297.8 i/s - 2.26x  slower
          []= symbol:  4403251.0 i/s - 2.78x  slower


=== 変換 ===
ruby 3.4.8 (2025-12-17 revision 995b59f666) +PRISM [arm64-darwin25]
Warming up --------------------------------------
        to_a 4-field     1.881M i/100ms
        to_h 4-field     1.119M i/100ms
Calculating -------------------------------------
        to_a 4-field     18.794M (± 1.6%) i/s   (53.21 ns/i) -     94.036M in   5.004841s
        to_h 4-field     11.870M (± 1.5%) i/s   (84.25 ns/i) -     60.412M in   5.090699s

Comparison:
        to_a 4-field: 18793999.9 i/s
        to_h 4-field: 11869956.3 i/s - 1.58x  slower


=== 等値比較 ===
ruby 3.4.8 (2025-12-17 revision 995b59f666) +PRISM [arm64-darwin25]
Warming up --------------------------------------
          == 4-field   834.122k i/100ms
        eql? 4-field   688.496k i/100ms
        hash 4-field     1.299M i/100ms
Calculating -------------------------------------
          == 4-field      8.151M (± 1.1%) i/s  (122.69 ns/i) -     40.872M in   5.015051s
        eql? 4-field      6.947M (± 0.8%) i/s  (143.95 ns/i) -     35.113M in   5.054932s
        hash 4-field     12.833M (± 2.0%) i/s   (77.93 ns/i) -     64.961M in   5.064185s

Comparison:
        hash 4-field: 12832631.3 i/s
          == 4-field:  8150950.6 i/s - 1.57x  slower
        eql? 4-field:  6946786.8 i/s - 1.85x  slower


=== イテレーション ===
ruby 3.4.8 (2025-12-17 revision 995b59f666) +PRISM [arm64-darwin25]
Warming up --------------------------------------
        each 4-field     1.044M i/100ms
   each_pair 4-field     1.035M i/100ms
Calculating -------------------------------------
        each 4-field     10.493M (± 1.3%) i/s   (95.30 ns/i) -     53.238M in   5.074285s
   each_pair 4-field     10.289M (± 0.7%) i/s   (97.19 ns/i) -     51.757M in   5.030346s

Comparison:
        each 4-field: 10493451.7 i/s
   each_pair 4-field: 10289440.7 i/s - same-ish: difference falls within error


=== inspect ===
ruby 3.4.8 (2025-12-17 revision 995b59f666) +PRISM [arm64-darwin25]
Warming up --------------------------------------
     inspect 4-field   322.400k i/100ms
Calculating -------------------------------------
     inspect 4-field      3.158M (± 2.3%) i/s  (316.68 ns/i) -     15.798M in   5.005368s
```

### プロファイル (メモリ・CPU・GC)
```
=== メモリプロファイル: アロケーション (1000 calls each) ===

--- インスタンス生成 ---
  new 1-field (positional)              1001 allocs / 1000 calls  ( 1.00 / call)
  new 4-field (positional)              1000 allocs / 1000 calls  ( 1.00 / call)
  new 8-field (positional)              1000 allocs / 1000 calls  ( 1.00 / call)
  new 1-field (keyword)                 2000 allocs / 1000 calls  ( 2.00 / call)
  new 4-field (keyword)                 2000 allocs / 1000 calls  ( 2.00 / call)
  new 8-field (keyword)                 2000 allocs / 1000 calls  ( 2.00 / call)

--- アクセサ ---
  getter (4-field)                         0 allocs / 1000 calls  ( 0.00 / call)
  [] symbol (4-field)                      0 allocs / 1000 calls  ( 0.00 / call)
  [] index (4-field)                       0 allocs / 1000 calls  ( 0.00 / call)
  setter (4-field)                         0 allocs / 1000 calls  ( 0.00 / call)
  []= symbol (4-field)                     0 allocs / 1000 calls  ( 0.00 / call)
  []= index (4-field)                      0 allocs / 1000 calls  ( 0.00 / call)

--- 変換 ---
  to_a (4-field)                        1000 allocs / 1000 calls  ( 1.00 / call)
  to_h (4-field)                        1000 allocs / 1000 calls  ( 1.00 / call)
  to_a (8-field)                        1000 allocs / 1000 calls  ( 1.00 / call)
  to_h (8-field)                        1000 allocs / 1000 calls  ( 1.00 / call)

--- 比較 ---
  == (4-field)                             0 allocs / 1000 calls  ( 0.00 / call)
  eql? (4-field)                           0 allocs / 1000 calls  ( 0.00 / call)
  hash (4-field)                           0 allocs / 1000 calls  ( 0.00 / call)

--- イテレーション ---
  each (4-field)                           0 allocs / 1000 calls  ( 0.00 / call)
  each_pair (4-field)                      0 allocs / 1000 calls  ( 0.00 / call)

--- その他 ---
  inspect (4-field)                     5000 allocs / 1000 calls  ( 5.00 / call)
  members (4-field)                     1000 allocs / 1000 calls  ( 1.00 / call)
  dig (4-field)                         1000 allocs / 1000 calls  ( 1.00 / call)
  values_at (4-field)                   6000 allocs / 1000 calls  ( 6.00 / call)

=== CPUプロファイル (100000 calls each) ===

--- インスタンス生成 ---
  new 1-field (positional)                 0.094 us/call  (0.0094 s total, 100000 calls)
  new 4-field (positional)                 0.118 us/call  (0.0118 s total, 100000 calls)
  new 8-field (positional)                 0.134 us/call  (0.0134 s total, 100000 calls)
  new 1-field (keyword)                    0.149 us/call  (0.0149 s total, 100000 calls)
  new 4-field (keyword)                    0.215 us/call  (0.0215 s total, 100000 calls)
  new 8-field (keyword)                    0.335 us/call  (0.0335 s total, 100000 calls)

--- アクセサ ---
  getter (4-field)                         0.069 us/call  (0.0069 s total, 100000 calls)
  [] symbol (4-field)                      0.220 us/call  (0.0220 s total, 100000 calls)
  [] index (4-field)                       0.169 us/call  (0.0169 s total, 100000 calls)
  setter (4-field)                         0.089 us/call  (0.0089 s total, 100000 calls)

--- 変換 ---
  to_a (4-field)                           0.057 us/call  (0.0057 s total, 100000 calls)
  to_h (4-field)                           0.089 us/call  (0.0089 s total, 100000 calls)

--- 比較 ---
  == (4-field)                             0.128 us/call  (0.0128 s total, 100000 calls)
  eql? (4-field)                           0.153 us/call  (0.0153 s total, 100000 calls)
  hash (4-field)                           0.082 us/call  (0.0082 s total, 100000 calls)

--- イテレーション ---
  each (4-field)                           0.101 us/call  (0.0101 s total, 100000 calls)
  each_pair (4-field)                      0.107 us/call  (0.0107 s total, 100000 calls)

--- その他 ---
  inspect (4-field)                        0.306 us/call  (0.0306 s total, 100000 calls)
  members (4-field)                        0.043 us/call  (0.0043 s total, 100000 calls)

=== GC圧力プロファイル (100000 calls each) ===
  new 4-field (positional)               1 GC runs  (0 ms GC time, 100000 calls)
  new 4-field (keyword)                  1 GC runs  (2 ms GC time, 100000 calls)
  to_a (4-field)                         4 GC runs  (2 ms GC time, 100000 calls)
  to_h (4-field)                         1 GC runs  (1 ms GC time, 100000 calls)
  inspect (4-field)                     23 GC runs  (4 ms GC time, 100000 calls)
  hash (4-field)                         0 GC runs  (0 ms GC time, 100000 calls)
```

---

## Iteration 1


### ベンチマーク結果
```
=== インスタンス生成 ===
ruby 3.4.8 (2025-12-17 revision 995b59f666) +PRISM [arm64-darwin25]
Warming up --------------------------------------
         new 1-field     1.147M i/100ms
         new 4-field   947.169k i/100ms
         new 8-field   759.089k i/100ms
         kw  1-field   755.518k i/100ms
         kw  4-field   476.222k i/100ms
         kw  8-field   314.527k i/100ms
Calculating -------------------------------------
         new 1-field     11.076M (± 1.4%) i/s   (90.28 ns/i) -     56.199M in   5.074828s
         new 4-field      8.924M (± 1.8%) i/s  (112.06 ns/i) -     45.464M in   5.096251s
         new 8-field      7.424M (± 1.3%) i/s  (134.70 ns/i) -     37.195M in   5.011108s
         kw  1-field      7.490M (± 1.2%) i/s  (133.51 ns/i) -     37.776M in   5.044162s
         kw  4-field      4.638M (± 1.2%) i/s  (215.59 ns/i) -     23.335M in   5.031483s
         kw  8-field      3.017M (± 2.1%) i/s  (331.42 ns/i) -     15.097M in   5.005933s

Comparison:
         new 1-field: 11076296.6 i/s
         new 4-field:  8923988.9 i/s - 1.24x  slower
         kw  1-field:  7490173.0 i/s - 1.48x  slower
         new 8-field:  7423936.1 i/s - 1.49x  slower
         kw  4-field:  4638473.1 i/s - 2.39x  slower
         kw  8-field:  3017347.8 i/s - 3.67x  slower


=== ゲッター ===
ruby 3.4.8 (2025-12-17 revision 995b59f666) +PRISM [arm64-darwin25]
Warming up --------------------------------------
              getter     1.752M i/100ms
           [] symbol   490.746k i/100ms
            [] index   621.542k i/100ms
Calculating -------------------------------------
              getter     17.628M (± 1.8%) i/s   (56.73 ns/i) -     89.364M in   5.071108s
           [] symbol      4.846M (± 2.0%) i/s  (206.37 ns/i) -     24.537M in   5.066022s
            [] index      6.137M (± 1.4%) i/s  (162.94 ns/i) -     31.077M in   5.064755s

Comparison:
              getter: 17628049.7 i/s
            [] index:  6137173.2 i/s - 2.87x  slower
           [] symbol:  4845586.6 i/s - 3.64x  slower


=== セッター ===
ruby 3.4.8 (2025-12-17 revision 995b59f666) +PRISM [arm64-darwin25]
Warming up --------------------------------------
              setter     1.234M i/100ms
          []= symbol   442.819k i/100ms
           []= index   563.861k i/100ms
Calculating -------------------------------------
              setter     12.138M (± 1.9%) i/s   (82.39 ns/i) -     61.678M in   5.083263s
          []= symbol      4.397M (± 1.9%) i/s  (227.45 ns/i) -     22.141M in   5.037997s
           []= index      5.473M (± 2.4%) i/s  (182.73 ns/i) -     27.629M in   5.051625s

Comparison:
              setter: 12137928.1 i/s
           []= index:  5472671.2 i/s - 2.22x  slower
          []= symbol:  4396507.7 i/s - 2.76x  slower


=== 変換 ===
ruby 3.4.8 (2025-12-17 revision 995b59f666) +PRISM [arm64-darwin25]
Warming up --------------------------------------
        to_a 4-field     1.856M i/100ms
        to_h 4-field     1.193M i/100ms
Calculating -------------------------------------
        to_a 4-field     18.765M (± 1.0%) i/s   (53.29 ns/i) -     94.650M in   5.044345s
        to_h 4-field     11.792M (± 2.8%) i/s   (84.80 ns/i) -     59.659M in   5.063386s

Comparison:
        to_a 4-field: 18765395.7 i/s
        to_h 4-field: 11792324.5 i/s - 1.59x  slower


=== 等値比較 ===
ruby 3.4.8 (2025-12-17 revision 995b59f666) +PRISM [arm64-darwin25]
Warming up --------------------------------------
          == 4-field   820.661k i/100ms
        eql? 4-field   694.039k i/100ms
        hash 4-field     1.305M i/100ms
Calculating -------------------------------------
          == 4-field      8.209M (± 1.0%) i/s  (121.82 ns/i) -     41.854M in   5.099099s
        eql? 4-field      6.883M (± 1.4%) i/s  (145.29 ns/i) -     34.702M in   5.042781s
        hash 4-field     12.793M (± 2.1%) i/s   (78.17 ns/i) -     63.938M in   4.999981s

Comparison:
        hash 4-field: 12793343.3 i/s
          == 4-field:  8208971.2 i/s - 1.56x  slower
        eql? 4-field:  6882872.2 i/s - 1.86x  slower


=== イテレーション ===
ruby 3.4.8 (2025-12-17 revision 995b59f666) +PRISM [arm64-darwin25]
Warming up --------------------------------------
        each 4-field     1.052M i/100ms
   each_pair 4-field     1.030M i/100ms
Calculating -------------------------------------
        each 4-field     10.557M (± 1.1%) i/s   (94.72 ns/i) -     53.653M in   5.082673s
   each_pair 4-field     10.256M (± 1.7%) i/s   (97.50 ns/i) -     51.522M in   5.025003s

Comparison:
        each 4-field: 10557343.0 i/s
   each_pair 4-field: 10256150.3 i/s - 1.03x  slower


=== inspect ===
ruby 3.4.8 (2025-12-17 revision 995b59f666) +PRISM [arm64-darwin25]
Warming up --------------------------------------
     inspect 4-field   318.063k i/100ms
Calculating -------------------------------------
     inspect 4-field      3.176M (± 3.0%) i/s  (314.91 ns/i) -     15.903M in   5.012904s
```

### プロファイル結果
```
=== メモリプロファイル: アロケーション (1000 calls each) ===

--- インスタンス生成 ---
  new 1-field (positional)              1001 allocs / 1000 calls  ( 1.00 / call)
  new 4-field (positional)              1000 allocs / 1000 calls  ( 1.00 / call)
  new 8-field (positional)              1000 allocs / 1000 calls  ( 1.00 / call)
  new 1-field (keyword)                 2000 allocs / 1000 calls  ( 2.00 / call)
  new 4-field (keyword)                 2000 allocs / 1000 calls  ( 2.00 / call)
  new 8-field (keyword)                 2000 allocs / 1000 calls  ( 2.00 / call)

--- アクセサ ---
  getter (4-field)                         0 allocs / 1000 calls  ( 0.00 / call)
  [] symbol (4-field)                      0 allocs / 1000 calls  ( 0.00 / call)
  [] index (4-field)                       0 allocs / 1000 calls  ( 0.00 / call)
  setter (4-field)                         0 allocs / 1000 calls  ( 0.00 / call)
  []= symbol (4-field)                     0 allocs / 1000 calls  ( 0.00 / call)
  []= index (4-field)                      0 allocs / 1000 calls  ( 0.00 / call)

--- 変換 ---
  to_a (4-field)                        1000 allocs / 1000 calls  ( 1.00 / call)
  to_h (4-field)                        1000 allocs / 1000 calls  ( 1.00 / call)
  to_a (8-field)                        1000 allocs / 1000 calls  ( 1.00 / call)
  to_h (8-field)                        1000 allocs / 1000 calls  ( 1.00 / call)

--- 比較 ---
  == (4-field)                             0 allocs / 1000 calls  ( 0.00 / call)
  eql? (4-field)                           0 allocs / 1000 calls  ( 0.00 / call)
  hash (4-field)                           0 allocs / 1000 calls  ( 0.00 / call)

--- イテレーション ---
  each (4-field)                           0 allocs / 1000 calls  ( 0.00 / call)
  each_pair (4-field)                      0 allocs / 1000 calls  ( 0.00 / call)

--- その他 ---
  inspect (4-field)                     5000 allocs / 1000 calls  ( 5.00 / call)
  members (4-field)                     1000 allocs / 1000 calls  ( 1.00 / call)
  dig (4-field)                         1000 allocs / 1000 calls  ( 1.00 / call)
  values_at (4-field)                   6000 allocs / 1000 calls  ( 6.00 / call)

=== CPUプロファイル (100000 calls each) ===

--- インスタンス生成 ---
  new 1-field (positional)                 0.086 us/call  (0.0086 s total, 100000 calls)
  new 4-field (positional)                 0.109 us/call  (0.0109 s total, 100000 calls)
  new 8-field (positional)                 0.128 us/call  (0.0128 s total, 100000 calls)
  new 1-field (keyword)                    0.142 us/call  (0.0142 s total, 100000 calls)
  new 4-field (keyword)                    0.200 us/call  (0.0200 s total, 100000 calls)
  new 8-field (keyword)                    0.319 us/call  (0.0319 s total, 100000 calls)

--- アクセサ ---
  getter (4-field)                         0.068 us/call  (0.0068 s total, 100000 calls)
  [] symbol (4-field)                      0.213 us/call  (0.0213 s total, 100000 calls)
  [] index (4-field)                       0.174 us/call  (0.0174 s total, 100000 calls)
  setter (4-field)                         0.092 us/call  (0.0092 s total, 100000 calls)

--- 変換 ---
  to_a (4-field)                           0.053 us/call  (0.0053 s total, 100000 calls)
  to_h (4-field)                           0.082 us/call  (0.0082 s total, 100000 calls)

--- 比較 ---
  == (4-field)                             0.127 us/call  (0.0127 s total, 100000 calls)
  eql? (4-field)                           0.152 us/call  (0.0152 s total, 100000 calls)
  hash (4-field)                           0.079 us/call  (0.0079 s total, 100000 calls)

--- イテレーション ---
  each (4-field)                           0.099 us/call  (0.0099 s total, 100000 calls)
  each_pair (4-field)                      0.104 us/call  (0.0104 s total, 100000 calls)

--- その他 ---
  inspect (4-field)                        0.301 us/call  (0.0301 s total, 100000 calls)
  members (4-field)                        0.041 us/call  (0.0041 s total, 100000 calls)

=== GC圧力プロファイル (100000 calls each) ===
  new 4-field (positional)               1 GC runs  (0 ms GC time, 100000 calls)
  new 4-field (keyword)                  1 GC runs  (1 ms GC time, 100000 calls)
  to_a (4-field)                         4 GC runs  (1 ms GC time, 100000 calls)
  to_h (4-field)                         1 GC runs  (1 ms GC time, 100000 calls)
  inspect (4-field)                     23 GC runs  (4 ms GC time, 100000 calls)
  hash (4-field)                         0 GC runs  (0 ms GC time, 100000 calls)
```

### コード差分
```diff

```

---

## Iteration 2


### ベンチマーク結果
```
=== インスタンス生成 ===
ruby 3.4.8 (2025-12-17 revision 995b59f666) +PRISM [arm64-darwin25]
Warming up --------------------------------------
         new 1-field     1.124M i/100ms
         new 4-field   940.298k i/100ms
         new 8-field   764.181k i/100ms
         kw  1-field   766.144k i/100ms
         kw  4-field   469.922k i/100ms
         kw  8-field   297.346k i/100ms
Calculating -------------------------------------
         new 1-field     10.923M (± 1.3%) i/s   (91.55 ns/i) -     55.092M in   5.044774s
         new 4-field      8.745M (± 2.1%) i/s  (114.35 ns/i) -     44.194M in   5.056235s
         new 8-field      7.404M (± 1.0%) i/s  (135.05 ns/i) -     37.445M in   5.057553s
         kw  1-field      7.323M (± 1.8%) i/s  (136.56 ns/i) -     36.775M in   5.023863s
         kw  4-field      4.665M (± 1.0%) i/s  (214.38 ns/i) -     23.496M in   5.037686s
         kw  8-field      3.006M (± 2.5%) i/s  (332.63 ns/i) -     15.165M in   5.047671s

Comparison:
         new 1-field: 10922535.0 i/s
         new 4-field:  8744733.1 i/s - 1.25x  slower
         new 8-field:  7404475.0 i/s - 1.48x  slower
         kw  1-field:  7322525.1 i/s - 1.49x  slower
         kw  4-field:  4664513.0 i/s - 2.34x  slower
         kw  8-field:  3006348.4 i/s - 3.63x  slower


=== ゲッター ===
ruby 3.4.8 (2025-12-17 revision 995b59f666) +PRISM [arm64-darwin25]
Warming up --------------------------------------
              getter     1.714M i/100ms
           [] symbol   487.517k i/100ms
            [] index   611.067k i/100ms
Calculating -------------------------------------
              getter     17.126M (± 1.4%) i/s   (58.39 ns/i) -     85.708M in   5.005526s
           [] symbol      4.881M (± 1.2%) i/s  (204.89 ns/i) -     24.863M in   5.095170s
            [] index      6.070M (± 2.2%) i/s  (164.74 ns/i) -     30.553M in   5.036031s

Comparison:
              getter: 17125988.0 i/s
            [] index:  6070068.6 i/s - 2.82x  slower
           [] symbol:  4880581.1 i/s - 3.51x  slower


=== セッター ===
ruby 3.4.8 (2025-12-17 revision 995b59f666) +PRISM [arm64-darwin25]
Warming up --------------------------------------
              setter     1.220M i/100ms
          []= symbol   442.100k i/100ms
           []= index   545.914k i/100ms
Calculating -------------------------------------
              setter     12.182M (± 0.8%) i/s   (82.09 ns/i) -     61.012M in   5.008947s
          []= symbol      4.419M (± 1.3%) i/s  (226.28 ns/i) -     22.105M in   5.002724s
           []= index      5.396M (± 1.9%) i/s  (185.31 ns/i) -     27.296M in   5.059941s

Comparison:
              setter: 12181522.6 i/s
           []= index:  5396388.1 i/s - 2.26x  slower
          []= symbol:  4419333.4 i/s - 2.76x  slower


=== 変換 ===
ruby 3.4.8 (2025-12-17 revision 995b59f666) +PRISM [arm64-darwin25]
Warming up --------------------------------------
        to_a 4-field     1.848M i/100ms
        to_h 4-field     1.193M i/100ms
Calculating -------------------------------------
        to_a 4-field     18.433M (± 1.6%) i/s   (54.25 ns/i) -     92.396M in   5.013835s
        to_h 4-field     11.970M (± 0.8%) i/s   (83.54 ns/i) -     60.854M in   5.084059s

Comparison:
        to_a 4-field: 18433165.1 i/s
        to_h 4-field: 11970492.0 i/s - 1.54x  slower


=== 等値比較 ===
ruby 3.4.8 (2025-12-17 revision 995b59f666) +PRISM [arm64-darwin25]
Warming up --------------------------------------
          == 4-field   818.924k i/100ms
        eql? 4-field   663.093k i/100ms
        hash 4-field     1.251M i/100ms
Calculating -------------------------------------
          == 4-field      8.141M (± 1.2%) i/s  (122.83 ns/i) -     40.946M in   5.030313s
        eql? 4-field      6.976M (± 0.7%) i/s  (143.35 ns/i) -     35.144M in   5.038159s
        hash 4-field     12.982M (± 1.4%) i/s   (77.03 ns/i) -     65.071M in   5.013338s

Comparison:
        hash 4-field: 12982227.1 i/s
          == 4-field:  8141202.3 i/s - 1.59x  slower
        eql? 4-field:  6975945.1 i/s - 1.86x  slower


=== イテレーション ===
ruby 3.4.8 (2025-12-17 revision 995b59f666) +PRISM [arm64-darwin25]
Warming up --------------------------------------
        each 4-field     1.075M i/100ms
   each_pair 4-field     1.020M i/100ms
Calculating -------------------------------------
        each 4-field     10.638M (± 1.2%) i/s   (94.00 ns/i) -     53.747M in   5.053261s
   each_pair 4-field     10.363M (± 1.4%) i/s   (96.50 ns/i) -     52.009M in   5.019997s

Comparison:
        each 4-field: 10637884.2 i/s
   each_pair 4-field: 10362534.6 i/s - same-ish: difference falls within error


=== inspect ===
ruby 3.4.8 (2025-12-17 revision 995b59f666) +PRISM [arm64-darwin25]
Warming up --------------------------------------
     inspect 4-field   321.221k i/100ms
Calculating -------------------------------------
     inspect 4-field      3.228M (± 0.9%) i/s  (309.75 ns/i) -     16.382M in   5.074832s
```

### プロファイル結果
```
=== メモリプロファイル: アロケーション (1000 calls each) ===

--- インスタンス生成 ---
  new 1-field (positional)              1001 allocs / 1000 calls  ( 1.00 / call)
  new 4-field (positional)              1000 allocs / 1000 calls  ( 1.00 / call)
  new 8-field (positional)              1000 allocs / 1000 calls  ( 1.00 / call)
  new 1-field (keyword)                 2000 allocs / 1000 calls  ( 2.00 / call)
  new 4-field (keyword)                 2000 allocs / 1000 calls  ( 2.00 / call)
  new 8-field (keyword)                 2000 allocs / 1000 calls  ( 2.00 / call)

--- アクセサ ---
  getter (4-field)                         0 allocs / 1000 calls  ( 0.00 / call)
  [] symbol (4-field)                      0 allocs / 1000 calls  ( 0.00 / call)
  [] index (4-field)                       0 allocs / 1000 calls  ( 0.00 / call)
  setter (4-field)                         0 allocs / 1000 calls  ( 0.00 / call)
  []= symbol (4-field)                     0 allocs / 1000 calls  ( 0.00 / call)
  []= index (4-field)                      0 allocs / 1000 calls  ( 0.00 / call)

--- 変換 ---
  to_a (4-field)                        1000 allocs / 1000 calls  ( 1.00 / call)
  to_h (4-field)                        1000 allocs / 1000 calls  ( 1.00 / call)
  to_a (8-field)                        1000 allocs / 1000 calls  ( 1.00 / call)
  to_h (8-field)                        1000 allocs / 1000 calls  ( 1.00 / call)

--- 比較 ---
  == (4-field)                             0 allocs / 1000 calls  ( 0.00 / call)
  eql? (4-field)                           0 allocs / 1000 calls  ( 0.00 / call)
  hash (4-field)                           0 allocs / 1000 calls  ( 0.00 / call)

--- イテレーション ---
  each (4-field)                           0 allocs / 1000 calls  ( 0.00 / call)
  each_pair (4-field)                      0 allocs / 1000 calls  ( 0.00 / call)

--- その他 ---
  inspect (4-field)                     5000 allocs / 1000 calls  ( 5.00 / call)
  members (4-field)                     1000 allocs / 1000 calls  ( 1.00 / call)
  dig (4-field)                         1000 allocs / 1000 calls  ( 1.00 / call)
  values_at (4-field)                   6000 allocs / 1000 calls  ( 6.00 / call)

=== CPUプロファイル (100000 calls each) ===

--- インスタンス生成 ---
  new 1-field (positional)                 0.087 us/call  (0.0087 s total, 100000 calls)
  new 4-field (positional)                 0.113 us/call  (0.0113 s total, 100000 calls)
  new 8-field (positional)                 0.129 us/call  (0.0129 s total, 100000 calls)
  new 1-field (keyword)                    0.144 us/call  (0.0144 s total, 100000 calls)
  new 4-field (keyword)                    0.201 us/call  (0.0201 s total, 100000 calls)
  new 8-field (keyword)                    0.321 us/call  (0.0321 s total, 100000 calls)

--- アクセサ ---
  getter (4-field)                         0.068 us/call  (0.0068 s total, 100000 calls)
  [] symbol (4-field)                      0.210 us/call  (0.0210 s total, 100000 calls)
  [] index (4-field)                       0.171 us/call  (0.0171 s total, 100000 calls)
  setter (4-field)                         0.091 us/call  (0.0091 s total, 100000 calls)

--- 変換 ---
  to_a (4-field)                           0.053 us/call  (0.0053 s total, 100000 calls)
  to_h (4-field)                           0.082 us/call  (0.0082 s total, 100000 calls)

--- 比較 ---
  == (4-field)                             0.130 us/call  (0.0130 s total, 100000 calls)
  eql? (4-field)                           0.152 us/call  (0.0152 s total, 100000 calls)
  hash (4-field)                           0.081 us/call  (0.0081 s total, 100000 calls)

--- イテレーション ---
  each (4-field)                           0.101 us/call  (0.0101 s total, 100000 calls)
  each_pair (4-field)                      0.105 us/call  (0.0105 s total, 100000 calls)

--- その他 ---
  inspect (4-field)                        0.299 us/call  (0.0299 s total, 100000 calls)
  members (4-field)                        0.041 us/call  (0.0041 s total, 100000 calls)

=== GC圧力プロファイル (100000 calls each) ===
  new 4-field (positional)               1 GC runs  (1 ms GC time, 100000 calls)
  new 4-field (keyword)                  1 GC runs  (1 ms GC time, 100000 calls)
  to_a (4-field)                         4 GC runs  (1 ms GC time, 100000 calls)
  to_h (4-field)                         1 GC runs  (0 ms GC time, 100000 calls)
  inspect (4-field)                     23 GC runs  (6 ms GC time, 100000 calls)
  hash (4-field)                         0 GC runs  (0 ms GC time, 100000 calls)
```

### コード差分
```diff

```

---

## Iteration 3

### アプローチ
- `[]` / `[]=` メソッドのネスト型 case/when（型チェック→値チェック の2段構造）をフラット化し、全メンバー（Symbol/Integer/String）をトップレベルの単一 case/when にまとめてディスパッチ層を削減
- `==` / `eql?` で `other.is_a?(self.class)`（祖先チェーン走査）を `other.class.equal?(self.class)`（ポインタ比較）に変更
- `to_h` のブロック版で中間ハッシュ生成を除去し、メンバーごとに直接 yield して結果を組み立て
- `select` / `filter` で `to_a.select` の中間配列生成を除去し、インスタンス変数から直接 yield
- `inspect` のローカル変数 `klass_name` 代入を省略して直接インライン化
- 全メソッド定義を単一の `code` 文字列にまとめ、1回の `class_eval` で一括パース・コンパイル（複数回の `class_eval` 呼び出しオーバーヘッドを削減）

### 変更点
- `[]` メソッド: ネスト `case key when Integer; case key when 0...` → フラット `case key when :a... when 0... when 'a'...` に変更。else 節で `is_a?` による型判定でエラー種別を分岐
- `[]=` メソッド: 同様にフラット化
- `==` / `eql?`: `return false unless other.is_a?(self.class)` → `other.class.equal?(self.class) && ...` に変更（短絡評価で1行に統合）
- `to_h` ブロック版: `{...}.to_h { |k, v| yield k, v }` → `h = {}; k, v = yield :m, @m; h[k] = v; ... ; h` に変更
- `select`: `to_a.select { |v| yield v }` → `r = []; r << @m if yield(@m); ...; r` に変更
- `inspect`: `klass_name = self.class.name || "struct"` → `self.class.name || 'struct'` をインライン化
- 複数の `klass.class_eval <<~RUBY ... RUBY` → 単一 `code` 文字列に統合し `klass.class_eval(code, ...)` 1回で評価

### ベンチマーク結果
```
=== インスタンス生成 ===
ruby 3.4.8 (2025-12-17 revision 995b59f666) +PRISM [arm64-darwin25]
Warming up --------------------------------------
         new 1-field     1.135M i/100ms
         new 4-field   931.035k i/100ms
         new 8-field   765.026k i/100ms
         kw  1-field   754.574k i/100ms
         kw  4-field   476.707k i/100ms
         kw  8-field   313.075k i/100ms
Calculating -------------------------------------
         new 1-field     10.891M (± 1.8%) i/s   (91.82 ns/i) -     54.457M in   5.001739s
         new 4-field      8.765M (± 1.4%) i/s  (114.09 ns/i) -     44.690M in   5.099710s
         new 8-field      7.422M (± 1.5%) i/s  (134.74 ns/i) -     37.486M in   5.052069s
         kw  1-field      7.417M (± 1.3%) i/s  (134.82 ns/i) -     37.729M in   5.087625s
         kw  4-field      4.622M (± 2.6%) i/s  (216.34 ns/i) -     23.359M in   5.057020s
         kw  8-field      3.028M (± 1.3%) i/s  (330.24 ns/i) -     15.341M in   5.066871s

Comparison:
         new 1-field: 10891298.2 i/s
         new 4-field:  8764918.3 i/s - 1.24x  slower
         new 8-field:  7421685.7 i/s - 1.47x  slower
         kw  1-field:  7417045.5 i/s - 1.47x  slower
         kw  4-field:  4622429.0 i/s - 2.36x  slower
         kw  8-field:  3028145.0 i/s - 3.60x  slower


=== ゲッター ===
ruby 3.4.8 (2025-12-17 revision 995b59f666) +PRISM [arm64-darwin25]
Warming up --------------------------------------
              getter     1.752M i/100ms
           [] symbol   899.079k i/100ms
            [] index   897.513k i/100ms
Calculating -------------------------------------
              getter     17.566M (± 1.2%) i/s   (56.93 ns/i) -     89.332M in   5.086112s
           [] symbol      8.952M (± 1.9%) i/s  (111.71 ns/i) -     44.954M in   5.023769s
            [] index      9.007M (± 1.1%) i/s  (111.03 ns/i) -     45.773M in   5.082700s

Comparison:
              getter: 17566438.7 i/s
            [] index:  9006797.3 i/s - 1.95x  slower
           [] symbol:  8951606.2 i/s - 1.96x  slower


=== セッター ===
ruby 3.4.8 (2025-12-17 revision 995b59f666) +PRISM [arm64-darwin25]
Warming up --------------------------------------
              setter     1.243M i/100ms
          []= symbol   762.259k i/100ms
           []= index   769.840k i/100ms
Calculating -------------------------------------
              setter     12.071M (± 1.4%) i/s   (82.84 ns/i) -     60.917M in   5.047488s
          []= symbol      7.377M (± 1.5%) i/s  (135.55 ns/i) -     37.351M in   5.064175s
           []= index      7.830M (± 0.7%) i/s  (127.71 ns/i) -     39.262M in   5.014420s

Comparison:
              setter: 12071318.6 i/s
           []= index:  7830215.3 i/s - 1.54x  slower
          []= symbol:  7377261.7 i/s - 1.64x  slower


=== 変換 ===
ruby 3.4.8 (2025-12-17 revision 995b59f666) +PRISM [arm64-darwin25]
Warming up --------------------------------------
        to_a 4-field     1.863M i/100ms
        to_h 4-field     1.142M i/100ms
Calculating -------------------------------------
        to_a 4-field     18.834M (± 1.4%) i/s   (53.09 ns/i) -     95.020M in   5.046161s
        to_h 4-field     11.167M (± 3.2%) i/s   (89.55 ns/i) -     55.960M in   5.016612s

Comparison:
        to_a 4-field: 18834192.2 i/s
        to_h 4-field: 11167278.9 i/s - 1.69x  slower


=== 等値比較 ===
ruby 3.4.8 (2025-12-17 revision 995b59f666) +PRISM [arm64-darwin25]
Warming up --------------------------------------
          == 4-field   775.373k i/100ms
        eql? 4-field   669.663k i/100ms
        hash 4-field     1.302M i/100ms
Calculating -------------------------------------
          == 4-field      7.666M (± 0.9%) i/s  (130.44 ns/i) -     38.769M in   5.057581s
        eql? 4-field      6.590M (± 1.8%) i/s  (151.75 ns/i) -     33.483M in   5.082829s
        hash 4-field     12.916M (± 1.5%) i/s   (77.42 ns/i) -     65.104M in   5.041647s

Comparison:
        hash 4-field: 12916352.9 i/s
          == 4-field:  7666086.9 i/s - 1.68x  slower
        eql? 4-field:  6589778.0 i/s - 1.96x  slower


=== イテレーション ===
ruby 3.4.8 (2025-12-17 revision 995b59f666) +PRISM [arm64-darwin25]
Warming up --------------------------------------
        each 4-field     1.047M i/100ms
   each_pair 4-field     1.039M i/100ms
Calculating -------------------------------------
        each 4-field     10.584M (± 1.0%) i/s   (94.48 ns/i) -     53.418M in   5.047486s
   each_pair 4-field     10.293M (± 1.5%) i/s   (97.15 ns/i) -     51.941M in   5.047303s

Comparison:
        each 4-field: 10584137.1 i/s
   each_pair 4-field: 10293426.2 i/s - 1.03x  slower


=== inspect ===
ruby 3.4.8 (2025-12-17 revision 995b59f666) +PRISM [arm64-darwin25]
Warming up --------------------------------------
     inspect 4-field   311.036k i/100ms
Calculating -------------------------------------
     inspect 4-field      3.159M (± 2.6%) i/s  (316.51 ns/i) -     15.863M in   5.024117s
```

### プロファイル結果
```
=== メモリプロファイル: アロケーション (1000 calls each) ===

--- インスタンス生成 ---
  new 1-field (positional)              1001 allocs / 1000 calls  ( 1.00 / call)
  new 4-field (positional)              1000 allocs / 1000 calls  ( 1.00 / call)
  new 8-field (positional)              1000 allocs / 1000 calls  ( 1.00 / call)
  new 1-field (keyword)                 2000 allocs / 1000 calls  ( 2.00 / call)
  new 4-field (keyword)                 2000 allocs / 1000 calls  ( 2.00 / call)
  new 8-field (keyword)                 2000 allocs / 1000 calls  ( 2.00 / call)

--- アクセサ ---
  getter (4-field)                         0 allocs / 1000 calls  ( 0.00 / call)
  [] symbol (4-field)                      0 allocs / 1000 calls  ( 0.00 / call)
  [] index (4-field)                       0 allocs / 1000 calls  ( 0.00 / call)
  setter (4-field)                         0 allocs / 1000 calls  ( 0.00 / call)
  []= symbol (4-field)                     0 allocs / 1000 calls  ( 0.00 / call)
  []= index (4-field)                      0 allocs / 1000 calls  ( 0.00 / call)

--- 変換 ---
  to_a (4-field)                        1000 allocs / 1000 calls  ( 1.00 / call)
  to_h (4-field)                        1000 allocs / 1000 calls  ( 1.00 / call)
  to_a (8-field)                        1000 allocs / 1000 calls  ( 1.00 / call)
  to_h (8-field)                        1000 allocs / 1000 calls  ( 1.00 / call)

--- 比較 ---
  == (4-field)                             0 allocs / 1000 calls  ( 0.00 / call)
  eql? (4-field)                           0 allocs / 1000 calls  ( 0.00 / call)
  hash (4-field)                           0 allocs / 1000 calls  ( 0.00 / call)

--- イテレーション ---
  each (4-field)                           0 allocs / 1000 calls  ( 0.00 / call)
  each_pair (4-field)                      0 allocs / 1000 calls  ( 0.00 / call)

--- その他 ---
  inspect (4-field)                     5000 allocs / 1000 calls  ( 5.00 / call)
  members (4-field)                     1000 allocs / 1000 calls  ( 1.00 / call)
  dig (4-field)                         1000 allocs / 1000 calls  ( 1.00 / call)
  values_at (4-field)                   6000 allocs / 1000 calls  ( 6.00 / call)

=== CPUプロファイル (100000 calls each) ===

--- インスタンス生成 ---
  new 1-field (positional)                 0.092 us/call  (0.0092 s total, 100000 calls)
  new 4-field (positional)                 0.113 us/call  (0.0113 s total, 100000 calls)
  new 8-field (positional)                 0.133 us/call  (0.0133 s total, 100000 calls)
  new 1-field (keyword)                    0.138 us/call  (0.0138 s total, 100000 calls)
  new 4-field (keyword)                    0.203 us/call  (0.0203 s total, 100000 calls)
  new 8-field (keyword)                    0.324 us/call  (0.0324 s total, 100000 calls)

--- アクセサ ---
  getter (4-field)                         0.069 us/call  (0.0069 s total, 100000 calls)
  [] symbol (4-field)                      0.118 us/call  (0.0118 s total, 100000 calls)
  [] index (4-field)                       0.114 us/call  (0.0114 s total, 100000 calls)
  setter (4-field)                         0.092 us/call  (0.0092 s total, 100000 calls)

--- 変換 ---
  to_a (4-field)                           0.054 us/call  (0.0054 s total, 100000 calls)
  to_h (4-field)                           0.086 us/call  (0.0086 s total, 100000 calls)

--- 比較 ---
  == (4-field)                             0.134 us/call  (0.0134 s total, 100000 calls)
  eql? (4-field)                           0.155 us/call  (0.0155 s total, 100000 calls)
  hash (4-field)                           0.080 us/call  (0.0080 s total, 100000 calls)

--- イテレーション ---
  each (4-field)                           0.100 us/call  (0.0100 s total, 100000 calls)
  each_pair (4-field)                      0.101 us/call  (0.0101 s total, 100000 calls)

--- その他 ---
  inspect (4-field)                        0.292 us/call  (0.0292 s total, 100000 calls)
  members (4-field)                        0.040 us/call  (0.0040 s total, 100000 calls)

=== GC圧力プロファイル (100000 calls each) ===
  new 4-field (positional)               1 GC runs  (0 ms GC time, 100000 calls)
  new 4-field (keyword)                  1 GC runs  (1 ms GC time, 100000 calls)
  to_a (4-field)                         4 GC runs  (2 ms GC time, 100000 calls)
  to_h (4-field)                         1 GC runs  (1 ms GC time, 100000 calls)
  inspect (4-field)                     23 GC runs  (5 ms GC time, 100000 calls)
  hash (4-field)                         0 GC runs  (0 ms GC time, 100000 calls)
```

### コード差分
```diff
--- ruby_struct.rb.baseline
+++ ruby_struct.rb
@@ -1,5 +1,6 @@
 # RubyのStructをプレーンRubyで再実装したクラス
-# class_eval による文字列ベースのメソッド生成でVMネイティブ最適縖パスに乗せる
+# class_eval による文字列ベースのメソッド生成でVMネイティブ最適化パスに乗せる
+# フラット化された case/when と identity チェックで高速ディスパッチを実現
 class RubyStruct
   def self.new(*members, keyword_init: false, &block)
     class_name = nil
@@ -23,207 +24,163 @@
 
     klass = Class.new
     member_count = members.length
-    ivar_names = members.map { |m| "@#{m}" }
-    members_sym_literal = "[#{members.map { |m| ":#{m}" }.join(', ')}]"
+    members_literal = "[#{members.map { |m| ":#{m}" }.join(', ')}]"
 
-    klass.class_eval <<~RUBY, __FILE__, __LINE__ + 1
-      def self.members; #{members_sym_literal}; end
-      def self.keyword_init?; #{keyword_init}; end
-    RUBY
+    # 全メソッド定義を単一文字列にまとめ、一括 class_eval でパース・コンパイルオーバーヘッドを削減
+    code = +""
 
+    # クラスメソッド: members, keyword_init?
+    code << "def self.members; #{members_literal}; end\n"
+    code << "def self.keyword_init?; #{keyword_init}; end\n"
+
+    # クラスメソッド: [] ショートカット
     if keyword_init
-      kw_params_b = members.map { |m| "#{m}: nil" }.join(", ")
-      kw_pass_b = members.map { |m| "#{m}: #{m}" }.join(", ")
-      klass.class_eval <<~RUBY, __FILE__, __LINE__ + 1
-        def self.[](#{kw_params_b})
-          new(#{kw_pass_b})
-        end
-      RUBY
+      kw_params = members.map { |m| "#{m}: nil" }.join(", ")
+      kw_pass = members.map { |m| "#{m}: #{m}" }.join(", ")
+      code << "def self.[](#{kw_params}); new(#{kw_pass}); end\n"
     else
-      pos_params_b = members.map { |m| "#{m}=nil" }.join(", ")
-      pos_pass_b = members.join(", ")
-      klass.class_eval <<~RUBY, __FILE__, __LINE__ + 1
-        def self.[](#{pos_params_b})
-          new(#{pos_pass_b})
-        end
-      RUBY
+      pos_params = members.map { |m| "#{m}=nil" }.join(", ")
+      pos_pass = members.join(", ")
+      code << "def self.[](#{pos_params}); new(#{pos_pass}); end\n"
     end
 
+    # initialize: 固定引数シグネチャで splat オーバーヘッドを回避
     if keyword_init
       kw_params = members.map { |m| "#{m}: nil" }.join(", ")
-      kw_assigns = members.map { |m| "  @#{m} = #{m}" }.join("\n")
-      klass.class_eval <<~RUBY, __FILE__, __LINE__ + 1
-        def initialize(#{kw_params})
-        #{kw_assigns}
-        end
-      RUBY
+      kw_assigns = members.map { |m| "@#{m} = #{m}" }.join("; ")
+      code << "def initialize(#{kw_params}); #{kw_assigns}; end\n"
     else
       pos_params = members.map { |m| "#{m}=nil" }.join(", ")
-      pos_assigns = members.map { |m| "  @#{m} = #{m}" }.join("\n")
-      klass.class_eval <<~RUBY, __FILE__, __LINE__ + 1
-        def initialize(#{pos_params})
-        #{pos_assigns}
-        end
-      RUBY
+      pos_assigns = members.map { |m| "@#{m} = #{m}" }.join("; ")
+      code << "def initialize(#{pos_params}); #{pos_assigns}; end\n"
     end
 
-    accessor_code = members.map { |m|
-      "def #{m}; @#{m}; end\ndef #{m}=(v); @#{m} = v; end"
-    }.join("\n")
-    klass.class_eval accessor_code, __FILE__, __LINE__ + 1
+    # アクセサ: ゲッター・セッター（VM インライン化対象）
+    members.each do |m|
+      code << "def #{m}; @#{m}; end\n"
+      code << "def #{m}=(v); @#{m} = v; end\n"
+    end
 
-    index_cases = members.each_with_index.map { |m, i|
-      "    when #{i}, #{i - member_count} then @#{m}"
+    # [] メソッド: フラット化 case/when でシンボルアクセスを高速化
+    sym_get = members.map { |m| "when :#{m} then @#{m}" }.join("\n")
+    idx_get = members.each_with_index.map { |m, i|
+      "when #{i}, #{i - member_count} then @#{m}"
     }.join("\n")
-    symbol_cases = members.map { |m|
-      "    when :#{m} then @#{m}"
-    }.join("\n")
-    string_cases = members.map { |m|
-      "    when '#{m}' then @#{m}"
-    }.join("\n")
+    str_get = members.map { |m| "when '#{m}' then @#{m}" }.join("\n")
 
-    klass.class_eval <<~RUBY, __FILE__, __LINE__ + 1
+    code << <<~RUBY
       def [](key)
         case key
-        when Integer
-          case key
-      #{index_cases}
-          else
+        #{sym_get}
+        #{idx_get}
+        #{str_get}
+        else
+          if key.is_a?(Integer)
             raise IndexError, "offset \#{key} too large for struct(size:#{member_count})"
-          end
-        when Symbol
-          case key
-      #{symbol_cases}
-          else
+          elsif key.is_a?(Symbol) || key.is_a?(String)
             raise NameError, "no member '\#{key}' in struct"
-          end
-        when String
-          case key
-      #{string_cases}
           else
-            raise NameError, "no member '\#{key}' in struct"
+            raise TypeError, "no implicit conversion of \#{key.class} into Integer"
           end
-        else
-          raise TypeError, "no implicit conversion of \#{key.class} into Integer"
         end
       end
     RUBY
 
-    index_set_cases = members.each_with_index.map { |m, i|
-      "    when #{i}, #{i - member_count} then @#{m} = value"
+    # []= メソッド: 同様にフラット化
+    sym_set = members.map { |m| "when :#{m} then @#{m} = value" }.join("\n")
+    idx_set = members.each_with_index.map { |m, i|
+      "when #{i}, #{i - member_count} then @#{m} = value"
     }.join("\n")
-    symbol_set_cases = members.map { |m|
-      "    when :#{m} then @#{m} = value"
-    }.join("\n")
-    string_set_cases = members.map { |m|
-      "    when '#{m}' then @#{m} = value"
-    }.join("\n")
+    str_set = members.map { |m| "when '#{m}' then @#{m} = value" }.join("\n")
 
-    klass.class_eval <<~RUBY, __FILE__, __LINE__ + 1
+    code << <<~RUBY
       def []=(key, value)
         case key
-        when Integer
-          case key
-      #{index_set_cases}
-          else
+        #{sym_set}
+        #{idx_set}
+        #{str_set}
+        else
+          if key.is_a?(Integer)
             raise IndexError, "offset \#{key} too large for struct(size:#{member_count})"
-          end
-        when Symbol
-          case key
-      #{symbol_set_cases}
-          else
+          elsif key.is_a?(Symbol) || key.is_a?(String)
             raise NameError, "no member '\#{key}' in struct"
-          end
-        when String
-          case key
-      #{string_set_cases}
           else
-            raise NameError, "no member '\#{key}' in struct"
+            raise TypeError, "no implicit conversion of \#{key.class} into Integer"
           end
-        else
-          raise TypeError, "no implicit conversion of \#{key.class} into Integer"
         end
       end
     RUBY
 
-    to_a_body = "[#{ivar_names.join(', ')}]"
-    klass.class_eval <<~RUBY, __FILE__, __LINE__ + 1
-      def to_a; #{to_a_body}; end
-      alias values to_a
-      alias deconstruct to_a
-    RUBY
+    # to_a / values / deconstruct
+    to_a_body = "[#{members.map { |m| "@#{m}" }.join(', ')}]"
+    code << "def to_a; #{to_a_body}; end\n"
+    code << "alias values to_a\n"
+    code << "alias deconstruct to_a\n"
 
-    to_h_body = "{#{members.map { |m| "#{m}: @#{m}" }.join(', ')}}"
-    klass.class_eval <<~RUBY, __FILE__, __LINE__ + 1
+    # to_h: ブロック版は中間ハッシュなしで直接 yield
+    to_h_literal = "{#{members.map { |m| "#{m}: @#{m}" }.join(', ')}}"
+    to_h_block_body = members.map { |m|
+      "k, v = yield :#{m}, @#{m}; h[k] = v"
+    }.join("; ")
+    code << <<~RUBY
       def to_h
         if block_given?
-          #{to_h_body}.to_h { |k, v| yield k, v }
+          h = {}; #{to_h_block_body}; h
         else
-          #{to_h_body}
+          #{to_h_literal}
         end
       end
     RUBY
 
-    dk_full = to_h_body
+    # deconstruct_keys
     dk_cases = members.map { |m|
-      "      h[:#{m}] = @#{m} if keys.include?(:#{m})"
-    }.join("\n")
-    klass.class_eval <<~RUBY, __FILE__, __LINE__ + 1
+      "h[:#{m}] = @#{m} if keys.include?(:#{m})"
+    }.join("; ")
+    code << <<~RUBY
       def deconstruct_keys(keys)
         if keys.nil?
-          #{dk_full}
+          #{to_h_literal}
         else
-          h = {}
-      #{dk_cases}
-          h
+          h = {}; #{dk_cases}; h
         end
       end
     RUBY
 
-    eq_body = if members.empty?
-      "true"
-    else
-      members.map { |m| "@#{m} == other.#{m}" }.join(" && ")
-    end
-    eql_body = if members.empty?
-      "true"
-    else
-      members.map { |m| "@#{m}.eql?(other.#{m})" }.join(" && ")
-    end
-    hash_body = "[self.class, #{ivar_names.join(', ')}].hash"
+    # ==: other.class.equal?(self.class) でポインタ比較
+    eq_body = members.empty? ? "true" : members.map { |m| "@#{m} == other.#{m}" }.join(" && ")
+    eql_body = members.empty? ? "true" : members.map { |m| "@#{m}.eql?(other.#{m})" }.join(" && ")
+    hash_body = "[self.class, #{members.map { |m| "@#{m}" }.join(', ')}].hash"
 
-    klass.class_eval <<~RUBY, __FILE__, __LINE__ + 1
+    code << <<~RUBY
       def ==(other)
-        return false unless other.is_a?(self.class)
-        #{eq_body}
+        other.class.equal?(self.class) && #{eq_body}
       end
-
       def eql?(other)
-        return false unless other.is_a?(self.class)
-        #{eql_body}
+        other.class.equal?(self.class) && #{eql_body}
       end
-
       def hash; #{hash_body}; end
     RUBY
 
-    each_body = members.map { |m| "  yield @#{m}" }.join("\n")
-    each_pair_body = members.map { |m| "  yield :#{m}, @#{m}" }.join("\n")
+    # each / each_pair
+    each_body = members.map { |m| "yield @#{m}" }.join("; ")
+    each_pair_body = members.map { |m| "yield :#{m}, @#{m}" }.join("; ")
 
-    klass.class_eval <<~RUBY, __FILE__, __LINE__ + 1
+    code << <<~RUBY
       def each
         return to_enum(:each) unless block_given?
-      #{each_body}
+        #{each_body}
         self
       end
-
       def each_pair
         return to_enum(:each_pair) unless block_given?
-      #{each_pair_body}
+        #{each_pair_body}
         self
       end
     RUBY
 
-    klass.class_eval <<~RUBY, __FILE__, __LINE__ + 1
+    # dig
+    code << <<~RUBY
       def dig(key, *rest)
         value = self[key]
         if rest.empty?
@@ -236,41 +193,45 @@
       end
     RUBY
 
-    klass.class_eval <<~RUBY, __FILE__, __LINE__ + 1
+    # select / filter: to_a を避けて直接 yield
+    select_body = members.map { |m| "r << @#{m} if yield(@#{m})" }.join("; ")
+    code << <<~RUBY
       def select
         return to_enum(:select) unless block_given?
-        to_a.select { |v| yield v }
+        r = []; #{select_body}; r
       end
       alias filter select
     RUBY
 
-    klass.class_eval <<~RUBY, __FILE__, __LINE__ + 1
-      def size; #{member_count}; end
-      alias length size
-    RUBY
+    # size / length
+    code << "def size; #{member_count}; end\n"
+    code << "alias length size\n"
 
-    klass.class_eval <<~RUBY, __FILE__, __LINE__ + 1
+    # values_at
+    code << <<~RUBY
       def values_at(*indices)
         ary = to_a
         indices.flat_map { |idx| ary.values_at(idx) }
       end
     RUBY
 
-    klass.class_eval <<~RUBY, __FILE__, __LINE__ + 1
-      def members; #{members_sym_literal}; end
-    RUBY
+    # members
+    code << "def members; #{members_literal}; end\n"
 
+    # inspect / to_s
     inspect_parts = members.map { |m|
       "#{m}=\#{@#{m}.inspect}"
     }.join(', ')
-    klass.class_eval <<~RUBY, __FILE__, __LINE__ + 1
+    code << <<~RUBY
       def inspect
-        klass_name = self.class.name || "struct"
-        "\#<\#{klass_name} #{inspect_parts}>"
+        "#<\#{self.class.name || 'struct'} #{inspect_parts}>"
       end
       alias to_s inspect
     RUBY
 
+    # 一括 class_eval
+    klass.class_eval(code, __FILE__, __LINE__ + 1)
+
     klass.class_eval(&block) if block
 
     if class_name
```


### ベンチマーク結果
```
=== インスタンス生成 ===
ruby 3.4.8 (2025-12-17 revision 995b59f666) +PRISM [arm64-darwin25]
Warming up --------------------------------------
         new 1-field     1.103M i/100ms
         new 4-field   923.487k i/100ms
         new 8-field   760.791k i/100ms
         kw  1-field   750.121k i/100ms
         kw  4-field   465.160k i/100ms
         kw  8-field   291.806k i/100ms
Calculating -------------------------------------
         new 1-field     10.935M (± 1.6%) i/s   (91.45 ns/i) -     55.150M in   5.044862s
         new 4-field      8.899M (± 1.7%) i/s  (112.37 ns/i) -     45.251M in   5.086557s
         new 8-field      7.418M (± 0.8%) i/s  (134.80 ns/i) -     37.279M in   5.025598s
         kw  1-field      7.373M (± 2.4%) i/s  (135.63 ns/i) -     37.506M in   5.090295s
         kw  4-field      4.681M (± 1.1%) i/s  (213.61 ns/i) -     23.723M in   5.068095s
         kw  8-field      3.041M (± 1.4%) i/s  (328.80 ns/i) -     15.466M in   5.086146s

Comparison:
         new 1-field: 10934814.0 i/s
         new 4-field:  8898842.9 i/s - 1.23x  slower
         new 8-field:  7418250.0 i/s - 1.47x  slower
         kw  1-field:  7372739.3 i/s - 1.48x  slower
         kw  4-field:  4681431.8 i/s - 2.34x  slower
         kw  8-field:  3041377.6 i/s - 3.60x  slower


=== ゲッター ===
ruby 3.4.8 (2025-12-17 revision 995b59f666) +PRISM [arm64-darwin25]
Warming up --------------------------------------
              getter     1.790M i/100ms
           [] symbol   924.403k i/100ms
            [] index   907.088k i/100ms
Calculating -------------------------------------
              getter     17.289M (± 3.2%) i/s   (57.84 ns/i) -     87.722M in   5.079138s
           [] symbol      9.046M (± 1.1%) i/s  (110.55 ns/i) -     45.296M in   5.008176s
            [] index      8.924M (± 1.9%) i/s  (112.06 ns/i) -     45.354M in   5.084492s

Comparison:
              getter: 17288689.5 i/s
           [] symbol:  9045545.9 i/s - 1.91x  slower
            [] index:  8923505.5 i/s - 1.94x  slower


=== セッター ===
ruby 3.4.8 (2025-12-17 revision 995b59f666) +PRISM [arm64-darwin25]
Warming up --------------------------------------
              setter     1.219M i/100ms
          []= symbol   751.486k i/100ms
           []= index   786.024k i/100ms
Calculating -------------------------------------
              setter     12.081M (± 1.4%) i/s   (82.78 ns/i) -     60.962M in   5.047203s
          []= symbol      7.381M (± 0.8%) i/s  (135.48 ns/i) -     37.574M in   5.090970s
           []= index      7.854M (± 1.1%) i/s  (127.33 ns/i) -     40.087M in   5.104966s

Comparison:
              setter: 12080874.9 i/s
           []= index:  7853606.7 i/s - 1.54x  slower
          []= symbol:  7381123.6 i/s - 1.64x  slower


=== 変換 ===
ruby 3.4.8 (2025-12-17 revision 995b59f666) +PRISM [arm64-darwin25]
Warming up --------------------------------------
        to_a 4-field     1.861M i/100ms
        to_h 4-field     1.137M i/100ms
Calculating -------------------------------------
        to_a 4-field     18.548M (± 2.9%) i/s   (53.91 ns/i) -     93.036M in   5.020411s
        to_h 4-field     11.394M (± 1.1%) i/s   (87.77 ns/i) -     57.989M in   5.090108s

Comparison:
        to_a 4-field: 18548048.5 i/s
        to_h 4-field: 11394011.0 i/s - 1.63x  slower


=== 等値比較 ===
ruby 3.4.8 (2025-12-17 revision 995b59f666) +PRISM [arm64-darwin25]
Warming up --------------------------------------
          == 4-field   780.300k i/100ms
        eql? 4-field   670.775k i/100ms
        hash 4-field     1.318M i/100ms
Calculating -------------------------------------
          == 4-field      7.795M (± 1.5%) i/s  (128.29 ns/i) -     39.015M in   5.006231s
        eql? 4-field      6.591M (± 1.7%) i/s  (151.73 ns/i) -     33.539M in   5.090356s
        hash 4-field     12.940M (± 1.2%) i/s   (77.28 ns/i) -     65.886M in   5.092428s

Comparison:
        hash 4-field: 12939758.2 i/s
          == 4-field:  7795023.3 i/s - 1.66x  slower
        eql? 4-field:  6590749.4 i/s - 1.96x  slower


=== イテレーション ===
ruby 3.4.8 (2025-12-17 revision 995b59f666) +PRISM [arm64-darwin25]
Warming up --------------------------------------
        each 4-field     1.065M i/100ms
   each_pair 4-field     1.041M i/100ms
Calculating -------------------------------------
        each 4-field     10.645M (± 0.9%) i/s   (93.94 ns/i) -     53.253M in   5.003236s
   each_pair 4-field     10.231M (± 2.2%) i/s   (97.74 ns/i) -     52.034M in   5.088593s

Comparison:
        each 4-field: 10644585.8 i/s
   each_pair 4-field: 10230922.1 i/s - 1.04x  slower


=== inspect ===
ruby 3.4.8 (2025-12-17 revision 995b59f666) +PRISM [arm64-darwin25]
Warming up --------------------------------------
     inspect 4-field   317.299k i/100ms
Calculating -------------------------------------
     inspect 4-field      3.221M (± 1.2%) i/s  (310.48 ns/i) -     16.182M in   5.025101s
```

### プロファイル結果
```
=== メモリプロファイル: アロケーション (1000 calls each) ===

--- インスタンス生成 ---
  new 1-field (positional)              1001 allocs / 1000 calls  ( 1.00 / call)
  new 4-field (positional)              1000 allocs / 1000 calls  ( 1.00 / call)
  new 8-field (positional)              1000 allocs / 1000 calls  ( 1.00 / call)
  new 1-field (keyword)                 2000 allocs / 1000 calls  ( 2.00 / call)
  new 4-field (keyword)                 2000 allocs / 1000 calls  ( 2.00 / call)
  new 8-field (keyword)                 2000 allocs / 1000 calls  ( 2.00 / call)

--- アクセサ ---
  getter (4-field)                         0 allocs / 1000 calls  ( 0.00 / call)
  [] symbol (4-field)                      0 allocs / 1000 calls  ( 0.00 / call)
  [] index (4-field)                       0 allocs / 1000 calls  ( 0.00 / call)
  setter (4-field)                         0 allocs / 1000 calls  ( 0.00 / call)
  []= symbol (4-field)                     0 allocs / 1000 calls  ( 0.00 / call)
  []= index (4-field)                      0 allocs / 1000 calls  ( 0.00 / call)

--- 変換 ---
  to_a (4-field)                        1000 allocs / 1000 calls  ( 1.00 / call)
  to_h (4-field)                        1000 allocs / 1000 calls  ( 1.00 / call)
  to_a (8-field)                        1000 allocs / 1000 calls  ( 1.00 / call)
  to_h (8-field)                        1000 allocs / 1000 calls  ( 1.00 / call)

--- 比較 ---
  == (4-field)                             0 allocs / 1000 calls  ( 0.00 / call)
  eql? (4-field)                           0 allocs / 1000 calls  ( 0.00 / call)
  hash (4-field)                           0 allocs / 1000 calls  ( 0.00 / call)

--- イテレーション ---
  each (4-field)                           0 allocs / 1000 calls  ( 0.00 / call)
  each_pair (4-field)                      0 allocs / 1000 calls  ( 0.00 / call)

--- その他 ---
  inspect (4-field)                     5000 allocs / 1000 calls  ( 5.00 / call)
  members (4-field)                     1000 allocs / 1000 calls  ( 1.00 / call)
  dig (4-field)                         1000 allocs / 1000 calls  ( 1.00 / call)
  values_at (4-field)                   6000 allocs / 1000 calls  ( 6.00 / call)

=== CPUプロファイル (100000 calls each) ===

--- インスタンス生成 ---
  new 1-field (positional)                 0.086 us/call  (0.0086 s total, 100000 calls)
  new 4-field (positional)                 0.110 us/call  (0.0110 s total, 100000 calls)
  new 8-field (positional)                 0.130 us/call  (0.0130 s total, 100000 calls)
  new 1-field (keyword)                    0.141 us/call  (0.0141 s total, 100000 calls)
  new 4-field (keyword)                    0.199 us/call  (0.0199 s total, 100000 calls)
  new 8-field (keyword)                    0.322 us/call  (0.0322 s total, 100000 calls)

--- アクセサ ---
  getter (4-field)                         0.069 us/call  (0.0069 s total, 100000 calls)
  [] symbol (4-field)                      0.116 us/call  (0.0116 s total, 100000 calls)
  [] index (4-field)                       0.116 us/call  (0.0116 s total, 100000 calls)
  setter (4-field)                         0.091 us/call  (0.0091 s total, 100000 calls)

--- 変換 ---
  to_a (4-field)                           0.055 us/call  (0.0055 s total, 100000 calls)
  to_h (4-field)                           0.087 us/call  (0.0087 s total, 100000 calls)

--- 比較 ---
  == (4-field)                             0.139 us/call  (0.0139 s total, 100000 calls)
  eql? (4-field)                           0.160 us/call  (0.0160 s total, 100000 calls)
  hash (4-field)                           0.083 us/call  (0.0083 s total, 100000 calls)

--- イテレーション ---
  each (4-field)                           0.101 us/call  (0.0101 s total, 100000 calls)
  each_pair (4-field)                      0.103 us/call  (0.0103 s total, 100000 calls)

--- その他 ---
  inspect (4-field)                        0.295 us/call  (0.0295 s total, 100000 calls)
  members (4-field)                        0.040 us/call  (0.0040 s total, 100000 calls)

=== GC圧力プロファイル (100000 calls each) ===
  new 4-field (positional)               1 GC runs  (1 ms GC time, 100000 calls)
  new 4-field (keyword)                  1 GC runs  (1 ms GC time, 100000 calls)
  to_a (4-field)                         4 GC runs  (2 ms GC time, 100000 calls)
  to_h (4-field)                         1 GC runs  (1 ms GC time, 100000 calls)
  inspect (4-field)                     23 GC runs  (5 ms GC time, 100000 calls)
  hash (4-field)                         0 GC runs  (0 ms GC time, 100000 calls)
```

### コード差分
```diff
--- ruby_struct.rb.before_iter3	2026-02-21 07:16:27
+++ ruby_struct.rb	2026-02-21 07:49:39
@@ -1,5 +1,6 @@
 # RubyのStructをプレーンRubyで再実装したクラス
-# class_eval による文字列ベースのメソッド生成でVMネイティブ最適縖パスに乗せる
+# class_eval による文字列ベースのメソッド生成でVMネイティブ最適化パスに乗せる
+# フラット化された case/when と identity チェックで高速ディスパッチを実現
 class RubyStruct
   def self.new(*members, keyword_init: false, &block)
     class_name = nil
@@ -23,207 +24,163 @@
 
     klass = Class.new
     member_count = members.length
-    ivar_names = members.map { |m| "@#{m}" }
-    members_sym_literal = "[#{members.map { |m| ":#{m}" }.join(', ')}]"
+    members_literal = "[#{members.map { |m| ":#{m}" }.join(', ')}]"
 
-    klass.class_eval <<~RUBY, __FILE__, __LINE__ + 1
-      def self.members; #{members_sym_literal}; end
-      def self.keyword_init?; #{keyword_init}; end
-    RUBY
+    # 全メソッド定義を単一文字列にまとめ、一括 class_eval でパース・コンパイルオーバーヘッドを削減
+    code = +""
 
+    # クラスメソッド: members, keyword_init?
+    code << "def self.members; #{members_literal}; end\n"
+    code << "def self.keyword_init?; #{keyword_init}; end\n"
+
+    # クラスメソッド: [] ショートカット
     if keyword_init
-      kw_params_b = members.map { |m| "#{m}: nil" }.join(", ")
-      kw_pass_b = members.map { |m| "#{m}: #{m}" }.join(", ")
-      klass.class_eval <<~RUBY, __FILE__, __LINE__ + 1
-        def self.[](#{kw_params_b})
-          new(#{kw_pass_b})
-        end
-      RUBY
+      kw_params = members.map { |m| "#{m}: nil" }.join(", ")
+      kw_pass = members.map { |m| "#{m}: #{m}" }.join(", ")
+      code << "def self.[](#{kw_params}); new(#{kw_pass}); end\n"
     else
-      pos_params_b = members.map { |m| "#{m}=nil" }.join(", ")
-      pos_pass_b = members.join(", ")
-      klass.class_eval <<~RUBY, __FILE__, __LINE__ + 1
-        def self.[](#{pos_params_b})
-          new(#{pos_pass_b})
-        end
-      RUBY
+      pos_params = members.map { |m| "#{m}=nil" }.join(", ")
+      pos_pass = members.join(", ")
+      code << "def self.[](#{pos_params}); new(#{pos_pass}); end\n"
     end
 
+    # initialize: 固定引数シグネチャで splat オーバーヘッドを回避
     if keyword_init
       kw_params = members.map { |m| "#{m}: nil" }.join(", ")
-      kw_assigns = members.map { |m| "  @#{m} = #{m}" }.join("\n")
-      klass.class_eval <<~RUBY, __FILE__, __LINE__ + 1
-        def initialize(#{kw_params})
-        #{kw_assigns}
-        end
-      RUBY
+      kw_assigns = members.map { |m| "@#{m} = #{m}" }.join("; ")
+      code << "def initialize(#{kw_params}); #{kw_assigns}; end\n"
     else
       pos_params = members.map { |m| "#{m}=nil" }.join(", ")
-      pos_assigns = members.map { |m| "  @#{m} = #{m}" }.join("\n")
-      klass.class_eval <<~RUBY, __FILE__, __LINE__ + 1
-        def initialize(#{pos_params})
-        #{pos_assigns}
-        end
-      RUBY
+      pos_assigns = members.map { |m| "@#{m} = #{m}" }.join("; ")
+      code << "def initialize(#{pos_params}); #{pos_assigns}; end\n"
     end
 
-    accessor_code = members.map { |m|
-      "def #{m}; @#{m}; end\ndef #{m}=(v); @#{m} = v; end"
-    }.join("\n")
-    klass.class_eval accessor_code, __FILE__, __LINE__ + 1
+    # アクセサ: ゲッター・セッター（VM インライン化対象）
+    members.each do |m|
+      code << "def #{m}; @#{m}; end\n"
+      code << "def #{m}=(v); @#{m} = v; end\n"
+    end
 
-    index_cases = members.each_with_index.map { |m, i|
-      "    when #{i}, #{i - member_count} then @#{m}"
+    # [] メソッド: フラット化 case/when でシンボルアクセスを高速化
+    # シンボルをトップレベルに配置し、型チェックのネストを除去
+    sym_get = members.map { |m| "when :#{m} then @#{m}" }.join("\n")
+    idx_get = members.each_with_index.map { |m, i|
+      "when #{i}, #{i - member_count} then @#{m}"
     }.join("\n")
-    symbol_cases = members.map { |m|
-      "    when :#{m} then @#{m}"
-    }.join("\n")
-    string_cases = members.map { |m|
-      "    when '#{m}' then @#{m}"
-    }.join("\n")
+    str_get = members.map { |m| "when '#{m}' then @#{m}" }.join("\n")
 
-    klass.class_eval <<~RUBY, __FILE__, __LINE__ + 1
+    code << <<~RUBY
       def [](key)
         case key
-        when Integer
-          case key
-      #{index_cases}
-          else
+        #{sym_get}
+        #{idx_get}
+        #{str_get}
+        else
+          if key.is_a?(Integer)
             raise IndexError, "offset \#{key} too large for struct(size:#{member_count})"
-          end
-        when Symbol
-          case key
-      #{symbol_cases}
-          else
+          elsif key.is_a?(Symbol) || key.is_a?(String)
             raise NameError, "no member '\#{key}' in struct"
-          end
-        when String
-          case key
-      #{string_cases}
           else
-            raise NameError, "no member '\#{key}' in struct"
+            raise TypeError, "no implicit conversion of \#{key.class} into Integer"
           end
-        else
-          raise TypeError, "no implicit conversion of \#{key.class} into Integer"
         end
       end
     RUBY
 
-    index_set_cases = members.each_with_index.map { |m, i|
-      "    when #{i}, #{i - member_count} then @#{m} = value"
+    # []= メソッド: 同様にフラット化
+    sym_set = members.map { |m| "when :#{m} then @#{m} = value" }.join("\n")
+    idx_set = members.each_with_index.map { |m, i|
+      "when #{i}, #{i - member_count} then @#{m} = value"
     }.join("\n")
-    symbol_set_cases = members.map { |m|
-      "    when :#{m} then @#{m} = value"
-    }.join("\n")
-    string_set_cases = members.map { |m|
-      "    when '#{m}' then @#{m} = value"
-    }.join("\n")
+    str_set = members.map { |m| "when '#{m}' then @#{m} = value" }.join("\n")
 
-    klass.class_eval <<~RUBY, __FILE__, __LINE__ + 1
+    code << <<~RUBY
       def []=(key, value)
         case key
-        when Integer
-          case key
-      #{index_set_cases}
-          else
+        #{sym_set}
+        #{idx_set}
+        #{str_set}
+        else
+          if key.is_a?(Integer)
             raise IndexError, "offset \#{key} too large for struct(size:#{member_count})"
-          end
-        when Symbol
-          case key
-      #{symbol_set_cases}
-          else
+          elsif key.is_a?(Symbol) || key.is_a?(String)
             raise NameError, "no member '\#{key}' in struct"
-          end
-        when String
-          case key
-      #{string_set_cases}
           else
-            raise NameError, "no member '\#{key}' in struct"
+            raise TypeError, "no implicit conversion of \#{key.class} into Integer"
           end
-        else
-          raise TypeError, "no implicit conversion of \#{key.class} into Integer"
         end
       end
     RUBY
 
-    to_a_body = "[#{ivar_names.join(', ')}]"
-    klass.class_eval <<~RUBY, __FILE__, __LINE__ + 1
-      def to_a; #{to_a_body}; end
-      alias values to_a
-      alias deconstruct to_a
-    RUBY
+    # to_a / values / deconstruct
+    to_a_body = "[#{members.map { |m| "@#{m}" }.join(', ')}]"
+    code << "def to_a; #{to_a_body}; end\n"
+    code << "alias values to_a\n"
+    code << "alias deconstruct to_a\n"
 
-    to_h_body = "{#{members.map { |m| "#{m}: @#{m}" }.join(', ')}}"
-    klass.class_eval <<~RUBY, __FILE__, __LINE__ + 1
+    # to_h: ブロック版は中間ハッシュなしで直接 yield してアロケーション削減
+    to_h_literal = "{#{members.map { |m| "#{m}: @#{m}" }.join(', ')}}"
+    to_h_block_body = members.map { |m|
+      "k, v = yield :#{m}, @#{m}; h[k] = v"
+    }.join("; ")
+    code << <<~RUBY
       def to_h
         if block_given?
-          #{to_h_body}.to_h { |k, v| yield k, v }
+          h = {}; #{to_h_block_body}; h
         else
-          #{to_h_body}
+          #{to_h_literal}
         end
       end
     RUBY
 
-    dk_full = to_h_body
+    # deconstruct_keys
     dk_cases = members.map { |m|
-      "      h[:#{m}] = @#{m} if keys.include?(:#{m})"
-    }.join("\n")
-    klass.class_eval <<~RUBY, __FILE__, __LINE__ + 1
+      "h[:#{m}] = @#{m} if keys.include?(:#{m})"
+    }.join("; ")
+    code << <<~RUBY
       def deconstruct_keys(keys)
         if keys.nil?
-          #{dk_full}
+          #{to_h_literal}
         else
-          h = {}
-      #{dk_cases}
-          h
+          h = {}; #{dk_cases}; h
         end
       end
     RUBY
 
-    eq_body = if members.empty?
-      "true"
-    else
-      members.map { |m| "@#{m} == other.#{m}" }.join(" && ")
-    end
-    eql_body = if members.empty?
-      "true"
-    else
-      members.map { |m| "@#{m}.eql?(other.#{m})" }.join(" && ")
-    end
-    hash_body = "[self.class, #{ivar_names.join(', ')}].hash"
+    # ==: other.class.equal?(self.class) でポインタ比較（is_a? の祖先チェーン走査を回避）
+    eq_body = members.empty? ? "true" : members.map { |m| "@#{m} == other.#{m}" }.join(" && ")
+    eql_body = members.empty? ? "true" : members.map { |m| "@#{m}.eql?(other.#{m})" }.join(" && ")
+    hash_body = "[self.class, #{members.map { |m| "@#{m}" }.join(', ')}].hash"
 
-    klass.class_eval <<~RUBY, __FILE__, __LINE__ + 1
+    code << <<~RUBY
       def ==(other)
-        return false unless other.is_a?(self.class)
-        #{eq_body}
+        other.class.equal?(self.class) && #{eq_body}
       end
-
       def eql?(other)
-        return false unless other.is_a?(self.class)
-        #{eql_body}
+        other.class.equal?(self.class) && #{eql_body}
       end
-
       def hash; #{hash_body}; end
     RUBY
 
-    each_body = members.map { |m| "  yield @#{m}" }.join("\n")
-    each_pair_body = members.map { |m| "  yield :#{m}, @#{m}" }.join("\n")
+    # each / each_pair: yield を直接使いブロック呼び出しオーバーヘッドを削減
+    each_body = members.map { |m| "yield @#{m}" }.join("; ")
+    each_pair_body = members.map { |m| "yield :#{m}, @#{m}" }.join("; ")
 
-    klass.class_eval <<~RUBY, __FILE__, __LINE__ + 1
+    code << <<~RUBY
       def each
         return to_enum(:each) unless block_given?
-      #{each_body}
+        #{each_body}
         self
       end
-
       def each_pair
         return to_enum(:each_pair) unless block_given?
-      #{each_pair_body}
+        #{each_pair_body}
         self
       end
     RUBY
 
-    klass.class_eval <<~RUBY, __FILE__, __LINE__ + 1
+    # dig
+    code << <<~RUBY
       def dig(key, *rest)
         value = self[key]
         if rest.empty?
@@ -236,41 +193,45 @@
       end
     RUBY
 
-    klass.class_eval <<~RUBY, __FILE__, __LINE__ + 1
+    # select / filter: to_a を避けてインスタンス変数から直接 yield
+    select_body = members.map { |m| "r << @#{m} if yield(@#{m})" }.join("; ")
+    code << <<~RUBY
       def select
         return to_enum(:select) unless block_given?
-        to_a.select { |v| yield v }
+        r = []; #{select_body}; r
       end
       alias filter select
     RUBY
 
-    klass.class_eval <<~RUBY, __FILE__, __LINE__ + 1
-      def size; #{member_count}; end
-      alias length size
-    RUBY
+    # size / length
+    code << "def size; #{member_count}; end\n"
+    code << "alias length size\n"
 
-    klass.class_eval <<~RUBY, __FILE__, __LINE__ + 1
+    # values_at
+    code << <<~RUBY
       def values_at(*indices)
         ary = to_a
         indices.flat_map { |idx| ary.values_at(idx) }
       end
     RUBY
 
-    klass.class_eval <<~RUBY, __FILE__, __LINE__ + 1
-      def members; #{members_sym_literal}; end
-    RUBY
+    # インスタンスメソッド: members
+    code << "def members; #{members_literal}; end\n"
 
+    # inspect / to_s: ローカル変数代入を省略して直接インライン化
     inspect_parts = members.map { |m|
       "#{m}=\#{@#{m}.inspect}"
     }.join(', ')
-    klass.class_eval <<~RUBY, __FILE__, __LINE__ + 1
+    code << <<~RUBY
       def inspect
-        klass_name = self.class.name || "struct"
-        "\#<\#{klass_name} #{inspect_parts}>"
+        "#<\#{self.class.name || 'struct'} #{inspect_parts}>"
       end
       alias to_s inspect
     RUBY
 
+    # 一括評価: 全メソッドを一度の class_eval でパース・コンパイル
+    klass.class_eval(code, __FILE__, __LINE__ + 1)
+
     klass.class_eval(&block) if block
 
     if class_name
```

---

## Iteration 4


### ベンチマーク結果
```
=== インスタンス生成 ===
ruby 3.4.8 (2025-12-17 revision 995b59f666) +PRISM [arm64-darwin25]
Warming up --------------------------------------
         new 1-field     1.132M i/100ms
         new 4-field   926.643k i/100ms
         new 8-field   761.045k i/100ms
         kw  1-field   757.100k i/100ms
         kw  4-field   479.469k i/100ms
         kw  8-field   312.953k i/100ms
Calculating -------------------------------------
         new 1-field     11.031M (± 1.5%) i/s   (90.65 ns/i) -     55.489M in   5.031259s
         new 4-field      8.745M (± 2.4%) i/s  (114.36 ns/i) -     44.479M in   5.089443s
         new 8-field      7.441M (± 0.8%) i/s  (134.39 ns/i) -     37.291M in   5.011825s
         kw  1-field      7.507M (± 1.6%) i/s  (133.21 ns/i) -     37.855M in   5.044062s
         kw  4-field      4.685M (± 0.4%) i/s  (213.44 ns/i) -     23.494M in   5.014552s
         kw  8-field      2.997M (± 2.0%) i/s  (333.72 ns/i) -     15.022M in   5.015139s

Comparison:
         new 1-field: 11031484.4 i/s
         new 4-field:  8744500.7 i/s - 1.26x  slower
         kw  1-field:  7506928.1 i/s - 1.47x  slower
         new 8-field:  7441086.0 i/s - 1.48x  slower
         kw  4-field:  4685230.5 i/s - 2.35x  slower
         kw  8-field:  2996564.9 i/s - 3.68x  slower


=== ゲッター ===
ruby 3.4.8 (2025-12-17 revision 995b59f666) +PRISM [arm64-darwin25]
Warming up --------------------------------------
              getter     1.786M i/100ms
           [] symbol   914.824k i/100ms
            [] index   899.447k i/100ms
Calculating -------------------------------------
              getter     17.851M (± 1.2%) i/s   (56.02 ns/i) -     91.094M in   5.103868s
           [] symbol      9.063M (± 2.0%) i/s  (110.34 ns/i) -     45.741M in   5.048956s
            [] index      8.984M (± 0.8%) i/s  (111.31 ns/i) -     44.972M in   5.006290s

Comparison:
              getter: 17850681.8 i/s
           [] symbol:  9063231.0 i/s - 1.97x  slower
            [] index:  8983719.3 i/s - 1.99x  slower


=== セッター ===
ruby 3.4.8 (2025-12-17 revision 995b59f666) +PRISM [arm64-darwin25]
Warming up --------------------------------------
              setter     1.188M i/100ms
          []= symbol   748.686k i/100ms
           []= index   781.594k i/100ms
Calculating -------------------------------------
              setter     12.149M (± 1.1%) i/s   (82.31 ns/i) -     61.790M in   5.086398s
          []= symbol      7.343M (± 2.2%) i/s  (136.19 ns/i) -     37.434M in   5.100859s
           []= index      7.762M (± 1.2%) i/s  (128.83 ns/i) -     39.080M in   5.035552s

Comparison:
              setter: 12149387.2 i/s
           []= index:  7762010.3 i/s - 1.57x  slower
          []= symbol:  7342500.5 i/s - 1.65x  slower


=== 変換 ===
ruby 3.4.8 (2025-12-17 revision 995b59f666) +PRISM [arm64-darwin25]
Warming up --------------------------------------
        to_a 4-field     1.820M i/100ms
        to_h 4-field     1.140M i/100ms
Calculating -------------------------------------
        to_a 4-field     18.573M (± 1.2%) i/s   (53.84 ns/i) -     94.650M in   5.096769s
        to_h 4-field     11.254M (± 2.8%) i/s   (88.86 ns/i) -     56.989M in   5.067880s

Comparison:
        to_a 4-field: 18573170.9 i/s
        to_h 4-field: 11254210.0 i/s - 1.65x  slower


=== 等値比較 ===
ruby 3.4.8 (2025-12-17 revision 995b59f666) +PRISM [arm64-darwin25]
Warming up --------------------------------------
          == 4-field   767.248k i/100ms
        eql? 4-field   652.036k i/100ms
        hash 4-field     1.318M i/100ms
Calculating -------------------------------------
          == 4-field      7.654M (± 1.0%) i/s  (130.65 ns/i) -     38.362M in   5.012471s
        eql? 4-field      6.670M (± 1.5%) i/s  (149.92 ns/i) -     33.906M in   5.084351s
        hash 4-field     13.051M (± 1.9%) i/s   (76.62 ns/i) -     65.894M in   5.050952s

Comparison:
        hash 4-field: 13050899.5 i/s
          == 4-field:  7654149.1 i/s - 1.71x  slower
        eql? 4-field:  6670102.3 i/s - 1.96x  slower


=== イテレーション ===
ruby 3.4.8 (2025-12-17 revision 995b59f666) +PRISM [arm64-darwin25]
Warming up --------------------------------------
        each 4-field     1.034M i/100ms
   each_pair 4-field     1.003M i/100ms
Calculating -------------------------------------
        each 4-field     10.598M (± 1.0%) i/s   (94.36 ns/i) -     53.747M in   5.072092s
   each_pair 4-field     10.308M (± 1.2%) i/s   (97.02 ns/i) -     52.147M in   5.059885s

Comparison:
        each 4-field: 10597671.4 i/s
   each_pair 4-field: 10307537.5 i/s - 1.03x  slower


=== inspect ===
ruby 3.4.8 (2025-12-17 revision 995b59f666) +PRISM [arm64-darwin25]
Warming up --------------------------------------
     inspect 4-field   330.071k i/100ms
Calculating -------------------------------------
     inspect 4-field      3.220M (± 3.3%) i/s  (310.58 ns/i) -     16.173M in   5.028897s
```

### プロファイル結果
```
=== メモリプロファイル: アロケーション (1000 calls each) ===

--- インスタンス生成 ---
  new 1-field (positional)              1001 allocs / 1000 calls  ( 1.00 / call)
  new 4-field (positional)              1000 allocs / 1000 calls  ( 1.00 / call)
  new 8-field (positional)              1000 allocs / 1000 calls  ( 1.00 / call)
  new 1-field (keyword)                 2000 allocs / 1000 calls  ( 2.00 / call)
  new 4-field (keyword)                 2000 allocs / 1000 calls  ( 2.00 / call)
  new 8-field (keyword)                 2000 allocs / 1000 calls  ( 2.00 / call)

--- アクセサ ---
  getter (4-field)                         0 allocs / 1000 calls  ( 0.00 / call)
  [] symbol (4-field)                      0 allocs / 1000 calls  ( 0.00 / call)
  [] index (4-field)                       0 allocs / 1000 calls  ( 0.00 / call)
  setter (4-field)                         0 allocs / 1000 calls  ( 0.00 / call)
  []= symbol (4-field)                     0 allocs / 1000 calls  ( 0.00 / call)
  []= index (4-field)                      0 allocs / 1000 calls  ( 0.00 / call)

--- 変換 ---
  to_a (4-field)                        1000 allocs / 1000 calls  ( 1.00 / call)
  to_h (4-field)                        1000 allocs / 1000 calls  ( 1.00 / call)
  to_a (8-field)                        1000 allocs / 1000 calls  ( 1.00 / call)
  to_h (8-field)                        1000 allocs / 1000 calls  ( 1.00 / call)

--- 比較 ---
  == (4-field)                             0 allocs / 1000 calls  ( 0.00 / call)
  eql? (4-field)                           0 allocs / 1000 calls  ( 0.00 / call)
  hash (4-field)                           0 allocs / 1000 calls  ( 0.00 / call)

--- イテレーション ---
  each (4-field)                           0 allocs / 1000 calls  ( 0.00 / call)
  each_pair (4-field)                      0 allocs / 1000 calls  ( 0.00 / call)

--- その他 ---
  inspect (4-field)                     5000 allocs / 1000 calls  ( 5.00 / call)
  members (4-field)                     1000 allocs / 1000 calls  ( 1.00 / call)
  dig (4-field)                         1000 allocs / 1000 calls  ( 1.00 / call)
  values_at (4-field)                   6000 allocs / 1000 calls  ( 6.00 / call)

=== CPUプロファイル (100000 calls each) ===

--- インスタンス生成 ---
  new 1-field (positional)                 0.083 us/call  (0.0083 s total, 100000 calls)
  new 4-field (positional)                 0.110 us/call  (0.0110 s total, 100000 calls)
  new 8-field (positional)                 0.127 us/call  (0.0127 s total, 100000 calls)
  new 1-field (keyword)                    0.140 us/call  (0.0140 s total, 100000 calls)
  new 4-field (keyword)                    0.201 us/call  (0.0201 s total, 100000 calls)
  new 8-field (keyword)                    0.324 us/call  (0.0324 s total, 100000 calls)

--- アクセサ ---
  getter (4-field)                         0.068 us/call  (0.0068 s total, 100000 calls)
  [] symbol (4-field)                      0.116 us/call  (0.0116 s total, 100000 calls)
  [] index (4-field)                       0.114 us/call  (0.0114 s total, 100000 calls)
  setter (4-field)                         0.090 us/call  (0.0090 s total, 100000 calls)

--- 変換 ---
  to_a (4-field)                           0.053 us/call  (0.0053 s total, 100000 calls)
  to_h (4-field)                           0.087 us/call  (0.0087 s total, 100000 calls)

--- 比較 ---
  == (4-field)                             0.133 us/call  (0.0133 s total, 100000 calls)
  eql? (4-field)                           0.160 us/call  (0.0160 s total, 100000 calls)
  hash (4-field)                           0.081 us/call  (0.0081 s total, 100000 calls)

--- イテレーション ---
  each (4-field)                           0.100 us/call  (0.0100 s total, 100000 calls)
  each_pair (4-field)                      0.102 us/call  (0.0102 s total, 100000 calls)

--- その他 ---
  inspect (4-field)                        0.295 us/call  (0.0295 s total, 100000 calls)
  members (4-field)                        0.041 us/call  (0.0041 s total, 100000 calls)

=== GC圧力プロファイル (100000 calls each) ===
  new 4-field (positional)               1 GC runs  (0 ms GC time, 100000 calls)
  new 4-field (keyword)                  1 GC runs  (1 ms GC time, 100000 calls)
  to_a (4-field)                         4 GC runs  (1 ms GC time, 100000 calls)
  to_h (4-field)                         1 GC runs  (1 ms GC time, 100000 calls)
  inspect (4-field)                     23 GC runs  (5 ms GC time, 100000 calls)
  hash (4-field)                         0 GC runs  (0 ms GC time, 100000 calls)
```

### コード差分
```diff

```

---

## Iteration 5


### ベンチマーク結果
```
=== インスタンス生成 ===
ruby 3.4.8 (2025-12-17 revision 995b59f666) +PRISM [arm64-darwin25]
Warming up --------------------------------------
         new 1-field     1.127M i/100ms
         new 4-field   941.672k i/100ms
         new 8-field   767.470k i/100ms
         kw  1-field   754.832k i/100ms
         kw  4-field   475.211k i/100ms
         kw  8-field   314.294k i/100ms
Calculating -------------------------------------
         new 1-field     10.965M (± 2.1%) i/s   (91.20 ns/i) -     55.202M in   5.036339s
         new 4-field      8.891M (± 2.0%) i/s  (112.48 ns/i) -     45.200M in   5.085993s
         new 8-field      7.432M (± 1.1%) i/s  (134.56 ns/i) -     37.606M in   5.060944s
         kw  1-field      7.608M (± 1.2%) i/s  (131.45 ns/i) -     38.496M in   5.060990s
         kw  4-field      4.632M (± 2.7%) i/s  (215.89 ns/i) -     23.285M in   5.030875s
         kw  8-field      3.031M (± 1.4%) i/s  (329.97 ns/i) -     15.400M in   5.082769s

Comparison:
         new 1-field: 10965488.8 i/s
         new 4-field:  8890642.2 i/s - 1.23x  slower
         kw  1-field:  7607661.6 i/s - 1.44x  slower
         new 8-field:  7431601.8 i/s - 1.48x  slower
         kw  4-field:  4631961.5 i/s - 2.37x  slower
         kw  8-field:  3030550.6 i/s - 3.62x  slower


=== ゲッター ===
ruby 3.4.8 (2025-12-17 revision 995b59f666) +PRISM [arm64-darwin25]
Warming up --------------------------------------
              getter     1.704M i/100ms
           [] symbol   919.047k i/100ms
            [] index   895.834k i/100ms
Calculating -------------------------------------
              getter     16.915M (± 2.7%) i/s   (59.12 ns/i) -     85.184M in   5.039587s
           [] symbol      8.982M (± 1.2%) i/s  (111.33 ns/i) -     45.033M in   5.014541s
            [] index      8.978M (± 1.3%) i/s  (111.38 ns/i) -     45.688M in   5.089567s

Comparison:
              getter: 16915455.6 i/s
           [] symbol:  8981981.5 i/s - 1.88x  slower
            [] index:  8978233.8 i/s - 1.88x  slower


=== セッター ===
ruby 3.4.8 (2025-12-17 revision 995b59f666) +PRISM [arm64-darwin25]
Warming up --------------------------------------
              setter     1.235M i/100ms
          []= symbol   748.523k i/100ms
           []= index   765.023k i/100ms
Calculating -------------------------------------
              setter     12.111M (± 1.7%) i/s   (82.57 ns/i) -     60.538M in   5.000177s
          []= symbol      7.494M (± 1.0%) i/s  (133.43 ns/i) -     38.175M in   5.094214s
           []= index      7.788M (± 1.3%) i/s  (128.40 ns/i) -     39.016M in   5.010419s

Comparison:
              setter: 12111105.4 i/s
           []= index:  7788389.9 i/s - 1.56x  slower
          []= symbol:  7494434.6 i/s - 1.62x  slower


=== 変換 ===
ruby 3.4.8 (2025-12-17 revision 995b59f666) +PRISM [arm64-darwin25]
Warming up --------------------------------------
        to_a 4-field     1.866M i/100ms
        to_h 4-field     1.113M i/100ms
Calculating -------------------------------------
        to_a 4-field     18.650M (± 2.3%) i/s   (53.62 ns/i) -     95.154M in   5.104865s
        to_h 4-field     11.248M (± 2.8%) i/s   (88.90 ns/i) -     56.761M in   5.050556s

Comparison:
        to_a 4-field: 18650100.9 i/s
        to_h 4-field: 11248204.1 i/s - 1.66x  slower


=== 等値比較 ===
ruby 3.4.8 (2025-12-17 revision 995b59f666) +PRISM [arm64-darwin25]
Warming up --------------------------------------
          == 4-field   760.162k i/100ms
        eql? 4-field   662.659k i/100ms
        hash 4-field     1.286M i/100ms
Calculating -------------------------------------
          == 4-field      7.659M (± 0.9%) i/s  (130.57 ns/i) -     38.768M in   5.062464s
        eql? 4-field      6.536M (± 2.2%) i/s  (153.01 ns/i) -     33.133M in   5.072205s
        hash 4-field     12.851M (± 1.9%) i/s   (77.81 ns/i) -     64.294M in   5.004868s

Comparison:
        hash 4-field: 12851308.1 i/s
          == 4-field:  7658680.8 i/s - 1.68x  slower
        eql? 4-field:  6535570.5 i/s - 1.97x  slower


=== イテレーション ===
ruby 3.4.8 (2025-12-17 revision 995b59f666) +PRISM [arm64-darwin25]
Warming up --------------------------------------
        each 4-field     1.041M i/100ms
   each_pair 4-field     1.042M i/100ms
Calculating -------------------------------------
        each 4-field     10.617M (± 1.1%) i/s   (94.19 ns/i) -     53.115M in   5.003277s
   each_pair 4-field     10.395M (± 1.2%) i/s   (96.20 ns/i) -     52.110M in   5.013708s

Comparison:
        each 4-field: 10617297.4 i/s
   each_pair 4-field: 10395019.8 i/s - same-ish: difference falls within error


=== inspect ===
ruby 3.4.8 (2025-12-17 revision 995b59f666) +PRISM [arm64-darwin25]
Warming up --------------------------------------
     inspect 4-field   319.204k i/100ms
Calculating -------------------------------------
     inspect 4-field      3.274M (± 1.3%) i/s  (305.41 ns/i) -     16.599M in   5.070374s
```

### プロファイル結果
```
=== メモリプロファイル: アロケーション (1000 calls each) ===

--- インスタンス生成 ---
  new 1-field (positional)              1001 allocs / 1000 calls  ( 1.00 / call)
  new 4-field (positional)              1000 allocs / 1000 calls  ( 1.00 / call)
  new 8-field (positional)              1000 allocs / 1000 calls  ( 1.00 / call)
  new 1-field (keyword)                 2000 allocs / 1000 calls  ( 2.00 / call)
  new 4-field (keyword)                 2000 allocs / 1000 calls  ( 2.00 / call)
  new 8-field (keyword)                 2000 allocs / 1000 calls  ( 2.00 / call)

--- アクセサ ---
  getter (4-field)                         0 allocs / 1000 calls  ( 0.00 / call)
  [] symbol (4-field)                      0 allocs / 1000 calls  ( 0.00 / call)
  [] index (4-field)                       0 allocs / 1000 calls  ( 0.00 / call)
  setter (4-field)                         0 allocs / 1000 calls  ( 0.00 / call)
  []= symbol (4-field)                     0 allocs / 1000 calls  ( 0.00 / call)
  []= index (4-field)                      0 allocs / 1000 calls  ( 0.00 / call)

--- 変換 ---
  to_a (4-field)                        1000 allocs / 1000 calls  ( 1.00 / call)
  to_h (4-field)                        1000 allocs / 1000 calls  ( 1.00 / call)
  to_a (8-field)                        1000 allocs / 1000 calls  ( 1.00 / call)
  to_h (8-field)                        1000 allocs / 1000 calls  ( 1.00 / call)

--- 比較 ---
  == (4-field)                             0 allocs / 1000 calls  ( 0.00 / call)
  eql? (4-field)                           0 allocs / 1000 calls  ( 0.00 / call)
  hash (4-field)                           0 allocs / 1000 calls  ( 0.00 / call)

--- イテレーション ---
  each (4-field)                           0 allocs / 1000 calls  ( 0.00 / call)
  each_pair (4-field)                      0 allocs / 1000 calls  ( 0.00 / call)

--- その他 ---
  inspect (4-field)                     5000 allocs / 1000 calls  ( 5.00 / call)
  members (4-field)                     1000 allocs / 1000 calls  ( 1.00 / call)
  dig (4-field)                         1000 allocs / 1000 calls  ( 1.00 / call)
  values_at (4-field)                   6000 allocs / 1000 calls  ( 6.00 / call)

=== CPUプロファイル (100000 calls each) ===

--- インスタンス生成 ---
  new 1-field (positional)                 0.085 us/call  (0.0085 s total, 100000 calls)
  new 4-field (positional)                 0.110 us/call  (0.0110 s total, 100000 calls)
  new 8-field (positional)                 0.130 us/call  (0.0130 s total, 100000 calls)
  new 1-field (keyword)                    0.139 us/call  (0.0139 s total, 100000 calls)
  new 4-field (keyword)                    0.200 us/call  (0.0200 s total, 100000 calls)
  new 8-field (keyword)                    0.318 us/call  (0.0318 s total, 100000 calls)

--- アクセサ ---
  getter (4-field)                         0.069 us/call  (0.0069 s total, 100000 calls)
  [] symbol (4-field)                      0.118 us/call  (0.0118 s total, 100000 calls)
  [] index (4-field)                       0.116 us/call  (0.0116 s total, 100000 calls)
  setter (4-field)                         0.094 us/call  (0.0094 s total, 100000 calls)

--- 変換 ---
  to_a (4-field)                           0.054 us/call  (0.0054 s total, 100000 calls)
  to_h (4-field)                           0.088 us/call  (0.0088 s total, 100000 calls)

--- 比較 ---
  == (4-field)                             0.141 us/call  (0.0141 s total, 100000 calls)
  eql? (4-field)                           0.165 us/call  (0.0165 s total, 100000 calls)
  hash (4-field)                           0.081 us/call  (0.0081 s total, 100000 calls)

--- イテレーション ---
  each (4-field)                           0.101 us/call  (0.0101 s total, 100000 calls)
  each_pair (4-field)                      0.106 us/call  (0.0106 s total, 100000 calls)

--- その他 ---
  inspect (4-field)                        0.301 us/call  (0.0301 s total, 100000 calls)
  members (4-field)                        0.041 us/call  (0.0041 s total, 100000 calls)

=== GC圧力プロファイル (100000 calls each) ===
  new 4-field (positional)               1 GC runs  (0 ms GC time, 100000 calls)
  new 4-field (keyword)                  1 GC runs  (1 ms GC time, 100000 calls)
  to_a (4-field)                         4 GC runs  (1 ms GC time, 100000 calls)
  to_h (4-field)                         1 GC runs  (0 ms GC time, 100000 calls)
  inspect (4-field)                     23 GC runs  (5 ms GC time, 100000 calls)
  hash (4-field)                         0 GC runs  (0 ms GC time, 100000 calls)
```

### コード差分
```diff

```

---

## Iteration 6


### ベンチマーク結果
```
=== インスタンス生成 ===
ruby 3.4.8 (2025-12-17 revision 995b59f666) +PRISM [arm64-darwin25]
Warming up --------------------------------------
         new 1-field     1.137M i/100ms
         new 4-field   909.336k i/100ms
         new 8-field   743.072k i/100ms
         kw  1-field   744.859k i/100ms
         kw  4-field   460.800k i/100ms
         kw  8-field   306.070k i/100ms
Calculating -------------------------------------
         new 1-field     11.243M (± 1.0%) i/s   (88.94 ns/i) -     56.867M in   5.058477s
         new 4-field      8.586M (± 3.6%) i/s  (116.47 ns/i) -     43.648M in   5.090457s
         new 8-field      7.121M (± 2.5%) i/s  (140.43 ns/i) -     35.667M in   5.011991s
         kw  1-field      7.090M (± 3.7%) i/s  (141.05 ns/i) -     35.753M in   5.050546s
         kw  4-field      4.595M (± 3.6%) i/s  (217.62 ns/i) -     23.040M in   5.020739s
         kw  8-field      2.914M (± 2.9%) i/s  (343.20 ns/i) -     14.691M in   5.046459s

Comparison:
         new 1-field: 11243238.7 i/s
         new 4-field:  8585671.1 i/s - 1.31x  slower
         new 8-field:  7121093.9 i/s - 1.58x  slower
         kw  1-field:  7089870.6 i/s - 1.59x  slower
         kw  4-field:  4595191.3 i/s - 2.45x  slower
         kw  8-field:  2913745.5 i/s - 3.86x  slower


=== ゲッター ===
ruby 3.4.8 (2025-12-17 revision 995b59f666) +PRISM [arm64-darwin25]
Warming up --------------------------------------
              getter     1.673M i/100ms
           [] symbol   887.933k i/100ms
            [] index   872.022k i/100ms
Calculating -------------------------------------
              getter     16.935M (± 3.6%) i/s   (59.05 ns/i) -     85.327M in   5.045052s
           [] symbol      8.875M (± 1.5%) i/s  (112.68 ns/i) -     44.397M in   5.003690s
            [] index      8.842M (± 2.0%) i/s  (113.10 ns/i) -     44.473M in   5.032021s

Comparison:
              getter: 16935323.6 i/s
           [] symbol:  8874897.2 i/s - 1.91x  slower
            [] index:  8841814.5 i/s - 1.92x  slower


=== セッター ===
ruby 3.4.8 (2025-12-17 revision 995b59f666) +PRISM [arm64-darwin25]
Warming up --------------------------------------
              setter     1.211M i/100ms
          []= symbol   721.796k i/100ms
           []= index   763.672k i/100ms
Calculating -------------------------------------
              setter     12.085M (± 1.6%) i/s   (82.75 ns/i) -     60.536M in   5.010490s
          []= symbol      7.348M (± 2.0%) i/s  (136.09 ns/i) -     36.812M in   5.011806s
           []= index      7.781M (± 2.0%) i/s  (128.52 ns/i) -     38.947M in   5.007618s

Comparison:
              setter: 12084838.4 i/s
           []= index:  7780834.3 i/s - 1.55x  slower
          []= symbol:  7347968.8 i/s - 1.64x  slower


=== 変換 ===
ruby 3.4.8 (2025-12-17 revision 995b59f666) +PRISM [arm64-darwin25]
Warming up --------------------------------------
        to_a 4-field     1.817M i/100ms
        to_h 4-field     1.051M i/100ms
Calculating -------------------------------------
        to_a 4-field     18.105M (± 3.3%) i/s   (55.23 ns/i) -     90.852M in   5.023623s
        to_h 4-field     11.225M (± 2.5%) i/s   (89.09 ns/i) -     56.733M in   5.057253s

Comparison:
        to_a 4-field: 18104824.7 i/s
        to_h 4-field: 11225214.8 i/s - 1.61x  slower


=== 等値比較 ===
ruby 3.4.8 (2025-12-17 revision 995b59f666) +PRISM [arm64-darwin25]
Warming up --------------------------------------
          == 4-field   761.728k i/100ms
        eql? 4-field   674.774k i/100ms
        hash 4-field     1.274M i/100ms
Calculating -------------------------------------
          == 4-field      7.509M (± 2.4%) i/s  (133.18 ns/i) -     38.086M in   5.075418s
        eql? 4-field      6.446M (± 1.4%) i/s  (155.14 ns/i) -     32.389M in   5.025804s
        hash 4-field     12.826M (± 2.0%) i/s   (77.96 ns/i) -     64.990M in   5.068904s

Comparison:
        hash 4-field: 12826348.6 i/s
          == 4-field:  7508613.4 i/s - 1.71x  slower
        eql? 4-field:  6445805.7 i/s - 1.99x  slower


=== イテレーション ===
ruby 3.4.8 (2025-12-17 revision 995b59f666) +PRISM [arm64-darwin25]
Warming up --------------------------------------
        each 4-field     1.046M i/100ms
   each_pair 4-field     1.007M i/100ms
Calculating -------------------------------------
        each 4-field     10.429M (± 2.0%) i/s   (95.88 ns/i) -     52.276M in   5.014383s
   each_pair 4-field     10.052M (± 2.1%) i/s   (99.48 ns/i) -     50.354M in   5.011402s

Comparison:
        each 4-field: 10429166.6 i/s
   each_pair 4-field: 10052322.4 i/s - same-ish: difference falls within error


=== inspect ===
ruby 3.4.8 (2025-12-17 revision 995b59f666) +PRISM [arm64-darwin25]
Warming up --------------------------------------
     inspect 4-field   320.951k i/100ms
Calculating -------------------------------------
     inspect 4-field      3.157M (± 3.1%) i/s  (316.77 ns/i) -     16.048M in   5.088234s
```

### プロファイル結果
```
=== メモリプロファイル: アロケーション (1000 calls each) ===

--- インスタンス生成 ---
  new 1-field (positional)              1001 allocs / 1000 calls  ( 1.00 / call)
  new 4-field (positional)              1000 allocs / 1000 calls  ( 1.00 / call)
  new 8-field (positional)              1000 allocs / 1000 calls  ( 1.00 / call)
  new 1-field (keyword)                 2000 allocs / 1000 calls  ( 2.00 / call)
  new 4-field (keyword)                 2000 allocs / 1000 calls  ( 2.00 / call)
  new 8-field (keyword)                 2000 allocs / 1000 calls  ( 2.00 / call)

--- アクセサ ---
  getter (4-field)                         0 allocs / 1000 calls  ( 0.00 / call)
  [] symbol (4-field)                      0 allocs / 1000 calls  ( 0.00 / call)
  [] index (4-field)                       0 allocs / 1000 calls  ( 0.00 / call)
  setter (4-field)                         0 allocs / 1000 calls  ( 0.00 / call)
  []= symbol (4-field)                     0 allocs / 1000 calls  ( 0.00 / call)
  []= index (4-field)                      0 allocs / 1000 calls  ( 0.00 / call)

--- 変換 ---
  to_a (4-field)                        1000 allocs / 1000 calls  ( 1.00 / call)
  to_h (4-field)                        1000 allocs / 1000 calls  ( 1.00 / call)
  to_a (8-field)                        1000 allocs / 1000 calls  ( 1.00 / call)
  to_h (8-field)                        1000 allocs / 1000 calls  ( 1.00 / call)

--- 比較 ---
  == (4-field)                             0 allocs / 1000 calls  ( 0.00 / call)
  eql? (4-field)                           0 allocs / 1000 calls  ( 0.00 / call)
  hash (4-field)                           0 allocs / 1000 calls  ( 0.00 / call)

--- イテレーション ---
  each (4-field)                           0 allocs / 1000 calls  ( 0.00 / call)
  each_pair (4-field)                      0 allocs / 1000 calls  ( 0.00 / call)

--- その他 ---
  inspect (4-field)                     5000 allocs / 1000 calls  ( 5.00 / call)
  members (4-field)                     1000 allocs / 1000 calls  ( 1.00 / call)
  dig (4-field)                         1000 allocs / 1000 calls  ( 1.00 / call)
  values_at (4-field)                   6000 allocs / 1000 calls  ( 6.00 / call)

=== CPUプロファイル (100000 calls each) ===

--- インスタンス生成 ---
  new 1-field (positional)                 0.087 us/call  (0.0087 s total, 100000 calls)
  new 4-field (positional)                 0.115 us/call  (0.0115 s total, 100000 calls)
  new 8-field (positional)                 0.132 us/call  (0.0132 s total, 100000 calls)
  new 1-field (keyword)                    0.148 us/call  (0.0148 s total, 100000 calls)
  new 4-field (keyword)                    0.206 us/call  (0.0206 s total, 100000 calls)
  new 8-field (keyword)                    0.336 us/call  (0.0336 s total, 100000 calls)

--- アクセサ ---
  getter (4-field)                         0.071 us/call  (0.0071 s total, 100000 calls)
  [] symbol (4-field)                      0.121 us/call  (0.0121 s total, 100000 calls)
  [] index (4-field)                       0.119 us/call  (0.0119 s total, 100000 calls)
  setter (4-field)                         0.090 us/call  (0.0090 s total, 100000 calls)

--- 変換 ---
  to_a (4-field)                           0.056 us/call  (0.0056 s total, 100000 calls)
  to_h (4-field)                           0.089 us/call  (0.0089 s total, 100000 calls)

--- 比較 ---
  == (4-field)                             0.143 us/call  (0.0143 s total, 100000 calls)
  eql? (4-field)                           0.166 us/call  (0.0166 s total, 100000 calls)
  hash (4-field)                           0.083 us/call  (0.0083 s total, 100000 calls)

--- イテレーション ---
  each (4-field)                           0.103 us/call  (0.0103 s total, 100000 calls)
  each_pair (4-field)                      0.107 us/call  (0.0107 s total, 100000 calls)

--- その他 ---
  inspect (4-field)                        0.307 us/call  (0.0307 s total, 100000 calls)
  members (4-field)                        0.040 us/call  (0.0040 s total, 100000 calls)

=== GC圧力プロファイル (100000 calls each) ===
  new 4-field (positional)               1 GC runs  (1 ms GC time, 100000 calls)
  new 4-field (keyword)                  1 GC runs  (1 ms GC time, 100000 calls)
  to_a (4-field)                         4 GC runs  (2 ms GC time, 100000 calls)
  to_h (4-field)                         1 GC runs  (1 ms GC time, 100000 calls)
  inspect (4-field)                     23 GC runs  (5 ms GC time, 100000 calls)
  hash (4-field)                         0 GC runs  (0 ms GC time, 100000 calls)
```

### コード差分
```diff

```

---

## Iteration 7

