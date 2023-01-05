module UART #(
    parameter LCR_ADDRESS = 2000,
    parameter MDR_ADDRESS = 2004,
    parameter TX_FIFO_ADDRESS = 2008
)(
    input [31:0] padd,
    input [31:0] pdata,
    input psel,
    input pen,
    input pwr,
    input rst,
    input clk,
    input rxSerial,
    output reg [31:0] prdata,
    output reg pready,
    output txSerial
);

    reg txEps;
    reg txPen;
    reg rxEps;
    reg rxPen;
    reg osmSel;

    reg [7:0] txByte;
    reg txStart = 0;

    reg [31:0] LCR = 32'b0; /* Line Control Register, bit 4 EPS (Even Parity Select), bit 3 PE (Parity Enable),
                            bits [31:5] and [2:0] are reserved or not supported in our implementation.*/
    reg [31:0] MDR = 32'b0; // Mode Definition Register for 31:1 reserved and bit 0 OSM_SEL for oversampling mode select x13 or x16
    reg [4:0] clks_Per_Bit;

    wire rxClk;
    wire txClk;
    wire rxBusy;
    wire txBusy;
    wire wTxSerial;

    wire txDone;
    wire rxDone;
    wire [7:0] rxByte;

    reg [7:0] rxFifo [0:15];
    reg [31:0] rxFifoOut;
    reg [3:0] rxFifoReadIndex = 0;
    reg [3:0] rxFifoWriteIndex = 0;
    reg rxFifoEmpty = 1;
    reg rxFifoFull = 0;
    reg rxDataReady = 0;
    reg r_rx_done = 0;
    reg [7:0] r_rx_byte;

    reg [7:0] txFifo [0:15];
    reg [31:0] txFifoIn;
    reg [3:0] txFifoReadIndex = 0;
    reg [3:0] txFifoWriteIndex = 0;
    reg txFifoStart = 0;
    reg txFifoFull = 0;
    reg txFifoEmpty = 1;

    BaudRateGenerator baud_gen (clk, osmSel, rxClk, txClk);
    UART_RX rx (rxClk, rst, rxSerial, clks_Per_Bit, rxEps, rxPen, rxBusy, rxDone, rxByte);
    UART_TX tx (txClk, rst, txEps, txPen, txStart, txByte, txBusy, txSerial, txDone);

    always @(posedge rst) begin
        if (rst == 1) begin
            LCR <= 32'b0;
            MDR <= 32'b0;
            txStart <= 0;
            txFifoStart <= 0;
            txFifoFull <= 0;
            txFifoEmpty <= 1;
            txFifoReadIndex <= 0;
            txFifoWriteIndex <= 0;
            rxFifoReadIndex <= 0;
            rxFifoWriteIndex <= 0;
            rxFifoEmpty = 1;
            rxFifoFull <= 0;
            rxDataReady <= 0;
            r_rx_done <= 0;
        end
    end

always @(posedge clk) begin
    if (rxBusy == 0) begin
        osmSel <= MDR[0];
        clks_Per_Bit <= 16 - 3*MDR[0];
        rxPen <= LCR[3];
        rxEps <= LCR[4];
    end

    if (txBusy == 0) begin
        txPen <= LCR[3];
        txEps <= LCR[4];
    end
end

always @(negedge clk) begin
  if (pready == 1)begin
    pready <= 0;
  end
  else if (psel == 1) begin
        if (pen == 1) begin
            if (pwr == 1) begin
                case (padd)
                    LCR_ADDRESS: begin
                        LCR <= pdata;
                        pready <= 1;
                    end
                    MDR_ADDRESS: begin
                        MDR <= pdata;
                        pready <= 1;
                    end
                    TX_FIFO_ADDRESS: begin
                        if (txFifoFull == 0 && txFifoReadIndex % 4 == 0) begin
                            txFifoIn <= pdata;
                            txFifoStart <= 1;
                            pready <= 1;
                        end
                    end
                endcase
            end
            else if(rxDataReady == 1) begin
                prdata <= rxFifoOut;
                rxDataReady <=0;
                pready <= 1;
            end
        end
    end
end

always @(posedge clk) begin
    if (rxDataReady == 0 && rxFifoEmpty == 0 && rxFifoWriteIndex % 4 == 0) begin
        if((rxFifoReadIndex + 4) % 16 == rxFifoWriteIndex)
            rxFifoEmpty <= 1;
        rxFifoOut[31:24] <= rxFifo[rxFifoReadIndex + 3] ;
        rxFifoOut[23:16] <= rxFifo[rxFifoReadIndex + 2] ;
        rxFifoOut[15:8] <= rxFifo[rxFifoReadIndex + 1] ;
        rxFifoOut[7:0] <= rxFifo[rxFifoReadIndex];
        rxFifoReadIndex <= rxFifoReadIndex + 4;
        rxFifoFull <= 0;
        rxDataReady <= 1;
    end
    else if (rxFifoFull == 0 && r_rx_done == 1) begin
            if ((rxFifoWriteIndex + 1) % 16 == rxFifoReadIndex) begin
                rxFifoFull <= 1;
            end
            rxFifo[rxFifoWriteIndex] <= r_rx_byte;
            rxFifoWriteIndex <= rxFifoWriteIndex + 1;
            r_rx_done <= 0;
            rxFifoEmpty <= 0;
    end
end

always @(posedge rxDone) begin
    r_rx_done <= 1;
    r_rx_byte <= rxByte;
end

always @(posedge clk) begin
    if (txFifoStart == 1) begin
        if ((txFifoWriteIndex + 4) % 16 == txFifoReadIndex) begin
            txFifoFull <= 1;
        end
        txFifo[txFifoWriteIndex]     <= txFifoIn[7:0];
        txFifo[txFifoWriteIndex + 1] <= txFifoIn[15:8];
        txFifo[txFifoWriteIndex + 2] <= txFifoIn[23:16];
        txFifo[txFifoWriteIndex + 3] <= txFifoIn[31:24];
        txFifoWriteIndex <= txFifoWriteIndex + 4;
        txFifoEmpty <= 0;
        txFifoStart <= 0;
        txStart <= 0;
    end
end

always@(negedge txClk)begin
    if (txFifoEmpty == 0 && txBusy == 0) begin
        if ((txFifoReadIndex + 1) % 16 == txFifoWriteIndex) begin
            txFifoEmpty <= 1;
        end
        txStart <= 1;
        txByte <= txFifo[txFifoReadIndex];
        txFifoReadIndex <= txFifoReadIndex + 1;
        txFifoFull <= 0;
    end
    else if(txBusy == 1 || txFifoEmpty == 1)begin
      txStart <= 0;
      end
end


assign txSerial = wTxSerial;

endmodule


/*
 31                       5    4       3       2    1       0
 ____________________________________________________________
|                          |       |       |       |         |
|         Reserved         |  EPS  |  PEN  |  STB  |   WLS   |  STB and WLS are not supported
|__________________________|_______|_______|_______|_________|
                            LCR


  31                                             1       0
 ____________________________________________________________
|                                                  |         |
|                   Reserved                       | OSM_SEL |
|__________________________________________________|_________|
                            MDR

*/



module UART_tb();

  reg                         rst;
  reg                         clk;
  reg                         psel;
  reg                         pen;
  reg                  [31:0] padd;
  reg                         pwr;
  reg                [32-1:0] pdata;
  reg                         rxSerial;
  wire               [32-1:0] prdata;
  wire                         pready;
  wire                         txSerial;

  always
    begin
    #10
    clk = ~clk;
    end

  initial 
  begin
   clk = 0;
  @(posedge clk)
   psel = 1; pen = 1; padd = 2000; pwr = 1; pdata = 32'b11000;

  @(posedge clk)
  @(posedge clk)
   psel = 1; pen = 1; padd = 2004; pdata = 32'b0; pwr = 1;  

  @(posedge clk)
  @(posedge clk)
   psel = 1; pen = 1; padd = 2008; pdata = 32'b01000110111111111111101111111111; pwr = 1;  

  @(posedge clk)
   pen = 0; rxSerial = 1;

   #17400
   #17400       //0   1101 0011  1 1
                //1100 1011
   rxSerial = 0;
   #17400
   rxSerial = 1;
   #17400
   rxSerial = 1;
   #17400
   rxSerial = 0;
   #17400
   rxSerial = 1;
   #17400
   rxSerial = 0;
   #17400
   rxSerial = 0;
   #17400
   rxSerial = 1;
   #17400
   rxSerial = 1;
   #17400
   rxSerial = 1;
   #17400
   rxSerial = 1;

   #17400
   #17400
   #17400     // 0     01111111  0   1       wrong parity
   rxSerial = 0;
   #17400
   rxSerial = 0;
   #17400
   rxSerial = 1;
   #17400
   rxSerial = 1;
   #17400
   rxSerial = 1;
   #17400
   rxSerial = 1;
   #17400
   rxSerial = 1;
   #17400
   rxSerial = 1;
   #17400
   rxSerial = 1;
   #17400
   rxSerial = 0;
   #17400
   rxSerial = 1;

      #17400
   #17400
      #17400    //0   1111 1111   1  1   wrong parity
   rxSerial = 0;
   #17400
   rxSerial = 1;
   #17400
   rxSerial = 1;
   #17400
   rxSerial = 1;
   #17400
   rxSerial = 1;
   #17400
   rxSerial = 1;
   #17400
   rxSerial = 1;
   #17400
   rxSerial = 1;
   #17400
   rxSerial = 1;
   #17400
   rxSerial = 1;
   #17400
   rxSerial = 1;

      #17400
   #17400
         #17400          // 0  11111111   0 1
   rxSerial = 0;
   #17400
   rxSerial = 1;
   #17400
   rxSerial = 1;
   #17400
   rxSerial = 1;
   #17400
   rxSerial = 1;
   #17400
   rxSerial = 1;
   #17400
   rxSerial = 1;
   #17400
   rxSerial = 1;
   #17400
   rxSerial = 1;
   #17400
   rxSerial = 0;
   #17400
   rxSerial = 1;

      #17400
   #17400
      #17400          //0     1101 0010  0 1
   rxSerial = 0;
   #17400
   rxSerial = 1;
   #17400
   rxSerial = 1;
   #17400
   rxSerial = 0;
   #17400
   rxSerial = 1;
   #17400
   rxSerial = 0;
   #17400
   rxSerial = 0;
   #17400
   rxSerial = 1;
   #17400
   rxSerial = 0;
   #17400
   rxSerial = 0;
   #17400
   rxSerial = 1;

      #17400
   #17400
      #17400 //0   1111 0100  1 1
   rxSerial = 0;
   #17400
   rxSerial = 1;
   #17400
   rxSerial = 1;
   #17400
   rxSerial = 1;
   #17400
   rxSerial = 1;
   #17400
   rxSerial = 0;
   #17400
   rxSerial = 0;
   #17400
   rxSerial = 1;
   #17400
   rxSerial = 0;
   #17400
   rxSerial = 1;
   #17400
   rxSerial = 1;

  @(posedge clk)
   psel = 1; pen = 1; padd = 2000; pwr = 1; pdata = 32'b0;

  @(posedge clk)
  @(posedge clk)
   psel = 1; pen = 1; padd = 2008; pdata = 32'b00010010000000110000000011001100; pwr = 1;  


  @(posedge clk)
   pen = 0;

   #1000000

  @(posedge clk)
   psel = 1; pen = 1; padd = 2000; pwr = 1; pdata = 32'b1000;  clk = 0;

  @(posedge clk)
  @(posedge clk)
   psel = 1; pen = 1; padd = 2008; pdata = 32'b10110100100100001010111011101100; pwr = 1;  

  @(posedge clk)
   pen = 0;

  #17400
  #17400
  @(posedge clk)
   psel = 1; pen = 1;pwr = 0; 
  @(posedge clk)
   pen = 0;

  end

UART uart(
    padd,
    pdata,
    psel,
    pen,
    pwr,
    rst,
    clk,
    rxSerial,
    prdata,
    pready,
    txSerial
);
endmodule