local QBCore = exports['qb-core']:GetCoreObject()
local isCallingCustomer = false

RegisterNetEvent("vivify_trapping:client:useTrapPhone")
AddEventHandler("vivify_trapping:client:useTrapPhone", function()
    if isCallingCustomer then
        QBCore.Functions.Notify("You can only call one customer at a time.", "error")
        return
    end

    isCallingCustomer = true
    local playerPed = PlayerPedId()
    TaskStartScenarioInPlace(playerPed, "WORLD_HUMAN_STAND_MOBILE", 0, true)
    Wait(Config.AnimationTime)
    ClearPedTasks(playerPed)
    QBCore.Functions.Notify("Wait for your customer to approach.", "success")

    local waitTime = math.random(Config.MinWaitTime, Config.MaxWaitTime)
    Wait(waitTime)

    local playerCoords = GetEntityCoords(playerPed)
    local randomModel = Config.PedModels[math.random(#Config.PedModels)]
    local pedModel = GetHashKey(randomModel)

    RequestModel(pedModel)
    while not HasModelLoaded(pedModel) do
        Wait(0)
    end

    local angle = math.random() * 2 * math.pi
    local offsetX = math.cos(angle) * Config.SpawnDistance
    local offsetY = math.sin(angle) * Config.SpawnDistance
    local spawnCoords = vector3(playerCoords.x + offsetX, playerCoords.y + offsetY, playerCoords.z)

    local customerPed = CreatePed(4, pedModel, spawnCoords.x, spawnCoords.y, spawnCoords.z, 0.0, true, true)
    TaskGoToCoordAnyMeans(customerPed, playerCoords.x, playerCoords.y, playerCoords.z, 1.0, 0, 0, 786603, 0xbf800000)

    CreateThread(function()
        while true do
            Wait(500)
            local customerCoords = GetEntityCoords(customerPed)
            local playerCoords = GetEntityCoords(playerPed)
            local distance = #(playerCoords - customerCoords)

            if distance <= Config.PedStopDistance then
                ClearPedTasks(customerPed)
                TaskStandStill(customerPed, -1)

                local pedHeading = GetHeadingFromVector_2d(customerCoords.x - playerCoords.x, customerCoords.y - playerCoords.y)
                TaskTurnPedToFaceEntity(playerPed, customerPed, -1)
                Wait(1000)

                RequestAnimDict("mp_common")
                while not HasAnimDictLoaded("mp_common") do
                    Wait(100)
                end

                TaskPlayAnim(playerPed, "mp_common", "givetake2_a", 8.0, -8, 2000, 0, 1, 0,0,0)
	            TaskPlayAnim(customerPed, "mp_common", "givetake2_a", 8.0, -8, 2000, 0, 1, 0,0,0)

                Wait(3000)

                ClearPedTasksImmediately(playerPed)
                ClearPedTasksImmediately(customerPed)

                if math.random(1, 100) <= Config.AlertChance then
                    exports['ps-dispatch']:DrugSale()
                end

                TriggerServerEvent("vivify_trapping:server:completeTransaction", NetworkGetNetworkIdFromEntity(customerPed))

                isCallingCustomer = false

                TaskWanderStandard(customerPed, 10.0, 10)
                Wait(15000)
                DeleteEntity(customerPed)
                
                break
            end
        end
    end)
end)

RegisterCommand("trap", function()
    TriggerEvent("vivify_trapping:client:useTrapPhone")
end, false)