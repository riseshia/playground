# perf プロファイリング結果

- Ruby 4.0.1 (2026-01-13 revision e04267a14b) +PRISM [x86_64-linux]
- YJIT なし
- 各パターン 2000万回生成
- `perf record -g --call-graph dwarf`
- `perf report --stdio --no-children -g none --sort=symbol --percent-limit=0.5`

---

## Class(pos) — 5,159 samples

```
37.58%  vm_exec_core
15.22%  gc_sweep_step
 9.25%  rb_wb_protected_newobj_of
 4.69%  vm_invoke_iseq_block
 2.99%  rb_vm_opt_getconstant_path
 2.67%  vm_sendish.constprop.0
 2.17%  rb_obj_alloc
 2.05%  rb_gc_obj_free_vm_weak_references
 1.98%  rb_gc_obj_free
 1.78%  vm_call_iseq_setup_normal_0start_1params_1locals
 1.59%  rb_gc_heap_id_for_size
 1.51%  rb_class_allocate_instance
 1.40%  vm_invokeblock_i
 1.34%  rb_vm_check_ints
 1.26%  CALLER_SETUP_ARG
 0.56%  each_location.constprop.1
 0.54%  __tls_get_addr
```

kwargs 関連関数なし。shape 探索関数なし。
`vm_call_iseq_setup_normal_0start_1params_1locals` が positional 専用ファストパス。

---

## Class(kw) — 6,125 samples

```
39.02%  vm_exec_core
12.56%  gc_sweep_step
 7.77%  vm_call_iseq_setup_kwparm_kwarg       ← kwargs ディスパッチ
 5.44%  rb_wb_protected_newobj_of
 3.22%  vm_invoke_iseq_block
 3.09%  args_setup_kw_parameters              ← keyword 引数セットアップ
 2.68%  vm_sendish.constprop.0
 1.96%  rb_class_allocate_instance
 1.84%  rb_gc_obj_free
 1.78%  rb_get_alloc_func
 1.62%  rb_gc_obj_free_vm_weak_references
 1.62%  rb_vm_opt_getconstant_path
 1.58%  __tls_get_addr
 1.37%  __memmove_avx_unaligned_erms
 1.36%  rb_id2sym
 1.01%  CALLER_SETUP_ARG
 0.95%  rb_obj_alloc
 0.75%  rb_vm_check_ints
 0.52%  each_location.constprop.1
```

kwargs ディスパッチに **~11%** CPU 消費:
- `vm_call_iseq_setup_kwparm_kwarg` (7.77%) — kwargs 専用コールパス
- `args_setup_kw_parameters` (3.09%) — keyword 名マッチング

---

## Struct(pos) — 7,668 samples

```
24.18%  vm_exec_core
11.68%  rb_shape_get_iv_index                 ← shape 探索
10.69%  rb_ivar_lookup.part.0                 ← ivar ルックアップ
10.22%  gc_sweep_step
 5.48%  rb_wb_protected_newobj_of
 3.51%  vm_call_cfunc_with_frame_
 3.21%  vm_invoke_iseq_block
 2.93%  num_members                           ← メンバ数チェック
 2.69%  rb_struct_initialize_m                ← C 実装の initialize
 2.65%  rb_vm_opt_getconstant_path
 2.05%  struct_alloc
 1.79%  vm_sendish.constprop.0
 1.72%  rb_gc_obj_free
 1.33%  rb_gc_obj_free_vm_weak_references
 1.07%  CALLER_SETUP_ARG
 1.07%  rb_obj_alloc
 1.02%  rb_obj_class
 0.67%  rb_vm_check_ints
 0.64%  vm_call_cfunc_with_frame
 0.61%  rb_attr_get@plt
 0.59%  vm_invokeblock_i
 0.53%  rb_is_instance_id
 0.52%  rb_is_instance_id@plt
```

shape 探索に **~22%** CPU 消費:
- `rb_shape_get_iv_index` (11.68%) — shape ツリー走査で ivar インデックスを検索
- `rb_ivar_lookup.part.0` (10.69%) — 実際の ivar スロットアクセス

C 実装のためバイトコードのインラインキャッシュが使えず、毎回 shape 探索が発生する。

---

## Struct(kw) — 13,092 samples

```
21.52%  vm_exec_core
 7.23%  gc_sweep_step
 7.20%  rb_shape_get_iv_index
 5.95%  rb_ivar_lookup.part.0
 4.96%  rb_wb_protected_newobj_of
 3.23%  rb_obj_class
 3.15%  vm_call_cfunc_with_frame_
 2.15%  vm_sendish.constprop.0
 2.05%  vm_invoke_iseq_block
 2.02%  __tls_get_addr
 1.99%  rb_ec_ensure
 1.98%  CALLER_SETUP_ARG
 1.84%  struct_hash_set_i                     ← Hash 経由メンバ設定
 1.83%  rb_struct_initialize_m
 1.70%  rb_gc_obj_free_vm_weak_references
 1.67%  hash_foreach_ensure
 1.60%  rb_hash_aset                          ← Hash 書き込み
 1.52%  tbl_update_modify
 1.49%  rb_gc_obj_free
 1.47%  rb_mem_clear
 1.43%  rb_hash_foreach                       ← Hash 走査
 1.41%  ar_update
 1.31%  rb_ensure
 1.28%  struct_alloc
 1.27%  hash_foreach_call
 1.24%  vm_call_cfunc_other
 1.05%  rb_attr_get
 1.05%  num_members
 1.04%  hash_aset_insert
 0.90%  rb_get_alloc_func
 0.88%  heap_page_allocate_and_initialize
 0.83%  rb_vm_opt_getconstant_path
 0.71%  ractor_safe_call_cfunc_m1
 0.63%  rb_hash_start
 0.55%  rb_hash_set_ifnone
 0.51%  rb_hash_new_with_size
 0.51%  rb_obj_alloc
```

shape 探索 + Hash 経由メンバ設定:
- shape 系: `rb_shape_get_iv_index` (7.20%) + `rb_ivar_lookup` (5.95%) = ~13%
- Hash 系: `struct_hash_set_i` (1.84%) + `rb_hash_aset` (1.60%) + `rb_hash_foreach` (1.43%) + `ar_update` (1.41%) + `tbl_update_modify` (1.52%) = ~8%

サンプル数が Struct(pos) の 1.7 倍。

---

## Data.define — 16,742 samples

```
10.91%  vm_exec_core
 8.08%  rb_shape_get_iv_index
 6.86%  rb_ivar_lookup.part.0
 6.39%  rb_wb_protected_newobj_of
 6.16%  gc_sweep_step
 4.33%  vm_call0_body                         ← 追加メソッドディスパッチ
 2.60%  vm_call_cfunc_with_frame_
 2.56%  rb_ec_ensure
 2.41%  struct_hash_set_i
 2.38%  ar_update
 2.35%  CALLER_SETUP_ARG
 2.34%  rb_call0                              ← 追加メソッドディスパッチ
 2.09%  vm_invoke_iseq_block
 1.97%  rb_vm_cframe_keyword_p                ← keyword 判別
 1.59%  __tls_get_addr
 1.41%  rb_data_initialize_m
 1.38%  rb_obj_class
 1.37%  hash_foreach_call
 1.33%  rb_vm_opt_getconstant_path
 1.33%  rb_method_call_status.constprop.0
 1.27%  rb_gc_obj_free
 1.24%  rb_gc_obj_free_vm_weak_references
 1.22%  rb_freeze_singleton_class             ← freeze コスト
 1.18%  tbl_update_modify
 1.16%  vm_call_cfunc_other
 1.16%  struct_alloc
 1.14%  vm_call0_cc
 1.06%  rb_keyword_given_p
 1.02%  rb_obj_shape_id
 1.00%  vm_sendish.constprop.0
 0.91%  __tls_get_addr@plt
 0.89%  heap_page_allocate_and_initialize
 0.86%  rb_class_new_instance_pass_kw
 0.85%  hash_foreach_ensure
 0.82%  rb_ensure
 0.81%  tbl_update.isra.0
 0.77%  num_members
 0.66%  rb_obj_freeze_inline
 0.65%  rb_funcallv_kw
 0.65%  rb_hash_aset
 0.58%  hash_iter_lev_inc
 0.55%  rb_hash_new_with_size
 0.53%  rb_data_s_new
 0.51%  rb_hash_foreach
```

Struct(kw) の全コストに加えて:
- 追加メソッドディスパッチ: `vm_call0_body` (4.33%) + `rb_call0` (2.34%) = ~7%
- freeze: `rb_freeze_singleton_class` (1.22%) + `rb_obj_freeze_inline` (0.66%) = ~2%
- keyword 判別: `rb_vm_cframe_keyword_p` (1.97%) + `rb_keyword_given_p` (1.06%) = ~3%

サンプル数が Class(pos) の 3.2 倍。
