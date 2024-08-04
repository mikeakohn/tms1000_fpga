
module iceblips
(
  output [7:0] leds,
  output [3:0] column,
  input raw_clk,
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
  output pin_r7
  //output pin_r8,
  //output pin_r9,
  //output pin_r10,
  //output pin_o0,
  //output pin_o1,
  //output pin_o2,
  //output pin_o3,
  //output pin_o4,
  //output pin_o5,
  //output pin_o6,
  //output pin_o7
);

tms1000 tms1000_0
(
  .leds                  (leds),
  .column                (column),
  .raw_clk               (raw_clk),
  .pin_k1                (pin_k1),
  .pin_k2                (pin_k2),
  .pin_k3                (pin_k3),
  .pin_k4                (pin_k4),
  .pin_r0                (pin_r0),
  .pin_r1                (pin_r1),
  .pin_r2                (pin_r2),
  .pin_r3                (pin_r3),
  .pin_r4                (pin_r4),
  .pin_r5                (pin_r5),
  .pin_r6                (pin_r6),
  .pin_r7                (pin_r7),
  //.pin_r8                (pin_r8),
  //.pin_r9                (pin_r9),
  //.pin_r10               (pin_r10),
  //.pin_o0                (pin_o0),
  //.pin_o1                (pin_o1),
  //.pin_o2                (pin_o2),
  //.pin_o3                (pin_o3),
  //.pin_o4                (pin_o4),
  //.pin_o5                (pin_o5),
  //.pin_o6                (pin_o6),
  //.pin_o7                (pin_o7),
  .button_reset          (1'b1),
  .button_halt           (1'b1),
  .button_program_select (1'b1),
  .button_0              (1'b1)
);

endmodule

