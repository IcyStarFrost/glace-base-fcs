


-- To start creating our Glace Player, we first create a local function like this. 
-- This is so we can input it into a console command
local function CreateTestPlayer()

    -- We will create our Glace Player. For this, we will use the default names and playermodel
    -- The function will return a GLACE object which is what we will be working with all the time.

    -- The GLACE object is a table essentially representing the fake player. It contains many custom functions and also contains methods for players/entities.
    -- You can run any player methods or entity methods on the GLACE object and it will run those functions on the player it is representing. Pretty neat yeah?
    -- If you haven't looked in sh_playerfunctions.lua, please have a look at all the functions in there. Everything is documented for you

    -- For this Glace Player, we are gonna have the AI be pretty simple. 
    -- First, when the Player has no enemy, we are gonna have them just run around randomly.
    -- When they see a NPC, they will instantly start attacking
    -- And lastly, when they get low on health and there's a medkit nearby, go to it

    local GLACE = GLACEBASE:CreatePlayer( nil, "models/player/barney.mdl" )   
    

    GLACE:SetSprint( true ) -- Always Sprint
    GLACE:SetAutoReload( true ) -- Automatically Reload when the weapon is out of ammo
    GLACE:SetAutoSwitchWeapon( true ) -- Automatically switch weapons when the weapon and ammo is completely out

    GLACE:SetGoalTolerance( 50 ) -- Set the distance we have to be to a goal in order for it to be considered complete

    -- Here we are creating some custom Get/Set functions
    -- For example GoalPos here will make a GLACE:GetGoalPos() and a GLACE:SetGoalPos( val ). Becareful with how you name them though. They can override player/entity methods on the GLACE object
    GLACE:CreateGetSetFuncs( "Enemy" )
    GLACE:CreateGetSetFuncs( "IsMoving" )
    GLACE:CreateGetSetFuncs( "GoalPos" )
    GLACE:CreateGetSetFuncs( "LastGoal" )
    GLACE:CreateGetSetFuncs( "GoalMedkit" )

    GLACE.gb_sightcheck = CurTime() + 0.5 -- A cooldown variable for limiting how often the line of sight check runs. Just a little optimization

    -- Set our enemy to nothing when they are killed
    function GLACE:OnOtherKilled( victim, info )
        if victim == self:GetEnemy() then
            self:SetEnemy( nil )
        end
    end

    -- Attack the NPC that hurt us
    function GLACE:OnHurt( attacker )
        if !IsValid( attacker ) or ( !attacker:IsNextBot() and !attacker:IsNPC() ) then return end
        self:SetEnemy( attacker )
    end
    
    -- Respawn after two seconds
    function GLACE:OnKilled( attacker )
        -- Set these to nothing
        self:SetGoalMedkit( nil ) 
        self:SetGoalPos( nil )
        self:SetEnemy( nil )
        self:SimpleTimer( 2, function()
            self:Spawn()
        end )
    end


    -- Here this function checks for nearby medkits if we are low on health.
    -- If there's a medkit, this function takes over the Player's movement and makes them head towards the med kit
    local medcheckdelay = 0
    function GLACE:MedCheck()
        if self:Health() < self:GetMaxHealth() * 0.4 and CurTime() > medcheckdelay then
            local near = self:FindInSphere( nil, 3000, function( ent ) return ent:GetClass() == "item_healthkit" or ent:GetClass() == "item_healthvial" end )
            local closest = self:GetClosest( near )
            if IsValid( closest ) then 
                self:SetGoalPos( closest )
                self:SetGoalMedkit( closest )
            end
            medcheckdelay = CurTime() + 1
        end
    end

    -- Custom movement function
    function GLACE:ControlMove()
        
        -- If we are close to our goal, stop
        if ( isentity( self:GetGoalPos() ) and !IsValid( self:GetGoalPos() ) ) or self:SqrRangeTo( self:GetGoalPos() ) < ( 50 * 50 ) then
            self:SetGoalPos( nil ) 
            self:SetIsMoving( false )
            return
        end

        local shouldrecompute = false

        self:SetIsMoving( true )

        -- Recompute the path since it has changed
        if self:GetGoalPos() != self:GetLastGoal() then
            shouldrecompute = true
        end

        self:SetLastGoal( self:GetGoalPos() )

        if !IsValid( self:GetPath() ) or shouldrecompute then
            self:ComputePathTo( self:GetGoalPos(), 0.5 ) -- Compute the path with a 0.5 refresh rate
        else
            self:UpdateOnPath() -- Update the player on the path
        end


    end

    -- The threaded think. Basically the same thing as nextbot's :RunBehaviour() function
    function GLACE:ThreadedThink()

        while true do
            if !self:Alive() then coroutine.yield() end


            self:MedCheck() -- Check for medkits

            -- If we can shoot our enemy, then shoot them
            if IsValid( self:GetEnemy() ) and self:CanShootAt( self:GetEnemy() )  then
                self:LookTowards( self:GetEnemy(), 1 )
                self:PressKey( IN_ATTACK )
            end

            if !IsValid( self:GetEnemy() ) and !self:GetIsMoving() then -- Idle movement
                self:SetGoalPos( self:GetRandomPos( 2000 ) )
            elseif IsValid( self:GetEnemy() ) and self:SqrRangeTo( self:GetEnemy() ) > ( 400 * 400 ) then -- Get closer
                self:SetGoalPos( self:GetEnemy() )
            elseif IsValid( self:GetEnemy() ) and self:SqrRangeTo( self:GetEnemy() ) < ( 400 * 400 ) then -- Move back a bit
                self:SetGoalPos( self:GetPos() - self:NormalTo( self:GetEnemy() ) * 200 )
            end

            -- Getting a medkit is top priority so go to the medkit
            if IsValid( self:GetGoalMedkit() ) then self:SetGoalPos( self:GetGoalMedkit() ) end 

            if self:GetGoalPos() then
                self:ControlMove()
            end

            -- Check for NPCs to murder
            if CurTime() > self.gb_sightcheck then
                local near = self:FindInSphere( nil, 8000, function( ent ) return ( ent:IsNextBot() or ent:IsNPC() ) and self:CanSee( ent ) end )

                local ent = self:GetClosest( near )
                if IsValid( ent ) then self:SetEnemy( ent ) end
                
                self.gb_sightcheck = CurTime() + 0.5
            end

            coroutine.yield()
        end

    end

end

-- Add the local function to a console command and we are done! All that's left is executing the console command
concommand.Add( "glacebase_spawntestplayer", CreateTestPlayer )