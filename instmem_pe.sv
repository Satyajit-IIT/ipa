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
// Module Name:    instmem                                                    //
// Project Name:                                                              //
// Language:       SystemVerilog                                              //
//                                                                            //
// Description:    Instruction memory                                         //
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
module instmem_pe #(parameter WRITE_AWIDTH = 6, parameter WRITE_DWIDTH = 64, parameter READ_AWIDTH = 6, parameter READ_DWIDTH = 21)
   (
     input logic 	              Clk, Write_En, Reset, exec_en,
     input logic  [WRITE_AWIDTH-1:0]  Write_Addr,
     input logic  [WRITE_DWIDTH-1:0]  In_Inst,
     input logic  [READ_AWIDTH-1:0]   Inst_Addr,
     output logic [READ_DWIDTH-1:0]   Inst_Data
     );
   integer 			i;
   
   logic [63:0] [20:0] im ;//64x21 ins memory
   logic [20:0]        temp;
   logic [5:0]      opcode; // for debugging purpose only
   
   always_ff @(posedge Clk or negedge Reset) begin
      if(Reset == 1'b0) begin
       for(i=0; i<8; i++) begin
         im[i] <= '0;
        //im[i] <= im[i];//chilanka; to facilitate restart (while running outer loops on cpu and inner loop on ipa)
       end
    end else if(Write_En == 1'b1) begin
            for(i=0; i<8; i++) begin //chilanka
               if(i<Write_Addr || i>Write_Addr+2)
               	im[i] <= im[i];
           end
      // if (Write_Addr < 63) begin
           // im[Write_Addr] <= In_Inst[63:43];
           // im[Write_Addr+1] <= In_Inst[42:22];
           // im[Write_Addr+2] <= In_Inst[21:1];
           im[Write_Addr] <= In_Inst[63:43];
           im[Write_Addr+1] <= In_Inst[42:22];
           im[Write_Addr+2] <= In_Inst[21:1];
      // end else begin
      //    im[Write_Addr] <= In_Inst[63:43];
      // end
    end
    else begin //chilanka 
	   for(i=0; i<8; i++) begin             
               	im[i] <= im[i];
           end
   end
 end


//initial begin
//$readmemh("program.bin", im);
//end
always_comb begin
      Inst_Data <= im[Inst_Addr];
      opcode <= Inst_Data[5:0];

      // if (Inst_Addr == 6'b000000) begin
      //     Inst_Data[Inst_Addr] <= im[Inst_Addr];
      // end        
end // always_comb begin

endmodule

