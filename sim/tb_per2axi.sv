// Copyright 2026
// SPDX-License-Identifier: Solderpad-0.51
//
// Self-checking smoke testbench for the per2axi bridge.

module tb_per2axi;


   localparam int unsigned NB_CORES       = 4;
   localparam int unsigned PER_ADDR_WIDTH = 32;
   localparam int unsigned PER_ID_WIDTH   = 5;
   localparam int unsigned AXI_ADDR_WIDTH = 32;
   localparam int unsigned AXI_DATA_WIDTH = 64;
   localparam int unsigned AXI_USER_WIDTH = 6;
   localparam int unsigned AXI_ID_WIDTH   = 3;
   localparam int unsigned AXI_STRB_WIDTH = AXI_DATA_WIDTH/8;

   logic                      clk;
   logic                      rst_n;
   logic                      test_en;

   logic                      per_slave_req;
   logic [PER_ADDR_WIDTH-1:0] per_slave_add;
   logic                      per_slave_we;
   logic [31:0]               per_slave_wdata;
   logic [3:0]                per_slave_be;
   logic [PER_ID_WIDTH-1:0]   per_slave_id;
   logic                      per_slave_gnt;

   logic                      per_slave_r_valid;
   logic                      per_slave_r_opc;
   logic [PER_ID_WIDTH-1:0]   per_slave_r_id;
   logic [31:0]               per_slave_r_rdata;

   logic                      axi_aw_valid;
   logic [AXI_ADDR_WIDTH-1:0] axi_aw_addr;
   logic [2:0]                axi_aw_prot;
   logic [3:0]                axi_aw_region;
   logic [7:0]                axi_aw_len;
   logic [2:0]                axi_aw_size;
   logic [1:0]                axi_aw_burst;
   logic                      axi_aw_lock;
   logic [3:0]                axi_aw_cache;
   logic [3:0]                axi_aw_qos;
   logic [AXI_ID_WIDTH-1:0]   axi_aw_id;
   logic [AXI_USER_WIDTH-1:0] axi_aw_user;
   logic                      axi_aw_ready;

   logic                      axi_ar_valid;
   logic [AXI_ADDR_WIDTH-1:0] axi_ar_addr;
   logic [2:0]                axi_ar_prot;
   logic [3:0]                axi_ar_region;
   logic [7:0]                axi_ar_len;
   logic [2:0]                axi_ar_size;
   logic [1:0]                axi_ar_burst;
   logic                      axi_ar_lock;
   logic [3:0]                axi_ar_cache;
   logic [3:0]                axi_ar_qos;
   logic [AXI_ID_WIDTH-1:0]   axi_ar_id;
   logic [AXI_USER_WIDTH-1:0] axi_ar_user;
   logic                      axi_ar_ready;

   logic                      axi_w_valid;
   logic [AXI_DATA_WIDTH-1:0] axi_w_data;
   logic [AXI_STRB_WIDTH-1:0] axi_w_strb;
   logic [AXI_USER_WIDTH-1:0] axi_w_user;
   logic                      axi_w_last;
   logic                      axi_w_ready;

   logic                      axi_r_valid;
   logic [AXI_DATA_WIDTH-1:0] axi_r_data;
   logic [1:0]                axi_r_resp;
   logic                      axi_r_last;
   logic [AXI_ID_WIDTH-1:0]   axi_r_id;
   logic [AXI_USER_WIDTH-1:0] axi_r_user;
   logic                      axi_r_ready;

   logic                      axi_b_valid;
   logic [1:0]                axi_b_resp;
   logic [AXI_ID_WIDTH-1:0]   axi_b_id;
   logic [AXI_USER_WIDTH-1:0] axi_b_user;
   logic                      axi_b_ready;

   logic                      busy;

   per2axi #(
      .NB_CORES       ( NB_CORES       ),
      .PER_ADDR_WIDTH ( PER_ADDR_WIDTH ),
      .PER_ID_WIDTH   ( PER_ID_WIDTH   ),
      .AXI_ADDR_WIDTH ( AXI_ADDR_WIDTH ),
      .AXI_DATA_WIDTH ( AXI_DATA_WIDTH ),
      .AXI_USER_WIDTH ( AXI_USER_WIDTH ),
      .AXI_ID_WIDTH   ( AXI_ID_WIDTH   ),
      .AXI_STRB_WIDTH ( AXI_STRB_WIDTH )
   ) dut (
      .clk_i                  ( clk                 ),
      .rst_ni                 ( rst_n               ),
      .test_en_i              ( test_en             ),
      .per_slave_req_i        ( per_slave_req       ),
      .per_slave_add_i        ( per_slave_add       ),
      .per_slave_we_i         ( per_slave_we        ),
      .per_slave_wdata_i      ( per_slave_wdata     ),
      .per_slave_be_i         ( per_slave_be        ),
      .per_slave_id_i         ( per_slave_id        ),
      .per_slave_gnt_o        ( per_slave_gnt       ),
      .per_slave_r_valid_o    ( per_slave_r_valid   ),
      .per_slave_r_opc_o      ( per_slave_r_opc     ),
      .per_slave_r_id_o       ( per_slave_r_id      ),
      .per_slave_r_rdata_o    ( per_slave_r_rdata   ),
      .axi_master_aw_valid_o  ( axi_aw_valid        ),
      .axi_master_aw_addr_o   ( axi_aw_addr         ),
      .axi_master_aw_prot_o   ( axi_aw_prot         ),
      .axi_master_aw_region_o ( axi_aw_region       ),
      .axi_master_aw_len_o    ( axi_aw_len          ),
      .axi_master_aw_size_o   ( axi_aw_size         ),
      .axi_master_aw_burst_o  ( axi_aw_burst        ),
      .axi_master_aw_lock_o   ( axi_aw_lock         ),
      .axi_master_aw_cache_o  ( axi_aw_cache        ),
      .axi_master_aw_qos_o    ( axi_aw_qos          ),
      .axi_master_aw_id_o     ( axi_aw_id           ),
      .axi_master_aw_user_o   ( axi_aw_user         ),
      .axi_master_aw_ready_i  ( axi_aw_ready        ),
      .axi_master_ar_valid_o  ( axi_ar_valid        ),
      .axi_master_ar_addr_o   ( axi_ar_addr         ),
      .axi_master_ar_prot_o   ( axi_ar_prot         ),
      .axi_master_ar_region_o ( axi_ar_region       ),
      .axi_master_ar_len_o    ( axi_ar_len          ),
      .axi_master_ar_size_o   ( axi_ar_size         ),
      .axi_master_ar_burst_o  ( axi_ar_burst        ),
      .axi_master_ar_lock_o   ( axi_ar_lock         ),
      .axi_master_ar_cache_o  ( axi_ar_cache        ),
      .axi_master_ar_qos_o    ( axi_ar_qos          ),
      .axi_master_ar_id_o     ( axi_ar_id           ),
      .axi_master_ar_user_o   ( axi_ar_user         ),
      .axi_master_ar_ready_i  ( axi_ar_ready        ),
      .axi_master_w_valid_o   ( axi_w_valid         ),
      .axi_master_w_data_o    ( axi_w_data          ),
      .axi_master_w_strb_o    ( axi_w_strb          ),
      .axi_master_w_user_o    ( axi_w_user          ),
      .axi_master_w_last_o    ( axi_w_last          ),
      .axi_master_w_ready_i   ( axi_w_ready         ),
      .axi_master_r_valid_i   ( axi_r_valid         ),
      .axi_master_r_data_i    ( axi_r_data          ),
      .axi_master_r_resp_i    ( axi_r_resp          ),
      .axi_master_r_last_i    ( axi_r_last          ),
      .axi_master_r_id_i      ( axi_r_id            ),
      .axi_master_r_user_i    ( axi_r_user          ),
      .axi_master_r_ready_o   ( axi_r_ready         ),
      .axi_master_b_valid_i   ( axi_b_valid         ),
      .axi_master_b_resp_i    ( axi_b_resp          ),
      .axi_master_b_id_i      ( axi_b_id            ),
      .axi_master_b_user_i    ( axi_b_user          ),
      .axi_master_b_ready_o   ( axi_b_ready         ),
      .busy_o                 ( busy                )
   );

   axi4_mm_slave_model #(
      .AXI_ADDR_WIDTH ( AXI_ADDR_WIDTH ),
      .AXI_DATA_WIDTH ( AXI_DATA_WIDTH ),
      .AXI_USER_WIDTH ( AXI_USER_WIDTH ),
      .AXI_ID_WIDTH   ( AXI_ID_WIDTH   ),
      .MEM_BYTES      ( 4096           ),
      .READ_LATENCY   ( 1              ),
      .AXI_STRB_WIDTH ( AXI_STRB_WIDTH )
   ) slave_i (
      .clk_i              ( clk          ),
      .rst_ni             ( rst_n        ),
      .s_axi_aw_valid_i   ( axi_aw_valid ),
      .s_axi_aw_addr_i    ( axi_aw_addr  ),
      .s_axi_aw_prot_i    ( axi_aw_prot  ),
      .s_axi_aw_region_i  ( axi_aw_region),
      .s_axi_aw_len_i     ( axi_aw_len   ),
      .s_axi_aw_size_i    ( axi_aw_size  ),
      .s_axi_aw_burst_i   ( axi_aw_burst ),
      .s_axi_aw_lock_i    ( axi_aw_lock  ),
      .s_axi_aw_cache_i   ( axi_aw_cache ),
      .s_axi_aw_qos_i     ( axi_aw_qos   ),
      .s_axi_aw_id_i      ( axi_aw_id    ),
      .s_axi_aw_user_i    ( axi_aw_user  ),
      .s_axi_aw_ready_o   ( axi_aw_ready ),
      .s_axi_ar_valid_i   ( axi_ar_valid ),
      .s_axi_ar_addr_i    ( axi_ar_addr  ),
      .s_axi_ar_prot_i    ( axi_ar_prot  ),
      .s_axi_ar_region_i  ( axi_ar_region),
      .s_axi_ar_len_i     ( axi_ar_len   ),
      .s_axi_ar_size_i    ( axi_ar_size  ),
      .s_axi_ar_burst_i   ( axi_ar_burst ),
      .s_axi_ar_lock_i    ( axi_ar_lock  ),
      .s_axi_ar_cache_i   ( axi_ar_cache ),
      .s_axi_ar_qos_i     ( axi_ar_qos   ),
      .s_axi_ar_id_i      ( axi_ar_id    ),
      .s_axi_ar_user_i    ( axi_ar_user  ),
      .s_axi_ar_ready_o   ( axi_ar_ready ),
      .s_axi_w_valid_i    ( axi_w_valid  ),
      .s_axi_w_data_i     ( axi_w_data   ),
      .s_axi_w_strb_i     ( axi_w_strb   ),
      .s_axi_w_user_i     ( axi_w_user   ),
      .s_axi_w_last_i     ( axi_w_last   ),
      .s_axi_w_ready_o    ( axi_w_ready  ),
      .s_axi_r_valid_o    ( axi_r_valid  ),
      .s_axi_r_data_o     ( axi_r_data   ),
      .s_axi_r_resp_o     ( axi_r_resp   ),
      .s_axi_r_last_o     ( axi_r_last   ),
      .s_axi_r_id_o       ( axi_r_id     ),
      .s_axi_r_user_o     ( axi_r_user   ),
      .s_axi_r_ready_i    ( axi_r_ready  ),
      .s_axi_b_valid_o    ( axi_b_valid  ),
      .s_axi_b_resp_o     ( axi_b_resp   ),
      .s_axi_b_id_o       ( axi_b_id     ),
      .s_axi_b_user_o     ( axi_b_user   ),
      .s_axi_b_ready_i    ( axi_b_ready  )
   );

   initial begin
      clk = 1'b0;
      forever #5 clk = ~clk;
   end

   task automatic init_peripheral_bus;
      begin
         per_slave_req   = 1'b0;
         per_slave_add   = '0;
         per_slave_we    = 1'b0;
         per_slave_wdata = '0;
         per_slave_be    = '0;
         per_slave_id    = '0;
      end
   endtask

   function automatic logic [PER_ID_WIDTH-1:0] id_to_onehot(input int unsigned id);
      logic [PER_ID_WIDTH-1:0] onehot;
      begin
         onehot = '0;
         onehot[id] = 1'b1;
         return onehot;
      end
   endfunction

   task automatic wait_for_idle;
      int unsigned timeout;
      begin
         timeout = 0;
         while (busy) begin
            @(posedge clk);
            timeout++;
            if (timeout > 100) begin
               $fatal(1, "Timed out waiting for busy_o to deassert");
            end
         end
      end
   endtask

   task automatic issue_peripheral_request(
      input logic                      we,
      input logic [PER_ADDR_WIDTH-1:0] addr,
      input logic [31:0]               wdata,
      input logic [3:0]                be,
      input int unsigned               id
   );
      int unsigned timeout;
      begin
         @(negedge clk);
         per_slave_req   = 1'b1;
         per_slave_add   = addr;
         per_slave_we    = we;
         per_slave_wdata = wdata;
         per_slave_be    = be;
         per_slave_id    = id_to_onehot(id);

         timeout = 0;
         do begin
            @(posedge clk);
            timeout++;
            if (timeout > 100) begin
               $fatal(1, "Timed out waiting for per_slave_gnt_o");
            end
         end while (!per_slave_gnt);

         @(negedge clk);
         per_slave_req   = 1'b0;
         per_slave_add   = '0;
         per_slave_we    = 1'b0;
         per_slave_wdata = '0;
         per_slave_be    = '0;
         per_slave_id    = '0;
      end
   endtask

   task automatic wait_for_response(
      input  int unsigned id,
      output logic [31:0] rdata
   );
      int unsigned timeout;
      begin
         timeout = 0;
         do begin
            @(posedge clk);
            timeout++;
            if (timeout > 200) begin
               $fatal(1, "Timed out waiting for peripheral response for ID %0d", id);
            end
         end while (!(per_slave_r_valid && per_slave_r_id[id]));

         if (per_slave_r_opc !== 1'b0) begin
            $fatal(1, "Unexpected peripheral response opcode: %0b", per_slave_r_opc);
         end
         rdata = per_slave_r_rdata;
      end
   endtask

   task automatic per_write32(
      input logic [PER_ADDR_WIDTH-1:0] addr,
      input logic [31:0]               wdata,
      input logic [3:0]                be,
      input int unsigned               id
   );
      logic [31:0] ignored_rdata;
      begin
         issue_peripheral_request(1'b0, addr, wdata, be, id);
         wait_for_response(id, ignored_rdata);
      end
   endtask

   task automatic per_read32_check(
      input logic [PER_ADDR_WIDTH-1:0] addr,
      input logic [31:0]               expected,
      input int unsigned               id
   );
      logic [31:0] actual;
      begin
         issue_peripheral_request(1'b1, addr, '0, 4'b1111, id);
         wait_for_response(id, actual);
         if (actual !== expected) begin
            $fatal(1, "Read mismatch at 0x%08h: expected 0x%08h, got 0x%08h", addr, expected, actual);
         end
      end
   endtask

   initial begin
      test_en = 1'b0;
      rst_n   = 1'b0;
      init_peripheral_bus();

      repeat (5) @(posedge clk);
      rst_n = 1'b1;
      repeat (2) @(posedge clk);

      if (busy !== 1'b0) begin
         $fatal(1, "busy_o should be low after reset");
      end

      per_write32(32'h0000_0000, 32'hA5A5_1234, 4'b1111, 0);
      wait_for_idle();
      per_read32_check(32'h0000_0000, 32'hA5A5_1234, 0);
      wait_for_idle();

      per_write32(32'h0000_0004, 32'hDEAD_BEEF, 4'b1111, 1);
      wait_for_idle();
      per_read32_check(32'h0000_0004, 32'hDEAD_BEEF, 1);
      wait_for_idle();

      per_write32(32'h0000_0000, 32'h0000_00CC, 4'b0001, 2);
      wait_for_idle();
      per_read32_check(32'h0000_0000, 32'hA5A5_12CC, 2);
      wait_for_idle();

      per_write32(32'h0000_0004, 32'h1122_3344, 4'b1100, 3);
      wait_for_idle();
      per_read32_check(32'h0000_0004, 32'h1122_BEEF, 3);
      wait_for_idle();

      $display("per2axi smoke test PASSED");
      $finish;
   end

endmodule
