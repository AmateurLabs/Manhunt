--[[
    Manhunt v0.7
    Created by Maroy of Amateur Labs
]]

class 'Manhunt'

function Manhunt:__init()
    Network:Subscribe( "ManhuntEnter", self, self.Enter )
    Network:Subscribe( "ManhuntExit", self, self.Exit )
    Network:Subscribe( "ManhuntEnterBorder", self, self.EnterBorder )
    Network:Subscribe( "ManhuntExitBorder", self, self.ExitBorder )
    Network:Subscribe( "ManhuntUpdateIt", self, self.UpdateIt )
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
    self.inMode = false
    self.isIt = false
end

function Manhunt:Enter()
    self.inMode = true
    Game:FireEvent("ply.grappling.disable")
    --Game:FireEvent("ply.parachute.disable")
end

function Manhunt:Exit()
    Waypoint:Remove()
    self.inMode = false
    Game:FireEvent("ply.grappling.enable")
    --Game:FireEvent("ply.parachute.enable")
end

function Manhunt:EnterBorder()
    self.oob = true
end

function Manhunt:ExitBorder()
    self.oob = false
end

function Manhunt:UpdateIt(it)
    if it then
        --Game:FireEvent("ply.grappling.disable")
        --Game:FireEvent("ply.parachute.disable")
    else
        --Game:FireEvent("ply.grappling.enable")
        --Game:FireEvent("ply.parachute.enable")
    end
    self.isIt = it
end

function Manhunt:UpdateItPos(pos)
    Waypoint:Remove()
    Waypoint:SetPosition(pos)
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
	
	local text = "Out of Bounds!"
    local text_width = Render:GetTextWidth( text, TextSize.Gigantic )
    local text_height = Render:GetTextHeight( text, TextSize.Gigantic )

    local pos = Vector2(    (Render.Width - text_width)/2, 
                            (Render.Height - text_height)/2 )

    Render:DrawText( pos, text, Color( 255, 255, 255 ), TextSize.Gigantic )
end

Manhunt = Manhunt()