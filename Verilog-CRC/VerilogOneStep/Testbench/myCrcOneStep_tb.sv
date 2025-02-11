/*
 * @Author       : Xu Xiaokang
 * @Email        :
 * @Date         : 2025-01-23 10:46:28
 * @LastEditors  : Xu Xiaokang
 * @LastEditTime : 2025-02-10 22:22:06
 * @Filename     :
 * @Description  :
*/

module myCrcOneStep_tb();

timeunit 1ns;
timeprecision 1ps;

//++ 实例化待测模块 ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
localparam DIN_WIDTH = 36; // 4的倍数
localparam WIDTH = 32;
localparam REFLECT_IN = 1;
localparam XOR_IN = 32'hFFFFFFFF;
localparam REFLECT_OUT = 1;
localparam XOR_OUT = 32'hFFFFFFFF;

logic [WIDTH-1 : 0] crc_out;
logic crc_out_valid;
logic [DIN_WIDTH-1 : 0] din;
logic  din_valid;
logic  clk;
logic  rstn;

myCrcOneStep #(
  .DIN_WIDTH   (DIN_WIDTH  ),
  .WIDTH       (WIDTH      ),
  .REFLECT_IN  (REFLECT_IN ),
  .XOR_IN      (XOR_IN     ),
  .REFLECT_OUT (REFLECT_OUT),
  .XOR_OUT     (XOR_OUT    )
) myCrcOneStep_inst (.*);
//-- 实例化待测模块 ------------------------------------------------------------


//++ 生成时钟 ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
localparam CLKT = 2;
initial begin
  clk = 0;
  forever #(CLKT / 2) clk = ~clk;
end
//-- 生成时钟 ------------------------------------------------------------


initial begin
  rstn = 0;
  #(CLKT * 2.6)
  rstn = 1;
  din = 'h8_2340_1230;
  din_valid = 1;
  #(CLKT*1)
  din = 'h5_AAAA_BCBC;
  #(CLKT*1)
  din = 'h3_8740_1000;
  #(CLKT*1)
  din = 'h0_0000_1441;
  #(CLKT*1)
  din_valid = 0;
  #(CLKT * 5) $stop;
end


endmodule