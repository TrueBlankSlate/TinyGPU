# import_sources.tcl
#
# Repo-relative -- computed from this script's own location, so this repo
# works unmodified no matter where it's cloned. Scripts live in build/, so
# one level up is the repo root.
set repo_root [file normalize [file dirname [info script]]/..]
set rtl_dir   "$repo_root/src/rtl/tinygpu"
set sim_dir   "$repo_root/src/tb"
set cvxif_dir "$repo_root/src/rtl/cvxif"
set build_dir "$repo_root/build"

# Convention: clone the CVA6 core repo as a SIBLING of wherever you clone
# this TinyGPU repo (e.g. <parent>/TinyGPU/... and <parent>/CVA6/cva6).
# Override this line if your CVA6 clone lives somewhere else.
set CVA6_ROOT [file normalize "$repo_root/../../CVA6/cva6"]


# ---------------------------------------------------------------------
# 1. External CVA6 core (untouched, shared with 0_2_CVA6)
# ---------------------------------------------------------------------
set cva6_core_files [list \
    "$CVA6_ROOT/common/local/util/ex_trace_item.svh" \
    "$CVA6_ROOT/common/local/util/instr_trace_item.svh" \
    "$CVA6_ROOT/common/local/util/instr_tracer.sv" \
    "$CVA6_ROOT/common/local/util/sram.sv" \
    "$CVA6_ROOT/common/local/util/sram_cache.sv" \
    "$CVA6_ROOT/common/local/util/tc_sram_wrapper.sv" \
    "$CVA6_ROOT/common/local/util/tc_sram_wrapper_cache_techno.sv" \
    "$CVA6_ROOT/core/acc_dispatcher.sv" \
    "$CVA6_ROOT/core/aes.sv" \
    "$CVA6_ROOT/core/alu.sv" \
    "$CVA6_ROOT/core/alu_wrapper.sv" \
    "$CVA6_ROOT/core/amo_buffer.sv" \
    "$CVA6_ROOT/core/ariane_regfile_ff.sv" \
    "$CVA6_ROOT/core/ariane_regfile_fpga.sv" \
    "$CVA6_ROOT/core/axi_shim.sv" \
    "$CVA6_ROOT/core/branch_unit.sv" \
    "$CVA6_ROOT/core/cache_subsystem/axi_adapter.sv" \
    "$CVA6_ROOT/core/cache_subsystem/cache_ctrl.sv" \
    "$CVA6_ROOT/core/cache_subsystem/cva6_hpdcache_if_adapter.sv" \
    "$CVA6_ROOT/core/cache_subsystem/cva6_hpdcache_subsystem.sv" \
    "$CVA6_ROOT/core/cache_subsystem/cva6_hpdcache_subsystem_axi_arbiter.sv" \
    "$CVA6_ROOT/core/cache_subsystem/cva6_hpdcache_wrapper.sv" \
    "$CVA6_ROOT/core/cache_subsystem/cva6_icache.sv" \
    "$CVA6_ROOT/core/cache_subsystem/cva6_icache_axi_wrapper.sv" \
    "$CVA6_ROOT/core/cache_subsystem/hpdcache/rtl/include/hpdcache_typedef.svh" \
    "$CVA6_ROOT/core/cache_subsystem/hpdcache/rtl/src/common/hpdcache_1hot_to_binary.sv" \
    "$CVA6_ROOT/core/cache_subsystem/hpdcache/rtl/src/common/hpdcache_data_downsize.sv" \
    "$CVA6_ROOT/core/cache_subsystem/hpdcache/rtl/src/common/hpdcache_data_resize.sv" \
    "$CVA6_ROOT/core/cache_subsystem/hpdcache/rtl/src/common/hpdcache_data_upsize.sv" \
    "$CVA6_ROOT/core/cache_subsystem/hpdcache/rtl/src/common/hpdcache_decoder.sv" \
    "$CVA6_ROOT/core/cache_subsystem/hpdcache/rtl/src/common/hpdcache_demux.sv" \
    "$CVA6_ROOT/core/cache_subsystem/hpdcache/rtl/src/common/hpdcache_fifo_reg.sv" \
    "$CVA6_ROOT/core/cache_subsystem/hpdcache/rtl/src/common/hpdcache_fifo_reg_initialized.sv" \
    "$CVA6_ROOT/core/cache_subsystem/hpdcache/rtl/src/common/hpdcache_fxarb.sv" \
    "$CVA6_ROOT/core/cache_subsystem/hpdcache/rtl/src/common/hpdcache_lfsr.sv" \
    "$CVA6_ROOT/core/cache_subsystem/hpdcache/rtl/src/common/hpdcache_mux.sv" \
    "$CVA6_ROOT/core/cache_subsystem/hpdcache/rtl/src/common/hpdcache_prio_1hot_encoder.sv" \
    "$CVA6_ROOT/core/cache_subsystem/hpdcache/rtl/src/common/hpdcache_prio_bin_encoder.sv" \
    "$CVA6_ROOT/core/cache_subsystem/hpdcache/rtl/src/common/hpdcache_regbank_wbyteenable_1rw.sv" \
    "$CVA6_ROOT/core/cache_subsystem/hpdcache/rtl/src/common/hpdcache_regbank_wmask_1rw.sv" \
    "$CVA6_ROOT/core/cache_subsystem/hpdcache/rtl/src/common/hpdcache_rrarb.sv" \
    "$CVA6_ROOT/core/cache_subsystem/hpdcache/rtl/src/common/hpdcache_sram.sv" \
    "$CVA6_ROOT/core/cache_subsystem/hpdcache/rtl/src/common/hpdcache_sram_wbyteenable.sv" \
    "$CVA6_ROOT/core/cache_subsystem/hpdcache/rtl/src/common/hpdcache_sram_wmask.sv" \
    "$CVA6_ROOT/core/cache_subsystem/hpdcache/rtl/src/common/hpdcache_sync_buffer.sv" \
    "$CVA6_ROOT/core/cache_subsystem/hpdcache/rtl/src/common/macros/behav/hpdcache_sram_1rw.sv" \
    "$CVA6_ROOT/core/cache_subsystem/hpdcache/rtl/src/common/macros/behav/hpdcache_sram_wbyteenable_1rw.sv" \
    "$CVA6_ROOT/core/cache_subsystem/hpdcache/rtl/src/common/macros/behav/hpdcache_sram_wmask_1rw.sv" \
    "$CVA6_ROOT/core/cache_subsystem/hpdcache/rtl/src/hpdcache.sv" \
    "$CVA6_ROOT/core/cache_subsystem/hpdcache/rtl/src/hpdcache_amo.sv" \
    "$CVA6_ROOT/core/cache_subsystem/hpdcache/rtl/src/hpdcache_cbuf.sv" \
    "$CVA6_ROOT/core/cache_subsystem/hpdcache/rtl/src/hpdcache_cmo.sv" \
    "$CVA6_ROOT/core/cache_subsystem/hpdcache/rtl/src/hpdcache_core_arbiter.sv" \
    "$CVA6_ROOT/core/cache_subsystem/hpdcache/rtl/src/hpdcache_ctrl.sv" \
    "$CVA6_ROOT/core/cache_subsystem/hpdcache/rtl/src/hpdcache_ctrl_pe.sv" \
    "$CVA6_ROOT/core/cache_subsystem/hpdcache/rtl/src/hpdcache_flush.sv" \
    "$CVA6_ROOT/core/cache_subsystem/hpdcache/rtl/src/hpdcache_memctrl.sv" \
    "$CVA6_ROOT/core/cache_subsystem/hpdcache/rtl/src/hpdcache_miss_handler.sv" \
    "$CVA6_ROOT/core/cache_subsystem/hpdcache/rtl/src/hpdcache_mshr.sv" \
    "$CVA6_ROOT/core/cache_subsystem/hpdcache/rtl/src/hpdcache_pkg.sv" \
    "$CVA6_ROOT/core/cache_subsystem/hpdcache/rtl/src/hpdcache_rtab.sv" \
    "$CVA6_ROOT/core/cache_subsystem/hpdcache/rtl/src/hpdcache_uncached.sv" \
    "$CVA6_ROOT/core/cache_subsystem/hpdcache/rtl/src/hpdcache_victim_plru.sv" \
    "$CVA6_ROOT/core/cache_subsystem/hpdcache/rtl/src/hpdcache_victim_random.sv" \
    "$CVA6_ROOT/core/cache_subsystem/hpdcache/rtl/src/hpdcache_victim_sel.sv" \
    "$CVA6_ROOT/core/cache_subsystem/hpdcache/rtl/src/hpdcache_wbuf.sv" \
    "$CVA6_ROOT/core/cache_subsystem/hpdcache/rtl/src/hwpf_stride/hwpf_stride.sv" \
    "$CVA6_ROOT/core/cache_subsystem/hpdcache/rtl/src/hwpf_stride/hwpf_stride_arb.sv" \
    "$CVA6_ROOT/core/cache_subsystem/hpdcache/rtl/src/hwpf_stride/hwpf_stride_pkg.sv" \
    "$CVA6_ROOT/core/cache_subsystem/hpdcache/rtl/src/hwpf_stride/hwpf_stride_wrapper.sv" \
    "$CVA6_ROOT/core/cache_subsystem/hpdcache/rtl/src/utils/hpdcache_mem_req_read_arbiter.sv" \
    "$CVA6_ROOT/core/cache_subsystem/hpdcache/rtl/src/utils/hpdcache_mem_req_write_arbiter.sv" \
    "$CVA6_ROOT/core/cache_subsystem/hpdcache/rtl/src/utils/hpdcache_mem_resp_demux.sv" \
    "$CVA6_ROOT/core/cache_subsystem/hpdcache/rtl/src/utils/hpdcache_mem_to_axi_read.sv" \
    "$CVA6_ROOT/core/cache_subsystem/hpdcache/rtl/src/utils/hpdcache_mem_to_axi_write.sv" \
    "$CVA6_ROOT/core/cache_subsystem/miss_handler.sv" \
    "$CVA6_ROOT/core/cache_subsystem/std_cache_subsystem.sv" \
    "$CVA6_ROOT/core/cache_subsystem/std_nbdcache.sv" \
    "$CVA6_ROOT/core/cache_subsystem/tag_cmp.sv" \
    "$CVA6_ROOT/core/cache_subsystem/wt_axi_adapter.sv" \
    "$CVA6_ROOT/core/cache_subsystem/wt_cache_subsystem.sv" \
    "$CVA6_ROOT/core/cache_subsystem/wt_dcache.sv" \
    "$CVA6_ROOT/core/cache_subsystem/wt_dcache_ctrl.sv" \
    "$CVA6_ROOT/core/cache_subsystem/wt_dcache_mem.sv" \
    "$CVA6_ROOT/core/cache_subsystem/wt_dcache_missunit.sv" \
    "$CVA6_ROOT/core/cache_subsystem/wt_dcache_wbuffer.sv" \
    "$CVA6_ROOT/core/commit_stage.sv" \
    "$CVA6_ROOT/core/compressed_decoder.sv" \
    "$CVA6_ROOT/core/controller.sv" \
    "$CVA6_ROOT/core/csr_buffer.sv" \
    "$CVA6_ROOT/core/csr_regfile.sv" \
    "$CVA6_ROOT/core/cva6.sv" \
    "$CVA6_ROOT/core/cva6_accel_first_pass_decoder_stub.sv" \
    "$CVA6_ROOT/core/cva6_fifo_v3.sv" \
    "$CVA6_ROOT/core/cva6_mmu/cva6_mmu.sv" \
    "$CVA6_ROOT/core/cva6_mmu/cva6_ptw.sv" \
    "$CVA6_ROOT/core/cva6_mmu/cva6_shared_tlb.sv" \
    "$CVA6_ROOT/core/cva6_mmu/cva6_tlb.sv" \
    "$CVA6_ROOT/core/cva6_rvfi_probes.sv" \
    "$CVA6_ROOT/core/cvfpu/src/fpnew_cast_multi.sv" \
    "$CVA6_ROOT/core/cvfpu/src/fpnew_classifier.sv" \
    "$CVA6_ROOT/core/cvfpu/src/fpnew_divsqrt_multi.sv" \
    "$CVA6_ROOT/core/cvfpu/src/fpnew_divsqrt_th_32.sv" \
    "$CVA6_ROOT/core/cvfpu/src/fpnew_divsqrt_th_64_multi.sv" \
    "$CVA6_ROOT/core/cvfpu/src/fpnew_fma.sv" \
    "$CVA6_ROOT/core/cvfpu/src/fpnew_fma_multi.sv" \
    "$CVA6_ROOT/core/cvfpu/src/fpnew_noncomp.sv" \
    "$CVA6_ROOT/core/cvfpu/src/fpnew_opgroup_block.sv" \
    "$CVA6_ROOT/core/cvfpu/src/fpnew_opgroup_fmt_slice.sv" \
    "$CVA6_ROOT/core/cvfpu/src/fpnew_opgroup_multifmt_slice.sv" \
    "$CVA6_ROOT/core/cvfpu/src/fpnew_pkg.sv" \
    "$CVA6_ROOT/core/cvfpu/src/fpnew_rounding.sv" \
    "$CVA6_ROOT/core/cvfpu/src/fpnew_top.sv" \
    "$CVA6_ROOT/core/cvfpu/src/fpu_div_sqrt_mvp/hdl/control_mvp.sv" \
    "$CVA6_ROOT/core/cvfpu/src/fpu_div_sqrt_mvp/hdl/defs_div_sqrt_mvp.sv" \
    "$CVA6_ROOT/core/cvfpu/src/fpu_div_sqrt_mvp/hdl/div_sqrt_top_mvp.sv" \
    "$CVA6_ROOT/core/cvfpu/src/fpu_div_sqrt_mvp/hdl/iteration_div_sqrt_mvp.sv" \
    "$CVA6_ROOT/core/cvfpu/src/fpu_div_sqrt_mvp/hdl/norm_div_sqrt_mvp.sv" \
    "$CVA6_ROOT/core/cvfpu/src/fpu_div_sqrt_mvp/hdl/nrbd_nrsc_mvp.sv" \
    "$CVA6_ROOT/core/cvfpu/src/fpu_div_sqrt_mvp/hdl/preprocess_mvp.sv" \
    "$CVA6_ROOT/core/cvfpu/vendor/openc910/C910_RTL_FACTORY/gen_rtl/vfdsu/rtl/ct_vfdsu_ctrl.v" \
    "$CVA6_ROOT/core/cvfpu/vendor/openc910/C910_RTL_FACTORY/gen_rtl/vfdsu/rtl/ct_vfdsu_double.v" \
    "$CVA6_ROOT/core/cvfpu/vendor/openc910/C910_RTL_FACTORY/gen_rtl/vfdsu/rtl/ct_vfdsu_ff1.v" \
    "$CVA6_ROOT/core/cvfpu/vendor/openc910/C910_RTL_FACTORY/gen_rtl/vfdsu/rtl/ct_vfdsu_pack.v" \
    "$CVA6_ROOT/core/cvfpu/vendor/openc910/C910_RTL_FACTORY/gen_rtl/vfdsu/rtl/ct_vfdsu_prepare.v" \
    "$CVA6_ROOT/core/cvfpu/vendor/openc910/C910_RTL_FACTORY/gen_rtl/vfdsu/rtl/ct_vfdsu_round.v" \
    "$CVA6_ROOT/core/cvfpu/vendor/openc910/C910_RTL_FACTORY/gen_rtl/vfdsu/rtl/ct_vfdsu_scalar_dp.v" \
    "$CVA6_ROOT/core/cvfpu/vendor/openc910/C910_RTL_FACTORY/gen_rtl/vfdsu/rtl/ct_vfdsu_srt.v" \
    "$CVA6_ROOT/core/cvfpu/vendor/openc910/C910_RTL_FACTORY/gen_rtl/vfdsu/rtl/ct_vfdsu_srt_radix16_bound_table.v" \
    "$CVA6_ROOT/core/cvfpu/vendor/openc910/C910_RTL_FACTORY/gen_rtl/vfdsu/rtl/ct_vfdsu_srt_radix16_with_sqrt.v" \
    "$CVA6_ROOT/core/cvfpu/vendor/openc910/C910_RTL_FACTORY/gen_rtl/vfdsu/rtl/ct_vfdsu_top.v" \
    "$CVA6_ROOT/core/cvfpu/vendor/opene906/E906_RTL_FACTORY/gen_rtl/clk/rtl/gated_clk_cell.v" \
    "$CVA6_ROOT/core/cvfpu/vendor/opene906/E906_RTL_FACTORY/gen_rtl/fdsu/rtl/pa_fdsu_ctrl.v" \
    "$CVA6_ROOT/core/cvfpu/vendor/opene906/E906_RTL_FACTORY/gen_rtl/fdsu/rtl/pa_fdsu_ff1.v" \
    "$CVA6_ROOT/core/cvfpu/vendor/opene906/E906_RTL_FACTORY/gen_rtl/fdsu/rtl/pa_fdsu_pack_single.v" \
    "$CVA6_ROOT/core/cvfpu/vendor/opene906/E906_RTL_FACTORY/gen_rtl/fdsu/rtl/pa_fdsu_prepare.v" \
    "$CVA6_ROOT/core/cvfpu/vendor/opene906/E906_RTL_FACTORY/gen_rtl/fdsu/rtl/pa_fdsu_round_single.v" \
    "$CVA6_ROOT/core/cvfpu/vendor/opene906/E906_RTL_FACTORY/gen_rtl/fdsu/rtl/pa_fdsu_special.v" \
    "$CVA6_ROOT/core/cvfpu/vendor/opene906/E906_RTL_FACTORY/gen_rtl/fdsu/rtl/pa_fdsu_srt_single.v" \
    "$CVA6_ROOT/core/cvfpu/vendor/opene906/E906_RTL_FACTORY/gen_rtl/fdsu/rtl/pa_fdsu_top.v" \
    "$CVA6_ROOT/core/cvfpu/vendor/opene906/E906_RTL_FACTORY/gen_rtl/fpu/rtl/pa_fpu_dp.v" \
    "$CVA6_ROOT/core/cvfpu/vendor/opene906/E906_RTL_FACTORY/gen_rtl/fpu/rtl/pa_fpu_frbus.v" \
    "$CVA6_ROOT/core/cvfpu/vendor/opene906/E906_RTL_FACTORY/gen_rtl/fpu/rtl/pa_fpu_src_type.v" \
    "$CVA6_ROOT/core/cvxif_compressed_if_driver.sv" \
    "$CVA6_ROOT/core/cvxif_fu.sv" \
    "$CVA6_ROOT/core/cvxif_issue_register_commit_if_driver.sv" \
    "$CVA6_ROOT/core/decoder.sv" \
    "$CVA6_ROOT/core/ex_stage.sv" \
    "$CVA6_ROOT/core/fpu_wrap.sv" \
    "$CVA6_ROOT/core/frontend/bht.sv" \
    "$CVA6_ROOT/core/frontend/bht2lvl.sv" \
    "$CVA6_ROOT/core/frontend/btb.sv" \
    "$CVA6_ROOT/core/frontend/frontend.sv" \
    "$CVA6_ROOT/core/frontend/instr_queue.sv" \
    "$CVA6_ROOT/core/frontend/instr_scan.sv" \
    "$CVA6_ROOT/core/frontend/ras.sv" \
    "$CVA6_ROOT/core/id_stage.sv" \
    "$CVA6_ROOT/core/include/aes_pkg.sv" \
    "$CVA6_ROOT/core/include/ariane_pkg.sv" \
    "$CVA6_ROOT/core/include/build_config_pkg.sv" \
    "$CVA6_ROOT/core/include/config_pkg.sv" \
    "$CVA6_ROOT/core/include/cv64a6_imafdc_sv39_config_pkg.sv" \
    "$CVA6_ROOT/core/include/cvxif_types.svh" \
    "$CVA6_ROOT/core/include/dummy_l15_pkg.sv" \
    "$CVA6_ROOT/core/include/instr_tracer_pkg.sv" \
    "$CVA6_ROOT/core/include/riscv_pkg.sv" \
    "$CVA6_ROOT/core/include/rvfi_types.svh" \
    "$CVA6_ROOT/core/include/std_cache_pkg.sv" \
    "$CVA6_ROOT/core/include/triggers_pkg.sv" \
    "$CVA6_ROOT/core/include/wt_cache_pkg.sv" \
    "$CVA6_ROOT/core/instr_realign.sv" \
    "$CVA6_ROOT/core/issue_read_operands.sv" \
    "$CVA6_ROOT/core/issue_stage.sv" \
    "$CVA6_ROOT/core/load_store_unit.sv" \
    "$CVA6_ROOT/core/load_unit.sv" \
    "$CVA6_ROOT/core/lsu_bypass.sv" \
    "$CVA6_ROOT/core/macro_decoder.sv" \
    "$CVA6_ROOT/core/mult.sv" \
    "$CVA6_ROOT/core/multiplier.sv" \
    "$CVA6_ROOT/core/perf_counters.sv" \
    "$CVA6_ROOT/core/pmp/src/pmp.sv" \
    "$CVA6_ROOT/core/pmp/src/pmp_data_if.sv" \
    "$CVA6_ROOT/core/pmp/src/pmp_entry.sv" \
    "$CVA6_ROOT/core/raw_checker.sv" \
    "$CVA6_ROOT/core/scoreboard.sv" \
    "$CVA6_ROOT/core/serdiv.sv" \
    "$CVA6_ROOT/core/store_buffer.sv" \
    "$CVA6_ROOT/core/store_unit.sv" \
    "$CVA6_ROOT/core/trigger_module.sv" \
    "$CVA6_ROOT/core/zcmt_decoder.sv" \
    "$CVA6_ROOT/vendor/pulp-platform/axi/include/axi/assign.svh" \
    "$CVA6_ROOT/vendor/pulp-platform/axi/include/axi/typedef.svh" \
    "$CVA6_ROOT/vendor/pulp-platform/axi/src/axi_id_prepend.sv" \
    "$CVA6_ROOT/vendor/pulp-platform/axi/src/axi_mux.sv" \
    "$CVA6_ROOT/vendor/pulp-platform/axi/src/axi_pkg.sv" \
    "$CVA6_ROOT/vendor/pulp-platform/common_cells/include/common_cells/registers.svh" \
    "$CVA6_ROOT/vendor/pulp-platform/common_cells/src/cf_math_pkg.sv" \
    "$CVA6_ROOT/vendor/pulp-platform/common_cells/src/counter.sv" \
    "$CVA6_ROOT/vendor/pulp-platform/common_cells/src/delta_counter.sv" \
    "$CVA6_ROOT/vendor/pulp-platform/common_cells/src/exp_backoff.sv" \
    "$CVA6_ROOT/vendor/pulp-platform/common_cells/src/fifo_v3.sv" \
    "$CVA6_ROOT/vendor/pulp-platform/common_cells/src/lfsr.sv" \
    "$CVA6_ROOT/vendor/pulp-platform/common_cells/src/lfsr_8bit.sv" \
    "$CVA6_ROOT/vendor/pulp-platform/common_cells/src/lzc.sv" \
    "$CVA6_ROOT/vendor/pulp-platform/common_cells/src/popcount.sv" \
    "$CVA6_ROOT/vendor/pulp-platform/common_cells/src/rr_arb_tree.sv" \
    "$CVA6_ROOT/vendor/pulp-platform/common_cells/src/shift_reg.sv" \
    "$CVA6_ROOT/vendor/pulp-platform/common_cells/src/spill_register.sv" \
    "$CVA6_ROOT/vendor/pulp-platform/common_cells/src/spill_register_flushable.sv" \
    "$CVA6_ROOT/vendor/pulp-platform/common_cells/src/stream_arbiter.sv" \
    "$CVA6_ROOT/vendor/pulp-platform/common_cells/src/stream_arbiter_flushable.sv" \
    "$CVA6_ROOT/vendor/pulp-platform/common_cells/src/stream_demux.sv" \
    "$CVA6_ROOT/vendor/pulp-platform/common_cells/src/stream_mux.sv" \
    "$CVA6_ROOT/vendor/pulp-platform/common_cells/src/unread.sv" \
    "$CVA6_ROOT/vendor/pulp-platform/fpga-support/rtl/AsyncDpRam.sv" \
    "$CVA6_ROOT/vendor/pulp-platform/fpga-support/rtl/AsyncThreePortRam.sv" \
    "$CVA6_ROOT/vendor/pulp-platform/fpga-support/rtl/SyncDpRam.sv" \
    "$CVA6_ROOT/vendor/pulp-platform/fpga-support/rtl/SyncDpRam_ind_r_w.sv" \
    "$CVA6_ROOT/vendor/pulp-platform/fpga-support/rtl/SyncThreePortRam.sv" \
    "$CVA6_ROOT/vendor/pulp-platform/tech_cells_generic/src/rtl/tc_sram.sv" \
]

# ---------------------------------------------------------------------
# 2. TinyGPU RTL -- split across src/rtl/cvxif/ (CVXIF boundary + real AXI
#    slave) and src/rtl/tinygpu/ (everything else)
# ---------------------------------------------------------------------
set tg_rtl_files [list \
    $rtl_dir/alu.v \
    $cvxif_dir/axi4_bram_slave.v \
    $rtl_dir/cache.v \
    $rtl_dir/cache_l3.v \
    $cvxif_dir/cva6_sv_shim.sv \
    $cvxif_dir/cva6_tinygpu_soc.v \
    $rtl_dir/design_1.v \
    $rtl_dir/design_1_wrapper.v \
    $rtl_dir/fourc_1.v \
    $rtl_dir/fourc_1_wrapper.v \
    $rtl_dir/register_file.v \
    $rtl_dir/tingpu_decoder.v \
    $cvxif_dir/tinygpu_cvxif_wrap.v \
    $cvxif_dir/tinygpu_fsm.v \
    $rtl_dir/writeback.v \
    $rtl_dir/fpga_top.v \
]

# ---------------------------------------------------------------------
# 3. TinyGPU simulation sources (src/tb/, plus axi4_mem_slave.v which
#    lives in src/rtl/cvxif/ -- includes the Option B fix already applied
#    to tb_cva6_boot.v: an extra vse64.v writes C_mul out to
#    MUL_RESULT_ADDR right after vmacc, BEFORE vadd.vv overwrites the
#    shared vd_* latch. RESULT_ADDR still holds C_add.
#
#    tb_boot_image.v is a second testbench that instantiates the REAL,
#    synthesizable axi4_bram_slave.v and $readmemh's the exact
#    boot_image.hex real hardware loads (fw/build.sh's output), unlike
#    tb_cva6_boot.v which pokes a hand-written instruction stream directly
#    into axi4_mem_slave.v's array and never touches boot_image.hex at
#    all. Use it to verify a freshly rebuilt boot_image.hex BEFORE
#    touching synth/impl/hardware.)
# ---------------------------------------------------------------------
set tg_sim_files [list \
    $sim_dir/tb_cva6_boot.v \
    $sim_dir/tb_boot_image.v \
    $sim_dir/tb_matmul.v \
    $sim_dir/tb_tinygpu_cvxif.v \
    $cvxif_dir/axi4_mem_slave.v \
]

# ---------------------------------------------------------------------
# 4. Add everything
# ---------------------------------------------------------------------
add_files -norecurse $cva6_core_files
add_files -norecurse $tg_rtl_files
add_files -fileset sim_1 -norecurse $tg_sim_files

# boot_image.hex -- axi4_bram_slave.v's $readmemh INIT_FILE. Added as a
# plain file (not HDL) so Vivado copies/tracks it; it must sit next to
# the compiled sources at elaboration time the same way it does in
# 0_2_CVA6.
add_files -norecurse -fileset sources_1 $repo_root/boot_image.hex
set_property file_type "Memory Initialization Files" [get_files $repo_root/boot_image.hex]

# Constraints
add_files -fileset constrs_1 -norecurse $build_dir/fpga_top.xdc

# `include` search paths -- exact 6-directory list pulled from
# 0_2_CVA6.xpr's own VerilogDir properties (sources_1 fileset), not
# guessed. Missing any of these causes an "cannot open include file"
# compile error (e.g. common_cells/registers.svh, axi/typedef.svh,
# hpdcache_typedef.svh) since CVA6's `include directives are written as
# paths relative to one of these roots, not absolute/local paths.
set cva6_include_dirs [list \
    "$CVA6_ROOT/core/include" \
    "$CVA6_ROOT/vendor/pulp-platform/common_cells/include" \
    "$CVA6_ROOT/vendor/pulp-platform/common_cells/src" \
    "$CVA6_ROOT/vendor/pulp-platform/axi/include" \
    "$CVA6_ROOT/common/local/util" \
    "$CVA6_ROOT/core/cache_subsystem/hpdcache/rtl/include" \
]
set_property include_dirs $cva6_include_dirs [get_filesets sources_1]
set_property include_dirs $cva6_include_dirs [get_filesets sim_1]

# XSIM macro -- several pulp-platform common_cells files (e.g.
# rr_arb_tree.sv:116, `ifndef XSIM ... default disable iff (...) ...
# `endif) guard an SVA construct XSim doesn't support behind this
# define. Confirmed via 0_2_CVA6.xpr: it sets "Verilog_Define Name=XSIM"
# on sources_1 -- without it, xvlog hits "Default Disable iff
# declaration is not supported yet for simulation" and the compile fails.
set_property verilog_define {XSIM} [get_filesets sources_1]
set_property verilog_define {XSIM} [get_filesets sim_1]

update_compile_order -fileset sources_1
update_compile_order -fileset sim_1

# Sim top -- tb_cva6_boot is the full CVA6+TinyGPU boot test (Option B
# fix lives here). Verify THIS in simulation before ever touching
# synth/impl -- zero bitstream risk, fastest possible confidence check.
set_property top tb_cva6_boot [get_filesets sim_1]

puts "\n==== Import complete ===="
puts "CVA6 core files added : [llength $cva6_core_files]"
puts "TinyGPU RTL files added: [llength $tg_rtl_files]"
puts "TinyGPU sim files added: [llength $tg_sim_files]"
puts "boot_image.hex, fpga_top.xdc added."
puts "Sim top set to tb_cva6_boot -- run behavioral simulation now to"
puts {confirm MUL_RESULT_ADDR+15 == 600 (C_mul row3 col3) and}
puts {RESULT_ADDR+15 == 32 (C_add row3 col3) before running synth/impl.}
puts ""
puts "If you rebuild boot_image.hex from fw/ (fw/build.sh), re-run this"
puts "script and switch sim top to tb_boot_image instead:"
puts {  set_property top tb_boot_image [get_filesets sim_1]}
puts "-- it $readmemh's boot_image.hex through the real axi4_bram_slave.v,"
puts "the same path real hardware takes, rather than tb_cva6_boot.v's"
puts "hand-poked instruction stream."
puts ""
puts "NOTE: the PS7 block design (zynq_system.bd) is NOT created by this"
puts "script -- that's a separate step. Once sim confirms Option B works,"
puts "run build_zynq_bd.tcl, then connect_gp0_direct.tcl (both repo-"
puts "relative, no hardcoded paths -- see build/ for the full sequence)"
puts "to create the PS7+GP0-direct-wiring block design in this project."

