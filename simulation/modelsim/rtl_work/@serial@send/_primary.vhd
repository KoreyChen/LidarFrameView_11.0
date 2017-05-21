library verilog;
use verilog.vl_types.all;
entity SerialSend is
    generic(
        SD1             : vl_logic_vector(0 to 7) := (Hi0, Hi1, Hi1, Hi1, Hi1, Hi0, Hi1, Hi1);
        SD2             : vl_logic_vector(0 to 7) := (Hi0, Hi0, Hi1, Hi0, Hi1, Hi0, Hi0, Hi0);
        SD3             : vl_logic_vector(0 to 7) := (Hi0, Hi0, Hi1, Hi1, Hi0, Hi0, Hi0, Hi1);
        SD4             : vl_logic_vector(0 to 7) := (Hi0, Hi0, Hi1, Hi1, Hi0, Hi0, Hi0, Hi0);
        SD5             : vl_logic_vector(0 to 7) := (Hi0, Hi0, Hi1, Hi1, Hi0, Hi0, Hi1, Hi0);
        SD6             : vl_logic_vector(0 to 7) := (Hi0, Hi0, Hi1, Hi1, Hi0, Hi1, Hi0, Hi0);
        SD7             : vl_logic_vector(0 to 7) := (Hi0, Hi0, Hi1, Hi0, Hi1, Hi0, Hi0, Hi1);
        SD8             : vl_logic_vector(0 to 7) := (Hi0, Hi1, Hi1, Hi1, Hi1, Hi1, Hi0, Hi1);
        S1              : vl_logic_vector(0 to 1) := (Hi0, Hi0);
        S2              : vl_logic_vector(0 to 1) := (Hi0, Hi1);
        S3              : vl_logic_vector(0 to 1) := (Hi1, Hi0);
        COUNT_S1        : vl_logic_vector(0 to 1) := (Hi0, Hi0);
        COUNT_S2        : vl_logic_vector(0 to 1) := (Hi0, Hi1);
        COUNT_S3        : vl_logic_vector(0 to 1) := (Hi1, Hi0);
        COUNT_S4        : vl_logic_vector(0 to 1) := (Hi1, Hi1);
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
    attribute mti_svvh_generic_type : integer;
    attribute mti_svvh_generic_type of SD1 : constant is 1;
    attribute mti_svvh_generic_type of SD2 : constant is 1;
    attribute mti_svvh_generic_type of SD3 : constant is 1;
    attribute mti_svvh_generic_type of SD4 : constant is 1;
    attribute mti_svvh_generic_type of SD5 : constant is 1;
    attribute mti_svvh_generic_type of SD6 : constant is 1;
    attribute mti_svvh_generic_type of SD7 : constant is 1;
    attribute mti_svvh_generic_type of SD8 : constant is 1;
    attribute mti_svvh_generic_type of S1 : constant is 1;
    attribute mti_svvh_generic_type of S2 : constant is 1;
    attribute mti_svvh_generic_type of S3 : constant is 1;
    attribute mti_svvh_generic_type of COUNT_S1 : constant is 1;
    attribute mti_svvh_generic_type of COUNT_S2 : constant is 1;
    attribute mti_svvh_generic_type of COUNT_S3 : constant is 1;
    attribute mti_svvh_generic_type of COUNT_S4 : constant is 1;
    attribute mti_svvh_generic_type of TXDATA_CNT_NUM : constant is 1;
end SerialSend;
