// Copyright 2026
// SPDX-License-Identifier: Solderpad-0.51
//
// Simple AXI4 memory-mapped slave model for per2axi simulations.
// The model accepts one outstanding write and one outstanding read at a time,
// returns OKAY responses, and stores data in a byte-addressable memory.

module axi4_mm_slave_model
#(
   parameter AXI_ADDR_WIDTH = 32,
   parameter AXI_DATA_WIDTH = 64,
   parameter AXI_USER_WIDTH = 6,
   parameter AXI_ID_WIDTH   = 3,
   parameter MEM_BYTES      = 4096,
   parameter READ_LATENCY   = 1,
   parameter AXI_STRB_WIDTH = AXI_DATA_WIDTH/8
)
(
   input  logic                      clk_i,
   input  logic                      rst_ni,

   // WRITE ADDRESS CHANNEL
   input  logic                      s_axi_aw_valid_i,
   input  logic [AXI_ADDR_WIDTH-1:0] s_axi_aw_addr_i,
   input  logic [2:0]                s_axi_aw_prot_i,
   input  logic [3:0]                s_axi_aw_region_i,
   input  logic [7:0]                s_axi_aw_len_i,
   input  logic [2:0]                s_axi_aw_size_i,
   input  logic [1:0]                s_axi_aw_burst_i,
   input  logic                      s_axi_aw_lock_i,
   input  logic [3:0]                s_axi_aw_cache_i,
   input  logic [3:0]                s_axi_aw_qos_i,
   input  logic [AXI_ID_WIDTH-1:0]   s_axi_aw_id_i,
   input  logic [AXI_USER_WIDTH-1:0] s_axi_aw_user_i,
   output logic                      s_axi_aw_ready_o,

   // READ ADDRESS CHANNEL
   input  logic                      s_axi_ar_valid_i,
   input  logic [AXI_ADDR_WIDTH-1:0] s_axi_ar_addr_i,
   input  logic [2:0]                s_axi_ar_prot_i,
   input  logic [3:0]                s_axi_ar_region_i,
   input  logic [7:0]                s_axi_ar_len_i,
   input  logic [2:0]                s_axi_ar_size_i,
   input  logic [1:0]                s_axi_ar_burst_i,
   input  logic                      s_axi_ar_lock_i,
   input  logic [3:0]                s_axi_ar_cache_i,
   input  logic [3:0]                s_axi_ar_qos_i,
   input  logic [AXI_ID_WIDTH-1:0]   s_axi_ar_id_i,
   input  logic [AXI_USER_WIDTH-1:0] s_axi_ar_user_i,
   output logic                      s_axi_ar_ready_o,

   // WRITE DATA CHANNEL
   input  logic                      s_axi_w_valid_i,
   input  logic [AXI_DATA_WIDTH-1:0] s_axi_w_data_i,
   input  logic [AXI_STRB_WIDTH-1:0] s_axi_w_strb_i,
   input  logic [AXI_USER_WIDTH-1:0] s_axi_w_user_i,
   input  logic                      s_axi_w_last_i,
   output logic                      s_axi_w_ready_o,

   // READ DATA CHANNEL
   output logic                      s_axi_r_valid_o,
   output logic [AXI_DATA_WIDTH-1:0] s_axi_r_data_o,
   output logic [1:0]                s_axi_r_resp_o,
   output logic                      s_axi_r_last_o,
   output logic [AXI_ID_WIDTH-1:0]   s_axi_r_id_o,
   output logic [AXI_USER_WIDTH-1:0] s_axi_r_user_o,
   input  logic                      s_axi_r_ready_i,

   // WRITE RESPONSE CHANNEL
   output logic                      s_axi_b_valid_o,
   output logic [1:0]                s_axi_b_resp_o,
   output logic [AXI_ID_WIDTH-1:0]   s_axi_b_id_o,
   output logic [AXI_USER_WIDTH-1:0] s_axi_b_user_o,
   input  logic                      s_axi_b_ready_i
);

   localparam [1:0] AXI_RESP_OKAY = 2'b00;

   logic [7:0]                  mem [0:MEM_BYTES-1];

   logic                        aw_pending_q;
   logic [AXI_ADDR_WIDTH-1:0]   aw_addr_q;
   logic [AXI_ID_WIDTH-1:0]     aw_id_q;

   logic                        w_pending_q;
   logic [AXI_DATA_WIDTH-1:0]   w_data_q;
   logic [AXI_STRB_WIDTH-1:0]   w_strb_q;

   logic                        ar_pending_q;
   logic [AXI_ADDR_WIDTH-1:0]   ar_addr_q;
   logic [AXI_ID_WIDTH-1:0]     ar_id_q;
   int unsigned                 read_count_q;

   assign s_axi_aw_ready_o = !aw_pending_q;
   assign s_axi_w_ready_o  = !w_pending_q;
   assign s_axi_ar_ready_o = !ar_pending_q && !s_axi_r_valid_o;

   task automatic clear_memory;
      int unsigned i;
      begin
         for (i = 0; i < MEM_BYTES; i++) begin
            mem[i] = '0;
         end
      end
   endtask

   function automatic int unsigned aligned_addr(input logic [AXI_ADDR_WIDTH-1:0] addr);
      int unsigned addr_int;
      begin
         addr_int = int'(addr);
         aligned_addr = (addr_int / AXI_STRB_WIDTH) * AXI_STRB_WIDTH;
      end
   endfunction

   function automatic logic [AXI_DATA_WIDTH-1:0] read_word(input logic [AXI_ADDR_WIDTH-1:0] addr);
      logic [AXI_DATA_WIDTH-1:0] data;
      int unsigned               base;
      begin
         data = '0;
         base = aligned_addr(addr);
         for (int unsigned i = 0; i < AXI_STRB_WIDTH; i++) begin
            if ((base + i) < MEM_BYTES) begin
               data[i*8 +: 8] = mem[base + i];
            end
         end
         return data;
      end
   endfunction

   task automatic write_word(
      input logic [AXI_ADDR_WIDTH-1:0]   addr,
      input logic [AXI_DATA_WIDTH-1:0]   data,
      input logic [AXI_STRB_WIDTH-1:0]   strb
   );
      int unsigned base;
      begin
         base = aligned_addr(addr);
         for (int unsigned i = 0; i < AXI_STRB_WIDTH; i++) begin
            if (strb[i] && ((base + i) < MEM_BYTES)) begin
               mem[base + i] = data[i*8 +: 8];
            end
         end
      end
   endtask

   always_ff @(posedge clk_i or negedge rst_ni) begin
      if (rst_ni == 1'b0) begin
         clear_memory();
         aw_pending_q  <= 1'b0;
         aw_addr_q     <= '0;
         aw_id_q       <= '0;
         w_pending_q   <= 1'b0;
         w_data_q      <= '0;
         w_strb_q      <= '0;
         ar_pending_q  <= 1'b0;
         ar_addr_q     <= '0;
         ar_id_q       <= '0;
         read_count_q  <= '0;
         s_axi_r_valid_o <= 1'b0;
         s_axi_r_data_o  <= '0;
         s_axi_r_resp_o  <= AXI_RESP_OKAY;
         s_axi_r_last_o  <= 1'b0;
         s_axi_r_id_o    <= '0;
         s_axi_r_user_o  <= '0;
         s_axi_b_valid_o <= 1'b0;
         s_axi_b_resp_o  <= AXI_RESP_OKAY;
         s_axi_b_id_o    <= '0;
         s_axi_b_user_o  <= '0;
      end else begin
         if (s_axi_aw_valid_i && s_axi_aw_ready_o) begin
            aw_pending_q <= 1'b1;
            aw_addr_q    <= s_axi_aw_addr_i;
            aw_id_q      <= s_axi_aw_id_i;
         end

         if (s_axi_w_valid_i && s_axi_w_ready_o) begin
            w_pending_q <= 1'b1;
            w_data_q    <= s_axi_w_data_i;
            w_strb_q    <= s_axi_w_strb_i;
         end

         if (aw_pending_q && w_pending_q && !s_axi_b_valid_o) begin
            write_word(aw_addr_q, w_data_q, w_strb_q);
            aw_pending_q  <= 1'b0;
            w_pending_q   <= 1'b0;
            s_axi_b_valid_o <= 1'b1;
            s_axi_b_resp_o  <= AXI_RESP_OKAY;
            s_axi_b_id_o    <= aw_id_q;
            s_axi_b_user_o  <= '0;
         end

         if (s_axi_b_valid_o && s_axi_b_ready_i) begin
            s_axi_b_valid_o <= 1'b0;
         end

         if (s_axi_ar_valid_i && s_axi_ar_ready_o) begin
            ar_pending_q <= 1'b1;
            ar_addr_q    <= s_axi_ar_addr_i;
            ar_id_q      <= s_axi_ar_id_i;
            read_count_q <= READ_LATENCY;
         end else if (ar_pending_q && !s_axi_r_valid_o) begin
            if (read_count_q == 0) begin
               ar_pending_q    <= 1'b0;
               s_axi_r_valid_o <= 1'b1;
               s_axi_r_data_o  <= read_word(ar_addr_q);
               s_axi_r_resp_o  <= AXI_RESP_OKAY;
               s_axi_r_last_o  <= 1'b1;
               s_axi_r_id_o    <= ar_id_q;
               s_axi_r_user_o  <= '0;
            end else begin
               read_count_q <= read_count_q - 1;
            end
         end

         if (s_axi_r_valid_o && s_axi_r_ready_i) begin
            s_axi_r_valid_o <= 1'b0;
            s_axi_r_last_o  <= 1'b0;
         end
      end
   end

   // The per2axi bridge emits single-beat INCR accesses. Keep the model
   // permissive but mark unused AXI sideband inputs as intentionally unused.
   logic unused_axi_sideband;
   assign unused_axi_sideband = ^{
      s_axi_aw_prot_i,
      s_axi_aw_region_i,
      s_axi_aw_len_i,
      s_axi_aw_size_i,
      s_axi_aw_burst_i,
      s_axi_aw_lock_i,
      s_axi_aw_cache_i,
      s_axi_aw_qos_i,
      s_axi_aw_user_i,
      s_axi_ar_prot_i,
      s_axi_ar_region_i,
      s_axi_ar_len_i,
      s_axi_ar_size_i,
      s_axi_ar_burst_i,
      s_axi_ar_lock_i,
      s_axi_ar_cache_i,
      s_axi_ar_qos_i,
      s_axi_ar_user_i,
      s_axi_w_user_i,
      s_axi_w_last_i
   };

endmodule
