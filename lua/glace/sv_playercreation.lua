local defaultnames = {
    "Sorry_an_Error_has_Occurred",
	"I am the Spy",
	"engineer gaming",
	"Ze Uberman",
	"Regret",
	"Sora",
	"Sky",
	"Scarf",
	"Graves",
	"bruh moment",
	"Garrys Mod employee",
	"i havent eaten in 69 days",
	"DOORSTUCK89",
	"PickUp That Can Cop",
	"Never gonna give you up",
	"The Lemon Arsonist",
	"Cave Johnson",
	"Chad",
	"Speedy",
	"Alan",
	"Alpha",
	"Bravo",
	"Delta",
	"Charlie",
	"Echo",
	"Foxtrot",
	"Golf",
	"Hotel",
	"India",
	"Juliet",
	"Kilo",
	"Lima",
	"Lina",
}


-- Creates a Fake Client that's being handled by Glace Base

-- plyname | string | The name of this player. Optional as if no name is provided a default will be used
-- playermodel | string | The model path for this Player to use. Optional
function GLACEBASE:CreatePlayer( plyname, playermodel )
    if player.GetCount() == game.MaxPlayers() then print( "Glace Base: No more player bots can be spawned. (Player Limit Reached!)" ) return end
    local ply = player.CreateNextBot( plyname or defaultnames[ math.random( #defaultnames ) ] )
    if playermodel then ply:SetModel( playermodel ) end

    ply.gb_playermodel = playermodel
    ply.gb_isglaceplayer = true

    local initspawn = true

    local GLACE = self:ApplyPlayerFunctions( ply )

    GLACE:SetThread( coroutine.create( function() GLACE:ThreadedThink() print( "Glace Base: " .. ply:Name() .. "'s Threaded Think has stopped executing!" ) end ) )

    local navigator = ents.Create( "glace_navigator" )
    navigator:SetOwner( ply )
    navigator:Spawn()

    GLACE:SetNavigator( navigator ) 
    navigator:SetPos( GLACE:GetPos() )
    

    -- Network this glace player to clients
    net.Start( "glacebase_playerinit" )
    net.WriteEntity( ply )
    net.Broadcast()

    -- Sometimes real players join mid game so we need to network this glace player to the real player
    hook.Add( "PlayerInitialSpawn", ply, function( plyself, player )
        net.Start( "glacebase_playerinit" )
        net.WriteEntity( ply )
        net.Send( player )
    end )

    -- Reset the player's playermodel | Call respawn hook
    hook.Add( "PlayerSpawn", ply, function( plyself, player )
        if player != ply then return end
        
        if !initspawn then GLACE:OnRespawn() end
        initspawn = false

        if ply.gb_playermodel then 
            ply:SetModel( ply.gb_playermodel )
        end
    end )

    -- On Killed hook
    hook.Add( "PlayerDeath", ply, function( plyself, player, inflictor, attacker ) 
        if player != ply then return end
        GLACE:OnKilled( attacker, inflictor )
    end )

    hook.Add( "PostCleanupMap", ply, function()
        if !IsValid( GLACE:GetNavigator() ) then
            local navigator = ents.Create( "glace_navigator" )
            navigator:SetOwner( ply )
            navigator:Spawn()
        
            GLACE:SetNavigator( navigator ) 
        end

        GLACE:GetNavigator():SetPos( GLACE:GetPos() )
        if GLACE.gb_pathgoal then GLACE:ComputePathTo( GLACE.gb_pathgoal )  end
    end )

    -- On hurt hook
    hook.Add( "PlayerHurt", ply, function( plyself, player, attacker, healthremaining, damage )
        if player != ply then return end
        GLACE:OnHurt( attacker, healthremaining, damage )
    end )


    local STUCK_RADIUS = 100 * 100
    self.m_stuckpos = GLACE:GetPos()
    self.m_stucktimer = CurTime() + 3
    self.m_stillstucktimer = CurTime() + 1

    -- Think and the Threaded think
    hook.Add( "Think", ply, function() 
        GLACE:Think()

        if coroutine.status( GLACE:GetThread() ) != "dead" then
            local ok, msg = coroutine.resume( GLACE:GetThread() )
            if !ok then ErrorNoHaltWithStack( msg ) end
        end


        if GetConVar( "glacebase_debug" ):GetBool() then debugoverlay.Line( GLACE:EyePos(), GLACE:GetEyeTrace().HitPos, 0.1, color_white, true ) end

        -- STUCK MONITOR --
        -- The following stuck monitoring system is a recreation of Source Engine's Stuck Monitoring for Nextbots
        if IsValid( GLACE:GetPath() ) and GLACE:Alive() and ( !GLACE.gb_PathStuckCheck or CurTime() < GLACE.gb_PathStuckCheck ) then
            
            if GLACE:IsStuck() then
                
                -- we are/were stuck - have we moved enough to consider ourselves "dislodged"
                if GLACE:SqrRangeTo( GLACE.m_stuckpos ) > STUCK_RADIUS then
                    GLACE:ClearStuck()

                else

                    -- Still stuck
                    if CurTime() > GLACE.m_stillstucktimer then
                        
                        GLACE:DevMsg( "IS STILL STUCK\n", GLACE:GetPos() )

                        debugoverlay.Sphere( GLACE:GetPos(), 100, 1, Color( 255, 0, 0 ), true )

                        GLACE:OnStuck()
                        GLACE.m_stillstucktimer = CurTime() + 1
                    end

                end

            else
                GLACE.m_stillstucktimer = CurTime() + 1

                -- We have moved. Reset the timer and position
                if GLACE:SqrRangeTo( GLACE.m_stuckpos ) > STUCK_RADIUS then
                    GLACE.m_stucktimer = CurTime() + 3
                    GLACE.m_stuckpos = GLACE:GetPos()


                else -- We are within the stuck radius. If we've been here too long, then, we are probably stuck

                    debugoverlay.Line( GLACE:WorldSpaceCenter(), GLACE.m_stuckpos, 1, Color( 255, 0, 0 ), true )

                    if CurTime() > GLACE.m_stucktimer then
                        GLACE._ISSTUCK = true

                        debugoverlay.Sphere( GLACE:GetPos(), 100, 2, Color( 255, 0, 0 ), true )
                        GLACE:DevMsg( "IS STUCK AT\n", GLACE:GetPos() )

                        GLACE:OnStuck()
                    end
                end


            end
            
            debugoverlay.Cross( GLACE.m_stuckpos, 5, 1, color_white, true )

        else -- Reset the stuck status
            GLACE.m_stillstucktimer = CurTime() + 1
            GLACE.m_stucktimer = CurTime() + 3
            GLACE.m_stuckpos = GLACE:GetPos()
        end

    end )

    hook.Add( "PostEntityTakeDamage", ply, function( plyself, victim, info, tookdmg )
        if victim == ply or ( !victim:IsNPC() and !victim:IsNextBot() and !victim:IsPlayer() ) or victim:Health() > 0 or !tookdmg  then return end
        GLACE:OnOtherKilled( victim, info )
    end )


    return GLACE
end