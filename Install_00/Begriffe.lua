-- Grundsätzliche Typen von Signalbildern
HALT=1
FAHRT=2
RANGIERFAHRT=3
ERSATZFAHRT=4
AUS=5

-- Hv-Signalsystem
Hp0={HALT}
Hp1={FAHRT}
Hp2={FAHRT, V_max=40}
Hp1Vr0={FAHRT, H_erwarten=true}
Hp1Vr1={FAHRT}
Hp1Vr2={FAHRT, V_erwarten=40}
Hp2Vr0={FAHRT, V_max=40, H_erwarten=true}
Hp2Vr1={FAHRT, V_max=40}
Hp2Vr2={FAHRT, V_max=40, V_erwarten=40}

-- OSJD/EZMG/Hl-Signale des Ostblocks
-- V_erwarten=60 wird durch V_erwarten=40 signalisiert
Hl1={FAHRT}
Hl2={FAHRT, V_max=100}
Hl3a={FAHRT, V_max=40}
Hl3b={FAHRT, V_max=60}
Hl4={FAHRT, V_erwarten=100}
Hl5={FAHRT, V_max=100, V_erwarten=100}
Hl6a={FAHRT, V_max=40, V_erwarten=100}
Hl6b={FAHRT, V_max=60, V_erwarten=100}
Hl7={FAHRT, V_erwarten=40}
Hl8={FAHRT, V_max=100, V_erwarten=40}
Hl9a={FAHRT, V_max=40, V_erwarten=40}
Hl9b={FAHRT, V_max=60, V_erwarten=40}
Hl10={FAHRT, H_erwarten=true}
Hl11={FAHRT, V_max=100, H_erwarten=true}
Hl12a={FAHRT, V_max=40, H_erwarten=true}
Hl12b={FAHRT, V_max=60, H_erwarten=true}
Hl13={HALT}

-- Zusatzsignale (DS 301 Namen)
Zs1={ERSATZFAHRT}
Sh1={RANGIERFAHRT} -- war Ra12 bei DR

function BegriffErklaeren(Begriff)
  if Begriff[1]==HALT then return "Halt" end
  if Begriff[1]==RANGIERFAHRT then return "Rangierfahrt" end
  if Begriff[1]==ERSATZFAHRT then return "Fahrt auf Ersatzsignal" end
  if Begriff[1]==AUS then return "Signal ausgeschaltet" end
  local txt = "Fahrt"
  if Begriff.H_erwarten ~= nil then
    txt = "Halt erwarten"
    if Begriff.kurz ~= nil then
      txt = "Halt im verkürzten Abstand"
    end
  end
  if Begriff.V_max then
    txt = txt.." mit "..tostring(Begriff.V_max).." km/h"
  end
  if Begriff.V_erwarten then
    txt = txt..", "..tostring(Begriff.V_erwarten).." km/h erwarten"
  end
  return txt
end
