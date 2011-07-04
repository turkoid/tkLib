local addon, tkLib = ...

local global = 'tkLib'
local media = tkMedia
local format, tostring = string.format, tostring

tkLib = {}

do
    --credit: tukUI
    local resolution = {}
    resolution.scale = 0.64
    resolution.width, resolution.height = string.match(GetCVar('gxResolution'), '(%d+)x(%d+)')
    resolution.mult = 768 / resolution.height / resolution.scale
    SetCVar('UIScale', resolution.scale)   
    
    tkLib.resolution = resolution
end

tkLib.player = {
    name = UnitName('player'),
    level = UnitLevel('player'),
    race = UnitRace('player'),
    class = select(2, UnitClass('player')),
    faction = UnitFactionGroup('player'),
}

tkLib.dummy = function() return end

tkLib.niltable = {}
setmetatable(tkLib.niltable, {
    __index = function(t, i)
        return tkLib.niltable
    end,
    __newindex = tkLib.dummy,
})

tkLib.hex = function(r, g, b, isNormalized)
    if (type(r) == 'table') then
        isNormalized = g
        if (r.r) then
            r, g, b = r.r, r.g, r.b
        else
            r, g, b = unpack(r)
        end
    end
    
    if (isNormalized) then
        r, g, b = r * 255, g * 255, b * 255
    end
    
    return string.format('|cff%02x%02x%02x', r, g, b)
end

tkLib.print = function(msg)
    DEFAULT_CHAT_FRAME:AddMessage(tostring(msg))
end 

tkLib.debug = function(name, ...)
    local param, counter
    local line = ''
    for i = 1, select('#', ...) do
        param = select(i, ...)
        if (type(param) == 'table') then
            line = format('%s%s[%d]|r TABLE: ', line, media.colors.hex.yellow, i)
            counter = 1
            for k, v in pairs(param) do
                line = format('%s%s[%d]|r %s ', line, media.colors.hex.cyan, counter, tostring(v))
                counter = counter + 1
                if (counter > 10) then break end
            end
        else
            line = format('%s%s[%d]|r %s ', line, media.colors.hex.green, i, tostring(param))
        end
    end
    
    if line == '' then line = format(' %s%s|r', colors.red, 'NOTHING TO PRINT') end
    tkLib.print(format('%sDEBUG|r [%s%s|r]: %s', media.default.hexcolor, media.default.hexcolor, name, line))
end

tkLib.error = function(name, msg)
    tkLib.print(format('%sERROR|r [%s%s|r]: %s', media.colors.hex.red, media.default.hexcolor, name, tostring(msg)))
end

tkLib.message = function(name, msg)
    tkLib.print(format('%s%s|r: %s', media.default.hexcolor, name, tostring(msg)))
end

tkLib.utf8sub = function(str, start, numChars)   
    local currentIndex = start
    while numChars > 0 and currentIndex <= #str do
        local char = string.byte(str, currentIndex)
        if (char > 240) then
            currentIndex = currentIndex + 4
        elseif (char > 225) then
            currentIndex = currentIndex + 3
        elseif (char > 192) then
            currentIndex = currentIndex + 2
        else 
            currentIndex = currentIndex + 1
        end
        numChars = numChars -1
    end
    return str:sub(start, currentIndex - 1)
end

tkLib.printPartyRaid = function(msg)
    if (not msg) then return end
    
    local channel = 'default'
    if (GetNumRaidMembers() > 0) then
        channel = 'raid'
    elseif (GetNumPartyMembers() > 0) then
        channel = 'party'
    end
    
    if (channel == 'default') then
        tkLib.print(msg)
    else
        SendChatMessage(msg, channel)
    end
end

tkLib.addSlashCommand = function(name, func, ...)
    if (not name) then
        tkLib.error('tkLib', 'Cannot add slash command: Name is missing')
        return
    elseif (not func) then
        tkLib.error('tkLib', 'Cannot add slash command: Function is missing')
        return
    end
    
    name = string.upper(name)
    SlashCmdList[name] = func
    
    if (select('#', ...) == 0) then
        _G[format('SLASH_%s%d', name, 1)] = '/'..name
    else
        for i = 1, select('#', ...) do
            _G[format('SLASH_%s%d', name, i)] = '/'..select(i, ...)
        end
    end
end
   
tkLib.createAddon = function(addon, ns)
    ns.error = function(msg)
        tkLib.error(addon, msg)
    end

    ns.message = function(msg)
        tkLib.message(addon, msg)
    end

    ns.debug = function(...)
        tkLib.debug(addon, ...)
    end
end

tkLib.createFallback = function(private, fallback, recursive)
    if (recursive) then
        for k, v in pairs(private) do
            if (type(v) == 'table') then
                tkLib.createFallback(v, fallback and fallback[k], true)
            end
        end
    end
    setmetatable(private, {
        __index = fallback,
        __newindex = function(t, k, v)
            if (type(v) == 'table') then                
                tkLib.createFallback(v, fallback and fallback[k], recursive)
            end
            rawset(t, k, v)
        end,                
    })
    
    return private
end

tkLib.getRGB = function(c)
    if (c.r) then
        return c.r, c.g, c.b
    else
        return c[1], c[2], c[3]
    end
end

do
    local funcPercent = function(num)
        return num / 255        
    end
    
    local func8Bit = function(num)
        return num and floor(num * 255 + 0.5)
    end
    
    local convert = function(func, r, g, b)
        if (type(r) == 'table') then 
            if (r.r) then
                r.r, r.g, r.b = func(r.r), func(r.g), func(r.b)
            else
                r[1], r[2], r[3] = func(r[1]), func(r[2]), func(r[3])
            end
            return r
        else
            return {func(r), func(g), func(b)}
        end
    end
            
    tkLib.getPercentRGB = function(r, g, b)
        return convert(funcPercent, r, g, b)
    end
    
    tkLib.get8BitRGB = function(r, g, b)
        return convert(func8Bit, r, g, b)
    end
end

_G[global] = tkLib

