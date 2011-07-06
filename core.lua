local addon, tkLib = ...

local global = 'tkLib'
local media = tkMedia
local format, tostring = string.format, tostring

local supressWarnings = false

tkLib = {}

tkLib.dummy = function() return end

tkLib.niltable = setmetatable({}, {
    __index = function(t, i)
        return tkLib.niltable
    end,
    __newindex = tkLib.dummy,
})

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
    
    if line == '' then line = format(' %s%s|r', media.colors.red, 'NOTHING TO PRINT') end
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

do
    local funcPercent = function(num)
        return num / 255        
    end
    
    local func8Bit = function(num)
        return floor(num * 255 + 0.5)
    end
    
    tkLib.getRGB = function(r, g, b)
        if (type(r) == 'table') then           
            if (r.r) then 
                return r.r, r.g, r.b
            else 
                return unpack(r) 
            end
        else 
            return r, g, b 
        end
    end
    
    local convert = function(func, r, g, b)
        r, g, b = tkLib.getRGB(r, g, b)
        return {func(r), func(g), func(b)}
    end
        
    tkLib.getPercentRGB = function(r, g, b)
        return convert(funcPercent, r, g, b)
    end
    
    tkLib.get8BitRGB = function(r, g, b)
        return convert(func8Bit, r, g, b)
    end
    
    tkLib.getHexRGB = function(r, g, b, isPercentRGB)  
        if (type(r) == 'table') then
            isPercentRGB = g
            r, g, b = tkLib.getRGB(r, g, b)
        end
        if (isPercentRGB) then r, g, b = r * 255, g * 255, b * 255 end
        return string.format('|cff%02x%02x%02x', r, g, b)
    end
    
    tkLib.hex = tkLib.getHexRGB --backwards compatibility
    
    tkLib.applyRGB = function(str, r, g, b, isPercentRGB)
        return tkLib.getHexRGB(r, g, b, isPercentRGB)..str..'|r'
    end
    
    tkLib.applyHex = function(str, color)
        return color..str..'|r'
    end
end


do
    --credit: tukUI
    local resolution = {}
    resolution.scale = 0.64
    resolution.width, resolution.height = string.match(GetCVar('gxResolution'), '(%d+)x(%d+)')
    resolution.mult = 768 / resolution.height / resolution.scale
    if (GetCVar('UIScale')) then
        SetCVar('UIScale', resolution.scale)  
    elseif (not suppressWarnings) then
        tkLib.message('WARNING', 'UIScale could not be set. A ReloadUI() will fix this.')
    end
    tkLib.debug('res', resolution)
    tkLib.resolution = resolution
end

tkLib.player = {
    name = UnitName('player'),
    realm = GetRealmName(),
    level = UnitLevel('player'),
    race = UnitRace('player'),
    class = select(2, UnitClass('player')),
    faction = UnitFactionGroup('player'),
}

tkLib.debug('player', tkLib.player)
_G[global] = tkLib