module digital_parking (
    input  wire       clk,
    input  wire       reset,
    input  wire       entry_req,
    input  wire       exit_req,
    output reg  [3:0] occupied,
    output wire [3:0] available,
    output wire       full,
    output wire       empty,
    output reg        entry_grant,
    output reg        exit_grant
);
    localparam [3:0] CAPACITY = 4'd8;
    wire allow_exit;
    wire allow_entry;

    assign full = (occupied == CAPACITY);
    assign empty = (occupied == 4'd0);
    assign available = CAPACITY - occupied;
    assign allow_exit = exit_req && !empty;
    assign allow_entry = entry_req && (!full || allow_exit);

    always @(posedge clk) begin
        if (reset) begin
            occupied <= 4'd0;
            entry_grant <= 1'b0;
            exit_grant <= 1'b0;
        end else begin
            entry_grant <= allow_entry;
            exit_grant <= allow_exit;
            case ({allow_entry, allow_exit})
                2'b10: occupied <= occupied + 4'd1;
                2'b01: occupied <= occupied - 4'd1;
                default: occupied <= occupied;
            endcase
        end
    end
endmodule
