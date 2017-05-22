transcript on
if {[file exists rtl_work]} {
	vdel -lib rtl_work -all
}
vlib rtl_work
vmap work rtl_work

vlog -vlog01compat -work work +incdir+C:/EngineeringDocument/GitHub/LidarFrameView_11.0 {C:/EngineeringDocument/GitHub/LidarFrameView_11.0/CCD_ADC_Control.v}
vlog -vlog01compat -work work +incdir+C:/EngineeringDocument/GitHub/LidarFrameView_11.0 {C:/EngineeringDocument/GitHub/LidarFrameView_11.0/uart_tx.v}
vlog -vlog01compat -work work +incdir+C:/EngineeringDocument/GitHub/LidarFrameView_11.0 {C:/EngineeringDocument/GitHub/LidarFrameView_11.0/uart_rx.v}
vlog -vlog01compat -work work +incdir+C:/EngineeringDocument/GitHub/LidarFrameView_11.0 {C:/EngineeringDocument/GitHub/LidarFrameView_11.0/timer.v}
vlog -vlog01compat -work work +incdir+C:/EngineeringDocument/GitHub/LidarFrameView_11.0 {C:/EngineeringDocument/GitHub/LidarFrameView_11.0/speed_select.v}
vlog -vlog01compat -work work +incdir+C:/EngineeringDocument/GitHub/LidarFrameView_11.0 {C:/EngineeringDocument/GitHub/LidarFrameView_11.0/SerialSend.v}
vlog -vlog01compat -work work +incdir+C:/EngineeringDocument/GitHub/LidarFrameView_11.0 {C:/EngineeringDocument/GitHub/LidarFrameView_11.0/SamplingControl.v}
vlog -vlog01compat -work work +incdir+C:/EngineeringDocument/GitHub/LidarFrameView_11.0 {C:/EngineeringDocument/GitHub/LidarFrameView_11.0/LidarFrameView.v}
vlog -vlog01compat -work work +incdir+C:/EngineeringDocument/GitHub/LidarFrameView_11.0 {C:/EngineeringDocument/GitHub/LidarFrameView_11.0/senddcfifo.v}

vlog -vlog01compat -work work +incdir+C:/EngineeringDocument/GitHub/LidarFrameView_11.0/simulation/modelsim {C:/EngineeringDocument/GitHub/LidarFrameView_11.0/simulation/modelsim/LidarFrameView.vt}

vsim -t 1ps -L altera_ver -L lpm_ver -L sgate_ver -L altera_mf_ver -L altera_lnsim_ver -L cyclone_ver -L rtl_work -L work -voptargs="+acc" LidarFrameView_vlg_tst

add wave *
view structure
view signals
run -all
