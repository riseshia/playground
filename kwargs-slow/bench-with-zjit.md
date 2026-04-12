Ruby 4.0.1 (x86_64-linux)

### Loc (1 field)
ruby 4.0.1 (2026-01-13 revision e04267a14b) +ZJIT +PRISM [x86_64-linux]
Warming up --------------------------------------
     Data.define(kw)   478.300k i/100ms
    Data.define(pos)   530.431k i/100ms
          Struct(kw)   639.709k i/100ms
         Struct(pos)     1.301M i/100ms
      RubyStruct(kw)     1.828M i/100ms
     RubyStruct(pos)     2.885M i/100ms
          Class(pos)     2.926M i/100ms
           Class(kw)     2.866M i/100ms
Calculating -------------------------------------
     Data.define(kw)      4.864M (± 1.9%) i/s  (205.61 ns/i) -     24.393M in   5.017339s
    Data.define(pos)      4.972M (± 1.7%) i/s  (201.13 ns/i) -     24.930M in   5.015682s
          Struct(kw)      6.640M (± 2.4%) i/s  (150.60 ns/i) -     33.265M in   5.012834s
         Struct(pos)     14.391M (± 2.1%) i/s   (69.49 ns/i) -     72.867M in   5.065708s
      RubyStruct(kw)     18.488M (± 2.6%) i/s   (54.09 ns/i) -     93.235M in   5.046506s
     RubyStruct(pos)     30.228M (± 2.5%) i/s   (33.08 ns/i) -    152.926M in   5.062334s
          Class(pos)     30.255M (± 2.4%) i/s   (33.05 ns/i) -    152.166M in   5.032330s
           Class(kw)     29.897M (± 2.0%) i/s   (33.45 ns/i) -    151.902M in   5.082975s

Comparison:
          Class(pos): 30254866.1 i/s
     RubyStruct(pos): 30227879.7 i/s - same-ish: difference falls within error
           Class(kw): 29896987.0 i/s - same-ish: difference falls within error
      RubyStruct(kw): 18488329.6 i/s - 1.64x  slower
         Struct(pos): 14390708.0 i/s - 2.10x  slower
          Struct(kw):  6639970.9 i/s - 4.56x  slower
    Data.define(pos):  4971900.8 i/s - 6.09x  slower
     Data.define(kw):  4863604.6 i/s - 6.22x  slower


### CallNode (8 fields)
ruby 4.0.1 (2026-01-13 revision e04267a14b) +ZJIT +PRISM [x86_64-linux]
Warming up --------------------------------------
     Data.define(kw)   203.764k i/100ms
    Data.define(pos)   200.231k i/100ms
          Struct(kw)   220.718k i/100ms
         Struct(pos)     1.044M i/100ms
      RubyStruct(kw)     1.023M i/100ms
     RubyStruct(pos)     1.351M i/100ms
          Class(pos)     1.475M i/100ms
           Class(kw)     1.043M i/100ms
Calculating -------------------------------------
     Data.define(kw)      2.047M (± 1.8%) i/s  (488.57 ns/i) -     10.392M in   5.078954s
    Data.define(pos)      2.082M (± 1.8%) i/s  (480.36 ns/i) -     10.412M in   5.003160s
          Struct(kw)      2.355M (± 2.0%) i/s  (424.70 ns/i) -     11.919M in   5.063975s
         Struct(pos)     10.823M (± 2.4%) i/s   (92.39 ns/i) -     54.295M in   5.019473s
      RubyStruct(kw)     10.434M (± 2.6%) i/s   (95.84 ns/i) -     52.195M in   5.005884s
     RubyStruct(pos)     14.186M (± 2.8%) i/s   (70.49 ns/i) -     71.624M in   5.052922s
          Class(pos)     15.185M (± 2.2%) i/s   (65.85 ns/i) -     76.684M in   5.052495s
           Class(kw)     10.705M (± 2.1%) i/s   (93.42 ns/i) -     54.226M in   5.067943s

Comparison:
          Class(pos): 15185077.4 i/s
     RubyStruct(pos): 14186270.8 i/s - 1.07x  slower
         Struct(pos): 10823114.7 i/s - 1.40x  slower
           Class(kw): 10704566.0 i/s - 1.42x  slower
      RubyStruct(kw): 10433737.4 i/s - 1.46x  slower
          Struct(kw):  2354600.1 i/s - 6.45x  slower
    Data.define(pos):  2081792.6 i/s - 7.29x  slower
     Data.define(kw):  2046781.7 i/s - 7.42x  slower


### Bulk: Loc 2M objects
Data.define(kw)  0.629s
Data.define(pos)  0.521s
Struct(pos)      0.155s
RubyStruct(pos)  0.066s
Class(pos)       0.067s
Class(kw)        0.090s
Integer          0.043s
