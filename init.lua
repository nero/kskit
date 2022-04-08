-- Versionsnummer. Diese dient vor allem zu Diagnosezwecken.
-- Ich weiss jetzt noch nicht, wie viele verschiedene Versionen von dem Script spaeter herumfliegen werden.
KsKitVer=0

-- Uebrige Konstanten
Vmax=400

-- Tabelle, in der alle Lambda-Funktionen gespeichert werden
-- Die Eintragung erfolgt durch die MainFunktion() vom Zielort aus.
MainFunktionTabelle={}

-- Neues Main-Lambda registrieren
function MainFunktion(Funktion)
  table.insert(MainFunktionTabelle, Funktion)
end

-- Alle Main-Lambda's ausfuehren
-- Dies ersetzt die Standard-EEP-Main Funktion.
function EEPMain()
  for cnt = 1, #MainFunktionTabelle do
   MainFunktionTabelle[cnt]()
  end
  return 1
end

-- Neues Signal-Lambda registrieren
SignalFunktionen = {}
function SignalFunktion(Signal, Funktion)
  if not SignalFunktionen[Signal] then
    EEPRegisterSignal(Signal)
    -- Callback bei EEP registrieren
    _G["EEPOnSignal_"..tostring(Signal)]=function(Stellung)
      -- Alle registrierten Lambdas ausfuehren
      for cnt = 1, #SignalFunktionen[Signal] do
       SignalFunktionen[Signal][cnt](Stellung)
      end
    end
    SignalFunktionen[Signal]={}
  end
  -- In unsere eigene Tabelle eintragen
  table.insert(SignalFunktionen[Signal], Funktion)
end

-- Lua-Serializer und Deserializer laden
serpent=require("kskit/serpent")

-- Lua-Tabelle aus EEP Slot laden
function ladeTabelle(Slot)
  local roh, geparst
  ok, roh = EEPLoadData(Slot)
  if not ok then return {} end
  ok, geparst = serpent.load(roh)
  if not ok then return {} end
  if type(geparst) ~= "table" then return {} end
  return geparst
end

-- Lua-Tabelle in EEP Slot speichern
function speicherTabelle(Slot, Tabelle)
  EEPSaveData(Slot, serpent.line(Tabelle, {comment = false}))
end

SignalLesenFunktionen={}

-- Definiere ein Signal
-- Signal: ID-Nummer
-- Haltstellung: Nummer der Haltstellung, meistens 1
-- SchaltFunk: Callback, wird wiederholt aufgerufen, um Fahrt-Stellung des Signals zu erwirken
-- AbmeldeFunk: Wird nach Durchfahrt am Signal aufgerufen
function Basissignal(Signal, Haltstellung, SchaltFunk, AbmeldeFunk)
  if EEPGetSignal(Signal)==0 then
    print("Anlagen-Fehler: ID ",Signal," ist kein Signal")
    return
  end
  -- Funktion, damit anderer Programmcode das Signal lesen kann
  SignalLesenFunktionen[Signal]=function()
    local Stellung = EEPGetSignal(Signal)
    if Stellung == 0 or Stellung == Haltstellung then
      return false, 0
    end
    return true, Vmax
  end
  -- Funktion fuer Kontaktpunkte: Zug an Signal anmelden
  _G["Anmeldung_"..tostring(Signal)] = function(Zug)
    local Anmeldung
    Anmeldung = ladeTabelle(Signal)
    if Anmeldung.train and Anmeldung.train ~= Zug then return end
    Anmeldung.train = Zug
    speicherTabelle(Signal, Anmeldung)
  end
  -- Auftragsstatus pollen
  MainFunktion(function()
    local Anmeldung = ladeTabelle(Signal)
    -- Wenn Zug vor Signal steht, Anmeldung ggf. nachholen
    if EEPGetSignalTrainsCount(Signal) > 0 then
      if Anmeldung.train == nil then
        Anmeldung.train = EEPGetSignalTrainName(Signal, 1)
        speicherTabelle(Signal, Anmeldung)
      end
      -- Ankunftszeit merken, sobald Zug am Signal angekommen ist
      -- Wird im if von EEPGetSignalTrainsCount gemacht,
      --   damit nur Halte an diesem Signal zaehlen
      if Anmeldung.arrival == nil then
        ok, speed = EEPGetTrainSpeed(Anmeldung.train)
        if math.abs(speed) < 5 then
          Anmeldung.arrival = EEPTime
          speicherTabelle(Signal, Anmeldung)
        end
      end
    end
    -- Nichts tun wenn kein Zug da
    if Anmeldung.train == nil then return end
    -- SchaltFunk
    if SchaltFunk and EEPGetSignal(Signal) == Haltstellung then
      r=SchaltFunk(Anmeldung.train)
      if r and r > 0 and r ~= Haltstellung then
        EEPSetSignal(Signal, r, 1)
      end
    end
  end)
  -- Reaktion auf Signal-Umstellungen
  SignalFunktion(Signal, function(Stellung)
    if Stellung == Haltstellung then
      -- Wenn Signal auf Halt gestellt wurde, mache eine Abmeldung
      if AbmeldeFunk then
        local Anmeldung = ladeTabelle(Signal)
        AbmeldeFunk(Anmeldung.train)
      end
      speicherTabelle(Signal, {})
    end
  end)
end

-- Funktion zum Erklaeren, was ein Signal gerade so tut
-- Nimmt die Nummer des Signals als Argument
-- Gibt einen Menschenlesbaren Text zurueck
function SignalBeschreibung(Signal)
  local Anmeldung = ladeTabelle(Signal)
  local Fahrt, V = SignalLesenFunktionen[Signal]()
  Text = "Signal " .. tonumber(Signal) .. ": "
  if Fahrt then
    if V < Vmax then
      Text = Text .. "Fahrt mit " .. tonumber(V) .. " Km/h\n"
    else
      Text = Text .. "Fahrt\n"
    end
  else
    Text = Text .. "Halt\n"
  end
  if Anmeldung.train then
    Text = Text .. "Zug angemeldet: " .. Anmeldung.train .. "\n"
  end
  if Anmeldung.arrival then
    local Dauer = EEPTime - Anmeldung.arrival
    if Dauer < 0 then Dauer = Dauer + 24*60*60 end
    Text = Text .. "Ankunft vor " .. Dauer .. " Sekunden\n"
  end
  return Text
end
