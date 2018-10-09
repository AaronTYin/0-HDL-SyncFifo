/***************************Copyright (c)***************************
**							          QSTSKING
**
**----------------------------File Info-----------------------------
** File Name:						fifo.v
** Last Modified Date:			2018-4-25
** Last Modified Version:		1.0
** Description:					xxx
**------------------------------------------------------------------
** Created By:						ArronTY
** Created Date:					2018-4-25
** Version:							1.0
** Description:					The origin version
**------------------------------------------------------------------
** Modified By:
** Modified Date:
** Modified Version:
** Description:
**------------------------------------------------------------------
*******************************************************************/


module ram(input clk,
			  input rst,
			  input wr_en,
			  input rd_en,
			  input [3:0]wr_addr,
			  input [3:0]rd_addr,
			  input full,
			  input empty,
			  input [7:0]data_in,
			  output reg[7:0]data_out);
			  
  reg [7:0]ram[0:16];
  
always @(posedge clk or negedge rst)
begin
	if(!rst)
	begin
		data_out<=0;
	end
	else
	begin
		if(rd_en==1 && empty==0)
			data_out<=ram[rd_addr];
	end
end

always @(posedge clk)
begin
	if(wr_en==1 && full==0)
	begin
		ram[wr_addr]<=data_in;
	end
end
endmodule


module wr_addr_gen(input clk, 
                   input rst, 
                   input wr_en, 
                   input full, 
                   output reg [3:0]wr_addr); 
						 
always @(posedge clk or negedge rst) 
begin 
	if(!rst) 
	begin 
		wr_addr<=0; 
	end 
	else if(full==0 && wr_en==1) 
	begin 
		wr_addr<=wr_addr+1;
	end 
	else 
	begin 
		wr_addr<=0;
	end 
end         
endmodule


module rd_addr_gen(input clk,
                   input rst,
                   input rd_en,
                   input empty,
                   output reg[3:0]rd_addr);
						 
always @(posedge clk or negedge rst)
begin
	if(!rst)
	begin
		rd_addr<=0;
	end  
	else
	begin
		if(empty==0&&rd_en==1)
		begin
			rd_addr<=rd_addr+1;
		end
	end
end
endmodule


module flag_gen(input clk,
					 input rst,
					 input wr_en,
					 input rd_en,
					 output reg full,
					 output reg empty);
					 
reg [4:0]count; 



always @(posedge clk or negedge rst)
begin
	if(!rst)
	begin
		count=0;
	end
	else
	begin
		case({wr_en,rd_en})
		2'b00:count<=count;
		2'b01:if(count!=5'b00000)
			count <= count-1;
		2'b10:if(count!=5'b01111)
			count <= count+1;
		2'b11:count<=count;
		endcase      
	end
end

always @(count)
begin
	if(count==5'b10000)
		full<=1;
	else
		full<=0;
end

always @(count)
begin
	if(count==5'b00000)
		empty<=1;
	else
		empty<=0;
end
endmodule


module sync_fifo(input clk,
					input rst,
					output [7:0]data_out,
					output full,
					output empty,
					output reg  [4:0]time_cnt);

wire wr_en;
wire rd_en;
wire [3:0]rd_addr;
wire [3:0]wr_addr;
reg [7:0]data_in;


ram ram_top(.clk(clk),
				.rst(rst),
				.wr_en(wr_en),
				.rd_en(rd_en),
				.wr_addr(wr_addr),
				.rd_addr(rd_addr),
				.data_in(data_in),
				.full(full),
				.empty(empty),
				.data_out(data_out));
				
rd_addr_gen rd_addr_gen_top(.clk(clk),
									.rst(rst),
									.rd_en(rd_en),
									.empty(empty),
									.rd_addr(rd_addr));
									
wr_addr_gen wr_addr_gen_top(.clk(clk),
									.rst(rst),
									.wr_en(wr_en),
									.full(full),
									.wr_addr(wr_addr));
									
flag_gen flag_gen_top(.clk(clk),
							.rst(rst),
							.wr_en(wr_en),
							.rd_en(rd_en),
							.full(full),
							.empty(empty));
							
							
always @(posedge clk or negedge rst)
begin
   if (rst == 1'b0)
      data_in <= 8'd0;
   else if (data_in == 8'd15)
      data_in <= 8'd0;
	else if (data_in >= 8'd0 && data_in < 8'd15)
      data_in <= data_in + 8'd1;
end

always @(posedge clk or negedge rst)
begin 
	if (!rst)
	      time_cnt <=5'b0;
			else if (data_in == 5'd31)
			time_cnt <=5'b0;
			else if (data_in >= 5'd0 && data_in < 5'd31)
			time_cnt <= time_cnt + 5'd1;
	end

assign wr_en = (time_cnt >= 1'b0 && time_cnt <= 5'd15) ? 1'b1:1'b0;
assign rd_en = (time_cnt >= 5'd16 && time_cnt <= 5'd31) ? 1'b1:1'b0;


endmodule


/*`timescale 1 ns/ 1 ps
module sync_fifo_vlg_tst();
reg eachvec;
reg clk;
reg rst;
reg wr_en;
reg rd_en;
reg [7:0] data_in;
wire [7:0]  data_out;
wire full;
wire empty;
integer i;

sync_fifo i1 (
	.clk(clk),
	.rst(rst),
	.data_in(data_in),
	.data_out(data_out),
	.full(full),
	.empty(empty),
	.wr_en(wr_en),
	.rd_en(rd_en)
);

always #10 clk=~clk;

initial
begin
	clk=0;
	rst=0;
	rd_en=0;
	wr_en=0;
	data_in=0;
	
	#40
	rst=1;
	#35
	wr_en=1;
	#20
	rd_en=1; 
	
	for(i=0;i<20;i=i+1)
	begin
		#20 data_in=data_in+1;
	end

	
	#200 $stop;
end
endmodule*/