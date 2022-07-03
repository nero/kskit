-- Begriffe, die mit dieser Funktion definiert werden, lassen sich aufaddieren
function Zusatzbegriff(r)
  return setmetatable(r, {
    __add = function(a, b)
     local r={}
     local l={1,2,"V_max","H_erwarten","V_erwarten","Kurz"}
     for i=1,#l do
       if b[l[i]] ~= nil then
         r[l[i]]=b[l[i]]
       elseif a[l[i]] ~= nil then
         r[l[i]]=a[l[i]]
       end
     end
     return r
   end
  })
end

-- HV-Signale der DR/DB
Hp0={ false }
Hp1={ true, Zugfahrt=true }
Hp2={ true, Zugfahrt=true, V_max=40 }

Vr0=Zusatzbegriff{ H_erwarten=true }
Vr1=Zusatzbegriff{ }
Vr2=Zusatzbegriff{ V_erwarten=40 }
Kurz=Zusatzbegriff{ Kurz=true }

-- OSJD/EZMG/Hl-Signale des Ostblocks
-- V_erwarten=60 wird durch V_erwarten=40 signalisiert
Hl1={ true, Zugfahrt=true }
Hl2={ true, Zugfahrt=true, V_max=100 }
Hl3a={ true, Zugfahrt=true, V_max=40 }
Hl3b={ true, Zugfahrt=true, V_max=60 }
Hl4={ true, Zugfahrt=true, V_erwarten=100 }
Hl5={ true, Zugfahrt=true, V_max=100, V_erwarten=100 }
Hl6a={ true, Zugfahrt=true, V_max=40, V_erwarten=100 }
Hl6b={ true, Zugfahrt=true, V_max=60, V_erwarten=100 }
Hl7={ true, Zugfahrt=true, V_erwarten=40 }
Hl8={ true, Zugfahrt=true, V_max=100, V_erwarten=40 }
Hl9a={ true, Zugfahrt=true, V_max=40, V_erwarten=40 }
Hl9b={ true, Zugfahrt=true, V_max=60, V_erwarten=40 }
Hl10={ true, Zugfahrt=true, H_erwarten=true }
Hl11={ true, Zugfahrt=true, V_max=100, H_erwarten=true }
Hl12a={ true, Zugfahrt=true, V_max=40, H_erwarten=true }
Hl12b={ true, Zugfahrt=true, V_max=60, H_erwarten=true }
Hl13={ false }

-- Ks-Signalsystem ab 1994
-- Zs3/Zs3v aufaddieren!
Ks1={ true, Zugfahrt=true }
Ks1bl={ true, Zugfahrt=true, V_erwarten=160 }
Ks2={ true, Zugfahrt=true, H_erwarten=true }

Zs1={ true, Ersatzsignal=true }
Zs7={ true, Vorsichtssignal=true, V_max=40 }

Sh0={ false }
Sh1={ true }
Rangierfahrt={ true, V_max=25 }

-- Ist Key 1 gleich nil -> Signal ignorieren
Kennlicht={ }
Aus={ }

for i=2,15 do
  _G["Zs3_"..tostring(i)]=Zusatzbegriff{ V_max=i*10 }
  _G["Zs3v_"..tostring(i)]=Zusatzbegriff{ V_erwarten=i*10 }
end

SignalModellBegriffe = {
  ["HlSigAV40Betno_GK3"]={},
  ["HlSigAV40BetnolaSch_GK3"]={},
  ["HlSigAV60Betnor_GK3"]={Hl13,Hl1,Hl3b,Hl3a,Rangierfahrt,Zs1,Hl13,Aus},
  ["HlSigAVmaxBetno_GK3"]={},
  ["HlSigAVmaxBetnolaS_GK3"]={},
  ["HlSigAZBetno_GK3"]={Hl13,Hl1,Hl4,Hl7,Hl10,Hl3a,Hl9a,Hl6a,Hl12a,Rangierfahrt,Zs1,Hl13},
  ["HlSigAZBetnolaS_GK3"]={},
  ["HlSigAZV40Betno_GK3"]={},
  ["HlSigAZV40BetnolaS_GK3"]={},
  ["HlSigAZV602Betno_GK3"]={Hl13,Hl1,Hl4,Hl7,Hl10,Hl3b,Hl6b,Hl9b,Hl12b,Hl3a,Hl6a,Hl9a,Hl12a,Rangierfahrt,Zs1,Hl13,Aus},
  ["HlSigAZV60Betno_GK3"]={Hl13,Hl7,Hl10,Hl9b,Hl12b,Hl9a,Hl12a,Rangierfahrt,Zs1,Hl13,Aus},
  ["HlSigAZVmax2Betno_GK3"]={},
  ["HlSigAZVmax2BetnolaS_GK3"]={},
  ["HlSigAZVmaxBetno_GK3"]={},
  ["HlSigAZVmaxBetnolaS_GK3"]={},
  ["HlSigBlockBetno_GK3"]={},
  ["HlSigBlockBetnolaS_GK3"]={},
  ["HlSigBueSo16B_GK3"]={Hl13,Sh1,Aus},
  ["HlSigEBetno_GK3"]={},
  ["HlSigEBetnolaS_GK3"]={},
  ["HlSigEV402Betno_GK3"]={},
  ["HlSigEV402BetnolaS_GK3"]={},
  ["HlSigEV40Betno_GK3"]={},
  ["HlSigEV40BetnolaS_GK3"]={},
  ["HlSigEV602Betno_GK3"]={Hl13,Hl1,Hl3b,Hl3a,Zs1,Hl13,Aus},
  ["HlSigEV603Betno_GK3"]={Hl13,Hl7,Hl10,Hl9b,Hl12b,Hl9a,Hl12a,Zs1,Hl13,Aus},
  ["HlSigEV60Betno_GK3"]={Hl13,Hl1,Hl4,Hl7,Hl10,Hl3b,Hl6b,Hl9b,Hl12b,Hl3a,Hl6a,Hl9a,Hl12a,Zs1,Hl13,Aus},
  ["HlSigEVmax2Betno_GK3"]={},
  ["HlSigEVmax2BetnolaS_GK3"]={},
  ["HlSigEVmaxBetno_GK3"]={},
  ["HlSigEVmaxBetnolaS_GK3"]={},
  ["HlSig_A_Vmax"]={Hl1,Hl13},
  ["HlSig_B"]={Hl1,Hl13},
  ["HlSig_E_Vhalt"]={Hl10,Hl13},
  ["Hl_Sig_A1_HK1"]={Hl13,Hl1,Zs1,Rangierfahrt,Hl13},
  ["Hl_Sig_A2_HK1"]={Hl13,Hl1,Hl3a,Zs1,Rangierfahrt,Hl13},
  ["Hl_Sig_A3_Ls_HK1"]={Hl13,Hl1,Hl3b,Hl3a,Zs1,Rangierfahrt,Hl13},
  ["Hl_Sig_B_HK1"]={Hl13,Hl1,Zs1,Hl13},
  ["Hl_Sig_E1_HK1"]={Hl13,Hl1,Hl7,Hl10,Hl3a,Hl9a,Hl12a,Zs1,Hl13},
  ["Hl_Sig_E2_Ls_HK1"]={Hl13,Hl1,Hl4,Hl7,Hl10,Hl3b,Hl6b,Hl9b,Hl12b,Hl3a,Hl6a,Hl9a,Hl12a,Zs1,Hl13},
  ["Hl_Sig_SB_HK1"]={Hl13,Hl1,Hl10,Hl13},
  ["Hl_Sig_Vs40_HK1"]={Hl10,Hl7,Hl1},
  ["Hl_Sig_Vs40_Wh_HK1"]={Hl10,Hl7,Hl1},
  ["Hl_Sig_Vs60_HK1"]={Hl10,Hl7,Hl1},
  ["Hl_Sig_Vs60_Wh_HK1"]={Hl10,Hl7,Hl1},
  ["Hl_Sig_ZBF_1_1_HK1"]={Hl13,Kennlicht},
  ["Hl_Sig_ZBF_1_2_HK1"]={Hl13,Kennlicht,Rangierfahrt,Hl13},
  ["Hl_Sig_ZBF_2_1_HK1"]={Hl13,Kennlicht,Hl13},
  ["Hl_Sig_ZBF_2_2_HK1"]={Hl13,Kennlicht,Rangierfahrt,Hl13},
  ["Hl_Zwerg_Hl_HK1"]={Hl13,Hl1,Hl10,Hl3a,Zs1,Rangierfahrt},
  ["Hl_Zwerg_Ra_HK1"]={Aus,Rangierfahrt},
  ["HpSig_AZ_V40_Vs_69_V7"]={Hp0,Hp1+Vr0,Hp1+Vr1,Hp1+Vr2,Hp2+Vr0,Hp2+Vr1,Hp2+Vr2,Rangierfahrt},
  ["HpSig_AZ_Vmax_Vs_69_V7"]={Hp0,Hp1+Vr0,Hp1+Vr1,Hp1+Vr2,Rangierfahrt},
  ["HpSig_A_V100_69_V8"]={Hp0,Hp1,Hp1+Zs3_10,Hp2,Rangierfahrt},
  ["HpSig_A_V100_Vs_69_V8"]={Hp0,Hp1+Vr0,Hp1+Vr1,Hp1+Zs3_10+Vr0,Hp1+Zs3_10+Vr1,Hp2+Vr0,Hp2+Vr1,Rangierfahrt},
  ["HpSig_A_V40_69_V7"]={Hp0,Hp1,Hp2,Rangierfahrt},
  ["HpSig_A_V40_EpIV"]={Hp2,Hp0},
  ["HpSig_A_V40_Vr0_EpIV"]={Hp2+Vr0,Hp0},
  ["HpSig_A_V40_Vs_69_V7"]={Hp0,Hp1+Vr0,Hp1+Vr1,Hp2+Vr0,Hp2+Vr1,Rangierfahrt},
  ["HpSig_A_V60_69_V8"]={Hp0,Hp1,Hp2+Zs3_6,Hp2,Rangierfahrt},
  ["HpSig_A_V60_80_69_V8"]={Hp0,Hp1,Hp1+Zs3_8,Hp2+Zs3_6,Hp2,Rangierfahrt},
  ["HpSig_A_V60_80_Vs_69_V8"]={Hp0,Hp1+Vr0,Hp1+Vr1,Hp1+Zs3_8+Vr0,Hp1+Zs3_8+Vr1,Hp2+Zs3_6+Vr0,Hp2+Zs3_6+Vr1,Hp2+Vr0,Hp2+Vr1,Rangierfahrt},
  ["HpSig_A_V60_Vs_69_V8"]={Hp0,Hp1+Vr0,Hp1+Vr1,Hp2+Zs3_6+Vr0,Hp2+Zs3_6+Vr1,Hp2+Vr0,Hp2+Vr1,Rangierfahrt},
  ["HpSig_A_V80_69_V8"]={Hp0,Hp1,Hp1+Zs3_8,Hp2,Rangierfahrt},
  ["HpSig_A_V80_Vs_69_V8"]={Hp0,Hp1+Vr0,Hp1+Vr1,Hp1+Zs3_8+Vr0,Hp1+Zs3_8+Vr1,Hp2+Vr0,Hp2+Vr1,Rangierfahrt},
  ["HpSig_A_Vmax_69_V7"]={Hp0,Hp1,Rangierfahrt},
  ["HpSig_A_Vmax_Vs_69_V7"]={Hp0,Hp1+Vr0,Hp1+Vr1,Rangierfahrt},
  ["HpSig_A_Vmax_Vr0_EpIV"]={Hp1+Vr0,Hp0},
  ["HpSig_Ae_V100_69_V8"]={Hp0,Hp1,Hp1+Zs3_10,Rangierfahrt},
  ["HpSig_Ae_V100_Vs_69_V8"]={Hp0,Hp1+Vr0,Hp1+Vr1,Hp1+Zs3_10+Vr0,Hp1+Zs3_10+Vr1,Rangierfahrt},
  ["HpSig_Ae_V120_69_V8"]={Hp0,Hp1,Hp1+Zs3_12,Rangierfahrt},
  ["HpSig_Ae_V80_69_V8"]={Hp0,Hp1,Hp1+Zs3_8,Rangierfahrt},
  ["HpSig_Ae_V80_Vs_69_V8"]={Hp0,Hp1+Vr0,Hp1+Vr1,Hp1+Zs3_8+Vr0,Hp1+Zs3_8+Vr1,Rangierfahrt},
  ["HpSig_B_69_V7"]={},
  ["HpSig_B_Vswg_69_V7"]={},
  ["HpSig_B_Vswg_oVSig_69_V7"]={},
  ["HpSig_B_Vswr_69_V7"]={},
  ["HpSig_B_Vswr_oVSig_69_V7"]={},
  ["HpSig_B_oVSig_69_V7"]={},
  ["HpSig_EZ_V40_Vs_69_V7"]={Hp2,Hp0},
  ["HpSig_EZw_V40_Vr0_EpIV"]={Hp2+Vr0,Hp0},
  ["HpSig_EZw_Vmax_Vr0_EpIV"]={Hp1,Hp0},
  ["HpSig_E_V100_69_V8"]={},
  ["HpSig_E_V100_Vs_69_V8"]={},
  ["HpSig_E_V100_Vs_V60_69_V8"]={},
  ["HpSig_E_V100_Vs_V60_l_69_V8"]={},
  ["HpSig_E_V100_Vs_V80_69_V8"]={},
  ["HpSig_E_V100_Vs_V80_l_69_V8"]={},
  ["HpSig_E_V100_Vs_l_69_V8"]={},
  ["HpSig_E_V100_l_69_V8"]={},
  ["HpSig_E_V20_30_69_V8"]={},
  ["HpSig_E_V20_30_l_69_V8"]={},
  ["HpSig_E_V20_69_V8"]={},
  ["HpSig_E_V20_l_69_V8"]={},
  ["HpSig_E_V30_69_V8"]={},
  ["HpSig_E_V30_l_69_V8"]={},
  ["HpSig_E_V40_69_V7"]={},
  ["HpSig_E_V40_Vr0_EpIV"]={Hp2+Vr0,Hp0},
  ["HpSig_E_V40_Vs_69_V7"]={},
  ["HpSig_E_V40_Vs_V100_69_V8"]={},
  ["HpSig_E_V40_Vs_V100_l_69_V8"]={},
  ["HpSig_E_V40_Vs_V20_30_69_V8"]={},
  ["HpSig_E_V40_Vs_V20_30_l_69_V8"]={},
  ["HpSig_E_V40_Vs_V20_69_V8"]={},
  ["HpSig_E_V40_Vs_V20_l_69_V8"]={},
  ["HpSig_E_V40_Vs_V30_69_V8"]={},
  ["HpSig_E_V40_Vs_V30_l_69_V8"]={},
  ["HpSig_E_V40_Vs_V60_69_V8"]={},
  ["HpSig_E_V40_Vs_V60_80_69_V8"]={},
  ["HpSig_E_V40_Vs_V60_80_l_69_V8"]={},
  ["HpSig_E_V40_Vs_V60_l_69_V8"]={},
  ["HpSig_E_V40_Vs_V80_69_V8"]={},
  ["HpSig_E_V40_Vs_V80_l_69_V8"]={},
  ["HpSig_E_V40_Vs_l_69_V7"]={},
  ["HpSig_E_V40_l_69_V7"]={},
  ["HpSig_E_V60_69_V8"]={},
  ["HpSig_E_V60_80_69_V8"]={},
  ["HpSig_E_V60_80_Vs_69_V8"]={},
  ["HpSig_E_V60_80_Vs_l_69_V8"]={},
  ["HpSig_E_V60_80_l_69_V8"]={},
  ["HpSig_E_V60_Vs_69_V8"]={},
  ["HpSig_E_V60_Vs_l_69_V8"]={},
  ["HpSig_E_V60_l_69_V8"]={},
  ["HpSig_E_V80_69_V8"]={},
  ["HpSig_E_V80_I_69_V8_"]={},
  ["HpSig_E_V80_Vs_69_V8"]={},
  ["HpSig_E_V80_Vs_l_69_V8"]={},
  ["HpSig_E_V80_l_69_V8"]={},
  ["HpSig_E_Vmax_Vr0_EpIV"]={Hp1+Vr0,Hp0},
  ["KS_HS_A_RI1"]={},
  ["KS_HS_A_Zs3_RI1"]={},
  ["KS_HS_E_RI1"]={},
  ["KS_HS_E_Zs3_RI1"]={},
  ["KS_HS_R_RI1"]={},
  ["KS_MA_A_RI1"]={},
  ["KS_MA_A_Zs3_RI1"]={},
  ["KS_MA_A_Zs3_Zs3v_RI1"]={},
  ["KS_MA_A_Zs3v_RI1"]={},
  ["KS_MA_E_RI1"]={},
  ["KS_MA_E_Zs3_RI1"]={},
  ["KS_MA_E_Zs3_Zs3v_RI1"]={},
  ["KS_MA_E_Zs3v_RI1"]={},
  ["KS_VS2_RI1"]={},
  ["KS_VSW_RI1"]={},
  ["KS_VSW_Zs3v_RI1"]={},
  ["KS_VS_RI1"]={},
  ["KS_VS_Zs3v_RI1"]={},
  ["KabKaSchSignalA_TB1"]={},
  ["KabKaSchSignalB_TB1"]={},
  ["KabKaSchSignal_TB1"]={},
  ["KsMastSigZs32_GK3"]={},
  ["KsMastSigZs3_GK3"]={},
  ["KsMastSigZs3v2_GK3"]={},
  ["KsMastSigZs3v_GK3"]={},
  ["KsMastSigZs6Zs13_GK3"]={},
  ["KsSigAKAMASKl_GK3"]={},
  ["KsSigAKAMASKlli_GK3"]={},
  ["KsSigAKAMAS_GK3"]={},
  ["KsSigAKAMASli_GK3"]={},
  ["KsSigAKA_GK3"]={},
  ["KsSigAKAli_GK3"]={},
  ["KsSigALAMASKl_GK3"]={},
  ["KsSigALAMASKlli_GK3"]={},
  ["KsSigALAMAS_GK3"]={},
  ["KsSigALAMASli_GK3"]={},
  ["KsSigALA_GK3"]={},
  ["KsSigALAli_GK3"]={},
  ["KsSigAMASKl_GK3"]={},
  ["KsSigAMAS_GK3"]={},
  ["KsSigAVKAMASKl_GK3"]={},
  ["KsSigAVKAMASKlli_GK3"]={},
  ["KsSigAVKAMAS_GK3"]={},
  ["KsSigAVKAMASli_GK3"]={},
  ["KsSigAVKA_GK3"]={},
  ["KsSigAVKAli_GK3"]={},
  ["KsSigAVLAMASKl_GK3"]={},
  ["KsSigAVLAMASKlli_GK3"]={},
  ["KsSigAVLAMAS_GK3"]={},
  ["KsSigAVLAMASli_GK3"]={},
  ["KsSigAVLA_GK3"]={},
  ["KsSigAVLAli_GK3"]={},
  ["KsSigAVMASKl_GK3"]={},
  ["KsSigAVMAS_GK3"]={},
  ["KsSigAV_GK3"]={},
  ["KsSigA_GK3"]={},
  ["KsSigBKAMAS_GK3"]={},
  ["KsSigBKAMASli_GK3"]={},
  ["KsSigBKA_GK3"]={},
  ["KsSigBKAli_GK3"]={},
  ["KsSigBLAMAS_GK3"]={},
  ["KsSigBLAMASli_GK3"]={},
  ["KsSigBLA_GK3"]={},
  ["KsSigBLAli_GK3"]={},
  ["KsSigBMAS_GK3"]={},
  ["KsSigBVKAMASKl_GK3"]={},
  ["KsSigBVKAMASKlli_GK3"]={},
  ["KsSigBVKAMAS_GK3"]={},
  ["KsSigBVKAMASli_GK3"]={},
  ["KsSigBVKA_GK3"]={},
  ["KsSigBVKAli_GK3"]={},
  ["KsSigBVLAMASKl_GK3"]={},
  ["KsSigBVLAMASKlli_GK3"]={},
  ["KsSigBVLAMAS_GK3"]={},
  ["KsSigBVLAMASli_GK3"]={},
  ["KsSigBVLA_GK3"]={},
  ["KsSigBVLAli_GK3"]={},
  ["KsSigBVMASKl_GK3"]={},
  ["KsSigBVMAS_GK3"]={},
  ["KsSigBV_GK3"]={},
  ["KsSigB_GK3"]={},
  ["KsSigVSigKA_GK3"]={},
  ["KsSigVSigKAli_GK3"]={},
  ["KsSigVSigLA_GK3"]={},
  ["KsSigVSigLAli_GK3"]={},
  ["KsSigVSigWdhKA_GK3"]={},
  ["KsSigVSigWdhKAli_GK3"]={},
  ["KsSigVSigWdhLA_GK3"]={},
  ["KsSigVSigWdhLAli_GK3"]={},
  ["KsSigVSigWdh_GK3"]={},
  ["KsSigVSig_GK3"]={},
  ["KsSigVSigverkKA_GK3"]={},
  ["KsSigVSigverkKAli_GK3"]={},
  ["KsSigVSigverkLA_GK3"]={},
  ["KsSigVSigverkLAli_GK3"]={},
  ["KsSigVSigverk_GK3"]={},
  ["PI5_HP01_Form"]={Hp0,Hp1},
  ["PI5_HP01_Form_oVSig"]={Hp0,Hp1},
  ["PI5_HP02_Form"]={Hp0,Hp1,Hp2},
  ["PI5_HP02_Form_V60T"]={Hp0,Hp1,Hp2+Zs3_6},
  ["PI5_HP02_Form_V60T_oVSig"]={Hp0,Hp1,Hp2+Zs3_6},
  ["PI5_HP02_Form_Vr0"]={Hp0,Hp1,Hp1+Vr2,Hp2+Vr0},
  ["PI5_HP02_Form_Vr0_oVSig"]={Hp0,Hp1,Hp1+Vr2,Hp2+Vr0},
  ["PI5_HP02_Form_oVSig"]={Hp0,Hp1,Hp2},
  ["PI5_RaSig_mech"]={},
  ["PI5_ShSig_Form"]={},
  ["ShSig_Form"]={Sh1,Sh0},
  ["ShSig_Licht_EpIV"]={Sh1,Sh0},
  ["ShSig_Licht_EpIV_kl"]={Sh1,Sh0},
  ["SperrSig_DS100_RI1"]={Hp0,Kennlicht,Rangierfahrt,Sh1},
  ["SperrSig_DS100_haeng2_RI1"]={Hp0,Kennlicht,Rangierfahrt,Sh1},
  ["SperrSig_DS100_haeng_RI1"]={Hp0,Kennlicht,Rangierfahrt,Sh1},
  ["SperrSig_DS100_hoch_RI1"]={Hp0,Kennlicht,Rangierfahrt,Sh1},
  ["Wartesignal_DR_alt_HK1"]={Sh0,Rangierfahrt},
  ["Wartesignal_DR_neu_HK1"]={Sh0,Rangierfahrt},
}

function BegriffErklaeren(Begriff)
  if Begriff == nil then return "nil", "" end
  if Begriff[1]==false then
    return "Halt", "<fgrgb=255,255,255><bgrgb=255,0,0>"
  elseif Begriff[1]==nil then
    return "Abgeschaltet", ""
  end
  local txt = "Fahrt"
  local farbe = "<fgrgb=0,0,0><bgrgb=0,255,0>"
  if Begriff.H_erwarten ~= nil or Begriff.V_max then
    farbe = "<fgrgb=0,0,0><bgrgb=255,255,0>"
  end
  if Begriff.Ersatzsignal or Begriff.Vorsichtssignal then
    farbe = "<fgrgb=255,255,255><bgrgb=0,0,0>"
  end
  if Begriff.Vorsichtssignal then txt = txt.." auf Sicht" end
  if Begriff.V_max then
    txt = txt.." mit "..tostring(Begriff.V_max).." km/h"
  end
  if Begriff.V_erwarten then
    txt = txt..", "..tostring(Begriff.V_erwarten).." km/h erwarten"
  end
  if Begriff.H_erwarten ~= nil then
    txt = txt..", Halt erwarten"
  end
  if Begriff.kurz then
    txt = txt.." (kurzer Bremsweg)"
  end
  return txt, farbe
end

function SignalmodelleAusAnlagendatei(Datei)
  local fd = io.open(Datei, "r")
  local xml = fd:read("*a")

  Signalmodelle={}

  for capture in string.gmatch(xml, "<Meldung .- name=\".-\" Key_Id=\"%d*\"") do
    local Model, ID = string.match(capture, 'name=\"(.-)\" Key_Id=\"(%d+)\"')
    if not string.match(Model, "system/") then
      Signalmodelle[ID]=Model
    end
  end

  return Signalmodelle
end


function leseSignalMitModell(ID, Modell, Stellung)
  local Stellung = Stellung or EEPGetSignal(ID)
  if SignalModellBegriffe[Modell] ~= nil then
    return SignalModellBegriffe[Modell][Stellung]
  else
    local Defaults={Hp1,Hp0}
    return Defaults[Stellung]
  end
end
