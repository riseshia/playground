Ruby 4.0.1 (x86_64-linux)

### Loc (1 field)
ruby 4.0.1 (2026-01-13 revision e04267a14b) +PRISM [x86_64-linux]
Warming up --------------------------------------
     Data.define(kw)   474.443k i/100ms
    Data.define(pos)   459.444k i/100ms
          Struct(kw)   583.215k i/100ms
         Struct(pos)     1.103M i/100ms
      RubyStruct(kw)     1.407M i/100ms
     RubyStruct(pos)     1.586M i/100ms
          Class(pos)     1.833M i/100ms
           Class(kw)     1.461M i/100ms
Calculating -------------------------------------
     Data.define(kw)      4.764M (± 3.4%) i/s  (209.92 ns/i) -     24.197M in   5.085393s
    Data.define(pos)      4.625M (± 2.1%) i/s  (216.20 ns/i) -     23.432M in   5.068215s
          Struct(kw)      5.708M (± 2.8%) i/s  (175.18 ns/i) -     28.578M in   5.010405s
         Struct(pos)     11.306M (± 2.2%) i/s   (88.45 ns/i) -     57.344M in   5.074614s
      RubyStruct(kw)     14.085M (± 5.6%) i/s   (71.00 ns/i) -     70.360M in   5.017232s
     RubyStruct(pos)     15.243M (± 1.6%) i/s   (65.61 ns/i) -     77.738M in   5.101395s
          Class(pos)     17.164M (± 1.8%) i/s   (58.26 ns/i) -     86.129M in   5.019631s
           Class(kw)     14.273M (± 1.7%) i/s   (70.06 ns/i) -     71.582M in   5.016885s

Comparison:
          Class(pos): 17164003.9 i/s
     RubyStruct(pos): 15242578.9 i/s - 1.13x  slower
           Class(kw): 14272518.4 i/s - 1.20x  slower
      RubyStruct(kw): 14085009.5 i/s - 1.22x  slower
         Struct(pos): 11305696.5 i/s - 1.52x  slower
          Struct(kw):  5708354.2 i/s - 3.01x  slower
     Data.define(kw):  4763805.2 i/s - 3.60x  slower
    Data.define(pos):  4625320.2 i/s - 3.71x  slower


### CallNode (8 fields)
ruby 4.0.1 (2026-01-13 revision e04267a14b) +PRISM [x86_64-linux]
Warming up --------------------------------------
     Data.define(kw)   193.679k i/100ms
    Data.define(pos)   190.364k i/100ms
          Struct(kw)   208.404k i/100ms
         Struct(pos)   869.054k i/100ms
      RubyStruct(kw)   637.747k i/100ms
     RubyStruct(pos)   764.801k i/100ms
          Class(pos)   791.893k i/100ms
           Class(kw)   611.511k i/100ms
Calculating -------------------------------------
     Data.define(kw)      2.014M (± 2.2%) i/s  (496.62 ns/i) -     10.071M in   5.004024s
    Data.define(pos)      1.963M (± 4.8%) i/s  (509.49 ns/i) -      9.899M in   5.057108s
          Struct(kw)      2.081M (± 6.2%) i/s  (480.60 ns/i) -     10.420M in   5.031481s
         Struct(pos)      8.284M (± 6.6%) i/s  (120.72 ns/i) -     41.715M in   5.061599s
      RubyStruct(kw)      6.316M (± 2.7%) i/s  (158.33 ns/i) -     31.887M in   5.052529s
     RubyStruct(pos)      7.480M (± 4.5%) i/s  (133.70 ns/i) -     37.475M in   5.021982s
          Class(pos)      7.851M (± 3.9%) i/s  (127.38 ns/i) -     39.595M in   5.052321s
           Class(kw)      6.022M (± 2.4%) i/s  (166.06 ns/i) -     30.576M in   5.080437s

Comparison:
         Struct(pos):  8283824.0 i/s
          Class(pos):  7850765.4 i/s - same-ish: difference falls within error
     RubyStruct(pos):  7479608.1 i/s - same-ish: difference falls within error
      RubyStruct(kw):  6315926.2 i/s - 1.31x  slower
           Class(kw):  6021744.8 i/s - 1.38x  slower
          Struct(kw):  2080724.6 i/s - 3.98x  slower
     Data.define(kw):  2013594.1 i/s - 4.11x  slower
    Data.define(pos):  1962738.8 i/s - 4.22x  slower


### Bulk: Loc 2M objects
Data.define(kw)  0.654s
Data.define(pos)  0.569s
Struct(pos)      0.190s
RubyStruct(pos)  0.119s
Class(pos)       0.134s
Class(kw)        0.165s
Integer          0.049s
