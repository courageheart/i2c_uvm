`ifndef I2C_CONFIG_SV
`define I2C_CONFIG_SV

class i2c_config extends uvm_object;
  
  uvm_active_passive_enum is_active = UVM_ACTIVE;
  
  bit is_master = 1;
  
  bit [6:0] slave_addr = 7'h55;
  
  i2c_speed_e speed = I2C_STANDARD_MODE;

  int t_low_ns;
  int t_high_ns;
  int t_buf_ns;

  // ---- Credit-Based Flow Control Configuration ----
  bit credit_mode_enable = 0;

  rand int unsigned cbr_depth;
  rand int unsigned cbt_pipe_delay;
  rand int unsigned cbr_pipe_delay;
  rand int unsigned cbr_return_burst;

  int unsigned credit_init_timeout_ns  = 500_000;
  int unsigned credit_return_timeout_ns = 200_000;
  int unsigned credit_stall_timeout_ns  = 1_000_000;

  bit inject_send_without_credit = 0;
  bit inject_phantom_credit      = 0;
  bit inject_init_glitch         = 0;

  bit [6:0] credit_reg_addr = 7'h50;
  
  `uvm_object_utils_begin(i2c_config)
    `uvm_field_enum(uvm_active_passive_enum, is_active, UVM_ALL_ON)
    `uvm_field_int(is_master, UVM_ALL_ON)
    `uvm_field_int(slave_addr, UVM_ALL_ON)
    `uvm_field_enum(i2c_speed_e, speed, UVM_ALL_ON)
    `uvm_field_int(t_low_ns, UVM_ALL_ON)
    `uvm_field_int(t_high_ns, UVM_ALL_ON)
    `uvm_field_int(credit_mode_enable,         UVM_ALL_ON)
    `uvm_field_int(cbr_depth,                  UVM_ALL_ON)
    `uvm_field_int(cbt_pipe_delay,             UVM_ALL_ON)
    `uvm_field_int(cbr_pipe_delay,             UVM_ALL_ON)
    `uvm_field_int(cbr_return_burst,           UVM_ALL_ON)
    `uvm_field_int(credit_init_timeout_ns,     UVM_ALL_ON)
    `uvm_field_int(credit_return_timeout_ns,   UVM_ALL_ON)
    `uvm_field_int(credit_stall_timeout_ns,    UVM_ALL_ON)
    `uvm_field_int(inject_send_without_credit, UVM_ALL_ON)
    `uvm_field_int(inject_phantom_credit,      UVM_ALL_ON)
    `uvm_field_int(inject_init_glitch,         UVM_ALL_ON)
    `uvm_field_int(credit_reg_addr,            UVM_ALL_ON)
  `uvm_object_utils_end

  constraint c_cbr_depth {
    cbr_depth inside {[2:I2C_CREDIT_MAX_DEPTH]};
  }

  constraint c_pipe_delays {
    cbt_pipe_delay inside {[0:4]};
    cbr_pipe_delay inside {[1:8]};
  }

  constraint c_return_burst {
    cbr_return_burst inside {[1:cbr_depth]};
  }

  constraint c_default_depth {
    soft cbr_depth == I2C_CREDIT_DEFAULT_DEPTH;
    soft cbt_pipe_delay == 0;
    soft cbr_pipe_delay == I2C_CREDIT_DEFAULT_PIPE_DLY;
    soft cbr_return_burst == 1;
  }

  function new(string name = "i2c_config");
    super.new(name);
  endfunction

  function void set_default_timings();
    case (speed)
      I2C_STANDARD_MODE: begin
        t_low_ns  = 4700;
        t_high_ns = 4000;
        t_buf_ns  = 4700;
      end
      I2C_FAST_MODE: begin
        t_low_ns  = 1300;
        t_high_ns = 600;
        t_buf_ns  = 1300;
      end
      I2C_FAST_MODE_PLUS: begin
        t_low_ns  = 500;
        t_high_ns = 260;
        t_buf_ns  = 500;
      end
    endcase
  endfunction

endclass

`endif // I2C_CONFIG_SV
