local PLAYER = FindMetaTable( "Player" )
local ENT = FindMetaTable( "Entity" )

-- Returns the Glace Object on this player. Only returns something on Glace Players
function PLAYER:GetGlaceObject()
    return self._GLACETABLE
end

-- Is Glace Player checking functions
function PLAYER:IsGlacePlayer()
    return self.gb_isglaceplayer
end

function ENT:IsGlacePlayer()
    return self.gb_isglaceplayer
end
--