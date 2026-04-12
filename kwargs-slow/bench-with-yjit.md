Ruby 4.0.1 (x86_64-linux)

### Loc (1 field)
ruby 4.0.1 (2026-01-13 revision e04267a14b) +YJIT +PRISM [x86_64-linux]
Warming up --------------------------------------
     Data.define(kw)   508.848k i/100ms
    Data.define(pos)   480.028k i/100ms
          Struct(kw)   615.050k i/100ms
         Struct(pos)     1.231M i/100ms
      RubyStruct(kw)     2.616M i/100ms
     RubyStruct(pos)     2.287M i/100ms
          Class(pos)     2.740M i/100ms
           Class(kw)     2.700M i/100ms
Calculating -------------------------------------
     Data.define(kw)      5.390M (± 5.1%) i/s  (185.52 ns/i) -     26.969M in   5.019257s
    Data.define(pos)      5.094M (± 4.2%) i/s  (196.32 ns/i) -     25.441M in   5.004398s
          Struct(kw)      6.560M (± 2.5%) i/s  (152.44 ns/i) -     33.213M in   5.066279s
         Struct(pos)     13.942M (± 1.9%) i/s   (71.73 ns/i) -     70.190M in   5.036265s
      RubyStruct(kw)     27.818M (± 2.7%) i/s   (35.95 ns/i) -    141.265M in   5.081861s
     RubyStruct(pos)     28.917M (± 2.1%) i/s   (34.58 ns/i) -    146.389M in   5.064692s
          Class(pos)     30.207M (± 2.4%) i/s   (33.10 ns/i) -    153.447M in   5.082853s
           Class(kw)     30.162M (± 1.9%) i/s   (33.15 ns/i) -    151.184M in   5.014191s

Comparison:
          Class(pos): 30207496.1 i/s
           Class(kw): 30162333.0 i/s - same-ish: difference falls within error
     RubyStruct(pos): 28916810.3 i/s - same-ish: difference falls within error
      RubyStruct(kw): 27817771.6 i/s - 1.09x  slower
         Struct(pos): 13942035.4 i/s - 2.17x  slower
          Struct(kw):  6559968.3 i/s - 4.60x  slower
     Data.define(kw):  5390175.0 i/s - 5.60x  slower
    Data.define(pos):  5093770.7 i/s - 5.93x  slower


### CallNode (8 fields)
ruby 4.0.1 (2026-01-13 revision e04267a14b) +YJIT +PRISM [x86_64-linux]
Warming up --------------------------------------
     Data.define(kw)   203.032k i/100ms
    Data.define(pos)   205.190k i/100ms
          Struct(kw)   216.637k i/100ms
         Struct(pos)   969.835k i/100ms
      RubyStruct(kw)     1.870M i/100ms
     RubyStruct(pos)     1.846M i/100ms
          Class(pos)     1.810M i/100ms
           Class(kw)     1.900M i/100ms
Calculating -------------------------------------
     Data.define(kw)      2.135M (± 2.9%) i/s  (468.41 ns/i) -     10.761M in   5.044887s
    Data.define(pos)      2.065M (± 5.2%) i/s  (484.17 ns/i) -     10.465M in   5.084350s
          Struct(kw)      2.335M (± 2.8%) i/s  (428.27 ns/i) -     11.698M in   5.014005s
         Struct(pos)     11.379M (± 2.5%) i/s   (87.88 ns/i) -     57.220M in   5.031648s
      RubyStruct(kw)     20.473M (± 1.6%) i/s   (48.84 ns/i) -    102.871M in   5.025980s
     RubyStruct(pos)     20.445M (± 2.1%) i/s   (48.91 ns/i) -    103.384M in   5.059129s
          Class(pos)     21.252M (± 1.7%) i/s   (47.05 ns/i) -    106.773M in   5.025552s
           Class(kw)     21.388M (± 1.4%) i/s   (46.75 ns/i) -    108.299M in   5.064405s

Comparison:
           Class(kw): 21388389.5 i/s
          Class(pos): 21251972.3 i/s - same-ish: difference falls within error
      RubyStruct(kw): 20473161.6 i/s - 1.04x  slower
     RubyStruct(pos): 20444954.1 i/s - 1.05x  slower
         Struct(pos): 11379410.4 i/s - 1.88x  slower
          Struct(kw):  2335001.7 i/s - 9.16x  slower
     Data.define(kw):  2134861.3 i/s - 10.02x  slower
    Data.define(pos):  2065377.7 i/s - 10.36x  slower


### Bulk: Loc 2M objects
Data.define(kw)  0.533s
Data.define(pos)  0.476s
Struct(pos)      0.149s
RubyStruct(pos)  0.075s
Class(pos)       0.070s
Class(kw)        0.077s
Integer          0.043s
