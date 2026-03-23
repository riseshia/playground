Ruby 4.0.1 (x86_64-linux)

### Loc (1 field)
ruby 4.0.1 (2026-01-13 revision e04267a14b) +PRISM [x86_64-linux]
Warming up --------------------------------------
         Data.define   488.439k i/100ms
          Struct(kw)   617.771k i/100ms
         Struct(pos)     1.170M i/100ms
      RubyStruct(kw)     1.460M i/100ms
     RubyStruct(pos)     1.672M i/100ms
          Class(pos)     1.834M i/100ms
           Class(kw)     1.476M i/100ms
Calculating -------------------------------------
         Data.define      4.833M (± 3.0%) i/s  (206.91 ns/i) -     24.422M in   5.057757s
          Struct(kw)      6.061M (± 2.8%) i/s  (164.99 ns/i) -     30.889M in   5.100356s
         Struct(pos)     11.052M (± 3.6%) i/s   (90.48 ns/i) -     56.180M in   5.089774s
      RubyStruct(kw)     13.951M (± 3.0%) i/s   (71.68 ns/i) -     70.062M in   5.026689s
     RubyStruct(pos)     16.020M (± 3.1%) i/s   (62.42 ns/i) -     80.262M in   5.014730s
          Class(pos)     18.091M (± 1.9%) i/s   (55.28 ns/i) -     91.675M in   5.069283s
           Class(kw)     14.765M (± 2.2%) i/s   (67.73 ns/i) -     73.795M in   5.000197s

Comparison:
          Class(pos): 18090939.1 i/s
     RubyStruct(pos): 16020228.2 i/s - 1.13x  slower
           Class(kw): 14765292.0 i/s - 1.23x  slower
      RubyStruct(kw): 13950927.6 i/s - 1.30x  slower
         Struct(pos): 11052019.8 i/s - 1.64x  slower
          Struct(kw):  6060982.2 i/s - 2.98x  slower
         Data.define:  4832911.8 i/s - 3.74x  slower


### CallNode (8 fields)
ruby 4.0.1 (2026-01-13 revision e04267a14b) +PRISM [x86_64-linux]
Warming up --------------------------------------
         Data.define   205.900k i/100ms
          Struct(kw)   229.279k i/100ms
         Struct(pos)   934.402k i/100ms
      RubyStruct(kw)   709.635k i/100ms
     RubyStruct(pos)   864.377k i/100ms
          Class(pos)   852.463k i/100ms
           Class(kw)   659.473k i/100ms
Calculating -------------------------------------
         Data.define      2.075M (± 2.9%) i/s  (481.90 ns/i) -     10.501M in   5.064753s
          Struct(kw)      2.294M (± 2.5%) i/s  (435.97 ns/i) -     11.464M in   5.000952s
         Struct(pos)      9.039M (± 2.9%) i/s  (110.63 ns/i) -     45.786M in   5.069807s
      RubyStruct(kw)      6.632M (± 2.4%) i/s  (150.78 ns/i) -     33.353M in   5.032069s
     RubyStruct(pos)      8.076M (± 2.6%) i/s  (123.82 ns/i) -     40.626M in   5.033995s
          Class(pos)      8.118M (± 2.4%) i/s  (123.18 ns/i) -     40.918M in   5.043194s
           Class(kw)      6.483M (± 2.6%) i/s  (154.24 ns/i) -     32.974M in   5.089620s

Comparison:
         Struct(pos):  9039100.1 i/s
          Class(pos):  8118356.1 i/s - 1.11x  slower
     RubyStruct(pos):  8076016.2 i/s - 1.12x  slower
      RubyStruct(kw):  6632014.3 i/s - 1.36x  slower
           Class(kw):  6483276.5 i/s - 1.39x  slower
          Struct(kw):  2293749.0 i/s - 3.94x  slower
         Data.define:  2075108.0 i/s - 4.36x  slower


### Bulk: Loc 2M objects
Data.define      0.616s
Struct(pos)      0.186s
RubyStruct(pos)  0.113s
Class(pos)       0.133s
Class(kw)        0.140s
Integer          0.049s
