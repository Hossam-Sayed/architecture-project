
module TbGPIOBUS();

  reg                          PRESETn;
  wire                         PENABLE;
  wire                [31:0]   PADDR_O;
  wire                         PWRITE;
  wire               [32-1:0]  PRDATA;
  wire                         PREADY;
  wire                [32-1:0] data1;
  wire                [32-1:0] data2;
  wire                [32-1:0] data3;
  wire                [32-1:0] data_reg;
  
  
  
  
  reg PCLK , PRESTn , transfer, Read_Write ; // For ex : From cpu to master
  reg[31:0] PADDR_I , write_data ;
  wire [1:0] PSEL ;  // 2`b00 No selction , 2`b01 uart , 2`b10 gpio 
  wire [31:0] PWDATA  ;
  wire [31:0] read_data_out ;

  
  
  
  
  always
    begin
    #10
    PCLK = ~PCLK;
    end
  
    
  
  initial 
  begin
  PRESETn = 0 ; PCLK = 0;  PRESTn = 0 ; transfer = 0 ;
  @(negedge PCLK)
  PRESETn = 1 ;PRESTn = 1 ; transfer = 1 ; Read_Write=1 ; 
  PADDR_I = 32'h1000 ; write_data = 32'hF0FF00F0;
  
  @(negedge PCLK)
  PRESETn = 1  ;  
  
  @(negedge PCLK)
  PRESETn = 1  ;  
  
  @(negedge PCLK)
  PRESETn = 1 ;
  @(negedge PCLK)
  PRESETn = 1  ;  
  
  $stop;
  
  
  /*
  initial 
  begin
  PRESETn = 1 ;  PCLK = 0; PRESTn = 0 ; transfer = 0 ; //  check reset signal validity 
 
  @(negedge PCLK)
  PRESETn = 1 ; PRESTn = 1 ; transfer = 1 ; Read_Write=0 ; 
  PADDR_I = 32'h1004 ; // check Enable signal 
  
 
  @(negedge PCLK)
  PRESETn = 1 ;  // check ready signal
 
 
  @(negedge PCLK)
  PRESETn = 1 ;  // check ready signal
  
  @(negedge PCLK)
  PRESETn = 1 ;    // check ready signal
  
 @(negedge PCLK)
  PRESETn = 1;   // check ready signal
  */


  $stop;
  
  
  
  
  end


  apb_gpio_UART final_test
(
                          PRESETn,
                           PCLK,
                           PSEL[1],
                           PENABLE,
                            PADDR_O,
                           PWRITE,
                          PWDATA,
                          PRDATA,
                          PREADY,
                          data1,
                          data2,
                          data3

);
  
MasterAPB APB_BUS(PCLK, PADDR_O,read_data_out  , Read_Write , transfer , PRESTn ,PREADY, 
 PSEL,PENABLE , PWDATA , PWRITE , write_data ,PRDATA , PADDR_I);

endmodule 
