

/***************************************************************************
 * Copyright (C) 2025 Intelligent System Architecture (ISA) Lab. All rights reserved. 
 * 
 * This file is written solely for academic use in AI Accelerator Design course assignment 
 * In School of Electrical and Electronics Engineering, Konkuk University 
 *
 * Unauthorized distribution is strictly prohibited.
 ***************************************************************************/
 
`timescale 1ns/1ns

// Behavioral memory 
module mem_behavior # (
    parameter firmware = "",
    parameter bitline = 16, 
    parameter bitaddr = 8, 
    parameter binary = 1 ) (
    input                   clk,
    input                   en,
    input                   we,
    input  [bitaddr-1:0]    addr,
    input  [bitline-1:0]    din,
    output [bitline-1:0]    dout
);
    reg                 test; 
    reg [bitline-1:0]   dout_;
    reg [bitline-1:0]   memory [2**bitaddr - 1:0];
    assign #1 dout = dout_;

    initial begin
        if (binary)
            $readmemb(firmware, memory);   
        else
            $readmemh(firmware, memory);
        test <= 1;
    end
 
    wire [bitline-1:0] memory_debug;
    assign memory_debug = memory[addr];
    
    always @ (posedge clk) begin
        if (we && en)
            memory[addr] <= din;
        if (~we && en)
            dout_ <= memory[addr];
        if (we && en)     
            test <= (memory[addr] == din);
    end
endmodule

// Import all modules from assignment_4.v
// Half Adder Module
module half_adder(
    input  a,
    input  b,
    output sum,
    output carry
);
    assign sum = a ^ b;
    assign carry = a & b;
endmodule

// Full Adder Module
module full_adder(
    input  a,
    input  b,
    input  cin,
    output sum,
    output carry
);
    assign sum = a ^ b ^ cin;
    assign carry = ((a ^ b) & cin) + (a & b);
endmodule

// 8-bit Ripple Carry Adder
module adder8(
    input  [7:0] A,
    input  [7:0] B,
    output [7:0] S,
    output       Cout
);
    wire [6:0] carry;
    half_adder HA0(.a(A[0]), .b(B[0]), .sum(S[0]), .carry(carry[0]));
    full_adder FA1(.a(A[1]), .b(B[1]), .cin(carry[0]), .sum(S[1]), .carry(carry[1]));
    full_adder FA2(.a(A[2]), .b(B[2]), .cin(carry[1]), .sum(S[2]), .carry(carry[2]));
    full_adder FA3(.a(A[3]), .b(B[3]), .cin(carry[2]), .sum(S[3]), .carry(carry[3]));
    full_adder FA4(.a(A[4]), .b(B[4]), .cin(carry[3]), .sum(S[4]), .carry(carry[4]));
    full_adder FA5(.a(A[5]), .b(B[5]), .cin(carry[4]), .sum(S[5]), .carry(carry[5]));
    full_adder FA6(.a(A[6]), .b(B[6]), .cin(carry[5]), .sum(S[6]), .carry(carry[6]));
    full_adder FA7(.a(A[7]), .b(B[7]), .cin(carry[6]), .sum(S[7]), .carry(Cout));
endmodule

// 16-bit Ripple Carry Adder
module adder16(
    input  [15:0] A,
    input  [15:0] B,
    output [15:0] S,
    output        Cout
);
    wire [15:0] carry;
    half_adder ha0 (.a(A[0]), .b(B[0]), .sum(S[0]), .carry(carry[0]));
    genvar i;
    generate
        for (i = 1; i < 16; i = i + 1) begin : full_adders
            full_adder fa (.a(A[i]), .b(B[i]), .cin(carry[i-1]), .sum(S[i]), .carry(carry[i]));
        end
    endgenerate
    assign Cout = carry[15];
endmodule

// 4-bit Signed Multiplier Module
module multiplier4( 
    input   [3:0] A,
    input   [3:0] B,
    output  [7:0] P
);
    wire signed [3:0] signed_A = A;
    wire signed [7:0] signedEx_A = {{4{signed_A[3]}}, signed_A};
    wire signed [7:0] result0, result1, result2, result3;
    wire signed [7:0] sum1, sum2, sum3;
    wire c1, c2, c3;

    assign result0 = {8{B[0]}} & signedEx_A;
    assign result1 = ({8{B[1]}} & signedEx_A) << 1;
    assign result2 = ({8{B[2]}} & signedEx_A) << 2;
    assign result3 = (({8{B[3]}} & signedEx_A) << 3) - (({4{B[3]}} & signedEx_A) << 4);

    adder8 add1(.A(result0), .B(result1), .S(sum1), .Cout(c1));
    adder8 add2(.A(sum1), .B(result2), .S(sum2), .Cout(c2));
    adder8 add3(.A(sum2), .B(result3), .S(sum3), .Cout(c3));
    assign P = sum3;
endmodule

// Unsigned 4-bit Multiplier
module multiplier4_unsigned(
    input   [3:0] A,
    input   [3:0] B,
    output  [7:0] P
);
    wire [7:0] multiplicand = {4'b0000, A};
    wire [7:0] partial0, partial1, partial2, partial3;
    wire [7:0] sum1, sum2, sum3;
    wire c1, c2, c3;

    assign partial0 = B[0] ? multiplicand : 8'b0;
    assign partial1 = B[1] ? (multiplicand << 1) : 8'b0;
    assign partial2 = B[2] ? (multiplicand << 2) : 8'b0;
    assign partial3 = B[3] ? (multiplicand << 3) : 8'b0;

    adder8 add1(.A(partial0), .B(partial1), .S(sum1), .Cout(c1));
    adder8 add2(.A(sum1), .B(partial2), .S(sum2), .Cout(c2));
    adder8 add3(.A(sum2), .B(partial3), .S(sum3), .Cout(c3));
    assign P = sum3;
endmodule

// Signed-Unsigned 4-bit Multiplier
module signed_unsigned_mul4 (
    input  [3:0] A,
    input  [3:0] B,
    output [7:0] P
);
    wire sign_A = A[3];
    wire [3:0] abs_A = (sign_A) ? (~A + 1'b1) : A;
    wire [3:0] unsigned_B = B;

    wire [7:0] partial0 = unsigned_B[0] ? {4'b0, abs_A} : 8'b0;
    wire [7:0] partial1 = unsigned_B[1] ? {3'b0, abs_A, 1'b0} : 8'b0;
    wire [7:0] partial2 = unsigned_B[2] ? {2'b0, abs_A, 2'b0} : 8'b0;
    wire [7:0] partial3 = unsigned_B[3] ? {1'b0, abs_A, 3'b0} : 8'b0;

    wire [7:0] sum1, sum2, unsigned_product;
    wire carry1, carry2, carry3;

    adder8 add1 (.A(partial0), .B(partial1), .S(sum1), .Cout(carry1));
    adder8 add2 (.A(sum1), .B(partial2), .S(sum2), .Cout(carry2));
    adder8 add3 (.A(sum2), .B(partial3), .S(unsigned_product), .Cout(carry3));
    assign P = (sign_A) ? (~unsigned_product + 1'b1) : unsigned_product;
endmodule

// Unsigned-Signed 4-bit Multiplier
module unsigned_signed_mul4 (
    input  [3:0] A,
    input  [3:0] B,
    output [7:0] P
);
    wire [3:0] unsigned_A = A;
    wire sign_B = B[3];
    wire [3:0] abs_B = (sign_B) ? (~B + 1'b1) : B;

    wire [7:0] partial0 = abs_B[0] ? {4'b0, unsigned_A} : 8'b0;
    wire [7:0] partial1 = abs_B[1] ? {3'b0, unsigned_A, 1'b0} : 8'b0;
    wire [7:0] partial2 = abs_B[2] ? {2'b0, unsigned_A, 2'b0} : 8'b0;
    wire [7:0] partial3 = abs_B[3] ? {1'b0, unsigned_A, 3'b0} : 8'b0;

    wire [7:0] sum1, sum2, unsigned_product;
    wire carry1, carry2, carry3;

    adder8 add1 (.A(partial0), .B(partial1), .S(sum1), .Cout(carry1));
    adder8 add2 (.A(sum1), .B(partial2), .S(sum2), .Cout(carry2));
    adder8 add3 (.A(sum2), .B(partial3), .S(unsigned_product), .Cout(carry3));
    assign P = (sign_B) ? (~unsigned_product + 1'b1) : unsigned_product;
endmodule

// 8-bit MAC Unit
module mac8(
    input               clk,
    input               rst,
    input               en,
    input   [7:0]       A,
    input   [7:0]       B,
    output reg          busy,
    output reg [15:0]   M
);
    localparam  IDLE    = 3'b000,
                LOAD1   = 3'b001,
                LOAD2   = 3'b010,
                LOAD3   = 3'b011,
                COMPUTE = 3'b100,
                DELAY1  = 3'b101,
                DELAY2  = 3'b110,
                DONE    = 3'b111;

    wire [7:0] signed_A = A;
    wire [7:0] signed_B = B;
    reg  [2:0] state;
    reg  [15:0] total;

    wire [3:0] A_high = signed_A[7:4];
    wire [3:0] A_low  = signed_A[3:0];
    wire [3:0] B_high = signed_B[7:4];
    wire [3:0] B_low  = signed_B[3:0];

    wire [7:0] out0, out1, out2, out3;
    reg  [7:0] out0_reg, out1_reg, out2_reg, out3_reg;

    wire [15:0] total0, total1, total2, totalAll;
    wire carry_total, c1, c2, cAll;

    multiplier4_unsigned mul0 (.A(A_low), .B(B_low), .P(out0));
    unsigned_signed_mul4 mul1 (.A(A_low), .B(B_high), .P(out1));
    signed_unsigned_mul4 mul2 (.A(A_high), .B(B_low), .P(out2));
    multiplier4 mul3 (.A(A_high), .B(B_high), .P(out3));

    wire [15:0] out0_ext = {{8'b0}, out0_reg};
    wire [15:0] out1_ext = {{4{out1_reg[7]}}, out1_reg, 4'b0};
    wire [15:0] out2_ext = {{4{out2_reg[7]}}, out2_reg, 4'b0};
    wire [15:0] out3_ext = {out3_reg, 8'b0};

    adder16 add0 (.A(total), .B(out0_ext), .S(total0), .Cout(carry_total));
    adder16 add1 (.A(total0), .B(out1_ext), .S(total1), .Cout(c1));
    adder16 add2 (.A(total1), .B(out2_ext), .S(total2), .Cout(c2));
    adder16 addAll (.A(total2), .B(out3_ext), .S(totalAll), .Cout(cAll));

    always @(posedge clk) begin
        if (rst) begin
            state <= IDLE;
            M <= 16'b0;
            total <= 16'b0;
            busy <= 1'b0;
        end else begin
            case (state)
                IDLE: begin
                    if (en) begin
                        busy <= 1'b1;
                        out0_reg <= out0;
                        state <= LOAD1;
                    end
                end
                LOAD1: begin
                    out1_reg <= out1;
                    state <= LOAD2;
                end
                LOAD2: begin
                    out2_reg <= out2;
                    state <= LOAD3;
                end
                LOAD3: begin
                    out3_reg <= out3;
                    state <= COMPUTE;
                end
                COMPUTE: begin
                    total <= totalAll;
                    M <= totalAll;
                    if (en) begin
                        out0_reg <= out0;
                        state <= LOAD1;
                    end else begin
                        busy <= 1'b0;
                        state <= DELAY1;
                    end
                end
                DELAY1: state <= DELAY2;
                DELAY2: state <= DONE;
                DONE: begin
                    state <= IDLE;
                    busy <= 1'b0;
                end
                default: state <= IDLE;
            endcase
        end
    end
endmodule

// 8-bit Systolic Element
module se8 (
    input               clk,
    input               rst,
    input       [7:0]   data_from_left,
    input       [15:0]  data_from_top,
    output reg  [7:0]   data_to_right,
    output reg  [15:0]  data_to_bottom,
    input       [6:0]   cycle_cnt,
    input               en,
    input               req_out
);
    wire [15:0] mac_result;
    wire        mac_busy;
    wire [7:0] _A = data_from_left;
    wire [7:0] _B = data_from_top[7:0];

    mac8 u_mac (
        .clk(clk),
        .rst(rst),
        .en(en),
        .A(_A),
        .B(_B),
        .busy(mac_busy),
        .M(mac_result)
    );

    always @(posedge clk) begin
        if (rst) begin
            data_to_right <= 8'd0;
            data_to_bottom <= 16'd0;
        end else begin
            if (en && (cycle_cnt % 4 == 0)) begin
                data_to_right <= data_from_left;
                data_to_bottom <= data_from_top;
            end
            if (req_out)
                data_to_bottom <= mac_result;
        end
    end
endmodule

// 4x4 8-bit Systolic Array
module sa8_4x4 (
    input                   clk,
    input                   rst,
    input                   en,
    input                   req_out,
    input       [8*4-1:0]   A,
    input       [8*4-1:0]   B,
    output  reg [16*4-1:0]  C,
    output  reg             busy
);
    reg [6:0] step_cnt;

    wire [7:0] a_row [0:3];
    wire [7:0] b_col [0:3];

    assign a_row[0] = A[31:24];
    assign a_row[1] = A[23:16];
    assign a_row[2] = A[15:8];
    assign a_row[3] = A[7:0];

    assign b_col[0] = B[31:24];
    assign b_col[1] = B[23:16];
    assign b_col[2] = B[15:8];
    assign b_col[3] = B[7:0];

    wire [7:0] a_to_right [0:3][0:3];
    wire [15:0] b_or_sum [0:3][0:3];
    
    always @(posedge clk) begin
        if (rst) begin
            step_cnt <= 6'd1;
            busy <= 1'b0;
        end
        if (en || step_cnt != 6'd1) begin
            if (step_cnt == 6'd47)
                step_cnt <= 6'd1;
            else
                step_cnt <= step_cnt + 6'd1;
        end
        busy <= (step_cnt != 6'd0) && (step_cnt < 6'd41);
    end

    genvar r, c;
    generate
        for (r = 0; r < 4; r = r + 1) begin : gen_rows
            for (c = 0; c < 4; c = c + 1) begin : gen_cols
                se8 pe_inst (
                    .clk(clk),
                    .rst(rst),
                    .data_from_left((c == 0) ? a_row[r] : a_to_right[r][c - 1]),
                    .data_from_top((r == 0) ? {8'b0, b_col[c]} : b_or_sum[r - 1][c]),
                    .data_to_right(a_to_right[r][c]),
                    .data_to_bottom(b_or_sum[r][c]),
                    .en((step_cnt >= (r + c) * 4 + 1) && (step_cnt <= (r + c) * 4 + 16)),
                    .req_out(req_out),
                    .cycle_cnt(step_cnt)
                );
            end
        end
    endgenerate

    always @(*) begin
        case (step_cnt)
            7'd43: C <= {b_or_sum[3][0], b_or_sum[3][1], b_or_sum[3][2], b_or_sum[3][3]};
            7'd44: C <= {b_or_sum[2][0], b_or_sum[2][1], b_or_sum[2][2], b_or_sum[2][3]};
            7'd45: C <= {b_or_sum[1][0], b_or_sum[1][1], b_or_sum[1][2], b_or_sum[1][3]};
            7'd46: C <= {b_or_sum[0][0], b_or_sum[0][1], b_or_sum[0][2], b_or_sum[0][3]};
            default: C <= {b_or_sum[3][0], b_or_sum[3][1], b_or_sum[3][2], b_or_sum[3][3]};
        endcase
    end
endmodule

// Controller for Systolic Array
module ctrl (
    input               clk,
    input               rst,
    input               run,
    output  reg [1:0]   state,
    output  reg         re_A,
    output  reg [5:0]   addr_A,
    input       [7:0]   data_A,
    output  reg         re_B,
    output  reg [5:0]   addr_B,
    input       [7:0]   data_B,
    output  reg         we_C,
    output  reg [5:0]   addr_C,
    output  reg [15:0]  data_C,
    output  reg         sa_en,
    output  reg         sa_req_out,
    input               sa_busy,
    output  reg [31:0]  sa_data_A,
    output  reg [31:0]  sa_data_B,
    input       [63:0]  sa_data_C
);
    localparam IDLE    = 2'b00,
               LOAD    = 2'b01,
               COMPUTE = 2'b10,
               WRITE   = 2'b11,
               LOAD_CYCLES = 19,
               COMP_CYCLES = 48,
               WRITE_CYCLES = 17;

    reg [1:0] row_idx, col_idx, depth_idx;
    reg [7:0] cycle_idx;
    reg [15:0] result_acc [0:3][0:3];
    reg [31:0] buf_a [0:6];
    reg [31:0] buf_b [0:6];

    wire load_done = (cycle_idx == LOAD_CYCLES - 1);
    wire comp_done = (cycle_idx == COMP_CYCLES - 1);
    wire write_done = (cycle_idx == WRITE_CYCLES - 1);

    integer r, c, n;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            cycle_idx <= 0;
            row_idx <= 0; col_idx <= 0; depth_idx <= 0;
            re_A <= 0; re_B <= 0; we_C <= 0;
            addr_A <= 0; addr_B <= 0; addr_C <= 0;
            sa_en <= 0; sa_req_out <= 0;
            state <= IDLE;
            for (r = 0; r < 4; r = r + 1) 
                for (c = 0; c < 4; c = c + 1)
                    result_acc[r][c] <= 0;
            for (n = 0; n < 7; n = n + 1) begin
                buf_a[n] = 32'd0;
                buf_b[n] = 32'd0;
            end
            sa_data_A <= 32'b0;
            sa_data_B <= 32'b0;
        end else begin
            case (state)
                IDLE: begin
                    if (run) begin
                        state <= LOAD;
                        row_idx <= 0; col_idx <= 0; depth_idx <= 0;
                        cycle_idx <= 0;
                        for (r = 0; r < 4; r = r + 1) 
                            for (c = 0; c < 4; c = c + 1)
                                result_acc[r][c] <= 0;
                        for (n = 0; n < 7; n = n + 1) begin
                            buf_a[n] = 32'd0;
                            buf_b[n] = 32'd0;
                        end
                        sa_data_A <= 32'b0;
                        sa_data_B <= 32'b0;
                    end
                end
                LOAD: begin
                    cycle_idx <= cycle_idx + 1;
                    if (!load_done) begin
                        re_A <= 1; re_B <= 1;
                        // Standard address calculation for A (weight matrix)
                        addr_A <= (row_idx * 4 + cycle_idx / 4) * 8 + (depth_idx * 4 + cycle_idx % 4);
                        // For B, use standard calculation - address translation happens outside
                        addr_B <= (depth_idx * 4 + cycle_idx % 4) * 8 + (col_idx * 4 + cycle_idx / 4);
                        if (cycle_idx >= 2 && cycle_idx <= 17) begin
                            buf_a[(cycle_idx - 2) % 4 + (cycle_idx - 2) / 4][31 - ((cycle_idx - 2) / 4) * 8 -: 8] <= data_A;
                            buf_b[(cycle_idx - 2) % 4 + (cycle_idx - 2) / 4][31 - ((cycle_idx - 2) / 4) * 8 -: 8] <= data_B;
                        end
                    end else begin
                        addr_A <= 0; addr_B <= 0;
                        re_A <= 0; re_B <= 0;
                        cycle_idx <= 0;
                        state <= COMPUTE;
                    end
                end
                COMPUTE: begin
                    cycle_idx <= cycle_idx + 1;
                    sa_en <= 1'b0;
                    sa_req_out <= 1'b0;
                    if (!comp_done) begin
                        if (cycle_idx < 17 && (cycle_idx == 0 || cycle_idx == 4 || cycle_idx == 8 || cycle_idx == 12)) begin
                            sa_en <= 1'b1;
                        end else if (cycle_idx == 41) begin
                            sa_req_out <= 1'b1;
                        end else if (cycle_idx > 41 && cycle_idx <= 46) begin
                            for (n = 0; n < 4; n = n + 1)
                                result_acc[cycle_idx - 43][n] <= sa_data_C[n * 16 +: 16];
                        end else begin
                            sa_en <= 1'b0;
                            sa_req_out <= 1'b0;
                        end
                        if (cycle_idx < 7 * 4 && cycle_idx[1:0] <= 2'b11) begin 
                            sa_data_A <= buf_a[cycle_idx / 4];
                            sa_data_B <= buf_b[cycle_idx / 4];
                        end  
                    end else begin
                        cycle_idx <= 0;
                        sa_data_A <= 32'b0;
                        sa_data_B <= 32'b0;
                        if (depth_idx == 1) state <= WRITE;
                        else begin
                            depth_idx <= depth_idx + 1;
                            state <= LOAD;
                        end
                    end
                end
                WRITE: begin
                    cycle_idx <= cycle_idx + 1;
                    if (!write_done) begin
                        we_C <= 1;
                        // Standard address calculation - translation happens outside
                        addr_C <= (row_idx * 4 + cycle_idx / 4) * 8 + col_idx * 4 + (cycle_idx % 4);
                        data_C <= result_acc[3 - (cycle_idx) / 4][3 - (cycle_idx) % 4];
                    end else begin
                        we_C <= 0;
                        cycle_idx <= 0;
                        if (col_idx == 1) begin
                            if (row_idx == 1) state <= IDLE;
                            else begin
                                row_idx <= row_idx + 1;
                                col_idx <= 0;
                                depth_idx <= 0;
                                for (r = 0; r < 4; r = r + 1)
                                    for (c = 0; c < 4; c = c + 1)
                                        result_acc[r][c] <= 0;
                                state <= LOAD;
                            end
                        end else begin
                            col_idx <= col_idx + 1;
                            depth_idx <= 0;
                            for (r = 0; r < 4; r = r + 1)
                                for (c = 0; c < 4; c = c + 1)
                                    result_acc[r][c] <= 0;
                            state <= LOAD;
                        end
                    end
                end
            endcase
        end
    end
endmodule

// Matrix Multiplication Module using Systolic Array
module matmul_sa (
    input               clk,
    input               rst,
    input               run,
    output      [1:0]   state,
    output              re_A,
    output      [5:0]   addr_A,
    input       [7:0]   data_A,
    output              re_B,
    output      [5:0]   addr_B,
    input       [7:0]   data_B,
    output              we_C,
    output      [5:0]   addr_C,
    output      [15:0]  data_C
);
    wire    [1:0]   state_;
    wire            re_A_, re_B_, we_C_;
    wire    [5:0]   addr_A_, addr_B_, addr_C_;
    wire    [15:0]  data_C_;
    reg             we_C_delay;
    
    wire         sa_en, sa_req_out, sa_busy;
    wire   [31:0]   sa_data_A, sa_data_B;
    wire   [63:0]   sa_data_C;
    wire            sa_local_rst;

    assign state = state_;
    assign re_A = re_A_; 
    assign re_B = re_B_; 
    assign we_C = we_C_;
    assign addr_A = addr_A_; 
    assign addr_B = addr_B_; 
    assign addr_C = addr_C_;
    assign data_C = data_C_;
    
    always @ (posedge clk) begin
        if (rst) we_C_delay <= 0;
        else we_C_delay <= we_C_;
    end
    assign sa_local_rst = we_C_ && ~we_C_delay;

    ctrl U_ctrl (
        .clk(clk), .rst(rst), .run(run), .state(state_),
        .re_A(re_A_), .addr_A(addr_A_), .data_A(data_A),
        .re_B(re_B_), .addr_B(addr_B_), .data_B(data_B),
        .we_C(we_C_), .addr_C(addr_C_), .data_C(data_C_),
        .sa_en(sa_en), .sa_req_out(sa_req_out), .sa_busy(sa_busy),
        .sa_data_A(sa_data_A), .sa_data_B(sa_data_B), .sa_data_C(sa_data_C)
    );

    sa8_4x4 U_sa (
        .clk(clk), .rst(rst || sa_local_rst), .en(sa_en), .req_out(sa_req_out), .busy(sa_busy),
        .A(sa_data_A), .B(sa_data_B), .C(sa_data_C)
    );              
endmodule

//==============================
// Norm Layer: Divide input by 32 (arithmetic right shift by 5)
//==============================
module norm_layer (
    input               clk,
    input               rst,
    input               en,
    input       [15:0]  din,
    output reg  [7:0]   dout,
    output reg          valid
);
    always @(posedge clk) begin
        if (rst) begin
            dout <= 8'd0;
            valid <= 1'b0;
        end else if (en) begin
            // Divide input by 32 and output lower 8 bits
            dout <= din[12:5];  
            valid <= 1'b1;
        end else begin
            valid <= 1'b0;
        end
    end
endmodule

//==============================
// ReLU Layer: Output max(0, din)
//==============================
module relu_layer (
    input               clk,
    input               rst,
    input               en,
    input       [7:0]   din,
    output reg  [7:0]   dout,
    output reg          valid
);
    always @(posedge clk) begin
        if (rst) begin
            dout <= 8'd0;
            valid <= 1'b0;
        end else if (en) begin
            // If input is negative (MSB=1), output 0; else output input
            dout <= din[7] ? 8'd0 : din;
            valid <= 1'b1;
        end else begin
            valid <= 1'b0;
        end
    end
endmodule

//==============================
// nn_accelerator: Main Controller (2-layer NN with batch support)
//==============================
module nn_accelerator (
    input               clk,
    input               rst,
    input               run,
    input               batch_mode,    
    output reg  [3:0]   state,         
    output              busy,          

    output              re_X,
    output      [6:0]   addr_X,        
    input       [7:0]   data_X,

    output              re_W1,
    output      [5:0]   addr_W1,
    input       [7:0]   data_W1,

    output              re_W2,
    output      [5:0]   addr_W2,
    input       [7:0]   data_W2,

    input               re_Y_ext,
    input       [6:0]   addr_Y_ext,
    output      [15:0]  data_Y
);
    // FSM state
    localparam  IDLE        = 4'b0000,
                FC1_EXEC    = 4'b0001,
                NORM_EXEC   = 4'b0010,
                RELU_EXEC   = 4'b0011,
                FC2_EXEC    = 4'b0100,
                WRITE_OUT   = 4'b0101,
                DONE        = 4'b0110;

    // Memory interface signals
    reg  we_mem1, re_mem1; reg [6:0] addr_mem1; reg [15:0] din_mem1; wire [15:0] dout_mem1;
    reg  we_mem2, re_mem2; reg [6:0] addr_mem2; reg [7:0]  din_mem2; wire [7:0]  dout_mem2;
    reg  we_mem3, re_mem3; reg [6:0] addr_mem3; reg [7:0]  din_mem3; wire [7:0]  dout_mem3;

    // FC1, FC2, NORM, RELU modele interface signals
    wire [1:0] fc1_state, fc2_state; wire fc1_busy, fc2_busy;
    wire fc1_re_A, fc1_re_B, fc1_we_C; wire [5:0] fc1_addr_A, fc1_addr_B, fc1_addr_C; wire [15:0] fc1_data_C;
    wire fc2_re_A, fc2_re_B, fc2_we_C; wire [5:0] fc2_addr_A, fc2_addr_B, fc2_addr_C; wire [15:0] fc2_data_C;
    wire norm_valid, relu_valid; wire [7:0] norm_dout, relu_dout;

    // Internal controller signals 
    reg         norm_read_done, relu_read_done;
    reg         norm_en, relu_en;
    reg [6:0]   elem_cnt;         // index 
    reg [1:0]   batch_cnt;        // batch iteration count
    reg         fc1_run, fc2_run;
    wire [2:0]  y_row, y_col;
    wire [5:0]  y_elem;

    // if state is not IDLE/DONE, busy
    assign busy     = (state != IDLE) && (state != DONE);

    // External memory port assignment (mux)
    assign re_W1    = (state == FC1_EXEC) ? fc1_re_A : 1'b0;
    assign addr_W1  = fc1_addr_A;
    assign re_W2    = (state == FC2_EXEC) ? fc2_re_A : 1'b0;
    assign addr_W2  = fc2_addr_A;
    assign re_X     = (state == FC1_EXEC) ? fc1_re_B : 1'b0;

    // Batch addressing for X input
    assign addr_X   = (state == FC1_EXEC) ? (batch_mode ? (fc1_addr_B[5:3] * 16 + fc1_addr_B[2:0] + (batch_cnt * 8)) : {1'b0, fc1_addr_B}) : 7'd0;
    assign data_Y   = dout_mem1;

    // FC1 -> NORM -> RELU -> FC2 input / output intermediate buffers
    mem_behavior #("", 16, 7, 1) U_mem_X1 (
        .clk(clk), .en(we_mem1 || re_mem1), .we(we_mem1),
        .addr(addr_mem1), .din(din_mem1), .dout(dout_mem1)
    );
    mem_behavior #("", 8, 7, 1)  U_mem_X2 (
        .clk(clk), .en(we_mem2 || re_mem2), .we(we_mem2),
        .addr(addr_mem2), .din(din_mem2), .dout(dout_mem2)
    );
    mem_behavior #("", 8, 7, 1)  U_mem_X3 (
        .clk(clk), .en(we_mem3 || re_mem3), .we(we_mem3),
        .addr(addr_mem3), .din(din_mem3), .dout(dout_mem3)
    );

    // Normalization & ReLU modules
    norm_layer U_norm (
        .clk(clk), .rst(rst), .en(norm_en),
        .din(dout_mem1), .dout(norm_dout), .valid(norm_valid)
    );
    relu_layer U_relu (
        .clk(clk), .rst(rst), .en(relu_en),
        .din(dout_mem2), .dout(relu_dout), .valid(relu_valid)
    );

    // Matmul systolic array modules for FC1, FC2
    matmul_sa U_FC1 (
        .clk(clk), .rst(rst), .run(fc1_run), .state(fc1_state),
        .re_A(fc1_re_A), .addr_A(fc1_addr_A), .data_A(data_W1),
        .re_B(fc1_re_B), .addr_B(fc1_addr_B), .data_B(data_X),
        .we_C(fc1_we_C), .addr_C(fc1_addr_C), .data_C(fc1_data_C)
    );
    matmul_sa U_FC2 (
        .clk(clk), .rst(rst), .run(fc2_run), .state(fc2_state),
        .re_A(fc2_re_A), .addr_A(fc2_addr_A), .data_A(data_W2),
        .re_B(fc2_re_B), .addr_B(fc2_addr_B), .data_B(dout_mem3),
        .we_C(fc2_we_C), .addr_C(fc2_addr_C), .data_C(fc2_data_C)
    );

    // Memory read logic for FC2 input
    always @(*) begin
        if (state == FC2_EXEC && fc2_re_B) begin
            re_mem3   <= 1'b1;
            addr_mem3 <= (batch_mode ? ((fc2_addr_B / 8) * 16 + (fc2_addr_B % 8) + (batch_cnt * 8)) : {1'b0, fc2_addr_B});
        end else begin
            re_mem3   <= 1'b0;
            addr_mem3 <= 7'd0;
        end
    end

    // External output read interface 
    always @(posedge clk) begin
        if(re_Y_ext) begin
            addr_mem1 <= addr_Y_ext;
            re_mem1   <= 1'b1;
        end else begin
            re_mem1   <= 1'b0;
        end
    end

    //============================================================
    // FSM: Orchestrates each pipeline stage and buffer
    //============================================================
    always @(posedge clk) begin
        if (rst) begin
            // reset all control registers and state variables
            state           <= IDLE;
            fc1_run         <= 1'b0;
            fc2_run         <= 1'b0;
            norm_en         <= 1'b0;
            relu_en         <= 1'b0;
            elem_cnt        <= 7'd0;
            batch_cnt       <= 2'd0;
            we_mem1         <= 1'b0;
            re_mem1         <= 1'b0;
            we_mem2         <= 1'b0;
            re_mem2         <= 1'b0;
            we_mem3         <= 1'b0;
            norm_read_done  <= 1'b0;
            relu_read_done  <= 1'b0;
        end else begin
            case (state)
                // IDLE: wait for run signal
                IDLE: begin
                    if (run) begin
                        state     <= FC1_EXEC;
                        batch_cnt <= 2'd0;
                        fc1_run   <= 1'b1;
                    end
                end

                // FC1_EXEC: run first FC1 layerm store result to mem1
                FC1_EXEC: begin
                    fc1_run <= 1'b0;
                    if (fc1_we_C) begin
                        we_mem1   <= 1'b1;
                        addr_mem1 <= batch_mode ? ((fc1_addr_C / 8) * 16 + (fc1_addr_C % 8) + (batch_cnt * 8))
                                                : {1'b0, fc1_addr_C};
                        din_mem1  <= fc1_data_C;
                    end else we_mem1   <= 1'b0;
                    // move to norm stage after FC1 done
                    if (fc1_state == 2'b00 && !fc1_run) begin
                        state           <= NORM_EXEC;
                        elem_cnt        <= 7'd0;
                        norm_read_done  <= 1'b0;
                    end
                end

                // NORM_EXEC: read from mem1, apply normalization, store result to mem2
                NORM_EXEC: begin
                    if (!norm_read_done) begin
                        if (elem_cnt < 66) begin
                            re_mem1   <= 1'b1;
                            addr_mem1 <= batch_mode ? ((elem_cnt / 8) * 16 + (elem_cnt % 8) + (batch_cnt * 8))
                                                    : elem_cnt;
                            norm_en   <= 1'b1;
                            elem_cnt  <= elem_cnt + 1;
                        end else begin
                            re_mem1        <= 1'b0;
                            norm_en        <= 1'b0;
                            norm_read_done <= 1'b1;
                            elem_cnt       <= 7'd0;
                        end
                    end

                    // save normalized output to mem2
                    if (norm_valid && elem_cnt >= 3) begin
                        we_mem2   <= 1'b1;
                        addr_mem2 <= batch_mode ? (((elem_cnt - 3) / 8) * 16 + ((elem_cnt - 3) % 8) + (batch_cnt * 8))
                                                : (elem_cnt - 3);
                        din_mem2  <= norm_dout;
                    end else we_mem2   <= 1'b0;
                    // move to relu stage after norm done
                    if (norm_read_done && !norm_valid && elem_cnt == 0) begin
                        state           <= RELU_EXEC;
                        elem_cnt        <= 7'd0;
                        relu_read_done  <= 1'b0;
                    end
                end

                // RELU_EXEC: read from mem2, apply ReLU, store result to mem3
                RELU_EXEC: begin
                    if (!relu_read_done) begin
                        if (elem_cnt < 66) begin
                            re_mem2   <= 1'b1;
                            addr_mem2 <= batch_mode ? ((elem_cnt / 8) * 16 + (elem_cnt % 8) + (batch_cnt * 8))
                                                   : elem_cnt;
                            relu_en   <= 1'b1;
                            elem_cnt  <= elem_cnt + 1;
                        end else begin
                            re_mem2        <= 1'b0;
                            relu_en        <= 1'b0;
                            relu_read_done <= 1'b1;
                            elem_cnt       <= 7'd0;
                        end
                    end

                    // save relu output to mem3
                    if (relu_valid && elem_cnt >= 3) begin
                        we_mem3   <= 1'b1;
                        addr_mem3 <= batch_mode ? (((elem_cnt - 3) / 8) * 16 + ((elem_cnt - 3) % 8) + (batch_cnt * 8))
                                                : (elem_cnt - 3);
                        din_mem3  <= relu_dout;
                    end else we_mem3   <= 1'b0;
                    // move to FC2 after relu done
                    if (relu_read_done && !relu_valid && elem_cnt == 0) begin
                        state      <= FC2_EXEC;
                        fc2_run    <= 1'b1;
                    end
                end

                // FC2_EXEC: run second FC2 layer, store result to mem1 (overwrite, reuse memory)
                FC2_EXEC: begin
                    fc2_run <= 1'b0;
                    if (fc2_we_C) begin
                        we_mem1   <= 1'b1;
                        addr_mem1 <= batch_mode ? ((fc2_addr_C / 8) * 16 + (fc2_addr_C % 8) + (batch_cnt * 8))
                                                : {1'b0, fc2_addr_C};
                        din_mem1  <= fc2_data_C;
                    end else we_mem1   <= 1'b0;
                    // move to write-out stage after FC2 done
                    if (fc2_state == 2'b00 && !fc2_run) begin
                        state    <= WRITE_OUT;
                        elem_cnt <= 7'd0;
                    end
                end

                // WRITE_OUT: sequentially read final result from mem1
                WRITE_OUT: begin
                    if (elem_cnt < 68) begin  // Read 64 elements + 2 cycle delay
                        if (elem_cnt >= 0) begin
                            re_mem1   <= 1'b1;
                            addr_mem1 <= batch_mode ? (((elem_cnt) / 8) * 16 + ((elem_cnt) % 8) + (batch_cnt * 8))
                                                    : elem_cnt;
                        end
                        elem_cnt <= elem_cnt + 1;
                    end else begin
                        re_mem1  <= 1'b0;
                        elem_cnt <= 7'd0;

                        // if 16-batch, go back to FC1 for the next batch, 
                        // else, go to DONE and end
                        if (batch_mode == 1'b1 && batch_cnt == 2'd0) begin
                            batch_cnt <= 2'd1;
                            state     <= FC1_EXEC;
                            fc1_run   <= 1'b1;
                        end else state <= DONE;
                    end
                end

                // DONE: return to IDLE after inference complete
                DONE:    state <= IDLE;
                default: state <= IDLE;
            endcase
        end
    end

endmodule
