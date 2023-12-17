local sexyrooms = SRMod

local HUDoffset = 0 -- set this to your preferred HUD offset level (0-10)
local healthlimit = -1 -- imposes a limit to health
-- multiples of 6 look better, 18 is nice

local redheartlimit = -1 -- imposes a limit to red heart containers
-- that can be lower than the total limit set above, cant be higher

local overlimitcontainersbecome = 0 --if players red hearts go over red heart cap above
--this sets what to turn them into (0 = nothing, 1 = soul heart, 2 = black heart, 3 = bone heart)

local displayheartrows = -1 --defines how many rows of health will be visible (if greater than 1)





local extrahearts = {}
-- 0 nothing, 1 empty, 2 half red, 3 full red
-- 4 half soul, 5 full soul, 6 half black, 7 full black
-- 8 empty bone heart, 9 half full bone heart, 10 full bone heart
local halfspacecount = 0
local halfredcount = 0
local halfsoulcount = 0
local blackcount = 0
local bonecount = 0
local rottenhearts = 0
local goldhearts = {}
local oldheartcount = 0
local goldheartbuffer = 0
local goldpushedbybone = false
local eternalheart = -1
--counts used to emulate gethearts() getmaxhearts() getsoulhearts() for the extra hearts
local effectivemaxhealth = 0
--workaround for blue babies special unfillable bone hearts
local takendamage = false;
local defaultheartlimit = 12
local maxrealheartoffset = 1
--how many heart slots at the end of the health bar are used to check for Hp Ups
local maxrealhearts = defaultheartlimit-maxrealheartoffset
--how many hearts there can be in 'real' health, any more go into mods extra count

local crowheart = 107; --gettrinketidbyname seems to not work sometimes in repentance for some reason

local negativeheart = 0
keeperscoinscount = 0

local unknowncurse = false
local rainbowpoop = false

local forgottenmode = 0
local oldforgottenmode = 0

local hudOn = true

local sacspikes = false

local modenabled = true -- allow things to disable the mod

--additional heart list for the forgottens sub-character
local extraheartsBONE = {}
local extraheartsSOUL = {}

--stuff for other mods to use
NoHealthCapModEnabled = true --for mods to check if this mod is being used, dont change it
NoHealthCapEnableItemList = false --set to true to force health cap to be set by items
NoHealthCapAddRequiredItems = {} --list of health cap changing items
NoHealthCapSetHealthLimits = {} --list of the health caps set by each item

NoHealthCapRedHearts = 0 --total number of half red hearts
NoHealthCapRedMax = 0 --total number of half heart containers
NoHealthCapSoulHearts = 0 --total number of half soul hearts
NoHealthCapBoneHearts = 0 --total number of bone hearts
NoHealthCapRottenHearts = 0 --total number of rotten hearts
NoHealthCapBlackHearts = 0 --number of half black hearts in extra
NoHealthCapModHealthLimit = 0 --current health cap
NoHealthCapModHeartContainerLimit = 0 --current red heart container cap

--if a mod wants to deal damage to player and have it ignore the extra hearts for some reason
NoHealthCapModIgnoreDamage = false

--if a mod wants to make the extra hearts get put in order
NoHealthCapModSortHearts = -1
-- set to -1 to disable
-- 0 for containers > bone > soul > black
-- 1 for containers > bone > black > soul
-- 2 for containers > soul > bone > black
-- 3 for containers > soul > black > bone
-- 4 for containers > black > bone > soul
-- 5 for containers > black > soul > bone


--to add an item than alters the health cap use code like this in PLAYER_INIT
--NoHealthCapEnableItemList = true
--table.insert(NoHealthCapAddRequiredItems, ITEMID)
--table.insert(NoHealthCapSetHealthLimits, X)


--[[ some public functions you might want to use are:
organisehearts() to iterate through the extra hearts and default hearts and make
sure they are in a valid order, sort them if they are not in order

updateheartcounts() to check through the extra hearts data and recount all heart types
forces the values above to be updated

addredhealth(int amount) to add red health to available spaces in the extra hearts

addsoulhealth(int amount) to add soul hearts to the extra hearts

loseredhealth(int amount) to remove red health from extra hearts and 
losesoulhealth(int amount) to remove soul hearts from extra hearts

both return the leftover amount e.g.
local temp = loseredhealth(amount)
if temp > 0 then
	player:AddHearts(-temp)
end
]]

debug_text = ""

function sexyrooms:PostPlayerInit(player)
	NoHealthCapModSortHearts = -1
	--check for the forgotten
	oldforgottenmode = 0
	forgottencheck(player)
	--reset or load extra hearts data
	loadhealthdata()
	if Game():GetFrameCount() < 5 then
		extrahearts = {}
		table.insert(extrahearts, 0);
		extraheartsBONE = {}
		table.insert(extraheartsBONE, 0);
		extraheartsSOUL = {}
		table.insert(extraheartsSOUL, 0);
		goldhearts = {}
		eternalheart = -1
		rottenhearts = 0
		savehealthdata()
		heartoffsetcooldown = 0
	end
	loadhealthdata()
	forgottenhealthbarupdate(player)
	updateheartcounts()
	oldheartcount = #extrahearts-1
end

local lastsaved = -99
function savehealthdata()
	if math.abs(Game():GetFrameCount()-lastsaved) > 9 then
        HUDoffset = math.floor(HUDoffset)
        healthlimit = math.floor(healthlimit)
        local temprotten = rottenhearts + 0
		local str = ""
		if HUDoffset > 9 then
			str = str .. "10"
		elseif HUDoffset > -1 then
			str = str .. "0"
			str = str .. HUDoffset
		else
			str = str .. "00"
		end
        if healthlimit > 99 then
			str = str .. "99"
		elseif healthlimit > 9 then
			str = str .. healthlimit
		elseif healthlimit > -1 then
			str = str .. "0"
			str = str .. healthlimit
		else
			str = str .. healthlimit
		end
        if redheartlimit > 99 then
			str = str .. "99"
		elseif redheartlimit > 9 then
			str = str .. redheartlimit
		elseif redheartlimit > -1 then
			str = str .. "0"
			str = str .. redheartlimit
		else
			str = str .. redheartlimit
		end
		if displayheartrows > 50 then
			str = str .. "50"
		elseif displayheartrows > 9 then
			str = str .. displayheartrows
		elseif displayheartrows > -1 then
			str = str .. "0"
			str = str .. displayheartrows
		else
			str = str .. displayheartrows
		end
        if overlimitcontainersbecome == nil then
            overlimitcontainersbecome = 0
        end
		str = str .. overlimitcontainersbecome
		if forgottenmode > 0 then
			for i = 1, #extraheartsBONE, 1 do
				local tempheartID = extraheartsBONE[i]
				if temprotten > 0 and tempheartID == 10 then
					tempheartID = tempheartID + 40
					temprotten = temprotten - 1
				end
				for j = 1, #goldhearts, 1 do
					if goldhearts[j] == i then
						tempheartID = tempheartID + 10
					end
				end
				if eternalheart == i then
					tempheartID = tempheartID + 20
				end
				if tempheartID <= 9 then
					str = str .. "0"
				end
				str = str .. tempheartID
			end
			str = str .. "##"
			for i = 1, #extraheartsSOUL, 1 do
				local tempheartID = extraheartsSOUL[i]
				for j = 1, #goldhearts, 1 do
					if goldhearts[j] == i then
						tempheartID = tempheartID + 10
					end
				end
				if eternalheart == i then
					tempheartID = tempheartID + 20
				end
				if tempheartID <= 9 then
					str = str .. "0"
				end
				str = str .. tempheartID
			end
		else
			for i = 1, #extrahearts, 1 do
				local tempheartID = extrahearts[i]
				if temprotten > 0 and (tempheartID == 3 or tempheartID == 10) then
					tempheartID = tempheartID + 40
					temprotten = temprotten - 1
				end
				for j = 1, #goldhearts, 1 do
					if goldhearts[j] == i then
						tempheartID = tempheartID + 10
					end
				end
				if eternalheart == i then
					tempheartID = tempheartID + 20
				end
				if tempheartID <= 9 then
					str = str .. "0"
				end
				str = str .. tempheartID
			end
		end
		Isaac.SaveModData(sexyrooms, str)
		lastsaved = Game():GetFrameCount()
	end
end
function loadhealthdata()
	extrahearts = {}
	extraheartsBONE = {}
	extraheartsSOUL = {}
	goldhearts = {}
	eternalheart = -1
	rottenhearts = 0
	local str = Isaac.LoadModData(sexyrooms)
	local soulmode = false
	for i = 1, string.len(str), 1 do
		if i == 1 then
			HUDoffset = tonumber(string.sub(str, 1, 2))
		elseif i == 3 then 
			healthlimit = tonumber(string.sub(str, 3, 4))
		elseif i == 5 then
			redheartlimit = tonumber(string.sub(str, 5, 6))
		elseif i == 7 then
			displayheartrows = tonumber(string.sub(str, 7, 8))
		elseif i == 9 then
			overlimitcontainersbecome = tonumber(string.sub(str, 9, 9))
            if overlimitcontainersbecome == nil then
                overlimitcontainersbecome = 0
            end
		elseif i > 9 and i % 2 == 0 then
			if forgottenmode == 0 then
				local substringbit = string.sub(str, i, i+1)
				if substringbit ~= "##" then
					local tempnumber = tonumber(substringbit)
                    if tempnumber == nil then
                        break
                    end
					if tempnumber > 40 then--rotten
						tempnumber = tempnumber - 40
						rottenhearts = rottenhearts + 1
					end
					if tempnumber > 20 then--eternal
						tempnumber = tempnumber - 20
						eternalheart = 2
					end
					if tempnumber > 10 then--gold
						tempnumber = tempnumber - 10
						table.insert(goldhearts, #goldhearts+2)
					end
					table.insert(extrahearts, tempnumber);
				end
			else
				if string.sub(str, i, i+1) == "##" then
					soulmode = true
				else
					local tempnumber = tonumber(string.sub(str, i, i+1))
                    if tempnumber == nil then
                        break
                    end
					if tempnumber > 40 then--rotten
						tempnumber = tempnumber - 40
						rottenhearts = rottenhearts + 1
					end
					if tempnumber > 20 then--eternal
						tempnumber = tempnumber - 20
						eternalheart = 2
					end
					if tempnumber > 10 then--gold
						tempnumber = tempnumber - 10
						table.insert(goldhearts, #goldhearts+2)
					end
					if soulmode == false then
						table.insert(extraheartsBONE, tempnumber);
					else
						table.insert(extraheartsSOUL, tempnumber);
					end
				end
			end
		end
	end
	oldheartcount = #extrahearts-1
	updateheartcounts()
end

function forgottencheck(player)
	forgottenmode = 0
	defaultheartlimit = 12
	if player:GetName() == "The Forgotten" then
		forgottenmode = 1
		defaultheartlimit = 6
	elseif player:GetName() == "The Soul" then
		forgottenmode = 2
		defaultheartlimit = 6
	end
	maxrealhearts = defaultheartlimit-maxrealheartoffset
end
function forgottenhealthbarupdate(player)
	if player:GetName() == "The Forgotten" then
		if forgottenmode ~= oldforgottenmode then
			if oldforgottenmode > 0 then
				extraheartsSOUL = extrahearts
			end
			extrahearts = extraheartsBONE
			updateheartcounts()
		end
	elseif player:GetName() == "The Soul" then
		if forgottenmode ~= oldforgottenmode then
			if oldforgottenmode > 0 then
				extraheartsBONE = extrahearts
			end
			extrahearts = extraheartsSOUL
			updateheartcounts()
		end
	end
	oldforgottenmode = forgottenmode
end

function sexyrooms:roomupdate()
	--workaround for keeper health
	keeperscoinscount = Isaac.GetPlayer(0):GetNumCoins()
	if PickupCapCoinNum then
		keeperscoinscount = PickupCapCoinNum
	end
end

function sexyrooms:getmaxeffectivehp(player)
    effectivemaxhealth = player:GetEffectiveMaxHearts()
    if player:GetName() == "???" then
        effectivemaxhealth = player:GetBoneHearts()*2
    end
    if REPENTANCE and (player:GetPlayerType() == 24 or player:GetPlayerType() == 36) then
        effectivemaxhealth = player:GetBoneHearts()*2
    end
end

local heartoffsetcooldown = 0
local savehealthdatanow = false
function sexyrooms:tick()
	savehealthdatanow = false
	--if mod config menu use its hud offset setting
	if ModConfigMenu then
		HUDoffset = ModConfigMenu.Config["General"].HudOffset
	end

	--toggle extra hud on key press
	if Game():GetSeeds():HasSeedEffect(SeedEffect.SEED_NO_HUD) then
		hudOn = false
	else
		hudOn = true
	end
	--hide extra hud if player has curse of unknown
	if Game():GetLevel():GetCurseName() == "Curse of the Unknown" then
		unknowncurse = true
	else
		unknowncurse = false
	end
	
	
	local player = Isaac.GetPlayer(0)
	--prevent settings going out of bounds
	if healthlimit < -2 then
		healthlimit = -2
	end
	if healthlimit > 99 then
		healthlimit = 99
	end
	if redheartlimit < -1 then
		redheartlimit = -1
	end
	if redheartlimit > 99 then
		redheartlimit = 99
	end
	if healthlimit > -1 and redheartlimit > -1 and redheartlimit > healthlimit then
		redheartlimit = healthlimit
	end
	if displayheartrows < -1 then
		displayheartrows = -1
	end
	if displayheartrows > 50 then
		displayheartrows = 50
	end
	if displayheartrows == 0 then
		displayheartrows = 2
	end
	if displayheartrows == 1 then
		displayheartrows = -1
	end
	
	
	--check for the forgotten player swap
	forgottencheck(player)
	
	--disable mod functionality if items have been set as a requirement and player doesnt have any of them
	if #NoHealthCapAddRequiredItems > 0 and NoHealthCapEnableItemList == true then
		modenabled = false
		healthlimit = defaultheartlimit
		redheartlimit = -1
		--apply largest cap higher than default
		for i = 1, #NoHealthCapAddRequiredItems, 1 do
			if player:HasCollectible(NoHealthCapAddRequiredItems[i]) then
				modenabled = true
				if NoHealthCapSetHealthLimits[i] > healthlimit and NoHealthCapSetHealthLimits[i] > defaultheartlimit then
					healthlimit = NoHealthCapSetHealthLimits[i]
				end
			end
		end
		--apply caps lower than default
		for i = 1, #NoHealthCapAddRequiredItems, 1 do
			if player:HasCollectible(NoHealthCapAddRequiredItems[i]) then
				modenabled = true
				if NoHealthCapSetHealthLimits[i] < healthlimit and NoHealthCapSetHealthLimits[i] < defaultheartlimit then
					healthlimit = NoHealthCapSetHealthLimits[i]
				end
			end
			--check for and remove duplicates
			for j = i+1, #NoHealthCapAddRequiredItems, 1 do
				if NoHealthCapAddRequiredItems[j] == NoHealthCapAddRequiredItems[i] then
					table.remove(NoHealthCapAddRequiredItems, j);
					table.remove(NoHealthCapSetHealthLimits, j);
				end
			end
		end
	end
	
	if NoHealthCapEnableItemList == false then
		modenabled = true
	end
	
	--dont break caasi or neg heart
	negativeheart = Isaac.GetItemIdByName("Negative Heart")
	if negativeheart ~= -1 then 
		local iscaasi = false
		if player:GetName() == "Caasi" then
			iscaasi = true
		end
		if (iscaasi or player:HasCollectible(negativeheart)) and iscaasi ~= player:HasCollectible(negativeheart) then
			modenabled = false
		end
	end
	
	
	NoHealthCapModHealthLimit = healthlimit
	NoHealthCapModHeartContainerLimit = redheartlimit
	if healthlimit == -2 then modenabled = false end --allow the mod to be completely disabled
	if modenabled then
		--run extra hearts when cap is larger than default
		if healthlimit > defaultheartlimit or healthlimit == -1 then
			--load extra hearts from save
			if #extrahearts == 0 then
				oldforgottenmode = 0
				forgottencheck(player)
				loadhealthdata()
				if #extrahearts == 0 then
					table.insert(extrahearts, 0);
				end
				if #extraheartsBONE == 0 then
					table.insert(extraheartsBONE, 0);
				end
				if #extraheartsSOUL == 0 then
					table.insert(extraheartsSOUL, 0);
				end
				forgottenhealthbarupdate(player)
				updateheartcounts()
				oldheartcount = #extrahearts-1
				savehealthdatanow = true
			end
			forgottenhealthbarupdate(player)
			
			--workaround for sacrifice spikes
			if sacspikes then
				player:AddHearts(2)
				local remaining = losesoulhealth(2)
				if remaining > 0 then
					loseredhealth(remaining)
				end
				if remaining > 0 then
					player:AddHearts(-remaining)
				end
				savehealthdatanow = true
			end
			sacspikes = false			
			
			--get players non-soul heart count
			sexyrooms:getmaxeffectivehp(player)
			
			--if player got HP up with gold hearts move them without breaking them
			if goldheartbuffer > 0 then
				if goldpushedbybone == false then
					player:AddGoldenHearts(1)
				end
				local entities = Isaac.FindByType(5, 20, -1)
				for ent = 1, #entities do
					local entity = entities[ent]
					if entity.FrameCount == 0 then
						entity:Remove()
					end
				end
				player:AddGoldenHearts(goldheartbuffer)
				goldpushedbybone = false
				savehealthdatanow = true
			end
			goldheartbuffer = 0
			
			
	
			--if using the sorted hearts mod
			if NoHealthCapModSortHearts > -1 and #extrahearts > 1 then
				local checksoulcount = 0
				local checkblackcount = 0
				for i = #extrahearts, 2, -1 do
					if extrahearts[i] == 4 or extrahearts[i] == 5 then
						checksoulcount = checksoulcount + 1
					end
					if extrahearts[i] == 6 or extrahearts[i] == 7 then
						checkblackcount = checkblackcount + 1
					end
					for j = #extrahearts, 3, -1 do
						--sort hearts in extra health bars
						local swaphearts = false
						--push black hearts forwards
						if extrahearts[j] == 6 or extrahearts[j] == 7 then
							if extrahearts[j-1] > 7 then
								if NoHealthCapModSortHearts < 3 then
									swaphearts = true
								end
							elseif extrahearts[j-1] < 6 then
								if NoHealthCapModSortHearts == 0 or NoHealthCapModSortHearts == 2 or NoHealthCapModSortHearts == 3 then
									swaphearts = true
								end
							end
						end
						--push soul hearts forwards
						if extrahearts[j] == 4 or extrahearts[j] == 5 then
							if extrahearts[j-1] > 7 then
								if NoHealthCapModSortHearts < 2 or NoHealthCapModSortHearts == 4 then
									swaphearts = true
								end
							else
								if NoHealthCapModSortHearts == 1 or NoHealthCapModSortHearts > 3 then
									swaphearts = true
								end
							end
						end
						--push bone hearts forwards
						if extrahearts[j] > 7 then
							if extrahearts[j-1] < 6 then
								if NoHealthCapModSortHearts == 2 or NoHealthCapModSortHearts == 3 or NoHealthCapModSortHearts == 5 then
									swaphearts = true
								end
							elseif extrahearts[j-1] < 8 then
								if NoHealthCapModSortHearts > 2 then
									swaphearts = true
								end
							end
						end
						--swap current heart with the next one
						if swaphearts then
							local temp = extrahearts[j]
							extrahearts[j] = extrahearts[j-1]
							extrahearts[j-1] = temp
							savehealthdatanow = true
						end
					end
				end
				--sort with actual health bars
				--swap bone heart in extra with soul/black heart in actual
				if bonecount > 0 and player:GetSoulHearts() > 0 and extrahearts[#extrahearts] > 7 then
					if NoHealthCapModSortHearts < 2 then
						movesoulblacktoextra(false, true)
						savehealthdatanow = true
					elseif NoHealthCapModSortHearts == 2 and SortedHeartsBlackHeartCount > 0 then
						movesoulblacktoextra(false, true)
						savehealthdatanow = true
					elseif NoHealthCapModSortHearts == 4 and SortedHeartsSoulHeartCount > 0 then
						movesoulblacktoextra(false, true)
						savehealthdatanow = true
					end
				end
				--swap bone heart in actual with soul/black heart in extra
				if player:GetBoneHearts() > 0 and halfsoulcount > 0 and extrahearts[#extrahearts] < 8 then
					if NoHealthCapModSortHearts == 3 or NoHealthCapModSortHearts == 5 then
						movebonestoextra(false)
						savehealthdatanow = true
					elseif NoHealthCapModSortHearts == 2 and checksoulcount > 0 then
						movebonestoextra(false)
						savehealthdatanow = true
					elseif NoHealthCapModSortHearts == 4 and checkblackcount > 0 then
						movebonestoextra(false)
						savehealthdatanow = true
					end
				end
				--swap soul/black heart in extra with soul/black heart in actual
				if SortedHeartsSoulHeartCount ~= nil and (NoHealthCapModSortHearts == 1 or NoHealthCapModSortHearts == 4 or NoHealthCapModSortHearts == 5) then
					if SortedHeartsSoulHeartCount > 0 and checkblackcount > 0 and extrahearts[#extrahearts] > 5 and extrahearts[#extrahearts] < 8  then
						player:AddSoulHearts(-2)
						table.insert(extrahearts, 2, 5)
						halfsoulcount = halfsoulcount + 2
						if extrahearts[#extrahearts] == 6 then
							player:AddBlackHearts(1)
							halfsoulcount = halfsoulcount - 1
							blackcount = blackcount - 1
						elseif extrahearts[#extrahearts] == 7 then
							player:AddBlackHearts(2)
							halfsoulcount = halfsoulcount - 2
							blackcount = blackcount - 2
						end
						extrahearts[#extrahearts] = 0
						table.remove(extrahearts, #extrahearts)
						savehealthdatanow = true
					end				
				end
				if SortedHeartsBlackHeartCount ~= nil and (NoHealthCapModSortHearts == 0 or NoHealthCapModSortHearts == 2 or NoHealthCapModSortHearts == 3) then
					if SortedHeartsBlackHeartCount > 0 and checksoulcount > 0 and extrahearts[#extrahearts] > 3 and extrahearts[#extrahearts] < 6 then
						player:RemoveBlackHeart(player:GetSoulHearts()-1)
						player:AddSoulHearts(-2)
						table.insert(extrahearts, 2, 7)
						halfsoulcount = halfsoulcount + 2
						blackcount = blackcount + 2
						if extrahearts[#extrahearts] == 4 then
							player:AddSoulHearts(1)
							halfsoulcount = halfsoulcount - 1
						elseif extrahearts[#extrahearts] == 5 then
							player:AddSoulHearts(2)
							halfsoulcount = halfsoulcount - 2
						end
						extrahearts[#extrahearts] = 0
						table.remove(extrahearts, #extrahearts)
						savehealthdatanow = true
					end
				end
			end
			
			
			--has player reached last natural heart
			if effectivemaxhealth + player:GetSoulHearts() > maxrealhearts*2 then
				--get boneheartindex
				local bonecheck = effectivemaxhealth + player:GetSoulHearts() - player:GetMaxHearts()
				if bonecheck % 2 == 1 then
					bonecheck = bonecheck + 1
				end
				bonecheck = bonecheck/2
				bonecheck = bonecheck - 1
				--check if soul/bone hearts were picked up or pushed by hp up
				local causedbyhpup = false
				local heartcontainercount = NoHealthCapRedMax - halfspacecount
				if heartcontainercount ~= player:GetMaxHearts() then
					causedbyhpup = true
				end
				if heartoffsetcooldown > Game():GetFrameCount() - 15 then
					causedbyhpup = true
				end
				--record gold heart amount
				if player:GetGoldenHearts() > 0 then
					goldheartbuffer = player:GetGoldenHearts()
					player:AddGoldenHearts(-goldheartbuffer)
					savehealthdatanow = true
					if player:IsBoneHeart(bonecheck) and player:GetSoulHearts() == 0 then
						goldpushedbybone = true
					end
				end
				--if heart over limit check each heart
				for d = 1, maxrealheartoffset do
					--move bone hearts extra hearts
					if player:IsBoneHeart(bonecheck) then
						movebonestoextra(causedbyhpup)
						savehealthdatanow = true
					--move heart containers to extra hearts
					elseif effectivemaxhealth > maxrealhearts*2 then
						moveredcontainertoextra()
						savehealthdatanow = true
					--move soul/black hearts to extra hearts
					else
						movesoulblacktoextra(causedbyhpup, false)
						savehealthdatanow = true
					end
					sexyrooms:getmaxeffectivehp(player)
					if effectivemaxhealth + player:GetSoulHearts() <= maxrealhearts*2 then
						d = 9
						break
					end
				end
			end
			
			--get players non-soul heart count
			sexyrooms:getmaxeffectivehp(player)
			
			--check for forgotten picking up 6th soul heart or soul picking up 6th bone heart
			if forgottenmode == 1 and player:GetSubPlayer() ~= nil and player:GetSubPlayer():GetSoulHearts() ~= nil then
				local subcharacterexcess = player:GetSubPlayer():GetSoulHearts()
				local subheartcap = 12 - (maxrealheartoffset*2)
				if subcharacterexcess > subheartcap then
					local amount = subcharacterexcess-subheartcap
					local blackcheckindex = player:GetSubPlayer():GetSoulHearts()
					if blackcheckindex > 0 and blackcheckindex % 2 == 0 then
						blackcheckindex = blackcheckindex - 1
					end
					local blackcheck = player:GetSubPlayer():IsBlackHeart(blackcheckindex)
					if amount >= 2 then
						if blackcheck then
							table.insert(extraheartsSOUL, 7)
						else
							table.insert(extraheartsSOUL, 5)
						end
						player:GetSubPlayer():AddSoulHearts(-2)
						savehealthdatanow = true
					elseif amount == 1 then
						if blackcheck then
							table.insert(extraheartsSOUL, 6)
						else
							table.insert(extraheartsSOUL, 4)
						end
						player:GetSubPlayer():AddSoulHearts(-1)
						savehealthdatanow = true
					end
				end
			elseif forgottenmode == 2 and player:GetSubPlayer() ~= nil and player:GetSubPlayer():GetBoneHearts() ~= nil then
				local subcharacterexcess = player:GetSubPlayer():GetBoneHearts()
				local subheartcap = 6 - maxrealheartoffset
				if subcharacterexcess > subheartcap then
					local amount = player:GetSubPlayer():GetEffectiveMaxHearts()-player:GetSubPlayer():GetHearts()
					if amount == 0 then
						table.insert(extraheartsBONE, 2, 10)
					elseif amount == 1 then
						table.insert(extraheartsBONE, 2, 9)
					else
						table.insert(extraheartsBONE, 2, 8)
					end
					player:GetSubPlayer():AddBoneHearts(-1)
					savehealthdatanow = true
				end
				--let Soul pick up red hearts if Forgotten has space
				local bonespace = 0
				for i = 1, #extraheartsBONE, 1 do
					if extraheartsBONE[i] == 8 then
						bonespace = bonespace + 2
					elseif extraheartsBONE[i] == 9 then
						bonespace = bonespace + 1
					end
				end
				if bonespace > 0 then
					local entities = Isaac.FindByType(5, 10, -1)
					local pickupradius = 25
					for ent = 1, #entities do
						local entity = entities[ent]
						if entity:IsDead() == false and entity.Type == 5 and entity.Variant == 10 and entity.SubType < 20 then
							if entity.Position.X < player.Position.X + pickupradius and entity.Position.X > player.Position.X - pickupradius and entity.Position.Y < player.Position.Y + pickupradius and entity.Position.Y > player.Position.Y - pickupradius then
								if entity.SubType == 1 or entity.SubType == 9 then--full red
									local amount = 2
									for i = #extraheartsBONE, 1, -1 do
										if amount > 0 then
											if extraheartsBONE[i] == 9 then
												amount = amount - 1
												extraheartsBONE[i] = 10
											elseif extraheartsBONE[i] == 8 then
												if amount > 1 then
													amount = amount - 2
													extraheartsBONE[i] = 10
												else
													amount = amount - 1
													extraheartsBONE[i] = 9
												end
											end
										end
									end
									SFXManager():Play(185, 1.25, 0, false, 1.0)
									entity:Remove()
									redhearttimeout = 0
									savehealthdatanow = true
								elseif entity.SubType == 2 or entity.SubType == 10 then--half red
									for i = #extraheartsBONE, 1, -1 do
										if extraheartsBONE[i] == 9 then
											extraheartsBONE[i] = 10
											break
										elseif extraheartsBONE[i] == 8 then
											extraheartsBONE[i] = 9
											break
										end
									end
									SFXManager():Play(185, 1.25, 0, false, 1.0)
									entity:Remove()
									redhearttimeout = 0
									savehealthdatanow = true
								elseif entity.SubType == 5 then--double red
									local amount = 4
									for i = #extraheartsBONE, 1, -1 do
										if amount > 0 then
											if extraheartsBONE[i] == 9 then
												amount = amount - 1
												extraheartsBONE[i] = 10
											elseif extraheartsBONE[i] == 8 then
												if amount > 1 then
													amount = amount - 2
													extraheartsBONE[i] = 10
												else
													amount = amount - 1
													extraheartsBONE[i] = 9
												end
											end
										end
									end
									SFXManager():Play(185, 1.25, 0, false, 1.0)
									entity:Remove()
									redhearttimeout = 0
									savehealthdatanow = true
								end
							end
						end
					end
				end
			end
			
			--get players non-soul heart count
			sexyrooms:getmaxeffectivehp(player)
			
			--are there soul/black hearts in regular health and red containers in extras?
			if player:GetMaxHearts() < maxrealhearts*2 and (player:GetSoulHearts() > 0 or player:GetBoneHearts() > 0) and halfspacecount > 0 then
				swapsoulforred()
				savehealthdatanow = true
			end
			
			sexyrooms:getmaxeffectivehp(player)
			--make sure health is in order and halves are stacked
			if bonecount > 0 or halfspacecount > 0 or halfsoulcount > 0 then
				organisehearts()
			end
			
			sexyrooms:getmaxeffectivehp(player)
			--dont let 'real' health go down while there's still hearts in extra health
			local temptotalhearts = effectivemaxhealth+player:GetSoulHearts()
			if temptotalhearts % 2 == 1 then
				temptotalhearts = temptotalhearts + 1
			end
			if temptotalhearts < maxrealhearts*2 and #extrahearts > 1 then
				--rotten hearts
				local addrottenheart = false
				if rottenhearts > 0 then
					local nonrottenreds = math.ceil((halfredcount - rottenhearts*2)/2)
					if nonrottenreds == 0 and (extrahearts[#extrahearts] == 2 or extrahearts[#extrahearts] == 3 or extrahearts[#extrahearts] == 9 or extrahearts[#extrahearts] == 10) then
						addrottenheart = true
					end
				end
				--move hearts
				if extrahearts[#extrahearts] == 1 then
					player:AddMaxHearts(2, false)
					table.remove(extrahearts, #extrahearts);
					halfspacecount = halfspacecount - 2
				elseif extrahearts[#extrahearts] == 2 then
					player:AddMaxHearts(2, false)
					player:AddHearts(1)
					halfredcount = halfredcount - 1
					halfspacecount = halfspacecount - 2
					table.remove(extrahearts, #extrahearts);
				elseif extrahearts[#extrahearts] == 3 then
					player:AddMaxHearts(2, false)
					player:AddHearts(2)
					halfredcount = halfredcount - 2
					halfspacecount = halfspacecount - 2
					table.remove(extrahearts, #extrahearts);
				elseif extrahearts[#extrahearts] == 4 then
					player:AddSoulHearts(1)
					halfsoulcount = halfsoulcount - 1
					table.remove(extrahearts, #extrahearts);
				elseif extrahearts[#extrahearts] == 5 then
					player:AddSoulHearts(2)
					halfsoulcount = halfsoulcount - 2
					table.remove(extrahearts, #extrahearts);
				elseif extrahearts[#extrahearts] == 6 then
					player:AddBlackHearts(1)
					halfsoulcount = halfsoulcount - 1
					blackcount = blackcount - 1
					table.remove(extrahearts, #extrahearts);
				elseif extrahearts[#extrahearts] == 7 then
					player:AddBlackHearts(2)
					halfsoulcount = halfsoulcount - 2
					blackcount = blackcount - 2
					table.remove(extrahearts, #extrahearts);
				elseif extrahearts[#extrahearts] == 8 then
					player:AddBoneHearts(1)
					bonecount = bonecount - 1
					table.remove(extrahearts, #extrahearts);
				elseif extrahearts[#extrahearts] == 9 then
					player:AddBoneHearts(1)
					player:AddHearts(1)
					halfredcount = halfredcount - 1
					bonecount = bonecount - 1
					table.remove(extrahearts, #extrahearts);
				elseif extrahearts[#extrahearts] == 10 then
					player:AddBoneHearts(1)
					player:AddHearts(2)
					halfredcount = halfredcount - 2
					bonecount = bonecount - 1
					table.remove(extrahearts, #extrahearts);
				end
				if addrottenheart then
					rottenhearts = rottenhearts - 1
					player:AddRottenHearts(2)
				end
				savehealthdatanow = true
			end
			
			sexyrooms:getmaxeffectivehp(player)
			--are there soul/black hearts in regular health and red containers in extras? (double check)
			if player:GetMaxHearts() < maxrealhearts*2 and (player:GetSoulHearts() > 0 or player:GetBoneHearts() > 0) and halfspacecount > 0 then
				swapsoulforred()
				savehealthdatanow = true
			end
			
			sexyrooms:getmaxeffectivehp(player)
			--move red health from extras to player if there is room
			while player:GetHearts() < effectivemaxhealth and #extrahearts > 1 and halfredcount > 0 do
				for i = 1, #extrahearts, 1 do
					if extrahearts[i] == 2 or extrahearts[i] == 3 or extrahearts[i] == 9 or extrahearts[i] == 10 then
						extrahearts[i] = extrahearts[i] - 1
						halfredcount = halfredcount - 1
						player:AddHearts(1)
					end
				end
				--rotten hearts
				if rottenhearts > 0 and rottenhearts > math.ceil(halfredcount/2) then
					rottenhearts = rottenhearts - 1
					player:AddRottenHearts(2)
				end
				savehealthdatanow = true
			end
			--move rotten hearts
			if REPENTANCE and player:GetRottenHearts() > 0 and rottenhearts < math.ceil(halfredcount/2) then
				player:AddRottenHearts(-2)
				player:AddHearts(2)
				rottenhearts = rottenhearts + 1
			end
			
			sexyrooms:getmaxeffectivehp(player)
			--if theres a half heart in 'real' health and a half heart in extra health of the same type merge them
			if player:GetSoulHearts() % 2 == 1 and halfsoulcount > 0 then
				if player:IsBlackHeart(player:GetSoulHearts()) then
					for i = 1, #extrahearts, 1 do
						if extrahearts[i] == 6 or extrahearts[i] == 4 then
							if extrahearts[i] == 6 then
								blackcount = blackcount - 1
							end
							extrahearts[i] = 0
							halfsoulcount = halfsoulcount - 1
							player:AddBlackHearts(1)
							break
						end
						if extrahearts[i] == 7 then
							extrahearts[i] = 6
							halfsoulcount = halfsoulcount - 1
							blackcount = blackcount - 1
							player:AddBlackHearts(1)
							break
						end
						if extrahearts[i] == 5 then
							extrahearts[i] = 4
							halfsoulcount = halfsoulcount - 1
							player:AddBlackHearts(1)
							break
						end
					end
				else
					for i = 1, #extrahearts, 1 do
						if extrahearts[i] == 4 then
							extrahearts[i] = 0
							halfsoulcount = halfsoulcount - 1
							player:AddSoulHearts(1)
							break
						end
						if extrahearts[i] == 5 then
							extrahearts[i] = 4
							halfsoulcount = halfsoulcount - 1
							player:AddSoulHearts(1)
							break
						end
					end
				end
				savehealthdatanow = true
			end
			if player:GetHearts() % 2 == 1 and halfredcount > 0 then
				for i = 1, #extrahearts, 1 do
					if extrahearts[i] == 2 then
						extrahearts[i] = 1
						halfredcount = halfredcount - 1
						player:AddHearts(1)
						break
					end
					if extrahearts[i] == 3 then
						extrahearts[i] = 2
						halfredcount = halfredcount - 1
						player:AddHearts(1)
						break
					end
					if extrahearts[i] == 9 then
						extrahearts[i] = 8
						halfredcount = halfredcount - 1
						player:AddHearts(1)
						break
					end
					if extrahearts[i] == 10 then
						extrahearts[i] = 9
						halfredcount = halfredcount - 1
						player:AddHearts(1)
						break
					end
				end
				savehealthdatanow = true
			end
			
			sexyrooms:getmaxeffectivehp(player)
			--let player pick up red hearts even when health is full if theres space in the extras
			local entities = Isaac.FindByType(5, 10, -1)
			local pickupradius = 25
			if halfredcount < halfspacecount + (bonecount*2) and player:GetHearts() == effectivemaxhealth then
				for ent = 1, #entities do
					local entity = entities[ent]
					if entity:IsDead() == false and entity.Type == 5 then
						if entity.Variant == 10 and entity.SubType < 20 then
							if entity.Position.X < player.Position.X + pickupradius and entity.Position.X > player.Position.X - pickupradius and entity.Position.Y < player.Position.Y + pickupradius and entity.Position.Y > player.Position.Y - pickupradius then
								if entity.SubType == 1 or entity.SubType == 9 then--full red
									addredhealth(2)
									SFXManager():Play(185, 1.25, 0, false, 1.0)
									entity:Remove()
									redhearttimeout = 0
									savehealthdatanow = true
								elseif entity.SubType == 2 or entity.SubType == 10 then--half red
									addredhealth(1)
									SFXManager():Play(185, 1.25, 0, false, 1.0)
									entity:Remove()
									redhearttimeout = 0
									savehealthdatanow = true
								elseif entity.SubType == 5 then--double red
									addredhealth(4)
									SFXManager():Play(185, 1.25, 0, false, 1.0)
									entity:Remove()
									redhearttimeout = 0
									savehealthdatanow = true
								elseif entity.SubType == 12 then--rotten heart
									addredhealth(2)
									rottenhearts = rottenhearts + 1
									SFXManager():Play(185, 1.25, 0, false, 1.0)
									entity:Remove()
									redhearttimeout = 0
									savehealthdatanow = true
								end
							end
							--pull items if player has magnet
							if player:HasCollectible(53) then
								if entity.SubType == 1 or entity.SubType == 2 or entity.SubType == 5 or entity.SubType == 9 or entity.SubType == 10 then
									local tempVel = entity.Velocity
									if entity.Position.X > player.Position.X then
										tempVel.X = -1.5
									else
										tempVel.X = 1.5
									end
									if entity.Position.Y > player.Position.Y then
										tempVel.Y = -1.5
									else
										tempVel.Y = 1.5
									end								
									entity.Velocity = tempVel
								end
							end
						end
					end
				end
				--let the keeper pick up coin health
				local keepercoincheck = player:GetNumCoins()
				if PickupCapCoinNum then
					keepercoincheck = PickupCapCoinNum
				end
				if player:GetName() == "Keeper" and keepercoincheck > keeperscoinscount then
					local coinhealthincrease = keepercoincheck-keeperscoinscount
					if coinhealthincrease % 2 == 1 then
						coinhealthincrease = coinhealthincrease + 1
					end
					if coinhealthincrease > halfspacecount-halfredcount then
						coinhealthincrease = halfspacecount-halfredcount
					end
					addredhealth(coinhealthincrease)
					savehealthdatanow = true
				end
				keeperscoinscount = keepercoincheck
			end
			
			--take into account things which grant more than 1 hpup in a single frame
			local needsheartoffset = 1
            entities = Isaac.FindByType(5, 100, -1)
			for ent = 1, #entities do
				local entity = entities[ent]
				if entity:IsDead() == false and entity.Type == 5 then
					--check for double soul/black/eternal hearts
					if p20HeartAltSubType and p20HeartAltSubType.HEART_SOUL_DOUBLEPACK and entity.Variant == p20PickupVariant.PICKUP_HEART_ALT then
						if entity.SubType == p20HeartAltSubType.HEART_SOUL_DOUBLEPACK or entity.SubType == p20HeartAltSubType.HEART_BLACK_DOUBLEPACK or entity.SubType == p20HeartAltSubType.HEART_ETERNAL_DOUBLEPACK then
							needsheartoffset = 2
							heartoffsetcooldown = Game():GetFrameCount() + 99
						end
					end
					--check for items that give 2/3 hearts
					if entity.Variant == 100 then
                        if needsheartoffset < 2 then
                            if entity.SubType == 16 or entity.SubType == 80 or entity.SubType == 129 or entity.SubType == 335 or entity.SubType == 464 then
                                needsheartoffset = 2
                                heartoffsetcooldown = Game():GetFrameCount() + 99
                            end
                        end
                        if needsheartoffset < 3 then
                            if entity.SubType == 72 or entity.SubType == 92 or entity.SubType == 216 or entity.SubType == 226 or entity.SubType == 301 or entity.SubType == 334 then
                                needsheartoffset = 3
                                heartoffsetcooldown = Game():GetFrameCount() + 99
                            end
						end
                        if needsheartoffset < 4 then
                            if entity.SubType == 428 then
                                needsheartoffset = 4
                                heartoffsetcooldown = Game():GetFrameCount() + 99
                            end
						end
					end
				end
			end
			if maxrealheartoffset < needsheartoffset then
				maxrealheartoffset = maxrealheartoffset + 1
			end
			if maxrealheartoffset > needsheartoffset and Game():GetFrameCount() > heartoffsetcooldown then
				maxrealheartoffset = maxrealheartoffset - 1
			end
			
			--check for rainbow poop destroy
			if SFXManager():IsPlaying(270) then
				if halfredcount < halfspacecount + (bonecount*2) and rainbowpoop == false then
					addredhealth(halfspacecount + (bonecount*2))
					savehealthdatanow = true
				end
				rainbowpoop = true
			else
				rainbowpoop = false
			end
			
			sexyrooms:getmaxeffectivehp(player)
			--check for unnecesary empty space
			if #extrahearts > 1 then
				for i = 2, #extrahearts, 1 do
					if extrahearts[i] == 0 then
						table.remove(extrahearts, i);
						break
					end
				end
			end
			
			sexyrooms:getmaxeffectivehp(player)
			--remove soul/black hearts if player has imposed a cap and has gotten hp up
			if (#extrahearts-1)+maxrealhearts > healthlimit and healthlimit > 0 then
				for i = 1, #extrahearts, 1 do
					if extrahearts[i] > 1 then
						--update soulheart counts
						if extrahearts[i] == 4 or extrahearts[i] == 6 then
							halfsoulcount = halfsoulcount - 1
							if extrahearts[i] == 6 then
								blackcount = blackcount - 1
							end
						elseif extrahearts[i] == 5 or extrahearts[i] == 7 then
							halfsoulcount = halfsoulcount - 2
							if extrahearts[i] == 7 then
								blackcount = blackcount - 2
							end
						elseif extrahearts[i] == 8 then
							bonecount = bonecount - 1
						elseif extrahearts[i] == 9 then
							bonecount = bonecount - 1
							halfredcount = halfredcount - 1
						elseif extrahearts[i] == 10 then
							bonecount = bonecount - 1
							halfredcount = halfredcount - 2
						end
						table.remove(extrahearts, i);
						break
					end
				end
				savehealthdatanow = true
			end
			
			--sort gold hearts to be at end of health bar
			if #goldhearts > 0 then
				local goldoffset = 0
				for i = 2, #goldhearts+1 do
					if i+goldoffset > #extrahearts then
						table.remove(goldhearts)
					else
						while extrahearts[i+goldoffset] < 2 do
							goldoffset = goldoffset + 1
						end
						goldhearts[i-1] = i + goldoffset
					end
				end
			end
			--if player picks up gold heart and there is space in extra move it there
			if #extrahearts > 1 and player:GetGoldenHearts() > 0 then
				if player:GetGoldenHearts() > 0 and #goldhearts < math.ceil(halfredcount*0.5) + math.ceil(halfsoulcount*0.5) + bonecount then
					table.insert(goldhearts, 2)
					player:AddGoldenHearts(-1)
					savehealthdatanow = true
				end
			end
			--should player lose a gold heart?
			if #goldhearts > 0 and #extrahearts-1 < oldheartcount and heartoffsetcooldown < Game():GetFrameCount() - 15 then
				sexyrooms:breakgoldheart()
				savehealthdatanow = true
			end
			oldheartcount = #extrahearts-1
			
			--check for an eternal heart
			if eternalheart == -1 and player:GetEternalHearts() > 0 then
				if effectivemaxhealth > 0 and halfspacecount+bonecount > 0 then
					eternalheart = 2
					player:AddEternalHearts(-1)
					savehealthdatanow = true
				end
			end
			--put eternal heart over last heart container
			if eternalheart > -1 and halfspacecount+bonecount > 0 then
				eternalheart = -9
				for j = #extrahearts, 1, -1 do
					if (extrahearts[j] > 0 and extrahearts[j] < 4) or (extrahearts[j] > 8 and extrahearts[j] < 11) then
						eternalheart = j
					end
				end
			end
			--check for eternal heart in extra when should be in normal health
			if eternalheart == -9 then
				eternalheart = -1
				player:AddEternalHearts(1)
				savehealthdatanow = true
			end
			--check for double eternal heart
			if eternalheart > -1 and player:GetEternalHearts() > 0 then
				eternalheart = -1
				player:AddEternalHearts(1)
				savehealthdatanow = true
			end
			--save extra heart data
			if savehealthdatanow then
				savehealthdata()
			end
		--if cap is set to less than default but not infinite
		elseif healthlimit < defaultheartlimit then
			if healthlimit > 0 then
				if player:GetSoulHearts() > 0 then
					if effectivemaxhealth + player:GetSoulHearts() > healthlimit*2 then
						player:AddSoulHearts(-1)
                        savehealthdatanow = true
					end
				else
					if effectivemaxhealth > healthlimit*2 then
						if player:GetBoneHearts() > 0 then
							player:AddBoneHearts(-1)
                            savehealthdatanow = true
						else
							player:AddMaxHearts(-2, false)
                            savehealthdatanow = true
						end
					end
				end
			else --limit to half a heart (of any type)
				if player:GetSoulHearts() > 0 then
					if effectivemaxhealth + player:GetSoulHearts() > 1 then
						player:AddSoulHearts(-1)
                        savehealthdatanow = true
					end
				else
					if REPENTANCE and player:GetName() == "Keeper" then
                        if player:GetMaxHearts() > 3 then
                            player:AddMaxHearts(-2, false)
                            savehealthdatanow = true
                        end
                        if player:GetHearts() > 2 then
                            player:AddHearts(-1)
                            savehealthdatanow = true
                        end
                    else
                        if player:GetMaxHearts() > 2 then
                            player:AddMaxHearts(-2, false)
                            savehealthdatanow = true
                        end
                        if player:GetHearts() > 1 then
                            player:AddHearts(-1)
                            savehealthdatanow = true
                        end
                    end
					if effectivemaxhealth > 2 then
						player:AddBoneHearts(-1)
                        savehealthdatanow = true
					end
				end
			end
			--save extra heart data
			if savehealthdatanow then
				savehealthdata()
			end
		end
	else
		if #extrahearts > 1 then
			local replaceheart = extrahearts[#extrahearts]
			if replaceheart > 0 and replaceheart < 4 then
				player:AddMaxHearts(2, false)
			end
			if replaceheart == 2 then
				player:AddHearts(1)
			elseif replaceheart == 3 then
				player:AddHearts(2)
			elseif replaceheart == 4 then
				player:AddSoulHearts(1)
			elseif replaceheart == 5 then
				player:AddSoulHearts(2)
			elseif replaceheart == 6 then
				player:AddBlackHearts(1)
			elseif replaceheart == 7 then
				player:AddBlackHearts(2)
			elseif replaceheart == 8 then
				player:AddBoneHearts(1)
			elseif replaceheart == 9 then
				player:AddBoneHearts(1)
				player:AddHearts(1)
			elseif replaceheart == 10 then
				player:AddBoneHearts(1)
				player:AddHearts(2)
			end
			extrahearts = {}
			savehealthdata()
		end
		if NoHealthCapEnableItemList then
			healthlimit = defaultheartlimit
		end
		halfspacecount = 0
		halfredcount = 0
		halfsoulcount = 0
		blackcount = 0
		bonecount = 0
		extrahearts = {}
		goldhearts = {}
		eternalheart = -1
		table.insert(extrahearts, 0);
		extraheartsBONE = {}
		table.insert(extraheartsBONE, 0);
		extraheartsSOUL = {}
		table.insert(extraheartsSOUL, 0);
	end
	
	--check for more heart containers than set container limit
	if redheartlimit > -1 and NoHealthCapRedMax > redheartlimit*2 and player.ControlsEnabled then
		local heartdifference = 0
		if overlimitcontainersbecome == 1 then
			player:AddSoulHearts(2)
			movesoulblacktoextra(false, false)
		elseif overlimitcontainersbecome == 2 then
			player:AddBlackHearts(2)
			movesoulblacktoextra(false, false)
		elseif overlimitcontainersbecome == 3 then
			heartdifference = 2 - (effectivemaxhealth-NoHealthCapRedHearts)
			player:AddBoneHearts(1)
			movebonestoextra(false)
		end
		player:AddMaxHearts(-2, false)
		if heartdifference > 0 then
			player:AddHearts(heartdifference)
		end
	end
	
	
	forgottenhealthbarupdate(player)
	oldforgottenmode = forgottenmode
	

	--update global values with total counts (normal + extra)
	NoHealthCapRedHearts = halfredcount + player:GetHearts()
	NoHealthCapRedMax = halfspacecount + player:GetMaxHearts()
	NoHealthCapSoulHearts = halfsoulcount + player:GetSoulHearts()
	NoHealthCapBlackHearts = blackcount
	NoHealthCapBoneHearts = bonecount + ((effectivemaxhealth - player:GetMaxHearts())/2)
	if REPENTANCE then
		NoHealthCapRottenHearts = rottenhearts + player:GetRottenHearts()
	end
end


function organisehearts()
	for i = #extrahearts, 2, -1 do
		--red hearts
		if extrahearts[i] == 2 and (extrahearts[i-1] == 3 or extrahearts[i-1] == 2) then
			extrahearts[i] = 3
			extrahearts[i-1] = extrahearts[i-1] - 1
		end
		--redhearts to empty containers
		if extrahearts[i] == 1 and (extrahearts[i-1] == 3 or extrahearts[i-1] == 2) then
			extrahearts[i] = extrahearts[i-1]
			extrahearts[i-1] = 1
		end
		--soul/black hearts before open spaces
		if extrahearts[i] == 0 and extrahearts[i-1] > 3 then
			extrahearts[i] = extrahearts[i-1]
			extrahearts[i-1] = 0
		end
		--soul/black hearts after red/empty health containers
		if extrahearts[i] > 3 and extrahearts[i-1] > 0 and extrahearts[i-1] < 4 then
			local temp = extrahearts[i]
			extrahearts[i] = extrahearts[i-1]
			extrahearts[i-1] = temp
		end
		--open spaces after red/empty empty containers
		if extrahearts[i] == 0 and extrahearts[i-1] > 0 and extrahearts[i-1] < 4 then
			local temp = extrahearts[i]
			extrahearts[i] = extrahearts[i-1]
			extrahearts[i-1] = temp
		end
		--bone hearts
		if extrahearts[i] == 8 and (extrahearts[i-1] == 9 or extrahearts[i-1] == 10 ) then
			extrahearts[i] = 9
			extrahearts[i-1] = extrahearts[i-1] - 1
		end
		if extrahearts[i] == 9 and (extrahearts[i-1] == 9 or extrahearts[i-1] == 10) then
			extrahearts[i] = 10
			extrahearts[i-1] = extrahearts[i-1] - 1
		end
		--soul hearts
		if extrahearts[i] == 4 then
			for j = i-1, 1, -1 do
				if extrahearts[j] == 4 then
					extrahearts[i] = 5
					extrahearts[j] = 0
					break
				elseif extrahearts[i-1] == 5 then
					extrahearts[i] = 5
					extrahearts[j] = 4
					break
				end
			end
		end
		--black hearts
		if extrahearts[i] == 6 then
			for j = i-1, 1, -1 do
				if extrahearts[j] == 6 then
					extrahearts[i] = 7
					extrahearts[j] = 0
					break
				elseif extrahearts[i-1] == 7 then
					extrahearts[i] = 7
					extrahearts[j] = 6
					break
				end
			end
		end
		--fill half black hearts with a soul half
		if extrahearts[i] == 6 then
			for j = i-1, 1, -1 do
				if extrahearts[j] == 4 then
					extrahearts[i] = 7
					extrahearts[j] = 0
					break
				elseif extrahearts[i-1] == 5 then
					extrahearts[i] = 7
					extrahearts[j] = 4
					break
				end
			end
		end
		--fill half soul hearts with a black half
		if extrahearts[i] == 4 then
			for j = i-1, 1, -1 do
				if extrahearts[j] == 6 then
					extrahearts[i] = 5
					extrahearts[j] = 0
					break
				elseif extrahearts[i-1] == 7 then
					extrahearts[i] = 5
					extrahearts[j] = 6
					break
				end
			end
		end
	end
end
function movebonestoextra(addtostart)
	local player = Isaac.GetPlayer(0)
	if (#extrahearts-1)+maxrealhearts < healthlimit or healthlimit == -1 then
		local boneheartamount = effectivemaxhealth - player:GetHearts()
		bonecount = bonecount + 1
		if addtostart then
			if boneheartamount == 0 then
				table.insert(extrahearts, 10)
				halfredcount = halfredcount + 2
			elseif boneheartamount == 1 then
				table.insert(extrahearts, 9)
				halfredcount = halfredcount + 1
			else
				table.insert(extrahearts, 8)
			end
		else
			if boneheartamount == 0 then
				table.insert(extrahearts, 2, 10)
				halfredcount = halfredcount + 2
			elseif boneheartamount == 1 then
				table.insert(extrahearts, 2, 9)
				halfredcount = halfredcount + 1
			else
				table.insert(extrahearts, 2, 8)
			end
		end
	end
	player:AddBoneHearts(-1)
end

function movesoulblacktoextra(addtostart, secondlast)
	local player = Isaac.GetPlayer(0)
	local amount = (effectivemaxhealth + player:GetSoulHearts())-(maxrealhearts*2)
	local blackcheckindex = player:GetSoulHearts()
	if blackcheckindex > 0 and blackcheckindex % 2 == 0 then
		blackcheckindex = blackcheckindex - 1
	end
	local blackcheck = player:IsBlackHeart(blackcheckindex)
	if secondlast then
		amount = (effectivemaxhealth + player:GetSoulHearts())-(maxrealhearts*2 - 2)
	end
	if amount >= 2 then
		if (#extrahearts-1)+maxrealhearts < healthlimit or healthlimit == -1 then
			if addtostart then
				if blackcheck then
					table.insert(extrahearts, 7)
					blackcount = blackcount + 2
				else
					table.insert(extrahearts, 5)
				end
			else
				if blackcheck then
					table.insert(extrahearts, 2, 7)
					blackcount = blackcount + 2
				else
					table.insert(extrahearts, 2, 5)
				end
			end
			halfsoulcount = halfsoulcount + 2
		else
			--check if player has hit health cap still has soul/black hearts and has picked up a black heart
			if blackcheck == true then
				if extrahearts[2] == 4 or extrahearts[2] == 6 then
					halfsoulcount = halfsoulcount + 1
					blackcount = blackcount + 1
					if extrahearts[2] == 4 then
						blackcount = blackcount + 1
					end
					extrahearts[2] = 7
				else
					for i = 2, #extrahearts, 1 do
						if extrahearts[i] == 5 then
							extrahearts[i] = 7
							blackcount = blackcount + 2
							break
						end
					end
				end
			else
			--check if player has hit health cap still has soul/black hearts and has picked up a soul heart
				if extrahearts[2] == 4 then
					halfsoulcount = halfsoulcount + 1
					extrahearts[2] = 5
				elseif extrahearts[2] == 6 then
					halfsoulcount = halfsoulcount + 1
					blackcount = blackcount + 1
					extrahearts[2] = 7
				end
			end
		end
		if blackcheck then
			player:RemoveBlackHeart(blackcheckindex)
		end
		player:AddSoulHearts(-2)
	else
		if (#extrahearts-1)+maxrealhearts < healthlimit or healthlimit == -1 then
			if addtostart then
				if blackcheck then
					table.insert(extrahearts, 6)
					blackcount = blackcount + 1
				else
					table.insert(extrahearts, 4)
				end
			else
				if blackcheck then
					table.insert(extrahearts, 2, 6)
					blackcount = blackcount + 1
				else
					table.insert(extrahearts, 2, 4)
				end
			end
			halfsoulcount = halfsoulcount + 1
		else
			--check if player has hit health cap still has soul/black hearts and has picked up half soul heart
			if extrahearts[2] == 4 then
				halfsoulcount = halfsoulcount + 1
				extrahearts[2] = 5
			elseif extrahearts[2] == 6 then
				halfsoulcount = halfsoulcount + 1
				blackcount = blackcount + 1
				extrahearts[2] = 7
			end
		end
		if blackcheck then
			player:RemoveBlackHeart(blackcheckindex)
		end
		player:AddSoulHearts(-1)
	end
end
function moveredcontainertoextra()
	local player = Isaac.GetPlayer(0)
	if ((#extrahearts-1)+maxrealhearts)-(halfsoulcount/2) < healthlimit or healthlimit == -1 then
		table.insert(extrahearts, 1);
		halfspacecount = halfspacecount + 2
		if player:GetHearts() >= (maxrealhearts+1)*2 then
			addredhealth(2)
		elseif player:GetHearts() == (maxrealhearts*2) + 1 then
			addredhealth(1)
		end
	end
	player:AddMaxHearts(-2, false)
end
function swapsoulforred()
	local player = Isaac.GetPlayer(0)
	--get what value to put into extras
	local lastreal = 0
	--get index for boneheart
	local bonecheck = effectivemaxhealth + player:GetSoulHearts() - player:GetMaxHearts()
	if bonecheck % 2 == 1 then
		bonecheck = bonecheck + 1
	end
	bonecheck = bonecheck/2
	bonecheck = bonecheck - 1
	--move bone hearts extra hearts
	if player:IsBoneHeart(bonecheck) then
		local boneheartamount = effectivemaxhealth - player:GetHearts()
		if boneheartamount > 2 then
			boneheartamount = 2
		end
		if boneheartamount == 2 then
			lastreal = 8
		elseif boneheartamount == 1 then
			lastreal = 9
		else
			lastreal = 10
		end
		player:AddBoneHearts(-1)
	else
		local heartnum = player:GetSoulHearts()
		if player:GetSoulHearts() % 2 == 1 then
			if player:IsBlackHeart(heartnum) then
				lastreal = 6
			else
				lastreal = 4
			end
			player:AddSoulHearts(-1)
		else
			heartnum = heartnum - 1
			if player:IsBlackHeart(heartnum) then
				lastreal = 7
			else
				lastreal = 5
			end
			player:AddSoulHearts(-2)
		end
	end
	--convert first heart in extras to 'real' health
	local firstextra = extrahearts[#extrahearts]
	table.remove(extrahearts, #extrahearts);
	if firstextra == 2 then
		halfredcount = halfredcount - 1
	elseif firstextra == 3 then
		halfredcount = halfredcount - 2
	end
	--move 'real' health to extras
	table.insert(extrahearts, lastreal)
	if lastreal == 4 or lastreal == 6 then
		halfsoulcount = halfsoulcount + 1
		if lastreal == 6 then
			blackcount = blackcount + 1
		end
	elseif lastreal == 5 or lastreal == 7 then
		halfsoulcount = halfsoulcount + 2
		if lastreal == 7 then
			blackcount = blackcount + 2
		end
	elseif lastreal == 8 then
		bonecount = bonecount + 1
	elseif lastreal == 9 then
		bonecount = bonecount + 1
		halfredcount = halfredcount + 1
	elseif lastreal == 10 then
		bonecount = bonecount + 1
		halfredcount = halfredcount + 2
	end
	--give player 'real' red health
	player:AddMaxHearts(2, false)
	if firstextra == 2 then
		player:AddHearts(1)
	elseif firstextra == 3 then
		player:AddHearts(2)
	end
end





--add half red hearts to empty containers and make them stack
function addredhealth(amount)
	local player = Isaac.GetPlayer(0)
	if player:GetName() ~= "???" then
		local temp = tonumber(amount)
		while temp > 0 and halfredcount < halfspacecount + bonecount*2 do
			for i = #extrahearts, 1, -1 do
				if extrahearts[i] == 1 then
					extrahearts[i] = 2
					temp = temp - 1
					halfredcount = halfredcount + 1
					break
				elseif extrahearts[i] == 2 then
					extrahearts[i] = 3
					temp = temp - 1
					halfredcount = halfredcount + 1
					break
				elseif extrahearts[i] == 8 then
					extrahearts[i] = 9
					temp = temp - 1
					halfredcount = halfredcount + 1
					break
				elseif extrahearts[i] == 9 then
					extrahearts[i] = 10
					temp = temp - 1
					halfredcount = halfredcount + 1
					break
				end
			end
		end
	end
end
--add half soul hearts to empty containers and make them stack
function addsoulhealth(amount)
	local temp = tonumber(amount)
	while temp > 0 do
		for i = #extrahearts, 1, -1 do
			if extrahearts[i] == 4 then
				extrahearts[i] = 5
				temp = temp - 1
				halfsoulcount = halfsoulcount + 1
				break
			elseif extrahearts[i] == 6 then
				extrahearts[i] = 7
				temp = temp - 1
				halfsoulcount = halfsoulcount + 1
				blackcount = blackcount + 1
				break
			end
		end
		table.insert(extrahearts, 4);
	end
end
--take half red hearts, returns leftover
function loseredhealth(amount)
	local temp = tonumber(amount)
	while temp > 0 and halfredcount > 0 do
		if eternalheart > -1 and REPENTANCE == false then
			eternalheart = -1
			temp = temp - 2
		end
		if temp > 0 then
			for i = 1, #extrahearts, 1 do
				if extrahearts[i] == 2 or extrahearts[i] == 3 then
					extrahearts[i] = extrahearts[i] - 1
					temp = temp - 1
					halfredcount = halfredcount - 1
					break
				elseif extrahearts[i] == 9 or extrahearts[i] == 10 then
					extrahearts[i] = extrahearts[i] - 1
					temp = temp - 1
					halfredcount = halfredcount - 1
					break
				end
			end
		end
	end
	--rotten hearts
	if rottenhearts > 0 and rottenhearts > math.ceil(halfredcount/2) then
		rottenhearts = rottenhearts - 1
		player:AddRottenHearts(2)
	end
	if REPENTANCE and temp > 0 and halfredcount == 0 and eternalheart > -1 then
		eternalheart = -1
		temp = temp - 2
	end
	return temp
end
--take half soul hearts, returns leftover
function losesoulhealth(amount)
	local temp = tonumber(amount)
	while temp > 0 and (halfsoulcount > 0 or bonecount > 0 or rottenhearts > 0) do
		for i = 1, #extrahearts, 1 do
			if extrahearts[i] == 4 then
				extrahearts[i] = 0
				temp = temp - 1
				halfsoulcount = halfsoulcount - 1
				break
			elseif extrahearts[i] == 5 or extrahearts[i] == 7 then
				if extrahearts[i] == 7 then
					blackcount = blackcount - 1
				end
				extrahearts[i] = extrahearts[i] - 1
				temp = temp - 1
				halfsoulcount = halfsoulcount - 1
				break
			elseif extrahearts[i] == 6 then
				extrahearts[i] = 0
				temp = temp - 1
				halfsoulcount = halfsoulcount - 1
				blackcount = blackcount - 1
				fakeblackheart()
				break
			elseif extrahearts[i] == 8 then
				extrahearts[i] = 0
				temp = temp - 2
				bonecount = bonecount - 1
				break
			elseif extrahearts[i] == 9 or extrahearts[i] == 10 then
				extrahearts[i] = extrahearts[i] - 1
				temp = temp - 1
				halfredcount = halfredcount - 1
				if rottenhearts > 0 then
					temp = temp - 1
					rottenhearts = rottenhearts - 1
					loseredhealth(1)
				end
				break
			elseif rottenhearts > 0 and (extrahearts[i] == 2 or extrahearts[i] == 3) then
				extrahearts[i] = extrahearts[i] - 1
				temp = temp - 2
				halfredcount = halfredcount - 1
				rottenhearts = rottenhearts - 1
				loseredhealth(1)
				break
			end
		end
	end
    if temp > 0 and eternalheart > -1 then
        temp = temp - 2
        eternalheart = -1
    end
	return temp
end
--take half soul hearts, does not take bone hearts, returns leftover
function loseonlysoulhealth(amount)
	local temp = tonumber(amount)
	while temp > 0 and (halfsoulcount > 0 or rottenhearts > 0) do
		for i = 1, #extrahearts, 1 do
			if extrahearts[i] == 4 then
				extrahearts[i] = 0
				temp = temp - 1
				halfsoulcount = halfsoulcount - 1
				break
			elseif extrahearts[i] == 5 or extrahearts[i] == 7 then
				if extrahearts[i] == 7 then
					blackcount = blackcount - 1
				end
				extrahearts[i] = extrahearts[i] - 1
				temp = temp - 1
				halfsoulcount = halfsoulcount - 1
				break
			elseif extrahearts[i] == 6 then
				extrahearts[i] = 0
				temp = temp - 1
				halfsoulcount = halfsoulcount - 1
				blackcount = blackcount - 1
				fakeblackheart()
				break
			elseif (extrahearts[i] == 2 or extrahearts[i] == 9) and rottenhearts > 0 and halfsoulcount == 0 then
				extrahearts[i] = extrahearts[i] - 1
				temp = temp - 2
				halfredcount = halfredcount - 1
				rottenhearts = rottenhearts - 1
				loseredhealth(1)
				break
			elseif (extrahearts[i] == 3 or extrahearts[i] == 10) and rottenhearts > 0 and halfsoulcount == 0 then
				extrahearts[i] = extrahearts[i] - 2
				temp = temp - 2
				halfredcount = halfredcount - 2
				rottenhearts = rottenhearts - 1
				break
			end
		end
	end
	return temp
end
--take only black hearts from extra health bar
function loseonlyblackhealth(amount, dodamage)
	local temp = tonumber(amount)
	while temp > 0 and blackcount > 0 do
		for i = 1, #extrahearts, 1 do
			if extrahearts[i] == 7 then
				extrahearts[i] = extrahearts[i] - 1
				temp = temp - 1
				halfsoulcount = halfsoulcount - 1
				blackcount = blackcount - 1
				valuesupdated = true
				break
			elseif extrahearts[i] == 6 then
				extrahearts[i] = 0
				temp = temp - 1
				halfsoulcount = halfsoulcount - 1
				blackcount = blackcount - 1
				if dodamage then
					fakeblackheart()
				end
				valuesupdated = true
				break
			end
		end
	end
	return temp
end
function fakeblackheart()--simulate black heart damage from losing a black heart
	local player = Isaac.GetPlayer(0)
	player:AddBlackHearts(1)
	takendamage = true
	player:TakeDamage(1, DamageFlag.DAMAGE_SPIKES, EntityRef(player), 0)
end

function sexyrooms:takeDamage(target,amount,flag,source,num)
	local player = Isaac.GetPlayer(0)
	if NoHealthCapModIgnoreDamage then
		NoHealthCapModIgnoreDamage = false
	elseif (healthlimit == -1 or healthlimit > defaultheartlimit) and (flag == DamageFlag.DAMAGE_SPIKES or flag & DamageFlag.DAMAGE_SPIKES == DamageFlag.DAMAGE_SPIKES) and Game():GetLevel():GetCurrentRoom():GetType() == RoomType.ROOM_SACRIFICE then
		--let you use sacrifice spikes
		if player:GetMaxHearts() > maxrealhearts*2 - 2 then
			sacspikes = true
		end
	elseif flag == 301998208 then --mausoluem door
		if player:GetMaxHearts() > maxrealhearts*2 - 2 then
			sacspikes = true
		end
	else
		if target.Type == EntityType.ENTITY_PLAYER and target.Index == player.Index then
			if takendamage == false then--if player takes damage move health from extra hearts
				if (flag ~= DamageFlag.DAMAGE_FAKE or flag & DamageFlag.DAMAGE_SPIKES ~= DamageFlag.DAMAGE_FAKE) and (halfredcount > 0 or halfsoulcount > 0) then
					local hearttype = "soul"
					if player:HasTrinket(crowheart) or flag == 270368 or flag == DamageFlag.DAMAGE_IV_BAG or flag == DamageFlag.DAMAGE_RED_HEARTS or flag & 270368 == 270368 or flag & DamageFlag.DAMAGE_RED_HEARTS == DamageFlag.DAMAGE_RED_HEARTS or flag & DamageFlag.DAMAGE_IV_BAG == DamageFlag.DAMAGE_IV_BAG then
						if player:GetHearts()+halfredcount > amount then
							hearttype = "red"
						end
					end
					if hearttype == "red" then --take red hearts
						if halfredcount > 0 then
							takendamage = true
							local temp = loseredhealth(amount)
							if temp > 0 then
								player:TakeDamage(temp, flag, source, num)
							else
								player:TakeDamage(1, DamageFlag.DAMAGE_FAKE, source, num)
							end
							return false
						end
					elseif hearttype == "soul" then --take soul hearts
						takendamage = true
						local temp = 0
						if Isaac.GetItemIdByName("Rib Cage") > 0 and player:HasCollectible(Isaac.GetItemIdByName("Rib Cage")) then
							temp = loseonlysoulhealth(amount)
						else
							temp = losesoulhealth(amount)
						end
						if temp > 0 then
							temp = loseredhealth(amount)
						end
						if temp > 0 then
							player:TakeDamage(temp, flag, source, num)
						else
							player:TakeDamage(1, DamageFlag.DAMAGE_FAKE, source, num)
						end
						return false
					end
				end
			else
				takendamage = false
			end
		end
	end
end


--let player set variables in console
function sexyrooms:onCmd(cmd, param)
	if cmd == "hudoffset" then
		if tonumber(param) == nil then
			Isaac.ConsoleOutput("Please enter a valid number (default 0)")
		elseif tonumber(param) > -1 and tonumber(param) < 11 then
			HUDoffset = tonumber(param)
			Isaac.ConsoleOutput("HUD offset updated")
		else
			Isaac.ConsoleOutput("Please enter a valid number (default 0)")
		end
		savehealthdata()
	end
	if cmd == "healthcap" then
		if NoHealthCapEnableItemList then
			Isaac.ConsoleOutput("Health cap is currently controlled by modded items")
			Isaac.ConsoleOutput("Disable all mods with health cap changing")
			Isaac.ConsoleOutput("items to control health caps manually")
		else
			if tonumber(param) == nil then
				Isaac.ConsoleOutput("Please enter a valid number (default -1)")
			elseif tonumber(param) > -2 then
				healthlimit = tonumber(param)
				Isaac.ConsoleOutput("Health cap updated")
				savehealthdata()
			else
				Isaac.ConsoleOutput("Please enter a valid number (default -1)")
			end
		end
	end
	if cmd == "redheartcap" then
		if NoHealthCapEnableItemList then
			Isaac.ConsoleOutput("Health cap is currently controlled by modded items")
			Isaac.ConsoleOutput("Disable all mods with health cap changing")
			Isaac.ConsoleOutput("items to control health caps manually")
		else
			if tonumber(param) == nil then
				Isaac.ConsoleOutput("Please enter a valid number (default -1)")
			elseif tonumber(param) > -2 then
				redheartlimit = tonumber(param)
				Isaac.ConsoleOutput("Red heart container cap updated")
				savehealthdata()
			else
				Isaac.ConsoleOutput("Please enter a valid number (default -1)")
			end
		end
	end
	if cmd == "extracontainersbecome" then
		if NoHealthCapEnableItemList then
			Isaac.ConsoleOutput("Health cap is currently controlled by modded items")
			Isaac.ConsoleOutput("Disable all mods with health cap changing")
			Isaac.ConsoleOutput("items to control health caps manually")
		else
			if param == "nothing" or param == "soul" or param == "black" or param == "bone" then
				overlimitcontainersbecome = 0
				if param == "soul" then
					overlimitcontainersbecome = 1
				elseif param == "black" then
					overlimitcontainersbecome = 2
				elseif param == "bone" then
					overlimitcontainersbecome = 3
				end
				Isaac.ConsoleOutput("Extra container conversion updated")
				savehealthdata()
			else
				Isaac.ConsoleOutput("Please enter 'nothing', 'soul', 'black' or 'bone'")
			end
		end
	end
	if cmd == "showhealthcaps" then
		Isaac.ConsoleOutput("Current health cap is " .. healthlimit)
		Isaac.ConsoleOutput("Current red heart container cap is " .. redheartlimit)
		local displaystring = "Nothing"
		if overlimitcontainersbecome == 1 then
			displaystring = "Soul Hearts"
		elseif overlimitcontainersbecome == 2 then
			displaystring = "Black Hearts"
		elseif overlimitcontainersbecome == 3 then
			displaystring = "Bone Hearts"
		end
		Isaac.ConsoleOutput("Heart containers over container cap become " .. displaystring)
	end
	if cmd == "heartoffset" then
		if tonumber(param) == nil then
			Isaac.ConsoleOutput("Please enter a valid number (1-3)")
		elseif tonumber(param) < 1 or tonumber(param) > 3 then
			Isaac.ConsoleOutput("Please enter a valid number (1-3)")
		else
			maxrealheartoffset = tonumber(param)
			maxrealhearts = defaultheartlimit-maxrealheartoffset
			Isaac.ConsoleOutput("Heart offset is now " .. param)
			organisehearts()
		end
	end
end


function updateheartcounts()--count hearts in loaded data
	halfspacecount = 0
	halfredcount = 0
	halfsoulcount = 0
	bonecount = 0
	blackcount = 0
	for i = 1, #extrahearts, 1 do
		if extrahearts[i] == 1 then
			halfspacecount = halfspacecount + 2
		elseif extrahearts[i] == 2 then
			halfspacecount = halfspacecount + 2
			halfredcount = halfredcount + 1
		elseif extrahearts[i] == 3 then
			halfspacecount = halfspacecount + 2
			halfredcount = halfredcount + 2
		elseif extrahearts[i] == 4 then
			halfsoulcount = halfsoulcount + 1
		elseif extrahearts[i] == 5 then
			halfsoulcount = halfsoulcount + 2
		elseif extrahearts[i] == 6 then
			halfsoulcount = halfsoulcount + 1
			blackcount = blackcount + 1
		elseif extrahearts[i] == 7 then
			halfsoulcount = halfsoulcount + 2
			blackcount = blackcount + 2
		elseif extrahearts[i] == 8 then
			bonecount = bonecount + 1
		elseif extrahearts[i] == 9 then
			bonecount = bonecount + 1
			halfredcount = halfredcount + 1
		elseif extrahearts[i] == 10 then
			bonecount = bonecount + 1
			halfredcount = halfredcount + 2
		end
	end
end

local hearticon = Sprite()
hearticon:Load("gfx/ui/nocaphearts.anm2", true)
local goldicon = Sprite()
goldicon:Load("gfx/ui/nocaphearts2.anm2", true)
local eternalicon = Sprite()
eternalicon:Load("gfx/ui/nocaphearts2.anm2", true)
local rottenicon = Sprite()
rottenicon:Load("gfx/ui/nocaphearts2.anm2", true)
function sexyrooms:displayinfo()
	local currentRoom = Game():GetLevel():GetCurrentRoom()
	local bosscheck = true
	if currentRoom:IsClear() == false and currentRoom:GetFrameCount() == 0 and currentRoom:GetType() == RoomType.ROOM_BOSS then
		bosscheck = false
	end
	if modenabled == true and #extrahearts > 1 and hudOn and unknowncurse == false and (healthlimit > defaultheartlimit or healthlimit == -1) and bosscheck then
		--show the heart icons
		local temprotten = rottenhearts+0
		local tempredheartcount = 0
		local nonrottenreds = math.ceil((halfredcount - rottenhearts*2)/2)
		local heartsize = Vector(12,10)
		local Xoffset = 128
		local Yoffset = 30
		Xoffset = Xoffset + (HUDoffset*2) - (maxrealheartoffset*heartsize.X)
		Yoffset = Yoffset + (HUDoffset*1.2)
		if forgottenmode > 0 then
			for g = 0, maxrealheartoffset-1 do
				--display extra for forgotten sub character
				if forgottenmode == 1 then
					local heartype = extraheartsSOUL[#extraheartsSOUL-g]
					if heartype == 0 then
						hearticon:Play("None", true)
					elseif heartype == 4 then
						hearticon:Play("SoulHalfClear2", true)
					elseif heartype == 5 then
						hearticon:Play("SoulFullClear2", true)
					elseif heartype == 6 then
						hearticon:Play("BlackHalfClear2", true)
					elseif heartype == 7 then
						hearticon:Play("BlackFullClear2", true)
					end
				else
					local heartype = extraheartsBONE[#extraheartsBONE-g]
					if heartype == 0 then
						hearticon:Play("None", true)
					elseif heartype == 1 then
						hearticon:Play("EmptyClear2", true)
					elseif heartype == 2 then
						hearticon:Play("RedHalfClear2", true)
					elseif heartype == 3 then
						hearticon:Play("RedFullClear2", true)
					elseif heartype == 8 then
						hearticon:Play("EmptyBoneClear2", true)
					elseif heartype == 9 then
						hearticon:Play("HalfBoneClear2", true)
					elseif heartype == 10 then
						hearticon:Play("FullBoneClear2", true)
					end
				end
				hearticon:SetOverlayRenderPriority(true)
				hearticon:Render(Vector(Xoffset,Yoffset), Vector(0,0), Vector(0,0))
				Xoffset = Xoffset + heartsize.X
			end
			Xoffset = Xoffset - heartsize.X*maxrealheartoffset
			Yoffset = Yoffset - heartsize.Y
		end
		goldicon:Play("None", true)
		eternalicon:Play("None", true)
		rottenicon:Play("None", true)
		for i = #extrahearts, 1, -1 do
			if extrahearts[i] < 1 or extrahearts[i] > 90 then
				hearticon:Play("None", true)
			else
				if displayheartrows > 0 and (#extrahearts-i+1)-maxrealheartoffset > 6*(displayheartrows-2) then
					hearticon:Play("None", true)
					--hide health rows based on setting
				else
					local hearttype = extrahearts[i]-1
					if (#extrahearts-i+1)-maxrealheartoffset > 6 then
						hearttype = hearttype+100
					end
					if (#extrahearts-i+1)-maxrealheartoffset > 12 then
						hearttype = hearttype+100
					end
					if (#extrahearts-i+1)-maxrealheartoffset > 18 then
						hearttype = hearttype+100
					end
					
					local player = Isaac.GetPlayer(0)
					local animname = "Empty"
					if player:GetName() == "Keeper" then
						animname = "CoinEmpty"
					end
					local heartnumcode = hearttype .. ""
					--get heart type
					local heartlastchar = string.sub(heartnumcode, -1, -1)
					if heartlastchar == "1" then
						animname = "RedHalf"
						tempredheartcount = tempredheartcount + 1
						if player:GetName() == "Keeper" then
							animname = "CoinHalf"
						end
					elseif heartlastchar == "2" then
						animname = "RedFull"
						tempredheartcount = tempredheartcount + 1
						if player:GetName() == "Keeper" then
							animname = "CoinFull"
						end
					elseif heartlastchar == "3" then
						animname = "SoulHalf"
					elseif heartlastchar == "4" then
						animname = "SoulFull"
					elseif heartlastchar == "5" then
						animname = "BlackHalf"
					elseif heartlastchar == "6" then
						animname = "BlackFull"
					elseif heartlastchar == "7" then
						animname = "EmptyBone"
					elseif heartlastchar == "8" then
						animname = "HalfBone"
						tempredheartcount = tempredheartcount + 1
					elseif heartlastchar == "9" then
						animname = "FullBone"
						tempredheartcount = tempredheartcount + 1
					end
					--manage half heart before rottens
					if halfredcount % 2 == 1 and temprotten > 0 and tempredheartcount == nonrottenreds then
						if animname == "RedFull" then
							animname = "RedHalf"
						elseif animname == "FullBone" then
							animname = "HalfBone"
						end
					end
					--apply gradual fade
					local fadestring = ""
					if string.len(heartnumcode) > 2 then
						fadestring =  "Clear"
						if string.sub(heartnumcode, 1, 1) ~= "1" then
							fadestring = fadestring .. string.sub(heartnumcode, 1, 1)
						end
					end
					hearticon:Play(animname .. fadestring, true)
					if (#extrahearts-i+1) % 6 == maxrealheartoffset+1 then
						Yoffset = Yoffset + heartsize.Y
						Xoffset = Xoffset - heartsize.X*6
					end
					hearticon:SetOverlayRenderPriority(true)
					--rotten hearts
					if temprotten > 0 and tempredheartcount > nonrottenreds then
						temprotten = temprotten - 1
						if animname == "FullBone" or animname == "HalfBone" then
							animname = "RottenBone"
						elseif animname == "RedFull"or animname == "RedHalf" then
							animname = "Rotten"
						end
						if string.sub(animname,1,6) == "Rotten" then
							rottenicon:Play(animname .. fadestring, true)
							rottenicon:SetOverlayRenderPriority(true)
							rottenicon:Render(Vector(Xoffset,Yoffset), Vector(0,0), Vector(0,0))
						end
					end
					if string.sub(animname,1,6) ~= "Rotten" then
						hearticon:Render(Vector(Xoffset,Yoffset), Vector(0,0), Vector(0,0))
					end
					Xoffset = Xoffset + heartsize.X
					if forgottenmode > 0 and 1+#extrahearts-i == maxrealheartoffset then
						Yoffset = Yoffset + heartsize.Y
					end
				end
			end
		end
		--show gold heart overlays
		for i = #goldhearts, 1, -1 do
			local heartposID = #extrahearts-goldhearts[i]+1-maxrealheartoffset
			if displayheartrows > 0 and heartposID > 6*(displayheartrows-2) then
				--hide hearts based on setting
			else
				local fadestring = ""
				if heartposID > 6 then
					fadestring = "Clear"
				end
				if heartposID > 12 then
					fadestring = "Clear2"
				end
				if heartposID > 18 then
					fadestring = "Clear3"
				end
				goldicon:Play("Gold" .. fadestring, true)
				goldicon:SetOverlayRenderPriority(true)
				heartposID = heartposID - 1
				local xRender = (heartposID%6) * heartsize.X + 56 + (HUDoffset*2)
				local yRender = math.floor((heartposID)/6)* heartsize.Y + 40 + (HUDoffset*1.2)
				goldicon:Render(Vector(xRender,yRender), Vector(0,0), Vector(0,0))
			end
		end
		--show eternal heart overlay
		if eternalheart > -1 then
			local heartposID = #extrahearts-eternalheart+1-maxrealheartoffset
			if displayheartrows > 0 and heartposID > 6*(displayheartrows-2) then
				--hide hearts based on setting
			else
				local fadestring = ""
				if heartposID > 6 then
					fadestring = "Clear"
				end
				if heartposID > 12 then
					fadestring = "Clear2"
				end
				if heartposID > 18 then
					fadestring = "Clear3"
				end
				eternalicon:Play("Eternal" .. fadestring, true)
				eternalicon:SetOverlayRenderPriority(true)
				heartposID = heartposID - 1
				local xRender = (heartposID%6) * heartsize.X + 56 + (HUDoffset*2)
				local yRender = math.floor((heartposID)/6)* heartsize.Y + 40 + (HUDoffset*1.2)
				eternalicon:Render(Vector(xRender,yRender), Vector(0,0), Vector(0,0))
			end
		end
		--display extra health as numbers, used for debugging
		local tempstring = extrahearts[#extrahearts]
		for i = #extrahearts-1, 1, -1 do
			tempstring = tempstring .. "," .. extrahearts[i]
		end
		--Isaac.RenderText(tempstring, 50, 75, 255, 255, 255, 255)
	end
	Isaac.RenderText(debug_text, 50, 50, 0, 255, 0, 255)
end

function sexyrooms:onPill(pillID)
	if pillID == 5 then--check if player uses full health pill
		for i = #extrahearts, 1, -1 do
			if extrahearts[i] == 1 then
				extrahearts[i] = 3
				halfredcount = halfredcount + 2
			end
			if extrahearts[i] == 2 then
				extrahearts[i] = 3
				halfredcount = halfredcount + 1
			end
			if extrahearts[i] == 8 then
				extrahearts[i] = 10
				halfredcount = halfredcount + 2
			end
			if extrahearts[i] == 9 then
				extrahearts[i] = 10
				halfredcount = halfredcount + 1
			end
		end
	end
	if pillID == 2 and #extrahearts > 1 then--check if player uses balls of steel pill
		table.insert(extrahearts, 2, 5);
		halfsoulcount = halfsoulcount + 2
	end
	if pillID == 21 and #extrahearts > 1 then--check if player uses hematemisis pill
		for i = #extrahearts, 1, -1 do
			if extrahearts[i] == 3 then
				extrahearts[i] = 1
				halfredcount = halfredcount - 2
			end
			if extrahearts[i] == 2 then
				extrahearts[i] = 1
				halfredcount = halfredcount - 1
			end
			if extrahearts[i] == 10 then
				extrahearts[i] = 8
				halfredcount = halfredcount - 2
			end
			if extrahearts[i] == 9 then
				extrahearts[i] = 8
				halfredcount = halfredcount - 1
			end
		end
	end
end

function sexyrooms:onCard(CardID)--check if player uses a '2 of hearts' card
	local player = Isaac.GetPlayer(0)
	if CardID == 26 and (healthlimit > defaultheartlimit or healthlimit == -1) and halfspacecount + bonecount > 0 and NoHealthCapRedHearts >= maxrealhearts then
		local playerred = NoHealthCapRedHearts - halfredcount
		local remainingspace = effectivemaxhealth-playerred
		--will red heart doubling overflow into extras?
		if remainingspace < NoHealthCapRedHearts then
			local extrareds = NoHealthCapRedHearts - remainingspace
			--will there be more reds than containers?
			if extrareds > NoHealthCapRedMax-effectivemaxhealth then
				extrareds = NoHealthCapRedMax-effectivemaxhealth
			end
			addredhealth(extrareds)
		end
	end
end

function sexyrooms:use_item(useitemID)--check if player uses guppys paw or soul converter
	local player = Isaac.GetPlayer(0)
	--guppys paw, 1 red for 3 soul
	if useitemID == 133 and #extrahearts > 1 and NoHealthCapRedMax-halfspacecount > 0 then
		table.insert(extrahearts, 2, 5);
		halfsoulcount = halfsoulcount + 2
		return false
	end
	--converter, 2 soul for 1 red
	if useitemID == 296 and #extrahearts > 1 then
		if player:GetSoulHearts() < 2 and halfsoulcount > 3 then
			losesoulhealth(4)
			table.insert(extrahearts, 3);
			halfspacecount = halfspacecount + 2
			halfredcount = halfredcount + 2
			return true
		end
	end
	--satanic bible + car battery
	if useitemID == 292 and #extrahearts > 1 and player:HasCollectible(356) then
		table.insert(extrahearts, 2, 6);
		halfsoulcount = halfsoulcount + 1
		blackcount = blackcount + 1
	end
	--book of revelations + car battery
	if useitemID == 78 and #extrahearts > 1 and player:HasCollectible(356) then
		table.insert(extrahearts, 2, 4);
		halfsoulcount = halfsoulcount + 1
	end
end

function sexyrooms:breakgoldheart()
	local player = Isaac.GetPlayer(0)
	table.remove(goldhearts)
	player:AddSoulHearts(1)
	player:AddGoldenHearts(1)
	player:AddSoulHearts(-1)
end

function sexyrooms:newfloor()
	local player = Isaac.GetPlayer(0)
	if eternalheart > -1 then
		eternalheart = -1
		player:AddEternalHearts(2)
	end
end


--mod config menu stuff
if ModConfigMenu then
	MCM = require("scripts.modconfig")
	MCM.UpdateCategory("Health Caps", {
		Info = "Health Cap settings"
	})
	MCM.AddSpace("Health Caps")
	MCM.AddSetting("Health Caps", { 
		Type = MCM.OptionType.NUMBER,
		CurrentSetting = function()
			return healthlimit
		end,
		Display = function()
			if healthlimit == -2 then
				return "Heart cap: Disabled"
			elseif healthlimit == -1 then
				return "Heart cap: Infinite"
			elseif healthlimit == 0 then
				return "Heart cap: Half a heart"
			else
				return "Heart cap: " .. healthlimit
			end
		end,
		OnChange = function(currentNum)
			healthlimit = currentNum
			savehealthdata()
		end,
		Info = {
			"Maximum hearts the player can have.",
			"(0 for a half heart)"
		}
	})
	MCM.AddSpace("Health Caps")
	MCM.AddSetting("Health Caps", { 
		Type = MCM.OptionType.NUMBER,
		CurrentSetting = function()
			return redheartlimit
		end,
		Display = function()
			if redheartlimit == -1 then
				return "Red container cap: Disabled"
			else
				return "Red container cap: " .. redheartlimit
			end
		end,
		OnChange = function(currentNum)
			redheartlimit = currentNum
			savehealthdata()
		end,
		Info = {
			"Maximum red heart containers the player can have.",
			"(Can't be larger than total health cap)"
		}
	})
	MCM.AddSpace("Health Caps")
	MCM.AddSetting("Health Caps", { 
		Type = MCM.OptionType.NUMBER,
		CurrentSetting = function()
			return overlimitcontainersbecome
		end,
		Display = function()
			local displaystring = "Nothing"
			if overlimitcontainersbecome == 1 then
				displaystring = "Soul Hearts"
			elseif overlimitcontainersbecome == 2 then
				displaystring = "Black Hearts"
			elseif overlimitcontainersbecome == 3 then
				displaystring = "Bone Hearts"
			end
			return "Containers over cap become: " .. displaystring
		end,
		Minimum = 0,
		Maximum = 3,
		OnChange = function(currentNum)
			overlimitcontainersbecome = currentNum
			savehealthdata()
		end,
		Info = {
			"What happens to heart containers over the container cap.",
			"(can turn hpups into other hearts like ???/forgotten)",
			"(only takes affect if the red container cap is enabled)"
		}
	})
	MCM.AddSpace("Health Caps")
	MCM.AddSetting("Health Caps", { 
		Type = MCM.OptionType.NUMBER,
		CurrentSetting = function()
			return displayheartrows
		end,
		Display = function()
			if displayheartrows < 1 then
				return "Show ALL rows of health"
			else
				return "Show " .. displayheartrows .. " rows of health"
			end
		end,
		Minimum = -1,
		Maximum = 50,
		OnChange = function(currentNum)
			displayheartrows = currentNum
			if displayheartrows == 0 then
				displayheartrows = 2
			end
			if displayheartrows == 1 then
				displayheartrows = -1
			end
			savehealthdata()
		end,
		Info = {
			"How many rows of health are visible.",
			"(mod still tracks extra health, just doesn't show it)"
		}
	})
end

function NoHealthCapGetHeartTypeAtPos(pos)
	pos = #extrahearts-(pos-(defaultheartlimit-maxrealheartoffset))
	local hearttype = "None"
	local overlaytype = "None"
	local eternal = false
	local goldheart = false
	local curse = Game():GetLevel():GetCurseName()
	if player:GetPlayerType() == 10 or player:GetPlayerType() == 31 then
		--return none for the lost
	elseif pos < 1 or pos > #extrahearts or curse == "Curse of the Unknown" then
		--return none
	else
		--get heart type
		local player = Isaac.GetPlayer(0)
		if extrahearts[pos] == 1 then
			if player:GetName() == "Keeper" then
				hearttype = "CoinEmpty"
			else
				hearttype = "RedEmpty"
			end
		elseif extrahearts[pos] == 2 then
			if player:GetName() == "Keeper" then
				hearttype = "CoinHalf"
			else
				hearttype = "RedHalf"
			end
		elseif extrahearts[pos] == 3 then
			if player:GetName() == "Keeper" then
				hearttype = "CoinEmpty"
			else
				hearttype = "RedFull"
			end
		elseif extrahearts[pos] == 4 then
			hearttype = "BlueHalf"
		elseif extrahearts[pos] == 5 then
			hearttype = "BlueFull"
		elseif extrahearts[pos] == 6 then
			hearttype = "BlackHalf"
		elseif extrahearts[pos] == 7 then
			hearttype = "BlackFull"
		elseif extrahearts[pos] == 8 then
			hearttype = "BoneEmpty"
		elseif extrahearts[pos] == 9 then
			hearttype = "BoneHalf"
		elseif extrahearts[pos] == 10 then
			hearttype = "BoneFull"
		end
		--get overlay
		if #goldhearts > 0 then
			for j = 1, #goldhearts, 1 do
				if goldhearts[j] == pos then
					goldheart = true
				end
			end
		end
		if eternalheart > 0 then
			eternal = true
		end
		if eternal and goldheart then
			overlaytype = "Gold&Eternal"
		elseif eternal then
			overlaytype = "Eternal"
		elseif goldheart then
			overlaytype = "Gold"
		end
	end
	return hearttype, overlaytype
end
loadhealthdata()

sexyrooms:AddCallback(ModCallbacks.MC_POST_PLAYER_INIT, sexyrooms.PostPlayerInit);
sexyrooms:AddCallback(ModCallbacks.MC_POST_UPDATE, sexyrooms.tick);
sexyrooms:AddCallback(ModCallbacks.MC_ENTITY_TAKE_DMG, sexyrooms.takeDamage);
sexyrooms:AddCallback(ModCallbacks.MC_POST_NEW_ROOM , sexyrooms.roomupdate);
sexyrooms:AddCallback(ModCallbacks.MC_POST_RENDER, sexyrooms.displayinfo);
sexyrooms:AddCallback(ModCallbacks.MC_EXECUTE_CMD, sexyrooms.onCmd);
sexyrooms:AddCallback(ModCallbacks.MC_USE_PILL, sexyrooms.onPill);
sexyrooms:AddCallback(ModCallbacks.MC_USE_CARD, sexyrooms.onCard);
sexyrooms:AddCallback(ModCallbacks.MC_USE_ITEM, sexyrooms.use_item);
sexyrooms:AddCallback(ModCallbacks.MC_POST_NEW_LEVEL, sexyrooms.newfloor);