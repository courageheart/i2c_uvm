`ifndef I2C_CREDIT_SLAVE_DRIVER_SV
`define I2C_CREDIT_SLAVE_DRIVER_SV

class i2c_credit_slave_driver extends i2c_driver;
  `uvm_component_utils(i2c_credit_slave_driver)

  int credit_counter;
  i2c_credit_state_e credit_state;

  int cr_return_pipe[$];

  int unsigned total_data_received;
  int unsigned total_credits_returned;
  int unsigned total_credits_initialized;

  function new(string name, uvm_component parent);
    super.new(name, parent);
    credit_counter = 0;
    credit_state = CREDIT_STATE_RESET;
    total_data_received = 0;
    total_credits_returned = 0;
    total_credits_initialized = 0;
  endfunction

  task run_phase(uvm_phase phase);
    vif.scl_drive <= 1'b1;
    vif.sda_drive <= 1'b1;

    if (!cfg.credit_mode_enable) begin
      super.run_phase(phase);
      return;
    end

    credit_init_task();

    fork
      credit_data_receive_loop();
      credit_return_task();
    join
  endtask

  task credit_init_task();
    `uvm_info("CBR_DRV", $sformatf("Starting credit init: depth=%0d", cfg.cbr_depth), UVM_LOW)
    credit_state = CREDIT_STATE_INIT;

    if (cfg.inject_init_glitch) begin
      `uvm_info("CBR_DRV", "Injecting init glitch -- skipping partial init", UVM_MEDIUM)
      credit_counter = cfg.cbr_depth / 2;
      total_credits_initialized = credit_counter;
    end else begin
      credit_counter = cfg.cbr_depth;
      total_credits_initialized = cfg.cbr_depth;
    end

    #(cfg.cbr_depth * cfg.t_low_ns * 1ns);

    credit_state = CREDIT_STATE_READY;
    i2c_event_pool::trigger_event("credit_init_done");
    `uvm_info("CBR_DRV", $sformatf("Credit init complete: %0d credits granted", credit_counter), UVM_LOW)
  endtask

  task credit_data_receive_loop();
    forever begin
      if (!cfg.is_master) begin
        wait_for_request();
        credit_counter--;
        total_data_received++;

        cr_return_pipe.push_back(cfg.cbr_pipe_delay);

        `uvm_info("CBR_DRV", $sformatf("Data received, buffer used: %0d/%0d",
          cfg.cbr_depth - credit_counter, cfg.cbr_depth), UVM_HIGH)

        if (credit_counter <= 0) begin
          credit_state = CREDIT_STATE_EXHAUSTED;
          `uvm_warning("CBR_DRV", "Receiver buffer full -- all credits consumed")
        end else begin
          credit_state = CREDIT_STATE_ACTIVE;
        end
      end else begin
        bit timed_out;
        i2c_event_pool::wait_for_event_timeout(
          i2c_event_pool::ROLE_UPDATE, idle_poll_time, timed_out);
      end
    end
  endtask

  task credit_return_task();
    forever begin
      if (cr_return_pipe.size() > 0) begin
        int delay;
        delay = cr_return_pipe.pop_front();

        repeat (delay) #(cfg.t_low_ns * 1ns);

        credit_counter++;
        total_credits_returned++;

        if (cfg.inject_phantom_credit && (total_credits_returned % 10 == 0)) begin
          credit_counter++;
          total_credits_returned++;
          `uvm_info("CBR_DRV", "Injecting phantom credit", UVM_MEDIUM)
        end

        i2c_event_pool::trigger_event("credit_returned");
        `uvm_info("CBR_DRV", $sformatf("Credit returned, buffer free: %0d/%0d",
          credit_counter, cfg.cbr_depth), UVM_HIGH)
      end else begin
        #(cfg.t_low_ns * 1ns);
      end
    end
  endtask

  function void check_phase(uvm_phase phase);
    super.check_phase(phase);
    if (cfg.credit_mode_enable) begin
      if (credit_counter != int'(cfg.cbr_depth) && !cfg.inject_init_glitch &&
          !cfg.inject_phantom_credit) begin
        `uvm_error("CBR_DRV", $sformatf(
          "TBI-4 violation: credit_counter=%0d expected=%0d (init=%0d rcvd=%0d ret=%0d)",
          credit_counter, cfg.cbr_depth,
          total_credits_initialized, total_data_received, total_credits_returned))
      end
    end
  endfunction

  function void report_phase(uvm_phase phase);
    if (cfg.credit_mode_enable) begin
      `uvm_info("CBR_DRV", $sformatf(
        "CBR Stats: rcvd=%0d returned=%0d init=%0d final_counter=%0d",
        total_data_received, total_credits_returned,
        total_credits_initialized, credit_counter), UVM_LOW)
    end
  endfunction

endclass

`endif // I2C_CREDIT_SLAVE_DRIVER_SV
