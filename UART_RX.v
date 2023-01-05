module UART_RX (
   input          i_Clock,
   input          rst,
   input          i_Rx_Serial,
   input [4:0]    i_Clks_Per_Bit,
   input          eps,
   input          pen,
   output         o_Rx_Busy,
   output         o_Rx_Done,
   output [7:0]   o_Rx_Byte
   );
    
  parameter IDLE        = 3'b000;
  parameter START_BIT   = 3'b001;
  parameter DATA_BITS   = 3'b010;
  parameter PARITY_BIT  = 3'b011;
  parameter STOP_BIT    = 3'b100;
  
  reg [7:0]     rx_Data_Bits;
  
  reg           r_Byte_Done  = 0;
  reg           r_Rx_Busy     = 0;
  
  reg [7:0]     r_Clock_Count = 0;
  reg [2:0]     r_Bit_Index   = 0; //8 bits total
  reg [2:0]     state         = IDLE;
  
  reg [7:0]     r_Rx_Byte;
  
  reg parity;


  always @(posedge rst) begin
    if (rst == 1) begin
      r_Byte_Done  <= 0;
      r_Rx_Busy    < = 0;
      r_Clock_Count <= 0;
      r_Bit_Index   <= 0;
      state         <= IDLE;
    end
  end
  
  always @(posedge i_Clock)
    begin
       
      case (state)
        IDLE :
          begin
            r_Byte_Done  <= 0;
            r_Clock_Count <= 0;
            r_Bit_Index   <= 0;
             
            if (i_Rx_Serial == 1'b0) begin         // Start bit detected
              state <= START_BIT;
              r_Rx_Busy <= 1;
            end
            else begin
              r_Rx_Busy <= 0;
              state <= IDLE;
            end
          end
         
        START_BIT :
          begin
            if (r_Clock_Count >= (i_Clks_Per_Bit-1)/2)
              begin
                if (i_Rx_Serial == 1'b0) // Ensured start bit arrived
                  begin
                    r_Clock_Count <= 0;  // reset counter at the bit center (sampling time)
                    state     <= DATA_BITS;
                  end
                else begin
                  r_Rx_Busy <= 0;
                  state <= IDLE;
                end
              end
            else
              begin
                r_Clock_Count <= r_Clock_Count + 1;
              end
          end
         
        DATA_BITS :
          begin
            if (r_Clock_Count >= i_Clks_Per_Bit-1)
              begin
                r_Clock_Count <= 0;
                
                rx_Data_Bits[r_Bit_Index] = i_Rx_Serial;

                if (r_Bit_Index < 7)
                  begin
                    r_Bit_Index <= r_Bit_Index + 1;
                  end
                else
                  begin
                    r_Bit_Index <= 0;
                    if (pen == 1) begin
                      parity <= (^rx_Data_Bits)^~eps;
                      state <= PARITY_BIT;
                    end
                    else state   <= STOP_BIT;
                  end
              end
            else
              begin
                r_Clock_Count <= r_Clock_Count + 1;
              end
          end

        PARITY_BIT :
          begin
            if (r_Clock_Count >= i_Clks_Per_Bit-1)
              begin
                if (i_Rx_Serial == parity) begin
                  state <= STOP_BIT;
                  r_Clock_Count <= 0;
                end
                else begin
                  state <= IDLE;
                  r_Rx_Busy <= 0;
                end
              end
            else
              begin
                r_Clock_Count <= r_Clock_Count + 1;
              end
          end
     
        STOP_BIT :
          begin
            // Wait i_Clks_Per_Bit-1 clock cycles to reach center of stop bit
            if (r_Clock_Count >= i_Clks_Per_Bit-1)
              begin
                if( i_Rx_Serial == 1)begin
                  r_Byte_Done       <= 1'b1;
                  r_Rx_Byte <= rx_Data_Bits;
                end
                r_Clock_Count <= 0;
                r_Rx_Busy <= 0;
                state     <= IDLE;
              end
            else
              begin
                r_Clock_Count <= r_Clock_Count + 1;
              end
          end
         
         
        default :
          state <= IDLE;
         
      endcase
    end
   
  assign o_Rx_Done = r_Byte_Done;
  assign o_Rx_Byte = r_Rx_Byte;
  assign o_Rx_Busy = r_Rx_Busy;
   
endmodule



module RX_tb();

   reg          clk;
   reg          reset;
   reg          i_Rx_Serial;
   reg [4:0]    i_Clks_Per_Bit;
   reg          eps;
   reg          pen;
   wire         o_Rx_Busy;
   wire         o_Rx_Done;
   wire [7:0]   o_Rx_Byte;

  always
    begin
    #10
    clk = ~clk;
    end

  initial 
  begin
   i_Rx_Serial=1; reset=0; eps = 0; pen = 1; i_Clks_Per_Bit = 16; clk = 0; #100

  @(posedge clk)
   i_Rx_Serial=0;#320

  @(posedge clk)
   i_Rx_Serial=1;#320

  @(posedge clk)
   i_Rx_Serial=1;#320

  @(posedge clk)
   i_Rx_Serial=0;#320

  @(posedge clk)
   i_Rx_Serial=1;#320

  @(posedge clk)
   i_Rx_Serial=0;#320

  @(posedge clk)
   i_Rx_Serial=1;#320

  @(posedge clk)
   i_Rx_Serial=0;#320

  @(posedge clk)
   i_Rx_Serial=1;#320

  @(posedge clk)
   i_Rx_Serial=0;#320

  @(posedge clk)
   i_Rx_Serial=1;

   #2000

  @(posedge clk)
   i_Rx_Serial=0;#320

  @(posedge clk)
   i_Rx_Serial=0;#320

  @(posedge clk)
   i_Rx_Serial=1;#320

  @(posedge clk)
   i_Rx_Serial=0;#320

  @(posedge clk)
   i_Rx_Serial=1;#320

  @(posedge clk)
   i_Rx_Serial=0;#320

  @(posedge clk)
   i_Rx_Serial=1;#320

  @(posedge clk)
   i_Rx_Serial=1;#320

  @(posedge clk)
   i_Rx_Serial=1;#320

  @(posedge clk)
   i_Rx_Serial=1;#320

  @(posedge clk)
   i_Rx_Serial=1;

   #2000
   $stop;
  end

  UART_RX  rx(
       clk,
       reset,
       i_Rx_Serial,
       i_Clks_Per_Bit,
       eps,
       pen,
       o_Rx_Busy,
       o_Rx_Done,
       o_Rx_Byte
   );

endmodule
