

# Remove any existing work library and create a fresh one
if {[file exists work]} {
    vdel -lib work -all
}
vlib work

# Compile the Verilog source file
vlog mux2x1.v
vlog mux4x1.v
vlog pipe_stage.v
vlog preadder.v
vlog postadder.v
vlog DSP48A1.v
vlog DSP48A1_tb.v

# Start simulation with the testbench module (disable optimization)
vsim -voptargs="+acc" work.DSP48A1_tb

# Add all signals from the testbench and all sub-modules recursively to the wave window
# This is a more robust command than "add wave *"
add wave -r /DSP48A1_tb/uut/*

# Run the simulation
run -all