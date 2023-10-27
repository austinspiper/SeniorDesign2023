onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate /main_tb/tb_ppu_data
add wave -noupdate /main_tb/tb_cpu_data
add wave -noupdate /main_tb/tb_ppu_adr
add wave -noupdate /main_tb/tb_cpu_adr
add wave -noupdate /main_tb/tb_m2
add wave -noupdate /main_tb/tb_romsel
add wave -noupdate /main_tb/tb_ppu_rd
add wave -noupdate /main_tb/tb_ppu_wr
add wave -noupdate /main_tb/tb_cpu_rw
add wave -noupdate /main_tb/tb_reset
add wave -noupdate /main_tb/tb_S_SCLK
add wave -noupdate /main_tb/tb_S_MOSI
add wave -noupdate /main_tb/tb_S_MISO
add wave -noupdate /main_tb/tb_CLK
add wave -noupdate /main_tb/m/b2v_inst2/slave_i/DOUT
add wave -noupdate /main_tb/m/b2v_inst2/slave_i/DOUT_VLD
add wave -noupdate /main_tb/m/b2v_inst2/slave_i/DIN
add wave -noupdate -expand /main_tb/m/b2v_inst8/memory_proc/mem
add wave -noupdate -expand /main_tb/m/b2v_inst9/memory_proc/mem
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {63507 ps} 0}
quietly wave cursor active 1
configure wave -namecolwidth 319
configure wave -valuecolwidth 100
configure wave -justifyvalue left
configure wave -signalnamewidth 0
configure wave -snapdistance 10
configure wave -datasetprefix 0
configure wave -rowmargin 4
configure wave -childrowmargin 2
configure wave -gridoffset 0
configure wave -gridperiod 1
configure wave -griddelta 40
configure wave -timeline 0
configure wave -timelineunits ns
update
WaveRestoreZoom {0 ps} {451364 ps}
