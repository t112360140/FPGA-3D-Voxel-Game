# 1. 宣告外部輸入的 50MHz 實體時鐘 (週期 20ns)
create_clock -name CLOCK_50 -period 20.000 [get_ports {CLOCK_50}]

# 2. 讓 Quartus 自動推導 PLL 產生的時鐘 (你的 100MHz 和 25MHz 會自動被抓到並設定為 10ns 和 40ns)
derive_pll_clocks

# 3. 自動計算時鐘的抖動與不確定性 (確保時序更安全)
derive_clock_uncertainty

set_clock_groups -asynchronous \
    -group [get_clocks {CLOCK_50 *pll*}] \
    -group [get_nodes {KEY[*] AUD_BCLK AUD_DACLRCK}]