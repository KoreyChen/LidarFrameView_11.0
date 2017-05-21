library verilog;
use verilog.vl_types.all;
entity LidarFrameView is
    port(
        clk             : in     vl_logic;
        rst_n           : in     vl_logic;
        rs232_tx        : out    vl_logic;
        startPoint      : in     vl_logic;
        AD_data         : in     vl_logic_vector(7 downto 0);
        AD_clk          : out    vl_logic;
        AD_OE           : out    vl_logic;
        CCD_clk         : out    vl_logic;
        CCD_rst         : out    vl_logic;
        CCD_sht         : out    vl_logic;
        CCD_data        : out    vl_logic;
        CCD_M0          : out    vl_logic;
        CCD_M1          : out    vl_logic;
        CCD_RM          : out    vl_logic
    );
end LidarFrameView;
