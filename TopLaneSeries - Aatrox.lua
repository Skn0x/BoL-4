--[[
	Top Lane Series - Aatrox by lel itz ok
	version 0.005
	20/06/2014
--]]
local version = 0.005

local author = "lel itz ok"

local scriptName = "TopLaneSeries"

if myHero.charName ~= "Aatrox" then return end

local AUTOUPDATE = true
local UPDATE_HOST = "raw.github.com"
local UPDATE_PATH = "/jelorono/BoL/master/TopLaneSeries%20-%20Aatrox.lua".."?rand="..math.random(1,10000)
local UPDATE_FILE_PATH = SCRIPT_PATH.."TopLaneSeries - Aatrox.lua"
local UPDATE_URL = "https://"..UPDATE_HOST..UPDATE_PATH

function AutoupdaterMsg(msg) print("<font color='#5F9EA0'><b>[".. scriptName .."] </font><font color='#cffffffff'> "..msg..".</font>") end
	if AUTOUPDATE then
		local ServerData = GetWebResult(UPDATE_HOST, "/jelorono/BoL/master/versions/TopLaneSeries%20-%20Aatrox.version")
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
local Aatrox = {
	AA = { range = 150 },
	Q = { range = 650, width = 280, speed = 1800, delay = 0.270 },
	E = { range = 1000, width = 80, speed = 1200, delay = 0.270 },
	R = { range = 300 },
	levelSequence = { 3,2,1,3,3,4,3,2,3,2,4,2,2,1,1,4,1,1 }	
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
    ts.name = "Aatrox"
    OW = SOW(VP)

	-- Load the menu
	Menu()

	-- Pretty little chat msg
	PrintChat("<font color='#5F9EA0'><b>[".. scriptName .."] </font><font color='#cffffffff'> Aatrox v".. version .."</b> loaded!</font>" )
end

function OnTick()
	-- If dead, we will return the function here so it doesn't loop through the rest
	if myHero.dead then return end	
	
	-- Call our pulse
	Pulse()

	if Menu.Misc.autoLevel == 2 then autoLevelSetSequence(Aatrox.levelSequence) end									-- Set auto level sequence if enabled 
	if Menu.Combo.comboKey then Combo()	end 																		-- Call Combo() function if key is down
	if Menu.Harass.harassKey1 or Menu.Harass.harassKey2 then Harass() end 											-- Call Harass() function if key is down
	if Menu.Farm.laneclearKey then FarmManager() end
	if Menu.Misc.escapeKey then Escape() end 																		-- Call Escape() function if key is down
end

function OnDraw()
	-- Don't draw incase we are dead
	if myHero.dead then return end	
	
	if Menu.Farm.laneclearKey then
		DrawLastHit()
	end
	
	-- If drawing is enabled, check what to draw.
	if Menu.Draw.drawAll then
		if Menu.Draw.drawAA then
			DrawCircle(myHero.x, myHero.y, myHero.z, Aatrox.AA["range"], ARGB(255, 255, 255, 255))
		end
		if Menu.Draw.drawQ and qReady then
			DrawCircle(myHero.x, myHero.y, myHero.z, Aatrox.Q["range"], ARGB(255, 255, 255, 255))
		end
		if Menu.Draw.drawE and eReady then
			DrawCircle(myHero.x, myHero.y, myHero.z, Aatrox.E["range"], ARGB(255, 255, 255, 255))
		end
		if Menu.Draw.drawR and rReady then
			DrawCircle(myHero.x, myHero.y, myHero.z, Aatrox.R["range"], ARGB(255, 255, 255, 255))
		end		
		if Menu.Draw.predLoc and target ~= nil then 
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
	local castPos, info = Prodiction.GetConeAOEPrediction(target, Aatrox.E["range"], Aatrox.E["speed"], Aatrox.E["delay"], Aatrox.E["width"])																
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
	local E = 0
	local R = 0
	local burst = 0
	
	if qReady then
		Q = getDmg("Q", target, myHero)
	end
	if eReady then
		E = getDmg("E", target, myHero)
	end
	if rReady then
		R = getDmg("R", target, myHero)
	end
	
	burst = Q + E + R
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

	enemyMinions = minionManager(MINION_ENEMY, Aatrox.E["range"], myHero, MINION_SORT_HEALTH_ASC)

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
	SpellManager(target, Menu.Combo.useQ, Menu.Combo.W.useW, Menu.Combo.useE, Menu.Combo.R.useR, Menu.Combo.useItems, Menu.Combo.useIgnite, false)
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

function FarmManager()
	for i, minion in pairs(enemyMinions.objects) do
		if ValidTarget(minion) and minion ~= nil then
			if Menu.Farm.useE and GetDistance(minion) <= Aatrox.E["range"] then 
				SpellManager(minion, false, false, true, false, false, false, false)			
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

	if Menu.Misc.smartW then
		if target == nil and myHero.health < (myHero.maxHealth * (95 / 100 )) then
			if isWActive() then
				CastSpell(_W)			
			end
		else
			WManager()
		end
	end
end	

-- Spell Manager
function SpellManager(target, Qs, Ws, Es, Rs, items, uIgnite, escape)
	if Qs then
		if target and qReady then
			if ValidTarget(target) then	
				if VIP_USER then
					local castPos, info = Prodiction.GetCircularAOEPrediction(target, Aatrox.Q["range"], Aatrox.Q["speed"], Aatrox.Q["delay"], Aatrox.Q["width"])																
					if castPos then
						if info.hitchance ~= 0 then
							CastSpell(_Q, castPos.x, castPos.z)
						end
					end
				else
					CastSpell(_Q, target.x, target.z)
				end
			end
		end
	end

	if Ws then
		if target and wReady then
			if ValidTarget(target) then
				WManager()
			end
		end
	end

	if Es then
		if Menu.Combo.comboMode then
			if target and eReady and (not qReady or GetDistance(target) < 600) then
				if ValidTarget(target) then
					if VIP_USER then
						local castPos, info = Prodiction.GetConeAOEPrediction(target, Aatrox.E["range"], Aatrox.E["speed"], Aatrox.E["delay"], Aatrox.E["width"])
						if castPos and info.hitchance ~= 0 then
							CastSpell(_E, castPos.x, castPos.z)
						end
					else
						CastSpell(_E, target.x, target.z)
					end
				end
			end
		else
			if target and eReady then
				if ValidTarget(target) then
					if VIP_USER then
						local castPos, info = Prodiction.GetConeAOEPrediction(target, Aatrox.E["range"], Aatrox.E["speed"], Aatrox.E["delay"], Aatrox.E["width"])
						if castPos and info.hitchance ~= 0 then
							CastSpell(_E, castPos.x, castPos.z)
						end
					else
						CastSpell(_E, target.x, target.z)
					end
				end
			end
		end
	end

	if Rs then
		if target and rReady and CountEnemyHeroInRange(Aatrox.R["range"]) >= Menu.Combo.R.minEnemy then
			if GetDistance(target) <= Aatrox.R["range"] and ValidTarget(target) then
				CastSpell(_R)
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
    	if myHero:CanUseSpell(_E) == READY then
	      CastSpell(_Q, mousePos.x, mousePos.z)
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

-- Is W active
function isWActive()
	-- If the damage is active, we return true
	if myHero:GetSpellData(_W).name == "aatroxw2" then
		return true
	-- If the heal is active, we return false
	else
		return false
	end
end

-- W Manager
function WManager()
	-- If our health is below the set %, we will activate the heal
	if myHero.health < myHero.maxHealth * (Menu.Combo.W.minW / 100) then
		if isWActive() then
			CastSpell(_W)
		end
	end
	
	-- If our heal is above the set %, we will activate the damage
	if myHero.health > myHero.maxHealth * (Menu.Combo.W.maxW / 100) then
		if not isWActive() then
			CastSpell(_W)
		end
	end	
end

--------------------------------------------------------------------------------------------------------------------------------------------
---- Menu function
--------------------------------------------------------------------------------------------------------------------------------------------

function Menu()
	-- Top level menu
	Menu = scriptConfig("[Top Lane Series] Aatrox", "Aatrox")
		--{ Target selector settings
		Menu:addSubMenu("[Settings] Target Selector", "TS")
			Menu.TS:addTS(ts)	
		--}	

		--{ Combo settings
		Menu:addSubMenu("[Settings] Combo mode", "Combo")
			Menu.Combo:addParam("comboMode", "Force Q>E", SCRIPT_PARAM_ONKEYTOGGLE, false, string.byte("A"))				-- Force Q>E true/false	
			Menu.Combo:addParam("useQ", "Use Q in combo mode", SCRIPT_PARAM_ONOFF, true)								-- Use Q true/false
			Menu.Combo:addSubMenu("[Settings] W logic]", "W")
				Menu.Combo.W:addParam("useW", "Use W in combo mode", SCRIPT_PARAM_ONOFF, true)							-- Use W true/false
				Menu.Combo.W:addParam("minW", "Min HP % for heal switch", SCRIPT_PARAM_SLICE, 20, 0, 100)				-- Min HP % value
				Menu.Combo.W:addParam("maxW", "Max HP % for dmg switch", SCRIPT_PARAM_SLICE, 80, 0, 100)				-- Max HP % value
			Menu.Combo:addSubMenu("[Settings] R Logic]", "R")
				Menu.Combo.R:addParam("useR", "Use R in combo mode", SCRIPT_PARAM_ONOFF, true)							-- Use R true/false
				Menu.Combo.R:addParam("minEnemy", "Min # of enemies for ultimate", SCRIPT_PARAM_SLICE, 1, 1, 5)			-- Min enemies value
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
			Menu.Farm:addParam("useE", "Use E in lane clear", SCRIPT_PARAM_ONOFF, true)									-- Use E true/false
			Menu.Farm:addParam("laneclearKey", "Lane clear key", SCRIPT_PARAM_ONKEYDOWN, false, string.byte("V"))		-- Lane clear true/false
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
			Menu.Draw:addParam("drawQ", "Draw Q range", SCRIPT_PARAM_ONOFF, true)										-- Draw Q true/false
			Menu.Draw:addParam("drawE", "Draw E range", SCRIPT_PARAM_ONOFF, true)										-- Draw E true/false		
			Menu.Draw:addParam("drawR", "Draw R range", SCRIPT_PARAM_ONOFF, true)										-- Draw R true/false
			Menu.Draw:addParam("predLoc", "Draw predicted location", SCRIPT_PARAM_ONOFF, true)						-- Draw pred loc true/false	
			--}

		--{ Misc settings	
		Menu:addSubMenu("[Settings] Misc", "Misc")
			Menu.Misc:addParam("autoLevel", "Auto Level", SCRIPT_PARAM_LIST, 1, {"Disable", "R>E>W>Q"})
			Menu.Misc:addParam("usePots", "Use HP pots", SCRIPT_PARAM_ONOFF, true)										-- Use HP pots true/false
			Menu.Misc:addParam("HPHealth", "Min % for Health Pots", SCRIPT_PARAM_SLICE, 50, 0, 100, -1)					-- Min % for health pots
			Menu.Misc:addParam("smartW", "Allow script to control W", SCRIPT_PARAM_ONKEYTOGGLE, true, string.byte("Z"))		-- Allow script to control W true/false
			Menu.Misc:addParam("escapeKey", "Escape Key", SCRIPT_PARAM_ONKEYDOWN, false, string.byte("T"))				-- Escape! true/false
		--}

		Menu:addParam("Author", "Author", SCRIPT_PARAM_INFO, author)
		Menu:addParam("Version", "Version", SCRIPT_PARAM_INFO, version)

		--{ Permashow
		Menu.Harass:permaShow("harassKey1")
		Menu.Harass:permaShow("harassKey2")
		Menu.Combo:permaShow("comboKey")
		Menu.Combo.R:permaShow("minEnemy")
		Menu.Misc:permaShow("smartW")
		--}
end