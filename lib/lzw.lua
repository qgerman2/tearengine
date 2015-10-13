local lzw = {}

local function enc_reset(dict, size)
  for k, _ in pairs(dict) do dict[k] = nil end
  for i = 0, size-1 do dict[string.char(i)] = i end
  return dict
end

local function dec_reset(dict, size)
  for k, _ in pairs(dict) do dict[k] = nil end
  for i = 0, size-1 do dict[i] = string.char(i) end
  return dict
end

lzw.encode = function(message)
  local w, result, size = "", {}, 256
  local dict = enc_reset({}, size)
  for k in message:gmatch('.') do
    local wk = w .. k
    if dict[wk] then
      w = wk
    else
      result[#result+1] = dict[w]
      dict[wk] = size
      size = size + 1
      w = k
    end
  end
  if w:len() > 0 then
    result[#result+1] = dict[w]
  end
  return result
end

lzw.short_encode = function(message)
  local w, result, size = "", {}, 128
  local dict = enc_reset({}, size)
  for k in string.gmatch(message, '.') do
    local wk = w .. k
    if dict[wk] then
      w = wk
    else
      result[#result+1] = string.char(dict[w])
      dict[wk] = size
      size = size + 1
      if size == 256 then
        size = 128
        enc_reset(dict, size)
      end
      w = k
    end
  end
  if w:len() > 0 then
    result[#result+1] = string.char(dict[w])
  end
  return table.concat(result)
end

lzw.decode = function(cipher)
  local w, entry, result  = "", "", {}
  local size = 256
  local dict = dec_reset({}, size)
  w = string.char(cipher[1])
  result[1] = w
  for i = 2, #cipher do
    local codeword = cipher[i]
    if dict[codeword] then
      entry = dict[codeword]
    else
      entry = w .. w:sub(1,1)
    end
    dict[size] = w .. entry:sub(1, 1)
    result[#result+1], w, size = entry, entry, size + 1
  end
  return table.concat(result)
end

lzw.short_decode = function(cipher)
  local w, entry, result, size = "", "", {}, 128
  local dict = dec_reset({}, size)
  w = cipher:sub(1, 1)
  result[1] = w
  for i = 2, cipher:len() do
    local k = string.byte(cipher:sub(i, i))
    if dict[k] then
      entry = dict[k]
    else
      entry = w .. w:sub(1,1)
    end
    dict[size] = w .. entry:sub(1, 1)
    result[#result+1], w, size = entry, entry, size + 1
    if size >= 256 then
      size = 128
      dec_reset(dict, size)
    end
  end
  return table.concat(result)
end

return lzw