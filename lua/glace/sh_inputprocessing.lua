
-- Process the queued inputs from Glace Players
hook.Add( "StartCommand", "GlaceBase-InputProcessing", function( ply, cmd )
    if !ply:IsGlacePlayer() or !ply:Alive() then return end 
    local GLACE = ply:GetGlaceObject()
    
    cmd:ClearButtons()
    cmd:ClearMovement()

    

    local buttonqueue = GLACE.gb_buttonqueue

    if GLACE:IsSprinting() then buttonqueue = buttonqueue + IN_SPEED end
    if buttonqueue > 0 then
        cmd:SetButtons( buttonqueue )
        GLACE.gb_buttonqueue = 0
    end

    if GLACE.gb_selectweapon then
        
        if isentity( GLACE.gb_selectweapon ) and IsValid( GLACE.gb_selectweapon ) then
            cmd:SelectWeapon( GLACE.gb_selectweapon )
        elseif isstring( GLACE.gb_selectweapon ) and GLACE:HasWeapon( GLACE.gb_selectweapon ) then
            cmd:SelectWeapon( GLACE:GetWeapon( GLACE.gb_selectweapon ) )
        end

        GLACE.gb_selectweapon = nil
    end
end )

-- Process movement inputs from Glace Players
hook.Add( "SetupMove", "Glacebase-MovementProcessing", function( ply,  mv, cmd )
    if !ply:IsGlacePlayer() or !ply:Alive() then return end 
    local GLACE = ply:GetGlaceObject()

    if GLACE.gb_approachpos then
        if CurTime() > GLACE.gb_approachend then mv:SetMoveAngles( Angle() ) GLACE.gb_approachpos = nil end
        
        if GLACE.gb_approachpos then
            mv:SetMoveAngles( ( GLACE.gb_approachpos - GLACE:GetPos() ):Angle() )
            mv:SetForwardSpeed( GLACE:IsSprinting() and GLACE:GetRunSpeed() or GLACE:GetWalkSpeed() )
        end
    elseif GLACE.gb_followpathpos then
        if CurTime() > GLACE.gb_followpathend then mv:SetMoveAngles( Angle() ) GLACE.gb_followpathpos = nil end

        if GLACE.gb_followpathpos then
            if !GLACE.gb_lookpos and !GLACE.gb_looktowardspos then 
                GLACE:GetPlayer():SetEyeAngles( LerpAngle( 0.2, GLACE:EyeAngles(), ( ( GLACE.gb_followpathpos + Vector( 0, 0, 70 ) ) - GLACE:EyePos() ):Angle() ) ) 
            end
            mv:SetMoveAngles( ( GLACE.gb_followpathpos - GLACE:GetPos() ):Angle() )
            mv:SetForwardSpeed( GLACE:IsSprinting() and GLACE:GetRunSpeed() or GLACE:GetWalkSpeed() )
        end
    end
    
    

    if GLACE.gb_movementinputforward then
        mv:SetForwardSpeed( GLACE.gb_movementinputforward )
        GLACE.gb_movementinputforward = nil
    end

    if GLACE.gb_movementinputside then
        mv:SetSideSpeed( GLACE.gb_movementinputside ) 
        gb_movementinputside = nil
    end

    
    
    

    if GLACE.gb_looktowardspos then
        if CurTime() > GLACE.gb_looktowardsend or isentity( GLACE.gb_looktowardspos ) and !IsValid( GLACE.gb_looktowardspos ) then GLACE.gb_looktowardspos = nil end

        if GLACE.gb_looktowardspos then
            local ang = ( isentity( GLACE.gb_looktowardspos ) and ( GLACE.gb_looktowardspos:WorldSpaceCenter() - GLACE:EyePos() ):Angle() ) or ( GLACE.gb_looktowardspos - GLACE:EyePos() ):Angle() ang[ 3 ] = 0
            GLACE:GetPlayer():SetEyeAngles( LerpAngle( GLACE.gb_looktowardssmooth, GLACE:EyeAngles(), ang ) )
        end
    elseif GLACE.gb_lookpos then
        if isentity( GLACE.gb_lookpos ) and !IsValid( GLACE.gb_lookpos ) or GLACE.gb_lookendtime and CurTime() > GLACE.gb_lookendtime then GLACE.gb_lookpos = nil GLACE.gb_lookendtime = nil  end

        if GLACE.gb_lookpos then
            local ang = ( isentity( GLACE.gb_lookpos ) and ( GLACE.gb_lookpos:WorldSpaceCenter() - GLACE:EyePos() ):Angle() ) or ( GLACE.gb_lookpos - GLACE:EyePos() ):Angle() ang[ 3 ] = 0
            GLACE:GetPlayer():SetEyeAngles( LerpAngle( GLACE.gb_smoothlook, GLACE:EyeAngles(), ang ) )
        end

    end

    if !IsValid( GLACE:GetNavigator() ) then
        local navigator = ents.Create( "glace_navigator" )
        navigator:SetOwner( ply )
        navigator:Spawn()
    
        GLACE:SetNavigator( navigator ) 
    end

    if GLACE:GetNavigator():GetPos() != GLACE:GetPos() then
        GLACE:GetNavigator():SetPos( GLACE:GetPos() )
    end
    
end )