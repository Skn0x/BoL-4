--[[
	Top Lane Series - Shyvana by lel itz ok
	version 0.001
	20/06/2014
--]]
local version = 0.001

local author = "lel itz ok"

local scriptName = "TopLaneSeries"

if myHero.charName ~= "Shyvana" then return end

local AUTOUPDATE = true
local UPDATE_HOST = "raw.github.com"
local UPDATE_PATH = "/jelorono/BoL/master/TopLaneSeries%20-%20Shyvana.lua".."?rand="..math.random(1,10000)
local UPDATE_FILE_PATH = SCRIPT_PATH.."TopLaneSeries - Shyvana.lua"
local UPDATE_URL = "https://"..UPDATE_HOST..UPDATE_PATH

function AutoupdaterMsg(msg) print("<font color='#5F9EA0'><b>[".. scriptName .."] </font><font color='#cffffffff'> "..msg..".</font>") end
	if AUTOUPDATE then
		local ServerData = GetWebResult(UPDATE_HOST, "/jelorono/BoL/master/versions/TopLaneSeries%20-%20Shyvana.version")
		if ServerData then
			ServerVersion = type(tonumber(ServerData)) == "number" and tonumber(ServerData) or nil
				if ServerVersion then
					if tonumber(version) < ServerVersion then
						AutoupdaterMsg("New version available"..ServerVersion)
						AutoupdaterMsg("Updating, please don't press F9")
						DelayAction(function() DownloadFile(UPDATE_URL, UPDATE_FILE_PATH, function () AutoupdaterMsg("Successfully updated. ("..version.." => "..ServerVersion.."), press F9 twice to load the updated version.") end) end, 3)
					else
						AutoupdaterMsg("You have got the latest version ("..ServerVersion..")")
					end
				end
		else
			AutoupdaterMsg("Error downloading version info")
	end
end

require 'VPrediction'
require 'SOW'

if VIP_USER then
	require 'Prodiction'
end

--------------------------------------------------------------------------------------------------------------------------------------------
---- Variables
--------------------------------------------------------------------------------------------------------------------------------------------
local Shyvana = {
	AA = { range = 125 },
	Q = { range = 165 },
	W = { range = 325 },
	E = { range = 925, width = 80, speed = 1500, delay = 0.125 },
	R = { range = 1000, width = 80, speed = 1000, delay = 0.125 },
	levelSequence = { 3,2,1,2,2,4,2,3,2,3,4,3,3,1,1,4,1,1 }	
}

local ignite = nil
local target = nil

--------------------------------------------------------------------------------------------------------------------------------------------
---- Callbacks
--------------------------------------------------------------------------------------------------------------------------------------------

function OnLoad()	
	-- Assign libraries
	VP = VPrediction()
    ts = TargetSelector(TARGET_LESS_CAST_PRIORITY, 1000, DAMAGE_PHYSICAL)
    ts.name = "Shyvana"
    OW = SOW(VP)

	-- Load the menu
	Menu()

	-- Pretty little chat msg
	PrintChat("<font color='#5F9EA0'><b>[".. scriptName .."] </font><font color='#cffffffff'> Shyvana v".. version .."</b> loaded!</font>" )
end

function OnTick()
	-- If dead, we will return the function here so it doesn't loop through the rest
	if myHero.dead then return end	
	
	-- Call our pulse
	Pulse()

	if Menu.Misc.autoLevel == 2 then autoLevelSetSequence(Shyvana.levelSequence) end									-- Set auto level sequence if enabled 
	if Menu.Combo.comboKey then Combo()	end 																		-- Call Combo() function if key is down
	if Menu.Harass.harassKey1 or Menu.Harass.harassKey2 then Harass() end 											-- Call Harass() function if key is down
	if Menu.Farm.LastHit.lasthitKey then FarmManager("lastHit") end
	if Menu.Farm.LaneClear.laneclearKey then FarmManager("laneClear") end
	if Menu.Misc.escapeKey then Escape() end 																		-- Call Escape() function if key is down
end

function OnDraw()
	-- Don't draw incase we are dead
	if myHero.dead then return end	
	
	if Menu.Farm.LaneClear.laneclearKey or Menu.Farm.LastHit.lasthitKey then
		DrawLastHit()
	end
	
	-- If drawing is enabled, check what to draw.
	if Menu.Draw.drawAll then
		if Menu.Draw.drawAA then
			DrawCircle(myHero.x, myHero.y, myHero.z, Shyvana.AA["range"], ARGB(255, 255, 255, 255))
		end
		if Menu.Draw.drawW and wReady then
			DrawCircle(myHero.x, myHero.y, myHero.z, Shyvana.W["range"], ARGB(255, 255, 255, 255))
		end
		if Menu.Draw.drawE and eReady then
			DrawCircle(myHero.x, myHero.y, myHero.z, Shyvana.E["range"], ARGB(255, 255, 255, 255))
		end
		if Menu.Draw.drawR and rReady then
			DrawCircle(myHero.x, myHero.y, myHero.z, Shyvana.R["range"], ARGB(255, 255, 255, 255))
		end		
		if Menu.Draw.predLoc and target ~=nil then 
			DrawPredPos()
		end
		if target ~= nil then
			DrawCircle(target.x, target.y, target.z, 150, ARGB(255, 34, 139, 34))	
			DrawDmgCalc()
		end	
	end
end

--------------------------------------------------------------------------------------------------------------------------------------------
---- Draw functions
--------------------------------------------------------------------------------------------------------------------------------------------

function DrawLastHit()
	for i, minion in pairs(enemyMinions.objects) do
		if minion ~= nil and minion.health < getDmg("AD", minion, myHero) then
			DrawCircle(minion.x, minion.y, minion.z, 65, ARGB(255, 255, 255, 255))	
		end
	end
end

function DrawPredPos()
	local castPos, info = Prodiction.GetLineAOEPrediction(target, Shyvana.E["range"], Shyvana.E["speed"], Shyvana.E["delay"], Shyvana.E["width"])																
	if Menu.Draw.predLoc and castPos ~= nil and target ~= nil then
		DrawCircle(castPos.x, castPos.y, castPos.z, 150, ARGB(255, 34, 139, 34))
		DrawLine3D(castPos.x, castPos.y, castPos.z, target.x, target.y, target.z, 5, ARGB(255, 34, 139, 34))			
	end
end

function DrawDmgCalc()
	if GetBurstDamage() > target.health then 
		local drawPos = WorldToScreen(D3DXVECTOR3(target.x, target.y, target.z))
		local drawPosX = drawPos.x - 35
		local drawPosY = drawPos.y - 50
		DrawText("100% KILL - GO FOR IT!", 15, drawPosX, drawPosY, ARGB(255, 255, 125, 000))
	end
end

function GetBurstDamage()	
	local Q = 0
	local W = 0
	local E = 0
	local R = 0
	local burst = 0
	
	if qReady then
		Q = getDmg("Q", target, myHero)
	end
	if wReady then
		W = getDmg("W", target, myHero)
	end
	if eReady then
		E = getDmg("E", target, myHero)
	end
	if rReady then
		R = getDmg("R", target, myHero)
	end
	
	burst = Q + W + E + R
	return burst
end

--------------------------------------------------------------------------------------------------------------------------------------------
---- General functions
--------------------------------------------------------------------------------------------------------------------------------------------

function OnCreateObj(obj)
    if obj ~= nil then
    	if obj.name:find("Global_Item_HealthPotion.troy") then
			if GetDistance(obj, myHero) <= 70 then
				potActive = true
			end
		end
        if obj.name:find("TeleportHome.troy") then
            if GetDistance(obj) <= 70 then
                Recalling = true
            end
        end 
    end
end

function OnDeleteObj(obj)
	if obj ~= nil then  
		if obj.name:find("Global_Item_HealthPotion.troy") then
			if GetDistance(obj) <= 70 then
				potActive = false
			end
		end      
        if obj.name:find("TeleportHome.troy") then
            if GetDistance(obj) <= 70 then
                Recalling = false
            end
        end         
    end
end

-- High speed checks for ready spells
function Pulse()
	-- Update the target selector and assign our target to the target variable
	ts:update()
	target = ts.target

	HPManager()	

	if myHero:GetSpellData(SUMMONER_1).name:find("SummonerDot") then
		ignite = SUMMONER_1
	elseif myHero:GetSpellData(SUMMONER_2).name:find("SummonerDot") then
		ignite = SUMMONER_2
	end

	enemyMinions = minionManager(MINION_ENEMY, Shyvana.E["range"], myHero, MINION_SORT_HEALTH_ASC)

	-- Check if our spells are ready
	qReady = (myHero:CanUseSpell(_Q) == READY)
    wReady = (myHero:CanUseSpell(_W) == READY)
    eReady = (myHero:CanUseSpell(_E) == READY)
    rReady = (myHero:CanUseSpell(_R) == READY)	
	if ignite ~= nil then iReady = (ignite ~= nil and myHero:CanUseSpell(ignite) == READY) end							-- Ignite

	tiamatSlot = GetInventorySlotItem(3077)																				-- Tiamat
	hydraSlot = GetInventorySlotItem(3074)																				-- Ravenous Hydra
	youmuuSlot = GetInventorySlotItem(3142)																				-- Youmuu's Ghostblade
	bilgeSlot = GetInventorySlotItem(3144)																				-- Bilgewater Cutlass
	bladeSlot = GetInventorySlotItem(3153)																				-- Blade of the Ruined King
	potSlot = GetInventorySlotItem(2003)	

	tiamatReady = (tiamatSlot ~= nil and myHero:CanUseSpell(tiamatSlot) == READY) 										-- Tiamat
	hydraReady = (hydraSlot ~= nil and myHero:CanUseSpell(hydraSlot) == READY) 											-- Ravenous Hydra
	youmuuReady	= (youmuuSlot ~= nil and myHero:CanUseSpell(youmuuSlot) == READY) 										-- Youmuu's Ghostblade
	bilgeReady = (bilgeSlot ~= nil and myHero:CanUseSpell(bilgeSlot) == READY) 											-- Bilgewater Cutlass
	bladeReady = (bladeSlot ~= nil and myHero:CanUseSpell(bladeSlot)	== READY)										-- Blade of the Ruined King
				
end

-- Check on if we have ignite and bind it to the ignite variable
function haveIgnite()
	if myHero:GetSpellData(SUMMONER_1).name:find("SummonerDot") then
			ignite = SUMMONER_1
			return true
	elseif myHero:GetSpellData(SUMMONER_2).name:find("SummonerDot") then
			ignite = SUMMONER_2
			return true
	end
	return false
end

--------------------------------------------------------------------------------------------------------------------------------------------
---- Modes functions
--------------------------------------------------------------------------------------------------------------------------------------------

-- Combo
function Combo()
	-- Call our spell manager with our desired spells
	SpellManager(target, Menu.Combo.useQ, Menu.Combo.W.useW, Menu.Combo.useE, Menu.Combo.useR, Menu.Combo.useItems, Menu.Combo.useIgnite, false)
end

-- Harass
function Harass()	
	-- Call our spell manager with our desired spells
    SpellManager(target, Menu.Harass.useQ, false, Menu.Harass.useE, false, false, false, false)
end

-- Escape
function Escape()
	-- Call our spell manager with our desired spells
	SpellManager(target, false, false, Menu.Harass.useE, false, false, false, true)
end

--------------------------------------------------------------------------------------------------------------------------------------------
---- Manager functions
--------------------------------------------------------------------------------------------------------------------------------------------

function FarmManager(farmType)
	for i, minion in pairs(enemyMinions.objects) do
		if ValidTarget(minion) and minion ~= nil then
			if farmType == "laneClear" then
				if  GetDistance(minion) <= Shyvana.E["range"] then 
					SpellManager(minion, Menu.Farm.LaneClear.useQ, Menu.Farm.LaneClear.useW, Menu.Farm.LaneClear.useE, false, false, false, false)			
				end
			end
			if farmType == "lastHit" then
				if Menu.Farm.LastHit.useE and GetDistance(minion) <= Shyvana.E["range"] and getDmg("E", minion, myHero) >= minion.health then 
					SpellManager(minion, false, false, true, false, false, false, false)			
				end
			end
		end		 
	end	
end

-- HP Manager
function HPManager()
	-- If we are not on the fountain and not recalling and we have a target
	if not InFountain() and not Recalling and target ~= nil then		
		if Menu.Misc.usePots and myHero.health < (myHero.maxHealth * (Menu.Misc.HPHealth / 100)) and potSlot
			and not potActive then
				CastSpell(potSlot)
		end
	end
end	

-- Spell Manager
function SpellManager(target, Qs, Ws, Es, Rs, items, uIgnite, escape)
	if Rs then
		if target and rReady then
			if Menu.Combo.R.useR then
				if GetDistance(target) <= Shyvana.R["range"] and ValidTarget(target) then
					local castPos, info = Prodiction.GetCircularAOEPrediction(target, Shyvana.R["range"], Shyvana.R["speed"], Shyvana.R["delay"], Shyvana.R["width"])																
					if castPos then
						if info.hitchance ~= 0 then
							CastSpell(_R, castPos.x, castPos.z)
						end
					end 
				end
			end
		end
	end

	if Ws then
		if target and wReady then
			if Menu.Combo.W.rangeW then
				if ValidTarget(target) and GetDistance(target) <= Shyvana.W["range"] then
					CastSpell(_W)
				end
			end
			if not Menu.Combo.W.rangeW then
				if ValidTarget(target) then
					CastSpell(_W)
				end
			end
		end
	end

	if Es then
		if target and eReady then
			if ValidTarget(target) then
				if VIP_USER then
					local castPos, info = Prodiction.GetLineAOEPrediction(target, Shyvana.E["range"], Shyvana.E["speed"], Shyvana.E["delay"], Shyvana.E["width"])
					if castPos and info.hitchance ~= 0 then
						CastSpell(_E, castPos.x, castPos.z)
					end
				else
					CastSpell(_E, target.x, target.z)
				end
			end
		end
	end	

	if Qs then
		if target and qReady then
			if ValidTarget(target) and GetDistance(target) <= Shyvana.Q["range"] then	
				CastSpell(_Q)
			end
		end
	end	

    if items then
    	if ValidTarget(target) then
    		ItemManager(target)
    	end
    end

    if uIgnite then
    	if target and iReady and (Menu.Combo.useIgnite == 2 or Menu.Combo.useIgnite == 3) then  
			if Menu.Combo.useIgnite == 3 then
				for i = 1, heroManager.iCount, 1 do
					local iTarget = heroManager:getHero(i)
					if ValidTarget(iTarget, 600) then
						dmg = 50 + 20 * myHero.level
						if Menu.Combo.useIgnite == 2 and iTarget.health <= dmg then
								CastSpell(ignite, iTarget)
						end
					end
				end
			elseif Menu.Combo.useIgnite == 2 then
				CastSpell(ignite, target)
			end
		end
    end

    if escape then
    	if GetDistance(mousePos) then
    		-- Thanks to Dienofail
			local moveToPos = myHero + (Vector(mousePos) - myHero):normalized()*300
			myHero:MoveTo(moveToPos.x, moveToPos.z)
    	end   
    	if wReady then
	      CastSpell(_W)
       	end
    end
end

-- Item Manager
function ItemManager(target)
	if target then
		-- Tiamat
		if tiamatReady and GetDistance(target) <= 185 then 
			CastSpell(tiamatSlot, target) 
		end

		-- Ravenous Hydra
		if hydraReady and GetDistance(target) <= 185 then 
			CastSpell(hydraSlot, target) 
		end

		-- Bilgewater Cutlass
		if bilgeReady and GetDistance(target) <= 450 then 
			CastSpell(bilgeSlot, target) 			
		end

		-- Blade of the Ruined King
		if bladeReady and GetDistance(target) <= 450 then 
			CastSpell(bladeSlot, target) 
		end

		-- Youomuu's Ghostblade
		if youmuuReady and GetDistance(target) <= 150 then 
			CastSpell(youmuuSlot) 
		end
	end
end

--------------------------------------------------------------------------------------------------------------------------------------------
---- Menu function
--------------------------------------------------------------------------------------------------------------------------------------------

function Menu()
	-- Top level menu
	Menu = scriptConfig("[Top Lane Series] Shyvana", "Shyvana")
		--{ Target selector settings
		Menu:addSubMenu("[Settings] Target Selector", "TS")
			Menu.TS:addTS(ts)	
		--}	

		--{ Combo settings
		Menu:addSubMenu("[Settings] Combo mode", "Combo")
			Menu.Combo:addSubMenu("[Settings] W logic", "W")				
				Menu.Combo.W:addParam("rangeW", "Use W only when in range", SCRIPT_PARAM_ONOFF, false)
				Menu.Combo.W:addParam("useW", "Use W in combo mode", SCRIPT_PARAM_ONOFF, true)							-- Use W true/false
			Menu.Combo:addSubMenu("[Settings] R logic", "R")
				Menu.Combo.R:addParam("useR", "Use R in combo mode", SCRIPT_PARAM_ONOFF, true)								-- Use E true/false

			Menu.Combo:addParam("useQ", "Use Q in combo mode", SCRIPT_PARAM_ONOFF, true)								-- Use Q true/false			
			Menu.Combo:addParam("useE", "Use E in combo mode", SCRIPT_PARAM_ONOFF, true)								-- Use E true/false
			
			Menu.Combo:addParam("useItems", "Use items in combo mode", SCRIPT_PARAM_ONOFF, true)						-- Use items true/false				
			Menu.Combo:addParam("useIgnite", "Ignite mode", SCRIPT_PARAM_LIST, 1, {"Disable", "On combo", "Secure kill"}) -- Use ignite dropdown			
			Menu.Combo:addParam("comboKey", "Combo mode", SCRIPT_PARAM_ONKEYDOWN, true, 32)								-- Carry me! true/false
		--}

		--{ Harass settings
		Menu:addSubMenu("[Settings] Harass mode", "Harass")
			Menu.Harass:addParam("useQ", "Use Q in harass mode", SCRIPT_PARAM_ONOFF, false)								-- Use Q true/false
			Menu.Harass:addParam("useE", "Use E in harass mode", SCRIPT_PARAM_ONOFF, true)								-- Use E true/false
			Menu.Harass:addParam("harassKey1", "Harass mode #1", SCRIPT_PARAM_ONKEYDOWN, false, string.byte("C"))		-- Harass true/false
			Menu.Harass:addParam("harassKey2", "Harass mode #2", SCRIPT_PARAM_ONKEYDOWN, false, string.byte("V"))		-- Harass true/false
		--}


		--{ Farm settings
		Menu:addSubMenu("[Settings] Farm mode", "Farm")
			Menu.Farm:addSubMenu("[Settings] Lane clear]", "LastHit")
				Menu.Farm.LastHit:addParam("useE", "Use E to last hit", SCRIPT_PARAM_ONOFF, true)								-- Use Q true/false
				Menu.Farm.LastHit:addParam("lasthitKey", "Last hit key", SCRIPT_PARAM_ONKEYDOWN, false, string.byte("X"))		-- Lane clear true/false
			Menu.Farm:addSubMenu("[Settings] Lane clear]", "LaneClear")
				Menu.Farm.LaneClear:addParam("useQ", "Use Q in lane clear", SCRIPT_PARAM_ONOFF, true)								-- Use Q true/false
				Menu.Farm.LaneClear:addParam("useW", "Use W in lane clear", SCRIPT_PARAM_ONOFF, true)								-- Use W true/false
				Menu.Farm.LaneClear:addParam("useE", "Use E in lane clear", SCRIPT_PARAM_ONOFF, true)								-- Use E true/false
				Menu.Farm.LaneClear:addParam("laneclearKey", "Lane clear key", SCRIPT_PARAM_ONKEYDOWN, false, string.byte("V"))		-- Lane clear true/false
		--}


		--{ SOW settings	
		Menu:addSubMenu("[Settings] Orbwalking", "Orbwalker")
			OW:LoadToMenu(Menu.Orbwalker)
			OW:RegisterAfterAttackCallback(AfterAttack)
		--}

		--{ Draw settings	
		Menu:addSubMenu("[Settings] Drawing", "Draw")
			Menu.Draw:addParam("drawAll", "Enable drawing", SCRIPT_PARAM_ONOFF, true)									-- Draw all true/false
			Menu.Draw:addParam("drawAA", "Draw AA range", SCRIPT_PARAM_ONOFF, true)										-- Draw AA true/false
			Menu.Draw:addParam("drawW", "Draw W range", SCRIPT_PARAM_ONOFF, true)										-- Draw Q true/false
			Menu.Draw:addParam("drawE", "Draw E range", SCRIPT_PARAM_ONOFF, true)										-- Draw E true/false		
			Menu.Draw:addParam("drawR", "Draw R range", SCRIPT_PARAM_ONOFF, true)										-- Draw R true/false
			Menu.Draw:addParam("predLoc", "Draw predicted location", SCRIPT_PARAM_ONOFF, true)						-- Draw pred loc true/false	
			--}

		--{ Misc settings	
		Menu:addSubMenu("[Settings] Misc", "Misc")
			Menu.Misc:addParam("autoLevel", "Auto Level", SCRIPT_PARAM_LIST, 1, {"Disable", "R>E>W>Q"})
			Menu.Misc:addParam("usePots", "Use HP pots", SCRIPT_PARAM_ONOFF, true)										-- Use HP pots true/false
			Menu.Misc:addParam("HPHealth", "Min % for Health Pots", SCRIPT_PARAM_SLICE, 50, 0, 100, -1)					-- Min % for health pots
			Menu.Misc:addParam("escapeKey", "Escape Key", SCRIPT_PARAM_ONKEYDOWN, false, string.byte("T"))				-- Escape! true/false
		--}

		Menu:addParam("Author", "Author", SCRIPT_PARAM_INFO, author)
		Menu:addParam("Version", "Version", SCRIPT_PARAM_INFO, version)

		--{ permaShow
		Menu.Harass:permaShow("harassKey1")
		Menu.Harass:permaShow("harassKey2")
		Menu.Combo:permaShow("comboKey")
		--}
end