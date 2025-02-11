/*
 * @Author       : Xu Xiaokang
 * @Email        :
 * @Date         : 2025-01-23 10:46:28
 * @LastEditors  : Xu Xiaokang
 * @LastEditTime : 2025-02-11 10:34:35
 * @Filename     :
 * @Description  :
*/

module myCrcMultiStep_tb();

timeunit 1ns;
timeprecision 1ps;

//++ 实例化待测模块 ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
localparam DIN_WIDTH = 32; // 8的倍数
localparam LAST_DIN_WIDTH = 16;
localparam WIDTH = 32;
localparam REFLECT_IN = 1;
localparam XOR_IN = 32'hFFFF_FFFF;
localparam REFLECT_OUT = 1;
localparam XOR_OUT = 32'hFFFF_FFFF;

logic [WIDTH-1 : 0] crc_out;
logic crc_out_valid;
logic [DIN_WIDTH-1 : 0] din;
logic  din_valid;
logic  din_first;
logic  din_last;
logic  clk;
logic  rstn;

myCrcMultiStep #(
  .DIN_WIDTH      (DIN_WIDTH     ),
  .LAST_DIN_WIDTH (LAST_DIN_WIDTH),
  .WIDTH          (WIDTH         ),
  .REFLECT_IN     (REFLECT_IN    ),
  .XOR_IN         (XOR_IN        ),
  .REFLECT_OUT    (REFLECT_OUT   ),
  .XOR_OUT        (XOR_OUT       )
) myCrcMultiStep_inst (.*);
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
  #(CLKT * 10.6)
  rstn = 1;
  din = 'h12004578;
  din_valid = 1;
  din_first = 1;
  din_last  = 0;
  #(CLKT*1)
  din = 'h368F0002;
  din_valid = 1;
  din_first = 0;
  din_last  = 1;
  #(CLKT*1)
  din = 'h78780000;
  din_valid = 1;
  din_first = 1;
  din_last  = 0;
  #(CLKT*1)
  din = 'h00010032;
  din_valid = 1;
  din_first = 0;
  din_last  = 1;
  #(CLKT*1)
  din_valid = 0;
  din_first = 0;
  din_last  = 0;
  #(CLKT * 10) $stop;
end


endmodule