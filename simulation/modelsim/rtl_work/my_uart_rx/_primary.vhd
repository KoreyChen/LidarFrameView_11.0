library verilog;
use verilog.vl_types.all;
entity my_uart_rx is
    port(
        clk             : in     vl_logic;
        rst_n           : in     vl_logic;
        rs232_rx        : in     vl_logic;
        rx_data         : out    vl_logic_vector(7 downto 0);
        rx_int          : out    vl_logic;
        clk_bps         : in     vl_logic;
        bps_start       : out    vl_logic
    );
end my_uart_rx;
