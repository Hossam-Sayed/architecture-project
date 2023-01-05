module Test_APB_UART();
  
  reg PCLK , PRESTn , transfer, Read_Write ; // For ex : From cpu to master
  reg[31:0] PADDR_I , write_data  ;
  wire PWRITE , PENABLE ;
  wire [1:0] PSEL ;  // 2`b00 No selction , 2`b01 uart , 2`b10 gpio 
  wire [31:0] PADDR_O  , PWDATA  ;
  wire [31:0] read_data_out ;
  
  reg                          rst;
  reg                          rxSerial;
  wire                [32-1:0] PRDATA;
  wire                         PREADY; ////////
  wire                         txSerial;
  
  
  MasterAPB APB_BUS(PCLK, PADDR_O,read_data_out  , Read_Write , transfer , PRESTn ,PREADY, 
  PSEL,PENABLE , PWDATA , PWRITE , write_data ,PRDATA , PADDR_I);
  
  
  UART uart(
    PADDR_O,
    PWDATA,
    PSEL[0],
    PENABLE,
    PWRITE,
    rst,
    PCLK,
    rxSerial,
    PRDATA,
    PREADY,
    txSerial
);

 
  always
    begin
    #10
    PCLK = ~PCLK;
    end

  
  initial 
  begin
   PCLK = 0 ; PRESTn = 0 ; transfer = 0 ;
  @(posedge PCLK)
  
   PRESTn = 1 ; transfer = 1 ; Read_Write= 1 ;
   PADDR_I = 2000 ; write_data = 32'b11000;
   
  @(posedge PCLK)
  @(posedge PCLK)
  
   PRESTn = 1 ; transfer = 1 ; Read_Write=1 ;
   PADDR_I = 2004 ; write_data = 32'b0;
  
  @(posedge PCLK)
  @(posedge PCLK)
  
  PADDR_I = 2008 ; write_data = 32'hBF5E9D02;  
  
  @(posedge PCLK)
  @(posedge PCLK)
  transfer=0;
  
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
  #17400
  #17400
  @(posedge PCLK)
  transfer = 1;PADDR_I= 2008 ;Read_Write = 0; 
  @(posedge PCLK)
  @(posedge PCLK)
  @(posedge PCLK)
   transfer = 0 ;
  end
  
  
endmodule