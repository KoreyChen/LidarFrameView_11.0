library verilog;
use verilog.vl_types.all;
entity SerialSend is
    generic(
        SD1             : integer := 123;
        SD2             : integer := 40;
        SD3             : integer := 49;
        SD4             : integer := 48;
        SD5             : integer := 50;
        SD6             : integer := 52;
        SD7             : integer := 41;
        SD8             : integer := 125;
        S1              : integer := 0;
        S2              : integer := 1;
        S3              : integer := 2;
        COUNT_S1        : integer := 0;
        COUNT_S2        : integer := 1;
        COUNT_S3        : integer := 2;
        COUNT_S4        : integer := 3;
        TXDATA_CNT_NUM  : integer := 1500
    );
    port(
        clk             : in     vl_logic;
        rst_n           : in     vl_logic;
        rs232_tx        : out    vl_logic;
        serialsend_flag : in     vl_logic;
        data            : in     vl_logic_vector(7 downto 0);
        wrclk           : in     vl_logic;
        wrreq           : in     vl_logic;
        wrempty         : out    vl_logic;
        wrfull          : out    vl_logic;
        wrusedw         : out    vl_logic_vector(9 downto 0);
        rdempty         : out    vl_logic;
        rdfull          : out    vl_logic;
        frameclk        : in     vl_logic
    );
end SerialSend;
