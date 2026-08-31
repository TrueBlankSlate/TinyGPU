# 02_import_sources.tcl -- run with 01_create_project.tcl's project open.
#
# core_dir is computed from this script's own location ([info script] is
# 4_64_Core/build/02_import_sources.tcl, one level up is 4_64_Core itself,
# the flat directory holding every TinyGPU-authored file) -- works
# unmodified regardless of where this repo is cloned.
set core_dir [file normalize [file dirname [info script]]/..]
set sim_dir  "$core_dir/sim"
set build_dir "$core_dir/build"

# Convention (same as TinyGPU-main/build/import_sources.tcl): clone the
# CVA6 core repo as a SIBLING of wherever you clone this TinyGPU repo.
# 4_64_Core sits one level deeper than TinyGPU-main's own root
# (D:/TinyGPU/TinyGPU/4_64_Core vs. D:/TinyGPU/TinyGPU-main), so this is
# 3 ".." up from core_dir, not 2 -- confirmed against this machine's actual
# layout (D:/TinyGPU/TinyGPU/4_64_Core/../../../CVA6/cva6 = D:/CVA6/cva6).
# Override this line if your CVA6 clone lives somewhere else.
set CVA6_ROOT [file normalize "$core_dir/../../../CVA6/cva6"]

# ---------------------------------------------------------------------
# 1. External CVA6 core (identical file list to TinyGPU-main/build/
#    import_sources.tcl -- the CVA6 side of the build never depends on
#    how the TinyGPU side happens to be laid out)
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
# 2. TinyGPU RTL -- 4_64_Core's flat layout (no cvxif/tinygpu split here,
#    unlike TinyGPU-main). Every file fpga_top.v's hierarchy needs, per
#    build/sim/build_zynq_bd.tcl's own established file list.
# ---------------------------------------------------------------------
set tg_rtl_files [list \
    $core_dir/alu.v \
    $core_dir/axi4_bram_slave.v \
    $core_dir/cache.v \
    $core_dir/cache_l3.v \
    $core_dir/cva6_sv_shim.sv \
    $core_dir/cva6_tinygpu_soc.v \
    $core_dir/design_1.v \
    $core_dir/design_1_wrapper.v \
    $core_dir/fourc_1.v \
    $core_dir/fourc_1_wrapper.v \
    $core_dir/register_file.v \
    $core_dir/tingpu_decoder.v \
    $core_dir/tinygpu_cvxif_wrap.v \
    $core_dir/tinygpu_fsm.v \
    $core_dir/writeback.v \
    $core_dir/fpga_top.v \
]

# ---------------------------------------------------------------------
# 3. TinyGPU simulation sources (4_64_Core/sim/ -- axi4_mem_slave.v lives
#    here too, unlike TinyGPU-main where it sits in src/rtl/cvxif/).
#    tb_cva6_boot.v is Option B (two vse64.v writebacks: C_mul then
#    C_add), matching main and fw/boot_matmul.S's program shape --
#    directly shows matmul-then-matadd from the default sim top.
# ---------------------------------------------------------------------
set tg_sim_files [list \
    $sim_dir/tb_cva6_boot.v \
    $sim_dir/tb_matmul.v \
    $sim_dir/tb_tinygpu_cvxif.v \
    $sim_dir/axi4_mem_slave.v \
    $sim_dir/tb_boot_image.v \
]

# ---------------------------------------------------------------------
# 4. Add everything
# ---------------------------------------------------------------------
add_files -norecurse $cva6_core_files
add_files -norecurse $tg_rtl_files
add_files -fileset sim_1 -norecurse $tg_sim_files

# boot_image.hex -- axi4_bram_slave.v's $readmemh INIT_FILE.
add_files -norecurse -fileset sources_1 $core_dir/boot_image.hex
set_property file_type "Memory Initialization Files" [get_files $core_dir/boot_image.hex]

# Constraints
add_files -fileset constrs_1 -norecurse $core_dir/fpga_top.xdc

# `include` search paths -- same 6-directory list as TinyGPU-main (CVA6's
# own `include directives are written relative to one of these roots).
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

# XSIM macro -- several pulp-platform common_cells files guard an SVA
# construct XSim doesn't support behind `ifndef XSIM. Without this define,
# xvlog fails with "Default Disable iff declaration is not supported yet
# for simulation".
set_property verilog_define {XSIM} [get_filesets sources_1]
set_property verilog_define {XSIM} [get_filesets sim_1]

update_compile_order -fileset sources_1
update_compile_order -fileset sim_1

# Sim top -- verify in simulation before ever touching synth/impl.
set_property top tb_cva6_boot [get_filesets sim_1]

puts "\n==== Import complete ===="
puts "CVA6 core files added : [llength $cva6_core_files]"
puts "TinyGPU RTL files added: [llength $tg_rtl_files]"
puts "TinyGPU sim files added: [llength $tg_sim_files]"
puts "boot_image.hex, fpga_top.xdc added."
puts "Sim top set to tb_cva6_boot -- run behavioral simulation now (Flow"
puts "Navigator -> Run Simulation -> Run Behavioral Simulation) and confirm"
puts "MUL_RESULT_ADDR+15 == 600 (C_mul row3 col3) and RESULT_ADDR+15 == 32"
puts "(C_add row3 col3) before running synth/impl."
puts ""
puts "Also added: tb_boot_image.v -- a second testbench that instantiates"
puts "the REAL axi4_bram_slave.v and \$readmemh's a boot_image.hex the same"
puts "way real hardware does (unlike tb_cva6_boot.v, which pokes its own"
puts "hand-written instruction stream directly into memory and never reads"
puts "boot_image.hex at all). Use it to verify the fw/ compiler-produced"
puts "boot_image.hex (Option B: matmul then matadd) BEFORE touching"
puts "hardware: set_property top tb_boot_image \[get_filesets sim_1\]"
puts ""
puts "Next: 03_build_bd.tcl"
