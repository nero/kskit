require("Prototype")
require("On")

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
Signal=Prototype{}
Signal.Begriffe={{FAHRT},{HALT}}
Signal.Beschreibung="Signal"

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
  if type(Signale) ~= "table" then Signale={} end
  if Signale[id]~=nil then error("Signal ID "..id.." bereits verwendet") end
  if type(id) ~= "number" then error("Signal ID muss eine Zahl sein") end
  self.ID = id
  Signale[id]=self
end
Signal.set_1=Signal.set_ID

-- Anfahrtsgeschwindigkeit ans Haltzeigende Signal
function Signal:set_V_halt(v)
  if type(v) ~= "number" then error("V_halt muss eine Geschwindigkeit sein") end
  self.V_halt = v
end

-- Unsichtbares Signal: Zum Schalten via GBS
-- ggf. auch vor dem Signal zum Ersatz der Haltefunktion
function Signal:set_S(S)
  self.S = S
  OnSignal(S, function()
    self:Update()
  end)
end

-- Unsichtbares Signal: Zugbeeinflussung, hinter dem Signal
function Signal:set_V_regler(id)
  self.V_regler=id
end

function Signal:set_Begriffe(Begriffe)
  self.Begriffe=Begriffe
end

function Signal:set_Wege(Wege)
  if type(Fahrwege)~="table" then Fahrwege={} end
  self.Wege=Wege
  -- Eigenen Callback an alle potentiellen Wegelemente koppeln
  local updateFunk = function()
    self:Update()
  end
  for i=1,#Wege do
    OnSignal(Wege[i][1], updateFunk)
    if Wege[i].turns then
      for j=1,#Wege[i].turns,2 do
        OnSwitch(Wege[i].turns[j], updateFunk)
      end
    end
  end
end

-- Stellung als struct
function Signal:Zeige(Stellung)
  local order={}
  for i=1,#self.Begriffe do
    table.insert(order, i)
  end
  table.sort(order, function(a,b)
    local StlgA = self.Begriffe[a]
    local StlgB = self.Begriffe[b]
    local props={1,"V_max","H_erwarten","V_erwarten"}
    for i=1,#props do
      -- Folgendes Muster: Wenn Stellung A und B sich in einem Merkmal unterscheiden
      -- UND Stellung A in diesem Merkmal mit der Zielstellung uebereinstimmt,
      -- DANN ist Stellung A besset geeignet, sonst nicht
      if StlgA[props[i]] ~= StlgB[props[i]] then
        if StlgA[props[i]] == Stellung[props[i]] then return true end
        if StlgB[props[i]] == Stellung[props[i]] then return false end
        -- Muster: Geschwindigkeitsmerkmal ist vorhanden und kleiner als Ziel, aber der Vergleichsbegriff:
        -- - zeigt das Merkmal gar nicht
        -- - zeigt eine hohere Geschwindigkeit als gewollt
        -- - zeigt eine noch kleinere Geschwindigkeit
        -- Dann ist der Vergleichsbegriff schlechter geeignet
        if i == 2 or i == 4 then
          if StlgA[props[i]] and Stellung[props[i]] and StlgA[props[i]] < Stellung[props[i]] then
            if StlgB[props[i]] == nil then return true end
            if StlgB[props[i]] > Stellung[props[i]] then return true end
            if StlgB[props[i]] < StlgA[props[i]] then return true end
          end
          if StlgB[props[i]] and Stellung[props[i]] and StlgB[props[i]] < Stellung[props[i]] then
            if StlgA[props[i]] == nil then return false end
            if StlgA[props[i]] > Stellung[props[i]] then return false end
            if StlgA[props[i]] < StlgB[props[i]] then return false end
          end
        end
      end
    end
    return false
  end)
  EEPSetSignal(self.ID, order[1], 1)
  return true
end

-- Fahrtstellung aktualisieren
function Signal:Update()
  local Fahrt = true
  if self.S and EEPGetSignal(self.S) == 2 then
    Fahrt = false
  end
  if not Fahrt then
    if self:Zeige{HALT} then return end
    self:Zeige{FAHRT, H_erwarten}
    return
  end

  local Stlg = {FAHRT}
  if self.Wege then
    for i=1,#self.Wege do
      local Weg = self.Wege[i]
      local match = true
      local V_max = nil
      if Weg.turns then
        for j=1,#Weg.turns,2 do
          if Weg.turns[j+1] > 1 then V_max = 40 end
          if EEPGetSwitch(Weg.turns[j]) ~= Weg.turns[j+1] then
            match = false
          end
        end
      end
      if match then Stlg.V_max = V_max end
    end
  end

  if self:Zeige(Stlg) then return end
  if self:Zeige{ERSATZFAHRT} then return end
end

function Signal:set_Beschreibung(v)
  self.Beschreibung=v
end

function Signal:TooltipText()
  r=self.Beschreibung.." "..tonumber(self.ID).."\n"
  return r
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

-- Zusatzsignale
Zs1={ERSATZFAHRT}
Ra10={HALT, Nur_Rangierfahrten=true} -- Rangierhalttafel
Ra11={HALT, Nur_Rangierfahrten=true} -- Wartezeichen
Sh1={RANGIERFAHRT} -- war Ra12 bei DR

Rangierhalttafel=Signal{Begriffe={{FAHRT},Ra10},Beschreibung="Rangierhalttafel"}

-- V11NHK10024 HL-Signale der DR *V40* - Grundset
Hl_Signal_Ausfahrt_V40=Signal{Begriffe={Hl13,Hl1,Hl3a,Zs1,Sh1,Hl13},Beschreibung="Ausfahrsignal"}
Hl_Signal_Ausfahrt_Vmax=Signal{Begriffe={Hl13,Hl1,Zs1,Sh1,Hl13},Beschreibung="Ausfahrsignal"}
Hl_Signal_Block=Signal{Begriffe={Hl13,Hl1,Zs1,Hl13},Beschreibung="Blocksignal"}
Hl_Signal_Einfahrt_V40=Signal{Begriffe={Hl13,Hl1,Hl7,Hl10,Hl3a,Hl9a,Hl12a,Zs1,Hl13},Beschreibung="Einfahrsignal"}
Hl_Signal_Selbstblock=Signal{Begriffe={Hl13,Hl1,Hl10,Hl13},Beschreibung="Blocksignal"}
Hl_Signal_Vorsignal_V40=Signal{Begriffe={Hl10,Hl7,Hl1},Beschreibung="Vorsignal"}
Hl_Signal_Vorsignalwiederholer_V40=Signal{Begriffe={Hl10,Hl7,Hl1},Beschreibung="Vorsignalwdh"}

-- V11NHK10025 HL-Signale der DR *V60* - Erweiterungsset
Hl_Signal_Ausfahrt_V60=Signal{Begriffe={Hl13,Hl1,Hl3b,Hl3a,Zs1,Sh1,Hl13}}
Hl_Signal_Einfahrt_V60=Signal{Begriffe={Hl13,Hl1,Hl4,Hl7,Hl10,Hl3b,Hl6b,Hl9b,Hl12b,Hl3a,Hl6a,Hl9a,Hl12a,Zs1,Hl13}}
Hl_Signal_Vorsignalwiederholer_V60=Signal{Begriffe={Hl10,Hl7,Hl1}}

Hl_Zwerg_Rangiersignal=Signal{Begriffe={Ra11,Sh1},Beschreibung="Rangierhaltsignal"}
