////////////////////////////////////////////////////////////////////////////////
// Company:        Lab-STICC @ Université Bretagne Sud					      //
//                 27 rue Armand Guillemot BP 92116,56321                     //
//                 LORIENT Cedex - Tél. 02 97 87 66 66 -                      //
//                                                                            //
// Engineer:       Rohit Prasad - rohit.prasad@univ-ubs.fr                    //
//																			  //
//													                          //
// Additional contributions by:                                               //
//                                                                            //
//                                                                            //
//                                                                            //
// Create Date:    14/11/2018                                                 //
// Design Name:    Address Generation Unit 		 	                          //
// Module Name:    agu                                                        //
// Project Name:                                                              //
// Language:       SystemVerilog                                              //
//                                                                            //
// Description:    						 						  			  //
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

module agu
	( //INPUT
		input logic [10:0] 	index_0, // i_START a[i][j]
		input logic [10:0] 	index_1, // j_START a[i][j]		
		input logic [19:0] 	base_adr, // base address

	//OUTPUT
		output logic [31:0]	address
	);

	always_comb
	begin
		address = (((index_0 + index_1)<<2) + base_adr);
	end
endmodule // agu
