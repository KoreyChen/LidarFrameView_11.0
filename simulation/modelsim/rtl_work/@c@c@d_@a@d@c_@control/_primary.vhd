library verilog;
use verilog.vl_types.all;
entity CCD_ADC_Control is
    generic(
        TimeReset       : integer := 100;
        TimeSetClk      : integer := 10;
        TimeIntegration : integer := 500;
        TimeADCDelay    : integer := 5;
        State1_Reset    : vl_logic_vector(0 to 1) := (Hi0, Hi0);
        State2_Integration: vl_logic_vector(0 to 1) := (Hi0, Hi1);
        State3_DataOut  : vl_logic_vector(0 to 1) := (Hi1, Hi0);
        State4          : vl_logic_vector(0 to 1) := (Hi1, Hi1);
        RestState_S1    : vl_logic_vector(0 to 1) := (Hi0, Hi0);
        RestState_S2    : vl_logic_vector(0 to 1) := (Hi0, Hi1);
        RestState_S3    : vl_logic_vector(0 to 1) := (Hi1, Hi0);
        RestState_S4    : vl_logic_vector(0 to 1) := (Hi1, Hi1);
        IntegState_S1   : vl_logic_vector(0 to 2) := (Hi0, Hi0, Hi0);
        IntegState_S2   : vl_logic_vector(0 to 2) := (Hi0, Hi0, Hi1);
        IntegState_S3   : vl_logic_vector(0 to 2) := (Hi0, Hi1, Hi0);
        IntegState_S4   : vl_logic_vector(0 to 2) := (Hi0, Hi1, Hi1);
        IntegState_S5   : vl_logic_vector(0 to 2) := (Hi1, Hi0, Hi0);
        IntegState_S6   : vl_logic_vector(0 to 2) := (Hi1, Hi0, Hi1);
        IntegState_S7   : vl_logic_vector(0 to 2) := (Hi1, Hi1, Hi0);
        IntegState_S8   : vl_logic_vector(0 to 2) := (Hi1, Hi1, Hi1);
        DataOutState_S1 : vl_logic_vector(0 to 1) := (Hi0, Hi0);
        DataOutState_S2 : vl_logic_vector(0 to 1) := (Hi0, Hi1);
        DataOutState_S3 : vl_logic_vector(0 to 1) := (Hi1, Hi0);
        DataOutState_S4 : vl_logic_vector(0 to 1) := (Hi1, Hi1)
    );
    port(
        clk             : in     vl_logic;
        n_rst           : in     vl_logic;
        AD_data         : in     vl_logic_vector(7 downto 0);
        AD_clk          : out    vl_logic;
        AD_OE           : out    vl_logic;
        CCD_clk         : out    vl_logic;
        CCD_rst         : out    vl_logic;
        CCD_sht         : out    vl_logic;
        CCD_data        : out    vl_logic;
        CCD_M0          : out    vl_logic;
        CCD_M1          : out    vl_logic;
        CCD_RM          : out    vl_logic;
        serialsend_flag : out    vl_logic;
        data            : out    vl_logic_vector(7 downto 0);
        wrclk           : out    vl_logic;
        wrreq           : out    vl_logic;
        wrempty         : in     vl_logic;
        wrfull          : in     vl_logic;
        wrusedw         : in     vl_logic_vector(10 downto 0);
        rdempty         : in     vl_logic;
        rdfull          : in     vl_logic;
        frameclk        : out    vl_logic
    );
    attribute mti_svvh_generic_type : integer;
    attribute mti_svvh_generic_type of TimeReset : constant is 1;
    attribute mti_svvh_generic_type of TimeSetClk : constant is 1;
    attribute mti_svvh_generic_type of TimeIntegration : constant is 1;
    attribute mti_svvh_generic_type of TimeADCDelay : constant is 1;
    attribute mti_svvh_generic_type of State1_Reset : constant is 1;
    attribute mti_svvh_generic_type of State2_Integration : constant is 1;
    attribute mti_svvh_generic_type of State3_DataOut : constant is 1;
    attribute mti_svvh_generic_type of State4 : constant is 1;
    attribute mti_svvh_generic_type of RestState_S1 : constant is 1;
    attribute mti_svvh_generic_type of RestState_S2 : constant is 1;
    attribute mti_svvh_generic_type of RestState_S3 : constant is 1;
    attribute mti_svvh_generic_type of RestState_S4 : constant is 1;
    attribute mti_svvh_generic_type of IntegState_S1 : constant is 1;
    attribute mti_svvh_generic_type of IntegState_S2 : constant is 1;
    attribute mti_svvh_generic_type of IntegState_S3 : constant is 1;
    attribute mti_svvh_generic_type of IntegState_S4 : constant is 1;
    attribute mti_svvh_generic_type of IntegState_S5 : constant is 1;
    attribute mti_svvh_generic_type of IntegState_S6 : constant is 1;
    attribute mti_svvh_generic_type of IntegState_S7 : constant is 1;
    attribute mti_svvh_generic_type of IntegState_S8 : constant is 1;
    attribute mti_svvh_generic_type of DataOutState_S1 : constant is 1;
    attribute mti_svvh_generic_type of DataOutState_S2 : constant is 1;
    attribute mti_svvh_generic_type of DataOutState_S3 : constant is 1;
    attribute mti_svvh_generic_type of DataOutState_S4 : constant is 1;
end CCD_ADC_Control;