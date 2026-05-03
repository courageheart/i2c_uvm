`ifndef I2C_CREDIT_TYPES_SV
`define I2C_CREDIT_TYPES_SV

// Credit Protocol Frame Types
typedef enum bit [1:0] {
  I2C_CREDIT_FRAME_DATA   = 2'b00,
  I2C_CREDIT_FRAME_INIT   = 2'b01,
  I2C_CREDIT_FRAME_RETURN = 2'b10,
  I2C_CREDIT_FRAME_STATUS = 2'b11
} i2c_credit_frame_e;

// Credit Protocol States
typedef enum bit [2:0] {
  CREDIT_STATE_RESET      = 3'b000,
  CREDIT_STATE_INIT       = 3'b001,
  CREDIT_STATE_READY      = 3'b010,
  CREDIT_STATE_ACTIVE     = 3'b011,
  CREDIT_STATE_EXHAUSTED  = 3'b100,
  CREDIT_STATE_ERROR      = 3'b101
} i2c_credit_state_e;

// Credit Error Types (for monitor/scoreboard error injection and detection)
typedef enum bit [2:0] {
  CREDIT_ERR_NONE         = 3'b000,
  CREDIT_ERR_UNDERFLOW    = 3'b001,
  CREDIT_ERR_OVERFLOW     = 3'b010,
  CREDIT_ERR_INIT_MISSING = 3'b011,
  CREDIT_ERR_PHANTOM      = 3'b100,
  CREDIT_ERR_TIMEOUT      = 3'b101
} i2c_credit_error_e;

// Credit protocol constants
parameter int I2C_CREDIT_DEFAULT_DEPTH    = 8;
parameter int I2C_CREDIT_MAX_DEPTH        = 256;
parameter int I2C_CREDIT_DEFAULT_PIPE_DLY = 2;

// Credit frame encoding: first data byte encodes the frame type
// [7:6] = frame_type, [5:0] = payload (credit count or frame_id)
parameter int I2C_CREDIT_FRAME_TYPE_MSB = 7;
parameter int I2C_CREDIT_FRAME_TYPE_LSB = 6;
parameter int I2C_CREDIT_PAYLOAD_MSB    = 5;
parameter int I2C_CREDIT_PAYLOAD_LSB    = 0;

`endif // I2C_CREDIT_TYPES_SV
