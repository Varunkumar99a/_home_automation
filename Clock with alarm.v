module Clock(
  input reset, clk,
  input [1:0] hour_in1,
  input [3:0] hour_in0,
  input [3:0] min_in1, min_in0,
  input LD_time, LD_alarm, stop_al, AL_ON,
  output reg Alarm,
  output [1:0] hour_out1,
  output [3:0] hour_out0, min_out1, min_out0, sec_out1, sec_out0
);

  reg clk_1s;
  reg [3:0] temp_1s;
  reg [5:0] temp_hour, temp_min, temp_sec;
  reg [1:0] c_hour1, a_hour1;
  reg [1:0] c_hour0, a_hour0;
  reg [3:0] c_min1, a_min1;
  reg [3:0] c_min0, a_min0;
  reg [3:0] c_sec1, a_sec1;
  reg [3:0] c_sec0, a_sec0;

  function [3:0] get_tens;
    input [5:0] number;
    begin
      get_tens = number / 10;
    end
  endfunction

  always @(posedge clk_1s or posedge reset) begin
    if (reset) begin
      a_hour1 <= 0; a_hour0 <= 0;
      a_min1 <= 0;  a_min0 <= 0;
      a_sec1 <= 0;  a_sec0 <= 0;
      temp_hour <= hour_in1 * 10 + hour_in0;
      temp_min  <= min_in1 * 10 + min_in0;
      temp_sec  <= 0;
    end else begin
      if (LD_alarm) begin
        a_hour1 <= hour_in1;
        a_hour0 <= hour_in0;
        a_min1  <= min_in1;
        a_min0  <= min_in0;
        a_sec1  <= 0;
        a_sec0  <= 0;
      end
      if (LD_time) begin
        temp_hour <= hour_in1 * 10 + hour_in0;
        temp_min  <= min_in1 * 10 + min_in0;
        temp_sec  <= 0;
      end else begin
        temp_sec <= temp_sec + 1;
        if (temp_sec > 59) begin
          temp_sec <= 0;
          temp_min <= temp_min + 1;
          if (temp_min > 59) begin
            temp_min <= 0;
            temp_hour <= temp_hour + 1;
            if (temp_hour >= 24) begin
              temp_hour <= 0;
            end
          end
        end
      end
    end
  end

  always @(posedge clk or posedge reset) begin
    if (reset) begin
      temp_1s <= 0;
      clk_1s <= 0;
    end else begin
      if (temp_1s >= 9) begin
        temp_1s <= 0;
        clk_1s <= 1;
      end else begin
        temp_1s <= temp_1s + 1;
        clk_1s <= 0;
      end
    end
  end


  always @(*) begin
    if (temp_hour >= 20)
      c_hour1 <= 2;
    else if (temp_hour >= 10)
      c_hour1 <= 1;
    else
      c_hour1 <= 0;

    c_hour0 <= temp_hour - c_hour1 * 10;
    c_min1  <= get_tens(temp_min);
    c_min0  <= temp_min - c_min1 * 10;
    c_sec1  <= get_tens(temp_sec);
    c_sec0  <= temp_sec - c_sec1 * 10;
  end

  always @(posedge clk_1s or posedge reset) begin
    if (reset)
      Alarm <= 0;
    else begin
      if ({a_hour1, a_hour0, a_min1, a_min0, a_sec1, a_sec0} == 
          {c_hour1, c_hour0, c_min1, c_min0, c_sec1, c_sec0}) begin
        if (AL_ON) Alarm <= 1;
      end
      if (stop_al) Alarm <= 0;
    end
  end

  assign hour_out1 = c_hour1;
  assign hour_out0 = c_hour0;
  assign min_out1 = c_min1;
  assign min_out0 = c_min0;
  assign sec_out1 = c_sec1;
  assign sec_out0 = c_sec0;

endmodule

module Testbench;

  reg reset;
  reg clk;
  reg [1:0] hour_in1;
  reg [3:0] hour_in0;
  reg [3:0] min_in1;
  reg [3:0] min_in0;
  reg LD_time;
  reg LD_alarm;
  reg stop_al;
  reg AL_ON;

  wire Alarm;
  wire [1:0] hour_out1;
  wire [3:0] hour_out0;
  wire [3:0] min_out1;
  wire [3:0] min_out0;
  wire [3:0] sec_out1;
  wire [3:0] sec_out0;

  Clock uut (
    .reset(reset), 
    .clk(clk), 
    .hour_in1(hour_in1), 
    .hour_in0(hour_in0), 
    .min_in1(min_in1), 
    .min_in0(min_in0), 
    .LD_time(LD_time), 
    .LD_alarm(LD_alarm), 
    .stop_al(stop_al), 
    .AL_ON(AL_ON), 
    .Alarm(Alarm), 
    .hour_out1(hour_out1), 
    .hour_out0(hour_out0), 
    .min_out1(min_out1), 
    .min_out0(min_out0), 
    .sec_out1(sec_out1), 
    .sec_out0(sec_out0)
  );

  initial begin
    $dumpfile("clock.vcd");
    $dumpvars(0, Testbench);
  end

  initial begin
    clk = 0;
    forever #5 clk = ~clk;  
  end

  initial begin
    reset = 1;
    LD_time = 0;
    LD_alarm = 0;
    stop_al = 0;
    AL_ON = 0;

    hour_in1 = 1;
    hour_in0 = 0;
    min_in1 = 1;
    min_in0 = 9;

    #20 reset = 0;

    
    LD_time = 1; #10; LD_time = 0;

   
    #50;
    hour_in1 = 1;
    hour_in0 = 0;
    min_in1 = 2;
    min_in0 = 0;
    LD_alarm = 1; #10; LD_alarm = 0;

    
    AL_ON = 1;

    
    #1000;

   
    stop_al = 1; #10; stop_al = 0;

    #100 $finish;
  end

endmodule

