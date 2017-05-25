library verilog;
use verilog.vl_types.all;
entity CCD_ADC_Control is
    generic(
        TimeReset       : integer := 100;
        TimeSetClk      : integer := 10;
        TimeIntegration : integer := 500;
        TimeADCDelay    : integer := 5;
        State1_Reset    : integer := 0;
        State2_Integration: integer := 1;
        State3_DataOut  : integer := 2;
        State4          : integer := 3;
        RestState_S1    : integer := 0;
        RestState_S2    : integer := 1;
        RestState_S3    : integer := 2;
        RestState_S4    : integer := 3;
        IntegState_S1   : integer := 0;
        IntegState_S2   : integer := 1;
        IntegState_S3   : integer := 2;
        IntegState_S4   : integer := 3;
        IntegState_S5   : integer := 4;
        IntegState_S6   : integer := 5;
        IntegState_S7   : integer := 6;
        IntegState_S8   : integer := 7;
        DataOutState_S1 : integer := 0;
        DataOutState_S2 : integer := 1;
        DataOutState_S3 : integer := 2;
        DataOutState_S4 : integer := 3
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
end CCD_ADC_Control;
