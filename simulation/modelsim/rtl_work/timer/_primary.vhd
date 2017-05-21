library verilog;
use verilog.vl_types.all;
entity timer is
    port(
        clk_in          : in     vl_logic;
        rst_n_in        : in     vl_logic;
        \out\           : out    vl_logic;
        timer           : in     vl_logic_vector(24 downto 0)
    );
end timer;
