// tb_lock_controller.v
`timescale 1ns / 1ps

module tb_lock_controller;

    reg        clk;
    reg        rst;
    reg  [3:0] digit_in;
    wire       unlocked_led;

    // Підключаємо DUT (Device Under Test) безпосередньо
    lock_controller dut (
        .clk(clk),
        .rst(rst),
        .digit_in(digit_in),
        .unlocked_led(unlocked_led)
    );

    // Генерація тактового сигналу (T = 10 нс)[cite: 2]
    initial clk = 0;
    always #5 clk = ~clk;

    // -------------------------------------------------------------------------
    // Таска для подачі цифри З МОДЕЛЮВАННЯМ БРЯЗКІТУ КНОПКИ
    // -------------------------------------------------------------------------
    task apply_digit_with_bounce(input [3:0] target_digit);
        begin
            $display("[%0t ns] --- load digit %0d debounce ---", $time, target_digit);
            
            // 1. Моделюємо брязкіт: шум тривалістю < 4 тактів
            digit_in = target_digit + 1'b1; #12; // Хибний сплеск (1.2 такти)
            digit_in = 4'd0;               #8;  // Сплеск 0 (0.8 такти)
            digit_in = target_digit;       #15; // Сплеск потрібної цифри (1.5 такти)
            digit_in = 4'd15;              #4; // Ще один шум (1 такт)
            
            // 2. Стабілізація сигналу
            digit_in = target_digit;
            
            // Чекаємо 6 тактів: 4 такти для затримки дебаунсера + 1-2 такти для переходу FSM[cite: 2]
            repeat (8) @(posedge clk); 
            #1;

//          //Імітація відпускання кнопки, чи перехідний процес                           
//            digit_in = 4'd0;
//            repeat (6) @(posedge clk);
//            #1;
            
            
        end
    endtask

    // -------------------------------------------------------------------------
    // Тестовий сценарій
    // -------------------------------------------------------------------------
    initial begin
        $display("=== START SIMU: LOCK CONTROLLER ===");

        // КРОК 1: Reset[cite: 2]
        rst = 1; digit_in = 4'd0;
        #20;
        rst = 0;
        #10;
        $display("[%0t ns] state after reset: state = %0d, unlocked_led = %0b", 
                 $time, dut.state, unlocked_led);

        // КРОК 2: Правильна послідовність (5 -> 3 -> 7) з брязкітом[cite: 1, 2]
        apply_digit_with_bounce(4'd5); // LOCKED -> WAIT_D2
        $display("[%0t ns] after 5: state = %0d (waiting WAIT_D2 = 1) led=%0b", $time, dut.state, unlocked_led);

        apply_digit_with_bounce(4'd3); // WAIT_D2 -> WAIT_D3
        $display("[%0t ns] after 3: state = %0d (waiting WAIT_D3 = 2) led=%0b", $time, dut.state, unlocked_led);

        apply_digit_with_bounce(4'd7); // WAIT_D3 -> UNLOCKED
        $display("[%0t ns] after 7: state = %0d (waiting UNLOCKED = 3) led=%0b", $time, dut.state, unlocked_led);

        // Перевіряємо вихід[cite: 2]
        if (unlocked_led === 1'b1)
            $display("[%0t ns] [PASS] UNLOCK (unlocked_led = 1)", $time);
        else
            $display("[%0t ns] [FAIL] Blocked (unlocked_led = %0b)", $time, unlocked_led);

        // КРОК 3: Перевірка утримання стану UNLOCKED
        apply_digit_with_bounce(4'd1); // Будь-яка цифра після відкриття
        if (unlocked_led === 1'b1 && dut.state === 2'd3)
            $display("[%0t ns] [PASS] Lock hold  UNLOCKED after any in", $time);
        else
            $display("[%0t ns] [FAIL]  UNLOCKED reseting", $time);

        // КРОК 4: Сценарій помилки (Reset -> 5 -> 9 -> LOCKED)[cite: 2]
        $display("\n=== TEST ERROR ===");
        rst = 1; #10; rst = 0; #10; // Скидаємо[cite: 2]
        #20;
        apply_digit_with_bounce(4'd5); // Правильна (WAIT_D2)[cite: 2]
        apply_digit_with_bounce(4'd9); // Помилкова цифра![cite: 2]

        if (dut.state === 2'd0 && unlocked_led === 1'b0)
            $display("[%0t ns] [PASS] fail digit mode FSM to LOCKED (state = 0)", $time);
        else
            $display("[%0t ns] [FAIL] fail digit mode FSM to LOCKED! state = %0d", $time, dut.state);

        $display("\n=== SIMULATION END ===");
        $finish;
    end

endmodule
