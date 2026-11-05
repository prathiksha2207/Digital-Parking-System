`timescale 1ns/1ps
module tb_digital_parking;
    reg clk = 0;
    reg reset = 0;
    reg entry_req = 0;
    reg exit_req = 0;
    wire [3:0] occupied, available;
    wire full, empty, entry_grant, exit_grant;
    integer reference_count = 0;
    integer checks = 0;
    integer level, pair, fill;

    digital_parking dut (
        .clk(clk), .reset(reset),
        .entry_req(entry_req), .exit_req(exit_req),
        .occupied(occupied), .available(available),
        .full(full), .empty(empty),
        .entry_grant(entry_grant), .exit_grant(exit_grant)
    );
    always #5 clk = ~clk;

    task cycle;
        input rst, ent, ext;
        input verbose;
        integer expected_entry, expected_exit;
        begin
            @(negedge clk);
            reset = rst;
            entry_req = ent;
            exit_req = ext;
            expected_entry = 0;
            expected_exit = 0;
            if (rst) reference_count = 0;
            else begin
                case ({ent, ext})
                    2'b01: if (reference_count > 0) begin
                        reference_count = reference_count - 1;
                        expected_exit = 1;
                    end
                    2'b10: if (reference_count < 8) begin
                        reference_count = reference_count + 1;
                        expected_entry = 1;
                    end
                    2'b11: begin
                        expected_entry = 1;
                        if (reference_count == 0)
                            reference_count = 1;
                        else expected_exit = 1;
                    end
                endcase
            end
            @(posedge clk); #1;
            if (occupied !== reference_count[3:0] ||
                available !== (4'd8 - reference_count[3:0]) ||
                full !== (reference_count == 8) ||
                empty !== (reference_count == 0) ||
                entry_grant !== (expected_entry != 0) ||
                exit_grant !== (expected_exit != 0) ||
                occupied > 8)
                $fatal(1, "FAIL check=%0d expected=%0d got=%0d",
                       checks + 1, reference_count, occupied);
            checks = checks + 1;
            if (verbose)
                $display("%0t rst=%b in=%b out=%b used=%0d free=%0d full=%b empty=%b grants=%b%b",
                         $time, reset, entry_req, exit_req,
                         occupied, available, full, empty,
                         entry_grant, exit_grant);
        end
    endtask

    initial begin
        $dumpfile("dump.vcd");
        $dumpvars(0, tb_digital_parking);
        $display("DIGITAL PARKING SYSTEM - CAPACITY 8");
        cycle(1, 0, 0, 1);
        cycle(0, 0, 1, 1);
        cycle(0, 1, 1, 1);
        cycle(0, 0, 0, 1);
        for (fill = 0; fill < 7; fill = fill + 1)
            cycle(0, 1, 0, 1);
        cycle(0, 1, 0, 1);
        cycle(0, 1, 1, 1);
        for (fill = 0; fill < 8; fill = fill + 1)
            cycle(0, 0, 1, 1);
        cycle(0, 0, 1, 1);
        cycle(0, 1, 0, 1);
        cycle(1, 1, 1, 1);
        cycle(1, 0, 0, 0);

        for (level = 0; level <= 8; level = level + 1)
            for (pair = 0; pair < 4; pair = pair + 1) begin
                cycle(1, 0, 0, 0);
                for (fill = 0; fill < level; fill = fill + 1)
                    cycle(0, 1, 0, 0);
                cycle(0, pair[1], pair[0], 0);
            end
        cycle(0, 0, 0, 0);
        $display("PASS: all 36 occupancy/request combinations");
        $display("PASS: reset, full, empty, replacement and idle");
        $display("PASS: %0d checked clock cycles", checks);
        $display("ALL TESTS PASSED");
        $finish;
    end
endmodule
