local utils = {}
function utils.round(n) return math.floor(n + 0.5) end
function utils.angle(x1,y1, x2,y2) return math.atan2(y2-y1, x2-x1) end
function utils.sign(n) return n>0 and 1 or n<0 and -1 or 0 end
function utils.multiple(n, size) size = size or 10 return utils.round(n/size)*size end
function utils.dist(x1,y1, x2,y2) return ((x2-x1)^2+(y2-y1)^2)^0.5 end

function utils.lerp(a,b,k)
  return (a + (b - a)*k);
end

--http://coronalabs.com/blog/2013/04/16/lua-string-magic/
function string:split( inSplitPattern, outResults )
   if not outResults then
      outResults = { }
   end
   local theStart = 1
   local theSplitStart, theSplitEnd = string.find( self, inSplitPattern, theStart )
   while theSplitStart do
      table.insert( outResults, string.sub( self, theStart, theSplitStart-1 ) )
      theStart = theSplitEnd + 1
      theSplitStart, theSplitEnd = string.find( self, inSplitPattern, theStart )
   end
   table.insert( outResults, string.sub( self, theStart ) )
   return outResults
end

function utils.speedVector(dist, a)
  local dx = math.cos(a) * dist;
  local dy = math.sin(a) * dist;
  return dx, dy;
end

--http://snippets.luacode.org/snippets/Table_Slice_116&version=000002
function table_slice(values,i1,i2)
  local res = {}
  local n = #values
  -- default values for range
  i1 = i1 or 1
  i2 = i2 or n
  if i2 < 0 then
    i2 = n + i2 + 1
  elseif i2 > n then
    i2 = n
  end
  if i1 < 1 or i1 > n then
    return {}
  end
  local k = 1
  for i = i1,i2 do
    res[k] = values[i]
    k = k + 1
  end
  return res
end

--http://stackoverflow.com/questions/1410862/concatenation-of-tables-in-lua
function array_concat(...) 
    local t = {}
    for n = 1,select("#",...) do
        local arg = select(n,...)
        if type(arg)=="table" then
            for _,v in ipairs(arg) do
                t[#t+1] = v
            end
        else
            t[#t+1] = arg
        end
    end
    return t
end

--http://lua-users.org/wiki/IteratorsTutorial
function ripairs(t)
  local max = 1
  while t[max] ~= nil do
    max = max + 1
  end
  local function ripairs_it(t, i)
    i = i-1
    local v = t[i]
    if v ~= nil then
      return i,v
    else
      return nil
    end
  end
  return ripairs_it, t, max
end

return utils