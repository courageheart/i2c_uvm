`ifndef I2C_CREDIT_RANDOM_TEST_SV
`define I2C_CREDIT_RANDOM_TEST_SV

class i2c_credit_random_test extends i2c_credit_test_base;
  `uvm_component_utils(i2c_credit_random_test)

  function new(string name = "i2c_credit_random_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  virtual function void configure_credit_params();
    cfg.credit_mode_enable = 1;
    if (!cfg.randomize() with {
      cbr_depth inside {[4:32]};
      cbr_pipe_delay inside {[1:4]};
      cbr_return_burst inside {[1:4]};
      cbt_pipe_delay inside {[0:2]};
    }) begin
      `uvm_warning("TEST", "Credit config randomization failed, using defaults")
      cfg.cbr_depth = I2C_CREDIT_DEFAULT_DEPTH;
      cfg.cbr_pipe_delay = I2C_CREDIT_DEFAULT_PIPE_DLY;
    end
    `uvm_info("TEST", $sformatf(
      "Randomized credit config: depth=%0d pipe_dly=%0d return_burst=%0d",
      cfg.cbr_depth, cfg.cbr_pipe_delay, cfg.cbr_return_burst), UVM_LOW)
  endfunction

  task run_phase(uvm_phase phase);
    int scenario_count;

    phase.raise_objection(this);

    `uvm_info("TEST", ">>> Credit Random Test: randomized credit depths, delays, burst sizes", UVM_LOW)

    #50us;

    scenario_count = $urandom_range(3, 8);
    repeat (scenario_count) begin
      int choice;
      choice = $urandom_range(0, 2);

      case (choice)
        0: begin
          i2c_credit_data_sequence seq;
          seq = i2c_credit_data_sequence::type_id::create("rand_data_seq");
          seq.target_addr = cfg.slave_addr;
          if (!seq.randomize()) `uvm_error("TEST", "Randomization failed")
          seq.start(env.agent.cbt_sequencer);
        end
        1: begin
          i2c_credit_burst_sequence seq;
          seq = i2c_credit_burst_sequence::type_id::create("rand_burst_seq");
          seq.target_addr = cfg.slave_addr;
          if (!seq.randomize()) `uvm_error("TEST", "Randomization failed")
          seq.start(env.agent.cbt_sequencer);
        end
        2: begin
          i2c_credit_exhaustion_sequence seq;
          seq = i2c_credit_exhaustion_sequence::type_id::create("rand_exhaust_seq");
          seq.target_addr = cfg.slave_addr;
          seq.start(env.agent.cbt_sequencer);
        end
      endcase

      #50us;
    end

    #(cfg.cbr_pipe_delay * cfg.cbr_depth * cfg.t_low_ns * 2ns);
    #200us;

    `uvm_info("TEST", ">>> Credit Random Test Complete", UVM_LOW)
    phase.drop_objection(this);
  endtask

endclass

`endif // I2C_CREDIT_RANDOM_TEST_SV
