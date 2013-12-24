class 'Manhunt'

function Manhunt:__init()
	Network:Subscribe( "ManhuntEnter", self, self.Enter )
	Network:Subscribe( "ManhuntExit", self, self.Exit )
    Network:Subscribe( "ManhuntEnterBorder", self, self.EnterBorder )
    Network:Subscribe( "ManhuntExitBorder", self, self.ExitBorder )
	Network:Subscribe( "ManhuntUpdateItPos", self, self.UpdateItPos )
    Network:Subscribe( "ManhuntUpdatePoints", self, self.UpdatePoints )
    Network:Subscribe( "ManhuntUpdateScores", self, self.UpdateScores )

    Events:Subscribe( "Render", self, self.Render )
    Events:Subscribe( "ModuleLoad", self, self.ModulesLoad )
    Events:Subscribe( "ModulesLoad", self, self.ModulesLoad )
    Events:Subscribe( "ModuleUnload", self, self.ModuleUnload )
	
	self.oob = false
    self.pts = 0
    self.scores = {}
	self.itPos = Vector3(0, 0, 0)
    self.inMode = false
end

function Manhunt:Enter()
    self.inMode = true
end

function Manhunt:Exit()
	Waypoint:Remove()
    self.inMode = false
end

function Manhunt:EnterBorder()
	self.oob = true
end

function Manhunt:ExitBorder()
    self.oob = false
end

function Manhunt:UpdateItPos(pos)
	if Vector3.Distance(pos, LocalPlayer:GetPosition()) > 10 then
		Waypoint:SetPosition(pos)
	else
		Waypoint:Remove()
	end
	self.itPos = pos
end

function Manhunt:UpdatePoints(pts)
    self.pts = pts
end

function Manhunt:UpdateScores(scores)
    self.scores = scores
end

function Manhunt:ModulesLoad()
    Events:Fire( "HelpAddItem",
        {
            name = "Manhunt",
            text = 
                "The Manhunt is a 1vAll fight game mode.\n \n" ..
                "To enter the Manhunt, type /Manhunt in chat and hit enter. " ..
                "You will be transported to the Manhunt, where you will respawn " ..
                "until you exit by using the command once more.\n \n" ..
                "If you leave the boundaries of the island, you will " ..
                "be killed."
        } )
end

function Manhunt:ModuleUnload()
    Events:Fire( "HelpRemoveItem",
        {
            name = "Manhunt"
        } )
end

function Manhunt:RightText( msg, y, color )
    local w = Render:GetTextWidth( msg, TextSize.Default )
    Render:DrawText( Vector2(Render.Width - w, y), msg, color, TextSize.Default )
end

function Manhunt:Render()
    --if self.timer == nil then return end
    if not self.inMode then return end 
    if Game:GetState() ~= GUIState.Game then return end
    
    self:RightText( "Your Points: "..self.pts, 48, Color( 255, 255, 0) )
    self:RightText( "[Leaderboard]", 80, Color( 255, 255, 0) )
    for i = 1, math.min(#self.scores, 10), 1 do
        local color = Color( 0, 255, 0)
        if self.scores[i].it then color = Color(255, 0, 0) end
        self:RightText( ""..i..". "..self.scores[i].name..": "..self.scores[i].pts, 80 + i * 16, color )
    end
	if not self.oob then return end
	--local dist = Vector3.Distance(LocalPlayer:GetPosition(), self.itPos)
	--local pos = Render:WorldToScreen(self.itPos)
	--Render:DrawCircle(pos, (dist / 1024), Color(255, 0, 0, 191))
	
    --[[
	local time = 20 - math.floor(math.clamp( self.timer:GetSeconds(), 0, 20 ))

    if time <= 0 then return end

    local text = tostring(time)
	]]
	
	local text = "Out of Bounds!"
    local text_width = Render:GetTextWidth( text, TextSize.Gigantic )
    local text_height = Render:GetTextHeight( text, TextSize.Gigantic )

    local pos = Vector2(    (Render.Width - text_width)/2, 
                            (Render.Height - text_height)/2 )

    Render:DrawText( pos, text, Color( 255, 255, 255 ), TextSize.Gigantic )
end

Manhunt = Manhunt()