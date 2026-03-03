--=====================================================
-- Food Delivery | Client
--=====================================================

local onDuty = false
local currentJob = nil
local foodCollected = false

local jobPed
local storePed, storeBlip
local deliveryPed, deliveryBlip

--==============================
-- Notify
--==============================
local function Notify(msg, type)
    lib.notify({
        title = 'Food Delivery',
        description = msg,
        type = type or 'inform'
    })
end

--==============================
-- Clear Job
--==============================
local function ClearJob(full)
    currentJob = nil
    foodCollected = false

    if storePed then DeletePed(storePed) storePed = nil end
    if deliveryPed then DeletePed(deliveryPed) deliveryPed = nil end
    if storeBlip then RemoveBlip(storeBlip) storeBlip = nil end
    if deliveryBlip then RemoveBlip(deliveryBlip) deliveryBlip = nil end

    if full then
        Notify("You are now off duty", "error")
    end
end

--==============================
-- Job Ped (On / Off Duty)
--==============================
CreateThread(function()
    lib.requestModel(Config.JobPed.model)

    jobPed = CreatePed(
        0,
        Config.JobPed.model,
        Config.JobPed.coords.xyz,
        Config.JobPed.coords.w,
        false,
        false
    )

    FreezeEntityPosition(jobPed, true)
    SetEntityInvincible(jobPed, true)
    SetBlockingOfNonTemporaryEvents(jobPed, true)

    exports.ox_target:addLocalEntity(jobPed, {
        {
            label = "Go On Duty",
            icon = "fa-solid fa-burger",
            canInteract = function()
                return not onDuty
            end,
            onSelect = function()
                onDuty = true
                Notify("You are now on duty", "success")
                StartJob()
            end
        },
        {
            label = "Go Off Duty",
            icon = "fa-solid fa-xmark",
            canInteract = function()
                return onDuty
            end,
            onSelect = function()
                onDuty = false
                ClearJob(true)
            end
        }
    })
end)

--==============================
-- Start Job
--==============================
function StartJob()
    if not onDuty or currentJob then return end

    SetTimeout(math.random(8000, 15000), function()
        if not onDuty or currentJob then return end

        lib.registerContext({
            id = 'food_delivery_request',
            title = 'New Food Order',
            options = {
                {
                    title = 'Accept Order',
                    icon = 'check',
                    onSelect = function()
                        TriggerEvent('fooddelivery:acceptOrder')
                    end
                },
                {
                    title = 'Decline Order',
                    icon = 'xmark',
                    onSelect = function()
                        Notify("Order declined", "error")
                        StartJob()
                    end
                }
            }
        })

        lib.showContext('food_delivery_request')
    end)
end

RegisterNetEvent('fooddelivery:acceptOrder', function()
    if currentJob then return end

    currentJob = {
        store = Config.FoodStores[math.random(#Config.FoodStores)],
        delivery = Config.DeliveryLocations[math.random(#Config.DeliveryLocations)]
    }

    Notify("Order accepted. Go collect food!", "success")
    SpawnStorePed()
end)

--==============================
-- Store Ped
--==============================
function SpawnStorePed()
    lib.requestModel('s_m_y_chef_01')

    storePed = CreatePed(
        0,
        's_m_y_chef_01',
        currentJob.store.ped.xyz,
        currentJob.store.ped.w,
        false,
        false
    )

    FreezeEntityPosition(storePed, true)
    SetEntityInvincible(storePed, true)

    storeBlip = AddBlipForCoord(currentJob.store.ped.xyz)
    SetBlipSprite(storeBlip, 280)
    SetBlipColour(storeBlip, 1)
    SetBlipRoute(storeBlip, true)

    exports.ox_target:addLocalEntity(storePed, {
        {
            label = "Collect Food",
            icon = "fa-solid fa-box",
            canInteract = function()
                return not foodCollected
            end,
            onSelect = function()
                foodCollected = true
                TriggerServerEvent('fooddelivery:giveItem')

                Notify("Food collected. Deliver it!", "success")

                if storeBlip then
                    RemoveBlip(storeBlip)
                    storeBlip = nil
                end

                SpawnDeliveryPed()
            end
        }
    })
end

--==============================
-- Delivery Ped + Location
--==============================
function SpawnDeliveryPed()
    local model = Config.DeliveryPeds[math.random(#Config.DeliveryPeds)]
    lib.requestModel(model)

    local loc = currentJob.delivery

    deliveryPed = CreatePed(
        0,
        model,
        loc.x, loc.y, loc.z - 1.0,
        math.random(0, 360),
        false,
        false
    )

    FreezeEntityPosition(deliveryPed, true)
    SetEntityInvincible(deliveryPed, true)

    -- 🔥 DELIVERY BLIP (FIX)
    deliveryBlip = AddBlipForCoord(loc)
    SetBlipSprite(deliveryBlip, 1)
    SetBlipColour(deliveryBlip, 2)
    SetBlipRoute(deliveryBlip, true)

    exports.ox_target:addLocalEntity(deliveryPed, {
        {
            label = "Deliver Food",
            icon = "fa-solid fa-house",
            onSelect = function()
                local dist = #(GetEntityCoords(PlayerPedId()) - loc)
                TriggerServerEvent('fooddelivery:finish', dist)
            end
        }
    })
end

--==============================
-- Server Success
--==============================
RegisterNetEvent('fooddelivery:success', function(pay)
    Notify("Delivery completed! Earned $" .. pay, "success")
    ClearJob(false)

    if onDuty then
        SetTimeout(2000, function()
            StartJob()
        end)
    end
end)