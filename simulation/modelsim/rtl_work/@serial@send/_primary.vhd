library verilog;
use verilog.vl_types.all;
entity SerialSend is
    generic(
        serialState_Start: integer := 0;
        serialState_Head: integer := 1;
        serialState_CMD : integer := 2;
        serialState_Data: integer := 3;
        serialState_End : integer := 4;
        serialState_Stop: integer := 5;
        SD1             : vl_logic_vector(0 to 7) := (Hi0, Hi1, Hi1, Hi1, Hi1, Hi0, Hi1, Hi1);
        SD2             : vl_logic_vector(0 to 7) := (Hi0, Hi0, Hi1, Hi0, Hi1, Hi0, Hi0, Hi0);
        SD3             : vl_logic_vector(0 to 7) := (Hi0, Hi0, Hi1, Hi1, Hi0, Hi0, Hi0, Hi1);
        SD4             : vl_logic_vector(0 to 7) := (Hi0, Hi0, Hi1, Hi1, Hi0, Hi0, Hi0, Hi0);
        SD5             : vl_logic_vector(0 to 7) := (Hi0, Hi0, Hi1, Hi1, Hi0, Hi0, Hi1, Hi0);
        SD6             : vl_logic_vector(0 to 7) := (Hi0, Hi0, Hi1, Hi1, Hi0, Hi1, Hi0, Hi0);
        SD7             : vl_logic_vector(0 to 7) := (Hi0, Hi0, Hi1, Hi0, Hi1, Hi0, Hi0, Hi1);
        SD8             : vl_logic_vector(0 to 7) := (Hi0, Hi1, Hi1, Hi1, Hi1, Hi1, Hi0, Hi1)
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
    attribute mti_svvh_generic_type of serialState_Start : constant is 1;
    attribute mti_svvh_generic_type of serialState_Head : constant is 1;
    attribute mti_svvh_generic_type of serialState_CMD : constant is 1;
    attribute mti_svvh_generic_type of serialState_Data : constant is 1;
    attribute mti_svvh_generic_type of serialState_End : constant is 1;
    attribute mti_svvh_generic_type of serialState_Stop : constant is 1;
    attribute mti_svvh_generic_type of SD1 : constant is 1;
    attribute mti_svvh_generic_type of SD2 : constant is 1;
    attribute mti_svvh_generic_type of SD3 : constant is 1;
    attribute mti_svvh_generic_type of SD4 : constant is 1;
    attribute mti_svvh_generic_type of SD5 : constant is 1;
    attribute mti_svvh_generic_type of SD6 : constant is 1;
    attribute mti_svvh_generic_type of SD7 : constant is 1;
    attribute mti_svvh_generic_type of SD8 : constant is 1;
end SerialSend;
