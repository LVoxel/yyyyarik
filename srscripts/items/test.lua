local sexyrooms = SRMod

sexyrooms.TESTUM = Isaac.GetItemIdByName("TESTUM")
local d_damg = 0.33

local game = Game()
local FIRE_CHANCE = 0.3
local FIRE_LENGHT = 3
local INTERVAL = 20

local playerCount = game:GetNumPlayers()

function sexyrooms:EvaluateCache(cacheFlags)
    for playerIndex = 0, playerCount - 1 do
        local player = Isaac.GetPlayer(playerIndex)

        if cacheFlags & CacheFlag.CACHE_DAMAGE == CacheFlag.CACHE_DAMAGE then
            local i_count = player:GetCollectibleNum(sexyrooms.TESTUM)
            local damage_plus = d_damg * i_count
            player.Damage = player.Damage + damage_plus
        end
    end

end

function sexyrooms:FireAspect()

    for playerIndex = 0, playerCount - 1 do
        local player = Isaac.GetPlayer(playerIndex)
        local copyCount = player:GetCollectibleNum(sexyrooms.TESTUM)
    end
end

sexyrooms:AddCallback(ModCallbacks.MC_EVALUATE_CACHE, sexyrooms.EvaluateCache)