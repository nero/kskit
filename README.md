---
author: Nero
title: KsKit für Eisenbahn.exe
lang: de
---

# KsKit für Eisenbahn.exe

KsKit sind ein paar Lua-Scripte und Anleitungen, welche ich auf meinen Anlagen nutze.
Von denen habe ich ein paar Dokumentiert, sie sind bisweilen recht nützlich.
Es ist auch immer dazugeschrieben, welche Vorraussetzungen man braucht.

Alle Scripte können [hier](https://github.com/nero/kskit/archive/refs/heads/master.zip) als Zip-Datei heruntergeladen werden, die lässt sich dann wie ein Modell installieren.
Die Teilscripte werden in den LUA-Ordner im EEP-Stammverzeichnis installiert.

## Tabellen in EEP-Slots speichern

Für viele ist dies sicher schon ein altbekanntes Problem.
Die Lua-Umgebung wird von EEP in bestimmten Situationen zurückgesetzt und verliert dabei die Inhalte aller Variablen.
Daher müssen persistente Werte via `EEPSaveData` gespeichert und nach dem Reset wieder geladen werden.
Bei Zeichenketten und Zahlen ist das kein Problem, das Speichern von Tabellen ist nicht ohne umwege möglich.

KsKit bringt einen Serializer mit, der in der Lage ist, die gängigen Lua-Daten und Tabellen in eine Zeichenkette zu serialisieren.

### Funktion __tostring

Die `__tostring`-Funktion ist das Herz des Serializers.
Sie nimmt ein Argument und gibt eine Zeichenkette zurück.

Der Return-Wert ist gültiges Lua und kann mittels `load()`-Funktion wieder in die Tabellenform zurückgewandelt werden.

```
require("Serializer")

Tabelle={
  str = "abcdef",
  lst = {1,2,3},
  bol = true
}

print(__tostring(Tabelle))
-- Ausgabe: {bol=true,lst={1,2,3},str="abcdef"}
```

Unterstützt werden Wahrheitswerte, Zeichenketten, Zahlen und verschachtelte Tabellen.
Lambda-Funktionen werden ignoriert, rekursiv in sich selbst verschachtelte Tabellen führen zum Absturz.

### Funktion dump

Die `dump()`-Funktion nimmt eine beliebige Anzahl von Argumenten und gibt diese nach der Behandlung durch `__tostring` an die normale `print`-Funktion weiter.

Diese Funktion ist vergleichbar mit `print(__tostring(...))` und dient Diagnosezwecken bei Lua-Problemen.

### Funktion speicherTabelle

Diese Funktion macht genau das, was der Name vermuten lässt.
Eine Lua-Tabelle wird in einem EEPSlot abgespeichert.

Das erste Argument zu der Funktion ist dabei die Slotnummer, das zweite Argument eine Lua-Tabelle.

Die Tabelle wird mittels `__tostring` in eine Zeichenkette umgewandelt.
Die EEPSlots unterstützen jedoch nicht alle möglichen Zeichen.
Daher wird das Zwischenergebnis nochmal in ein `urlencode`-ähnliches Format umkonvertiert.
Dabei werden sämtliche Steuerzeichen und Hochkommas sicher verpackt.

```
require("Serializer")

Tabelle={
  str = "abcdef",
  lst = {1,2,3},
  bol = true
}

speicherTabelle(1, Tabelle)

-- So sieht der Datenslot hinterher in der Lua-Datei aus:
-- [EEPLuaData]
-- DS_1 = "{bol=true,lst={1,2,3},str=%22abcdef%22}"
```

### Funktion ladeTabelle

Das pendant zu `speicherTabelle`.
Als Argument wird die Slotnummer übergeben, als Return-Wert erhält man die vorher gespeicherte Tabelle zurück.

Dabei wird das `urlencode` wieder entfernt und die Daten mittels `load`-Funktion wieder eingelesen.

Ist der Slot unleserlich oder wurde in diesen noch keine Tabelle geschrieben, wird eine Warnmeldung in das Ereignisfenster geschrieben und eine leere Tabelle zurückgegeben.

```
require("Serializer")

dump(ladeTabelle(1))
-- Ausgabe: {bol=true,lst={1,2,3},str="abcdef"}
```

### Praxisbeispiel

Es ist nicht notwendig, eine Tabelle vor jeder Benutzung zu laden und wieder zu speicern.

Viel schneller ist es, die Tabelle als globale Variable zu halten und nur beim Lua-Start einmal einzulesen.
Die Tabelle kann dann wie jede andere Tabelle verwendet werden.

Die EEPMain wird innerhalb eines Zyklus zuletzt aufgerufen.
Die Kontakte und Callbacks werden davor abgearbeitet.
Daher reicht es aus, wenn die Tabelle nur einmalig am Ende der EEPMain zurückgeschrieben wird.

```
require("Serializer")

-- Die Tabelle wird nur beim Starten von Lua einmal geladen
Zugdaten_Slotnummer = 1
Zugdaten = ladeTabelle(Zugdaten_Slotnummer)

-- Diese Funktion wird in Kontakten eingetragen
function Richtung_Merken(Zugname)
  local ok, V = EEPGetTrainSpeed(Zugname)
  Zugdaten[Zugname].V = V
end

function Zug_Wenden(Zugname)
  local Vneu = -Zugdaten[Zugname].V
  EEPSetTrainSpeed(Zugname, Vneu)
  Zugdaten[Zugname].V = Vneu
end

function EEPMain()
  -- andere Dinge tun
  -- ...

  -- Wir sind am Ende des EEP-Zyklus, nur einmal hier speichern
  speicherTabelle(Zugdaten_Slotnummer, Zugdaten)
  return 1
end
```

## Fahrstrassen

Fahrstrassen bestehen aus jeweils einem Start- und Endsignal und haben eine Liste von Fahrwegelementen:

Der Fahrweg einer Fahrstraße besteht aus beliebigen Splines, meist jedoch Gleise.
Pro Spline kann dabei nur maximal eine Fahrstraße aktiv geschalten sein.
Wird versucht, eine Fahrstraße zu schalten, deren Fahrweg von einer anderen Fahrstraße besetzt ist, hat der Schaltversuch keine Wirkung.
Das selbe gilt auch, wenn die Splines einer Fahrstraße von Rollmaterialien besetzt sind.
Dies wird beim Vorbild als Fahrstrassenausschluss bezeichnet.
Beim Bearbeiten im 2D-Modus werden die Splines einer Fahrstraße Fahrstraße mit einer einfarbigen Linie überzeichnet, um ihre Zugehörigkeit anzuzeigen.

Signale als Teil einer Fahrstraße bewirken keinen Fahrstrassenausschluss.
Das Schalten einer weiteren Fahrstraße mit diesem Signal stellt dieses einfach um.
Signale zeigen beim Bearbeiten der Fahrstraße mittels farblicher Unterlegung an, ob sie zu einer Fahrstraße gehören.

Weichen in Fahrstrassen bewirken einen Fahrstrassenausschluss auf alle Fahrstrassen, welche die Weiche in einer anderen Stellung eingestellt haben.
Fahrstrassen, welche die selbe Weiche in der selben Stellung aufgenommen haben, dürfen gleichzeitig geschaltet werden, sofern sie sich nicht anders (z.B. über die Splines der jeweiligen Weiche) ausschließen.

Sehr viele EEP-Benutzer finden Fahrstrassensignale im 3D-Modus unschön.
Unter "Ansicht" -> "Anzeige 3D-Fenster" -> "3D Fahrstrassen Signale" kann man das Rendern abstellen.

![Menüeintrag zum Verstecken der Fahrstrassen](img/fs_verstecken.png)

### Startsignal

Da ein Fahrstrassen-Startsignal selbst keine Züge anhalten kann, wird es meist in Verbindung mit einem regulären Signal verwendet.
Dabei gilt unbedingt zu beachten, das der Haltepunkt des Signales nicht Teil der folgenden Fahrstrasse ist, also vor dem Startsignal liegt.
Den Haltepunkt erkennt man beim Heranzoomen an dem L-förmingen Linie im Gleis.

![Startsignal hinter dem Haltepunkt eines Lichtsignales](img/fs_start.png)

Bei regulären Signalen in EEP ist die sichtbare Position Sicherungstechnisch nicht relevant, was wichtig ist, ist der Haltepunkt.
Dieser kann im Signal über die Option "Halteabstand" eingestellt werden.

Der von einer Fahrstrasse überwachte Fahrweg kann durch die farbige Hervorhebung eingesehen werden.
Das Signal wird in die Fahrstrasse aufgenommen, bei mehrbegriffigen Signalen kann durch die Fahrstrasse auch spezieller Fahrtbegriff eingestellt werden, zm Beispiel eine Langsamfahrt im Weichenbereich oder eine Rangierfahrt.

### Zielsignal

Das Zielsignal löst bei Durchfahrt der Zugspitze die Fahrstrasse auf.
Sämtlicher Bereich nach dem Ende der Fahrstrasse wird daher nicht gegen Folgefahrten geschützt.

![Unüberwachter Bereich nach dem Zielsignal: Eine BR 212 ist zu kurz und wird vom Folgezug gleich unsanft aufgegabelt](img/fs_ziel_luecke.png)

Führt eine Fahrstrasse zu einem regulären Signal, muss der Fahrweg bis zum Haltepunkt (L-Winkel) mit in der Fahrstrasse aufgenommen werden.
Erfolgt dies nicht, kann es passieren, das sich kurze Fahrzeuge zwischen Zielsignal und Haltepunkt vor der Gleisbesetztmeldung verstecken können.
Speziell Loks auf Rangierfahrten laufen so Gefahr, von einfahrenden Zügen unsanft aufgegabelt zu werden.

#### Hinter dem Folgesignal

Das Aufgabeln von kurzen Fahrzeugen kann verhindert werden, wenn das Zielsignal nach dem Haltepunkt des regulären Signales steht.

![Zielsignal nach regulären Signal](img/fs_ziel_es.png)

Wurde das Zielsignal nach dem Haltepunkt des Signales platziert, wird die Fahrstrasse durch Ankunft des Zuges nicht mehr automatisch aufgelöst.
Bei Blockstellen ist das kein Problem und kann auch gewollt sein, in Bahnhöfen jedoch können dadurch Weichenstraßen unnötig blockiert werden.

Wie beim Vorbild kann dieses Problem mit einer Fahrstrassenzugschlussstelle umgangen werden.

![Signal-Kontakt als Fahrstrassenzugschlussstelle](img/fs_zugschlussstelle.png)

Die Fahrstrassenzugschlussstelle ist ein Signal-Kontakt für das Startsignal.
Dieser befindet sich nach der letzten Weiche (in Fahrtrichtung) des Weichenbereichs.
Sobald das Zugende den Weichenbereich verlassen hat, wird die Fahrstrasse aufgelöst und der Weichenbereich kann durch andere Züge benutzt werden.

Wenn in ein Gleis auch von einem anderen Startsignal oder sogar auch ohne Fahrstrasse eingefahren werden kann, muss der Kontakt angepasst werden, das er nur wirkt, wenn das eigene Startsignal auch aktiv ist.
Wird das nicht gemacht, kann eine Paralleleinfahrt zu verfrühten Auflösen von Fahrstrassen führen.

### Profilfreiheit

Bei der Berechnung von Fahrstrassenausschlüssen werden die Fahrwege auf ihre Freiheit von Rollmaterialien und fremden Fahrstrassen überprüft.
Was dabei nicht überprüft wird, ist der Lichtraum über den Fahrwegen, auf denen die Fahrzeuge fahren.
Speziell im Weichenbereich von Bahnhöfen kann es vorkommen, das sich geschaltete Fahrstrassen überkreuzen und die Züge durcheinander durch fahren.

Dem kann abgeholfen werden, wenn zu jeder Fahrstraße alle Fahrwege hinzugefügt werden, welche im Lichtraum jener Fahrstrasse liegen.

![Nicht profilfreie andere Gleise wurden hier mit in die Fahrstraße eingebunden](img/fs_raum.png)

Damit wird auch die Grenzzeichenfreiheit an den Weichen sichergestellt.

### Schalten von Fahrstrassen

Fahrstrassen werden über das Startsignal gesteuert.
Die Stellung des Startsignales ist 1, falls keine Fahrstraße geschaltet ist.
Die höheren Stellungen entsprechen jeweils einer Fahrstraße zu einem Zielsignal.
Stellung 2 ist die erste Fahrstraße, Stellung 3 die zweite und so weiter.

Eine Schaltung kann mittels Signalverknüpfung, Kontakte und `EEPSetSignal` versucht werden.
Kann die Fahrstraße nicht geschaltet werden, weil z.B. Rollmaterialien auf dem Gleis stehen oder ein Fahrstrassenausschluss diese blockiert, hat der Schaltversuch keinen Erfolg.
Darüber erfolgt keine unmittelbare Rückmeldung.

Das Zielsignal hat nur zwei Stellungen und bietet daher keine Information darüber, welche Fahrstrasse geschaltet ist.

### Schutzweiche

Nach dem Festlegen einer Fahrstrasse werden Schutzweichen auf die Stellung gebracht, die den Flankenschutz gewährleistet und mittels Strg+Mausklick mit in die Fahrstrasse aufgenommen.
Die Schutzweiche ist als Teil der Fahrstrasse dann ebenfalls gegen händisches Umstellen geschützt.

![Weiche 1 ist als Schutzweiche Teil der Fahrstrasse](img/schutzweiche.png)

Zwieschutzweichen können durch die EEP-Fahrstrassen nicht implementiert werden.

### Virtuelle Schutzweichen

Gibt es keine passenden Weichen in der Nähe, kann sich mittels Steuerstrecken oder Splines eine Weiche gebaut werden.
Diese virtuelle Schutzweiche wird von den sich auszuschliessenden Fahrstrassen in unterschiedlichen Stellungen aufgenommen.

Die Fahrstrassen müssen dafür nicht in der Nähe liegen.
Es kann ein Ausschluss zwischen beliebigen Fahrstrassen realisiert werden.

## Bahnübergänge

Bahnübergänge können recht einfach über Fahrstrassen gelöst werden.

In den Fahrstrassen für den Zugverkehr werden beide Schranken aufgenommen, sie werden beim Einstellen der Fahrstraße auf Halt gestellt.
Da mehrere Fahrstrassen gleichzeitig über den Bahnübergang führen können, dürfen die Schranken beim Auflösen einer Fahrstrasse nicht auf Fahrt gestellt werden.

![Eine Fahrstrasse für die Gleise](img/bue_fs.png)

Um die Schranken zu öffnen, nachdem alle Fahrstrassen aufgelöst wurden, wird eine Hilfsfahrstraße auf einem naheliegenden unsichtbaren Spline eingerichtet.
Diese hat die Gleise des Bahnüberganges als Fahrwegelemente eingetragen und öffnet beim Schalten die beiden Schranken.
Beim Auflösen hat sie auf die Schranken keine Wirkung.

![Die Hilfsfahrstrasse für die Straße](img/bue_hfs.png)

Damit die Freigabe des Bahnüberganges funktioniert, muss regelmäßig das Schalten der Hilfsfahrstrasse versucht werden.
Dies kann entweder mit einen Schaltauto oder mit Lua realisiert werden:

```
-- Wenn die Schranke geschlossen ist
if EEPGetSignal(1) == 2 then
  -- Hilfsfahrstrasse schalten
  EEPSetSignal(3, 2)
  -- Hilfsfahrstrasse aufloesen
  EEPSetSignal(3, 1)
end
```

Wichtig ist, das die Hilfsfahrstrasse sofort wieder aufgelöst wird und nicht geschaltet bleibt.

Durch die Aufnahme der Gleise in die Hilfsfahrstrasse wird zu einem erzielt, das die Schranken nicht geöffnet werden können, solange eine Zugfahrstrasse über den Bahnübergang führt.
Zum anderen blockieren auch Rollmaterialien das Öffnen der Schranken, womit z.B. Rangierfahrten und Wendemanöver im Bahnhofskopf entsprechend gesichert werden können.

Wenn die Schranke mit einer Startverzögerung konfiguriert ist, liest EEPGetSignal nach dem Öffnen der Schranke weiterhin eine Haltstellung aus.
Die Fahrstrasse wird dann 5 mal pro Sekunde geschalten, bis die Startverzögerung abgelaufen ist und EEPGetSignal die richtige Stellung zurückgibt.
Wem das klackern der Fahrstrassensignale dann stört, der kann die oben genannte Anleitung nicht mit den Schranken selber, sondern mit einem Unsichtbaren Signal durchführen und die Schranken dann mittels Signalverknüpfung an das Unsichtbare Signal binden.

## Lua

### Mehrere Funktionen pro Callback

Meine On.lua übernimmt die Entgegennahme sämtlicher Callbacks und erlaubt es, mehrere Funktionen durch einen EEP-Callback auszuführen.
Das Script kann einzeln [hier](Install_00/On.lua) heruntergeladen werden.

Das bedeutet allerdings auch, das im Anlagenscript keine EEPMain, EEPOnSignal und EEPOnSwitch zu definieren sind.
Als Ersatz dafür bietet On.lua eine eigene Schnittstelle an:

```
Main(function()
  print("Main")
  -- return-Wert von hier wird ignoriert
end)

OnSignal(1, function(Stellung)
  print("Signal 1 zeigt jetzt Stellung ", Stellung)
end)

OnSwitch(2, function(Stellung)
  if Stellung == 1 then
    print("Weiche 2 ist auf Durchfahrt gestellt")
  elseif Stellung == 2 then
    print("Weiche 2 ist auf Abzweig gestellt")
  elseif Stellung == 3 then
    print("Weiche 2 ist auf Coabzweig gestellt")
  end
end)
```

Auf diese Art darf der selbe Callback mehrfach definiert werden.
Ruft EEP den Callback auf, werden alle dazu eingetragenen Funktionen aufgerufen.

Die Anmeldung bei EEP durch die `EEPRegister...` Funktionen wird von KsKit automatisch vorgenommen.
