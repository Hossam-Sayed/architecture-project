module main();

  reg                         PRESETn;
  reg                         PCLK;
  reg                         PSEL;
  reg                         PENABLE;
  reg      [             31:0] PADDR;
  reg                         PWRITE;
  reg                [32-1:0] PWDATA;
  wire               [32-1:0] PRDATA;
  wire                         PREADY;
  wire                [32-1:0] data1;
  wire                [32-1:0] data2;
  wire                [32-1:0] data3;
  wire                [32-1:0] data_reg;
  
  
  always
    begin
    #10
    PCLK = ~PCLK;
    end
  
    
  /*
  initial 
  begin
  PRESETn = 0 ; PCLK = 0; PSEL = 1; PENABLE = 1; PADDR = 32'h1004; PWRITE = 0; PWDATA = 0; 
 
  @(negedge PCLK)
  PRESETn = 1 ; PSEL = 0; PENABLE = 0; PADDR = 32'h1004; PWRITE = 0; PWDATA = 0;  
  
  @(negedge PCLK)
  PRESETn = 1 ; PSEL = 1; PENABLE = 1; PADDR = 32'h1004; PWRITE = 1; PWDATA = 1 ;  
  
  @(negedge PCLK)
  PRESETn = 0 ; PCLK = 0; PSEL = 1; PENABLE = 0; PADDR = 32'h1004; PWRITE = 0; PWDATA = 0;   
  
  @(negedge PCLK)
  PRESETn = 0 ; PCLK = 0; PSEL = 1; PENABLE = 0; PADDR = 32'h1004; PWRITE = 0; PWDATA = 0;   
  
  $stop;
  */
  
  
  initial 
  begin
  PRESETn = 1 ;  PSEL = 1; PENABLE = 0; PADDR = 32'h1004; PWRITE = 1;  PCLK = 0;//  check reset signal validity 
 
  @(negedge PCLK)
  PRESETn = 1 ; PSEL = 1; PENABLE = 0; PADDR = 32'h1004; PWRITE = 0;  // check Enable signal 
  
 
  @(negedge PCLK)
  PRESETn = 1 ; PSEL = 1; PENABLE = 1; PADDR = 32'h1004; PWRITE = 0;  // check ready signal
 
 
  @(negedge PCLK)
  PRESETn = 1 ; PSEL = 1; PENABLE = 1; PADDR = 32'h1004; PWRITE = 0; // check ready signal
  
  @(negedge PCLK)
  PRESETn = 1 ; PSEL = 1; PENABLE = 1; PADDR = 32'h1004; PWRITE = 0;   // check ready signal
  
 @(negedge PCLK)
  PRESETn = 0 ; PSEL = 0; PENABLE = 0; PADDR = 32'h1004; PWRITE = 0;   // check ready signal
 


  $stop;
  
  
  
  
  end

  apb_gpio_UART final_test
(
                          PRESETn,
                           PCLK,
                           PSEL,
                           PENABLE,
                            PADDR,
                           PWRITE,
                          PWDATA,
                          PRDATA,
                          PREADY,
                          data1,
                          data2,
                          data3

);
  
endmodule 

module apb_gpio_UART
(
  input                       PRESETn,
  input                         PCLK,
  input                         PSEL,
  input                         PENABLE,
  input      [             31:0] PADDR,
  input                         PWRITE,
  input                [32-1:0] PWDATA,
  output reg           [32-1:0] PRDATA,
  output reg                    PREADY,
  output                [32-1:0] data1,
  output                [32-1:0] data2,
  output                [32-1:0] data3,
   reg                  [32-1:0]   data_reg,
   reg                  [32-1:0]   data_reg2,
   reg                  [32-1:0]  data_reg3

  
  //input reg            [32-1:0] CONTROL,  // PRESETn,PCLK,PSEL,PENABLE,PADDR * 2,PWRITE
  
  //input [32-1:0] tx_data,
  //output [32-1:0] rx_data
);
  //////////////////////////////////////////////////////////////////
  //
  // Constants
  //

  parameter PADDR_SIZE = 32;
  parameter PDATA_SIZE = 32;  //must be a multiple of 8

  parameter  DATA1 = 32'h1000,
             DATA2    = 32'h1004,
             DATA3    = 32'h1008;
  //////////////////////////////////////////////////////////////////
  //
  // Variables
  //

  //Control registers
  reg [PDATA_SIZE-1:0]
                        
                        in_reg_uart,
                        out_reg_uart;
  
  //////////////////////////////////////////////////////////////////
  //
  // always blocks
  //
  assign  tx_data = in_reg_uart;
  assign rx_data = out_reg_uart;

  assign data1 = data_reg;
  assign data2 = data_reg2;
  assign data3 = data_reg3;
 
initial 
begin 
data_reg = 32'hF1;
data_reg2 = 32'hF1;
data_reg3 = 32'hF1;
PREADY = 1;
end 



always @(posedge PCLK,negedge PRESETn)
begin
  PREADY <= 1;
	if (!PRESETn)
		begin
		data_reg <= 0;
	  data_reg2 <= 0;
	  data_reg3 <= 0;
		end
	else if(PREADY & PSEL & PENABLE & ~PWRITE)
	  begin
		// check address to read from
	   case (PADDR)
      
        DATA1   : PRDATA <= data_reg;
        DATA2   : PRDATA <= data_reg2;
        DATA3   : PRDATA <= data_reg3;
  
        default  : PRDATA <= 0;
      endcase
    end

		
	else if( PREADY & PSEL & PENABLE & PWRITE)
	  begin
		// check address to write on
		PREADY <= 0;
		case(PADDR)
    DATA1: data_reg <= PWDATA; 
    DATA2: data_reg2 <= PWDATA; 
    DATA3: data_reg3 <= PWDATA; 
		endcase
		end
	end


endmodule





