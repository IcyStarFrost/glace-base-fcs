GLACEBASE = GLACEBASE or {}

local function IncludeDirectory( directory )
    directory = directory .. "/"

    
    local lua, dirs = file.Find( directory .. "*", "LUA", "namedesc" )

    for k, luafile in ipairs( lua ) do 
        if string.StartWith( luafile, "sv_") and SERVER then
            include( directory .. luafile )
        elseif string.StartWith( luafile, "sh_" ) then
            if SERVER then
                AddCSLuaFile( directory .. luafile )
            end
            include( directory .. luafile )
        elseif string.StartWith( luafile, "cl_" ) then
            if SERVER then
                AddCSLuaFile( directory .. luafile )
            elseif CLIENT then
                include( directory .. luafile )
            end
        end
    end

    for k, dir in ipairs( dirs ) do
        IncludeDirectory( directory .. dir )
    end

end

-- Load base addon lua files
IncludeDirectory( "glace" )
IncludeDirectory( "glace/globals" )

print( "Glace Base: All base Lua files have been loaded" )

local lua = file.Find( "glace/players/*", "LUA", "namedesc" )

for k, luafile in ipairs( lua ) do
    if SERVER then AddCSLuaFile( "glace/players/" .. luafile ) end
    print( "Glace Base: Included a player (" .. luafile .. ")")
    include( "glace/players/" .. luafile )
end

