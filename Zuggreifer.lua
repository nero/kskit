-- Erwartet im Anlagenscript definierte Zuggreifer-Tabelle:
--   Schluessel ist die Signal-ID
--   Wert ist eine Liste von Gleisen vor dem Signal
--   Fuehrt das Gleis vom Signal weg statt hin, wird die ID negativ angegeben
function ZuggreiferInstallieren(Optionen)
  if type(EEPRollingstockGetOrientation) ~= "function" and Optionen.FahrzeugeGleicheRichtung ~= true then
    error("Zuggreifer erfordert mindestens EEP 15 Plugin 1")
  end
  if type(EEPRollingstockGetTrack) ~= "function" then
    error("Zuggreifer erfordert mindestens EEP 15")
  end
  if type(Zuggreifer) ~= "table" then
    error("Zuggreifer findet seine Tabelle nicht")
  end
  if type(leseSignal) ~= "function" then
    error("Zuggreifer findet leseSignal() nicht")
  end
  if Optionen == nil then Optionen={} end
  for Signal, Schienen in pairs(Zuggreifer) do
    if EEPGetSignal(Signal) == 0 then
      print("Zuggreifer findet Signal "..Signal.." nicht")
    end
    -- Schienen fuer die Gleisbesetztabfrage registrieren
    for i=1,#Schienen do
      local SchienenID = math.abs(Schienen[i])
      if not EEPRegisterRailTrack(SchienenID) then
        print("Zuggreifer "..Signal.." findet Gleis "..SchienenID.." nicht")
      end
    end
    -- Vorherigen Callback retten
    local CallbackName = "EEPOnSignal_"..tostring(Signal)
    local VorherigerCallback = _G[CallbackName]
    -- Wenn der User vorher EEPRegisterSignal vergessen hat, holen wirs nicht nach.
    -- Das darf nicht sein das es der User vergisst und es funktioniert trotzdem.
    if VorherigerCallback == nil then
      EEPRegisterSignal(Signal)
    end
    -- Callback registrieren
    _G[CallbackName]=function(Stellung)
      -- Vorherigen Callback trotzdem ausfuehren
      if VorherigerCallback ~= nil then
        VorherigerCallback(Stellung)
      end
      -- Nix tun, wenn das Signal auf Halt gestellt wurde
      local Fahrt, V_max = leseSignal(Signal)
      if not Fahrt then return end
      if type(V_max) ~= "number" then V_max = 40 end 
      -- Zug ermitteln
      local Zugname, Richtung = ZuggreiferAbfragen(Zuggreifer[Signal])
      -- Erfolg melden
      if Optionen.Melden then
        print("Signal ",Signal," hat ",Zugname and Zugname or "ins Leere"," gegriffen")
      end
      -- Abfahrbefehl erteilen
      if Zugname then
        if type(AnimiereAbfahrt) == "function" then
          AnimiereAbfahrt(Zugname, V_max * Richtung)
        else
          EEPSetTrainSpeed(Zugname, V_max * Richtung)
        end
      end
    end
  end
end

-- Schienen ist eine Liste von Gleis-IDs
-- Negative ID wenn andersherum verlegt
function ZuggreiferAbfragen(Schienen)
  local Zugname = nil
  local SchienenMap = {}
  local Besetzt = false
  local ok
  -- Testen, ob hier ueberhaupt was steht
  for i=1,#Schienen do
    local SchienenID = math.abs(Schienen[i])
    SchienenMap[SchienenID] = Schienen[i] > 0 and 1 or -1
    if not Besetzt then
      ok, Besetzt, Zugname = EEPIsRailTrackReserved(SchienenID , true)
      if not ok then
        error("Zuggreifer kann Gleis "..SchienenID.." nicht abfragen, wurde das Gleis registriert?")
      end
    end
  end
  -- Wenn hier ein Zug steht, dann...
  if Zugname then
    -- Alle Fahrzeuge durchgehen
    local AnzahlFahrzeuge = EEPGetRollingstockItemsCount(Zugname)
    for i=0,AnzahlFahrzeuge-1 do
      local FahrzeugName = EEPGetRollingstockItemName(Zugname, i)
      -- Testen, ob das Fahrzeug auf einen von "unseren" Gleisen steht
      local ok, Gleis, _, FahrzeugRichtung, _ = EEPRollingstockGetTrack(FahrzeugName)
      if not ok then return Zugname, 0 end
      if SchienenMap[Gleis] ~= nil then
        FahrzeugRichtung = FahrzeugRichtung > 0 and 1 or -1
        -- Richtung des Fahrzeugs im Zug ermitteln, benoetigt EEP 15 Plugin 1
        local FahrzeugVorwaerts = true
        if type(EEPRollingstockGetOrientation) == "function" then
          local ok, FahrzeugVorwaerts = EEPRollingstockGetOrientation(FahrzeugName)
        end
        -- Richtung zusammenmultiplizieren und mit Zugnamen zurueckgeben
        return Zugname, SchienenMap[Gleis] * ( FahrzeugRichtung > 0 and 1 or -1) * (FahrzeugVorwaerts and 1 or -1)
      end
    end
  end
  return nil, 0
end
