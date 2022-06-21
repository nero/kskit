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
function AnimiereZugStromabnehmer(Zug, Richtung)
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

FAHRT=1
HALT=2

function leseSignal(Signal)
  if EEPGetSignal(Signal) == 1 then
    return {FAHRT}
  else 
    return {HALT}
  end
end

local GefundeneSignale={}
local Zugaktionen={}

setmetatable(Zugaktionen, {
  __index=function(table, key)
    table[key]={}
    return table[key]
  end
})

function KsKitInit()
  GefundeneSignale={}
  Zugaktionen=ladeTabelle(1)

  for Signal=1,1000 do
    if EEPGetSignal(Signal) > 0 and EEPGetSignal(Signal+1000) > 0 then
      table.insert(GefundeneSignale, Signal)
    end
  end

  for i=1,#GefundeneSignale do
    local Signal = GefundeneSignale[i]
    EEPRegisterSignal(Signal)
    _G["EEPOnSignal_"..tostring(Signal)]=function(Stellung)

    end
    EEPRegisterSignal(Signal+1000)
    _G["EEPOnSignal_"..tostring(Signal+1000)]=function(FStellung)
      if FStellung > 1 then
        print("Fahrstrasse ",string.format("%04d-%02d", Signal+1000, FStellung-1)," geschalten")
      end
    end
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
      end
    end
  end

  -- Signalstellauftraege
  local Schaltauftraege = {}
  local SignalHaltegruende = {}

  for Zugname, Data in pairs(Zugaktionen) do
    local ok, V = EEPGetTrainSpeed(Zugname)
    if ok then
      local Haltegrund = "Kein Plan"

      -- Wenn wir stehen, merken wir uns unsere Ankunftszeit
      if V > -5 and V < 5 then
        if Zugaktionen[Zugname].A == nil then
          Zugaktionen[Zugname].A = EEPTime
          if Zugaktionen[Zugname].V then
            EEPSetTrainSpeed(Zugname, 0)
            if Zugaktionen[Zugname].R then
              AnimiereZugStromabnehmer(Zugname, 0)
            end
          end
        end
      -- Ankunftszeit loeschen falls wir unterwegs sind
      elseif Zugaktionen[Zugname].A then
        Zugaktionen[Zugname].A = nil
        Zugaktionen[Zugname].S = nil
        Zugaktionen[Zugname].R = nil
        Zugaktionen[Zugname].V = nil
      end

      if Zugaktionen[Zugname].W then
        Haltegrund = "Planhalt"
      end

      -- Wartezeit loeschen falls abgesessen
      if Zugaktionen[Zugname].W and Zugaktionen[Zugname].A then
        local Wartedauer = EEPTime - Zugaktionen[Zugname].A
        if Wartedauer < 0 then
          Wartedauer = Wartedauer + 24*60*60
        end
        if Wartedauer > Zugaktionen[Zugname].W then
          Zugaktionen[Zugname].W = nil
        end
      end

      -- Fahrstrasse schalten
      if not Zugaktionen[Zugname].W and Zugaktionen[Zugname].S then
        local ZSignal = Zugaktionen[Zugname].S
        local FSignal = ZSignal + 1000
        local Fahrstrassen = {}
        if Zugaktionen[Zugname].FS then
          Fahrstrassen = Zugaktionen[Zugname].FS
        elseif Selbstblock_Default then
          Fahrstrassen = {1}
        end
        if #Fahrstrassen > 0 then
          if EEPGetSignal(FSignal) == 1 then
            Schaltauftraege[FSignal] = 1+Fahrstrassen[math.random(#Fahrstrassen)]
          end
          Haltegrund = "FS angefordert"
        end
      end

      -- Haltegrund merken, das wir ihn spaeter im Signal-Tooltip darstellen koennen
      if Zugaktionen[Zugname].S then
        SignalHaltegruende[Zugaktionen[Zugname].S] = Haltegrund
      end

      if Zugaktionen[Zugname].S then
        local Begriff = leseSignal(Zugaktionen[Zugname].S)
        if Begriff[1] ~= HALT then
          if Zugaktionen[Zugname].V then
            if Zugaktionen[Zugname].B and Zugaktionen[Zugname].B + 5 < EEPTime then
              EEPSetTrainSpeed(Zugname, Zugaktionen[Zugname].V)
              Zugaktionen[Zugname].V = nil
              Zugaktionen[Zugname].B = nil
            elseif not Zugaktionen[Zugname].B then
              AnimiereZugStromabnehmer(Zugname, Zugaktionen[Zugname].V>0 and 1 or -1)
              Zugaktionen[Zugname].B = EEPTime
              Zugaktionen[Zugname].R = nil
            end
          else
            Zugaktionen[Zugname].S = nil            
          end
        end
      end

    else
      -- Zug aus den Augen verloren...
      Zugaktionen[Zugname]=nil
    end
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
      local Stellung = EEPGetSignal(Signal)
      if Stellung == 1 then
        txt = txt.."\n<c><b><fgrgb=0,0,0><bgrgb=0,255,0>Fahrt</b>"
      else
        txt = txt.."\n<c><b><fgrgb=255,255,255><bgrgb=255,0,0>Halt</b>"
      end
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
  -- Geschwindigkeit fuer Weiterfahrt ermitteln
  local _, V = EEPGetTrainSpeed(Zugname)
  Zugaktionen[Zugname].V = math.floor(V)
  speicherTabelle(1, Zugaktionen)
end

function R(Signal)
  Zugaktionen[Zugname].S = Signal
  -- Geschwindigkeit fuer Weiterfahrt ermitteln
  local _, V = EEPGetTrainSpeed(Zugname)
  Zugaktionen[Zugname].V = math.floor(-V)
  -- Merken, das ein Richtungswechsel animiert werden soll
  Zugaktionen[Zugname].R = 1
  speicherTabelle(1, Zugaktionen)
end
