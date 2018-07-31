from yellow_block import YellowBlock
from constraints import PortConstraint
from helpers import to_int_list

class skarab_adc4x3g_14(YellowBlock):
    def initialize(self):
        # Set bitwidth of block (this is determined by the 'Data bitwidth' parameter in the Simulink mask)
        self.bitwidth = int(self.bitwidth)
        # add the source files, which have the same name as the module (this is the verilog module created above)
        self.module = 'skarab_adc4x3g_14'
        self.add_source(self.module)
        self.add_source('skarab_adc4x3g_14/JESD204B_4LaneRX_7500MHz.xdc')

    def modify_top(self,top):
    
        # port name to be used for 'dio_buf'
        external_port_name = self.fullname + '_ext'
        
        # get this instance from 'top.v' or create if not instantiated yet
        inst = top.get_instance(entity=self.module, name=self.fullname, comment=self.fullname)
        
        inst.add_port('FREE_RUN_156M25HZ_CLK_IN77', signal='%s_din_i'%self.fullname) 
        inst.add_port('ADC_MEZ_REFCLK_0_P', signal='ADC_MEZ_REFCLK_0_P')
        inst.add_port('ADC_MEZ_REFCLK_0_N', signal='ADC_MEZ_REFCLK_0_N')        
        inst.add_port('ADC_MEZ_PHY11_LANE_RX_P', signal='ADC_MEZ_PHY11_LANE_RX_P',width=4) 
        inst.add_port('ADC_MEZ_PHY11_LANE_RX_N', signal='ADC_MEZ_PHY11_LANE_RX_N',width=4)
        inst.add_port('ADC_MEZ_REFCLK_1_P', signal='ADC_MEZ_REFCLK_1_P')
        inst.add_port('ADC_MEZ_REFCLK_1_N', signal='ADC_MEZ_REFCLK_1_N')        
        inst.add_port('ADC_MEZ_PHY12_LANE_RX_P', signal='ADC_MEZ_PHY12_LANE_RX_P',width=4) 
        inst.add_port('ADC_MEZ_PHY12_LANE_RX_N', signal='ADC_MEZ_PHY12_LANE_RX_N',width=4) 
        inst.add_port('ADC_MEZ_REFCLK_2_P', signal='ADC_MEZ_REFCLK_2_P') 
        inst.add_port('ADC_MEZ_REFCLK_2_N', signal='ADC_MEZ_REFCLK_2_N')        
        inst.add_port('ADC_MEZ_PHY21_LANE_RX_P', signal='ADC_MEZ_PHY21_LANE_RX_P',width=4) 
        inst.add_port('ADC_MEZ_PHY21_LANE_RX_N', signal='ADC_MEZ_PHY21_LANE_RX_N',width=4)
        inst.add_port('ADC_MEZ_REFCLK_3_P', signal='ADC_MEZ_REFCLK_3_P') 
        inst.add_port('ADC_MEZ_REFCLK_3_N', signal='ADC_MEZ_REFCLK_3_N')        
        inst.add_port('ADC_MEZ_PHY22_LANE_RX_P', signal='ADC_MEZ_PHY22_LANE_RX_P',width=4) 
        inst.add_port('ADC_MEZ_PHY22_LANE_RX_N', signal='ADC_MEZ_PHY22_LANE_RX_N',width=4)
        inst.add_port('DSP_CLK_IN', signal='DSP_CLK_IN') 
        inst.add_port('DSP_RST_IN', signal='DSP_RST_IN') 
        inst.add_port('ADC0_DATA_VAL_OUT', signal='ADC0_DATA_VAL_OUT')
        inst.add_port('ADC0_DATA_OUT', signal='ADC0_DATA_OUT',width=128) 
        inst.add_port('ADC1_DATA_VAL_OUT', signal='ADC1_DATA_VAL_OUT') 
        inst.add_port('ADC1_DATA_OUT', signal='ADC1_DATA_OUT',width=128) 
        inst.add_port('ADC2_DATA_VAL_OUT', signal='ADC2_DATA_VAL_OUT')
        inst.add_port('ADC2_DATA_OUT', signal='ADC2_DATA_OUT',width=128) 
        inst.add_port('ADC3_DATA_VAL_OUT', signal='ADC3_DATA_VAL_OUT')
        inst.add_port('ADC3_DATA_OUT', signal='ADC3_DATA_OUT',width=128) 
        inst.add_port('ADC_SYNC_START_IN', signal='ADC_SYNC_START_IN') 
        inst.add_port('ADC_SYNC_COMPLETE_OUT', signal='ADC_SYNC_COMPLETE_OUT') 
        inst.add_port('PLL_SYNC_START_IN', signal='PLL_SYNC_START_IN') 
        inst.add_port('PLL_SYNC_COMPLETE_OUT', signal='PLL_SYNC_COMPLETE_OUT')
        inst.add_port('AUX_CLK_P', signal='AUX_CLK_P')
        inst.add_port('AUX_CLK_N', signal='AUX_CLK_N') 
        inst.add_port('AUX_SYNCI_P', signal='AUX_SYNCI_P')
        inst.add_port('AUX_SYNCI_N', signal='AUX_SYNCI_N') 
        inst.add_port('AUX_SYNCO_P', signal='AUX_SYNCO_P') 
        inst.add_port('AUX_SYNCO_N', signal='AUX_SYNCO_N')

    def gen_constraints(self):
        # add port constraint to user_const.xdc for 'inout' ()
        return [PortConstraint(self.fullname+'_ext', self.io_group, port_index=range(self.bitwidth), iogroup_index=to_int_list(self.bit_index))]
