module UART_TX
  (
   input        i_Clock,
   input        rst,
   input		    eps,
   input		    pen,
   input        i_start_transmission,
   input [7:0]  i_Tx_Byte,
   output       o_Tx_Busy,
   output reg   o_Tx_Serial,
   output       o_Tx_Done
   );
  
  parameter IDLE        = 3'b000;
  parameter START_BIT 	= 3'b001;
  parameter DATA_BITS 	= 3'b010;
  parameter PARITY_BIT  = 3'b011;
  parameter STOP_BIT  	= 3'b100;

  
  reg [2:0]     state     = IDLE;
  reg [2:0]     r_Bit_Index   = 0;
  reg [7:0]     r_Tx_Byte = 0;
  reg           r_Tx_Done     = 0;
  reg           r_Tx_Busy   = 0;
  reg 			    parity_bit;
     

  always @(posedge rst) begin
     if (rst == 1) begin
       state <= IDLE;
       r_Bit_Index <= 0;
       r_Tx_Done <= 0;
       r_Tx_Busy <= 0;
       o_Tx_Serial   <= 1'b1;
  end
end
     
  always @(posedge i_Clock)
    begin
    
      case (state)
        IDLE :
          begin
            o_Tx_Serial   <= 1'b1;
            r_Tx_Done     <= 1'b0;
            r_Bit_Index   <= 0;
            
            if (i_start_transmission == 1'b1)
              begin
                r_Tx_Busy <= 1'b1;
                state <= START_BIT;
              end
            else
              state <= IDLE;
          end
        
        START_BIT :
          begin
            o_Tx_Serial <= 1'b0;
            r_Tx_Done <= 1'b0;
			      r_Tx_Byte <= i_Tx_Byte;
            state <= DATA_BITS;
          end
          
        DATA_BITS :
          begin
            o_Tx_Serial <= r_Tx_Byte[r_Bit_Index];
             
            if (r_Bit_Index < 7)
              begin
                r_Bit_Index <= r_Bit_Index + 1;
              end
            else
              begin
				        if(pen == 1)begin
			            parity_bit <= (^i_Tx_Byte) ^ ~eps;
				        	state   <= PARITY_BIT;
				        end
				        else begin
				          r_Tx_Busy <= 1'b0;	
				        	state   <= STOP_BIT;
				        end
              end
          end
         
        PARITY_BIT:
			    begin
			      o_Tx_Serial <= parity_bit;
			      r_Tx_Busy <= 1'b0;
			      state   <= STOP_BIT;
			  end
		 
		 
        STOP_BIT :
          begin
            o_Tx_Serial <= 1'b1;
				    r_Tx_Done <= 1'b1;   
            if (i_start_transmission == 1'b1)
              begin
                r_Tx_Busy <= 1'b1;
                r_Bit_Index   <= 0;
                state <= START_BIT;
              end
            else
              state <= IDLE;
          end
         
        default :
          state <= IDLE;
         
      endcase
    end
 
  assign o_Tx_Busy = r_Tx_Busy;
  assign o_Tx_Done = r_Tx_Done;
   
endmodule


module TX_tb();

 

   reg        clk;
   reg        rst;
   reg              eps;
   reg              pen;
   reg        i_start_transmission;
   reg [7:0]  i_Tx_Byte;
   wire       o_Tx_Busy;
   wire       o_Tx_Serial;
   wire       o_Tx_Done;


  always
    begin
    #10
    clk = ~clk;
    end

 

  initial 
  begin
  i_Tx_Byte = 8'b01001010; eps = 0; pen = 0; clk = 0; rst =0; i_start_transmission = 1; #30; i_start_transmission = 0; #300

  @(posedge clk)
  i_Tx_Byte = 8'b10101110; eps = 0; pen = 1; i_start_transmission = 1; #30; i_start_transmission = 0; #300

  @(posedge clk)
  i_Tx_Byte = 8'b11111111; eps = 1; pen = 1; i_start_transmission = 1;#30; i_start_transmission = 0; #300

   $stop;
  end

UART_TX tx
  (
      clk,
      rst,
         eps,
      pen,
      i_start_transmission,
      i_Tx_Byte,
      o_Tx_Busy,
      o_Tx_Serial,
      o_Tx_Done
   );

endmodule
