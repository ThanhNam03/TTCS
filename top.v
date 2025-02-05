
`timescale 1ns / 1ps

module top(
    input clk,       
    input reset,            
    input up,               
    input down,             
    output hsync,           
    output vsync,           
    output [11:0] rgb       
    );
    
    wire w_reset, w_up, w_down, w_vid_on, w_p_tick;
    wire [9:0] w_x, w_y;
    reg [11:0] rgb_reg;
    wire [11:0] rgb_next;
    
    vga_controller vga(.clk(clk), .reset(w_reset), .video_on(w_vid_on),
                       .hsync(hsync), .vsync(vsync), .p_tick(w_p_tick), .x(w_x), .y(w_y));
    pixel_gen pg(.clk(clk), .reset(w_reset), .up(w_up), .down(w_down), 
                 .video_on(w_vid_on), .x(w_x), .y(w_y), .rgb(rgb_next));
    debounce dbR(.clk(clk), .btn_in(reset), .btn_out(w_reset));
    debounce dbU(.clk(clk), .btn_in(up), .btn_out(w_up));
    debounce dbD(.clk(clk), .btn_in(down), .btn_out(w_down));
    
    // rgb buffer
    always @(posedge clk)
        if(w_p_tick)
            rgb_reg <= rgb_next;
            
    assign rgb = rgb_reg;
    
endmodule
