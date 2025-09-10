# clear all
set nfacs [ gtkwave::getNumFacs ]
set signals [list]
for {set i 0} {$i < $nfacs } {incr i} {
    set facname [ gtkwave::getFacName $i ]
    lappend signals "$facname"
}
gtkwave::deleteSignalsFromList $signals

# add instance port
set ports [list tb_clk_divider.CLK100MHZ tb_clk_divider.rst_p tb_clk_divider.i_enable tb_clk_divider.o_tick]
gtkwave::addSignalsFromList $ports
