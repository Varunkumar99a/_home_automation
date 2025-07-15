module buttonControl(
  input clk, input reset,input button,
  output reg valid_vote);
  
  reg [30:0] counter;
  
  always@(posedge clk) begin
    if(reset)
      counter <= 0;
    else begin
      if(button && counter<11)
        counter <= counter + 1;
      else if(!button)
        counter <= 0;
    end
  end

  always@(posedge clk) begin
    if(reset)
      valid_vote <= 1'b0;
    else begin
      if(counter == 10)
        valid_vote <= 1'b1;
      else
        valid_vote <= 1'b0;
    end
  end
endmodule

module voteMonitor(
  input clk, input reset, input mode,
  input cand1_voteValid,
  input cand2_voteValid,
  input cand3_voteValid,
  input cand4_voteValid,
  output reg [7:0] cand1_voteReceived,
  output reg [7:0] cand2_voteReceived,
  output reg [7:0] cand3_voteReceived,
  output reg [7:0] cand4_voteReceived);
  
  always @(posedge clk) begin
    if(reset) begin
      cand1_voteReceived <= 0;
      cand2_voteReceived <= 0;
      cand3_voteReceived <= 0;
      cand4_voteReceived <= 0;
    end
    else begin
      if(cand1_voteValid && mode==0)
        cand1_voteReceived <= cand1_voteReceived + 1;
      else if(cand2_voteValid && mode==0)
        cand2_voteReceived <= cand2_voteReceived + 1;
      else if(cand3_voteValid && mode==0)
        cand3_voteReceived <= cand3_voteReceived + 1;
      else if(cand4_voteValid && mode==0)
        cand4_voteReceived <= cand4_voteReceived + 1;
    end
  end
  
endmodule

module modeControl(
  input clk,input reset,input mode,
  input valid_voteGiven,
  input [7:0] cand1_vote,
  input [7:0] cand2_vote,
  input [7:0] cand3_vote,
  input [7:0] cand4_vote,
  input cand1_buttonPress,
  input cand2_buttonPress,
  input cand3_buttonPress,
  input cand4_buttonPress,
  output reg [7:0] led);
  
  reg [30:0] counter;
  
  always @(posedge clk) begin
    if(reset)
      counter <= 0; // if reset is pressed counter is set to 0
    else if(valid_voteGiven)
      counter <= counter + 1; // if valid vote is casted inc counter by one
    else if(counter!=0 && counter < 10)
      counter <= counter + 1; // if counter is not 0 inc it upto 10
    else
      counter <= 0; // if counter reaches 10,then reset the counter to zero
  end
  
  always @(posedge clk) begin
    if(reset)
      led <= 0;
    else begin
      if(mode==0 && counter > 0) // mode0-voting ; mode1-counting
        led <= 8'hFF;
      else if(mode==0)
        led <= 8'h00;
      else if(mode==1) begin
        if(cand1_buttonPress)
          led <= cand1_vote;
        else if(cand2_buttonPress)
          led <= cand2_vote;
        else if(cand3_buttonPress)
          led <= cand3_vote;
        else if(cand4_buttonPress)
          led <= cand4_vote;
      end
    end
  end
endmodule

module votingMachine( //This is the main topmodule
  input clk,input mode,input reset,
  input button1,
  input button2,
  input button3,
  input button4,
  output [7:0] led);
  
  wire valid_vote1,valid_vote2,valid_vote3,valid_vote4;
  wire [7:0] cand1_voteReceived,cand2_voteReceived,cand3_voteReceived,cand4_voteReceived;
  wire anyValid_vote;
  
  assign anyValid_vote = valid_vote1|valid_vote2|valid_vote3|valid_vote4;
  
  buttonControl bC1(.clk(clk),.reset(reset),.button(button1),.valid_vote(valid_vote1));
  buttonControl bC2(.clk(clk),.reset(reset),.button(button2),.valid_vote(valid_vote2));
  buttonControl bC3(.clk(clk),.reset(reset),.button(button3),.valid_vote(valid_vote3));
  buttonControl bC4(.clk(clk),.reset(reset),.button(button4),.valid_vote(valid_vote4));
  
  voteMonitor vM(.clk(clk),.reset(reset),.mode(mode),
                 .cand1_voteValid(valid_vote1),
                 .cand2_voteValid(valid_vote2),
                 .cand3_voteValid(valid_vote3),
                 .cand4_voteValid(valid_vote4),
                 .cand1_voteReceived(cand1_voteReceived),
                 .cand2_voteReceived(cand2_voteReceived),
                 .cand3_voteReceived(cand3_voteReceived),
                 .cand4_voteReceived(cand4_voteReceived));
  
  modeControl mC(.clk(clk),.reset(reset),.mode(mode),.valid_voteGiven(anyValid_vote),
                 .cand1_vote(cand1_voteReceived),
                 .cand2_vote(cand2_voteReceived),
                 .cand3_vote(cand3_voteReceived),
                 .cand4_vote(cand4_voteReceived),
                 .cand1_buttonPress(valid_vote1),
                 .cand2_buttonPress(valid_vote2),
                 .cand3_buttonPress(valid_vote3),
                 .cand4_buttonPress(valid_vote4),
                 .led(led));
  
endmodule

module stimulus();
  
  //INPUTS
  reg clk;
  reg mode;
  reg reset;
  reg button1;
  reg button2;
  reg button3;
  reg button4;
  //OUTPUTS
  wire [7:0] led;
  
  votingMachine uut(
    .clk(clk), .mode(mode), .reset(reset),
    .button1(button1), .button2(button2), .button3(button3), .button4(button4),
    .led(led)
  );
  
  // Clock Generation
  initial begin
    clk = 0;
    forever #5 clk = ~clk;
  end

  initial begin
    // Initial reset and inputs
    reset = 1; mode = 0; button1 = 0; button2 = 0; button3 = 0; button4 = 0;
    #100
    
    #100 reset = 0; mode = 0; button1 = 0; button2 = 0; button3 = 0; button4 = 0;
    #5   reset = 0; mode = 0; button1 = 1; button2 = 0; button3 = 0; button4 = 0;
    #10  reset = 0; mode = 0; button1 = 0; button2 = 0; button3 = 0; button4 = 0;
    #5   reset = 0; mode = 0; button1 = 1; button2 = 0; button3 = 0; button4 = 0;
    #200 reset = 0; mode = 0; button1 = 0; button2 = 0; button3 = 0; button4 = 0;
    #5   reset = 0; mode = 0; button1 = 0; button2 = 0; button3 = 0; button4 = 0;
    #10  reset = 0; mode = 0; button1 = 0; button2 = 0; button3 = 0; button4 = 0;
    #5   reset = 0; mode = 0; button1 = 0; button2 = 0; button3 = 0; button4 = 0;

    #5   reset = 0; mode = 0; button1 = 0; button2 = 1; button3 = 0; button4 = 0;
    #200 reset = 0; mode = 0; button1 = 0; button2 = 0; button3 = 0; button4 = 0;
    #5   reset = 0; mode = 0; button1 = 0; button2 = 0; button3 = 0; button4 = 0;
    #10  reset = 0; mode = 0; button1 = 0; button2 = 0; button3 = 0; button4 = 0;
    #5   reset = 0; mode = 0; button1 = 0; button2 = 0; button3 = 0; button4 = 0;

    #5   reset = 0; mode = 0; button1 = 0; button2 = 0; button3 = 1; button4 = 0;
    #200 reset = 0; mode = 0; button1 = 0; button2 = 0; button3 = 0; button4 = 0;
    #5   reset = 0; mode = 0; button1 = 0; button2 = 0; button3 = 0; button4 = 0;
    #10  reset = 0; mode = 0; button1 = 0; button2 = 0; button3 = 0; button4 = 0;
    #5   reset = 0; mode = 0; button1 = 0; button2 = 0; button3 = 0; button4 = 0;

    #5   reset = 0; mode = 1; button1 = 0; button2 = 1; button3 = 0; button4 = 1;
    #200 reset = 0; mode = 0; button1 = 0; button2 = 0; button3 = 1; button4 = 0;
    #5   reset = 0; mode = 0; button1 = 0; button2 = 0; button3 = 0; button4 = 0;
    #10  reset = 0; mode = 1; button1 = 0; button2 = 1; button3 = 0; button4 = 0;
    #5   reset = 0; mode = 0; button1 = 0; button2 = 0; button3 = 0; button4 = 0;

    $finish;
  end

  initial begin
    $dumpfile("votingMachine.vcd");
    $dumpvars(0,stimulus);
  end

  initial begin
    $monitor($time, " mode = %b | button1 = %b | button2 = %b | button3 = %b | button4 = %b | led = %b",
             mode, button1, button2, button3, button4, led);
  end

endmodule

                 
                 
  
 
  
  
  
  
  
  
    
  
  
  
        
    
