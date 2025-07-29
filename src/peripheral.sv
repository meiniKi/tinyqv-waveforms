// Copyright (c) 2025 Meinhard Kissich
// SPDX-License-Identifier: MIT
// -----------------------------------------------------------------------------
// File  :  peripheral.v
// Usage :  SSD1306 OLED logic analyzer / waveform plotter
//
// -----------------------------------------------------------------------------


`default_nettype none
module tqvp_meiniKi_waveforms (
    input         clk,          // Clock - the TinyQV project clock is normally set to 64MHz.
    input         rst_n,        // Reset_n - low to reset.

    input  [7:0]  ui_in,        // The input PMOD, always available.  Note that ui_in[7] is normally used for UART RX.
                                // The inputs are synchronized to the clock, note this will introduce 2 cycles of delay on the inputs.

    output [7:0]  uo_out,       // The output PMOD.  Each wire is only connected if this peripheral is selected.
                                // Note that uo_out[0] is normally used for UART TX.

    input [3:0]   address,      // Address within this peripheral's address space

    input         data_write,   // Data write request from the TinyQV core.
    input [7:0]   data_in,      // Data in to the peripheral, valid when data_write is high.
    
    output [7:0]  data_out      // Data out from the peripheral, set this in accordance with the supplied address
);

  localparam CPOL = 0;

  // w) 000: send pixel data to active track
  //-->// w) 001: send pixel data RLE transitions
  // w) 010: tunnel SPI data
  // w) 011: set {CS, DC, prescaler}          --> must be deselected while sending data
  // w) 100: set cursor to track
  // r) 1xx: get status

  //localparam CMD_RLE      = 5'b1_0001; only if area sufficient
  localparam CMD_PIXEL    = 5'b1_0000;
  localparam CMD_SPI      = 5'b1_0001;
  localparam CMD_DC_PRESC = 5'b1_0010;
  localparam CMD_SEL      = 5'b1_1000;
  localparam CMD_STATUS   = 5'b0_1000;
  // Todo: modify mapping and introduce dont-cares

  enum int unsigned { IDLE, SPI_TX, ADDR1, ADDR2, ADDR3, ADDR4, ADDR5, PIXEL } state_r, state_n, state_cont_r, state_cont_n;

  logic sck_r, sck_n;
  logic tick;
  logic done;

  logic cs_r, cs_n;

  logic oled_dc_r, oled_dc_n;

  logic [7:0] tx_r, tx_n;
  logic [2:0] cnt_r, cnt_n;

  logic [3:0] presc_r, presc_n;
  logic [3:0] cnt_presc_r, cnt_presc_n;
  logic [4:0] cnt_hbit_r, cnt_hbit_n;
  logic [7:0] bfr_r, bfr_n;
  logic [2:0] cnt_px_r, cnt_px_n;

  assign uo_out[1]    = sck_r;
  assign uo_out[2]    = tx_r[7];
  assign uo_out[3]    = cs_r & (state_r != SPI_TX) & (state_n != SPI_TX);

  assign tick         = (~|cnt_presc_r);
  assign done         = (state_r == SPI_TX) & (state_n != SPI_TX);
  assign data_out     = {7'b0, state_r == IDLE};

  always_comb begin
    tx_n          = tx_r << 1;
    state_n       = state_r;
    cnt_presc_n   = cnt_presc_r - 'b1;
    presc_n       = presc_r;
    cnt_hbit_n    = cnt_hbit_r;
    oled_dc_n     = oled_dc_r;
    cs_n          = cs_r;
    state_cont_n  = state_cont_r;
    bfr_n         = bfr_r;
    cnt_px_n      = cnt_px_r;

    case(state_r)
      IDLE: begin
        bfr_n       = data_in;
        cnt_presc_n = presc_r;
        cnt_hbit_n  = 'd16;

        casez({data_write, address})
          CMD_DC_PRESC: begin
            presc_n   = data_in[3:0];
            oled_dc_n = data_in[4];
            cs_n      = data_in[5];
          end

          CMD_SPI: begin
            tx_n          = data_in;
            state_n       = SPI_TX;
            state_cont_n  = IDLE;
          end

          CMD_SEL: begin
            state_n = ADDR1;
          end

          CMD_PIXEL: begin
            cnt_px_n = 'd0;
            state_n = PIXEL;
          end

        endcase

      end
      // ---
      ADDR1: begin
        oled_dc_n = 1'b0;
        if (tick) begin
          state_n = ADDR2;
        end
      end
      // ---
      ADDR2: begin
        tx_n        = 8'h22;
        state_n     = SPI_TX;
        cnt_hbit_n  = 'd16;
        cnt_presc_n = presc_r;
        state_cont_n = ADDR3;
      end
      // ---
      ADDR3: begin
        tx_n        = 8'h00;
        state_n     = SPI_TX;
        cnt_hbit_n  = 'd16;
        cnt_presc_n = presc_r;
        state_cont_n = ADDR4;
      end
      // ---
      ADDR4: begin
        tx_n        = bfr_r;
        state_n     = SPI_TX;
        cnt_hbit_n  = 'd16;
        cnt_presc_n = presc_r;
        state_cont_n = ADDR5;
      end
      // ---
      ADDR5: begin
        oled_dc_n     = 1'b1;
        state_cont_n  = IDLE;
        if (tick) begin
          state_n = IDLE;
        end
      end
      // ---
      PIXEL: begin
        cnt_px_n = cnt_px_r - 'b1;
        cnt_presc_n = presc_r;
        cnt_hbit_n  = 'd16;

        if (~|cnt_px_r) begin
          state_n       = SPI_TX;
          state_cont_n  = PIXEL;
          bfr_n         = bfr_r << 1;
          if (bfr_r[7]) tx_n = 8'h80;
          else          tx_n = 8'h01;
        end else begin
          state_cont_n  = IDLE;
          state_n       = IDLE;
        end

      end
      // ---
      SPI_TX: begin
        if (tick) begin
          cnt_hbit_n = cnt_hbit_r - 'b1;

          if (~|(cnt_hbit_r - 'b1)) begin
            state_n = state_cont_r;
          end

          if (cnt_hbit_r[0]) begin
            tx_n        = tx_r << 1;
          end
        end
      end
      // ---

    endcase
  end

always_ff @(posedge clk) begin
  presc_r       <= presc_n;
  cnt_presc_r   <= cnt_presc_n;
  cnt_hbit_r    <= cnt_hbit_n;
  oled_dc_r     <= oled_dc_n;
  cs_r          <= cs_n;
  state_cont_r  <= state_cont_n;
  bfr_r         <= bfr_n;
  cnt_px_r      <= cnt_px_n;

  if (~rst_n) begin
    state_r     <= IDLE;
    sck_r       <= CPOL;
    presc_r     <= 4'b100;
    cnt_hbit_r  <= 'b0;
    cs_r        <= 'b1;
    oled_dc_r   <= oled_dc_n;
    state_cont_r <= IDLE;
    bfr_r       <= 'b0;
  end else begin
    state_r     <= state_n;
    // SCK
    if (state_r == IDLE)  sck_r <= CPOL;
    else if (tick)        sck_r <= done ? CPOL : ~sck_r;
    else                  sck_r <= sck_r;
  end
end


endmodule

