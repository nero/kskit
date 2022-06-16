local Callbacks = {}

function On(Name, Funktion)
  -- Nur Strings erlaubt!
  if type(Name) ~= "string" then
    error("Ungueltiger Callback-Name "..tostring(Name))
    return
  end
  if not Callbacks[Name] then
    -- Bestehende globale Funktionen duerfen nicht ueberschrieben werden
    if _G[Name] ~= nil then
      error(Name.."() bereits definiert")
      return
    end
    -- Bei Weichen und Signalen muss EEP vorher informiert werden
    -- Item ist normal "Switch" oder "Signal"
    local Item, Number = string.match(Name, 'EEPOn(.+)_(%d+)')
    if Number ~= nil then
      local Registration = "EEPRegister"..Item
      if _G[Registration](Number) == 0 then
        error(Registration.."("..tostring(Number)..") fehlgeschlagen")
      end
    end
    -- Lambda-Untertabelle fuer diesen EEP Callback eroeffnen
    Callbacks[Name] = {}
    -- Handler installieren, der alle Lambdas ausfuehrt
    _G[Name] = function(...)
      for cnt = 1, #Callbacks[Name] do
        Callbacks[Name][cnt](...)
      end
      -- EEPMain stoppt, geben wir hier nicht 1 zurueck
      return 1
    end
  end
  table.insert(Callbacks[Name], Funktion)
end

-- EEPMain-Callback registrieren
function Main(Funktion)
  On("EEPMain", Funktion)
end

-- Signal-Callback registrieren
function OnSignal(Signal, Funktion)
  On("EEPOnSignal_"..tostring(Signal), Funktion)
end

-- Weichen-Callbacks registrieren
function OnSwitch(Switch, Funktion)
  On("EEPOnSwitch_"..tostring(Switch), Funktion)
end
