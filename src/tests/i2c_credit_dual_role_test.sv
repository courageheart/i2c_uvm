`ifndef I2C_CREDIT_DUAL_ROLE_TEST_SV
`define I2C_CREDIT_DUAL_ROLE_TEST_SV

class i2c_credit_dual_role_test extends i2c_credit_test_base;
  `uvm_component_utils(i2c_credit_dual_role_test)

  function new(string name = "i2c_credit_dual_role_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  virtual function void configure_credit_params();
    super.configure_credit_params();
    cfg.cbr_depth = 8;
    cfg.cbr_pipe_delay = 2;
  endfunction

  task run_phase(uvm_phase phase);
    i2c_credit_data_sequence data_seq;
    bit timed_out;

    phase.raise_objection(this);

    `uvm_info("TEST", ">>> Credit Dual-Role Test: credit protocol across role switches", UVM_LOW)

    // Phase 1: Master mode with credit flow
    `uvm_info("TEST", "Phase 1: Master mode credit flow", UVM_LOW)
    #50us;

    data_seq = i2c_credit_data_sequence::type_id::create("data_seq");
    data_seq.target_addr = cfg.slave_addr;
    if (!data_seq.randomize() with { num_frames == 4; })
      `uvm_fatal("TEST", "Randomization failed")
    data_seq.start(env.agent.cbt_sequencer);

    #50us;
    i2c_event_pool::reset_event(i2c_event_pool::BUS_IDLE);
    i2c_event_pool::wait_for_event_timeout(i2c_event_pool::BUS_IDLE, 200us, timed_out);

    // Phase 2: Switch to slave mode
    `uvm_info("TEST", "Phase 2: Switching to slave mode", UVM_LOW)
    cfg.is_master = 0;
    i2c_event_pool::trigger_event(i2c_event_pool::ROLE_UPDATE);

    #100us;

    // Phase 3: Switch back to master mode
    `uvm_info("TEST", "Phase 3: Switching back to master mode", UVM_LOW)
    cfg.is_master = 1;
    i2c_event_pool::trigger_event(i2c_event_pool::ROLE_UPDATE);

    #50us;

    // Phase 4: Resume credit flow
    data_seq = i2c_credit_data_sequence::type_id::create("data_seq2");
    data_seq.target_addr = cfg.slave_addr;
    if (!data_seq.randomize() with { num_frames == 3; })
      `uvm_fatal("TEST", "Randomization failed")
    data_seq.start(env.agent.cbt_sequencer);

    #(cfg.cbr_pipe_delay * cfg.cbr_depth * cfg.t_low_ns * 2ns);
    #200us;

    `uvm_info("TEST", ">>> Credit Dual-Role Test Complete", UVM_LOW)
    phase.drop_objection(this);
  endtask

endclass

`endif // I2C_CREDIT_DUAL_ROLE_TEST_SV
