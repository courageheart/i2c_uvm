`ifndef I2C_CREDIT_MASTER_DRIVER_SV
`define I2C_CREDIT_MASTER_DRIVER_SV

class i2c_credit_master_driver extends i2c_driver;
  `uvm_component_utils(i2c_credit_master_driver)

  int credit_counter;
  i2c_credit_state_e credit_state;

  int unsigned total_data_sent;
  int unsigned total_stall_cycles;
  int unsigned total_credits_received;

  function new(string name, uvm_component parent);
    super.new(name, parent);
    credit_counter = 0;
    credit_state = CREDIT_STATE_RESET;
    total_data_sent = 0;
    total_stall_cycles = 0;
    total_credits_received = 0;
  endfunction

  task run_phase(uvm_phase phase);
    vif.scl_drive <= 1'b1;
    vif.sda_drive <= 1'b1;

    if (!cfg.credit_mode_enable) begin
      super.run_phase(phase);
      return;
    end

    wait_for_credit_init();

    forever begin
      if (cfg.is_master) begin
        req = null;
        seq_item_port.try_next_item(req);
        if (req != null) begin
          case (req.frame_type)
            I2C_CREDIT_FRAME_DATA: begin
              wait_for_credit();
              drive_transfer(req);
              credit_counter--;
              total_data_sent++;
              `uvm_info("CBT_DRV", $sformatf("Data sent, credits remaining: %0d", credit_counter), UVM_MEDIUM)
              update_credit_state();
            end
            default: begin
              drive_transfer(req);
            end
          endcase
          seq_item_port.item_done();
        end else begin
          bit timed_out;
          i2c_event_pool::wait_for_event_timeout(
            i2c_event_pool::ROLE_UPDATE, idle_poll_time, timed_out);
        end
      end else begin
        wait_for_request();
      end
    end
  endtask

  task wait_for_credit_init();
    bit timed_out;
    `uvm_info("CBT_DRV", "Waiting for credit initialization...", UVM_LOW)
    credit_state = CREDIT_STATE_INIT;

    i2c_event_pool::wait_for_event_timeout(
      "credit_init_done", cfg.credit_init_timeout_ns * 1ns, timed_out);

    if (timed_out) begin
      `uvm_error("CBT_DRV", "Credit initialization timed out")
      credit_state = CREDIT_STATE_ERROR;
      return;
    end

    credit_counter = cfg.cbr_depth;
    total_credits_received = cfg.cbr_depth;
    credit_state = CREDIT_STATE_READY;
    `uvm_info("CBT_DRV", $sformatf("Credit init complete: %0d credits available", credit_counter), UVM_LOW)
  endtask

  task wait_for_credit();
    if (cfg.inject_send_without_credit) return;

    if (credit_counter <= 0) begin
      bit timed_out;
      credit_state = CREDIT_STATE_EXHAUSTED;
      i2c_event_pool::trigger_event("credit_exhausted");
      `uvm_info("CBT_DRV", "Credits exhausted, stalling...", UVM_MEDIUM)

      i2c_event_pool::wait_for_event_timeout(
        "credit_returned", cfg.credit_stall_timeout_ns * 1ns, timed_out);

      if (timed_out) begin
        `uvm_error("CBT_DRV", "Credit stall timeout -- potential credit deadlock")
        credit_state = CREDIT_STATE_ERROR;
      end else begin
        total_stall_cycles++;
      end
    end
    credit_state = CREDIT_STATE_ACTIVE;
  endtask

  function void receive_credit(int count = 1);
    credit_counter += count;
    total_credits_received += count;
    update_credit_state();
    i2c_event_pool::trigger_event("credit_returned");
    `uvm_info("CBT_DRV", $sformatf("Credit returned (+%0d), total: %0d", count, credit_counter), UVM_HIGH)
  endfunction

  function void update_credit_state();
    if (credit_counter <= 0)
      credit_state = CREDIT_STATE_EXHAUSTED;
    else if (credit_counter >= int'(cfg.cbr_depth))
      credit_state = CREDIT_STATE_READY;
    else
      credit_state = CREDIT_STATE_ACTIVE;
  endfunction

  function void report_phase(uvm_phase phase);
    if (cfg.credit_mode_enable) begin
      `uvm_info("CBT_DRV", $sformatf(
        "CBT Stats: sent=%0d stalls=%0d credits_rcvd=%0d final_counter=%0d",
        total_data_sent, total_stall_cycles, total_credits_received, credit_counter), UVM_LOW)
    end
  endfunction

endclass

`endif // I2C_CREDIT_MASTER_DRIVER_SV
