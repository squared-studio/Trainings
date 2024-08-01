/*
Description: Testbench for float_multi module
Author: Md Abdullah Al Samad (mdsam.raian@gmail.com)
*/

`include "fp_pkg.sv"

module float_multi_tb;

  // Uncomment to enable waveform dump file
  //`define ENABLE_DUMPFILE

  //////////////////////////////////////////////////////////////////////////////////////////////////
  //-IMPORTS
  //////////////////////////////////////////////////////////////////////////////////////////////////

  import fp_pkg::fp16_t;  // Import the floating-point package
  `include "vip/tb_ess.sv"  // Include essential functions and macros for the testbench

  //////////////////////////////////////////////////////////////////////////////////////////////////
  //-TYPEDEFS
  //////////////////////////////////////////////////////////////////////////////////////////////////

  typedef fp_pkg::fp16_t fp_t;  // Define the floating-point type

  //////////////////////////////////////////////////////////////////////////////////////////////////
  //-SIGNALS
  //////////////////////////////////////////////////////////////////////////////////////////////////
  fp_t opa_i;  // First operand (floating-point value)
  fp_t opb_i;  // Second operand (floating-point value)
  fp_t result_o;  // Result of the multiplication (floating-point value)

  // Generate static clock signal clk_i with tHigh:4ns tLow:6ns
  `CREATE_CLK(clk_i, 4ns, 6ns)

  //////////////////////////////////////////////////////////////////////////////////////////////////
  //-VARIABLES
  //////////////////////////////////////////////////////////////////////////////////////////////////
  int pass;  // Counter for passed test cases
  int fail;  // Counter for failed test cases

  // Mailboxes for communication between driver and monitor
  mailbox #(fp_t) dvr_opa_i_mbx = new();
  mailbox #(fp_t) dvr_opb_i_mbx = new();
  mailbox #(fp_t) mon_opa_i_mbx = new();
  mailbox #(fp_t) mon_opb_i_mbx = new();
  mailbox #(fp_t) mon_result_o_mbx = new();

  //////////////////////////////////////////////////////////////////////////////////////////////////
  //-RTLS
  //////////////////////////////////////////////////////////////////////////////////////////////////
  // Instantiate the float_multi module
  float_multi #(.fp_t(fp16_t)) uut (
    .opa_i(opa_i),
    .opb_i(opb_i),
    .result_o(result_o)
  );

  //////////////////////////////////////////////////////////////////////////////////////////////////
  //-METHODS
  //////////////////////////////////////////////////////////////////////////////////////////////////

  // Task to apply reset to the DUT
  task static apply_reset();
    #100ns;
    opa_i <= '0;
    opb_i <= '0;
    #100ns;
  endtask

  // Task to drive inputs to the DUT
  task static driver();
    fork
      forever begin
        fp_t inA, inB;
        dvr_opa_i_mbx.get(inA);
        dvr_opb_i_mbx.get(inB);
        opa_i <= inA;
        opb_i <= inB;
        @(posedge clk_i);  // Wait for one clock cycle before fetching new inputs
      end
    join_none
  endtask

  // Task to monitor the inputs and outputs of the DUT
  task static monitor();
    fork
      forever begin
        fp_t inA, inB;
        mon_opa_i_mbx.put(opa_i);
        mon_opb_i_mbx.put(opb_i);
        mon_result_o_mbx.put(result_o);
        @(posedge clk_i);  // Wait for one clock cycle before fetching new outputs
      end
    join_none
  endtask


    // Function to compare floating-point numbers with tolerance
  // function bit float_compare(fp_t a, fp_t b, real tolerance = 1e-5);
  //   if (a.exp == b.exp && a.sig == b.sig && (a.man - b.man) < tolerance)
  //     return 1;
  //   else
  //     return 0;
  // endfunction

  // Task to compare the DUT output with the expected output and log results
  task static scoreboard();
    fp_t a, b, expected_out, actual_out;
    //real tolerance = 1e-5;  // Define tolerance for floating-point comparison

    fork
      forever begin
        mon_opa_i_mbx.get(a);
        mon_opb_i_mbx.get(b);
        mon_result_o_mbx.get(actual_out);

        // Calculate expected output
        expected_out = a * b;

        // Display the inputs and expected output
        $display("input A: %p", a);
        $display("input B: %p", b);
        $display("expected output: %p", expected_out);
        $display("actual output: %p", actual_out);

        // Compare actual output with expected output
        //if (float_compare(actual_out, expected_out, tolerance)) begin
        if (actual_out === expected_out) begin
          pass++;
        end else begin
          fail++;
        end

        $display("PASS: %d, FAIL: %d", pass, fail);
      end
    join_none
  endtask

  //////////////////////////////////////////////////////////////////////////////////////////////////
  //-PROCEDURALS
  //////////////////////////////////////////////////////////////////////////////////////////////////

    initial begin  // Main initial block

      // Apply reset to the DUT
      apply_reset();

      // Start the clock signal
      start_clk_i();

      // Start the driver, monitor, and scoreboard tasks
      driver();
      monitor();
      scoreboard();

      // Generate random test cases
      @(posedge clk_i);
      repeat (10) begin
        dvr_opa_i_mbx.put(fp_t'($random));  // Ensure valid range for random values
        dvr_opb_i_mbx.put(fp_t'($random));  // Ensure valid range for random values
        
      end

      // Wait for some time to ensure all transactions are processed
      repeat(12) @(posedge clk_i);

      // Print final results
      result_print(!fail, $sformatf("%0d/%0d PASSED", pass, pass + fail));

      // End the simulation
      $finish;
    end

  endmodule
