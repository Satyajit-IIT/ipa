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
// Module Name:    constantregfile                                            //
// Project Name:                                                              //
// Language:       SystemVerilog                                              //
//                                                                            //
// Description:    Constant register file                                     //
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
module scrf #(parameter READ_AWIDTH = 6, parameter WRITE_AWIDTH = 5, parameter WRITE_DWIDTH = 64, parameter READ_DWIDTH = 20)
	(
		input logic 		   			Clk, Reset, Read_En_CRF_0, Read_En_CRF_1, Write_En,
		input logic [READ_AWIDTH-1:0] 	Read_Addr_CRF_0, Read_Addr_CRF_1,
		input logic [WRITE_DWIDTH-1:0] 	In_Const,
		input logic [WRITE_AWIDTH-1:0] 	Write_Addr,

		input logic [4:0] 				jmp_index,
		input logic 					jmp_trigger,
		input logic [4:0] 				index_addr,
		input logic [4:0] 				BA_addr,
		input logic						ig_en,

		output logic [READ_DWIDTH-1:0] 	Read_Data_CRF_0, Read_Data_CRF_1, 
		output logic [31:0] 	   		address_o
		);
	localparam Num_Regs = 32;
	integer 			   i;

	logic [Num_Regs-1:0][19:0] 	   	Mem_Content ;

	logic [19:0] 					BA;
	logic [19:0] 					index;
	
	logic [19:0] 					index1;
	logic [19:0] 					index2;
	logic [19:0] 					index3;
	logic [19:0] 					index4;

	logic [9:0] 					IG1_start_i;
	logic [9:0] 					IG2_start_i;
	logic [9:0] 					IG3_start_i;
	logic [9:0] 					IG4_start_i;
	logic [10:0] 					update_lv;

	logic [7:0][11:0]				index_mem;
	logic [2:0]						updated_start_addr;
	logic [2:0]						updated_start_addr_i;

	logic [10:0]					index1_agu;
	logic [10:0]					index2_agu;
	logic [31:0]					address;
	logic [4:0]						jmp_index_prev;

	always_ff @(posedge Clk or negedge Reset) begin
		if(Reset == 1'b0) begin
			for(i=0; i<Num_Regs; i++) begin
				Mem_Content[i] <= '0;
			end
			for(i=0; i<8; i++) begin
				index_mem[i] <= 12'b0;
			end
			// for(i=0; i<8; i++) begin
			// 	index_mem[i] <= {Mem_Content[i][19:9],1'b0}; // initialise index_mem with first 8 lines of CRF
			// end
		end else if(Write_En) begin
			Mem_Content[Write_Addr] <= In_Const[63:44];
			Mem_Content[Write_Addr+1] <= In_Const[43:24];
			Mem_Content[Write_Addr+2] <= In_Const[23:4];

			for(i=0; i<8; i++) begin
				index_mem[i] <= {Mem_Content[i][19:9],1'b0}; // initialise index_mem with first 8 lines of CRF
			end	

		end else if (jmp_trigger == 1'b0) begin			
			updated_start_addr <= updated_start_addr_i; // store the address of updated lv **			
			// index_mem[updated_start_addr][10:0] <= update_lv;
			index_mem[updated_start_addr_i][10:0] <= update_lv;
			jmp_index_prev <= jmp_index;
		end else if (ig_en) begin
			address_o <= address;
			// index_mem[updated_start_addr][10:0] <= update_lv;		
		end else begin
			address_o <= address;
			// for(i=0; i<8; i++) begin
			// 	index_mem[i] <= {Mem_Content[i][19:9],1'b0}; // initialise index_mem with first 8 lines of CRF
			// end
		end
	end

	always_comb begin
		//CRF
		if(Read_En_CRF_0 == 1'b1) begin
			Read_Data_CRF_0 <= Mem_Content[Read_Addr_CRF_0];			
        end else begin
        	Read_Data_CRF_0 <= '0;
        end

        if(Read_En_CRF_1 == 1'b1) begin
        	Read_Data_CRF_1 <= Mem_Content[Read_Addr_CRF_1];
      	end else begin
      		Read_Data_CRF_1 <= '0;
      	end

   end // always_comb

   // address generation
 //   always_ff @(posedge Clk or negedge Reset) begin
 //   		if(Reset == 1'b0) begin
	// 		for(i=0; i<8; i++) begin
	// 			index_mem[i] <= 12'b0;
	// 		end

	// 		// for(i=0; i<8; i++) begin
	// 		// 	index_mem[i] <= {Mem_Content[i][19:9],1'b0}; // initialise inst_mem with first 8 lines of CRF
	// 		// end	

	// 		address_o <= '0;
		   
	// 	end else if (jmp_trigger == 1'b0) begin
	// 		// index_mem[updated_start_addr_i][10:0] <= update_lv; // store the updated start value of loop_variable
	// 		updated_start_addr <= updated_start_addr_i; // store the address of updated lv **			
	// 		index_mem[updated_start_addr][10:0] <= update_lv;
	// 	end else if (ig_en) begin
	// 		address_o <= address;
	// 	// end else if (Write_En) begin
	// 	// 	for(i=0; i<8; i++) begin
	// 	// 		index_mem[i] <= {Mem_Content[i][19:9],1'b0}; // initialise inst_mem with first 8 lines of CRF
	// 	// 	end
	// 	end else begin
	// 		for(i=0; i<8; i++) begin
	// 			index_mem[i] <= {Mem_Content[i][19:9],1'b0}; // initialise inst_mem with first 8 lines of CRF
	// 		end
	// 	end
	// end // always_ff

   always_comb begin
   	if (ig_en) begin
   		index = Mem_Content[index_addr]; // IP_addresses 4*5-bits = 20-bits

   		index1 = Mem_Content[index[19:15]]; // 20-bits -> || i | A ||
   		index2 = Mem_Content[index[14:10]];
   		index3 = Mem_Content[index[9:5]];
   		index4 = Mem_Content[index[4:0]];
   
   		IG1_start_i = (index1[19]) ? (index_mem[index1[12:10]][11]) ? index_mem[index_mem[index1[12:10]][3:1]][10:1] : index_mem[index1[12:10]][10:1] : {1'b0,index1[18:10]} ;
   		IG2_start_i = (index2[19]) ? (index_mem[index2[12:10]][11]) ? index_mem[index_mem[index2[12:10]][3:1]][10:1] : index_mem[index2[12:10]][10:1] : {1'b0,index2[18:10]} ;
   		IG3_start_i = (index3[19]) ? (index_mem[index3[12:10]][11]) ? index_mem[index_mem[index3[12:10]][3:1]][10:1] : index_mem[index3[12:10]][10:1] : {1'b0,index3[18:10]} ;
   		IG4_start_i = (index4[19]) ? (index_mem[index4[12:10]][11]) ? index_mem[index_mem[index4[12:10]][3:1]][10:1] : index_mem[index4[12:10]][10:1] : {1'b0,index4[18:10]} ;

   		// IG1_const_i = (index1[19]) ? (index_mem[index1[12:10]][11]) ? index_mem[index_mem[index1[12:10]][3:1]][10:1] : index_mem[index1[12:10]][10:1] : {1'b0,index1[18:10]} ;

   		index1_agu = (IG1_start_i + index1[9:0]) * (IG2_start_i + index2[9:0]);
   		index2_agu = (IG3_start_i + index3[9:0]) * (IG4_start_i + index4[9:0]);

   		// BA = Mem_Content[BA_addr];

   		address = (((index1_agu + index2_agu)<<2) + Mem_Content[BA_addr]);
   	end else begin
   		address = address_o;
   	end

   	if (jmp_trigger == 1'b0) begin

	   	if (index_mem[jmp_index[2:0]][11]==1'b0) begin // 0 = constant

	   		if ((index_mem[jmp_index[2:0]][0]==1'b1)&&(jmp_index_prev==jmp_index)) begin // loop iteration

				// loop (0)increment or (1)decrement and send this value to AGU
	   			update_lv = (Mem_Content[jmp_index][0]) ? {(index_mem[jmp_index[2:0]][10:1] - {2'b0,Mem_Content[jmp_index][8:1]}),1'b1} 
	   													: {(index_mem[jmp_index[2:0]][10:1] + {2'b0,Mem_Content[jmp_index][8:1]}),1'b1};
	   			updated_start_addr_i = jmp_index[2:0];

	   		end else if ((index_mem[jmp_index[2:0]][0]==1'b1)&&(jmp_index_prev!=jmp_index)) begin // already updated, skip

				update_lv = index_mem[updated_start_addr][10:0];
   				updated_start_addr_i = updated_start_addr;		   		
		   		
	   		end else begin // loop enter
	   			update_lv = (Mem_Content[jmp_index][0]) ? {(index_mem[jmp_index[2:0]][10:1]),1'b1} : {(index_mem[jmp_index[2:0]][10:1]),1'b1};
 				updated_start_addr_i = jmp_index[2:0];
   			end
	   		
   		end else begin // 1 = loop variable
   			if ((index_mem[index_mem[jmp_index[2:0]][3:1]][0]==1'b1)&&(jmp_index_prev==jmp_index)) begin // loop iteration
 
   				// loop (0)increment or (1)decrement and send this value to AGU
	   			update_lv = (Mem_Content[jmp_index][0]) ? {(index_mem[index_mem[jmp_index[2:0]][3:1]][10:1] - {2'b0,Mem_Content[jmp_index][8:1]}),1'b1} 
	   													: {(index_mem[index_mem[jmp_index[2:0]][3:1]][10:1] + {2'b0,Mem_Content[jmp_index][8:1]}),1'b1};
	   			updated_start_addr_i = index_mem[jmp_index[2:0]][3:1];

	   		end else if ((index_mem[index_mem[jmp_index[2:0]][3:1]][0]==1'b1)&&(jmp_index_prev!=jmp_index)) begin // already updated, skip

				update_lv = index_mem[updated_start_addr][10:0];
   				updated_start_addr_i = updated_start_addr;

	   		end else begin // loop enter
	   			update_lv = (Mem_Content[jmp_index][0]) ? {(index_mem[index_mem[jmp_index[2:0]][3:1]][10:1]),1'b1} : {(index_mem[index_mem[jmp_index[2:0]][3:1]][10:1]),1'b1};
   				updated_start_addr_i = index_mem[jmp_index[2:0]][3:1];
   			end
   		end
   	end else begin
   		update_lv = index_mem[updated_start_addr][10:0];
   		updated_start_addr_i = updated_start_addr;
   	end

   	//  else begin
   	// end
   end // always_comb

   // assign loop_end = (updated_start_addr_i!=updated_start_addr) ? 1'b1 : 1'b0 ;


  /* agu agu (
	//INPUT
		.index_0(index1_agu),
		.index_1(index2_agu),
		.base_adr(BA),
	//OUTPUT
		.address(address)
		); */

   // assign address_o = address;

endmodule // constantregfile



