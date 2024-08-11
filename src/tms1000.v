// TMS1000 FPGA Soft Processor
//  Author: Michael Kohn
//   Email: mike@mikekohn.net
//     Web: https://www.mikekohn.net/
//   Board: iceFUN iCE40 HX8K
// License: MIT
//
// Copyright 2024 by Michael Kohn

module tms1000
(
  output [7:0] leds,
  output [3:0] column,
  input raw_clk,
  //output speaker_p,
  //output speaker_m,
  input pin_k1,
  input pin_k2,
  input pin_k3,
  input pin_k4,
  output pin_r0,
  output pin_r1,
  output pin_r2,
  output pin_r3,
  output pin_r4,
  output pin_r5,
  output pin_r6,
  output pin_r7,
  output pin_r8,
  output pin_r9,
  output pin_r10,
  output pin_o0,
  output pin_o1,
  output pin_o2,
  output pin_o3,
  output pin_o4,
  output pin_o5,
  output pin_o6,
  output pin_o7,
  input  button_reset,
  input  button_halt,
  input  button_program_select,
  input  button_0
);

// iceFUN 8x4 LEDs used for debugging.
reg [7:0] leds_value;
reg [3:0] column_value;

assign leds = leds_value;
assign column = column_value;

// RAM (TMS1000 is 64 bytes, TMS1100 is 128 bytes).
reg [3:0] ram [63:0];
reg [3:0] ram_temp;

// ROM (TMS1000 is 1024 bytes, TMS1100 is 2048 bytes).
reg [7:0] rom [1023:0];

initial begin
  $readmemh("rom.txt", rom);
end

// Clock.
reg [21:0] count = 0;
reg [2:0] state = 0;
reg [19:0] clock_div;
reg [14:0] delay_loop;
wire clk;
// TMS1000 runs at 300KHz. 40 times slower than 12MHz clock.
assign clk = clock_div[5];

// Registers.
reg [3:0] reg_a;
reg [1:0] reg_x;
reg [3:0] reg_y;
//reg status_latch = 0;

wire[5:0] reg_xy;
assign reg_xy = { reg_x, reg_y };

// Instruction.
// page is labled PA in the docs.
// pb is the page buffer, used to store / restore page for call / retn.
// cl is call latch. It's set when currently in a subroutine.
// sr is where pc gets copied to (and restored from) for call / retn.
reg [3:0] page = 0;
reg [5:0] pc = 0;
reg [7:0] instruction;

wire [3:0] const4;
assign const4 = {
  instruction[0], instruction[1], instruction[2], instruction[3]
};

wire [1:0] const2;
assign const2 = { instruction[0], instruction[1] };

reg cl;
reg [3:0] pb;
reg [5:0] sr;

// Flags.
reg flag_s = 0;
reg update_s = 0;

// I/O pins.
wire [3:0] pins_k;
reg [10:0] pins_r = 0;
reg [7:0]  pins_o = 0;
assign pins_k = { pin_k4, pin_k3, pin_k2, pin_k1 };

assign pin_r0  = pins_r[0];
assign pin_r1  = pins_r[1];
assign pin_r2  = pins_r[2];
assign pin_r3  = pins_r[3];
assign pin_r4  = pins_r[4];
assign pin_r5  = pins_r[5];
assign pin_r6  = pins_r[6];
assign pin_r7  = pins_r[7];
assign pin_r8  = pins_r[8];
assign pin_r9  = pins_r[9];
assign pin_r10 = pins_r[10];

assign pin_o0 = pins_o[0];
assign pin_o1 = pins_o[1];
assign pin_o2 = pins_o[2];
assign pin_o3 = pins_o[3];
assign pin_o4 = pins_o[4];
assign pin_o5 = pins_o[5];
assign pin_o6 = pins_o[6];
assign pin_o7 = pins_o[7];

// This block is simply a clock divider for the raw_clk.
always @(posedge raw_clk) begin
  count <= count + 1;
  clock_div <= clock_div + 1;
end

// This block simply drives the 8x4 LEDs.
always @(posedge raw_clk) begin
  case (count[9:7])
    3'b000: begin column_value <= 4'b0111; leds_value <= ~{ reg_x, reg_y }; end
    //3'b000: begin column_value <= 4'b0111; leds_value <= ~{ pins_r }; end
    //3'b010: begin column_value <= 4'b1011; leds_value <= ~instruction; end
    3'b010: begin column_value <= 4'b1011; leds_value <= ~{ flag_s, reg_a }; end
    3'b100: begin column_value <= 4'b1101; leds_value <= ~{ page[1:0], pc[5:0] }; end
    3'b110: begin column_value <= 4'b1110; leds_value <= ~state; end
    default: begin column_value <= 4'b1111; leds_value <= 8'hff; end
  endcase
end

parameter STATE_RESET =         0;
parameter STATE_DELAY_LOOP =    1;
parameter STATE_FETCH_OP_0 =    2;
parameter STATE_START_DECODE =  3;
parameter STATE_FINISH =        4;

parameter STATE_HALTED =        6;
parameter STATE_ERROR =         7;

// This block is the main CPU instruction execute state machine.
always @(posedge clk) begin
  if (!button_reset)
    state <= STATE_RESET;
  else if (!button_halt) begin
    state <= STATE_HALTED;
  end else begin
    case (state)
      STATE_RESET:
        begin
          flag_s <= 0;
          sr <= 0;
          cl <= 0;
          page <= 4'hf;
          pb <= 4'hf;
          pins_o <= 0;
          pins_r <= 0;

          delay_loop <= 12000;
          state <= STATE_DELAY_LOOP;
        end
      STATE_DELAY_LOOP:
        begin
          // This is probably not needed. The chip starts up fine without it.
          if (delay_loop == 0) begin
            // If button is not pushed, start rom.v code otherwise use EEPROM.
            if (button_program_select) begin
              pc <= 0;
              state <= STATE_FETCH_OP_0;
            end else begin
              pc <= 0;
              //state <= STATE_EEPROM_START;
            end
          end else begin
            delay_loop <= delay_loop - 1;
          end
        end
      STATE_FETCH_OP_0:
        begin
          instruction <= rom[{ page, pc }];
          ram_temp <= ram[reg_xy];

          if (pc == 6'h1f) begin
            pc <= { pc[4:0], 1'b1 };
          end else if (pc == 6'h3f) begin
            pc <= { pc[4:0], 1'b0 };
          end else begin
            pc <= { pc[4:0], ~(pc[5] ^ pc[4]) };
          end

          update_s <= 1;
          state <= STATE_START_DECODE;
        end
      STATE_START_DECODE:
        begin
          case (instruction[7:6])
            2'b00:
              begin
                case (instruction[5:4])
                  2'b00:
                    case (instruction[3:0])
                      // 0000_0000 comx   [0x00]
                      4'b0000: reg_x <= ~reg_x;
                      // 0000_0001 a8aac  [0x01]
                      4'b0001: { update_s, reg_a } <= reg_a + 8;
                      // 0000_0010 ynea   [0x02]
                      4'b0010: update_s <= reg_y != reg_a;
                      // 0000_0011 tam    [0x03]
                      4'b0011: ram[reg_xy] <= reg_a;
                      // 0000_0100 tamza  [0x04]
                      4'b0100: begin ram[reg_xy] <= reg_a; reg_a <= 0; end
                      // 0000_0101 a10aac [0x05]
                      4'b0101: { update_s, reg_a } <= reg_a + 10;
                      // 0000_0110 a6aac  [0x06]
                      4'b0110: { update_s, reg_a } <= reg_a + 6;
                      // 0000_0111 dan    [0x07]
                      4'b0111: { update_s, reg_a } <= { 1'b1, reg_a } - 1;
                      // 0000_1000 tka    [0x08]
                      4'b1000: reg_a <= pins_k;
                      // 0000_1001 knez   [0x09]
                      4'b1001: update_s <= pins_k != 0;
                      // 0000_1010 tdo    [0x0a]
                      4'b1010:
                        begin
                          if (flag_s == 0) begin
                            pins_o <= { 3'b0000, reg_a };
                          end else begin
                            case (reg_a)
                              8'h0: pins_o <= 8'b01111110;
                              8'h1: pins_o <= 8'b00110000;
                              8'h2: pins_o <= 8'b01101101;
                              8'h3: pins_o <= 8'b01111001;
                              8'h4: pins_o <= 8'b00110011;
                              8'h5: pins_o <= 8'b01011011;
                              8'h6: pins_o <= 8'b01011111;
                              8'h7: pins_o <= 8'b01110000;
                              8'h8: pins_o <= 8'b01111111;
                              8'h9: pins_o <= 8'b01111011;
                              8'ha: pins_o <= 8'b01110111;
                              8'hb: pins_o <= 8'b00011111;
                              8'hc: pins_o <= 8'b01001110;
                              8'hd: pins_o <= 8'b00111101;
                              8'he: pins_o <= 8'b01001111;
                              8'hf: pins_o <= 8'b01000111;
                            endcase
                          end
                        end
                      // 0000_1011 clo    [0x0b]
                      4'b1011: pins_o <= 0;
                      // 0000_1100 rstr   [0x0c]
                      4'b1100: pins_r[reg_y[3:0]] <= 0;
                      // 0000_1101 setr   [0x0d]
                      4'b1101: pins_r[reg_y[3:0]] <= 1;
                      // 0000_1110 ia     [0x0e]
                      4'b1110: reg_a <= reg_a + 1;
                      // 0000_1111 retn   [0x0f]
                      4'b1111:
                        begin
                          if (cl == 1) begin
                            pc <= sr;
                            cl <= 0;
                          end

                          page <= pb;
                        end
                    endcase
                  2'b01:
                    // 0001_xxxx ldp [-]
                    pb <= const4;
                  2'b10:
                    case (instruction[3:0])
                      // 0010_0000 tamiy [0x20]
                      4'b0000:
                        begin
                          ram[reg_xy] <= reg_a;
                          reg_y <= reg_y + 1;
                        end
                      // 0010_0001 tma   [0x21]
                      4'b0001: reg_a <= ram_temp;
                      // 0010_0010 tmy   [0x22]
                      4'b0010: reg_y <= ram_temp;
                      // 0010_0011 tya   [0x23]
                      4'b0011: reg_a <= reg_y;
                      // 0010_0100 tay   [0x24]
                      4'b0100: reg_y <= reg_a;
                      // 0010_0101 amaac [0x25]
                      4'b0101: { update_s, reg_a } <= reg_a + ram_temp;
                      // 0010_0110 mnez  [0x26]
                      4'b0110: update_s <= ram_temp != 0;
                      // 0010_0111 saman [0x27]
                      4'b0111:
                        begin
                          { update_s, reg_a } <= { 1'b1, ram_temp } - reg_a;
                        end
                      // 0010_1000 imac  [0x28]
                      4'b1000: { update_s, reg_a } <= ram_temp + 1;
                      // 0010_1001 alem  [0x29]
                      4'b1001: update_s <= (reg_a <= ram_temp);
                      // 0010_1010 dman  [0x2a]
                      4'b1010: { update_s, reg_a } <= { 1'b1, ram_temp } - 1;
                      // 0010_1011 iyc   [0x2b]
                      4'b1011: { update_s, reg_y } <= reg_y + 1;
                      // 0010_1100 dyn   [0x2c]
                      4'b1100: { update_s, reg_y } <= { 1'b1, reg_y } - 1;
                      // 0010_1101 cpaiz [0x2d]
                      4'b1101:
                        begin
                          // Set status if reg_a was 0 before the change.
                          // It shouldn't matter since -0 is 0.
                          reg_a <= -reg_a;
                          update_s <= reg_a == 0;
                        end
                      // 0010_1110 xma   [0x2e]
                      4'b1110:
                        begin
                          reg_a <= ram_temp;
                          ram[reg_xy] <= reg_a;
                        end
                      // 0010_1111 cla   [0x2f]
                      4'b1111: reg_a <= 0;
                    endcase
                  2'b11:
                    // 0011_00bb sbit  [-]
                    // 0011_01bb rbit  [-]
                    // 0011_10bb tbit1 [-]
                    // 0011_11xx ldx   [-]
                    case (instruction[3:2])
                      2'b00: ram[reg_xy][const2] <= 1;
                      2'b01: ram[reg_xy][const2] <= 0;
                      2'b10: update_s <= ram_temp[const2];
                      2'b11: reg_x <= { const2 };
                    endcase
                endcase
              end
            2'b01:
              begin
                // 0100_xxxx tcy   [-]
                // 0101_xxxx ynec  [-]
                // 0110_xxxx tcmiy [-]
                // 0111_xxxx alec  [-]
                case (instruction[5:4])
                  2'b00: reg_y <= const4;
                  2'b01: update_s <= (ram_temp != const4);
                  2'b10:
                    begin
                      ram[reg_xy] <= const4;
                      reg_y <= reg_y + 1;
                    end
                  2'b11: update_s <= (reg_a <= const4);
                endcase
              end
            2'b10:
              begin
                // 10xxxxxx br [-]
                if (flag_s == 1) begin
                  pc <= instruction[5:0];

                  if (cl == 0) begin
                    page <= pb;
                  end
                end
              end
            2'b11:
              begin
                // 11xxxxxx call [-]
                if (flag_s == 1) begin
                  pc <= instruction[5:0];

                  if (cl == 0) begin
                    sr <= pc;
                    page <= pb;
                    pb <= page;
                    cl <= 1;
                  end else begin
                    pb <= page;
                  end
                end
              end
          endcase

          state <= STATE_FINISH;
        end
      STATE_FINISH:
        begin
          flag_s <= update_s;
          state <= STATE_FETCH_OP_0;
        end
      STATE_HALTED:
        begin
          state <= STATE_HALTED;
        end
      STATE_ERROR:
        begin
          state <= STATE_ERROR;
        end
    endcase
  end
end

endmodule

