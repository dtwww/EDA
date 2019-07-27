transcript on
if {[file exists gate_work]} {
	vdel -lib gate_work -all
}
vlib gate_work
vmap work gate_work

vlog -vlog01compat -work work +incdir+. {test3_8_1200mv_85c_slow.vo}

vlog -vlog01compat -work work +incdir+F:/hit/eda/program3/simulation/modelsim {F:/hit/eda/program3/simulation/modelsim/test3.vt}

vsim -t 1ps +transport_int_delays +transport_path_delays -L altera_ver -L cycloneive_ver -L gate_work -L work -voptargs="+acc"  test3_vlg_tst

add wave *
view structure
view signals
run -all
