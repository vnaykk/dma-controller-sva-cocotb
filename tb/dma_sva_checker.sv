`timescale 1ns / 1ps
module dma_sva_checker (input logic clk, rst_n, m_rd_valid, m_wr_valid);
    always_ff @(posedge clk) if (rst_n) assert (!(m_rd_valid && m_wr_valid)) else $error("[SVA FAIL] Simultaneous read and write valid!");
endmodule
