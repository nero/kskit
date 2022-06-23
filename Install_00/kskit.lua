require("BetterContacts_BH2"){printErrors=true, deprecatedUseGlobal=true}
require("Begriffe")

-- Tabelle in einen String umwandeln, rekursiv
-- Funktionswerte werden ignoriert
function __tostring(self)
  local t=type(self)
  if t=="table" then
    local r=""
    -- load and sort table keys
    local tkeys={}
    for k in pairs(self) do table.insert(tkeys, k) end
    table.sort(tkeys, function(a,b) return tostring(a)<tostring(b) end)
    -- iterate over our table
    for _,k in ipairs(tkeys) do
      local v = __tostring(self[k])
      -- ignore nil values, they unset the key anyways
      if v~= nil and v ~= "nil" then
        if r~="" then r=r.."," end
        -- short format: foo="bar", saves bytes
        if type(k)=="string" and k:match("^[%l%u_][%w_]*$") then
          r=r..k.."="..v
        -- long format: ["foo"]="bar", allows weird keys
        else
          r=r.."["..__tostring(k).."]="..v
        end
      end
    end
    return "{"..r.."}"
  elseif t=="number" or t=="boolean" then
    return tostring(self)
  elseif t=="string" then
    return ("%q"):format(self)
  else
    return "nil"
  end
end

-- Da wir jetzt ohnehin Tabellen in Strings umwandeln koennen, patchen wir
--   print(...) damit diese von dieser Darstellung profitieren kann.
do
  local oldprint=print
  function print(...)
    local args={...}
    for i=1,#args do
      if type(args[i]) == "table" then
        args[i]=__tostring(args[i])
      end
    end
    oldprint(table.unpack(args))
  end
end

-- Tabelle in beliebigen Slot speichern
-- Im Slot steht dann eine Lua-Tabelle als String
-- Formatierungszeichen werden URL-encoded, damit EEP mit ihren zurecht kommt
-- Speziell Hochkommas haben mir immer meine Daten abgeschnitten...
function speicherTabelle(Slotnummer, Tabelle)
  local s=__tostring(Tabelle):gsub("([%c%%\"])", function(c)
    return string.format("%%%02X", string.byte(c))
  end)
  EEPSaveData(Slotnummer, s)
end

-- Tabelle aus beliebigen Slot laden
-- Sind die Daten nicht lesbar, wird eine leere Tabelle zurueckgegeben
function ladeTabelle(Slotnummer)
  local ok, raw = EEPLoadData(Slotnummer)
  if not ok then
    print("WARNUNG: Daten im Slot ",Slotnummer," unleserlich")
    return {}
  end
  return load("return "..raw:gsub("%%(%x%x)", function(x)
    return string.char(tonumber(x, 16))
  end))()
end

function AnimiereFahrzeugStromabnehmer(Fahrzeug, Richtung)
  local Index, _ = Fahrzeug:gsub(";%d*$","")
  local Angelegt = false
  if Stromabnehmer[Index] then
    local Achsen = Stromabnehmer[Index]
    for i=1,#Achsen do
      if (i == 1 and Richtung == -1) or (i == #Achsen and Richtung == 1) then
        EEPRollingstockSetAxis(Fahrzeug, Achsen[i], 100)
        Angelegt = true
      else
        EEPRollingstockSetAxis(Fahrzeug, Achsen[i], 0)
      end
    end
  end
  return Angelegt
end

-- Richtung: -1, 0 oder 1
function setzeStromabnehmer(Zug, Richtung)
  local AnzahlFahrzeuge = EEPGetRollingstockItemsCount(Zug)
  local Startwert = 1
  local Endwert = AnzahlFahrzeuge
  local Schritt = 1
  if Richtung > 0 then
    Startwert = AnzahlFahrzeuge
    Endwert = 1
    Schritt = -1
  end
  for i=Startwert,Endwert,Schritt do
    local Fahrzeug = EEPGetRollingstockItemName(Zug, i-1)
    local ok, Vorwaerts = EEPRollingstockGetOrientation(Fahrzeug)
    if ok and not Vorwaerts then
      if AnimiereFahrzeugStromabnehmer(Fahrzeug, -1 * Richtung) then Richtung = 0 end
    else
      if AnimiereFahrzeugStromabnehmer(Fahrzeug, Richtung) then Richtung = 0 end
    end
  end
end

function leseSignal(Signal)
  if EEPGetSignal(Signal) == 1 then
    return {FAHRT}
  else 
    return {HALT}
  end
end

local GefundeneSignale={}
local Zugaktionen=ladeTabelle(1)
local SignalChanged={}

setmetatable(Zugaktionen, {
  __index=function(table, key)
    table[key]={}
    return table[key]
  end
})

function KsKitInit()
  GefundeneSignale={}

  for Signal=1,1000 do
    if EEPGetSignal(Signal) > 0 and EEPGetSignal(Signal+1000) > 0 then
      table.insert(GefundeneSignale, Signal)
    end
  end
end

local function KsKitZugSteuern(Zugname, Aktion)
  -- Wartezeit abarbeiten
  -- Wie ist .D zu interpretieren?
  --   nil -> kein Timer laufend
  --   0 -> Timer abgelaufen
  --   >0 -> Timer laeuft noch
  if Aktion.D and Aktion.D > 0 then
    Aktion.D = Aktion.D - 1
    return
  end

  local ok, V_ist = EEPGetTrainSpeed(Zugname)

  -- Wenn wir stehen, merken wir uns unsere Ankunftszeit
  if V_ist == 0 and Aktion.A == nil then
    -- 2 Sekunden Wartezeit bevor Ankunft registriert wird
    if Aktion.D == nil then
      Aktion.D = 10
      return
    end
    -- Timer erfuellt, Ankunft registrieren
    Aktion.D = nil
    Aktion.A = EEPTime
    -- Falls wir eine Abfahrtsgeschwindigkeit haben
    if Aktion.V then
      -- ... von Signalbeeinflussing trennen
      EEPSetTrainSpeed(Zugname, 0)
      -- Falls wir einen Fahrrichtungswechsel planen
      -- fahren wir jetzt die Stromabnehmer herunter
      if Aktion.R then
        if _G["setzeStromabnehmer"] then
          setzeStromabnehmer(Zugname, 0)
        end
      end
    end
  end

  -- Ankunftszeit loeschen falls wir schon wieder beschleunigen
  if V_ist ~=0 and Aktion.A then
    Aktion.A = nil
    Aktion.S = nil
    Aktion.R = nil
    Aktion.V = nil
  end

  -- Wartezeit in Delay-Aktion uebertragen
  if Aktion.W and Aktion.A then
    if Aktion.D == nil then
      Aktion.D = 5 * Aktion.W
      return
    end
    Aktion.D = nil
    Aktion.W = nil
    return
  end

  -- Nichts mehr tun wenn Warten ansteht
  if Aktion.W then return end

  -- Signal austragen, wenn wir einen Fahrtbegriff sehen
  if Aktion.S then
    local Begriff = leseSignal(Aktion.S)
    if Begriff[1] ~= HALT then
      Aktion.S = nil
    end
  end

  -- Fahrstrasse schalten (greift nur wenn Signal auf Halt)
  if Aktion.S then
    local ZSignal = Aktion.S
    local FSignal = ZSignal + 1000
    local Fahrstrassen = {}
    if Aktion.FS then
      Fahrstrassen = Aktion.FS
    elseif Selbstblock_Default then
      Fahrstrassen = {1}
    end
    if #Fahrstrassen > 0 then
      if EEPGetSignal(FSignal) == 1 then
        EEPSetSignal(FSignal, 1+Fahrstrassen[math.random(#Fahrstrassen)])
        --print("FS ",FSignal)
        --Schaltauftraege[FSignal] = 1+Fahrstrassen[math.random(#Fahrstrassen)]
      end
    end
    return
  end

  -- Sobald wir nicht mehr ans Signal gebunden sind, Abfahrt via EEPSetTrainSpeed
  if Aktion.V and Zugaktionen[Zugname].A then
    if _G["setzeStromabnehmer"] and Aktion.D == nil then
      setzeStromabnehmer(Zugname, Aktion.V>0 and 1 or -1)
      Aktion.D = 20
      return
    end
    -- Timer erfuellt, Ankunft registrieren
    Aktion.D = nil
    EEPSetTrainSpeed(Zugname, Aktion.V)
    Aktion.V = nil
  end
end

function KsKitMain()
  -- Signale abfragen, ob vielleicht ein Zug vor ihnen steht
  for i=1,#GefundeneSignale do
    local Signal = GefundeneSignale[i]
    if EEPGetSignalTrainsCount(Signal) > 0 then
      Zugname = EEPGetSignalTrainName(Signal, 1)
      if not Zugaktionen[Zugname].S then
        Zugaktionen[Zugname].S = Signal
        print("Zug ",Zugname," vom Signal ",Signal, " eingefangen")
      end
    end
  end

  -- Signalstellauftraege
  local Schaltauftraege = {}
  local SignalHaltegruende = {}

  for Zugname, Data in pairs(Zugaktionen) do
    local ok, V_ist = EEPGetTrainSpeed(Zugname)
    if not ok or next(Zugaktionen[Zugname]) == nil then
      Zugaktionen[Zugname] = nil
    end
  end

  for Zugname, Aktion in pairs(Zugaktionen) do
    KsKitZugSteuern(Zugname, Aktion)
  end

  speicherTabelle(1, Zugaktionen)
  EEPChangeInfoSignal(1, __tostring(Zugaktionen))
  for k,v in pairs(Schaltauftraege) do
    EEPSetSignal(k,v,1)
  end

  for i=1,#GefundeneSignale do
    local Signal = GefundeneSignale[i]
    if Aktiviere_Tooltips then
      local name = string.format("%04d", Signal)
      if Name and Name[Signal] then name=Name[Signal] end
      local txt = "<c>Signal "..name
      local Begriff = leseSignal(Signal)
      local Farbe = "<fgrgb=255,255,255><bgrgb=255,0,0>"
      if Begriff[1] == AUS then
        Farbe = ""
      elseif Begriff[1] ~= HALT then
        if Begriff.H_erwarten or Begriff.V_max then
          Farbe = "<fgrgb=0,0,0><bgrgb=255,255,0>"
        else
          Farbe = "<fgrgb=0,0,0><bgrgb=0,255,0>"
        end
      end
      txt = txt.."\n<c><b>"..Farbe..BegriffErklaeren(Begriff).."</b>"
      txt = txt.."<fgrgb=0,0,0><bgrgb=255,255,255>"
      local FStellung = EEPGetSignal(Signal+1000)
      if FStellung > 1 then
        txt = txt.."\n<c>".. string.format("FS #%02d", FStellung-1)
      end
      if SignalHaltegruende[Signal] then
        txt = txt.."\n"..SignalHaltegruende[Signal]
      end
      EEPChangeInfoSignal(Signal, txt)
      EEPShowInfoSignal(Signal, 1)
    else
      EEPShowInfoSignal(Signal, 0)
    end
  end
end

function FS(...)
  Zugaktionen[Zugname].FS = {...}
  speicherTabelle(1, Zugaktionen)
end

function W(Dauer)
  Zugaktionen[Zugname].W = Dauer
  speicherTabelle(1, Zugaktionen)
end

function S(Signal)
  Zugaktionen[Zugname].S = Signal
  speicherTabelle(1, Zugaktionen)
end

function V(V_soll)
  local _, V_ist = EEPGetTrainSpeed(Zugname)
  -- Negieren, falls Zug rueckwarts faehrt
  if V_ist < 0 then V_soll = -V_soll end
  -- Mit dieser Division teste ich, ob beide Geschwindigkeiten das selbe Vorzeichen haben
  -- Falls Vorzeichen ungleich, beim naechsten Halt Fahrtrichtungswechsel
  if V_soll/V_ist < 0 then Zugaktionen[Zugname].R = 1 end
  Zugaktionen[Zugname].V = V_soll
  speicherTabelle(1, Zugaktionen)
end
