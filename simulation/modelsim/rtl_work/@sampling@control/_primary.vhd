library verilog;
use verilog.vl_types.all;
entity SamplingControl is
    port(
        clk             : in     vl_logic;
        n_rst           : in     vl_logic;
        timeSet         : in     vl_logic_vector(25 downto 0);
        resolution      : in     vl_logic_vector(8 downto 0);
        startPoint      : in     vl_logic;
        enable          : in     vl_logic;
        sample_clk      : out    vl_logic;
        frame_number    : out    vl_logic_vector(8 downto 0)
    );
end SamplingControl;
