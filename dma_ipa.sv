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
// Design Name:    DMA                                                        //
// Module Name:    dma                                                        //
// Project Name:                                                              //
// Language:       SystemVerilog                                              //
//                                                                            //
// Description:    DMA_CGRA                                                   //
//                                                                            //
//                                                                            //
// Revision:                                                                  //
// Revision v0.1 - File Created                                               //
// Revision v0.2 - Updated InData bit selection for inst_num and const_num    //
//                 Updated MIDDLE state                                       //
//                                                                            //
//                                                                            //
//                                                                            //
//                                                                            //
//                                                                            //
//                                                                            //
////////////////////////////////////////////////////////////////////////////////
//module dma_ipa #(parameter NB_ROWS = 2, parameter NB_COLS = 4, parameter GCM_ADDR_WIDTH = 9)(
//module dma_ipa #(parameter NB_ROWS = 3, parameter NB_COLS = 2, parameter GCM_ADDR_WIDTH = 9)(
module dma_ipa #(parameter NB_ROWS = 4, parameter NB_COLS = 4, parameter GCM_ADDR_WIDTH = 9)(
	input logic 	       				Clk, Reset, Context_Fetch_En, exec_comp, read_valid,
	input logic	[63:0]  			In_Data,
	input logic	[4:0] 	    			s_ipa_cfg_id, 
	output logic 	[4:0] 	          		s_ipa_cfg_r_id,				     
	output logic 	[63:0] 				Out_Data,
	output logic 	[22:0] 				Out_Addr,
	output logic    	    			Write_En, Exec_En_Out,
	output logic 	[GCM_ADDR_WIDTH-1:0]		Context_Addr,
	output logic 					ipa_gcm_req_o, busy_o
);

   logic [6:0]	Inst_Number_Reg;
   logic [31:0] Inst_Count;
   logic [31:0] Const_Count;   	 
   logic [4:0] 	Const_Number_Reg;
   logic [15:0] Mask;
   logic [4:0] 	Const_Addr;
   logic [5:0]  Inst_Addr;
   
   logic [4:0] 	Nb_Tiles;	
   logic 		Inst_Fetch, Const_Fetch;
   logic 		End_Tiles, reset_const_inst_addr, complete_load, start;
   logic [4:0] 	id_reg;
   
   enum `ifdef SYNTHESIS logic [2:0] `endif {IDLE, START, IN_ACCEPT, MIDDLE, END_TILE} CS, NS;

   always_ff @(posedge Clk or negedge Reset) begin
      if(Reset == 1'b0)	begin   	
		 Context_Addr <= 0;
		 Nb_Tiles <= '0;
		 Inst_Number_Reg <= '0;
		 Const_Number_Reg <= '0; 
		 CS <= IDLE;
		 Inst_Addr<= '0;
		 Const_Addr <= '0;
		 End_Tiles <= '0;
		 Inst_Count <= 0;
		 Const_Count <= 0;
		 
		 busy_o <= 0;
		 Mask <= '0;	 
      end 
      else if(Context_Fetch_En == 1'b1) begin
      	CS <= START;
		// Const_Number_Reg <= In_Data[16:12];
		Const_Number_Reg <= In_Data[15:11];
		// Inst_Number_Reg <=In_Data[11:5];
		Inst_Number_Reg <=In_Data[10:5];
		Context_Addr <= 0;
		Nb_Tiles <= '0;
		 
		Inst_Addr<= '0;
		Const_Addr <= '0;
		End_Tiles <= '0;
		Inst_Count <= 0;
		Const_Count <= 0;
		id_reg <= s_ipa_cfg_id;
		busy_o <= 1;
		Mask <= (In_Data[4:1]==4'b0000)? 16'h0001:
				In_Data[4:1]==4'b0001 ? 16'h0002:
				In_Data[4:1]==4'b0010 ? 16'h0004:
				In_Data[4:1]==4'b0011 ? 16'h0008:
				In_Data[4:1]==4'b0100 ? 16'h0010:
				In_Data[4:1]==4'b0101 ? 16'h0020:
				In_Data[4:1]==4'b0110 ? 16'h0040:
				In_Data[4:1]==4'b0111 ? 16'h0080:
				In_Data[4:1]==4'b1000 ? 16'h0100:
				In_Data[4:1]==4'b1001 ? 16'h0200:
				In_Data[4:1]==4'b1010 ? 16'h0400:
				In_Data[4:1]==4'b1011 ? 16'h0800:
				In_Data[4:1]==4'b1100 ? 16'h1000:
				In_Data[4:1]==4'b1101 ? 16'h2000:
				In_Data[4:1]==4'b1110 ? 16'h4000:
				16'h8000;
      end       
      else  begin	
	 	CS <= NS;		 
	 	id_reg <= '0;
	 	Context_Addr <= start == 0 ? Context_Addr+1 : Context_Addr;

	 	if(reset_const_inst_addr == '1 ) begin
	      		Inst_Addr<= '0;
	      		Const_Addr <= '0;
	      		End_Tiles <= '0;
	      		Inst_Count <= 0;
	      		Const_Count <= 0;
	      		Nb_Tiles <= Nb_Tiles + 1;
	      		// Const_Number_Reg <= In_Data[16:12];
	      		Const_Number_Reg <= In_Data[15:11];
	      		// Inst_Number_Reg <=In_Data[11:5];
	      		Inst_Number_Reg <=In_Data[10:5];
	      		Mask <= (In_Data[4:1]==4'b0000)? 16'h0001:
			In_Data[4:1]==4'b0001 ? 16'h0002:
			In_Data[4:1]==4'b0010 ? 16'h0004:
			In_Data[4:1]==4'b0011 ? 16'h0008:
			In_Data[4:1]==4'b0100 ? 16'h0010:
			In_Data[4:1]==4'b0101 ? 16'h0020:
			In_Data[4:1]==4'b0110 ? 16'h0040:
			In_Data[4:1]==4'b0111 ? 16'h0080:
			In_Data[4:1]==4'b1000 ? 16'h0100:
			In_Data[4:1]==4'b1001 ? 16'h0200:
			In_Data[4:1]==4'b1010 ? 16'h0400:
			In_Data[4:1]==4'b1011 ? 16'h0800:
			In_Data[4:1]==4'b1100 ? 16'h1000:
			In_Data[4:1]==4'b1101 ? 16'h2000:
			In_Data[4:1]==4'b1110 ? 16'h4000:
			16'h8000; 
	   	end
	 	else begin
	    	if(Inst_Fetch) begin
	       		Inst_Addr<=Inst_Addr+3;
	       		// Inst_Addr<=Inst_Addr+1;
	       		Inst_Count <= Inst_Count+64;
	    	end
	    
	    	if(Const_Fetch) begin
	       		//Const_Addr<=Const_Addr+3;//commented by chilanka to make crf 32 x 24-bit
	       		 Const_Addr<=Const_Addr+2; //two 24-bit constants;added by chilanka to make crf 32 x 24-bit
	       		// Const_Count <= Const_Count+2;
	       		Const_Count <= Const_Count+64;

	       		if(Const_Number_Reg != 1 && Const_Number_Reg != 0) begin 

	       			if((Const_Count < Const_Number_Reg-2)) begin
	       				Context_Addr <=Context_Addr+1; 
	       			end 
	       		end
	    	end 
	 	end // else: !if(reset_const_inst_addr == '1 )

      end
   end // always_ff @ 

   always_comb  begin
      Exec_En_Out <= 1'b0;
      complete_load = 0;
      ipa_gcm_req_o <= '0;
      reset_const_inst_addr = 0;
      start = 0;
      Const_Fetch <= '0;
      Inst_Fetch <= '0;
      NS<=IDLE;
      Write_En <= '0;
      Out_Data <= '0;
      Out_Addr <= '0;

      case(CS)
	IDLE:
	  begin	    	
	     Const_Fetch <= '0;
	     Inst_Fetch <= '0;
	     NS<=IDLE;
	     Write_En <= '0;
	     complete_load = 0;
	     reset_const_inst_addr = 0;	     
	  end
	START:
	  begin	     	
	     Const_Fetch <= '0;
	     Inst_Fetch <= '0;
	     NS <= IN_ACCEPT;
	     Write_En <= '0;
	     ipa_gcm_req_o <= '1;
	  end	     
	IN_ACCEPT:
	  begin
	     ipa_gcm_req_o <= '1;
	     if(In_Data[0] == 1'b0) begin		
		NS <= MIDDLE; 	
		Const_Fetch <= '0;
		Inst_Fetch <= '0;
		Write_En <= '0;
	     end else if(In_Data[0] == 1'b1) begin		
		Const_Fetch <= '0;
		Inst_Fetch <= '0;		
		NS <= MIDDLE;		
	     end // else: !if(In_Data[63] == 1'b0)	     
	  end 
	MIDDLE:
	  begin
	     ipa_gcm_req_o <= '1;

	     // if(Inst_Count <= (((Inst_Number_Reg == 96)||(Inst_Number_Reg == 80)||(Inst_Number_Reg == 48)||(Inst_Number_Reg == 32) || (Inst_Number_Reg == 64) || (Inst_Number_Reg == 128) ||  (Inst_Number_Reg 			== 16)|| (Inst_Number_Reg == 8)|| (Inst_Number_Reg == 4)|| (Inst_Number_Reg == 2)) ? ((Inst_Number_Reg-1) * 20) : (Inst_Number_Reg * 20))) begin

	     if( ( Inst_Count <= ( ((Inst_Number_Reg == 3)||(Inst_Number_Reg == 6)||(Inst_Number_Reg == 9)||(Inst_Number_Reg == 12)
	     	     						||(Inst_Number_Reg == 15)||(Inst_Number_Reg == 18)||(Inst_Number_Reg == 21)||(Inst_Number_Reg == 24)
	     	     						||(Inst_Number_Reg == 27)||(Inst_Number_Reg == 30)||(Inst_Number_Reg == 33)||(Inst_Number_Reg == 36)
	     	     						||(Inst_Number_Reg == 39)||(Inst_Number_Reg == 42)||(Inst_Number_Reg == 45)||(Inst_Number_Reg == 48)
	     	     						||(Inst_Number_Reg == 51)||(Inst_Number_Reg == 54)||(Inst_Number_Reg == 57)||(Inst_Number_Reg == 60)
	     	     						||(Inst_Number_Reg == 63)) ? ((Inst_Number_Reg)*21) : (((Inst_Number_Reg-2)*21) + 63)) ) 
	     	) begin

				Out_Data <= In_Data;
				Out_Addr[15:0] <= Mask;
				Out_Addr[16] <= 1'b0;
				Out_Addr[22:17] <= Inst_Addr;
				NS <= MIDDLE; 	  
				Const_Fetch <= '0;
				Inst_Fetch <= '1;
				Write_En <= 1;	
		
	     // end else if(Const_Count <= Const_Number_Reg-1 && Const_Number_Reg!=0) begin //modified to make CRF 24-bit (2 constants in one line)
	     	/*end else if( ( Const_Count <= ( ((Const_Number_Reg == 3)||(Const_Number_Reg == 6)||(Const_Number_Reg == 9)||(Const_Number_Reg == 12)
	     		     									||(Const_Number_Reg == 15)||(Const_Number_Reg == 18)
												||(Const_Number_Reg == 21)||(Const_Number_Reg == 27)
	     		     									||(Const_Number_Reg == 30)) ? 
												(((Const_Number_Reg)*20)) : (((Const_Number_Reg-2)*20) + 63)) )*/ 
		// edited by chilanka to make crf 32x 24-bit ; Const_Number_Reg/2 *64 wtitten as Const_Number_Reg*32
		end else if(Const_Count < Const_Number_Reg*32) 
		begin

				Out_Data <= In_Data;
				Out_Addr[15:0] <= Mask;
				Out_Addr[16] <= 1'b1;
				Out_Addr[21:17] <= Const_Addr;	 
				// Out_Addr[21] <= '0;
				Out_Addr[22] <= '0;
				Const_Fetch <= '1;
				Inst_Fetch <= '0;
				NS <= MIDDLE;
				Write_En <= 1;
		
	       end else begin // if (Const_Count < Const_Number_Reg)
		
		//if(Nb_Tiles == 5'h0b) begin //rohit -> 5'h0f
		if(Nb_Tiles == 5'h0f) begin //chilanka
		//if(Nb_Tiles == 5'h07) begin //chilanka
		   NS <= END_TILE;
		   complete_load = 1;
		   Const_Fetch <= '0;
		   Inst_Fetch <= '0;
		   Write_En <= '0;
		   reset_const_inst_addr = 1;
		end else begin
		   NS <= IN_ACCEPT;
		   start = 1;
		   Const_Fetch <= '0;
		   Inst_Fetch <= '0;
		   Write_En <= '0;
		   reset_const_inst_addr = 1;
		   
		end
             end
	  end
	END_TILE:
	  begin
	     NS <= IDLE;
	     Exec_En_Out <= 1'b1;
	     Const_Fetch <= '0;
	     Inst_Fetch <= '0;
	     Write_En <= '0;    
	  end
	  
      endcase

   end 

endmodule // dma





