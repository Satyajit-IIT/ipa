////////////////////////////////////////////////////////////////////////////////
// Company:        Lab-STICC @ Université Bretagne Sud					      //
//                 27 rue Armand Guillemot BP 92116,56321                     //
//                 LORIENT Cedex - Tél. 02 97 87 66 66 -                      //
//                                                                            //
// Engineer:       Rohit Prasad - rohit.prasad@univ-ubs.fr                    //
//																			  //
// Source : https://github.com/pulp-platform/fpu  							  //
//													                          //
// Additional contributions by:                                               //
//                                                                            //
//                                                                            //
//                                                                            //
// Create Date:    21/02/2019                                                 //
// Design Name:    floating point unit  				                      //
// Module Name:    sfu_top                                                    //
// Project Name:                                                              //
// Language:       SystemVerilog                                              //
//                                                                            //
// Description:    modified code from pulp_platform (RISCV fpu)				  // 
//				   to be compatible with IPA 					  			  //
//                                                                            //
//                                                                            //
// Revision:                                                                  //
// Revision v0.1 - File Created                                               //
//                                                                            //
//                                                                            //
//                                                                            //
//                                                                            //
//                                                                            //
//                                                                            //
//////////////////////////////////////////////////////////////////////////////// 

module fpu_top
  (
   //Clock and reset
   input logic 	              Clk,
   input logic 	              Reset,
   input logic                Enable_SI,

   input logic			      Exec_En_Global, 	//
   input logic			      data_req_valid_i, 	//

   //Input Operands
   input logic [31:0]         load_data_i,		//
   input logic [31:0]         fpu_in_prev,		//
   input logic [31:0]         Operand_a_DI,
   input logic [31:0]         Operand_b_DI,
   input logic [5:0]    OP_SI,				// opcode 6-bits

   //OUTPUT
   // output logic               SFU_Cond,
   output logic [31:0]        Result_DO,

   output logic               result_valid_o, // result is valid
   output logic               fpu_busy
   );

   // Number of cycles the fpu needs, after two cycles the output is valid
   localparam CYCLES = 2;
   logic [$clog2(CYCLES):0]     valid_count_q, valid_count_n;
   logic [31:0]                 Result_DO_i;

   // result is valid if we waited 2 cycles
   // assign result_valid_o = (valid_count_q == CYCLES - 1) ? 1'b1 : 1'b0;

  /* always_comb
   begin
   	if (Enable_SI)
   	begin
      if (OP_SI == 6'b011001) // fLT
      begin
        if (Operand_a_DI[31]=='1 && Operand_a_DI[31]=='0) begin
          Result_DO_i = '1;
        end else if (Operand_a_DI[30:23] < Operand_b_DI[30:23] ) begin
          Result_DO_i = '1;
        end else if (Operand_a_DI[22:16] < Operand_b_DI[22:16] ) begin
          Result_DO_i = '1;
        end else begin
          Result_DO_i = '0;
        end
      end else if (OP_SI == 6'b011010) //fABS
      begin
        Result_DO_i = {1'b0,Operand_a_DI[30:0]};
      end      
   	end
   end */

   // combinatorial update logic - set output bit accordingly
   always_comb
   begin
      valid_count_n = valid_count_q;
      // sfu_ready_o = 1'b1;

      // if (Enable_SI)
      if (fpu_busy)
      begin
          valid_count_n = valid_count_q + 1;
          // sfu_busy = 1'b1;
          // sfu_ready_o = 1'b0;
          // if we already waited 2 cycles set the output to valid, fpu is ready
          if (valid_count_q == CYCLES - 1)
          begin
            // sfu_ready_o = 1'b1;
            valid_count_n = 2'd0;
            // sfu_busy = 1'b0;
          end
      end
   end

   always_ff @(posedge Clk, negedge Reset)
    begin
      if (Reset == 1'b0)
      begin
        valid_count_q <= 1'b0;
        fpu_busy <= 1'b0;
      end
      else
      begin
        if (Enable_SI)
        begin
          valid_count_q <= valid_count_n;
          fpu_busy <= 1'b1;
        end
        if (valid_count_n==CYCLES - 1)
        begin          
          fpu_busy <= 1'b0;
        end
      end
    end

   /////////////////////////////////////////////////////////////////////////////
   // FPU_core                                                                //
   /////////////////////////////////////////////////////////////////////////////

  fpu_core fpu_core_i

     (
   //Clock and reset
   .Clk_CI(Clk),
   .Rst_RBI(Reset),
   .Enable_SI(Enable_SI),

   //Input Operands
   .Operand_a_DI(Operand_a_DI),
   .Operand_b_DI(Operand_b_DI),
   .RM_SI(3'h1),    //Rounding Mode
   .OP_SI(OP_SI[3:0]),

   .Result_DO(Result_DO_i),
   .Valid_SO(result_valid_o),

   //Output-Flags
   .OF_SO(),    //Overflow
   .UF_SO(),    //Underflow
   .Zero_SO(),  //Result zero
   .IX_SO(),    //Result inexact
   .IV_SO(),    //Result invalid
   .Inf_SO()    //Infinity
   );

  assign Result_DO = Result_DO_i;

endmodule // fpu_top
