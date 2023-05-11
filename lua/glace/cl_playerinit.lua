net.Receive( "glacebase_playerinit", function()
    local ply = net.ReadEntity()
    if !IsValid( ply ) then return end
    ply.gb_isglaceplayer = true
    GLACEBASE:ApplyPlayerFunctions( ply )
end )