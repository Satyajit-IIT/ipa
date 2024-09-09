////////////////////////////////////////////////////////////////////////////////
// Company:        Multitherman Laboratory @ DEIS - University of Bologna     //
//                    Viale Risorgimento 2 40136                              //
//                    Bologna - fax 0512093785 -                              //
//                                                                            //
// Engineer:       Satyajit Das - satyajit.das@unibo.it                       //
//                                                                            //
// Additional contributions by:                                               //
//                                                                            //
//                                                                            //
//                                                                            //
// Create Date:    17/05/2016                                                 // 
// Design Name:    CGRA                                                       // 
// Module Name:    alu                                                        //
// Project Name:                                                              //
// Language:       SystemVerilog                                              //
//                                                                            //
// Description:    ALU_PE                                                     //
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
module alu_pe #(parameter DWIDTH = 32)
   (input logic 						Clk, Reset, ALU_En,Exec_En_Global, data_req_valid_i,
    input logic signed [31:0]        	load_data_i, alu_in_prev,    
    input logic signed [DWIDTH-1:0]  	ALU_In0,
    input logic signed [DWIDTH-1:0]  	ALU_In1,
    input logic [5:0] 	       			Opcode,
    output logic signed [DWIDTH-1:0] 	ALU_Out,
    output logic 	       				ALU_Cond);
   
   logic 		       					data_valid;
   logic [31:0] 	       				alu_out_prev;
   
   always_ff @(posedge Clk or negedge Reset)
     begin
	if(Reset == 1'b0) begin
	   data_valid <= '0;
	   alu_out_prev <= '0;
	   
	end else begin
	   data_valid <= data_req_valid_i;
	   alu_out_prev <= ALU_Out;
	   
	end
     end // always_ff @ (posedge Clk or negedge Reset)
   
   
   always_comb begin
      if(Exec_En_Global == '0) begin
	 ALU_Out <= alu_in_prev;
	 ALU_Cond <= '0;
      end else if(ALU_En == 1'b1) begin
	 if(Opcode == 6'b000111 && data_req_valid_i) begin // LOAD
	    ALU_Out <= load_data_i;
	    ALU_Cond <= 1'b0;
	 end else if(Opcode == 6'b000001) begin
	       ALU_Out <= ALU_In0 + ALU_In1;
	       ALU_Cond <= 1'b0;	
	       
	    end else if(Opcode == 6'b000010) begin // S_ADD
	       ALU_Out <= ALU_In0 + ALU_In1;
	       ALU_Cond <= 1'b0;	
	       
	    end else if(Opcode == 6'b000011) begin
	       ALU_Out <= ALU_In0 - ALU_In1;
	       ALU_Cond <= 1'b0;	
	       
	    end else if(Opcode == 6'b000100) begin
	       ALU_Out <= ALU_In0 * ALU_In1;
	       ALU_Cond <= 1'b0;	
	       
	    end else if(Opcode == 6'b000101) begin
	       ALU_Out <= ALU_In0 << ALU_In1;
	       ALU_Cond <= 1'b0;	
	       
	    end else if(Opcode == 6'b000110) begin
	       ALU_Out <= ALU_In0 >> ALU_In1;
	       ALU_Cond <= 1'b0;	
	       
	    end else if(Opcode == 6'b000111) begin
	       ALU_Cond <= 0;
	       ALU_Out <= alu_in_prev;			
	    end else if(Opcode == 6'b001000) begin
	       ALU_Cond <= 0;	
	       ALU_Out <= alu_in_prev;	
	    end else if(Opcode == 6'b001001) begin //STR
	       ALU_Cond <= 1'b0;	
	       ALU_Out <= ALU_In1;
	    end else if(Opcode == 6'b001011) begin
	       ALU_Out <= ALU_In0 & ALU_In1;
	       ALU_Cond <= 1'b0;	
	       
	    end else if(Opcode == 6'b001100) begin
	       ALU_Out <= ALU_In0 | ALU_In1;
	       ALU_Cond <= 0;	
	       
	    end else if(Opcode == 6'b001101) begin
	       ALU_Out <= !ALU_In0;
	       ALU_Cond <= 1'b0;	
	       
	    end else if(Opcode == 6'b001110) begin
	       ALU_Out <= ALU_In0 ^ ALU_In1;
	       ALU_Cond <= 1'b0;	
	       
	    end else if(Opcode == 6'b001111) begin // MOVE
	       ALU_Out <= ALU_In0;
	       ALU_Cond <= 1'b0;	
	       
	    end else if(Opcode == 6'b010000) begin
	       ALU_Cond <= (ALU_In0 <= ALU_In1)?1'b1:1'b0;	
	       ALU_Out <= '0;
	    end else if(Opcode == 6'b010001) begin
	       ALU_Cond <= (ALU_In0 >= ALU_In1)?1'b1:1'b0;	
	       ALU_Out <= '0;
	       
	    end else if(Opcode == 6'b010100) begin
	       ALU_Cond <= 1'b0;	
	       ALU_Out <= alu_in_prev;
	    end else if(Opcode == 6'b010101) begin
	       ALU_Cond <= (ALU_In0 != ALU_In1)?1'b1:1'b0;	
	       ALU_Out <= '0;
	    end else if(Opcode == 6'b011100) begin
	       ALU_Cond <= (ALU_In0 < ALU_In1)?1'b1:1'b0;	
	       ALU_Out <= '0;
	    end else if(Opcode == 6'b011101) begin
	       ALU_Cond <= (ALU_In0 > ALU_In1)?1'b1:1'b0;	
	       ALU_Out <= '0;
	    end else if(Opcode == 6'b011000) begin
	       ALU_Out <= '0;	
	       ALU_Cond <= '0;
	    end else begin
	       ALU_Cond <= 1'b0;
	       ALU_Out <= alu_in_prev;
	    end // else: !if(Opcode == 5'b11101)
	 end else begin // if (data_valid == 1'b0)
	    ALU_Cond <= 1'b0;
	    ALU_Out <= alu_in_prev;
	 end	 
   end // always_comb begin
endmodule // alu_pe
