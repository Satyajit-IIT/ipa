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
// Module Name:    CGRA                                                       //
// Project Name:                                                              //
// Language:       SystemVerilog                                              //
//                                                                            //
// Description:    CGRA                                                       //
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
module cgra 
  #(
   // parameter NB_ROWS = 3,
  //  parameter NB_COLS=2, 
      parameter NB_ROWS = 4, //nbrows=3, nbcols=2 for(2x3 cgra in compiler)
      parameter NB_COLS=4, 
      parameter DATA_WIDTH = 32, 
      parameter NB_LS = 8
  //  parameter NB_LS = 6
    )
   (
    input logic 				  Clk, Reset, DMA_Read_En, Exec_En,
    input logic [(NB_ROWS*NB_COLS)-1:0] 	  Load_Store_Grant_I, Data_Req_Valid_I,
    input logic [63:0] 				  DMA_Data_In, 
    input logic [22:0] 				  DMA_Addr_In,
    input logic [(NB_LS)-1 : 0] [DATA_WIDTH-1:0]  Load_Data_I,
    output logic [(NB_LS)-1 : 0] [DATA_WIDTH-1:0] Load_Store_Addr_O,
    output logic [(NB_ROWS*NB_COLS)-1 : 0] 	  End_Exec_O,
    output logic [(NB_LS)-1:0] 			  Load_Store_Req_O, Load_Store_Data_Req_O,
    output logic [(NB_LS)-1 : 0] [DATA_WIDTH-1:0] Store_Data_O
    );

   logic [(NB_ROWS-1) : 0][(NB_COLS-1):0][DATA_WIDTH-1:0] PE_Out_N;
   logic [(NB_ROWS-1) : 0][(NB_COLS-1):0][DATA_WIDTH-1:0] PE_Out_S;
   logic [(NB_ROWS-1) : 0][(NB_COLS-1):0][DATA_WIDTH-1:0] PE_Out_E;
   logic [(NB_ROWS-1) : 0][(NB_COLS-1):0][DATA_WIDTH-1:0] PE_Out_W;
   logic [(NB_ROWS*NB_COLS)-1 : 0] 			  PE_Cond_Out;
   logic [(NB_ROWS*NB_COLS)-1 : 0][3:0] 		  tile_id;	
   logic [(NB_ROWS*NB_COLS)-1 : 0] 			  Stall_Out;
   //for hardware loop by chilanka
   logic [1:0]                      			  jmp_index;
   logic						  jmp_trigger;
   logic [2:0] 				   		  hloopID;
   logic  				                  Inst_Addr_fromHloop;
   logic [(NB_ROWS*NB_COLS)-1 : 0][31:0]		  insCount_Out;
   logic [(NB_ROWS*NB_COLS)-1 : 0][31:0]		  memStallCount_Out;
   logic [(NB_ROWS*NB_COLS)-1 : 0] 			  memStall_Out;
   logic [(NB_ROWS*NB_COLS)-1 : 0][31:0]		  cycleCount_Out;
   genvar 						  i, j;

   
   

/* -----\/----- EXCLUDED -----\/-----
 generate
      for (i = 0; i< NB_ROWS; i++) begin
	 for (j = 0; j< NB_COLS; j++) begin
	    assign tile_id[i*NB_ROWS + j] = i*NB_ROWS + j;
	    
	 end
      end
 endgenerate

 generate
      for (i = 0; i< NB_ROWS; i++) begin
	 for (j = 0; j< NB_COLS; j++) begin
	    assign tile_id[i*NB_ROWS + j] = i*NB_ROWS + j;
	    if (i*NB_ROWS+j < NB_LS) begin
	 end
      end
 endgenerate
 -----/\----- EXCLUDED -----/\----- */
   
/* -----\/----- EXCLUDED -----\/-----
   generate
      for (i = 0; i< NB_ROWS; i++) begin
	 for (j = 0; j< NB_COLS; j++) begin
	    assign tile_id[i*NB_ROWS + j] = i*NB_ROWS + j;
	    if (1) begin
	       
	       tile_ipa #(4, 32, 10, NB_ROWS, NB_COLS, 20)  tile_i (
							      .Clk(Clk),
							      .Reset(Reset),
							      .Load_Store_Grant_I(Load_Store_Grant_I[i*NB_ROWS + j]),
							      .Data_Req_Valid_I(Data_Req_Valid_I[i*NB_ROWS + j]),
							      .Tile_Id(tile_id[i*NB_ROWS + j]),
							      .PE_In_N(PE_Out_S[(NB_ROWS+i-1)%NB_ROWS][j]),
							      .PE_In_S(PE_Out_N[(i+1)%NB_ROWS][j]),
							      .PE_In_E(PE_Out_W[i][(j+1)%NB_COLS]),
							      .PE_In_W(PE_Out_E[i][(NB_COLS+j-1)%NB_COLS]),
							      .PE_Out_N(PE_Out_N[i][j]),
							      .PE_Out_S(PE_Out_S[i][j]),
							      .PE_Out_E(PE_Out_E[i][j]),
							      .PE_Out_W(PE_Out_W[i][j]),
							      .PE_Cond_Out(PE_Cond_Out[i*NB_ROWS + j]),
							      .PE_Cond_In(PE_Cond_Out),	
							      .DMA_Read_En(DMA_Read_En),
							      .DMA_Data_In(DMA_Data_In),
							      .DMA_Addr_In(DMA_Addr_In),
							      .Exec_En_Global(Exec_En),
							      .Load_Data_I (Load_Data_I[i*NB_ROWS + j]),
							      .Store_Data_O(Store_Data_O[i*NB_ROWS + j]),
							      .Load_Store_Addr_O(Load_Store_Addr_O[i*NB_ROWS + j]),
							      .Load_Store_Req_O(Load_Store_Req_O[i*NB_ROWS + j]),
							      .Load_Store_Data_Req_O(Load_Store_Data_Req_O[i*NB_ROWS + j]),
							      .End_Exec_O(End_Exec_O[i*NB_ROWS + j]),
							      .Stall_In(Stall_Out),
							      .Stall_Out(Stall_Out[i*NB_ROWS + j])
							      );
	    end else begin // if (i*NB_ROWS < NB_LS)
	       
	       tile_ipa #(4, 32, 10, NB_ROWS, NB_COLS, 20)  tile_i (
							      .Clk(Clk),
							      .Reset(Reset),
							      .Tile_Id(tile_id[i*NB_ROWS + j]),
							      .PE_In_N(PE_Out_S[(NB_ROWS+i-1)%NB_ROWS][j]),
							      .PE_In_S(PE_Out_N[(i+1)%NB_ROWS][j]),
							      .PE_In_E(PE_Out_W[i][(j+1)%NB_COLS]),
							      .PE_In_W(PE_Out_E[i][(NB_COLS+j-1)%NB_COLS]),
							      .PE_Out_N(PE_Out_N[i][j]),
							      .PE_Out_S(PE_Out_S[i][j]),
							      .PE_Out_E(PE_Out_E[i][j]),
							      .PE_Out_W(PE_Out_W[i][j]),
							      .PE_Cond_Out(PE_Cond_Out[i*NB_ROWS + j]),
							      .PE_Cond_In(PE_Cond_Out),	
							      .DMA_Read_En(DMA_Read_En),
							      .DMA_Data_In(DMA_Data_In),
							      .DMA_Addr_In(DMA_Addr_In),
							      .Exec_En_Global(Exec_En),
							      .Load_Data_I ('0),
							      .Store_Data_O(),
							      .Load_Store_Addr_O(),
							      .Load_Store_Req_O(),
							      .Load_Store_Data_Req_O(),
							      .End_Exec_O(End_Exec_O[i*NB_ROWS + j]),
							      .Stall_In(Stall_Out),
							      .Stall_Out(Stall_Out[i*NB_ROWS + j])
							      );
	    end // else: !if(i*NB_ROWS < NB_LS)
	    
            
	 end // for (j = 0; j< NB_COLS; j++)
      end // for (i = 0; i< NB_ROWS; i++)
   endgenerate   
 -----/\----- EXCLUDED -----/\----- */

 generate
      for (i = 0; i< NB_ROWS; i++) begin
	 for (j = 0; j< NB_COLS; j++) begin
	   //assign tile_id[i*4 + j] = i*4 + j;//commented on 18/11/2022
           assign tile_id[i*NB_COLS + j] = i*NB_COLS + j;
	   if (1) begin
   		if ((i==0 && j==0)) begin
			tile_ipa #(4, 32, 10, NB_ROWS, NB_COLS, 21)  tile_i_MDS ( //changed on 07/12/2022
 			//tile2_ipa #(4, 32, 10, NB_ROWS, NB_COLS, 21)  tile_i_MDS (
								      .Clk(Clk),
								      .Reset(Reset),
								      .Load_Store_Grant_I(Load_Store_Grant_I[i*NB_COLS + j]),
								      .Data_Req_Valid_I(Data_Req_Valid_I[i*NB_COLS + j]),
								      .Tile_Id(tile_id[i*NB_COLS + j]),
								      .PE_In_N(PE_Out_S[(NB_ROWS+i-1)%NB_ROWS][j]),
								      .PE_In_S(PE_Out_N[(i+1)%NB_ROWS][j]),
								      .PE_In_E(PE_Out_W[i][(j+1)%NB_COLS]),
								      .PE_In_W(PE_Out_E[i][(NB_COLS+j-1)%NB_COLS]),
								      .PE_Out_N(PE_Out_N[i][j]),
								      .PE_Out_S(PE_Out_S[i][j]),
								      .PE_Out_E(PE_Out_E[i][j]),
								      .PE_Out_W(PE_Out_W[i][j]),
								      .PE_Cond_Out(PE_Cond_Out[i*NB_COLS + j]),
								      .PE_Cond_In(PE_Cond_Out),	
								      .DMA_Read_En(DMA_Read_En),
								      .DMA_Data_In(DMA_Data_In),
								      .DMA_Addr_In(DMA_Addr_In),
								      .Exec_En_Global(Exec_En),
								      .Load_Data_I (Load_Data_I[i*NB_COLS + j]),
								      .Store_Data_O(Store_Data_O[i*NB_COLS + j]),
								      .Load_Store_Addr_O(Load_Store_Addr_O[i*NB_COLS + j]),
								      .Load_Store_Req_O(Load_Store_Req_O[i*NB_COLS + j]),
								      .Load_Store_Data_Req_O(Load_Store_Data_Req_O[i*NB_COLS + j]),
								      .End_Exec_O(End_Exec_O[i*NB_COLS + j]),
								      .Stall_In(Stall_Out),
								      .Stall_Out(Stall_Out[i*NB_COLS + j]),
								      .memStall_In(memStall_Out),
								      .memStall_Out(memStall_Out[i*NB_COLS + j]),
								      .memStallCount_Out(memStallCount_Out[i*NB_COLS + j]),
								      .insCount_Out(insCount_Out[i*NB_COLS + j]),
								      .cycleCount_Out(cycleCount_Out[i*NB_COLS + j])
								    
								      );
	               //commented on 18/11/2022      
    			/*   tilemaster_ipa #(4, 32, 10, NB_ROWS, NB_COLS, 21)  tile_i_MDS (
								      .Clk(Clk),
								      .Reset(Reset),
								      .Load_Store_Grant_I(Load_Store_Grant_I[i*4 + j]),
								      .Data_Req_Valid_I(Data_Req_Valid_I[i*4 + j]),
								      .Tile_Id(tile_id[i*4 + j]),
								      .PE_In_N(PE_Out_S[(NB_ROWS+i-1)%NB_ROWS][j]),
								      .PE_In_S(PE_Out_N[(i+1)%NB_ROWS][j]),
								      .PE_In_E(PE_Out_W[i][(j+1)%NB_COLS]),
								      .PE_In_W(PE_Out_E[i][(NB_COLS+j-1)%NB_COLS]),
								      .PE_Out_N(PE_Out_N[i][j]),
								      .PE_Out_S(PE_Out_S[i][j]),
								      .PE_Out_E(PE_Out_E[i][j]),
								      .PE_Out_W(PE_Out_W[i][j]),
								      .PE_Cond_Out(PE_Cond_Out[i*4 + j]),
								      .PE_Cond_In(PE_Cond_Out),	
								      .DMA_Read_En(DMA_Read_En),
								      .DMA_Data_In(DMA_Data_In),
								      .DMA_Addr_In(DMA_Addr_In),
								      .Exec_En_Global(Exec_En),
								      .Load_Data_I (Load_Data_I[i*4 + j]),
								      .Store_Data_O(Store_Data_O[i*4 + j]),
								      .Load_Store_Addr_O(Load_Store_Addr_O[i*4 + j]),
								      .Load_Store_Req_O(Load_Store_Req_O[i*4 + j]),
								      .Load_Store_Data_Req_O(Load_Store_Data_Req_O[i*4 + j]),
								      .End_Exec_O(End_Exec_O[i*4 + j]),
								      .Stall_In(Stall_Out),
								      .Stall_Out(Stall_Out[i*4 + j]),
   								      .jmp_trigger_O(jmp_trigger),
   								      .jmp_index_O(jmp_index),
   								      .hloopID_O(hloopID),
   								      .Inst_Addr_fromHloop_O(Inst_Addr_fromHloop)
								      );*/
	       
	        // end else if ((i==0 && j==1)||(i==0 && j==2)) begin
                end else  begin
		 	tile_ipa #(4, 32, 10, NB_ROWS, NB_COLS, 21)  tile_i_DS (
								      .Clk(Clk),
								      .Reset(Reset),
								      .Load_Store_Grant_I(Load_Store_Grant_I[i*NB_COLS + j]),
								      .Data_Req_Valid_I(Data_Req_Valid_I[i*NB_COLS + j]),
								      .Tile_Id(tile_id[i*NB_COLS + j]),
								      .PE_In_N(PE_Out_S[(NB_ROWS+i-1)%NB_ROWS][j]),
								      .PE_In_S(PE_Out_N[(i+1)%NB_ROWS][j]),
								      .PE_In_E(PE_Out_W[i][(j+1)%NB_COLS]),
								      .PE_In_W(PE_Out_E[i][(NB_COLS+j-1)%NB_COLS]),
								      .PE_Out_N(PE_Out_N[i][j]),
								      .PE_Out_S(PE_Out_S[i][j]),
								      .PE_Out_E(PE_Out_E[i][j]),
								      .PE_Out_W(PE_Out_W[i][j]),
								      .PE_Cond_Out(PE_Cond_Out[i*NB_COLS + j]),
								      .PE_Cond_In(PE_Cond_Out),	
								      .DMA_Read_En(DMA_Read_En),
								      .DMA_Data_In(DMA_Data_In),
								      .DMA_Addr_In(DMA_Addr_In),
								      .Exec_En_Global(Exec_En),
								      .Load_Data_I (Load_Data_I[i*NB_COLS + j]),
								      .Store_Data_O(Store_Data_O[i*NB_COLS + j]),
								      .Load_Store_Addr_O(Load_Store_Addr_O[i*NB_COLS + j]),
								      .Load_Store_Req_O(Load_Store_Req_O[i*NB_COLS + j]),
								      .Load_Store_Data_Req_O(Load_Store_Data_Req_O[i*NB_COLS + j]),
								      .End_Exec_O(End_Exec_O[i*NB_COLS + j]),
								      .Stall_In(Stall_Out),
								      .Stall_Out(Stall_Out[i*NB_COLS + j]),
								      .memStall_In(memStall_Out),
								      .memStall_Out(memStall_Out[i*NB_COLS + j]),
								      .memStallCount_Out(memStallCount_Out[i*NB_COLS + j]),
								      .insCount_Out(insCount_Out[i*NB_COLS + j]),
								      .cycleCount_Out(cycleCount_Out[i*NB_COLS + j])
								      );
			//commented on 18/11/2022
		      /* tile_ipa #(4, 32, 10, NB_ROWS, NB_COLS, 21)  tile_i_DS (
								      .Clk(Clk),
								      .Reset(Reset),
								      .Load_Store_Grant_I(Load_Store_Grant_I[i*4 + j]),
								      .Data_Req_Valid_I(Data_Req_Valid_I[i*4 + j]),
								      .Tile_Id(tile_id[i*4 + j]),
								      .PE_In_N(PE_Out_S[(NB_ROWS+i-1)%NB_ROWS][j]),
								      .PE_In_S(PE_Out_N[(i+1)%NB_ROWS][j]),
								      .PE_In_E(PE_Out_W[i][(j+1)%NB_COLS]),
								      .PE_In_W(PE_Out_E[i][(NB_COLS+j-1)%NB_COLS]),
								      .PE_Out_N(PE_Out_N[i][j]),
								      .PE_Out_S(PE_Out_S[i][j]),
								      .PE_Out_E(PE_Out_E[i][j]),
								      .PE_Out_W(PE_Out_W[i][j]),
								      .PE_Cond_Out(PE_Cond_Out[i*4 + j]),
								      .PE_Cond_In(PE_Cond_Out),	
								      .DMA_Read_En(DMA_Read_En),
								      .DMA_Data_In(DMA_Data_In),
								      .DMA_Addr_In(DMA_Addr_In),
								      .Exec_En_Global(Exec_En),
								      .Load_Data_I (Load_Data_I[i*4 + j]),
								      .Store_Data_O(Store_Data_O[i*4 + j]),
								      .Load_Store_Addr_O(Load_Store_Addr_O[i*4 + j]),
								      .Load_Store_Req_O(Load_Store_Req_O[i*4 + j]),
								      .Load_Store_Data_Req_O(Load_Store_Data_Req_O[i*4 + j]),
								      .End_Exec_O(End_Exec_O[i*4 + j]),
								      .Stall_In(Stall_Out),
								      .Stall_Out(Stall_Out[i*4 + j]),
   								      .jmp_trigger_I(jmp_trigger),
   								      .jmp_index_I(jmp_index),
   								      .hloopID_I(hloopID),
   								      .Inst_Addr_fromHloop_I(Inst_Addr_fromHloop)
								      );*/
		end   /* else begin
		       tile_ipa #(4, 32, 10, NB_ROWS, NB_COLS, 21)  tile_i (
								      .Clk(Clk),
								      .Reset(Reset),
								      .Load_Store_Grant_I(Load_Store_Grant_I[i*4 + j]),
								      .Data_Req_Valid_I(Data_Req_Valid_I[i*4 + j]),
								      .Tile_Id(tile_id[i*4 + j]),
								      .PE_In_N(PE_Out_S[(NB_ROWS+i-1)%NB_ROWS][j]),
								      .PE_In_S(PE_Out_N[(i+1)%NB_ROWS][j]),
								      .PE_In_E(PE_Out_W[i][(j+1)%NB_COLS]),
								      .PE_In_W(PE_Out_E[i][(NB_COLS+j-1)%NB_COLS]),
								      .PE_Out_N(PE_Out_N[i][j]),
								      .PE_Out_S(PE_Out_S[i][j]),
								      .PE_Out_E(PE_Out_E[i][j]),
								      .PE_Out_W(PE_Out_W[i][j]),
								      .PE_Cond_Out(PE_Cond_Out[i*4 + j]),
								      .PE_Cond_In(PE_Cond_Out),	
								      .DMA_Read_En(DMA_Read_En),
								      .DMA_Data_In(DMA_Data_In),
								      .DMA_Addr_In(DMA_Addr_In),
								      .Exec_En_Global(Exec_En),
								      .Load_Data_I (Load_Data_I[i*4 + j]),
								      .Store_Data_O(Store_Data_O[i*4 + j]),
								      .Load_Store_Addr_O(Load_Store_Addr_O[i*4 + j]),
								      .Load_Store_Req_O(Load_Store_Req_O[i*4 + j]),
								      .Load_Store_Data_Req_O(Load_Store_Data_Req_O[i*4 + j]),
								      .End_Exec_O(End_Exec_O[i*4 + j]),
								      .Stall_In(Stall_Out),
								      .Stall_Out(Stall_Out[i*4 + j]),
   								      .jmp_trigger_I(jmp_trigger),
   								      .jmp_index_I(jmp_index),
   								      .hloopID_I(hloopID),
   								      .Inst_Addr_fromHloop_I(Inst_Addr_fromHloop)
								      );
		    end*/

	    end else begin // if (i*NB_ROWS < NB_LS)	       
	       	tile_ipa #(4, 32, 10, NB_ROWS, NB_COLS, 21)  tile_i (
							      .Clk(Clk),
							      .Reset(Reset),
							      .Tile_Id(tile_id[i*NB_COLS + j]),
							      .PE_In_N(PE_Out_S[(NB_ROWS+i-1)%NB_ROWS][j]),
							      .PE_In_S(PE_Out_N[(i+1)%NB_ROWS][j]),
							      .PE_In_E(PE_Out_W[i][(j+1)%NB_COLS]),
							      .PE_In_W(PE_Out_E[i][(NB_COLS+j-1)%NB_COLS]),
							      .PE_Out_N(PE_Out_N[i][j]),
							      .PE_Out_S(PE_Out_S[i][j]),
							      .PE_Out_E(PE_Out_E[i][j]),
							      .PE_Out_W(PE_Out_W[i][j]),
							      .PE_Cond_Out(PE_Cond_Out[i*NB_COLS + j]),
							      .PE_Cond_In(PE_Cond_Out),	
							      .DMA_Read_En(DMA_Read_En),
							      .DMA_Data_In(DMA_Data_In),
							      .DMA_Addr_In(DMA_Addr_In),
							      .Exec_En_Global(Exec_En),
							      .Load_Data_I ('0),
							      .Store_Data_O(),
							      .Load_Store_Addr_O(),
							      .Load_Store_Req_O(),
							      .Load_Store_Data_Req_O(),
							      .End_Exec_O(End_Exec_O[i*NB_COLS + j]),
							      .Stall_In(Stall_Out),
							      .Stall_Out(Stall_Out[i*NB_COLS + j])
							      );
	    end // else: !if(i*NB_ROWS < NB_LS)
	    
            
	 end // for (j = 0; j< NB_COLS; j++)
      end // for (i = 0; i< NB_ROWS; i++)
   endgenerate   

   
endmodule // cgra
