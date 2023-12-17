local sexyrooms = SRMod
local game = Game()
local json = require("json")
local isClear = false

sexyrooms.ROOM_PLACEHOLDER = {
	VARIANT = Isaac.GetEntityVariantByName("DoorPlaceholder")
}

local function SpawnPlaceholder(pos)
	player = Isaac.GetPlayer(0)
	-- print("Spawned at ", pos, " : ", sexyrooms.ROOM_PLACEHOLDER.VARIANT )
	return Isaac.Spawn(1000, sexyrooms.ROOM_PLACEHOLDER.VARIANT, 0, pos, Vector(0,0), player)
	-- placeholder:GetSprite():Play("BaseAnim", false)
end

local function PlaceholderManagement()
	room = game:GetRoom()
	door_slot = 0
	--print(DoorSlot.NUM_DOOR_SLOTS)
	while door_slot < DoorSlot.NUM_DOOR_SLOTS do
		if room:IsDoorSlotAllowed(door_slot) then
			--room:RemoveDoor(door_slot)
			door = room:GetDoor(door_slot)
			if door ~= nil then -- Vérifie qu'une porte existe
				-- print(door.Position, " any kind of door")
				if door:IsRoomType(RoomType.ROOM_SUPERSECRET) or door:IsRoomType(RoomType.ROOM_SECRET) then -- Et l'affiche que si il n'y a pas de vraie porte
					--door:SpawnDust()
					SpawnPlaceholder(door.Position)
				end
			else
				-- C'est une position possible pour afficher une porte
				SpawnPlaceholder(room:GetDoorSlotPosition(door_slot)) 
			end
		end
		door_slot = door_slot + 1
	end
end


local isEnabled = true 


function sexyrooms:onNewRoom()

	isClear = game:GetRoom():IsClear()
	if  isClear and game:GetRoom():GetAliveEnemiesCount() == 0 and game:GetRoom():GetType() ~= RoomType.ROOM_BOSS and isEnabled then
		PlaceholderManagement()
	end
end

sexyrooms:AddCallback(ModCallbacks.MC_POST_NEW_ROOM, sexyrooms.onNewRoom)




function sexyrooms:onClearedRoom(RNG, pos)
	if game:GetRoom():IsClear() ~= isClear and isEnabled then
		isClear = game:GetRoom():IsClear() 
		if game:GetRoom():GetType() ~= RoomType.ROOM_BOSS then
			PlaceholderManagement()
		end
	end
end

sexyrooms:AddCallback(ModCallbacks.MC_POST_UPDATE, sexyrooms.onClearedRoom)


function sexyrooms:inputManagement(RNG, pos)
	if Input.IsButtonTriggered(Keyboard.KEY_F3,0) then
		isEnabled = not isEnabled 
		if isClear and game:GetRoom():GetAliveEnemiesCount() == 0 and game:GetRoom():GetType() ~= RoomType.ROOM_BOSS and isEnabled then
			PlaceholderManagement()
		else
			for i,entity in pairs(Isaac.GetRoomEntities()) do
				if entity.Type == 1000 and entity.Variant == sexyrooms.ROOM_PLACEHOLDER.VARIANT then
					entity:Remove()
				end
			end 
		end
	end
end

sexyrooms:AddCallback(ModCallbacks.MC_POST_RENDER, sexyrooms.inputManagement)



function sexyrooms:onPlayerInit(player)

	local isEnabled = json.decode(sexyrooms:LoadData())
	if isEnabled == nil then isEnabled = true end
	
end

sexyrooms:AddCallback(ModCallbacks.MC_POST_PLAYER_INIT, sexyrooms.onPlayerInit)

function sexyrooms:onGameExit()
	sexyrooms:SaveData(json.encode(isEnabled))
end

sexyrooms:AddCallback(ModCallbacks.MC_PRE_GAME_EXIT, sexyrooms.onGameExit)