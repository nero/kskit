-- Versionsnummer. Diese dient vor allem zu Diagnosezwecken.
-- Ich weiss jetzt noch nicht, wie viele verschiedene Versionen von dem Script spaeter herumfliegen werden.
KsKitVer=0

Kennziffer=34

local Callbacks = {}

function On(Name, Funktion)
  -- Erlaube es, Signal und Weichen via Nummer zu referenzieren
  if type(Name) == "number" then
    if EEPGetSwitch(Name) > 0 then
      Name = "EEPOnSwitch_"..tostring(Name)
    elseif EEPGetSignal(Name) > 0 then
      Name = "EEPOnSignal_"..tostring(Name)
    end
  end
  if type(Name) == "table" then
    for _, Newname in pairs(Name) do
      On(Newname, Funktion)
    end
    return
  end
  if type(Name) ~= "string" or string.match(Name, "EEP.+") == nil then
    print("Verweigere Callback von "..type(Name).." "..tostring(Name))
    return
  end
  if not Callbacks[Name] then
    Callbacks[Name] = {}
    if _G[Name] ~= nil then
      print("Warnung: "..Name.."() von KsKit adoptiert")
      table.insert(Callbacks[Name], _G[Name])
    end
    _G[Name] = function(...)
      for cnt = 1, #Callbacks[Name] do
        Callbacks[Name][cnt](...)
      end
      -- Nur EEPMain braucht dies, aber dringends
      return 1
    end
    -- Bei Weichen und Signalen muss EEP vorher informiert werden
    -- Item ist normal "Switch" oder "Signal"
    local Item, Number = string.match(Name, 'EEPOn(.+)_(%d+)')
    if Number ~= nil then
      _G["EEPRegister"..Item](Number)
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
  EEPRegisterSignal(Signal)
  On("EEPOnSignal_"..tostring(Signal), Funktion)
end

-- Weichen-Callbacks registrieren
function OnSwitch(Switch, Funktion)
  EEPRegisterSwitch(Switch)
  On("EEPOnSwitch_"..tostring(Switch), Funktion)
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

-- Referenz-Datenbank mit Signalen, Fahrstrassen & Weichen
-- Geordnet nach Signal/Weichen-ID
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

  -- Ersatzfahrt an Ausfahrsignalen und Blocksignalen ohne Vorsichtssignal
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
  _G[GK3KsBauarten[cnt]]=function(Signal, Meta)
    -- Falls kein name gegeben, einen generieren
    if Meta.Name == nil then
      Meta.Name = string.format("%d", Signal)
    end
    Meta.Kennziffer = Kennziffer
    Meta.Begriffe = GK3KsBegriffe(GK3KsBauarten[cnt])
    for _, Var in ipairs({"Schild","Mastschild","Immobilie", "PZB"}) do
      if type(Meta[Var]) == "number" then
        Meta[Var]=tostring("#"..Meta[Var])
      end
      if Meta[Var] then
        local ok,x,y,z = EEPStructureGetPosition(Meta[Var])
        if ok then
          if not Meta.Ort then
            Meta.Ort = {x,y,z}
          end
        else
          print("Warnung: Signal ",Signal," ",Var," ",Meta[Var]," nicht gefunden")
        end
      end
    end
    if not Meta.Ort then
      print("Warnung: Signal ",Signal," hat keine Immobilie, um die eigene Position zu ermitteln")
    end
    KsSignale[Signal] = Meta
    if Meta.Schild then
      EEPStructureSetTextureText(Meta.Schild, 1, Meta.Kennziffer)
      EEPStructureSetTextureText(Meta.Schild, 2, Meta.Name)      
    end
  end
end
