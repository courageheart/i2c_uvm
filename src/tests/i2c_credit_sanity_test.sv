`ifndef I2C_CREDIT_SANITY_TEST_SV
`define I2C_CREDIT_SANITY_TEST_SV

class i2c_credit_sanity_test extends i2c_credit_test_base;
  `uvm_component_utils(i2c_credit_sanity_test)

  function new(string name = "i2c_credit_sanity_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  task run_phase(uvm_phase phase);
    i2c_credit_data_sequence data_seq;

    phase.raise_objection(this);

    `uvm_info("TEST", ">>> Credit Sanity Test: init credits, send within budget, verify balanced", UVM_LOW)

    #50us;

    data_seq = i2c_credit_data_sequence::type_id::create("data_seq");
    data_seq.target_addr = cfg.slave_addr;
    if (!data_seq.randomize() with { num_frames == cfg.cbr_depth / 2; })
      `uvm_fatal("TEST", "Randomization failed")

    data_seq.start(env.agent.cbt_sequencer);

    #(cfg.cbr_pipe_delay * cfg.cbr_depth * cfg.t_low_ns * 1ns);
    #100us;

    `uvm_info("TEST", ">>> Credit Sanity Test Complete", UVM_LOW)
    phase.drop_objection(this);
  endtask

endclass

`endif // I2C_CREDIT_SANITY_TEST_SV
