--[[
    Manhunt v0.8
    Created by Maroy of Amateur Labs
]]

class "ManhuntPlayer"
function ManhuntPlayer:__init(player, Manhunt)
    self.Manhunt = Manhunt
    self.player = player
    self.start_pos = player:GetPosition()
    self.start_world = player:GetWorld()
    self.inventory = player:GetInventory()
    self.color = player:GetColor()
    self.oob = false
    self.pts = 0
    self.dead = false
    self.loaded = false
end

function ManhuntPlayer:Enter()
    self.player:SetWorld(self.Manhunt.world)
    self:Spawn()
    Network:Send( self.player, "ManhuntEnter" )
end

function ManhuntPlayer:Spawn()
  if self.player:GetHealth() <= 0.1 then return end
    local spawn = self.Manhunt.spawns[ math.random(1, #self.Manhunt.spawns) ]
    self.player:Teleport(spawn, Angle())
    self.player:ClearInventory()
    if self.Manhunt.it == self.player then
        self.player:SetColor( Color(255, 0, 0) )
        self.player:GiveWeapon(0, Weapon(Weapon.Revolver))
        --self.player:GiveWeapon(1, Weapon(Weapon.Revolver))
        self.player:GiveWeapon(2, Weapon(Weapon.MachineGun))
    else
        self.player:GiveWeapon(0, Weapon(Weapon.Revolver))
        --self.player:GiveWeapon(1, Weapon(Weapon.Revolver))
        self.player:GiveWeapon(2, Weapon(Weapon.Sniper))
        self.player:SetColor( Color(0, 255, 0) )
    end
    self.player:SetHealth(50)
    self.dead = false
end

function ManhuntPlayer:Leave()
    self.player:SetWorld( self.start_world )
    self.player:Teleport( self.start_pos, Angle() )

    self.player:ClearInventory()
    for k,v in pairs(self.inventory) do
        self.player:GiveWeapon( k, v )
    end
	self.player:SetColor( self.color )
    Network:Send( self.player, "ManhuntExit" )
end

class "Manhunt"
function table.find(l, f)
  for _, v in ipairs(l) do
    if v == f then
      return _
    end
  end
  return nil
end

function Manhunt:CreateSpawns()
    local dist = self.maxDist - 128
	
    for j=0,8,1 do
    for i=0,360,1 do        
          local x = self.center.x + (math.sin( 2 * i * math.pi/360 ) * dist * math.random())
          local y = self.center.y 
          local z = self.center.z + (math.cos( 2 * i * math.pi/360 ) * dist * math.random())
          
          local radians = math.rad(360 - i)
          
          angle = Angle.AngleAxis(radians , Vector3(0 , -1 , 0))
          table.insert(self.spawns, Vector3( x, y, z ))
    end
    end
end

function Manhunt:UpdateScores()
    scores = {}
    for k,v in pairs(self.players) do
        table.insert(scores, { name=v.player:GetName(), pts=v.pts, it=(self.it == v.player)})
    end
    table.sort(scores, function(a, b) return a.pts > b.pts end)
    for k,v in pairs(self.players) do
        Network:Send( v.player, "ManhuntUpdateScores", scores )
    end
end

function Manhunt:SetIt( v )
    if self.it ~= nil then Network:Send( self.it, "ManhuntUpdateIt", false ) end
    self.it = v.player
    self.oldIt = v.player
    self:MessagePlayers( self.it:GetName().." is now the Hunted!" )
    Network:Send( self.it, "ManhuntUpdateIt", true )
    v:Spawn()
    self:UpdateScores()
end

function Manhunt:__init( spawn, maxDist )
    self.world = World.Create()
    self.world:SetTimeStep( 10 )
    self.world:SetTime( 0 )
    
    self.spawns = {}
	  self.center = spawn
	  self.maxDist = maxDist

    self:CreateSpawns()
    
    self.players = {}
    self.last_broadcast = 0
    self.last_wp = 0
	
    Events:Subscribe( "PlayerChat", self, self.ChatMessage )
    Events:Subscribe( "ModuleUnload", self, self.ModuleUnload )
    
    Events:Subscribe( "PlayerJoin", self, self.PlayerJoined )
    Events:Subscribe( "PlayerQuit", self, self.PlayerQuit )
    
    Events:Subscribe( "PlayerDeath", self, self.PlayerDeath )
    Events:Subscribe( "PlayerSpawn", self, self.PlayerSpawn )
    Events:Subscribe( "PostTick", self, self.PostTick )

    Events:Subscribe( "PlayerEnterVehicle", self, self.PlayerEnterVehicle )
    Events:Subscribe( "PlayerExitVehicle", self, self.PlayerExitVehicle )

    Events:Subscribe( "JoinGamemode", self, self.JoinGamemode )
end

function Manhunt:ModuleUnload()
    for k,v in pairs(self.players) do
        v:Leave()
        self:MessagePlayer(v.player, "Manhunt script unloaded. You have been restored to your starting pos.")
    end
    self.players = {}
end

function Manhunt:PostTick()
    if ( os.difftime(os.time(), self.last_broadcast) >= 5*60 ) then
        self:MessageGlobal( "Manhunt is underway! /hunt to enter." )
        self.last_broadcast = os.time()
    end
    
    --[[local minDist = 99999999999
    
    if self.it then
        for k,v in pairs(self.players) do
            local dist = Vector3.Distance(v.player:GetPosition(), self.it:GetPosition())
            if dist < minDist and self.it ~= v.player then
                minDist = dist
            end
        end
    end
    
    if minDist < 1024 and os.difftime(os.time(), self.last_wp) >= 5 then
        for k,v in pairs(self.players) do
            Network:Send(v.player, "ManhuntUpdateItPos", self.it:GetPosition())
        end
    end
    ]]
	
    for k,v in pairs(self.players) do
        local randIt = math.random() < 1 / table.count(self.players)
        if self.it then
        
        elseif (randIt and self.oldIt and self.oldIt ~= player) or #self.players > 1 then
            self:SetIt( v )
        end
        local dist = Vector3.Distance(v.player:GetPosition(), self.center)
        if v.loaded then
            if v.oob and dist < self.maxDist - 32 then
                Network:Send( v.player, "ManhuntExitBorder" )
                v.oob = false
            end
            if not v.oob and dist > self.maxDist - 32 then
                Network:Send( v.player, "ManhuntEnterBorder" )
                v.oob = true
            end
            if not v.dead and dist > self.maxDist then
                v.player:SetHealth(0)
                v.dead = true
                v.loaded = false
                self:MessagePlayer ( v.player, "You left the playing area!" )
            end
        else
            if Vector3.Distance(v.player:GetPosition(), self.center) < self.maxDist then v.loaded = true end
        end
    end
end

function Manhunt:IsInManhunt(player)
    return self.players[player:GetId()] ~= nil
end

function Manhunt:MessagePlayer(player, message)
    player:SendChatMessage( "[Manhunt] " .. message, Color(0xfff0b010) )
end

function Manhunt:MessagePlayers(message)
    for k,v in pairs(self.players) do
        self:MessagePlayer(v.player, message)
    end
end

function Manhunt:MessageGlobal(message)
    Chat:Broadcast( "[Manhunt] " .. message, Color(0xfff0c5b0) )
end

function Manhunt:EnterManhunt(player)
    if player:GetWorld() ~= DefaultWorld then
        self:MessagePlayer(player, "You must exit all other game modes before joining.")
        return
    end
    
    local args = {}
    args.name = "Manhunt"
    args.player = player
    Events:Fire( "JoinGamemode", args )
    
    local p = ManhuntPlayer(player, self)
    p:Enter()
    
    self:MessagePlayer(player, "You have entered the Manhunt! Type /hunt to leave.") 
    
    if self.oldIt and self.it then
        self:MessagePlayer(player, self.it:GetName().." is currently being Hunted!") 
    else
        self:SetIt( p )
    end
    
    self.players[player:GetId()] = p
    Network:Send( player, "ManhuntUpdateIt", self.it == player )
    self:UpdateScores()
end

function Manhunt:LeaveManhunt(player)
    local p = self.players[player:GetId()]
    if p == nil then return end
    p:Leave()
    
    self:MessagePlayer(player, "You have left the Manhunt! Type /hunt to enter at any time.")    
    self.players[player:GetId()] = nil
    if self.it == player then self.it = nil end
    self:UpdateScores()
end

function Manhunt:ChatMessage(args)
    local msg = args.text
    local player = args.player
    
    
    if ( msg:sub(1, 1) ~= "/" ) then
        if self:IsInManhunt(player) then
            for k,v in pairs(self.players) do
                player:SendChatMessage( "[Manhunt] "..v.player:GetName()..": " .. msg, v.player:GetColor() )
            end
        else
            return true
        end
    end    
    
    local cmdargs = {}
    for word in string.gmatch(msg, "[^%s]+") do
        table.insert(cmdargs, word)
    end
    
    if ( cmdargs[1] == "/hunt" ) then
        if ( self:IsInManhunt(player) ) then
            self:LeaveManhunt(player, false)
        else        
            self:EnterManhunt(player)
        end
    end
    if (cmdargs[1] == "/pos" ) then
		local pos = player:GetPosition()
		self:MessagePlayer(player, "Your coordinates are ("..pos.x..","..pos.y..","..pos.z..")")
    end
    return false
end

function Manhunt:PlayerJoined(args)
    self.players[args.player:GetId()] = nil
    if self.it == args.player then self.it = nil end
    self:UpdateScores()
end

function Manhunt:PlayerQuit(args)
    self.players[args.player:GetId()] = nil
    if self.it == args.player then self.it = nil end
    self:UpdateScores()
end

function Manhunt:PlayerDeath(args)
    if ( not self:IsInManhunt(args.player) ) then
        return true
    end
    if self.it == args.player then
        args.player:SetColor( Color(0, 255, 0) )
        if args.killer then
          self.it = args.killer
          self.oldIt = args.killer
          self.players[self.it:GetId()].pts = self.players[self.it:GetId()].pts + 5
          Network:Send( self.it, "ManhuntUpdatePoints", self.players[self.it:GetId()].pts )
          self:MessagePlayers(args.killer:GetName().." killed "..args.player:GetName().." and is now the Hunted!")
          self.players[args.killer:GetId()]:Spawn()
        else
          self.it = nil
          if args.reason == DamageEntity.None then
              self:MessagePlayers(args.player:GetName().." has perished!")
          elseif args.reason == DamageEntity.Physics then
              self:MessagePlayers(args.player:GetName().." was crushed!")
          elseif args.reason == DamageEntity.Bullet then
              self:MessagePlayers(args.player:GetName().." was filled with lead!")
          elseif args.reason == DamageEntity.Explosion then
              self:MessagePlayers(args.player:GetName().." asploded!")
          elseif args.reason == DamageEntity.Vehicle then
              self:MessagePlayers(args.player:GetName().." was demolished!")
          end
      end
          self:UpdateScores()
    elseif self.it and self.it == args.killer then
          self.players[self.it:GetId()].pts = self.players[self.it:GetId()].pts + 1
          Network:Send( self.it, "ManhuntUpdatePoints", self.players[self.it:GetId()].pts )
          self:MessagePlayers(args.killer:GetName().." killed Hunter "..args.player:GetName().."!")
          self:UpdateScores()
    end
end

function Manhunt:PlayerSpawn(args)
    if ( not self:IsInManhunt(args.player) ) then
        return true
    end
    
    self:MessagePlayer(args.player, "You have spawned in the Manhunt. Type /hunt if you wish to leave.")
	
    self.players[args.player:GetId()]:Spawn()
    return false
end

function Manhunt:PlayerEnterVehicle(args)
    if ( not self:IsInManhunt(args.player) ) then
        return true
    end
    args.vehicle:SetHealth(0)
end

function Manhunt:PlayerExitVehicle(args)
    if ( not self:IsInManhunt(args.player) ) then
        return true
    end
end

function Manhunt:JoinGamemode( args )
    if args.name ~= "Manhunt" then
        self:LeaveManhunt( args.player )
    end
end

--Manhunt = Manhunt(Vector3(-13790, 1200, -13625), 2048)
Manhunt = Manhunt(Vector3(15210, 350, -13213), 640)