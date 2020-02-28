//设计快
module fifo_syn_ram(clk,wr_en,                   
                    rd_en, 
                    rd_addr, 
                    data_in, 
                    data_out); //存储器模块RAM
  input clk,wr_en,rd_en; 
  input [5:0]wr_addr; 
  input [5:0]rd_addr; 
  input [7:0]data_in; 
  output [7:0]data_out; 
     
  reg [7:0]data_out; 
  reg [7:0]ram[63:0]; 
  wire clk,wr_en,rd_en; 
  wire [7:0]data_in; 
  
  always@(posedge clk or wr_en) 
    begin 
      if(wr_en) //当写使能信号高电平时，将输入数据写入相应存储单元
        begin 
          ram[wr_addr]<=data_in; 
        end 
    end 
  always@(posedge clk or rd_en) 
    begin 
      if(rd_en) //读使能信号高电平时，将相应存储单元的数据读出
        begin 
            data_out<=ram[rd_addr]; 
        end 
    end 
endmodule

module fifo_syn_wraddr_gen(clk, 
                           rst, 
                           wr_en, 
                           full, 
                           wr_addr); //用于产生写数据时所用的地址
  input clk,rst,wr_en,full; 
  output [5:0]wr_addr; 
   
  reg [5:0]wr_addr; //由4位计数器产生
  wire clk,rst,wr_en,full; 
   
 always@(posedge clk or rst or full or wr_en) 
   begin 
    if(!rst) //复位时，写地址值为0
       begin 
         wr_addr<=0; 
       end 
    else 
       begin 
        if(full) //FIFO满时，置地址为全1
           begin 
             wr_addr[5:0]<=6'b111111; 
           end 
        else //FIFO未满且写使能信号为高电平时，地址加1，否则不变
           begin 
               if(wr_en) 
                begin 
                   wr_addr<=wr_addr+1; 
                end 
           end 
       end         
   end 
endmodule

module fifo_syn_rdaddr_gen(clk, 
                           rst, 
                           empty, 
                           rd_en, 
                           rd_addr); //用于产生FIFO读数据所用的地址
  input clk,rst,empty,rd_en; 
  output [5:0]rd_addr; 
  
  reg [5:0]rd_addr; //由4位计数器产生
  wire clk,rst,empty,rd_en; 
   
 always@(posedge clk or rst or empty or rd_en) 
   begin 
    if(!rst) //复位时，读地址为0
       begin 
         rd_addr<=0; 
       end 
    else 
       begin 
        if(empty) //FIFO为空时，读地址为0
          begin 
             rd_addr<=0; 
          end 
        else 
          begin 
            if(rd_en) //FIFO未满且读使能信号为高电平时，地址加1，否则不变
              begin 
                rd_addr<=rd_addr+1; 
              end 
           end 
       end         
   end 
endmodule

module fifo_syn_flag(clk, 
                     rst, 
                     wr_en, 
                     rd_en, 
                     empty, 
                     full); //用于产生FIFO空满标志
  input clk,rst,wr_en,rd_en; 
  output empty,full; 
  wire clk,rst,wr_en,rd_en; 
  reg [5:0]fifo_cnt; //计数器，用于指示当前周期中FIFO数据个数，FIFO中最多有16个数据
  wire empty,full; 
   
  parameter RAM_MN=62; //定义状态参数
  reg empty_in,full_in; 
  assign empty=empty_in; 
  assign full=full_in; 
    
  always@(posedge clk or rst or wr_en or rd_en or full or empty) 
    begin 
      if(!rst) //复位信号进行重置
         begin 
           fifo_cnt<=0; //计数器初始化为0
           empty_in<=1; 
           full_in<=0;          
         end 
       else 
        begin 
          if(wr_en) 
             begin 
               if(rd_en) //当读/写使能信号同时有效，计数器不变，FIFO中数据个数不变
                  begin 
					fifo_cnt<=fifo_cnt; //当前状态
                  end 
               else 
                  begin 
                    if(!full) //当写使能信号有效且存储器未满时，计数器加1
                      begin 
                        fifo_cnt<=fifo_cnt+1; 
                        empty_in<=0; 
                        if(fifo_cnt==RAM_MN) //计数器为最大时，设置满信号为1，表存储器已满
                           full_in<=1;                            
                      end 
                  end 
             end 
          else 
            begin    
              if(rd_en) 
                begin 
                  if(!empty) //当读使能信号有效且存储器不为空，计数器减1
                    begin 
                      fifo_cnt<=fifo_cnt-1; 
                      full_in<=0; 
                      if(fifo_cnt==0) //计数器为0时，设置空信号为1，表存储器为空
                        empty_in=1; 
                    end 
                end  
              else 
                 fifo_cnt<=fifo_cnt;        
            end 
        end        
    end 
endmodule

//顶层模块
module fifo_syn_top(clk,rst,wr_en,rd_en,data_in,data_out); 
    input clk,rst,wr_en,rd_en; 
    input [7:0]data_in; 
    output [7:0]data_out; 
     
    wire [7:0]data_out; 
    wire [7:0]data_in; 
    wire [5:0]wr_addr; 
    wire [5:0]rd_addr; 
    
    fifo_syn_ram myram(.clk(clk), 
                       .wr_en(wr_en), 
                       .wr_addr(wr_addr), 
                       .rd_en(rd_en), 
                       .rd_addr(rd_addr), 
                       .data_in(data_in), 
                       .data_out(data_out)); 
   fifo_syn_wraddr_gen mywr(.clk(clk), 
                            .rst(rst), 
                            .wr_en(wr_en), 
                            .full(full), 
                            .wr_addr(wr_addr)); 
   fifo_syn_rdaddr_gen myrd(.clk(clk), 
                            .rst(rst), 
                            .empty(empty), 
                            .rd_en(rd_en), 
                            .rd_addr(rd_addr)); 
   fifo_syn_flag myflag(.clk(clk), 
                        .rst(rst), 
                        .wr_en(wr_en), 
                        .rd_en(rd_en), 
                        .empty(empty), 
                        .full(full)); 
endmodule
  
//测试块
module fifo_top_tb();
    reg clk;
    reg rst;
    reg wr_en;
    reg rd_en;
    reg [7:0]data_in;
    wire [7:0]data_out;
	
	integer i;
	
fifo_syn_top myfifo(.clk(clk),
                    .rst(rst),
                    .wr_en(wr_en),
                    .rd_en(rd_en),
                    .data_in(data_in),
                    .data_out(data_out));//实例化顶层模块

always #10 clk=~clk;//时钟翻转

initial
begin
    clk=0;
    rst=0;
    #100 rst=1;
	
    wr_en=1;
    rd_en=0;
	
    data_in[7:0]=8'b10101010;//初始化写入数据
    #20 data_in[7:0]=8'b11001100;
    #20 data_in[7:0]=8'b11111111;
	
    #20 wr_en=0;
        rd_en=1;
    #80 rd_en=0;
    
    rst=0;
    #100 rst=1;
	
    wr_en=1;
    rd_en=0;
	
    for(i=0;i<16;i=i+1)//连续写入数据
      begin
        #20 data_in[7:0]=8'b00000000;
        #20 data_in[7:0]=8'b10101010;
        #20 data_in[7:0]=8'b11001100;
        #20 data_in[7:0]=8'b11111111; 
      end
	  
    #1000 wr_en=0;
    #10 rd_en=1;
	
    #2000 rst=0; 
end
endmodule