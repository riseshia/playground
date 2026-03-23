Ruby 4.0.1 (x86_64-linux)

### Loc (1 field)
ruby 4.0.1 (2026-01-13 revision e04267a14b) +YJIT +PRISM [x86_64-linux]
Warming up --------------------------------------
         Data.define   525.771k i/100ms
          Struct(kw)   651.571k i/100ms
         Struct(pos)     1.257M i/100ms
      RubyStruct(kw)     2.595M i/100ms
     RubyStruct(pos)     2.651M i/100ms
          Class(pos)     2.768M i/100ms
           Class(kw)     2.724M i/100ms
Calculating -------------------------------------
         Data.define      5.633M (± 1.5%) i/s  (177.53 ns/i) -     28.392M in   5.041660s
          Struct(kw)      7.240M (± 1.8%) i/s  (138.12 ns/i) -     36.488M in   5.041487s
         Struct(pos)     14.729M (± 3.5%) i/s   (67.89 ns/i) -     74.168M in   5.041935s
      RubyStruct(kw)     29.932M (± 1.4%) i/s   (33.41 ns/i) -    150.517M in   5.029647s
     RubyStruct(pos)     29.894M (± 1.7%) i/s   (33.45 ns/i) -    151.100M in   5.055945s
          Class(pos)     30.580M (± 1.4%) i/s   (32.70 ns/i) -    155.026M in   5.070536s
           Class(kw)     29.835M (± 1.8%) i/s   (33.52 ns/i) -    149.832M in   5.023652s

Comparison:
          Class(pos): 30579790.2 i/s
      RubyStruct(kw): 29931908.8 i/s - same-ish: difference falls within error
     RubyStruct(pos): 29894258.4 i/s - same-ish: difference falls within error
           Class(kw): 29835251.1 i/s - same-ish: difference falls within error
         Struct(pos): 14729272.9 i/s - 2.08x  slower
          Struct(kw):  7239925.4 i/s - 4.22x  slower
         Data.define:  5632736.8 i/s - 5.43x  slower


### CallNode (8 fields)
ruby 4.0.1 (2026-01-13 revision e04267a14b) +YJIT +PRISM [x86_64-linux]
Warming up --------------------------------------
         Data.define   205.424k i/100ms
          Struct(kw)   225.272k i/100ms
         Struct(pos)     1.057M i/100ms
      RubyStruct(kw)     1.960M i/100ms
     RubyStruct(pos)     2.014M i/100ms
          Class(pos)     2.042M i/100ms
           Class(kw)     2.068M i/100ms
Calculating -------------------------------------
         Data.define      2.215M (± 2.3%) i/s  (451.53 ns/i) -     11.093M in   5.011585s
          Struct(kw)      2.445M (± 1.9%) i/s  (408.97 ns/i) -     12.390M in   5.068921s
         Struct(pos)     11.441M (± 2.2%) i/s   (87.40 ns/i) -     58.135M in   5.083783s
      RubyStruct(kw)     20.908M (± 2.2%) i/s   (47.83 ns/i) -    105.863M in   5.065823s
     RubyStruct(pos)     21.241M (± 2.2%) i/s   (47.08 ns/i) -    106.723M in   5.026990s
          Class(pos)     21.958M (± 2.2%) i/s   (45.54 ns/i) -    110.277M in   5.024628s
           Class(kw)     22.429M (± 2.3%) i/s   (44.59 ns/i) -    113.752M in   5.074279s

Comparison:
           Class(kw): 22428992.3 i/s
          Class(pos): 21957669.4 i/s - same-ish: difference falls within error
     RubyStruct(pos): 21240681.6 i/s - 1.06x  slower
      RubyStruct(kw): 20907894.4 i/s - 1.07x  slower
         Struct(pos): 11441091.9 i/s - 1.96x  slower
          Struct(kw):  2445174.3 i/s - 9.17x  slower
         Data.define:  2214680.7 i/s - 10.13x  slower


### Bulk: Loc 2M objects
Data.define      0.517s
Struct(pos)      0.148s
RubyStruct(pos)  0.072s
Class(pos)       0.110s
Class(kw)        0.072s
Integer          0.041s
