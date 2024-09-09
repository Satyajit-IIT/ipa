////////////////////////////////////////////////////////////////////////////////
// Company:        LAVA							      //
//                 IIT Palakkad                             		      //
//                  					                      //
//                                                                            //
// Engineer:       Chilankamol Sunny - 112004004@smail.iitpkd.ac.in           //
//                                                                            //
// Additional contributions by:                                               //
//                                                                            //
//                                                                            //
//                                                                            //
// Create Date:    2020                                                       // 
// Design Name:    CGRA                                                       // 
// Module Name:    Hardware Loop                                              //
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
module ins_ag (
  input logic         Clk,Reset,Global_Cond,Global_Stall,Clock_Gate_En_O,exec,inst_fetch_en,
  input logic [5:0]   Inst_Addr_In,
  input logic [20:0]  Inst_Data_In,
  input logic [2:0]   loopID_In, 
  output logic [2:0]  loopID_Out,
  output logic [5:0]  Inst_Addr_Out, 
  output logic        jmp_trigger,
  output logic        jmp_init,
  output logic [4:0]  jmp_index
);
  logic [5:0] Inst_Addr_FromHloop;
  logic [2:0] loopID_Out_FromHloop;

  always_ff @(posedge Clk or negedge Reset)
  begin
	if(Reset == 1'b0) begin
		Inst_Addr_Out <= '0;
		loopID_Out<='0;		
	end
	else if ((exec ==1'b1) && (Clock_Gate_En_O == '1)&& (Global_Stall != '1)&&(inst_fetch_en)) begin
     			Inst_Addr_Out <= (Inst_Data_In[5:0]==6'b011110) ? '0 : 
                        ((Inst_Data_In[5:0]==6'b010100)||((Inst_Data_In[5:0]==6'b010011) && (Global_Cond==1'b1))) ? Inst_Data_In[11:6] :                        
                        ((Inst_Data_In[5:0]==6'b010011) && (Global_Cond==1'b0)) ? Inst_Data_In[17:12] :
 			((Inst_Data_In[5:0]==6'b010110)||(Inst_Data_In[5:0]==6'b010111)) ? Inst_Addr_In+1: Inst_Addr_FromHloop;		
			loopID_Out<=loopID_Out_FromHloop;
	end
  end
  hloop HLOOP(
            .clk(Clk),
            .reset(Reset),                
            .Global_Cond(Global_Cond), 
	    .Global_Stall(Global_Stall), 
	    .Clock_Gate_En_O(Clock_Gate_En_O), 
	    .Inst_Addr_In(Inst_Addr_In),
	    .Inst_Data_In(Inst_Data_In),           
            .loopID_In(loopID_In),
            .Inst_Addr_Out(Inst_Addr_FromHloop),
            .loopID_Out(loopID_Out_FromHloop) ,
            .jmp_trigger(jmp_trigger),
            .jmp_init(jmp_init),
            .jmp_index(jmp_index)          
  );
endmodule


module hloop (
  input logic clk,reset,Global_Cond,Global_Stall,Clock_Gate_En_O,
  input logic [5:0] Inst_Addr_In,
  input logic [20:0] Inst_Data_In, 
  input logic [2:0]loopID_In, 
  output logic [5:0] Inst_Addr_Out,
  output logic [2:0]loopID_Out,
  output logic jmp_trigger,
  output logic jmp_init,
  output logic [4:0] jmp_index
);

  logic [2:0] loopID;
  logic loopInit_HIGH,loopCnt_HIGH,lvalFlag_in;
  logic [5 : 0] ls_in;
  logic [5 : 0] le_in;
  logic [11 : 0] lc_in;
  logic [1:0]lvalAddMSB_in;
  logic [2:0]lvalAddLSB_in;
 
  typedef struct {
  logic [5 : 0] ls;
  logic [5 : 0] le;
  logic [11 : 0] lc;
  logic lvalf;
  logic [4:0] lvalAdd;
  }loopreg;
  loopreg RF1 [4];

  assign loopID=loopID_In; 
 
  //Next Inst Address
  always @(*) begin
  	if ( (Inst_Addr_In == RF1[loopID_In-1].le) && (RF1[loopID_In-1].lc  > 0)) begin
		Inst_Addr_Out = RF1[loopID_In-1].ls; 
        end
	else begin			
		if ( (loopID_In > 1) && (Inst_Addr_In == RF1[loopID_In-2].le) && (RF1[loopID_In-2].lc  > 0)) begin
			Inst_Addr_Out = RF1[loopID_In-2].ls; 
        	end
		else begin			
			if ( (loopID_In > 2) && (Inst_Addr_In == RF1[loopID_In-3].le) && (RF1[loopID_In-3].lc  > 0)) begin
				Inst_Addr_Out = RF1[loopID_In-3].ls; 
        		end
			else begin			
				if ( (loopID_In > 3) && (Inst_Addr_In == RF1[loopID_In-4].le) && (RF1[loopID_In-4].lc  > 0)) begin
					Inst_Addr_Out = RF1[loopID_In-4].ls; 
        			end
				else Inst_Addr_Out =Inst_Addr_In+1;		
			end
		end
	end
  end

  //Next LoopID
  always @(*) begin   
      if( (Global_Stall != '1) && (Clock_Gate_En_O == '1))   begin 
  	if ((Inst_Data_In[5:0] == 6'b010111) ) begin // LOOP_CNT 
		loopID_Out = loopID_In+1;
        end
	else if ( Inst_Addr_In == RF1[loopID_In-1].le && RF1[loopID_In-1].lc  == 0) begin
		if ( (loopID_In > 1) && ( Inst_Addr_In == RF1[loopID_In-2].le) && (RF1[loopID_In-2].lc  == 0)) begin
                      	
			if ( (loopID_In > 2) && ( Inst_Addr_In == RF1[loopID_In-3].le) && (RF1[loopID_In-3].lc  == 0)) begin                      		
				if ( (loopID_In > 3) && ( Inst_Addr_In == RF1[loopID_In-4].le) && (RF1[loopID_In-4].lc  == 0)) begin
                      			loopID_Out = loopID_In-4;
				end
				else loopID_Out = loopID_In-3; 
			end
                        else loopID_Out = loopID_In-2; 
		end
		else loopID_Out = loopID_In-1; 
	end
	else loopID_Out=loopID_In;
      end else loopID_Out=loopID_In;
  end
 
  //Next lc; New ls, lc, lc
  always_ff @(posedge clk or negedge reset) begin
    if(reset == 1'b0) begin
		jmp_trigger <= '1;
		jmp_init <= '1;
		jmp_index<='0;	
                RF1[0].ls<='0;RF1[0].le<='0;RF1[0].lc<='0;RF1[0].lvalf<='0;RF1[0].lvalAdd<='0;
                RF1[1].ls<='0;RF1[1].le<='0;RF1[1].lc<='0;RF1[1].lvalf<='0;RF1[1].lvalAdd<='0;
                RF1[2].ls<='0;RF1[2].le<='0;RF1[2].lc<='0;RF1[2].lvalf<='0;RF1[2].lvalAdd<='0;
                RF1[3].ls<='0;RF1[3].le<='0;RF1[3].lc<='0;RF1[3].lvalf<='0;RF1[3].lvalAdd<='0;
   end
   else begin
    jmp_trigger<=1'b1;
    jmp_init<=1'b1;
    if( (Global_Stall != '1) && (Clock_Gate_En_O == '1))   begin            
	    if ((Inst_Data_In[5:0] == 6'b010110)) begin // LOOP_INIT	
            	RF1[loopID_In ].ls <= Inst_Data_In[11:6]; //loop start ins address
            	RF1[loopID_In ].le <= Inst_Data_In[17:12]; //loop end ins address  			
            	RF1[loopID_In ].lvalf <= Inst_Data_In[20]; //loop val update or not flag
            	RF1[loopID_In ].lvalAdd[4:3]<=Inst_Data_In[19:18]; //2 MSB of 5-bit loop val CRF address
                lvalAddMSB_in<=Inst_Data_In[19:18];
	    end
	    else if ((Inst_Data_In[5:0] == 6'b010111)) begin // LOOP_CNT         	
	        RF1[loopID_In ].lc <=  Inst_Data_In[17:6]-1; //loop iteration count
            	RF1[loopID_In ].lvalAdd[2:0]<= Inst_Data_In[20:18]; //3 LSB of 5-bit loop val CRF address
		jmp_trigger<=1'b0;
		jmp_init<=1'b0;
		jmp_index<={lvalAddMSB_in,Inst_Data_In[20:18]};
	   end
           else begin
                      
			//if PC == Loop End                         
          		if ( Inst_Addr_In == RF1[loopID_In-1].le ) begin			
				//decrement Loop Count
            			RF1[loopID_In-1].lc <= RF1[loopID_In-1].lc - 1;
                                //set to update the loop val in CRF if the flag is set
                                if(RF1[loopID_In-1].lvalf == 1) begin                                  
                                          jmp_trigger<=1'b0;
                                          jmp_index<=RF1[loopID_In-1].lvalAdd;
                                end  
            			if (RF1[loopID_In-1].lc  == 0) begin //if loop count =0 					               		  	                           	 
					jmp_init<=1'b0;//added on 07/06/2023
					//checking PC against parent loop end address
              				if ( (loopID_In > 1) && ( Inst_Addr_In == RF1[loopID_In-2].le) ) begin
                      				RF1[loopID_In-2].lc <= RF1[loopID_In-2].lc - 1;
                                 		//set to update the loop val in CRF if the flag is set
                          			if(RF1[loopID_In-2].lvalf == 1) begin                            				
                                                          jmp_trigger<=1'b0;
                                                          jmp_index<=RF1[loopID_In-2].lvalAdd;
                                		 end 
                        			 if (RF1[loopID_In-2].lc  == 0) begin
							jmp_init<=1'b0;//added on 07/06/2023							
							//checking PC against parent loop end address
                      					if ( (loopID_In > 2) && ( Inst_Addr_In == RF1[loopID_In-3].le) ) begin
                        					RF1[loopID_In-3].lc <= RF1[loopID_In-3].lc - 1;
                                       				//set to update the loop val in CRF if the flag is set
                                      				if(RF1[loopID_In-3].lvalf == 1) begin                                        			
                                                                          jmp_trigger<=1'b0;
                                                                          jmp_index<=RF1[loopID_In-3].lvalAdd;
                                      				end 
                            					if (RF1[loopID_In-3].lc  == 0) begin	
									jmp_init<=1'b0;//added on 07/06/2023								
                            						//checking PC against parent loop end address
                        						if ( (loopID_In > 3) && ( Inst_Addr_In == RF1[loopID_In-4].le) ) begin
                              							RF1[loopID_In-4].lc <= RF1[loopID_In-4].lc - 1;
                                                    				//set to update the loop val in CRF if the flag is set
                                                 				if(RF1[loopID_In-4].lvalf == 1) begin                                                   				
                                                                                          jmp_trigger<=1'b0;
                                                                                          jmp_index<=RF1[loopID_In-4].lvalAdd;
											  if (RF1[loopID_In-4].lc  == 0)//added on 07/06/2023	
												jmp_init<=1'b0;
                                                  				end 										
									end
                        					end	//if (RF1[loopID-3].lc  == 0)
                       					end 
						end //  if (RF1[loopID-2].lc  == 0)  
                    			end
                		end //if (RF1[loopID-1].lc  == 0)
            		end   
	end
    end 
   end
  end 
endmodule




