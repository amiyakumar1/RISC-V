module dplru #(
)(
    input logic clk0,
    input logic rst0,
    input logic csb0,
    input logic web0,
    input logic din0,
    output logic dout0
);

    logic decision_array;
    logic next_decision;

    /*
            2
           / \
          1   0
         / \ / \
    */

    // combinational logic to deal with reads from plru tree, ie if we want to get the lru way
    // plru tree only updated on hits in cache r/w state
    always_comb begin
        if (decision_array == 1'b0) begin
            dout0 = 1'b0;
        end else begin
            dout0 = 1'b1;
        end
    end

    // combinational logic to deal with writes to plru tree, ie if we access a way on a hit. the tree should update
    always_comb begin
        case (decision_array)
            1'b0 : begin
                case(din0)
                    1'b0 : next_decision = 1'b1;
                    1'b1 : next_decision = 1'b0;
                endcase
            end
            1'b1 : begin
                case(din0)
                    1'b0 : next_decision = 1'b1;
                    1'b1 : next_decision = 1'b0;
                endcase
            end
        endcase
    end

    always_ff @(posedge clk0) begin
        if (rst0) begin
            decision_array <= 1'b0;
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

endmodule : dplru