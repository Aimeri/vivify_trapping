local QBCore = exports['qb-core']:GetCoreObject()

QBCore.Functions.CreateUseableItem(Config.ItemName, function(source)
    local xPlayer = QBCore.Functions.GetPlayer(source)
    TriggerClientEvent("vivify_trapping:client:useTrapPhone", source)
end)

RegisterNetEvent("vivify_trapping:server:completeTransaction")
AddEventHandler("vivify_trapping:server:completeTransaction", function(customerNetId)
    local src = source
    local xPlayer = QBCore.Functions.GetPlayer(src)
    local customerPed = NetworkGetEntityFromNetworkId(customerNetId)

    local function GetCops()
        local count = 0
        for _, v in pairs(QBCore.Functions.GetPlayers()) do
            local Player = QBCore.Functions.GetPlayer(v)
            if Player and Player.PlayerData.job.name == "police" and Player.PlayerData.job.onduty then
                count = count + 1
            end
        end
        return count
    end

    local function ApplyCopBonus(price)
        local cops = GetCops()
        if cops > 0 and cops < 3 then
            price = price * 1.2
        elseif cops >= 3 and cops <= 6 then
            price = price * 1.5
        elseif cops >= 7 then
            price = price * 2.0
        end
        return math.floor(price)
    end

    for _, drug in ipairs(Config.Drugs) do
        local itemCount = xPlayer.Functions.GetItemByName(drug.name)
        if itemCount and itemCount.amount > 0 then
            local amountToSell = math.random(1, math.min(6, itemCount.amount))
            local pricePerItem = math.random(drug.minPrice, drug.maxPrice)
            local totalPrice = amountToSell * pricePerItem

            local bonusPrice = ApplyCopBonus(totalPrice)

            if xPlayer.Functions.RemoveItem(drug.name, amountToSell) then
                xPlayer.Functions.AddMoney("black_money", bonusPrice)
                TriggerClientEvent("QBCore:Notify", src, string.format("Sold %d %s for $%d.", amountToSell, drug.name, bonusPrice), "success")
            else
                TriggerClientEvent("QBCore:Notify", src, "Transaction failed. Insufficient items.", "error")
            end
            break
        end
    end
end)
