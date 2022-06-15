-- Versionsnummer. Diese dient vor allem zu Diagnosezwecken.
-- Ich weiss jetzt noch nicht, wie viele verschiedene Versionen von dem Script spaeter herumfliegen werden.
KsKitVer=0

-- Grundsätzliche Typen von Signalbildern
FAHRT=1
HALT=2
RANGIERFAHRT=3
ERSATZFAHRT=4
AUS=5

-- Signalbilder des Hv-Signalsystems
Hp0={HALT}
Hp1={FAHRT}
Hp2={FAHRT, V_max=40}
Vr0={FAHRT, H_erwarten=true}
Vr1={FAHRT}
Vr2={FAHRT, V_erwarten=40}

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

-- Signalebilder der jeweiligen Signalmodelle
Signalmodelle={
  -- V11NHK10024 HL-Signale der DR *V40* - Grundset
  ["Hl_Signal_Ausfahrt_V40_HK1"]={ Hl13,Hl1,Hl3a,Zs1,Sh1,Hl13 },
  ["Hl_Signal_Ausfahrt_Vmax_HK1"]={ Hl13,Hl1,Zs1,Sh1,Hl13 },
  ["Hl_Signal_Block_HK1"]={ Hl13,Hl1,Zs1,Hl13 },
  ["Hl_Signal_Einfahrt_V40_HK1"]={ Hl13,Hl1,Hl7,Hl10,Hl3a,Hl9a,Hl12a,Zs1,Hl13 },
  ["Hl_Signal_Selbstblock_HK1"]={ Hl13,Hl1,Hl10,Hl13 },
  ["Hl_Signal_Vorsignal_V40_HK1"]={ Hl10,Hl7,Hl1 },
  ["Hl_Signal_Vorsignalwiederholer_V40_HK1"]={ Hl10,Hl7,Hl1 },
  -- V11NHK10025 HL-Signale der DR *V60* - Erweiterungsset
  ["Hl_Signal_Ausfahrt_V60_HK1"]={ Hl13,Hl1,Hl3b,Hl3a,Zs1,Sh1,Hl13 },
  ["Hl_Signal_Einfahrt_V60_HK1"]={ Hl13,Hl1,Hl4,Hl7,Hl10,Hl3b,Hl6b,Hl9b,Hl12b,Hl3a,Hl6a,Hl9a,Hl12a,Zs1,Hl13 },
  ["Hl_Signal_Vorsignalwiederholer_V60_HK1"]={ Hl10,Hl7,Hl1 }
}

--
Signalmeta = {}

Signalmeta.__call= function(table, data)
  local sigobj = {}
  local mt = {}
  mt.__index = table
  setmetatable(sigobj, mt)
  for k, v in pairs(data) do
    local setter = "set_"..tostring(k)
    if type(sigobj[setter]) == "function" then
      sigobj[setter](sigobj, v)
    else
      error("Invalid signal property "..tostring(k))
    end
  end
  return sigobj
end

-- Basisklasse fuer alle Signale
-- Entspricht den Signalen von vor EEP 6: Stellung 1 ist Fahrt, Stellung 2 ist Halt
Basissignal = {
  Begriffe = { Hp1, Hp0 }
}
setmetatable(Basissignal, Signalmeta)

function Basissignal:set_1(v)
  if type(v) ~= "number" then
    error("Signal ID must be number")
  end
  self.ID = v
end

USignal = {}
setmetatable(USignal, Signalmeta)

-- Datenbank fuer Tabelle
KsFahrstrassen = {}

-- Fahrstrasse in Datenbank aufnehmen
function FS(Tabelle)
  KsFahrstrassen[Tabelle[1]] = Tabelle
end

-- Datenbank fuer Signale
KsSignale = {}

-- KsSignale von GK3 sind sehr systematisch benannt, die moeglichen Stellungen lassen sich aus dem Namen herleiten
function GK3KsBegriffe(Modell)
  local Teile = {}
  for str in string.gmatch(Modell, "([^_ ]+)") do
    Teile[str]=true
  end
  local Stellungen = {}

  -- Halt am Hauptsignal
  if Teile["A"] or Teile["B"] then
    table.insert(Stellungen, {"Hp0"})
  end

  -- Halt erwarten
  -- ... am Wiederholer 
  if Teile["VSigWdh"] then
    table.insert(Stellungen, {"Ks2","Kl"})
  end
  -- ... An MAS oder Vorsignalen
  if Teile["MAS"] or Teile["VSig"] then
    if Teile["verkuerzt"] then
      table.insert(Stellungen, {"Ks2","Kl"})
    end
    table.insert(Stellungen, {"Ks2"})
    if Teile["Kl"] then
      table.insert(Stellungen, {"Ks2","Kl"})
    end
  end

  -- Fahrt/Fahrt erwarten
  table.insert(Stellungen, {"Ks1"})

  -- Langsamfahrt erwarten
  -- ... am Wiederholer
  if Teile["VSigWdh"] then
    table.insert(Stellungen, {"Ks1bl","Kl"})
  end
  -- ... am MAS oder Vorsignalen
  if Teile["MAS"] or Teile["VSig"] or Teile["VSigWdh"] then
    if Teile["verkuerzt"] then
      table.insert(Stellungen, {"Ks1bl","Kl"})
    end
    table.insert(Stellungen, {"Ks1bl"})
    if Teile["Kl"] then
      table.insert(Stellungen, {"Ks1bl","Kl"})
    end
  end

  -- Rangierfahrt an Ausfahrsignalen
  if Teile["A"] then
    table.insert(Stellungen, {"Sh1"})
  end

  -- Ersatzsignal an Ausfahrsignalen und Blocksignalen ohne Vorsichtssignal
  if Teile["A"] or (Teile["B"] and not Teile["V"]) then
    table.insert(Stellungen, {"Zs1"})
  end

  -- Vorsichtssignal an Hauptsignalen
  if Teile["V"] then
    table.insert(Stellungen, {"Zs7"})
  end

  -- Kennlicht
  if Teile["Kl"] or Teile["VSigWdh"] or Teile["verkuerzt"] then
    table.insert(Stellungen, {"Kl"})
  end

  -- Dunkel geschaltet
  table.insert(Stellungen, {})
  return Stellungen
end

local GK3KsBauarten={
  "Ks_Sig_A",
  "Ks_Sig_A_MAS",
  "Ks_Sig_A_MAS_Kl",
  "Ks_Sig_A_V",
  "Ks_Sig_A_V_MAS",
  "Ks_Sig_A_V_MAS_Kl",
  "Ks_Sig_B",
  "Ks_Sig_B_MAS",
  "Ks_Sig_B_V",
  "Ks_Sig_B_V_MAS",
  "Ks_Sig_B_V_MAS_Kl",
  "Ks_Sig_VSig",
  "Ks_Sig_VSigWdh",
  "Ks_Sig_VSig_verkuerzt"
}

for cnt=1, #GK3KsBauarten do
  _G[GK3KsBauarten[cnt]]=function(Meta)
    Signal=Meta[1]
    Meta[1] = nil
    -- Falls kein name gegeben, einen generieren
    if Meta.Name == nil then
      Meta.Name = string.format("%d", Signal)
    end
    if type(Meta.Schild) == "number" then
      Meta.Schild="#"..tostring(Meta.Schild)
    end
    Meta.Kennzahl = Kennzahl
    Meta.Begriffe = GK3KsBegriffe(GK3KsBauarten[cnt])
    KsSignale[Signal] = Meta
  end
end

function KsKitInit()
  for Signal, Meta in pairs(KsSignale) do
    if Meta.Schild ~= nil then
      EEPStructureSetTextureText(Meta.Schild, 1, Meta.Kennzahl)
      EEPStructureSetTextureText(Meta.Schild, 2, Meta.Name)
    end
  end
end
