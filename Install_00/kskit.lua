require("Prototype")
require("On")

-- Tabelle in beliebigen Slot speichern
-- Im Slot steht dann eine Lua-Tabelle als String
-- Formatierungszeichen werden soweit URL-encoded,
--   dass EEP mit Formatierungszeichen keine Probleme mehr hat
-- Speziell hochkommas haben mir immer meine Daten abgeschnitten...
function speicherTabelle(Slotnummer, Tabelle)
  local s=Prototype.__tostring(Tabelle):gsub("([%c%%\"])", function(c)
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

-- KsKit merkt sich, welche Zuege vor einem Signal stehen
-- Die Tabelle wird einmal beim Lua-Start gelesen
--   und nach Aenderungen wieder zurueck geschrieben
-- Slot 960 ist damit durch KsKit blockiert!
Zugmeldung_Slotnummer = 960
Zugmeldung = ladeTabelle(Zugmeldung_Slotnummer)

-- Hier werden Zuglenker je nach Fahrstrassen-Startsignal sortiert gesammelt
Zuglenkfunktionen = {}

-- Neuen Zuglenker installieren:
-- Zuglenker schalten unter bestimmten Bedingungen automatisch Fahrstrassen
function Zuglenkung(Tab)
  local FS = Tab[1]
  Tab[1]=nil
  if Zuglenkfunktionen[FS] == nil then Zuglenkfunktionen[FS]={} end
  table.insert(Zuglenkfunktionen[FS], function(Zugname, Ankunft)
    local ziel = 2
    if Tab.Ziele then
      ziel = Tab.Ziele(math.random(#Tab.Ziele))
    end
    return ziel
  end)
end

-- EEPMain-Komponente der Zuglenkung
Main(function()
  local FS = {}

  -- Teste, ob an einem Signal Fahrstrassen und Zuglenkung existieren
  -- Subfunktion, wird beim Sammeln der Fahrstrassen-Signale mehrfach aufgerufen
  local VersucheAnSignal = function(Signal, Zugname, Ankunft)
    if Signal == nil then return end
    if Signale[Signal] == nil then return end
    if Signale[Signal].FS == nil then return end
    local FSignal = Signale[Signal].FS
    if EEPGetSignal(FSignal) == 1 and Zuglenkfunktionen[FSignal] then
      table.insert(FS, {FSignal, Zugname, Ankunft})
    end
  end

  -- Sammle alle Fahrstrassen-Signale, die geschaltet werden koennen
  -- Einmal die, wo direkt ein Zug in Anfahrt ist
  -- Und einmal die, wo der Zug gerade das "Halt erwarten" am vorherigen Signal sieht
  -- Zugname und Ankunftszeit merken
  for k,v in pairs(Signale) do
    if Zugmeldung[k] and v.FS then
      local Begriff = v:Lese()
      if Begriff[1] == HALT then
        VersucheAnSignal(k, Zugmeldung[k][1], Zugmeldung[k][3])
      elseif Begriff[1] == FAHRT and Begriff.H_erwarten and v.FF then
        local Ziel = EEPGetSignal(v.FS) - 1
	if v.FF[Ziel] then
          VersucheAnSignal(v.FF[Ziel], Zugmeldung[k][1], Zugmeldung[k][3])
        end
      end
    end
  end

  -- Zuglenker abarbeiten, moegliche Fahrstrassenstellungen sammeln
  local FSStellungen = {}
  for i=1,#FS do
    local FSignal = FS[i][1]
    local Zugname = FS[i][2]
    local Ankunft = FS[i][3]
    for j=1, #Zuglenkfunktionen[FSignal] do
      local ziel = Zuglenkfunktionen[FSignal][j](Zugname,Ankunft)
      if type(ziel) == "number" and ziel > 1 then
        table.insert(FSStellungen,{FSignal,ziel})
      end
    end
  end

  -- Eine einzelne Fahrstrassenstellung mittels EEPSetSignal abarbeiten
  -- Diese wird zufaellig ausgewaehlt, damit haben wir sowohl bei Verzweigungen und Zusammenfuehrungen
  --   automatisch Abwechslung, soweit es die Zuglenker erlauben
  -- Das wir nur eine Fahrstrasse schalten ist nicht schlimm, wir werden ja 5 mal pro Sekunde ausgefuehrt
  -- Beim naechsten mal kann man dann aber via EEPGetSignal() sehen, was wir an Fahrstrassen nicht mehr zu schalten brauchen
  if #FSStellungen >= 1 then
    local FS, Ziel = table.unpack(FSStellungen[math.random(#FSStellungen)])
      -- Wichtig: Callbacks aktivieren, damit Mehrabschnittssignale ueber ihren Nachfolger informiert werden
      EEPSetSignal(FS, Ziel, 1)
  end
end)

-- Basis-Prototyp fuer alle Signale
Signal=Prototype{}

-- Konstanten fuer Signalbegriffe
-- KsKit benutzt ein eigenes Format, um Signalbegriffe abzubilden
-- Dabei handelt es sich um eine Tabelle mit folgenden Schluesseln:
--  - 1: Grundsaetzlicher Typ von Begriffen, Fahrt ist 1, Halt ist 2
--  - V_max: nil oder number, Maximalgeschwindigkeit falls angezeigt
--  - H_erwarten: nil oder true, falls Begriff "Halt Erwarten" signalisiert
--  - V_erwarten: nil oder number, falls Begriff eine Geschwindigkeit vorsignalisiert
-- V_max und V_erwarten entsprechen absichtlich der Aufteilung der Zusatzanzeiger am Ks-Signal.
-- Gegen Ende der Datei sind extensiv Signalbegriffe als eigene Konstanten definiert

-- Grundsätzliche Typen von Signalbildern
FAHRT=1
HALT=2
RANGIERFAHRT=3
ERSATZFAHRT=4
AUS=5

-- Achtung: Keine Methode, Zugriff via einfachen Punkt, nicht Doppelpunkt
-- Wandelt einen Begriff in eine Textuelle Beschreibung um
-- Es lohnt sich, diesen Text im Signal-Tooltip anzuzeigen
-- Hl-Signale sind zwar huebsch, aber nicht immer einfach zu lesen
function Signal.BegriffZuText(Begriff)
  if Begriff[1]==HALT then return "Halt" end
  if Begriff[1]==RANGIERFAHRT then return "Rangierfahrt" end
  if Begriff[1]==ERSATZFAHRT then return "Fahrt auf Ersatzsignal" end
  if Begriff[1]==AUS then return "Signal ausgeschaltet" end
  local txt = "Fahrt"
  if Begriff.V_max then
    txt = txt.." mit "..tostring(Begriff.V_max).." km/h"
  end
  if Begriff.H_erwarten ~= nil then
    txt = txt..", Halt erwarten"
    if Begriff.kurz ~= nil then
      txt = txt.." im verkürzten Abstand"
    end
  end
  if Begriff.V_erwarten then
    txt = txt..", "..tostring(Begriff.V_erwarten).." km/h erwarten"
  end
  return txt
end

-- Alle Signale vor EEP5 konnten nur diese beiden Begriffe
Signal.Begriffe={{FAHRT},{HALT}}

-- Text fuer einen potentiellen Tooltip generieren
function Signal:TooltipText()
  local Begriff = self:Lese()
  local col=1
  local bgcol = "255,0,0"
  if Begriff[1]~=HALT then col=2 end
  if Begriff[1]==FAHRT and Begriff.V_max == nil and not Begriff.H_erwarten then col=3 end

  local fgcol={"255,255,255","0,0,0","0,0,0"}
  local bgcol={"255,0,0","255,255,0","0,255,0"}

  r="<c><b><bgrgb="..bgcol[col].."><fgrgb="..fgcol[col]..">"..self.BegriffZuText(Begriff).."<bgrgb=255,255,255></b>"
  if Zugmeldung[self.ID] then
    r=r.."\n<c>"..Zugmeldung[self.ID][1]
  end
  return r
end

-- Wird derzeit nicht genutzt, das war so gedacht, das im Tooltip dann "Rangiersignal" oder "Ausfahrsignal" steht
-- Hinterher war mir der Platz im Tooltip aber dann zu schade
-- Wenn hier vom User sowas wie "Einfahrsignal aus Richtung Nossen" eingetragen wird, ware das sicher nuetzlich
Signal.Beschreibung="Signal"
function Signal:set_Beschreibung(v)
  self.Beschreibung=v
end

-- Neue Signale werden mit Signal{...} vom Prototyp abgeleitet
-- Die Optionen werden durch set_$schluessel Setter geleitet.
-- Gibt es einen Setter nicht, gibt es einen harten Fehler - hier vertippt sich keiner mehr, auch ich nicht.
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

-- Setter fuer Signal-ID. Die selbe ID, wie auch fur EEPGetSignal und EEPSetSignal genutzt wird.
-- Die steht ganz am Anfang in der Tabelle vom Init-Aufruf und hat keinen String als Schluessel.
-- Ab hier ist auch die exakte ID unseres Signales bekannt, deswegen werden Globale Funktionen mit der ID im Namen ebenfalls hier definiert.
-- Koennte man aber auch spaeter machen.
function Signal:set_1(id)
  -- Globale Tabelle wo alle Signale drinnestehen
  -- So merkt man besser wenn man eine ID zweimal vergibt
  -- Die Signale-Tabelle wird auch benoetigt, damit Mehrabschnittssignale ueber die ID ihres Folgesignales den Begriff dessen lesen koennen.
  if type(Signale) ~= "table" then Signale={} end
  if Signale[id]~=nil then error("Signal ID "..id.." bereits verwendet") end
  if type(id) ~= "number" then error("Signal ID muss eine Zahl sein") end
  self.ID = id
  Signale[id]=self
  -- Anfahrtkontakt: Wir merken uns, das ein Zug an dieses Signal heranfaehrt.
  -- Die Zuglenkung wertet diese Informationen aus
  _G["Anfahrt_"..tostring(self.ID)]=function(Zugname)
    local ok, Speed = EEPGetTrainSpeed(Zugname)
    -- Derzeitige Fahrtrichtung ermitteln
    local Richtung = 1
    if Speed < 0 then Richtung = -1 end
    -- Ankündigung an den User
    --print(Zugname," an: ",self.Beschreibung," ",self.ID, ", V=",math.ceil(Speed))
    -- Zuganmeldung speichern
    Zugmeldung[self.ID]={Zugname, Richtung, EEPTime}
    speicherTabelle(Zugmeldung_Slotnummer, Zugmeldung)
  end
  -- Wird ein Signal auf Halt gestellt, gehen wir davon aus, das der Zug, der bisher hier Stand, jetzt weg ist.
  -- Damit kann durch einen Haltkontakt die Zugmeldung aufgeloest werden.
  -- Liegengebliebende Zugmeldungen koennen damit auch durch Toggeln des Signales geloescht werden
  OnSignal(self.ID, function(Stellung)
    if self.Begriffe[Stellung][1] == HALT then
      Zugmeldung[self.ID]=nil
      speicherTabelle(Zugmeldung_Slotnummer, Zugmeldung)
    end
  end)
end

-- Der Konstruktor des jeweiligen Signaltypes fuettert die Stellungen des Signals hier rein
-- Das ist eine Liste von Begriffen im oben dokumentierten Tabellenformat
function Signal:set_Begriffe(Begriffe)
  -- TODO: validieren das hier kein Mist reinkommt
  self.Begriffe=Begriffe
end

-- Fahrstrassenstartsignal mit Signal verbinden
function Signal:set_FS(FS)
  self.FS=FS
end

-- Folgesignale setzen
-- Der Wert ist eine Liste von Signal-IDs:
--   - Element 1 entspricht Folgesignal der ersten Fahrstrasse (Stellung 2)
--   - Element 2 entspricht dem Folgesignal der zweiten Fahrstrasse (Stellung 3)
--   - etc
-- Wird zum Vorsignalisieren genutzt
function Signal:set_FF(FF)
  self.FF=FF
  -- Callback fuer alle potentiellen Folgesignale eintragen
  -- Wir mussen das ja hinterher ggf. vorsignalieren
  for i=1,#FF do
    if type(FF[i])=="number" and FF[i] > 0 then
      OnSignal(FF[i], function()
        self:UpdateVorsignalfunktion()
      end)
    end
  end
end

-- Diese Funktion ist fuer Mehrabschnittssignale relevant
-- Ueber die FS und FF attribute koennen wir ableiten, welches Signal auf dieses folgt
-- Das lesen wir dann (geht nur, wenn es auch in KsKit eingetragen ist)
--   und basteln uns dann unsere eigenen Begriff zurecht
function Signal:UpdateVorsignalfunktion()
  if self.FS == nil then return end -- Wir haben kein Fahrstrassensignal
  if self.FF == nil then return end -- Wir haben keine Folgesignale
  local FS_Ziel = EEPGetSignal(self.FS) - 1
  if FS_Ziel < 1 then return end -- Fahrstrasse nicht geschaltet
  local Folgesignal = self.FF[FS_Ziel]
  local Begriff=self:Lese()
  if Begriff[1] ~= FAHRT then return end
  local Folgebegriff=Signale[Folgesignal]:Lese()
  local NeuerBegriff = {FAHRT}
  NeuerBegriff.V_max = Begriff.V_max
  NeuerBegriff.V_erwarten = Folgebegriff.V_max
  if Folgebegriff[1] == FAHRT then
    NeuerBegriff.H_erwarten = nil
  else
    NeuerBegriff.H_erwarten = true
  end
  self:Zeige(NeuerBegriff)
end

-- Signalbegriff lesen
-- Sehr trivial
function Signal:Lese()
  return self.Begriffe[EEPGetSignal(self.ID)]
end

-- Signalbegriff setzen
-- Faktisch sortiert diese Funktion alle Begriffe je nachdem, wie gut sie der gesuchten Stellung entsprechen
-- Der erste (besten-passende) Begriff wird dann gesetzt
-- Die Funktion ist zwar saumaessig kompliziert, kann aber bei Geschwindigkeitsabstufungen auf gerigere Geschwindigkeiten zurueckfallen.
-- Speziell bei Hl-Signalen, die sich einen VS-Begriff fuer V40 und V60 teilen, ist das nuetzlich.
-- Bei Signalen mit einer sehr schlechten Auswahl an Begriffen kommt hier vielleicht Murks raus
-- Das sollte man vielleicht genauer testen
function Signal:Zeige(Stellung)
  -- Achso, wir sortieren nicht die richtige Begriffstabelle, sondern eine Ersatztabelle mit den Indexen.
  -- Ist performanter. Und wir zerschiessen uns nicht die Begriffstabelle, weil wir die ja per Referenz haben.
  local order={}
  for i=1,#self.Begriffe do
    table.insert(order, i)
  end
  -- Sortieraufruf mit Sortierlabda
  table.sort(order, function(a,b)
    local StlgA = self.Begriffe[a]
    local StlgB = self.Begriffe[b]
    local props={1,"V_max","H_erwarten","V_erwarten"}
    for i=1,#props do
      -- Folgendes Muster: Wenn Stellung A und B sich in einem Merkmal unterscheiden
      -- UND Stellung A in diesem Merkmal mit der Zielstellung uebereinstimmt,
      -- DANN ist Stellung A besset geeignet, sonst nicht
      -- Wir muessen das auch andersherum mit Stellung B machen
      if StlgA[props[i]] ~= StlgB[props[i]] then
        if StlgA[props[i]] == Stellung[props[i]] then return true end
        if StlgB[props[i]] == Stellung[props[i]] then return false end
        -- Muster: Geschwindigkeitsmerkmal ist vorhanden und kleiner als Ziel, aber der Vergleichsbegriff:
        -- - zeigt das Merkmal gar nicht
        -- - zeigt eine hohere Geschwindigkeit als gewollt
        -- - zeigt eine noch kleinere Geschwindigkeit
        -- Dann ist der Vergleichsbegriff schlechter geeignet
        -- Und das dann jeweils in beide Richtungen
        if i == 2 or i == 4 then -- 2 ist V_max, 4 ist V_erwarten
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
  -- Begriff aktiv schalten... der Wert in unserer Indextabelle ist der Index in die Begriffstabelle
  --   und damit auch genau der Wert, den EEP fuer die numerische Stellung braucht
  EEPSetSignal(self.ID, order[1], 1)
  return true
end

-- So, der Signal-Prototyp ist definiert! Jetzt definieren wir uns die ganzen Signalsysteme und jeweils ein paar Modelle dazu

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
Hl_Signal_Ausfahrt_V60=Signal{Begriffe={Hl13,Hl1,Hl3b,Hl3a,Zs1,Sh1,Hl13}, Beschreibung="Ausfahrsignal"}
Hl_Signal_Einfahrt_V60=Signal{Begriffe={Hl13,Hl1,Hl4,Hl7,Hl10,Hl3b,Hl6b,Hl9b,Hl12b,Hl3a,Hl6a,Hl9a,Hl12a,Zs1,Hl13}, Beschreibung="Einfahrsignal"}
-- V40 und V60 werden bei Hl gleich vorsignalisiert, keine Ahnung warum das ueberhaupt verschiedene Modelle hat
Hl_Signal_Vorsignal_V60=Hl_Signal_Vorsignal_V40
Hl_Signal_Vorsignalwiederholer_V60=Hl_Signal_Vorsignalwiederholer_V40

-- Bahnhofsset
Hl_Zwerg_Rangiersignal=Signal{Begriffe={Ra11,Sh1},Beschreibung="Rangierhaltsignal"}

-- Irgendein anderes set
Hl_Signal_AZ=Signal{Begriffe={Hl13,Hl1,Hl4,Hl7,Hl10,Hl3a,Hl9a,Hl6a,Hl12a,Sh1,Zs1,Hl13,{}}, Beschreibung="Ausfahrsignal"}
