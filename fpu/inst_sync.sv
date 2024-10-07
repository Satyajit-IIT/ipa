////////////////////////////////////////////////////////////////////////////////
// Company:        Lab-STICC @ Université Bretagne Sud
//                 27 rue Armand Guillemot BP 92116,56321
//                 LORIENT Cedex - Tél. 02 97 87 66 66 -
//
// Engineer:       Rohit Prasad - rohit.prasad@univ-ubs.fr
//
//
// Additional contributions by:
//
//
//
// Create Date:    05/03/2019
// Design Name:    Instruction Synchronizer
// Module Name:    inst_sync
// Project Name:
// Language:       SystemVerilog
//
// Description:
//
//
// Revision:
// Revision v0.1 - File Created
//
//
////////////////////////////////////////////////////////////////////////////////

module inst_sync
  ( //INPUT
  	input logic 		    Clk,
  	input logic 		    Reset,
  	input logic [5:0] 	opcode,
    input logic         LSreq,
  	//OUTPUT
    output logic        inst_fetch_en,
    output logic        alu_data_fetch_en,
    output logic        sfu_data_fetch_en,
    output logic        DS_data_fetch_en,

    output logic        sfu_en,
    output logic        DS_en
    );

  localparam CYCLE2 = 2;
  localparam CYCLE5 = 5;

  logic [2:0]   count;
  logic [2:0]   count_i;
  logic         C2;
  logic         C5;

  enum      `ifdef SYNTHESIS logic [2:0] `endif {FETCH, ALU, SFU, DS} CS, NS;

  always_ff @(posedge Clk or negedge Reset)
  begin
  	if (Reset == 1'b0)
  	begin
  		CS <= FETCH;
      count_i <= 3'b0;
  	end
  	else
  	begin
      if (!LSreq) 
      begin
        count_i <= count;
    		CS <= NS;
      end
    end
  end


  always_comb
  begin
    
  	case(CS)

//////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////
  		FETCH:
  		begin
        C2 = 1'b0;
        C5 = 1'b0;
        count = 3'b0;
        sfu_en = 1'b0;
        DS_en = 1'b0;

  			if ((opcode[5]==1'b1))
  			begin
          inst_fetch_en = 1'b0;
          sfu_data_fetch_en = 1'b0;
          DS_data_fetch_en = 1'b0;
  				if ((opcode == 6'h24)||(opcode == 6'h25))
          begin
            NS = DS;
          end else
          begin
            NS = SFU;
          end
  			end else begin
          inst_fetch_en = 1'b1;
          alu_data_fetch_en = 1'b1;
          NS = ALU;
        end
  		end
//////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////
  		ALU:
  		begin        
        inst_fetch_en = 1'b1;
        alu_data_fetch_en = 1'b1;
        sfu_data_fetch_en = 1'b0;
        DS_data_fetch_en = 1'b0;
        sfu_en = 1'b0;
        DS_en = 1'b0;

  			if (opcode[5]==1'b1)
        begin
          if ((opcode == 6'h24)||(opcode == 6'h25))
          begin
            NS = DS;
          end else
          begin
            NS = SFU;
          end
        end else begin          
          NS = ALU;
        end    
  		end
//////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////
      SFU:
      begin

        if (((opcode == 6'h21)||(opcode == 6'h22)||(opcode == 6'h23)||(opcode == 6'h2B)||(opcode == 6'h2C)||(opcode == 6'h2D))) // 2 cycle ops
        begin
          C2 = 1'b1;
          count = 3'b0;
          inst_fetch_en = 1'b0;
          sfu_en = 1'b1;
          DS_en = 1'b0;              

        end else if (((opcode == 6'h27)||(opcode == 6'h2A))) // 1 cycle ops
        begin
          count = 3'b0;
          inst_fetch_en = 1'b1;
          sfu_en = 1'b0;
          DS_en = 1'b0;
        end

        if (C2 == 1'b1) begin
          count = count_i+1;

          if(count_i == CYCLE2-1)
          begin
            count = 3'b0;
            inst_fetch_en = 1'b1;
            alu_data_fetch_en = 1'b0;
            sfu_data_fetch_en = 1'b1;
            DS_data_fetch_en = 1'b0;
            sfu_en = 1'b0;
            DS_en = 1'b0;
            
            if (opcode[5]==1'b1)
            begin
              if ((opcode == 6'h24)||(opcode == 6'h25))
              begin
                NS = DS;
              end else
              begin
                NS = SFU;
              end
            end else begin          
              NS = ALU;
            end 
          end
        end

      end
//////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////
      DS:
      begin
        
        if (((opcode == 6'h24)||(opcode == 6'h25))) // 5 cycle ops
        begin
          C5 = 1'b1;
          count = 3'b0;
          inst_fetch_en = 1'b0;
          sfu_en = 1'b0;
          DS_en = 1'b1;
        end

        if (C5 == 1'b1) begin
          count = count_i+1;          

          if(count_i == CYCLE5-1)
          begin
            count = 3'b0;
            inst_fetch_en = 1'b1;
            alu_data_fetch_en = 1'b0;
            sfu_data_fetch_en = 1'b0;
            DS_data_fetch_en = 1'b1;
            sfu_en = 1'b0;
            DS_en = 1'b0;
            
            if (opcode[5]==1'b1)
            begin
              if ((opcode == 6'h24)||(opcode == 6'h25))
              begin
                NS = DS;
              end else
              begin
                NS = SFU;
              end
            end else begin          
              NS = ALU;
            end 
          end
        end

      end  
//////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////
  		default:
  		begin
        C2 = 1'b0;
        C5 = 1'b0;
        count = 3'b0;
        sfu_en = 1'b0;
        DS_en = 1'b0;

        if ((opcode[5]==1'b1))
        begin
          inst_fetch_en = 1'b0;
          sfu_data_fetch_en = 1'b0;
          DS_data_fetch_en = 1'b0;
          if ((opcode == 6'h24)||(opcode == 6'h25))
          begin
            NS = DS;
          end else
          begin
            NS = SFU;
          end
        end else begin
          inst_fetch_en = 1'b1;
          alu_data_fetch_en = 1'b1;
          NS = ALU;
        end
  		end
	endcase // case (CS)
end
endmodule // inst_sync
