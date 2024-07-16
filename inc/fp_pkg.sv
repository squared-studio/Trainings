`ifndef FP_PKG__
`define FP_PKG__

package fp_pkg;

  typedef struct packed {
    logic       sig;
    logic [4:0] exp;
    logic [9:0] man;
  } fp16_t;

  typedef struct packed {
    logic        sig;
    logic [7:0]  exp;
    logic [22:0] man;
  } fp32_t;

  typedef struct packed {
    logic        sig;
    logic [10:0] exp;
    logic [51:0] man;
  } fp64_t;

endpackage

`endif
