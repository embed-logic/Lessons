// debounce_filter.v
module debounce_filter #(
    parameter DEBOUNCE_LIMIT = 4 // Кількість тактів стабільності (для симуляції - 4)
)(
    input  wire       clk,
    input  wire       rst,
    input  wire [3:0] raw_digit,
    output reg  [3:0] clean_digit
);

    reg [3:0] prev_digit;
    reg [7:0] counter;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            prev_digit  <= 4'd0;
            clean_digit <= 4'd0;
            counter     <= 8'd0;
        end else begin
            if (raw_digit != prev_digit) begin
                prev_digit <= raw_digit;
                counter    <= 8'd0;
            end else if (counter < DEBOUNCE_LIMIT) begin
                counter <= counter + 1'b1;
            end else begin
                clean_digit <= prev_digit;
            end
        end
    end

endmodule


// lock_controller.v
module lock_controller (
    input  wire       clk,          // тактовий сигнал
    input  wire       rst,          // асинхронний reset, активний високим рівнем
    input  wire [3:0] digit_in,     // вхідні цифри (з фізичних кнопок, із брязкітом)
    output reg        unlocked_led  // вихід, 1 = розблоковано
);

    // Код замка: 5 -> 3 -> 7
    localparam [3:0] CODE0 = 4'd5;
    localparam [3:0] CODE1 = 4'd3;
    localparam [3:0] CODE2 = 4'd7;

    // ЧОТИРИ стани FSM
    localparam [1:0] LOCKED   = 2'd0;
    localparam [1:0] WAIT_D2  = 2'd1;
    localparam [1:0] WAIT_D3  = 2'd2;
    localparam [1:0] UNLOCKED = 2'd3;

    // Сигнал після дебаунсера
    wire [3:0] clean_digit;

    // -------------------------------------------------------------------------
    // ВНУТРІШНІЙ ДЕБАУНСЕР: фільтрує вхідний digit_in
    // -------------------------------------------------------------------------
    debounce_filter #(
        .DEBOUNCE_LIMIT(4) // Для симуляції - 4 такти
    ) u_debounce (
        .clk        (clk),
        .rst        (rst),
        .raw_digit  (digit_in),
        .clean_digit(clean_digit)
    );

    // Реєстри стану
    reg [1:0] state, next_state;

    // =========================================================================
    // БЛОК 1: ЛИШЕ реєстр стану (Sequential State Register)
    // =========================================================================
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            state <= LOCKED;
        end else begin
            state <= next_state;
        end
    end

    // =========================================================================
    // БЛОК 2: ЛИШЕ логіка переходів (Combinational Next-State Logic)
    // Використовує відфільтрований clean_digit замість сирого digit_in
    // =========================================================================
    always @(*) begin
        next_state = state;
        case (state)
            LOCKED: begin
                if (clean_digit == CODE0)
                    next_state = WAIT_D2;
                else
                    next_state = LOCKED;
            end

            WAIT_D2: begin
                if (clean_digit == CODE1) // Прийшла друга цифра (3)
                    next_state = WAIT_D3;
                else if (clean_digit == 4'd0 || clean_digit == CODE0) 
                    next_state = WAIT_D2; // Чекаємо: кнопка відпущена (0) АБО все ще утримується (5)
                else
                    next_state = LOCKED;  // Скидаємо ТІЛЬКИ якщо введено НОВУ невірну цифру
            end

            WAIT_D3: begin
                if (clean_digit == CODE2) // Прийшла третя цифра (7)
                    next_state = UNLOCKED;
                else if (clean_digit == 4'd0 || clean_digit == CODE1) 
                    next_state = WAIT_D3; // Чекаємо: кнопка відпущена (0) АБО все ще утримується (3)
                else
                    next_state = LOCKED;  // Скидаємо ТІЛЬКИ якщо введено НОВУ невірну цифру
            end


            UNLOCKED: begin
                // У стані UNLOCKED лишається в UNLOCKED (не скидається само по собі)
                next_state = UNLOCKED;
            end

            default: next_state = LOCKED;
        endcase
    end

    // =========================================================================
    // БЛОК 3: ЛИШЕ логіка виходу (Moore Output Logic)
    // =========================================================================
    always @(*) begin
        unlocked_led = (state == UNLOCKED);
    end

endmodule

