`timescale 1ns / 1ps

module pixel_gen(
    input clk,  
    input reset,    
    input up,
    input down,
    input video_on,
    input [9:0] x,
    input [9:0] y,
    output reg [11:0] rgb
    );
    
    
    parameter X_MAX = 639;
    parameter Y_MAX = 479;
    
   
    wire refresh_tick;
    assign refresh_tick = ((y == 481) && (x == 0)) ? 1 : 0; 
    

    parameter X_WALL_L = 32;    
    parameter X_WALL_R = 39;    
    

    parameter X_PAD_L = 600;
    parameter X_PAD_R = 603;    

    wire [9:0] y_pad_t, y_pad_b;
    parameter PAD_HEIGHT = 72;  
    
    reg [9:0] y_pad_reg, y_pad_next;
   
    parameter PAD_VELOCITY = 3;     
    

    parameter BALL_SIZE = 8;

    wire [9:0] x_ball_l, x_ball_r;

    wire [9:0] y_ball_t, y_ball_b;

    reg [9:0] y_ball_reg, x_ball_reg;

    wire [9:0] y_ball_next, x_ball_next;

    reg [9:0] x_delta_reg, x_delta_next;
    reg [9:0] y_delta_reg, y_delta_next;

    parameter BALL_VELOCITY_POS = 2;
    parameter BALL_VELOCITY_NEG = -2;

    wire [2:0] rom_addr, rom_col;   
    reg [7:0] rom_data;             
    wire rom_bit;                   
    

    always @(posedge clk or posedge reset)
        if(reset) begin
            y_pad_reg <= 0;
            x_ball_reg <= 0;
            y_ball_reg <= 0;
            x_delta_reg <= 10'h002;
            y_delta_reg <= 10'h002;
        end
        else begin
            y_pad_reg <= y_pad_next;
            x_ball_reg <= x_ball_next;
            y_ball_reg <= y_ball_next;
            x_delta_reg <= x_delta_next;
            y_delta_reg <= y_delta_next;
        end
    
    // ball rom
    always @*
        case(rom_addr)
            3'b000 :    rom_data = 8'b00111100; //   ****  
            3'b001 :    rom_data = 8'b01111110; //  ******
            3'b010 :    rom_data = 8'b11111111; // ********
            3'b011 :    rom_data = 8'b11111111; // ********
            3'b100 :    rom_data = 8'b11111111; // ********
            3'b101 :    rom_data = 8'b11111111; // ********
            3'b110 :    rom_data = 8'b01111110; //  ******
            3'b111 :    rom_data = 8'b00111100; //   ****
        endcase
    

    wire wall_on, pad_on, sq_ball_on, ball_on;
    wire [11:0] wall_rgb, pad_rgb, ball_rgb, bg_rgb;
    

    assign wall_on = ((X_WALL_L <= x) && (x <= X_WALL_R)) ? 1 : 0;
    

    assign wall_rgb = 12'hAAA;      
    assign pad_rgb = 12'hAAA;      
    assign ball_rgb = 12'hFFF;     
    assign bg_rgb = 12'h111;      
    

    assign y_pad_t = y_pad_reg;                             
    assign y_pad_b = y_pad_t + PAD_HEIGHT - 1;              
    assign pad_on = (X_PAD_L <= x) && (x <= X_PAD_R) &&     
                    (y_pad_t <= y) && (y <= y_pad_b);
                    

    always @* begin
        y_pad_next = y_pad_reg;     
        if(refresh_tick)
            if(up & (y_pad_t > PAD_VELOCITY))
                y_pad_next = y_pad_reg - PAD_VELOCITY;  
            else if(down & (y_pad_b < (Y_MAX - PAD_VELOCITY)))
                y_pad_next = y_pad_reg + PAD_VELOCITY;  
    end
    

    assign x_ball_l = x_ball_reg;
    assign y_ball_t = y_ball_reg;
    assign x_ball_r = x_ball_l + BALL_SIZE - 1;
    assign y_ball_b = y_ball_t + BALL_SIZE - 1;
   
    assign sq_ball_on = (x_ball_l <= x) && (x <= x_ball_r) &&
                        (y_ball_t <= y) && (y <= y_ball_b);
    
    assign rom_addr = y[2:0] - y_ball_t[2:0];   
    assign rom_col = x[2:0] - x_ball_l[2:0];    
    assign rom_bit = rom_data[rom_col];         
    
    assign ball_on = sq_ball_on & rom_bit;      
    
    assign x_ball_next = (refresh_tick) ? x_ball_reg + x_delta_reg : x_ball_reg;
    assign y_ball_next = (refresh_tick) ? y_ball_reg + y_delta_reg : y_ball_reg;
    
    
    always @* begin
        x_delta_next = x_delta_reg;
        y_delta_next = y_delta_reg;
        if(y_ball_t < 1)                                           
            y_delta_next = BALL_VELOCITY_POS;                       
        else if(y_ball_b > Y_MAX)                                   
            y_delta_next = BALL_VELOCITY_NEG;                      
        else if(x_ball_l <= X_WALL_R)                              
            x_delta_next = BALL_VELOCITY_POS;                       
        else if((X_PAD_L <= x_ball_r) && (x_ball_r <= X_PAD_R) &&
                (y_pad_t <= y_ball_b) && (y_ball_t <= y_pad_b))     
            x_delta_next = BALL_VELOCITY_NEG;                       
    end                    
    
    
    always @*
        if(~video_on)
            rgb = 12'h000;      
        else
            if(wall_on)
                rgb = wall_rgb;     
            else if(pad_on)
                rgb = pad_rgb;     
            else if(ball_on)
                rgb = ball_rgb;     
            else
                rgb = bg_rgb;      
       
endmodule
