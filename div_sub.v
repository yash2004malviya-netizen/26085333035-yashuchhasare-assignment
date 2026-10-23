// =============================================================================
// File    : div_sub.v  (ASSIGNMENT: the body is yours)
// Name    : Saicharan Malyala (Roll No: 260850333016)
//
// Spec    : q = a / b and r = a % b for 8-bit unsigned a and b, by repeated
//           subtraction: subtract b from what is left of a until it is smaller
//           than b; count the subtractions. b >= 1 is guaranteed.
//           Arithmetic allowed: one subtractor, one comparator, one incrementer.
//
// Interface (fixed; tb_div_sub.v connects to these names)
//   start   looked at only while the machine is idle; the testbench raises it
//           for one cycle. The edge that samples it is edge 0.
//   a, b    read at edge 0 only; they may change afterwards
//   done    1 for exactly one cycle, q + 1 edges after edge 0; q and r are
//           valid during that cycle
//
// The method is the recipe (assignment.md, section 4): registers, transfers,
//   status signal, state diagram and the per-cycle table on paper first; then
//   the four blocks in the order of d8_mult_add/mult_add.v, the model for the shape.
// =============================================================================
`timescale 1ns/1ps
`default_nettype none

module div_sub (
    input  wire       clk,
    input  wire       rst,       // synchronous, active-high
    input  wire       start,     // sampled while idle
    input  wire [7:0] a,         // dividend
    input  wire [7:0] b,         // divisor, >= 1
    output wire       done,      // one cycle: q and r are valid
    output wire [7:0] q,         // quotient
    output wire [7:0] r          // remainder
);

    localparam [1:0] IDLE = 2'd0,
                     RUN  = 2'd1,
                     DONE = 2'd2;

    reg [1:0] state, next_state;
    reg [7:0] rem;               // remainder so far (initialized to dividend a)
    reg [7:0] breg;              // divisor b, held while input may change
    reg [7:0] quot;              // quotient count (number of subtractions)

    wire      rem_ge_breg;       // status: 1 if rem >= breg (can subtract again)
    reg       load, sub_step;    // control signals

    // 1. state register
    always @(posedge clk) begin
        if (rst) state <= IDLE;
        else     state <= next_state;
    end

    // 2. next state and control signals (defaults first)
    always @(*) begin
        next_state = state;
        load       = 1'b0;
        sub_step   = 1'b0;
        case (state)
            IDLE: begin
                if (start) begin
                    load       = 1'b1;
                    next_state = RUN;
                end
            end
            RUN: begin
                if (rem_ge_breg) begin
                    sub_step = 1'b1;
                end else begin
                    next_state = DONE;
                end
            end
            DONE: begin
                next_state = IDLE;
            end
            default: next_state = IDLE;
        endcase
    end

    // 3. datapath registers: written here only
    always @(posedge clk) begin
        if (rst) begin
            rem  <= 8'd0;
            breg <= 8'd0;
            quot <= 8'd0;
        end else if (load) begin
            rem  <= a;
            breg <= b;
            quot <= 8'd0;
        end else if (sub_step) begin
            rem  <= rem - breg;
            quot <= quot + 8'd1;
        end
    end

    // 4. status and outputs
    assign rem_ge_breg = (rem >= breg);
    assign done        = (state == DONE);  // Moore: depends on state only
    assign q           = quot;
    assign r           = rem;

endmodule

`default_nettype wire
