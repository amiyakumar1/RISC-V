module plru #(
)(
    input logic clk0,
    input logic rst0,
    input logic csb0,
    input logic web0,
    input logic [1:0] din0,
    output logic [1:0] dout0
);

    logic [2:0] decision_array;
    logic [2:0] next_decision;

    /*
            2
           / \
          1   0
         / \ / \
    */

    // combinational logic to deal with reads from plru tree, ie if we want to get the lru way
    // plru tree only updated on hits in cache r/w state
    always_comb begin
        if (decision_array[2] == 1'b0) begin
            if (decision_array[1] == 1'b0) dout0 = 2'b00;
            else dout0 = 2'b01;
        end else begin
            if (decision_array[0] == 1'b0) dout0 = 2'b10;
            else dout0 = 2'b11;
        end
    end

    // combinational logic to deal with writes to plru tree, ie if we access a way on a hit. the tree should update
    always_comb begin
        case (decision_array)
            3'b000 : begin
                case(din0)
                    2'b00 : next_decision = 3'b110;
                    2'b01 : next_decision = 3'b100;
                    2'b10 : next_decision = 3'b001;
                    2'b11 : next_decision = 3'b000;
                endcase
            end
            3'b001 : begin
                case(din0)
                    2'b00 : next_decision = 3'b111;
                    2'b01 : next_decision = 3'b101;
                    2'b10 : next_decision = 3'b001;
                    2'b11 : next_decision = 3'b000;
                endcase
            end
            3'b010 : begin
                case(din0)
                    2'b00 : next_decision = 3'b110;
                    2'b01 : next_decision = 3'b100;
                    2'b10 : next_decision = 3'b011;
                    2'b11 : next_decision = 3'b010;
                endcase
            end
            3'b011 : begin
                case(din0)
                    2'b00 : next_decision = 3'b111;
                    2'b01 : next_decision = 3'b101;
                    2'b10 : next_decision = 3'b011;
                    2'b11 : next_decision = 3'b010;
                endcase
            end
            3'b100 : begin
                case(din0)
                    2'b00 : next_decision = 3'b110;
                    2'b01 : next_decision = 3'b100;
                    2'b10 : next_decision = 3'b001;
                    2'b11 : next_decision = 3'b000;
                endcase
            end
            3'b101 : begin
                case(din0)
                    2'b00 : next_decision = 3'b111;
                    2'b01 : next_decision = 3'b101;
                    2'b10 : next_decision = 3'b001;
                    2'b11 : next_decision = 3'b000;
                endcase
            end
            3'b110 : begin
                case(din0)
                    2'b00 : next_decision = 3'b110;
                    2'b01 : next_decision = 3'b100;
                    2'b10 : next_decision = 3'b011;
                    2'b11 : next_decision = 3'b010;
                endcase
            end
            3'b111 : begin
                case(din0)
                    2'b00 : next_decision = 3'b111;
                    2'b01 : next_decision = 3'b101;
                    2'b10 : next_decision = 3'b011;
                    2'b11 : next_decision = 3'b010;
                endcase
            end
        endcase
    end

    always_ff @(posedge clk0) begin
        if (rst0) begin
            decision_array <= 3'b000;
        end
        else begin
            if (!csb0) begin
                if (!web0) begin
                    decision_array <= next_decision;
                end
                else begin
                end
            end
        end
    end

endmodule : plru
