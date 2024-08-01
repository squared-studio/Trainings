/*
The `float_multi` module performs floating-point multiplication. It takes two input operands
(`opa_i` and `opb_i`) and produces the result (`result_o`). The module supports customizable
floating-point formats through the `fp_t` parameter.
Author : Foez Ahmed (foez.official@gmail.com)
*/

`include "fp_pkg.sv"

module float_multi #(
    parameter type fp_t = fp_pkg::fp16_t  // The floating-point type (default is `fp_pkg::fp16_t`)
) (
    input  fp_t opa_i,    // First operand (floating-point value)
    input  fp_t opb_i,    // Second operand (floating-point value)
    output fp_t result_o  // Result of the multiplication (floating-point value)
);

  //////////////////////////////////////////////////////////////////////////////////////////////////
  //-LOCALPARAMS GENERATED
  //////////////////////////////////////////////////////////////////////////////////////////////////

  localparam int MW = $bits(result_o.man);  // Mantissa Width
  localparam int MPW = MW + 1;  // Mantissa +1 Width
  localparam int MMPW = 2 * $bits(MPW);  // Mult Mantissa +1 Width
  localparam int EXPW = $bits(result_o.exp);  // Exponent Width
  localparam int BIAS = (1 << (EXPW - 1)) - 1; // Bias value
  localparam logic [EXPW-1:0] MAX_EXP = {EXPW{1'b1}}; // Maximum exponent value (all bits set)

  //////////////////////////////////////////////////////////////////////////////////////////////////
  //-SIGNALS
  //////////////////////////////////////////////////////////////////////////////////////////////////

  // Contains the result after interger multiplying {1,manA} & {1,manB}
  logic [MMPW-1:0] int_mult_result;
  logic [MMPW-1:0] int_mult_result_shifted;
  logic [BIAS-2:0] expA, expB ;

  //////////////////////////////////////////////////////////////////////////////////////////////////
  //-ASSIGNMENTS
  //////////////////////////////////////////////////////////////////////////////////////////////////

  // Sign bit of the result (XOR of input operand signs)
  assign result_o.sig = opa_i.sig ^ opb_i.sig;

  // Integer multiplication of mantissas
  assign int_mult_result = {1'b1, opa_i.man} * {1'b1, opb_i.man};

  // Right-shifted version of `int_mult_result`
  assign int_mult_result_shifted = int_mult_result >> 1;

  // Final mantissa (selects shifted or unshifted result based on overflow)
  assign result_o.man = int_mult_result[MMPW-1] ?
                          int_mult_result_shifted[2*MW-1:MW] :
                          int_mult_result[2*MW-1:MW];

  // Adding Bias in Exponent
  assign expA = opa_i.exp + BIAS;
  assign expB = opb_i.exp + BIAS;
  // Exponent calculation based on input operands and intermediate result
  assign result_o.exp = expA + expB + int_mult_result[MMPW-1] - BIAS;

    // Check if result_o.man and result_o.exp are zero
  always_comb begin
    if (result_o.man == 0 && result_o.exp == 0) begin
      result_o = '{sig: 0, man: 0, exp: 0}; // Set the entire result to zero
    end
    else if (result_o.man == 0 && result_o.exp == MAX_EXP) begin
      result_o = '{sig: result_o.sig, man: 0, exp: MAX_EXP}; // Set result to infinity
    end
    else if (result_o.man != 0 && result_o.exp == MAX_EXP) begin
      result_o = '{sig: result_o.sig, man: {MW{1'b1}}, exp: MAX_EXP}; // Set result to NaN
    end

  end

endmodule
