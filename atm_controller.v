module atm_controller #(
    parameter MAX_PIN_ATTEMPTS = 3
)(
    input clk,
    input rst,
    input card_inserted,
    input pin_valid,
    input pin_invalid,
    input txn_select,
    input amount_valid,
    input cash_available,
    input cash_taken,
    input cancel,

    output reg card_eject,
    output reg card_retain,
    output reg cash_dispense,
    output reg receipt_print,
    output reg error,
    output [3:0] state_dbg
);

parameter S_IDLE        = 4'd0,
          S_CARD_IN     = 4'd1,
          S_PIN_CHECK   = 4'd2,
          S_MENU        = 4'd3,
          S_AMOUNT      = 4'd4,
          S_DISPENSE    = 4'd5,
          S_RECEIPT     = 4'd6,
          S_EJECT       = 4'd7,
          S_ERROR       = 4'd8,
          S_RETAIN_CARD = 4'd9;

reg [3:0] state;
reg [3:0] next_state;
reg [1:0] pin_attempts;
reg pin_retry_error;

assign state_dbg = state;

always @(posedge clk) begin
    if (rst) begin
        state <= S_IDLE;
        pin_attempts <= 2'd0;
        pin_retry_error <= 1'b0;
    end
    else begin
        state <= next_state;

        if ((state == S_IDLE) ||
            ((state == S_PIN_CHECK) && pin_valid))
            pin_attempts <= 2'd0;

        else if ((state == S_PIN_CHECK) && pin_invalid)
            pin_attempts <= pin_attempts + 1'b1;

        if ((state == S_PIN_CHECK) && pin_invalid)
            pin_retry_error <= 1'b1;

        else if ((state == S_AMOUNT) &&
                 amount_valid &&
                 !cash_available)
            pin_retry_error <= 1'b0;

        else if (state == S_IDLE)
            pin_retry_error <= 1'b0;
    end
end

always @(*) begin
    next_state = state;

    card_eject    = 1'b0;
    card_retain   = 1'b0;
    cash_dispense = 1'b0;
    receipt_print = 1'b0;
    error         = 1'b0;

    case (state)

        S_IDLE: begin
            if (card_inserted)
                next_state = S_CARD_IN;
        end

        S_CARD_IN: begin
            if (cancel)
                next_state = S_EJECT;
            else
                next_state = S_PIN_CHECK;
        end

        S_PIN_CHECK: begin
            if (cancel)
                next_state = S_EJECT;

            else if (pin_valid)
                next_state = S_MENU;

            else if (pin_invalid) begin
                if (pin_attempts == MAX_PIN_ATTEMPTS - 1)
                    next_state = S_RETAIN_CARD;
                else
                    next_state = S_ERROR;
            end
        end

        S_MENU: begin
            if (cancel)
                next_state = S_EJECT;

            else if (txn_select)
                next_state = S_AMOUNT;
        end

        S_AMOUNT: begin
            if (cancel)
                next_state = S_EJECT;

            else if (amount_valid) begin
                if (cash_available)
                    next_state = S_DISPENSE;
                else
                    next_state = S_ERROR;
            end
        end

        S_DISPENSE: begin
            cash_dispense = 1'b1;

            if (cancel)
                next_state = S_EJECT;

            else if (cash_taken)
                next_state = S_RECEIPT;
        end

        S_RECEIPT: begin
            receipt_print = 1'b1;
            next_state = S_EJECT;
        end

        S_EJECT: begin
            card_eject = 1'b1;
            next_state = S_IDLE;
        end

        S_ERROR: begin
            error = 1'b1;

            if (pin_retry_error)
                next_state = S_PIN_CHECK;
            else
                next_state = S_EJECT;
        end

        S_RETAIN_CARD: begin
            card_retain = 1'b1;
            next_state = S_IDLE;
        end

        default: begin
            next_state = S_IDLE;
        end

    endcase
end

endmodule
