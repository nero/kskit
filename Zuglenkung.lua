require("Serializer")

Zuglenkung_Slot = Zuglenkung_Slot or 991
Zuglenkung_Auftreage = ladeTabelle(Zuglenkung_Slot)

-- Extrafunktion, damit der User das ueberschreiben kann
function ZuglenkungMelden(...)
  local Zeitstempel = string.format("%02d:%02d:%02d", EEPTimeH, EEPTimeM, EEPTimeS)
  print(Zeitstempel," Zuglenkung: ",...)
end

function Zuglenkung(...)
  local Weg = {...}
  if #Weg % 2 == 1 then
    print("Zuglenkung() erfordert eine gerade Anzahl Argumente")
    return
  end
  local Auftrag=nil
  for i=#Weg-1,1,-2 do
    Auftrag={Weg[i],Weg[i+1],0,Auftrag}
  end
  ZuglenkungAuftrag(Auftrag)
  speicherTabelle(Zuglenkung_Slot, Zuglenkung_Auftreage)
end

function ZuglenkungAuftrag(Auftrag)
  if Zuglenkung_Auftreage[Auftrag[1]] ~= nil then
    ZuglenkungMelden("Stellauftrag ", Auftrag[1], " verworfen")
  end
  Zuglenkung_Auftreage[Auftrag[1]]=Auftrag
  if type(Auftrag[2]) == "number" then
    ZuglenkungMelden("Anmeldung ",string.format("FS %04d-%02d",Auftrag[1],Auftrag[2]))
  else
    ZuglenkungMelden("Anmeldung ",string.format("FS %04d",Auftrag[1])," zu ",__tostring(Auftrag[2]))
  end
end

function ZuglenkungMain()
  local ZuStellen={}
  for k, Auftrag in pairs(Zuglenkung_Auftreage) do
    local Stellung = EEPGetSignal(Auftrag[1])

    -- Rumheulen, falls es unser FSignal nicht gibt
    if Stellung == 0 then
      ZuglenkungMelden("FSignal ", Auftrag[1], " nicht gefunden")
      Zuglenkung_Auftreage[k]=nil

    -- Merken, das wir das FS-Signal schonmal aufgeloest gesehen haben
    elseif Stellung == 1 then
      Auftrag[3]=1
      local Ziel = Auftrag[2]
      if type(Ziel) == "number" then Ziel={Ziel} end
      table.insert(ZuStellen, {Auftrag[1], Ziel[math.random(#Ziel)]})

    -- Stellung > 1 und wir haben es vorher auf 1 gesehen -> wir waren das
    elseif Auftrag[3] == 1 then
      ZuglenkungMelden(string.format("FS %04d-%02d",Auftrag[1],Stellung-1)," geschaltet")
      Auftrag = Auftrag[4]
      Zuglenkung_Auftreage[k]=nil
      if Auftrag then
        ZuglenkungAuftrag(Auftrag)
        return
      end
    end
  end

  -- Stellversuche durchmischen
  for i=#ZuStellen, 2, -1 do
    local j = math.random(#ZuStellen)
    ZuStellen[i], ZuStellen[j] = ZuStellen[j], ZuStellen[i]
  end

  -- Stellversuche durchfuehren
  for i=1, #ZuStellen do
    EEPSetSignal(ZuStellen[i][1], ZuStellen[i][2]+1, 1)
  end

  speicherTabelle(Zuglenkung_Slot, Zuglenkung_Auftreage)
end

function Zuglenkung_Beschreiben()
  txt=""
  for k, Auftrag in pairs(Zuglenkung_Auftreage) do
    txt=txt.."FS "..Auftrag[1].." auf "..__tostring(Auftrag[2])
    while Auftrag[3] do
      Auftrag=Auftrag[3]
      txt=txt..", dann "..Auftrag[1].." auf "..__tostring(Auftrag[2])
    end
    txt=txt.."\n"
  end
  return txt
end
