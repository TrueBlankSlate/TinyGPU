# import_final_v1_sources.tcl
#
# Run this in the Vivado Tcl console with the "final_v1" project already
# open (D:/Vivado_Projects/final_v1). It imports every source the working
# 0_2_CVA6 project uses, pointed at final_v1's own copies for the
# TinyGPU-authored files, so:
#   - D:/TinyGPU/TinyGPU/4_64_Core is NEVER touched (read from nowhere here).
#   - D:/Vivado_Projects/0_2_CVA6 is NEVER touched (not referenced at all).
#   - The external CVA6 core (D:/CVA6/cva6/...) is referenced read-only,
#     shared, unmodified -- it's the same untouched repo 0_2_CVA6 already
#     uses, not something that needs copying or duplicating.
#
# The CVA6 core file list below was extracted directly from 0_2_CVA6.xpr
# (not hand-typed), so it's the exact, complete, verified fileset -- all
# 221 files confirmed to exist on disk before this script was written.

set tg_dir  "D:/TinyGPU/TinyGPU/final_v1"
set tg_sim  "D:/TinyGPU/TinyGPU/final_v1/sim"

# ---------------------------------------------------------------------
# 1. External CVA6 core (untouched, shared with 0_2_CVA6)
# ---------------------------------------------------------------------
set cva6_core_files [list \
    "D:/CVA6/cva6/common/local/util/ex_trace_item.svh" \
    "D:/CVA6/cva6/common/local/util/instr_trace_item.svh" \
    "D:/CVA6/cva6/common/local/util/instr_tracer.sv" \
    "D:/CVA6/cva6/common/local/util/sram.sv" \
    "D:/CVA6/cva6/common/local/util/sram_cache.sv" \
    "D:/CVA6/cva6/common/local/util/tc_sram_wrapper.sv" \
    "D:/CVA6/cva6/common/local/util/tc_sram_wrapper_cache_techno.sv" \
    "D:/CVA6/cva6/core/acc_dispatcher.sv" \
    "D:/CVA6/cva6/core/aes.sv" \
    "D:/CVA6/cva6/core/alu.sv" \
    "D:/CVA6/cva6/core/alu_wrapper.sv" \
    "D:/CVA6/cva6/core/amo_buffer.sv" \
    "D:/CVA6/cva6/core/ariane_regfile_ff.sv" \
    "D:/CVA6/cva6/core/ariane_regfile_fpga.sv" \
    "D:/CVA6/cva6/core/axi_shim.sv" \
    "D:/CVA6/cva6/core/branch_unit.sv" \
    "D:/CVA6/cva6/core/cache_subsystem/axi_adapter.sv" \
    "D:/CVA6/cva6/core/cache_subsystem/cache_ctrl.sv" \
    "D:/CVA6/cva6/core/cache_subsystem/cva6_hpdcache_if_adapter.sv" \
    "D:/CVA6/cva6/core/cache_subsystem/cva6_hpdcache_subsystem.sv" \
    "D:/CVA6/cva6/core/cache_subsystem/cva6_hpdcache_subsystem_axi_arbiter.sv" \
    "D:/CVA6/cva6/core/cache_subsystem/cva6_hpdcache_wrapper.sv" \
    "D:/CVA6/cva6/core/cache_subsystem/cva6_icache.sv" \
    "D:/CVA6/cva6/core/cache_subsystem/cva6_icache_axi_wrapper.sv" \
    "D:/CVA6/cva6/core/cache_subsystem/hpdcache/rtl/include/hpdcache_typedef.svh" \
    "D:/CVA6/cva6/core/cache_subsystem/hpdcache/rtl/src/common/hpdcache_1hot_to_binary.sv" \
    "D:/CVA6/cva6/core/cache_subsystem/hpdcache/rtl/src/common/hpdcache_data_downsize.sv" \
    "D:/CVA6/cva6/core/cache_subsystem/hpdcache/rtl/src/common/hpdcache_data_resize.sv" \
    "D:/CVA6/cva6/core/cache_subsystem/hpdcache/rtl/src/common/hpdcache_data_upsize.sv" \
    "D:/CVA6/cva6/core/cache_subsystem/hpdcache/rtl/src/common/hpdcache_decoder.sv" \
    "D:/CVA6/cva6/core/cache_subsystem/hpdcache/rtl/src/common/hpdcache_demux.sv" \
    "D:/CVA6/cva6/core/cache_subsystem/hpdcache/rtl/src/common/hpdcache_fifo_reg.sv" \
    "D:/CVA6/cva6/core/cache_subsystem/hpdcache/rtl/src/common/hpdcache_fifo_reg_initialized.sv" \
    "D:/CVA6/cva6/core/cache_subsystem/hpdcache/rtl/src/common/hpdcache_fxarb.sv" \
    "D:/CVA6/cva6/core/cache_subsystem/hpdcache/rtl/src/common/hpdcache_lfsr.sv" \
    "D:/CVA6/cva6/core/cache_subsystem/hpdcache/rtl/src/common/hpdcache_mux.sv" \
    "D:/CVA6/cva6/core/cache_subsystem/hpdcache/rtl/src/common/hpdcache_prio_1hot_encoder.sv" \
    "D:/CVA6/cva6/core/cache_subsystem/hpdcache/rtl/src/common/hpdcache_prio_bin_encoder.sv" \
    "D:/CVA6/cva6/core/cache_subsystem/hpdcache/rtl/src/common/hpdcache_regbank_wbyteenable_1rw.sv" \
    "D:/CVA6/cva6/core/cache_subsystem/hpdcache/rtl/src/common/hpdcache_regbank_wmask_1rw.sv" \
    "D:/CVA6/cva6/core/cache_subsystem/hpdcache/rtl/src/common/hpdcache_rrarb.sv" \
    "D:/CVA6/cva6/core/cache_subsystem/hpdcache/rtl/src/common/hpdcache_sram.sv" \
    "D:/CVA6/cva6/core/cache_subsystem/hpdcache/rtl/src/common/hpdcache_sram_wbyteenable.sv" \
    "D:/CVA6/cva6/core/cache_subsystem/hpdcache/rtl/src/common/hpdcache_sram_wmask.sv" \
    "D:/CVA6/cva6/core/cache_subsystem/hpdcache/rtl/src/common/hpdcache_sync_buffer.sv" \
    "D:/CVA6/cva6/core/cache_subsystem/hpdcache/rtl/src/common/macros/behav/hpdcache_sram_1rw.sv" \
    "D:/CVA6/cva6/core/cache_subsystem/hpdcache/rtl/src/common/macros/behav/hpdcache_sram_wbyteenable_1rw.sv" \
    "D:/CVA6/cva6/core/cache_subsystem/hpdcache/rtl/src/common/macros/behav/hpdcache_sram_wmask_1rw.sv" \
    "D:/CVA6/cva6/core/cache_subsystem/hpdcache/rtl/src/hpdcache.sv" \
    "D:/CVA6/cva6/core/cache_subsystem/hpdcache/rtl/src/hpdcache_amo.sv" \
    "D:/CVA6/cva6/core/cache_subsystem/hpdcache/rtl/src/hpdcache_cbuf.sv" \
    "D:/CVA6/cva6/core/cache_subsystem/hpdcache/rtl/src/hpdcache_cmo.sv" \
    "D:/CVA6/cva6/core/cache_subsystem/hpdcache/rtl/src/hpdcache_core_arbiter.sv" \
    "D:/CVA6/cva6/core/cache_subsystem/hpdcache/rtl/src/hpdcache_ctrl.sv" \
    "D:/CVA6/cva6/core/cache_subsystem/hpdcache/rtl/src/hpdcache_ctrl_pe.sv" \
    "D:/CVA6/cva6/core/cache_subsystem/hpdcache/rtl/src/hpdcache_flush.sv" \
    "D:/CVA6/cva6/core/cache_subsystem/hpdcache/rtl/src/hpdcache_memctrl.sv" \
    "D:/CVA6/cva6/core/cache_subsystem/hpdcache/rtl/src/hpdcache_miss_handler.sv" \
    "D:/CVA6/cva6/core/cache_subsystem/hpdcache/rtl/src/hpdcache_mshr.sv" \
    "D:/CVA6/cva6/core/cache_subsystem/hpdcache/rtl/src/hpdcache_pkg.sv" \
    "D:/CVA6/cva6/core/cache_subsystem/hpdcache/rtl/src/hpdcache_rtab.sv" \
    "D:/CVA6/cva6/core/cache_subsystem/hpdcache/rtl/src/hpdcache_uncached.sv" \
    "D:/CVA6/cva6/core/cache_subsystem/hpdcache/rtl/src/hpdcache_victim_plru.sv" \
    "D:/CVA6/cva6/core/cache_subsystem/hpdcache/rtl/src/hpdcache_victim_random.sv" \
    "D:/CVA6/cva6/core/cache_subsystem/hpdcache/rtl/src/hpdcache_victim_sel.sv" \
    "D:/CVA6/cva6/core/cache_subsystem/hpdcache/rtl/src/hpdcache_wbuf.sv" \
    "D:/CVA6/cva6/core/cache_subsystem/hpdcache/rtl/src/hwpf_stride/hwpf_stride.sv" \
    "D:/CVA6/cva6/core/cache_subsystem/hpdcache/rtl/src/hwpf_stride/hwpf_stride_arb.sv" \
    "D:/CVA6/cva6/core/cache_subsystem/hpdcache/rtl/src/hwpf_stride/hwpf_stride_pkg.sv" \
    "D:/CVA6/cva6/core/cache_subsystem/hpdcache/rtl/src/hwpf_stride/hwpf_stride_wrapper.sv" \
    "D:/CVA6/cva6/core/cache_subsystem/hpdcache/rtl/src/utils/hpdcache_mem_req_read_arbiter.sv" \
    "D:/CVA6/cva6/core/cache_subsystem/hpdcache/rtl/src/utils/hpdcache_mem_req_write_arbiter.sv" \
    "D:/CVA6/cva6/core/cache_subsystem/hpdcache/rtl/src/utils/hpdcache_mem_resp_demux.sv" \
    "D:/CVA6/cva6/core/cache_subsystem/hpdcache/rtl/src/utils/hpdcache_mem_to_axi_read.sv" \
    "D:/CVA6/cva6/core/cache_subsystem/hpdcache/rtl/src/utils/hpdcache_mem_to_axi_write.sv" \
    "D:/CVA6/cva6/core/cache_subsystem/miss_handler.sv" \
    "D:/CVA6/cva6/core/cache_subsystem/std_cache_subsystem.sv" \
    "D:/CVA6/cva6/core/cache_subsystem/std_nbdcache.sv" \
    "D:/CVA6/cva6/core/cache_subsystem/tag_cmp.sv" \
    "D:/CVA6/cva6/core/cache_subsystem/wt_axi_adapter.sv" \
    "D:/CVA6/cva6/core/cache_subsystem/wt_cache_subsystem.sv" \
    "D:/CVA6/cva6/core/cache_subsystem/wt_dcache.sv" \
    "D:/CVA6/cva6/core/cache_subsystem/wt_dcache_ctrl.sv" \
    "D:/CVA6/cva6/core/cache_subsystem/wt_dcache_mem.sv" \
    "D:/CVA6/cva6/core/cache_subsystem/wt_dcache_missunit.sv" \
    "D:/CVA6/cva6/core/cache_subsystem/wt_dcache_wbuffer.sv" \
    "D:/CVA6/cva6/core/commit_stage.sv" \
    "D:/CVA6/cva6/core/compressed_decoder.sv" \
    "D:/CVA6/cva6/core/controller.sv" \
    "D:/CVA6/cva6/core/csr_buffer.sv" \
    "D:/CVA6/cva6/core/csr_regfile.sv" \
    "D:/CVA6/cva6/core/cva6.sv" \
    "D:/CVA6/cva6/core/cva6_accel_first_pass_decoder_stub.sv" \
    "D:/CVA6/cva6/core/cva6_fifo_v3.sv" \
    "D:/CVA6/cva6/core/cva6_mmu/cva6_mmu.sv" \
    "D:/CVA6/cva6/core/cva6_mmu/cva6_ptw.sv" \
    "D:/CVA6/cva6/core/cva6_mmu/cva6_shared_tlb.sv" \
    "D:/CVA6/cva6/core/cva6_mmu/cva6_tlb.sv" \
    "D:/CVA6/cva6/core/cva6_rvfi_probes.sv" \
    "D:/CVA6/cva6/core/cvfpu/src/fpnew_cast_multi.sv" \
    "D:/CVA6/cva6/core/cvfpu/src/fpnew_classifier.sv" \
    "D:/CVA6/cva6/core/cvfpu/src/fpnew_divsqrt_multi.sv" \
    "D:/CVA6/cva6/core/cvfpu/src/fpnew_divsqrt_th_32.sv" \
    "D:/CVA6/cva6/core/cvfpu/src/fpnew_divsqrt_th_64_multi.sv" \
    "D:/CVA6/cva6/core/cvfpu/src/fpnew_fma.sv" \
    "D:/CVA6/cva6/core/cvfpu/src/fpnew_fma_multi.sv" \
    "D:/CVA6/cva6/core/cvfpu/src/fpnew_noncomp.sv" \
    "D:/CVA6/cva6/core/cvfpu/src/fpnew_opgroup_block.sv" \
    "D:/CVA6/cva6/core/cvfpu/src/fpnew_opgroup_fmt_slice.sv" \
    "D:/CVA6/cva6/core/cvfpu/src/fpnew_opgroup_multifmt_slice.sv" \
    "D:/CVA6/cva6/core/cvfpu/src/fpnew_pkg.sv" \
    "D:/CVA6/cva6/core/cvfpu/src/fpnew_rounding.sv" \
    "D:/CVA6/cva6/core/cvfpu/src/fpnew_top.sv" \
    "D:/CVA6/cva6/core/cvfpu/src/fpu_div_sqrt_mvp/hdl/control_mvp.sv" \
    "D:/CVA6/cva6/core/cvfpu/src/fpu_div_sqrt_mvp/hdl/defs_div_sqrt_mvp.sv" \
    "D:/CVA6/cva6/core/cvfpu/src/fpu_div_sqrt_mvp/hdl/div_sqrt_top_mvp.sv" \
    "D:/CVA6/cva6/core/cvfpu/src/fpu_div_sqrt_mvp/hdl/iteration_div_sqrt_mvp.sv" \
    "D:/CVA6/cva6/core/cvfpu/src/fpu_div_sqrt_mvp/hdl/norm_div_sqrt_mvp.sv" \
    "D:/CVA6/cva6/core/cvfpu/src/fpu_div_sqrt_mvp/hdl/nrbd_nrsc_mvp.sv" \
    "D:/CVA6/cva6/core/cvfpu/src/fpu_div_sqrt_mvp/hdl/preprocess_mvp.sv" \
    "D:/CVA6/cva6/core/cvfpu/vendor/openc910/C910_RTL_FACTORY/gen_rtl/vfdsu/rtl/ct_vfdsu_ctrl.v" \
    "D:/CVA6/cva6/core/cvfpu/vendor/openc910/C910_RTL_FACTORY/gen_rtl/vfdsu/rtl/ct_vfdsu_double.v" \
    "D:/CVA6/cva6/core/cvfpu/vendor/openc910/C910_RTL_FACTORY/gen_rtl/vfdsu/rtl/ct_vfdsu_ff1.v" \
    "D:/CVA6/cva6/core/cvfpu/vendor/openc910/C910_RTL_FACTORY/gen_rtl/vfdsu/rtl/ct_vfdsu_pack.v" \
    "D:/CVA6/cva6/core/cvfpu/vendor/openc910/C910_RTL_FACTORY/gen_rtl/vfdsu/rtl/ct_vfdsu_prepare.v" \
    "D:/CVA6/cva6/core/cvfpu/vendor/openc910/C910_RTL_FACTORY/gen_rtl/vfdsu/rtl/ct_vfdsu_round.v" \
    "D:/CVA6/cva6/core/cvfpu/vendor/openc910/C910_RTL_FACTORY/gen_rtl/vfdsu/rtl/ct_vfdsu_scalar_dp.v" \
    "D:/CVA6/cva6/core/cvfpu/vendor/openc910/C910_RTL_FACTORY/gen_rtl/vfdsu/rtl/ct_vfdsu_srt.v" \
    "D:/CVA6/cva6/core/cvfpu/vendor/openc910/C910_RTL_FACTORY/gen_rtl/vfdsu/rtl/ct_vfdsu_srt_radix16_bound_table.v" \
    "D:/CVA6/cva6/core/cvfpu/vendor/openc910/C910_RTL_FACTORY/gen_rtl/vfdsu/rtl/ct_vfdsu_srt_radix16_with_sqrt.v" \
    "D:/CVA6/cva6/core/cvfpu/vendor/openc910/C910_RTL_FACTORY/gen_rtl/vfdsu/rtl/ct_vfdsu_top.v" \
    "D:/CVA6/cva6/core/cvfpu/vendor/opene906/E906_RTL_FACTORY/gen_rtl/clk/rtl/gated_clk_cell.v" \
    "D:/CVA6/cva6/core/cvfpu/vendor/opene906/E906_RTL_FACTORY/gen_rtl/fdsu/rtl/pa_fdsu_ctrl.v" \
    "D:/CVA6/cva6/core/cvfpu/vendor/opene906/E906_RTL_FACTORY/gen_rtl/fdsu/rtl/pa_fdsu_ff1.v" \
    "D:/CVA6/cva6/core/cvfpu/vendor/opene906/E906_RTL_FACTORY/gen_rtl/fdsu/rtl/pa_fdsu_pack_single.v" \
    "D:/CVA6/cva6/core/cvfpu/vendor/opene906/E906_RTL_FACTORY/gen_rtl/fdsu/rtl/pa_fdsu_prepare.v" \
    "D:/CVA6/cva6/core/cvfpu/vendor/opene906/E906_RTL_FACTORY/gen_rtl/fdsu/rtl/pa_fdsu_round_single.v" \
    "D:/CVA6/cva6/core/cvfpu/vendor/opene906/E906_RTL_FACTORY/gen_rtl/fdsu/rtl/pa_fdsu_special.v" \
    "D:/CVA6/cva6/core/cvfpu/vendor/opene906/E906_RTL_FACTORY/gen_rtl/fdsu/rtl/pa_fdsu_srt_single.v" \
    "D:/CVA6/cva6/core/cvfpu/vendor/opene906/E906_RTL_FACTORY/gen_rtl/fdsu/rtl/pa_fdsu_top.v" \
    "D:/CVA6/cva6/core/cvfpu/vendor/opene906/E906_RTL_FACTORY/gen_rtl/fpu/rtl/pa_fpu_dp.v" \
    "D:/CVA6/cva6/core/cvfpu/vendor/opene906/E906_RTL_FACTORY/gen_rtl/fpu/rtl/pa_fpu_frbus.v" \
    "D:/CVA6/cva6/core/cvfpu/vendor/opene906/E906_RTL_FACTORY/gen_rtl/fpu/rtl/pa_fpu_src_type.v" \
    "D:/CVA6/cva6/core/cvxif_compressed_if_driver.sv" \
    "D:/CVA6/cva6/core/cvxif_fu.sv" \
    "D:/CVA6/cva6/core/cvxif_issue_register_commit_if_driver.sv" \
    "D:/CVA6/cva6/core/decoder.sv" \
    "D:/CVA6/cva6/core/ex_stage.sv" \
    "D:/CVA6/cva6/core/fpu_wrap.sv" \
    "D:/CVA6/cva6/core/frontend/bht.sv" \
    "D:/CVA6/cva6/core/frontend/bht2lvl.sv" \
    "D:/CVA6/cva6/core/frontend/btb.sv" \
    "D:/CVA6/cva6/core/frontend/frontend.sv" \
    "D:/CVA6/cva6/core/frontend/instr_queue.sv" \
    "D:/CVA6/cva6/core/frontend/instr_scan.sv" \
    "D:/CVA6/cva6/core/frontend/ras.sv" \
    "D:/CVA6/cva6/core/id_stage.sv" \
    "D:/CVA6/cva6/core/include/aes_pkg.sv" \
    "D:/CVA6/cva6/core/include/ariane_pkg.sv" \
    "D:/CVA6/cva6/core/include/build_config_pkg.sv" \
    "D:/CVA6/cva6/core/include/config_pkg.sv" \
    "D:/CVA6/cva6/core/include/cv64a6_imafdc_sv39_config_pkg.sv" \
    "D:/CVA6/cva6/core/include/cvxif_types.svh" \
    "D:/CVA6/cva6/core/include/dummy_l15_pkg.sv" \
    "D:/CVA6/cva6/core/include/instr_tracer_pkg.sv" \
    "D:/CVA6/cva6/core/include/riscv_pkg.sv" \
    "D:/CVA6/cva6/core/include/rvfi_types.svh" \
    "D:/CVA6/cva6/core/include/std_cache_pkg.sv" \
    "D:/CVA6/cva6/core/include/triggers_pkg.sv" \
    "D:/CVA6/cva6/core/include/wt_cache_pkg.sv" \
    "D:/CVA6/cva6/core/instr_realign.sv" \
    "D:/CVA6/cva6/core/issue_read_operands.sv" \
    "D:/CVA6/cva6/core/issue_stage.sv" \
    "D:/CVA6/cva6/core/load_store_unit.sv" \
    "D:/CVA6/cva6/core/load_unit.sv" \
    "D:/CVA6/cva6/core/lsu_bypass.sv" \
    "D:/CVA6/cva6/core/macro_decoder.sv" \
    "D:/CVA6/cva6/core/mult.sv" \
    "D:/CVA6/cva6/core/multiplier.sv" \
    "D:/CVA6/cva6/core/perf_counters.sv" \
    "D:/CVA6/cva6/core/pmp/src/pmp.sv" \
    "D:/CVA6/cva6/core/pmp/src/pmp_data_if.sv" \
    "D:/CVA6/cva6/core/pmp/src/pmp_entry.sv" \
    "D:/CVA6/cva6/core/raw_checker.sv" \
    "D:/CVA6/cva6/core/scoreboard.sv" \
    "D:/CVA6/cva6/core/serdiv.sv" \
    "D:/CVA6/cva6/core/store_buffer.sv" \
    "D:/CVA6/cva6/core/store_unit.sv" \
    "D:/CVA6/cva6/core/trigger_module.sv" \
    "D:/CVA6/cva6/core/zcmt_decoder.sv" \
    "D:/CVA6/cva6/vendor/pulp-platform/axi/include/axi/assign.svh" \
    "D:/CVA6/cva6/vendor/pulp-platform/axi/include/axi/typedef.svh" \
    "D:/CVA6/cva6/vendor/pulp-platform/axi/src/axi_id_prepend.sv" \
    "D:/CVA6/cva6/vendor/pulp-platform/axi/src/axi_mux.sv" \
    "D:/CVA6/cva6/vendor/pulp-platform/axi/src/axi_pkg.sv" \
    "D:/CVA6/cva6/vendor/pulp-platform/common_cells/include/common_cells/registers.svh" \
    "D:/CVA6/cva6/vendor/pulp-platform/common_cells/src/cf_math_pkg.sv" \
    "D:/CVA6/cva6/vendor/pulp-platform/common_cells/src/counter.sv" \
    "D:/CVA6/cva6/vendor/pulp-platform/common_cells/src/delta_counter.sv" \
    "D:/CVA6/cva6/vendor/pulp-platform/common_cells/src/exp_backoff.sv" \
    "D:/CVA6/cva6/vendor/pulp-platform/common_cells/src/fifo_v3.sv" \
    "D:/CVA6/cva6/vendor/pulp-platform/common_cells/src/lfsr.sv" \
    "D:/CVA6/cva6/vendor/pulp-platform/common_cells/src/lfsr_8bit.sv" \
    "D:/CVA6/cva6/vendor/pulp-platform/common_cells/src/lzc.sv" \
    "D:/CVA6/cva6/vendor/pulp-platform/common_cells/src/popcount.sv" \
    "D:/CVA6/cva6/vendor/pulp-platform/common_cells/src/rr_arb_tree.sv" \
    "D:/CVA6/cva6/vendor/pulp-platform/common_cells/src/shift_reg.sv" \
    "D:/CVA6/cva6/vendor/pulp-platform/common_cells/src/spill_register.sv" \
    "D:/CVA6/cva6/vendor/pulp-platform/common_cells/src/spill_register_flushable.sv" \
    "D:/CVA6/cva6/vendor/pulp-platform/common_cells/src/stream_arbiter.sv" \
    "D:/CVA6/cva6/vendor/pulp-platform/common_cells/src/stream_arbiter_flushable.sv" \
    "D:/CVA6/cva6/vendor/pulp-platform/common_cells/src/stream_demux.sv" \
    "D:/CVA6/cva6/vendor/pulp-platform/common_cells/src/stream_mux.sv" \
    "D:/CVA6/cva6/vendor/pulp-platform/common_cells/src/unread.sv" \
    "D:/CVA6/cva6/vendor/pulp-platform/fpga-support/rtl/AsyncDpRam.sv" \
    "D:/CVA6/cva6/vendor/pulp-platform/fpga-support/rtl/AsyncThreePortRam.sv" \
    "D:/CVA6/cva6/vendor/pulp-platform/fpga-support/rtl/SyncDpRam.sv" \
    "D:/CVA6/cva6/vendor/pulp-platform/fpga-support/rtl/SyncDpRam_ind_r_w.sv" \
    "D:/CVA6/cva6/vendor/pulp-platform/fpga-support/rtl/SyncThreePortRam.sv" \
    "D:/CVA6/cva6/vendor/pulp-platform/tech_cells_generic/src/rtl/tc_sram.sv" \
]

# ---------------------------------------------------------------------
# 2. TinyGPU RTL (final_v1's OWN copies -- 4_64_Core is never read here)
# ---------------------------------------------------------------------
set tg_rtl_files [list \
    $tg_dir/alu.v \
    $tg_dir/axi4_bram_slave.v \
    $tg_dir/cache.v \
    $tg_dir/cache_l3.v \
    $tg_dir/cva6_sv_shim.sv \
    $tg_dir/cva6_tinygpu_soc.v \
    $tg_dir/design_1.v \
    $tg_dir/design_1_wrapper.v \
    $tg_dir/fourc_1.v \
    $tg_dir/fourc_1_wrapper.v \
    $tg_dir/register_file.v \
    $tg_dir/tingpu_decoder.v \
    $tg_dir/tinygpu_cvxif_wrap.v \
    $tg_dir/tinygpu_fsm.v \
    $tg_dir/writeback.v \
    $tg_dir/fpga_top.v \
]

# ---------------------------------------------------------------------
# 3. TinyGPU simulation sources (final_v1/sim -- includes the Option B
#    fix already applied to tb_cva6_boot.v: an extra vse64.v writes
#    C_mul out to MUL_RESULT_ADDR right after vmacc, BEFORE vadd.vv
#    overwrites the shared vd_* latch. RESULT_ADDR still holds C_add.)
# ---------------------------------------------------------------------
set tg_sim_files [list \
    $tg_sim/tb_cva6_boot.v \
    $tg_sim/tb_matmul.v \
    $tg_sim/tb_tinygpu_cvxif.v \
    $tg_sim/axi4_mem_slave.v \
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
add_files -norecurse -fileset sources_1 $tg_dir/boot_image.hex
set_property file_type "Memory Initialization Files" [get_files $tg_dir/boot_image.hex]

# Constraints
add_files -fileset constrs_1 -norecurse $tg_dir/fpga_top.xdc

# `include` search paths -- exact 6-directory list pulled from
# 0_2_CVA6.xpr's own VerilogDir properties (sources_1 fileset), not
# guessed. Missing any of these causes an "cannot open include file"
# compile error (e.g. common_cells/registers.svh, axi/typedef.svh,
# hpdcache_typedef.svh) since CVA6's `include directives are written as
# paths relative to one of these roots, not absolute/local paths.
set cva6_include_dirs [list \
    "D:/CVA6/cva6/core/include" \
    "D:/CVA6/cva6/vendor/pulp-platform/common_cells/include" \
    "D:/CVA6/cva6/vendor/pulp-platform/common_cells/src" \
    "D:/CVA6/cva6/vendor/pulp-platform/axi/include" \
    "D:/CVA6/cva6/common/local/util" \
    "D:/CVA6/cva6/core/cache_subsystem/hpdcache/rtl/include" \
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
puts "NOTE: the PS7 block design (zynq_system.bd) is NOT created by this"
puts "script -- that's a separate step. Once sim confirms Option B works,"
puts "re-run build_zynq_bd.tcl (rtl_dir changed to \"$tg_dir\") followed"
puts "by connect_gp0_direct.tcl (unmodified -- no hardcoded paths in it)"
puts "to recreate the already-fixed PS7+GP0-direct-wiring block design in"
puts "this project, exactly like 0_2_CVA6's, without touching 0_2_CVA6."

