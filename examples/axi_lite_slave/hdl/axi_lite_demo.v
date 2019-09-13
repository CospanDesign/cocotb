/*
Distributed under the MIT license.
Copyright (c) 2016 Dave McCoy (dave.mccoy@cospandesign.com)

Permission is hereby granted, free of charge, to any person obtaining a copy of
this software and associated documentation files (the "Software"), to deal in
the Software without restriction, including without limitation the rights to
use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies
of the Software, and to permit persons to whom the Software is furnished to do
so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
*/

/*
 * Author:
 * Description:
 *
 * Changes:
 */

`timescale 1ps / 1ps

module axi_lite_demo #(
  parameter ADDR_WIDTH          = 5,
  parameter DATA_WIDTH          = 32,
  parameter STROBE_WIDTH        = (DATA_WIDTH / 8)
)(
  input                               clk,
  input                               rst,

  //Write Address Channel
  input                               i_awvalid,
  input       [ADDR_WIDTH - 1: 0]     i_awaddr,
  output                              o_awready,

  //Write Data Channel
  input                               i_wvalid,
  output                              o_wready,
  input       [STROBE_WIDTH - 1:0]    i_wstrb,
  input       [DATA_WIDTH - 1: 0]     i_wdata,

  //Write Response Channel
  output                              o_bvalid,
  input                               i_bready,
  output      [1:0]                   o_bresp,

  //Read Address Channel
  input                               i_arvalid,
  output                              o_arready,
  input       [ADDR_WIDTH - 1: 0]     i_araddr,

  //Read Data Channel
  output                              o_rvalid,
  input                               i_rready,
  output      [1:0]                   o_rresp,
  output      [DATA_WIDTH - 1: 0]     o_rdata,


  //Video Channel
  output                              o_video_hsync,
  output                              o_video_vsync,
  output      [23:0]                  o_video_data  //RGB Data  R[5:0]  -> o_video_data[23:18]
                                                    //          G[5:0]  -> o_video_data[16:10]
                                                    //          B[5:0]  -> o_video_data[ 7: 2]

  //AXI Master (For Memory)


  input                             i_am_aclk,
  input                             i_am_areset_n,

  //bus write addr path
  output  reg [3:0]                 o_am_awid,         //Write ID
  output      [ADDR_WIDTH - 1:0]    o_am_awaddr,       //Write Addr Path Address
  output  reg [3:0]                 o_am_awlen,        //Write Addr Path Burst Length
  output  reg [2:0]                 o_am_awsize,       //Write Addr Path Burst Size
  output      [1:0]                 o_am_awburst,      //Write Addr Path Burst Type
                                                        //  0 = Fixed
                                                        //  1 = Incrementing
                                                        //  2 = wrap
  output      [1:0]                 o_am_awlock,       //Write Addr Path Lock (atomic) information
                                                        //  0 = Normal
                                                        //  1 = Exclusive
                                                        //  2 = Locked
  output      [3:0]                 o_am_awcache,      //Write Addr Path Cache Type
  output      [2:0]                 o_am_awprot,       //Write Addr Path Protection Type
  output  reg                       o_am_awvalid,      //Write Addr Path Address Valid
  input                             i_am_awready,      //Write Addr Path Slave Ready
                                                        //  1 = Slave Ready
                                                        //  0 = Slave Not Ready

    //bus write data
  output  reg [3:0]                 o_am_wid,          //Write ID
  output  reg [DATA_WIDTH - 1: 0]   o_am_wdata,        //Write Data (this size is set with the DATA_WIDTH Parameter
                                                      //Valid values are: 8, 16, 32, 64, 128, 256, 512, 1024
  output  reg [DATA_WIDTH >> 3:0]   o_am_wstrobe,      //Write Strobe (a 1 in the write is associated with the byte to write)
  output  reg                       o_am_wlast,        //Write Last transfer in a write burst
  output  reg                       o_am_wvalid,       //Data through this bus is valid
  input                             i_am_wready,       //Slave is ready for data

    //Write Response Channel
  input       [3:0]                 i_am_bid,          //Response ID (this must match awid)
  input       [1:0]                 i_am_bresp,        //Write Response
                                                        //  0 = OKAY
                                                        //  1 = EXOKAY
                                                        //  2 = SLVERR
                                                        //  3 = DECERR
  input                             i_am_bvalid,       //Write Response is:
                                                        //  1 = Available
                                                        //  0 = Not Available
  output  reg                       o_am_bready,       //WBM Ready

    //bus read addr path
  output  reg  [3:0]                o_am_arid,         //Read ID
  output       [ADDR_WIDTH - 1:0]   o_am_araddr,       //Read Addr Path Address
  output  reg  [3:0]                o_am_arlen,        //Read Addr Path Burst Length
  output  reg  [2:0]                o_am_arsize,       //Read Addr Path Burst Size
  output       [1:0]                o_am_arburst,      //Read Addr Path Burst Type
  output       [1:0]                o_am_arlock,       //Read Addr Path Lock (atomic) information
  output       [3:0]                o_am_arcache,      //Read Addr Path Cache Type
  output       [2:0]                o_am_arprot,       //Read Addr Path Protection Type
  output  reg                       o_am_arvalid,      //Read Addr Path Address Valid
  input                             i_am_arready,      //Read Addr Path Slave Ready
                                                        //  1 = Slave Ready
                                                        //  0 = Slave Not Ready
    //bus read data
  input       [3:0]                 i_am_rid,          //Write ID
  input       [DATA_WIDTH - 1: 0]   i_am_rdata,        //Write Data (this size is set with the DATA_WIDTH Parameter
                                                    //Valid values are: 8, 16, 32, 64, 128, 256, 512, 1024
  input       [DATA_WIDTH >> 3:0]   i_am_rstrobe,      //Write Strobe (a 1 in the write is associated with the byte to write)
  input                             i_am_rlast,        //Write Last transfer in a write burst
  input                             i_am_rvalid,       //Data through this bus is valid
  output  reg                       o_am_rready,       //WBM is ready for data
                                                        //  1 = WBM Ready
                                                        //  0 = Slave Ready

  input     [INTERRUPT_WIDTH - 1:0] i_interrupts

);
//local parameters

//Address Map

localparam      CONTROL             = 5'h00;
localparam      STATUS              = 5'h01;
localparam      USER_INPUT          = 5'h02;
localparam      HCI_OPCODE_COUNT    = 5'h03;
localparam      HCI_OPCODE_ADDR     = 5'h04;
localparam      HCI_OPCODE          = 5'h05;
localparam      HCI_OPCODE_DATA     = 5'h06;
localparam      DMA_STATUS          = 5'h07;
localparam      REG_MEM_0_BASE      = 5'h08;
localparam      REG_MEM_0_SIZE      = 5'h09;
localparam      REG_MEM_1_BASE      = 5'h0A;
localparam      REG_MEM_1_SIZE      = 5'h0B;
localparam      REG_IMAGE_WIDTH     = 5'h0C;
localparam      REG_IMAGE_HEIGHT    = 5'h0D;


localparam      MAX_ADDR            = REG_IMAGE_HEIGHT;

//registers/wires

//User Interface
wire [ADDR_WIDTH - 1: 0]    w_reg_address;
reg                         r_reg_invalid_addr;

wire                        w_reg_in_rdy;
reg                         r_reg_in_ack_stb;
wire [DATA_WIDTH - 1: 0]    w_reg_in_data;

wire                        w_reg_out_req;
reg                         r_reg_out_rdy_stb;
reg [DATA_WIDTH - 1: 0]     r_reg_out_data;


//TEMP DATA, JUST FOR THE DEMO
reg [DATA_WIDTH - 1: 0]     r_temp_0;
reg [DATA_WIDTH - 1: 0]     r_temp_1;

//submodules

//Convert AXI Slave bus to a simple register/address strobe
axi_lite_slave #(
  .ADDR_WIDTH         (ADDR_WIDTH           ),
  .DATA_WIDTH         (DATA_WIDTH           )

) axi_lite_reg_interface (
  .clk                (clk                  ),
  .rst                (rst                  ),


  .i_awvalid          (i_awvalid            ),
  .i_awaddr           (i_awaddr             ),
  .o_awready          (o_awready            ),

  .i_wvalid           (i_wvalid             ),
  .o_wready           (o_wready             ),
  .i_wstrb            (i_wstrb              ),
  .i_wdata            (i_wdata              ),

  .o_bvalid           (o_bvalid             ),
  .i_bready           (i_bready             ),
  .o_bresp            (o_bresp              ),

  .i_arvalid          (i_arvalid            ),
  .o_arready          (o_arready            ),
  .i_araddr           (i_araddr             ),

  .o_rvalid           (o_rvalid             ),
  .i_rready           (i_rready             ),
  .o_rresp            (o_rresp              ),
  .o_rdata            (o_rdata              ),


  //Simple Register Interface
  .o_reg_address      (w_reg_address        ),
  .i_reg_invalid_addr (r_reg_invalid_addr   ),

  //Ingress Path (From Master)
  .o_reg_in_rdy       (w_reg_in_rdy         ),
  .i_reg_in_ack_stb   (r_reg_in_ack_stb     ),
  .o_reg_in_data      (w_reg_in_data        ),

  //Egress Path (To Master)
  .o_reg_out_req      (w_reg_out_req        ),
  .i_reg_out_rdy_stb  (r_reg_out_rdy_stb    ),
  .i_reg_out_data     (r_reg_out_data       )
);

//asynchronous logic

//synchronous logic
always @ (posedge clk) begin
  //De-assert Strobes
  r_reg_in_ack_stb                        <=  0;
  r_reg_out_rdy_stb                       <=  0;
  r_reg_invalid_addr                      <=  0;

  if (rst) begin
    r_reg_out_data                        <=  0;

    //Reset the temporary Data
    r_temp_0                              <=  0;
    r_temp_1                              <=  0;
  end
  else begin

    if (w_reg_in_rdy) begin
      //From master
      case (w_reg_address)
        ADDR_0: begin
          //$display("Incomming data on address: 0x%h: 0x%h", w_reg_address, w_reg_in_data);
          r_temp_0                        <=  w_reg_in_data;
        end
        ADDR_1: begin
          //$display("Incomming data on address: 0x%h: 0x%h", w_reg_address, w_reg_in_data);
          r_temp_1                        <=  w_reg_in_data;
        end
        default: begin
          $display ("Unknown address: 0x%h", w_reg_address);
        end
      endcase
      if (w_reg_address > MAX_ADDR) begin
        //Tell the host they wrote to an invalid address
        r_reg_invalid_addr                <= 1;
      end
      //Tell the AXI Slave Control we're done with the data
      r_reg_in_ack_stb                    <= 1;
    end
    else if (w_reg_out_req) begin
      //To master
      //$display("User is reading from address 0x%0h", w_reg_address);
      case (w_reg_address)
        ADDR_0: begin
          r_reg_out_data                  <= r_temp_0;
        end
        ADDR_1: begin
          r_reg_out_data                  <= r_temp_1;
        end
        default: begin
          //Unknown address
          r_reg_out_data                  <= 32'h00;
        end
      endcase
      if (w_reg_address > MAX_ADDR) begin
        //Tell the host they are reading from an invalid address
        r_reg_invalid_addr                <= 1;
      end
      //Tell the AXI Slave to send back this packet
      r_reg_out_rdy_stb                   <= 1;
    end
  end
end

endmodule
