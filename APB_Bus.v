module MasterAPB(PCLK, PADDR_O,read_data_out  , Read_Write , transfer , PRESTn ,PREADY, 
 PSEL,PENABLE , PWDATA , PWRITE , write_data ,PRDATA , PADDR_I );

input PCLK , PRESTn , transfer, Read_Write ; // For ex : From cpu to master
input PREADY  ; // from slave to master
input[31:0] PADDR_I , write_data , PRDATA ;
output reg PWRITE , PENABLE ;
output reg [1:0] PSEL ;  // 2`b00 No selction , 2`b01 uart , 2`b10 gpio 
output reg[31:0] PADDR_O  , PWDATA  ;
output reg[31:0] read_data_out ;

reg [1:0] state , next_state ; 
// IDLE : PSEL = 2`b00 , PENABLE = 0 , Transfer = 0 // IDLE : PSEL = 2`b00 , PENABLE = 0 , Transfer = 0 
// SETUP : PSEL != 2`b00 , PENABLE = 0 ,  Transfer = 1 
// Access : PSEL != 2`b00 , PENABLE = 1 ,  Transfer = 1 

localparam IDLE = 3'b00, SETUP = 3'b01, ACCESS = 3'b10 ; 
//assign PSEL = ( (state!= IDLE ) ? (PADDR_I[31] ? 2'b10 : 2'b01) : 2'b00 );)

always@(PCLK)
begin
  if(PADDR_I == 31'h1000 || PADDR_I == 31'h1004)
    PSEL = 2'b10 ;
  else if (PADDR_I == 2000 || PADDR_I == 2004 || PADDR_I == 2008 )
    PSEL = 2'b01;
  else
    PSEL = 2'b00;
end

always@(posedge PCLK)
begin
  if(!PRESTn)
    state <= IDLE ;
  else
   state <= next_state ; 
 end
  
always@(state , transfer , PREADY )
begin 
  if(!PRESTn)
    next_state <= IDLE ;
  else
    begin
      
    case(state)
      IDLE:
      begin
      PENABLE <= 0 ;
      PWRITE <= 1'bX;
      PENABLE <= 1'b0 ;
      PSEL <= 2'b00 ;
      PADDR_O <= 32'hx;
      PWDATA <= 32'hx;
      read_data_out = 32'hx;
      if(transfer)
       next_state = SETUP ;
      else
       next_state = IDLE ;
      end
      
      SETUP:
      begin
         PENABLE = 0;
         PWRITE = Read_Write ;
         if(!Read_Write)
           PADDR_O = PADDR_I ;
         else
           begin
           PADDR_O = PADDR_I ;
           PWDATA = write_data ;
           end
         if(transfer)
           next_state = ACCESS ;
         else
           next_state = IDLE ;
       end
       ACCESS:
       begin
         PENABLE = 1 ;
         if(!transfer)
           next_state = IDLE ;
         else
           begin
             if(PREADY)
               begin
               if(Read_Write)
                 next_state = SETUP ;
               else
                begin
                  read_data_out = PRDATA ;
                  next_state = SETUP ; 
                end
               end
             else
              next_state = ACCESS ;
           end
        end
        default: next_state = IDLE;
      endcase
    end
end
endmodule 


module Test();

reg PCLK , PRESTn , transfer, Read_Write ; // For ex : From cpu to master
reg PREADY  ; // from slave to master
reg[31:0] PADDR_I , write_data , PRDATA ;
wire PWRITE , PENABLE ;
wire [1:0] PSEL ;  // 2`b00 No selction , 2`b01 uart , 2`b10 gpio 
wire [31:0] PADDR_O  , PWDATA  ;
wire [31:0] read_data_out ;

MasterAPB APB_BUS(PCLK, PADDR_O,read_data_out  , Read_Write , transfer , PRESTn ,PREADY, 
 PSEL,PENABLE , PWDATA , PWRITE , write_data ,PRDATA , PADDR_I);

always
begin
#10
PCLK = ~PCLK;
end
/* write
initial
begin
  
PCLK = 0 ; PRESTn = 0 ; transfer = 0 ;

@(negedge PCLK)
PRESTn = 1 ; transfer = 1 ; Read_Write=1 ; PREADY = 0 ;
PADDR_I = 31'h1000 ; write_data = 31'hF0FF00F0;

@(negedge PCLK)
PRESTn = 1 ; transfer = 1 ; Read_Write=1 ; PREADY = 1 ;
PADDR_I = 31'h1000 ; write_data = 31'hF0FF00F0;

@(negedge PCLK)
PRESTn = 1 ; transfer = 1 ; Read_Write=1 ; PREADY = 0 ;
PADDR_I = 31'h1000 ; write_data = 31'hF0FF00F0;

@(negedge PCLK)
PRESTn = 1 ; transfer = 0 ; Read_Write=1 ; PREADY = 0 ;

end

*/

/* read 
initial
begin
  
PCLK = 0 ; PRESTn = 0 ; transfer = 0 ;

@(negedge PCLK)
PRESTn = 1 ; transfer = 1 ; Read_Write=0 ; PREADY = 0 ;
PADDR_I = 31'h1000 ;

@(negedge PCLK)
PRESTn = 1 ; transfer = 1 ; Read_Write=0 ; PREADY = 1 ;
PADDR_I = 31'h1000 ; PRDATA = 32'h0EC25F01;

@(negedge PCLK)
PRESTn = 1 ; transfer = 1 ; Read_Write=0 ; PREADY = 1 ;
PADDR_I = 31'h1000 ; PRDATA = 32'h0EC25F01;

@(negedge PCLK)
PADDR_I = 31'h00 ; transfer = 0 ;
end
initial
begin
  
PCLK = 0 ; PRESTn = 0 ; transfer = 0 ;

@(negedge PCLK)
PRESTn = 1 ; transfer = 1 ; Read_Write=0 ; PREADY = 0 ;
PADDR_I = 31'h1000 ;

@(negedge PCLK)
@(negedge PCLK)
PRESTn = 1 ; transfer = 1 ; Read_Write=0 ; PREADY = 1 ;
PADDR_I = 31'h1000 ; PRDATA = 32'h0EC25F01;

@(negedge PCLK)
PRESTn = 1 ; transfer = 1 ; Read_Write=0 ; PREADY = 1 ;
PADDR_I = 31'h1000 ; PRDATA = 32'h0EC25F01;

@(negedge PCLK)
PADDR_I = 31'h00 ; transfer = 0 ;
end

*/
endmodule