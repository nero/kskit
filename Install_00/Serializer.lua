-- Tabelle in einen String umwandeln, rekursiv
-- Funktionen als Lua-Werte werden ignoriert
function __tostring(tab)
  local t=type(tab)
  if t=="table" then
    local r=""
    -- Tabellen-Keys sammeln und sortieren
    local tkeys={}
    for k in pairs(tab) do table.insert(tkeys, k) end
    table.sort(tkeys, function(a,b) return tostring(a)<tostring(b) end)
    -- Durch die Tabelle gehen
    for _,k in ipairs(tkeys) do
      -- Uns selbst fuer Tabellen-Value aufrufen
      local v = __tostring(tab[k])
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
    return tostring(tab)
  elseif t=="string" then
    return ("%q"):format(tab)
  else
    return "nil"
  end
end

-- Funktion, welche sich wie print() verhaelt, aber Tabellen als String ausgibt
function nprint(...)
  local args={...}
  for i=1,#args do
    if type(args[i]) == "table" then
      args[i]=__tostring(args[i])
    end
  end
  print(table.unpack(args))
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
