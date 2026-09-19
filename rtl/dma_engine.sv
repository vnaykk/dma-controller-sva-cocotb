`timescale 1ns / 1ps
module dma_engine #(parameter int ADDR_WIDTH = 32, parameter int DATA_WIDTH = 32) (
    input  logic clk, rst_n, cfg_start, m_rd_ready, m_rd_rvalid, m_wr_ready,
    input  logic [ADDR_WIDTH-1:0] cfg_src_addr, cfg_dst_addr,
    input  logic [15:0] cfg_len_beats,
    input  logic [DATA_WIDTH-1:0] m_rd_rdata,
    output logic dma_busy, dma_done_irq, m_rd_valid, m_wr_valid,
    output logic [ADDR_WIDTH-1:0] m_rd_addr, m_wr_addr,
    output logic [DATA_WIDTH-1:0] m_wr_wdata
);
    typedef enum logic [1:0] { ST_IDLE = 2'b00, ST_READ = 2'b01, ST_WRITE = 2'b10, ST_DONE = 2'b11 } state_t;
    state_t state;
    logic [ADDR_WIDTH-1:0] cur_src, cur_dst;
    logic [15:0] rem_beats;
    logic [DATA_WIDTH-1:0] data_buf;
    assign dma_busy = (state != ST_IDLE); assign m_rd_addr = cur_src; assign m_wr_addr = cur_dst; assign m_wr_wdata = data_buf;
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin state <= ST_IDLE; cur_src <= '0; cur_dst <= '0; rem_beats <= '0; data_buf <= '0; m_rd_valid <= 1'b0; m_wr_valid <= 1'b0; dma_done_irq <= 1'b0; end
        else begin
            dma_done_irq <= 1'b0;
            case (state)
                ST_IDLE: if (cfg_start) begin if (cfg_len_beats == 16'd0) state <= ST_DONE; else begin cur_src <= cfg_src_addr; cur_dst <= cfg_dst_addr; rem_beats <= cfg_len_beats; m_rd_valid <= 1'b1; state <= ST_READ; end end
                ST_READ: begin if (m_rd_valid && m_rd_ready) m_rd_valid <= 1'b0; if (m_rd_rvalid) begin data_buf <= m_rd_rdata; m_wr_valid <= 1'b1; state <= ST_WRITE; end end
                ST_WRITE: if (m_wr_valid && m_wr_ready) begin m_wr_valid <= 1'b0; cur_src <= cur_src + 32'd4; cur_dst <= cur_dst + 32'd4; if (rem_beats == 16'd1) state <= ST_DONE; else begin rem_beats <= rem_beats - 16'd1; m_rd_valid <= 1'b1; state <= ST_READ; end end
                ST_DONE: begin dma_done_irq <= 1'b1; state <= ST_IDLE; end
            endcase
        end
    end
endmodule
