// =============================================================================
// File    : tb_div_sub.v  (ASSIGNMENT: run this against your div_sub.v)
// DUT     : div_sub (div_sub.v), ports as listed there
//
// What it does
//   Eight divisions. For each: a and b on the inputs, start for one cycle
//   (on a falling edge), then it waits for done, counting rising edges
//   from the edge that sampled start. At done it compares q and r with the
//   simulator's own / and % (the model) and prints one line. If done does
//   not come within 600 edges it says so and goes on to the next pair, so
//   an empty div_sub.v does not hang the simulation.
//
// Expected output with a correct div_sub.v (xsim and Icarus; $finish at 3260 ns)
//   a=  7 b=  2 q=  3 r=  1 (model q=  3 r=  1) done after   4 edges ok
//   a=100 b=  7 q= 14 r=  2 (model q= 14 r=  2) done after  15 edges ok
//   a=255 b=  1 q=255 r=  0 (model q=255 r=  0) done after 256 edges ok
//   a=  0 b=  5 q=  0 r=  0 (model q=  0 r=  0) done after   1 edges ok
//   a=  5 b=  9 q=  0 r=  5 (model q=  0 r=  5) done after   1 edges ok
//   a=200 b=200 q=  1 r=  0 (model q=  1 r=  0) done after   2 edges ok
//   a=255 b= 16 q= 15 r= 15 (model q= 15 r= 15) done after  16 edges ok
//   a= 37 b=  3 q= 12 r=  1 (model q= 12 r=  1) done after  13 edges ok
//   tb_div_sub: 8 divisions, 0 mismatches -> PASS; done after q+1 edges on 8 of 8
//
// The edge counts are the latency the assignment requires: q subtractions,
//   then one edge to see that nothing is left. The verdict line counts the
//   mismatches (PASS needs 0) and, separately, the divisions done in q + 1
//   edges; the assignment requires 8 of 8.
// =============================================================================
`timescale 1ns/1ps
`default_nettype none

module tb_div_sub;
    reg        clk, rst, start;
    reg  [7:0] a, b;
    wire       done;
    wire [7:0] q, r;
    integer    edges, divisions, errors, on_time;

    div_sub dut (.clk(clk), .rst(rst), .start(start), .a(a), .b(b), .done(done), .q(q), .r(r));

    initial clk = 1'b0;
    always #5 clk = ~clk;

    task divide;
        input [7:0] ta, tb;
        reg   [7:0] mq, mr;
        begin
            mq = ta / tb; mr = ta % tb;              // the model
            @(negedge clk);
            a = ta; b = tb; start = 1'b1;
            @(negedge clk);                          // edge 0 sampled start
            start = 1'b0;
            edges = 0;
            while (done !== 1'b1 && edges < 600) begin
                @(posedge clk); #1;
                edges = edges + 1;
            end
            divisions = divisions + 1;
            if (done !== 1'b1) begin
                errors = errors + 1;
                $display("a=%3d b=%3d: done never came (600 edges) FAIL", ta, tb);
            end else begin
                if (q !== mq || r !== mr) errors = errors + 1;
                if (edges == mq + 1) on_time = on_time + 1;
                $display("a=%3d b=%3d q=%3d r=%3d (model q=%3d r=%3d) done after %3d edges %0s",
                         ta, tb, q, r, mq, mr, edges, (q === mq && r === mr) ? "ok" : "WRONG");
            end
            @(negedge clk);                          // back to IDLE before the next start
        end
    endtask

    initial begin
        divisions = 0; errors = 0; on_time = 0; edges = 0;
        start = 1'b0; a = 8'd0; b = 8'd1;
        rst = 1'b1;
        repeat (2) @(negedge clk);
        rst = 1'b0;
        divide(8'd7,   8'd2);
        divide(8'd100, 8'd7);
        divide(8'd255, 8'd1);
        divide(8'd0,   8'd5);
        divide(8'd5,   8'd9);
        divide(8'd200, 8'd200);
        divide(8'd255, 8'd16);
        divide(8'd37,  8'd3);
        $display("tb_div_sub: %0d divisions, %0d mismatches -> %s; done after q+1 edges on %0d of %0d",
                 divisions, errors, (errors == 0) ? "PASS" : "FAIL", on_time, divisions);
        $finish;
    end
endmodule

`default_nettype wire
