# ---------------------------------------------------------------------------
# Adds CVA6 (core-only, no corev_apu SoC peripherals, no cvxif_example) and
# TinyGPU coprocessor sources to the CURRENT Vivado project.
#
# Usage: open/create an empty Vivado project, then in the Tcl Console:
#   source {D:/TinyGPU/TinyGPU/scripts/add_sources.tcl}
#
# Adjust CVA6_DIR / TINYGPU_DIR below if your clones live elsewhere.
# ---------------------------------------------------------------------------

set CVA6_DIR      "D:/CVA6/cva6"
set HPDCACHE_DIR  "$CVA6_DIR/core/cache_subsystem/hpdcache"
set TINYGPU_DIR   "D:/TinyGPU/TinyGPU/4_64_Core"
set TARGET_CFG    "cv64a6_imafdc_sv39"

# ---------------------------------------------------------------------------
# 1. CVA6 core sources, in dependency order (packages before consumers).
#    This is core/Flist.cva6 with corev_apu/* (full reference SoC) and
#    core/cvxif_example/* (CVA6's own demo coprocessor) removed, since
#    TinyGPU is standing in as the CVXIF coprocessor instead.
# ---------------------------------------------------------------------------
set cva6_files [list \
  "$CVA6_DIR/vendor/pulp-platform/fpga-support/rtl/SyncDpRam.sv" \
  "$CVA6_DIR/vendor/pulp-platform/fpga-support/rtl/AsyncDpRam.sv" \
  "$CVA6_DIR/vendor/pulp-platform/fpga-support/rtl/AsyncThreePortRam.sv" \
  "$CVA6_DIR/vendor/pulp-platform/fpga-support/rtl/SyncThreePortRam.sv" \
  "$CVA6_DIR/vendor/pulp-platform/fpga-support/rtl/SyncDpRam_ind_r_w.sv" \
  \
  "$CVA6_DIR/core/cvfpu/src/fpnew_pkg.sv" \
  "$CVA6_DIR/core/cvfpu/src/fpnew_cast_multi.sv" \
  "$CVA6_DIR/core/cvfpu/src/fpnew_classifier.sv" \
  "$CVA6_DIR/core/cvfpu/vendor/opene906/E906_RTL_FACTORY/gen_rtl/clk/rtl/gated_clk_cell.v" \
  "$CVA6_DIR/core/cvfpu/vendor/opene906/E906_RTL_FACTORY/gen_rtl/fdsu/rtl/pa_fdsu_ctrl.v" \
  "$CVA6_DIR/core/cvfpu/vendor/opene906/E906_RTL_FACTORY/gen_rtl/fdsu/rtl/pa_fdsu_ff1.v" \
  "$CVA6_DIR/core/cvfpu/vendor/opene906/E906_RTL_FACTORY/gen_rtl/fdsu/rtl/pa_fdsu_pack_single.v" \
  "$CVA6_DIR/core/cvfpu/vendor/opene906/E906_RTL_FACTORY/gen_rtl/fdsu/rtl/pa_fdsu_prepare.v" \
  "$CVA6_DIR/core/cvfpu/vendor/opene906/E906_RTL_FACTORY/gen_rtl/fdsu/rtl/pa_fdsu_round_single.v" \
  "$CVA6_DIR/core/cvfpu/vendor/opene906/E906_RTL_FACTORY/gen_rtl/fdsu/rtl/pa_fdsu_special.v" \
  "$CVA6_DIR/core/cvfpu/vendor/opene906/E906_RTL_FACTORY/gen_rtl/fdsu/rtl/pa_fdsu_srt_single.v" \
  "$CVA6_DIR/core/cvfpu/vendor/opene906/E906_RTL_FACTORY/gen_rtl/fdsu/rtl/pa_fdsu_top.v" \
  "$CVA6_DIR/core/cvfpu/vendor/opene906/E906_RTL_FACTORY/gen_rtl/fpu/rtl/pa_fpu_dp.v" \
  "$CVA6_DIR/core/cvfpu/vendor/opene906/E906_RTL_FACTORY/gen_rtl/fpu/rtl/pa_fpu_frbus.v" \
  "$CVA6_DIR/core/cvfpu/vendor/opene906/E906_RTL_FACTORY/gen_rtl/fpu/rtl/pa_fpu_src_type.v" \
  "$CVA6_DIR/core/cvfpu/vendor/openc910/C910_RTL_FACTORY/gen_rtl/vfdsu/rtl/ct_vfdsu_ctrl.v" \
  "$CVA6_DIR/core/cvfpu/vendor/openc910/C910_RTL_FACTORY/gen_rtl/vfdsu/rtl/ct_vfdsu_double.v" \
  "$CVA6_DIR/core/cvfpu/vendor/openc910/C910_RTL_FACTORY/gen_rtl/vfdsu/rtl/ct_vfdsu_ff1.v" \
  "$CVA6_DIR/core/cvfpu/vendor/openc910/C910_RTL_FACTORY/gen_rtl/vfdsu/rtl/ct_vfdsu_pack.v" \
  "$CVA6_DIR/core/cvfpu/vendor/openc910/C910_RTL_FACTORY/gen_rtl/vfdsu/rtl/ct_vfdsu_prepare.v" \
  "$CVA6_DIR/core/cvfpu/vendor/openc910/C910_RTL_FACTORY/gen_rtl/vfdsu/rtl/ct_vfdsu_round.v" \
  "$CVA6_DIR/core/cvfpu/vendor/openc910/C910_RTL_FACTORY/gen_rtl/vfdsu/rtl/ct_vfdsu_scalar_dp.v" \
  "$CVA6_DIR/core/cvfpu/vendor/openc910/C910_RTL_FACTORY/gen_rtl/vfdsu/rtl/ct_vfdsu_srt_radix16_bound_table.v" \
  "$CVA6_DIR/core/cvfpu/vendor/openc910/C910_RTL_FACTORY/gen_rtl/vfdsu/rtl/ct_vfdsu_srt_radix16_with_sqrt.v" \
  "$CVA6_DIR/core/cvfpu/vendor/openc910/C910_RTL_FACTORY/gen_rtl/vfdsu/rtl/ct_vfdsu_srt.v" \
  "$CVA6_DIR/core/cvfpu/vendor/openc910/C910_RTL_FACTORY/gen_rtl/vfdsu/rtl/ct_vfdsu_top.v" \
  "$CVA6_DIR/core/cvfpu/src/fpnew_divsqrt_th_32.sv" \
  "$CVA6_DIR/core/cvfpu/src/fpnew_divsqrt_th_64_multi.sv" \
  "$CVA6_DIR/core/cvfpu/src/fpnew_divsqrt_multi.sv" \
  "$CVA6_DIR/core/cvfpu/src/fpnew_fma_multi.sv" \
  "$CVA6_DIR/core/cvfpu/src/fpnew_fma.sv" \
  "$CVA6_DIR/core/cvfpu/src/fpnew_noncomp.sv" \
  "$CVA6_DIR/core/cvfpu/src/fpnew_opgroup_block.sv" \
  "$CVA6_DIR/core/cvfpu/src/fpnew_opgroup_fmt_slice.sv" \
  "$CVA6_DIR/core/cvfpu/src/fpnew_opgroup_multifmt_slice.sv" \
  "$CVA6_DIR/core/cvfpu/src/fpnew_rounding.sv" \
  "$CVA6_DIR/core/cvfpu/src/fpnew_top.sv" \
  "$CVA6_DIR/core/cvfpu/src/fpu_div_sqrt_mvp/hdl/defs_div_sqrt_mvp.sv" \
  "$CVA6_DIR/core/cvfpu/src/fpu_div_sqrt_mvp/hdl/control_mvp.sv" \
  "$CVA6_DIR/core/cvfpu/src/fpu_div_sqrt_mvp/hdl/div_sqrt_top_mvp.sv" \
  "$CVA6_DIR/core/cvfpu/src/fpu_div_sqrt_mvp/hdl/iteration_div_sqrt_mvp.sv" \
  "$CVA6_DIR/core/cvfpu/src/fpu_div_sqrt_mvp/hdl/norm_div_sqrt_mvp.sv" \
  "$CVA6_DIR/core/cvfpu/src/fpu_div_sqrt_mvp/hdl/nrbd_nrsc_mvp.sv" \
  "$CVA6_DIR/core/cvfpu/src/fpu_div_sqrt_mvp/hdl/preprocess_mvp.sv" \
  \
  "$CVA6_DIR/core/include/config_pkg.sv" \
  "$CVA6_DIR/core/include/${TARGET_CFG}_config_pkg.sv" \
  "$CVA6_DIR/core/include/riscv_pkg.sv" \
  "$CVA6_DIR/core/include/ariane_pkg.sv" \
  "$CVA6_DIR/vendor/pulp-platform/axi/src/axi_pkg.sv" \
  \
  "$CVA6_DIR/core/include/wt_cache_pkg.sv" \
  "$CVA6_DIR/core/include/std_cache_pkg.sv" \
  "$CVA6_DIR/core/include/instr_tracer_pkg.sv" \
  "$CVA6_DIR/core/include/build_config_pkg.sv" \
  "$CVA6_DIR/core/include/aes_pkg.sv" \
  "$CVA6_DIR/core/include/triggers_pkg.sv" \
  \
  "$CVA6_DIR/core/cvxif_compressed_if_driver.sv" \
  "$CVA6_DIR/core/cvxif_issue_register_commit_if_driver.sv" \
  "$CVA6_DIR/core/cvxif_fu.sv" \
  \
  "$CVA6_DIR/vendor/pulp-platform/common_cells/src/cf_math_pkg.sv" \
  "$CVA6_DIR/vendor/pulp-platform/common_cells/src/fifo_v3.sv" \
  "$CVA6_DIR/vendor/pulp-platform/common_cells/src/lfsr.sv" \
  "$CVA6_DIR/vendor/pulp-platform/common_cells/src/lfsr_8bit.sv" \
  "$CVA6_DIR/vendor/pulp-platform/common_cells/src/stream_arbiter.sv" \
  "$CVA6_DIR/vendor/pulp-platform/common_cells/src/stream_arbiter_flushable.sv" \
  "$CVA6_DIR/vendor/pulp-platform/common_cells/src/stream_mux.sv" \
  "$CVA6_DIR/vendor/pulp-platform/common_cells/src/stream_demux.sv" \
  "$CVA6_DIR/vendor/pulp-platform/common_cells/src/lzc.sv" \
  "$CVA6_DIR/vendor/pulp-platform/common_cells/src/rr_arb_tree.sv" \
  "$CVA6_DIR/vendor/pulp-platform/common_cells/src/shift_reg.sv" \
  "$CVA6_DIR/vendor/pulp-platform/common_cells/src/unread.sv" \
  "$CVA6_DIR/vendor/pulp-platform/common_cells/src/popcount.sv" \
  "$CVA6_DIR/vendor/pulp-platform/common_cells/src/exp_backoff.sv" \
  "$CVA6_DIR/vendor/pulp-platform/common_cells/src/counter.sv" \
  "$CVA6_DIR/vendor/pulp-platform/common_cells/src/delta_counter.sv" \
  \
  "$CVA6_DIR/core/cva6.sv" \
  "$CVA6_DIR/core/cva6_rvfi_probes.sv" \
  "$CVA6_DIR/core/alu.sv" \
  "$CVA6_DIR/core/alu_wrapper.sv" \
  "$CVA6_DIR/core/aes.sv" \
  "$CVA6_DIR/core/fpu_wrap.sv" \
  "$CVA6_DIR/core/branch_unit.sv" \
  "$CVA6_DIR/core/compressed_decoder.sv" \
  "$CVA6_DIR/core/macro_decoder.sv" \
  "$CVA6_DIR/core/controller.sv" \
  "$CVA6_DIR/core/zcmt_decoder.sv" \
  "$CVA6_DIR/core/csr_buffer.sv" \
  "$CVA6_DIR/core/csr_regfile.sv" \
  "$CVA6_DIR/core/trigger_module.sv" \
  "$CVA6_DIR/core/decoder.sv" \
  "$CVA6_DIR/core/ex_stage.sv" \
  "$CVA6_DIR/core/instr_realign.sv" \
  "$CVA6_DIR/core/id_stage.sv" \
  "$CVA6_DIR/core/issue_read_operands.sv" \
  "$CVA6_DIR/core/issue_stage.sv" \
  "$CVA6_DIR/core/load_unit.sv" \
  "$CVA6_DIR/core/load_store_unit.sv" \
  "$CVA6_DIR/core/lsu_bypass.sv" \
  "$CVA6_DIR/core/mult.sv" \
  "$CVA6_DIR/core/multiplier.sv" \
  "$CVA6_DIR/core/serdiv.sv" \
  "$CVA6_DIR/core/perf_counters.sv" \
  "$CVA6_DIR/core/ariane_regfile_ff.sv" \
  "$CVA6_DIR/core/ariane_regfile_fpga.sv" \
  "$CVA6_DIR/core/scoreboard.sv" \
  "$CVA6_DIR/core/raw_checker.sv" \
  "$CVA6_DIR/core/store_buffer.sv" \
  "$CVA6_DIR/core/amo_buffer.sv" \
  "$CVA6_DIR/core/store_unit.sv" \
  "$CVA6_DIR/core/commit_stage.sv" \
  "$CVA6_DIR/core/axi_shim.sv" \
  "$CVA6_DIR/core/cva6_accel_first_pass_decoder_stub.sv" \
  "$CVA6_DIR/core/acc_dispatcher.sv" \
  "$CVA6_DIR/core/cva6_fifo_v3.sv" \
  \
  "$CVA6_DIR/core/frontend/btb.sv" \
  "$CVA6_DIR/core/frontend/bht.sv" \
  "$CVA6_DIR/core/frontend/bht2lvl.sv" \
  "$CVA6_DIR/core/frontend/ras.sv" \
  "$CVA6_DIR/core/frontend/instr_scan.sv" \
  "$CVA6_DIR/core/frontend/instr_queue.sv" \
  "$CVA6_DIR/core/frontend/frontend.sv" \
  \
  "$CVA6_DIR/core/cache_subsystem/wt_dcache_ctrl.sv" \
  "$CVA6_DIR/core/cache_subsystem/wt_dcache_mem.sv" \
  "$CVA6_DIR/core/cache_subsystem/wt_dcache_missunit.sv" \
  "$CVA6_DIR/core/cache_subsystem/wt_dcache_wbuffer.sv" \
  "$CVA6_DIR/core/cache_subsystem/wt_dcache.sv" \
  "$CVA6_DIR/core/cache_subsystem/cva6_icache.sv" \
  "$CVA6_DIR/core/cache_subsystem/wt_cache_subsystem.sv" \
  "$CVA6_DIR/core/cache_subsystem/wt_axi_adapter.sv" \
  "$CVA6_DIR/core/cache_subsystem/tag_cmp.sv" \
  "$CVA6_DIR/core/cache_subsystem/axi_adapter.sv" \
  "$CVA6_DIR/core/cache_subsystem/miss_handler.sv" \
  "$CVA6_DIR/core/cache_subsystem/cache_ctrl.sv" \
  "$CVA6_DIR/core/cache_subsystem/cva6_icache_axi_wrapper.sv" \
  "$CVA6_DIR/core/cache_subsystem/std_cache_subsystem.sv" \
  "$CVA6_DIR/core/cache_subsystem/std_nbdcache.sv" \
  \
  "$HPDCACHE_DIR/rtl/src/hpdcache_pkg.sv" \
  "$HPDCACHE_DIR/rtl/src/utils/hpdcache_mem_req_read_arbiter.sv" \
  "$HPDCACHE_DIR/rtl/src/utils/hpdcache_mem_req_write_arbiter.sv" \
  "$HPDCACHE_DIR/rtl/src/common/hpdcache_demux.sv" \
  "$HPDCACHE_DIR/rtl/src/common/hpdcache_lfsr.sv" \
  "$HPDCACHE_DIR/rtl/src/common/hpdcache_sync_buffer.sv" \
  "$HPDCACHE_DIR/rtl/src/common/hpdcache_fifo_reg.sv" \
  "$HPDCACHE_DIR/rtl/src/common/hpdcache_fifo_reg_initialized.sv" \
  "$HPDCACHE_DIR/rtl/src/common/hpdcache_fxarb.sv" \
  "$HPDCACHE_DIR/rtl/src/common/hpdcache_rrarb.sv" \
  "$HPDCACHE_DIR/rtl/src/common/hpdcache_mux.sv" \
  "$HPDCACHE_DIR/rtl/src/common/hpdcache_decoder.sv" \
  "$HPDCACHE_DIR/rtl/src/common/hpdcache_1hot_to_binary.sv" \
  "$HPDCACHE_DIR/rtl/src/common/hpdcache_prio_1hot_encoder.sv" \
  "$HPDCACHE_DIR/rtl/src/common/hpdcache_prio_bin_encoder.sv" \
  "$HPDCACHE_DIR/rtl/src/common/hpdcache_sram.sv" \
  "$HPDCACHE_DIR/rtl/src/common/hpdcache_sram_wbyteenable.sv" \
  "$HPDCACHE_DIR/rtl/src/common/hpdcache_sram_wmask.sv" \
  "$HPDCACHE_DIR/rtl/src/common/hpdcache_regbank_wbyteenable_1rw.sv" \
  "$HPDCACHE_DIR/rtl/src/common/hpdcache_regbank_wmask_1rw.sv" \
  "$HPDCACHE_DIR/rtl/src/common/hpdcache_data_downsize.sv" \
  "$HPDCACHE_DIR/rtl/src/common/hpdcache_data_upsize.sv" \
  "$HPDCACHE_DIR/rtl/src/common/hpdcache_data_resize.sv" \
  "$HPDCACHE_DIR/rtl/src/hwpf_stride/hwpf_stride_pkg.sv" \
  "$HPDCACHE_DIR/rtl/src/hwpf_stride/hwpf_stride.sv" \
  "$HPDCACHE_DIR/rtl/src/hwpf_stride/hwpf_stride_arb.sv" \
  "$HPDCACHE_DIR/rtl/src/hwpf_stride/hwpf_stride_wrapper.sv" \
  "$HPDCACHE_DIR/rtl/src/hpdcache.sv" \
  "$HPDCACHE_DIR/rtl/src/hpdcache_amo.sv" \
  "$HPDCACHE_DIR/rtl/src/hpdcache_cmo.sv" \
  "$HPDCACHE_DIR/rtl/src/hpdcache_core_arbiter.sv" \
  "$HPDCACHE_DIR/rtl/src/hpdcache_ctrl.sv" \
  "$HPDCACHE_DIR/rtl/src/hpdcache_ctrl_pe.sv" \
  "$HPDCACHE_DIR/rtl/src/hpdcache_memctrl.sv" \
  "$HPDCACHE_DIR/rtl/src/hpdcache_cbuf.sv" \
  "$HPDCACHE_DIR/rtl/src/hpdcache_miss_handler.sv" \
  "$HPDCACHE_DIR/rtl/src/hpdcache_mshr.sv" \
  "$HPDCACHE_DIR/rtl/src/hpdcache_rtab.sv" \
  "$HPDCACHE_DIR/rtl/src/hpdcache_uncached.sv" \
  "$HPDCACHE_DIR/rtl/src/hpdcache_victim_plru.sv" \
  "$HPDCACHE_DIR/rtl/src/hpdcache_victim_random.sv" \
  "$HPDCACHE_DIR/rtl/src/hpdcache_victim_sel.sv" \
  "$HPDCACHE_DIR/rtl/src/hpdcache_wbuf.sv" \
  "$HPDCACHE_DIR/rtl/src/hpdcache_flush.sv" \
  "$HPDCACHE_DIR/rtl/src/utils/hpdcache_mem_resp_demux.sv" \
  "$HPDCACHE_DIR/rtl/src/utils/hpdcache_mem_to_axi_read.sv" \
  "$HPDCACHE_DIR/rtl/src/utils/hpdcache_mem_to_axi_write.sv" \
  "$CVA6_DIR/core/include/dummy_l15_pkg.sv" \
  "$CVA6_DIR/core/cache_subsystem/cva6_hpdcache_subsystem.sv" \
  "$CVA6_DIR/core/cache_subsystem/cva6_hpdcache_subsystem_axi_arbiter.sv" \
  "$CVA6_DIR/core/cache_subsystem/cva6_hpdcache_if_adapter.sv" \
  "$CVA6_DIR/core/cache_subsystem/cva6_hpdcache_wrapper.sv" \
  "$HPDCACHE_DIR/rtl/src/common/macros/behav/hpdcache_sram_1rw.sv" \
  "$HPDCACHE_DIR/rtl/src/common/macros/behav/hpdcache_sram_wbyteenable_1rw.sv" \
  "$HPDCACHE_DIR/rtl/src/common/macros/behav/hpdcache_sram_wmask_1rw.sv" \
  \
  "$CVA6_DIR/core/pmp/src/pmp.sv" \
  "$CVA6_DIR/core/pmp/src/pmp_entry.sv" \
  "$CVA6_DIR/core/pmp/src/pmp_data_if.sv" \
  \
  "$CVA6_DIR/common/local/util/instr_tracer.sv" \
  "$CVA6_DIR/common/local/util/tc_sram_wrapper.sv" \
  "$CVA6_DIR/common/local/util/tc_sram_wrapper_cache_techno.sv" \
  "$CVA6_DIR/vendor/pulp-platform/tech_cells_generic/src/rtl/tc_sram.sv" \
  "$CVA6_DIR/common/local/util/sram.sv" \
  "$CVA6_DIR/common/local/util/sram_cache.sv" \
  \
  "$CVA6_DIR/core/cva6_mmu/cva6_mmu.sv" \
  "$CVA6_DIR/core/cva6_mmu/cva6_ptw.sv" \
  "$CVA6_DIR/core/cva6_mmu/cva6_tlb.sv" \
  "$CVA6_DIR/core/cva6_mmu/cva6_shared_tlb.sv" \
]

# ---------------------------------------------------------------------------
# 2. TinyGPU coprocessor sources (4_64_Core only).
# ---------------------------------------------------------------------------
set tinygpu_files [list \
  "$TINYGPU_DIR/alu.v" \
  "$TINYGPU_DIR/register_file.v" \
  "$TINYGPU_DIR/cache.v" \
  "$TINYGPU_DIR/cache_l3.v" \
  "$TINYGPU_DIR/tingpu_decoder.v" \
  "$TINYGPU_DIR/design_1.v" \
  "$TINYGPU_DIR/design_1_wrapper.v" \
  "$TINYGPU_DIR/fourc_1.v" \
  "$TINYGPU_DIR/fourc_1_wrapper.v" \
  "$TINYGPU_DIR/tinygpu_fsm.v" \
  "$TINYGPU_DIR/tinygpu_cvxif_wrap.v" \
  "$TINYGPU_DIR/cva6_sv_shim.sv" \
  "$TINYGPU_DIR/cva6_tinygpu_soc.v" \
]

# ---------------------------------------------------------------------------
# 3. Add to project, set include dirs, mark file types.
# ---------------------------------------------------------------------------
add_files -norecurse $cva6_files
add_files -norecurse $tinygpu_files

set_property include_dirs [list \
  "$CVA6_DIR/core/include" \
  "$CVA6_DIR/vendor/pulp-platform/common_cells/include" \
  "$CVA6_DIR/vendor/pulp-platform/common_cells/src" \
  "$CVA6_DIR/vendor/pulp-platform/axi/include" \
  "$CVA6_DIR/common/local/util" \
  "$HPDCACHE_DIR/rtl/include" \
] [current_fileset]

# Force correct file typing (extension-based inference can misfire in mixed projects).
foreach f [get_files -filter {FILE_TYPE == Verilog} "*.sv"] {
  set_property file_type SystemVerilog $f
}
set_property file_type SystemVerilog [get_files "$TINYGPU_DIR/cva6_sv_shim.sv"]

update_compile_order -fileset [current_fileset]

puts "Added [llength $cva6_files] CVA6 files and [llength $tinygpu_files] TinyGPU files."
puts "Set top to cva6_tinygpu_soc (or cva6_sv_shim if you want CVA6 alone) and re-run update_compile_order."
