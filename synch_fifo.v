module synch_fifo_bram #(
    parameter DATA_WIDTH = 8,     // Number of bits per memory slot
    parameter FIFO_DEPTH = 8      // Number of memory slots (Must be a power of 2)
)(
    input  wire                    clk,
    input  wire                    rst_n,
    input  wire                    wr_en,
    input  wire                    rd_en,
    input  wire [DATA_WIDTH-1:0]   data_in,
    output wire                    full,
    output wire                    empty,
    output wire [DATA_WIDTH-1:0]   data_out
);

    // Localparam handles the internal address width math automatically
    localparam ADDR_WIDTH = $clog2(FIFO_DEPTH);

    // Memory array declaration using parameters
    reg [DATA_WIDTH-1:0] bram [0:FIFO_DEPTH-1];

    // Pointers are defined dynamically: ADDR_WIDTH down to 0 (which adds the extra MSB!)
    reg [ADDR_WIDTH:0] wr_ptr;
    reg [ADDR_WIDTH:0] rd_ptr;
    reg [ADDR_WIDTH-1:0] rd_ptr_reg;

    // --- WRITE LOGIC ---
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            wr_ptr <= {(ADDR_WIDTH+1){1'b0}}; // Resets all pointer bits to 0
        end
        else if (wr_en && !full) begin
            bram[wr_ptr[ADDR_WIDTH-1:0]] <= data_in;
            wr_ptr                       <= wr_ptr + 1'b1;
        end
    end

    // --- READ LOGIC ---
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            rd_ptr     <= {(ADDR_WIDTH+1){1'b0}};
            rd_ptr_reg <= {ADDR_WIDTH{1'b0}};
        end
        else if (rd_en && !empty) begin
            rd_ptr     <= rd_ptr + 1'b1;
            rd_ptr_reg <= rd_ptr[ADDR_WIDTH-1:0]; 
        end
    end

    // --- MEMORY LOOKUP ---
    assign data_out = bram[rd_ptr_reg];

    // --- FLAG GENERATION ---
    assign empty = (wr_ptr == rd_ptr);

    // Full condition adapts to the dynamic ADDR_WIDTH boundary
    assign full  = (wr_ptr[ADDR_WIDTH] != rd_ptr[ADDR_WIDTH]) && 
                   (wr_ptr[ADDR_WIDTH-1:0] == rd_ptr[ADDR_WIDTH-1:0]);

endmodule
