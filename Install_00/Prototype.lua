Prototype={}

function Prototype:init() end -- dummy constructor

-- function for injecting our functionality into an table
function Prototype:__set_parent(newparent)
  setmetatable(self, {
    -- non-overwritten keys are to be fetched from parent
    __index=newparent,
    -- construct a child when called directly
    __call=function(parent, ...)
      local newchild = {}
      self.__set_parent(newchild, parent)
      newchild:init(...)
      return newchild
    end
  })
end

-- serialize our object into a string
function Prototype:__tostring()
  local t=type(self)
  if t=="table" then
    local r=""
    -- load and sort table keys
    local tkeys={}
    for k in pairs(self) do table.insert(tkeys, k) end
    table.sort(tkeys, function(a,b) return tostring(a)<tostring(b) end)
    -- iterate over our table
    for _,k in ipairs(tkeys) do
      local v = Prototype.__tostring(self[k])
      -- ignore nil values, they unset the key anyways
      if v~= nil and v ~= "nil" then
        if r~="" then r=r.."," end
        -- short format: foo="bar", saves bytes
        if type(k)=="string" and k:match("^[%l%u_][%w_]*$") then
          r=r..k.."="..v
        -- long format: ["foo"]="bar", allows weird keys
        else
          r=r.."["..Prototype.__tostring(k).."]="..v
        end
      end
    end
    return "{"..r.."}"
  elseif t=="number" or t=="boolean" then
    return tostring(self)
  elseif t=="string" then
    return "\""..self:gsub("\\","\\\\"):gsub("\"","\\\"").."\""
  else
    return "nil"
  end
end

Prototype:__set_parent(nil) -- enable __call
