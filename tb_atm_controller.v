module tb_atm_controller;

reg clk;
reg rst;
reg card_inserted;
reg pin_valid;
reg pin_invalid;
reg txn_select;
reg amount_valid;
reg cash_available;
reg cash_taken;
reg cancel;

wire card_eject;
wire card_retain;
wire cash_dispense;
wire receipt_print;
wire error;
wire [3:0] state_dbg;

atm_controller uut (
    .clk(clk),
    .rst(rst),
    .card_inserted(card_inserted),
    .pin_valid(pin_valid),
    .pin_invalid(pin_invalid),
    .txn_select(txn_select),
    .amount_valid(amount_valid),
    .cash_available(cash_available),
    .cash_taken(cash_taken),
    .cancel(cancel),
    .card_eject(card_eject),
    .card_retain(card_retain),
    .cash_dispense(cash_dispense),
    .receipt_print(receipt_print),
    .error(error),
    .state_dbg(state_dbg)
);

always #5 clk = ~clk;

initial begin
    $dumpfile("wave_atm_controller.vcd");
    $dumpvars(0, tb_atm_controller);

    clk = 0;
    rst = 0;
    card_inserted = 0;
    pin_valid = 0;
    pin_invalid = 0;
    txn_select = 0;
    amount_valid = 0;
    cash_available = 0;
    cash_taken = 0;
    cancel = 0;

    rst = 1;
    #10;
    rst = 0;

    $display("===== Successful Withdrawal Test =====");

    card_inserted = 1;
    #10;
    card_inserted = 0;

    pin_valid = 1;
    #10;
    pin_valid = 0;

    txn_select = 1;
    #10;
    txn_select = 0;

    amount_valid = 1;
    cash_available = 1;
    #10;
    amount_valid = 0;
    cash_available = 0;

    #10;

    cash_taken = 1;
    #10;
    cash_taken = 0;

    #20;

    $display("===== Invalid PIN Retry Test =====");

    card_inserted = 1;
    #10;
    card_inserted = 0;

    pin_invalid = 1;
    #10;
    pin_invalid = 0;

    #20;

    pin_invalid = 1;
    #10;
    pin_invalid = 0;

    #20;

    pin_invalid = 1;
    #10;
    pin_invalid = 0;

    #20;

    $display("===== Cash Unavailable Test =====");

    rst = 1;
    #10;
    rst = 0;

    card_inserted = 1;
    #10;
    card_inserted = 0;

    pin_valid = 1;
    #10;
    pin_valid = 0;

    txn_select = 1;
    #10;
    txn_select = 0;

    amount_valid = 1;
    cash_available = 0;
    #10;
    amount_valid = 0;

    #30;

    $display("===== Cancel Test =====");

    rst = 1;
    #10;
    rst = 0;

    card_inserted = 1;
    #10;
    card_inserted = 0;

    pin_valid = 1;
    #10;
    pin_valid = 0;

    txn_select = 1;
    #10;
    txn_select = 0;

    cancel = 1;
    #10;
    cancel = 0;

    #30;

    $display("Simulation Completed");
    $finish;
end

endmodule
