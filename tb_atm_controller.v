`timescale 1ns/1ps

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

integer pass_count;
integer fail_count;

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

atm_controller uut(
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

task check_state;
input [3:0] expected;
begin
    #1;
    if(state_dbg == expected) begin
        $display("PASS : Expected State = %0d  Actual State = %0d",
                 expected,state_dbg);
        pass_count = pass_count + 1;
    end
    else begin
        $display("FAIL : Expected State = %0d  Actual State = %0d",
                 expected,state_dbg);
        fail_count = fail_count + 1;
    end
end
endtask

task check_output;
input actual;
input expected;
input [127:0] signal_name;
begin
    #1;
    if(actual == expected) begin
        $display("PASS : %s",signal_name);
        pass_count = pass_count + 1;
    end
    else begin
        $display("FAIL : %s",signal_name);
        fail_count = fail_count + 1;
    end
end
endtask

initial begin

    $dumpfile("wave_atm_controller.vcd");
    $dumpvars(0,tb_atm_controller);

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

    pass_count = 0;
    fail_count = 0;

    rst = 1;
    @(posedge clk);;
    rst = 0;

    $display("\n");
    $display("RESET TEST");
    $display("");

    check_state(S_IDLE);

    $display("\n");
    $display("SUCCESSFUL WITHDRAWAL TEST");
    $display("");

    card_inserted = 1;
    @(posedge clk);
    card_inserted = 0;

    check_state(S_CARD_IN);

    @(posedge clk);
    check_state(S_PIN_CHECK);

    pin_valid = 1;
    @(posedge clk);
    pin_valid = 0;

    check_state(S_MENU);

    txn_select = 1;
    @(posedge clk);
    txn_select = 0;

    check_state(S_AMOUNT);
    amount_valid = 1;
    cash_available = 1;

    @(posedge clk);

    amount_valid = 0;
    cash_available = 0;

    check_state(S_DISPENSE);
    check_output(cash_dispense,1'b1,"cash_dispense");

    cash_taken = 1;

    @(posedge clk);

    cash_taken = 0;

    check_state(S_RECEIPT);
    check_output(receipt_print,1'b1,"receipt_print");

    @(posedge clk);

    check_state(S_EJECT);
    check_output(card_eject,1'b1,"card_eject");

    @(posedge clk);

    check_state(S_IDLE);

$display("\n");
    $display("INVALID PIN RETRY TEST");
    $display("");

check_state(S_IDLE);

@(negedge clk);
card_inserted = 1;

@(posedge clk);
check_state(S_CARD_IN);

@(negedge clk);
card_inserted = 0;

@(posedge clk);
check_state(S_PIN_CHECK);


@(negedge clk);
pin_invalid = 1;

@(posedge clk);
check_state(S_ERROR);
check_output(error,1'b1,"error");

@(negedge clk);
pin_invalid = 0;

@(posedge clk);
check_state(S_PIN_CHECK);


@(negedge clk);
pin_invalid = 1;

@(posedge clk);
check_state(S_ERROR);
check_output(error,1'b1,"error");

@(negedge clk);
pin_invalid = 0;

@(posedge clk);
check_state(S_PIN_CHECK);


@(negedge clk);
pin_invalid = 1;

@(posedge clk);
check_state(S_RETAIN_CARD);
check_output(card_retain,1'b1,"card_retain");

@(negedge clk);
pin_invalid = 0;

@(posedge clk);
check_state(S_IDLE);

    $display("\n");
    $display("CASH UNAVAILABLE TEST");
    $display("");

    rst = 1;
    @(posedge clk);
    rst = 0;

    check_state(S_IDLE);

    card_inserted = 1;
    @(posedge clk);
    card_inserted = 0;

    check_state(S_CARD_IN);

    @(posedge clk);
    check_state(S_PIN_CHECK);

    pin_valid = 1;
    @(posedge clk);
    pin_valid = 0;

    check_state(S_MENU);

    txn_select = 1;
    @(posedge clk);
    txn_select = 0;

    check_state(S_AMOUNT);
    amount_valid = 1;
    cash_available = 0;

    @(posedge clk);

    amount_valid = 0;

    check_state(S_ERROR);
    check_output(error,1'b1,"error");

    @(posedge clk);

    check_state(S_EJECT);
    check_output(card_eject,1'b1,"card_eject");

    @(posedge clk);

    check_state(S_IDLE);

    $display("\n");
    $display("AMOUNT INVALID TEST");
    $display("");

    rst = 1;
    @(posedge clk);
    rst = 0;

    check_state(S_IDLE);

    card_inserted = 1;
    @(posedge clk);
    card_inserted = 0;

    check_state(S_CARD_IN);

    @(posedge clk);
    check_state(S_PIN_CHECK);

    pin_valid = 1;
    @(posedge clk);
    pin_valid = 0;

    check_state(S_MENU);

    txn_select = 1;
    @(posedge clk);
    txn_select = 0;

    check_state(S_AMOUNT);
    amount_valid = 0;
    cash_available = 0;

    @(posedge clk);

    amount_valid = 0;

    check_state(S_ERROR);
    check_output(error,1'b1,"error");

    @(posedge clk);

    check_state(S_EJECT);
    check_output(card_eject,1'b1,"card_eject");

    @(posedge clk);

    check_state(S_IDLE);

    $display("\n");
    $display("CANCEL TEST");
    $display("");

    rst = 1;
    @(posedge clk);
    rst = 0;

    check_state(S_IDLE);

    card_inserted = 1;
    @(posedge clk);
    card_inserted = 0;

    check_state(S_CARD_IN);

    @(posedge clk);
    check_state(S_PIN_CHECK);

    pin_valid = 1;
    @(posedge clk);
    pin_valid = 0;

    check_state(S_MENU);

    txn_select = 1;
    @(posedge clk);
    txn_select = 0;

    check_state(S_AMOUNT);

    cancel = 1;
    @(posedge clk);
    cancel = 0;

    check_state(S_EJECT);
    check_output(card_eject,1'b1,"card_eject");

    @(posedge clk);

    check_state(S_IDLE);

    $display("");
    $display("");
    $display("Verification Summary");
    $display("");
    $display("PASS = %0d", pass_count);
    $display("FAIL = %0d", fail_count);

    if(fail_count == 0)
        $display("ATM CONTROLLER : PASS");
    else
        $display("ATM CONTROLLER : FAIL");

    $display("================================");

    #20;
    $finish;

end

endmodule
