---
author: Nero
title: KsKit für Eisenbahn.exe
---

# KsKit für Eisenbahn.exe

KsKit enthält Steuer-Code für Strecken- und Bahnhofsanlagen in EEP.
Der Code ist auf mehere Scripte aufgeteilt, die Scripte haben teilweise sehr spezifische Funktion und können zum Teil auch alleinstehend in Anlagen verwendet werden.

Derzeit ist noch alles etwas im Flux, wenn du vom EEP Forum hierhergefunden hast, warte bitte ab bis ich offizielle Ankündigungen mache.

Das Gesamtpacket kann [hier](https://github.com/nero/kskit/archive/refs/heads/master.zip) als Zip-Datei heruntergeladen werden, es lässt sich dann wie ein Modell installieren.
Die Teilscripte werden in den LUA-Ordner im EEP-Stammverzeichnis installiert.

## Fahrstrassen

### Schutzweiche

Nach dem Festlegen einer Fahrstrasse werden Schutzweichen auf die Stellung gebracht, die den Flankenschutz gewährleistet und mittels Strg+Mausklick mit in die Fahrstrasse aufgenommen.
Die Schutzweiche ist als Teil der Fahrstrasse dann ebenfalls gegen händisches Umstellen geschützt.

![Weiche 1 ist als Schutzweiche Teil der Fahrstrasse](img/schutzweiche.png)

Zwieschutzweichen können durch die EEP-Fahrstrassen nicht implementiert werden.

### Kreuzende Fahrstrassen

Fahrstrassen reservieren nur den Fahrweg, nicht den Raum über den Fahrweg.
Bei Kreuzungen und DKWs kann es daher dazu kommen, das physikalisch kreuzende Fahrstrassen keine gemeinsamen Fahrwegelemente haben und sich daher nicht gegenseitig ausschließen.

Die Vorgehensweise ist hier die selbe wie bei Schutzweichen.
Weichen, die nicht Teil des Fahrweges selber sind, werden mit in die Fahrstrasse aufgenommen.
Es ist darauf zu achten, das Weichen dabei von der Kreuzung wegzeigen.

![Weichen 5 und 6 sind Teil der Fahrstrasse. In diesem Fall mit dem Hosenträger wird durch die extra Weichen kein Flankenschutz sichergestellt](img/kreuzung.png)

Die Fahrstrasse erzwingt dadurch eine Stellung der Weichen, die keine kreuzende Durchfahrt mehr erlaubt.

### Virtuelle Schutzweichen

Gibt es keine passenden Weichen in der Nähe, kann sich mittels Steuerstrecken oder Splines eine Weiche gebaut werden.
Diese virtuelle Schutzweiche wird von den sich auszuschliessenden Fahrstrassen in unterschiedlichen Stellungen aufgenommen.

Die Fahrstrassen müssen dafür nicht in der Nähe liegen.
Es kann ein Ausschluss zwischen beliebigen Fahrstrassen realisiert werden.

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
