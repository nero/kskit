-- Versionsnummer. Diese dient vor allem zu Diagnosezwecken.
-- Ich weiss jetzt noch nicht, wie viele verschiedene Versionen von dem Script spaeter herumfliegen werden.
KsKitVersion=0

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
