require("Prototype")
require("On")
serpent=require("serpent")

-- Versionsnummer. Diese dient vor allem zu Diagnosezwecken.
-- Ich weiss jetzt noch nicht, wie viele verschiedene Versionen von dem Script spaeter herumfliegen werden.
KsKitVer=0

-- Grundsätzliche Typen von Signalbildern
FAHRT=1
HALT=2
RANGIERFAHRT=3
ERSATZFAHRT=4
AUS=5

-- Grundsignal, entspricht allen Signalen vor EEP 6 sowie dem Unsichtbaren Signal aus dem Grundbestand
Signal=Prototype()

function Signal:init(tab)
  for k,v in pairs(tab) do
    local setter = "set_"..tostring(k)
    if type(self[setter]) == "function" then
      self[setter](self, v)
    else
      error("Signaleigenschaft "..k.." hier nicht erlaubt")
    end
  end
end

-- ID to use with EEPGetSignal/EEPSetSignal
function Signal:set_ID(id)
  if type(id) ~= "number" then error("Signal ID must be a number") end
  self.ID = id
end
Signal.set_1=Signal.set_ID

-- Anfahrtsgeschwindigkeit ans Haltzeigende Signal
function Signal:set_V_halt(v)
  if type(v) ~= "number" then error("V_halt must be number") end
  self.V_halt = v
end

-- Unsichtbares Signal: Zugbeeinflussung
function Signal:set_V_regler(id)
  self.V_regler=id
end

function Signal:set_Begriffe(Begriffe)
  self.RFSS=false -- Rangierfahrstrassenstart
  self.RFSZ=false -- Rangierfahrstrassenziel
  self.ZFSS=false -- Zugfahrstrassenstart
  self.ZFSZ=false -- Zugfahrstrassenziel
  for i=1,#Begriffe do
    if Begriffe[i][1]==RANGIERFAHRT then self.RFSS=true end
    if Begriffe[i][1]==HALT then self.RFSZ=true; self.ZFSZ=true end
    if Begriffe[i][1]==FAHRT then self.ZFSS=true end
  end
  self.Begriffe=Begriffe
end

-- Signalbilder OSJD/EZMG/Hl-Signale des Ostblocks
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

-- V11NHK10024 HL-Signale der DR *V40* - Grundset
Hl_Signal_Ausfahrt_V40=Signal{Begriffe={Hl13,Hl1,Hl3a,Zs1,Sh1,Hl13}}
Hl_Signal_Ausfahrt_Vmax=Signal{Begriffe={Hl13,Hl1,Zs1,Sh1,Hl13}}
Hl_Signal_Block=Signal{Begriffe={Hl13,Hl1,Zs1,Hl13}}
Hl_Signal_Einfahrt_V40=Signal{Begriffe={Hl13,Hl1,Hl7,Hl10,Hl3a,Hl9a,Hl12a,Zs1,Hl13}}
Hl_Signal_Selbstblock=Signal{Begriffe={Hl13,Hl1,Hl10,Hl13}}
Hl_Signal_Vorsignal_V40=Signal{Begriffe={Hl10,Hl7,Hl1}}
Hl_Signal_Vorsignalwiederholer_V40=Signal{Begriffe={Hl10,Hl7,Hl1}}

-- V11NHK10025 HL-Signale der DR *V60* - Erweiterungsset
Hl_Signal_Ausfahrt_V60=Signal{Begriffe={Hl13,Hl1,Hl3b,Hl3a,Zs1,Sh1,Hl13}}
Hl_Signal_Einfahrt_V60=Signal{Begriffe={Hl13,Hl1,Hl4,Hl7,Hl10,Hl3b,Hl6b,Hl9b,Hl12b,Hl3a,Hl6a,Hl9a,Hl12a,Zs1,Hl13}}
Hl_Signal_Vorsignalwiederholer_V60=Signal{Begriffe={Hl10,Hl7,Hl1}}
