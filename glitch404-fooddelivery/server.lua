--=====================================================
-- Food Delivery | Server (MULTI ITEM VERSION)
--=====================================================

local activeOrders = {}

--==============================
-- GIVE FOOD (MULTI ITEMS)
--==============================
RegisterNetEvent('fooddelivery:giveItem', function()
    local src = source

    if activeOrders[src] then
        print('[FoodDelivery] Duplicate giveItem', src)
        return
    end

    local orderItems = {}

    -- generate random order
    for item, data in pairs(Config.FoodItems) do
        local amount = math.random(data.min, data.max)
        if amount > 0 then
            local added = exports.ox_inventory:AddItem(src, item, amount)
            if added then
                orderItems[item] = amount
            else
                print('[FoodDelivery] FAILED to add item', src, item)
            end
        end
    end

    if next(orderItems) == nil then
        print('[FoodDelivery] No items generated for', src)
        return
    end

    activeOrders[src] = orderItems

    print('[FoodDelivery] Order given to', src, json.encode(orderItems))
end)

--==============================
-- FINISH DELIVERY
--==============================
RegisterNetEvent('fooddelivery:finish', function(distance)
    local src = source
    local order = activeOrders[src]

    if not order then
        print('[FoodDelivery] No active order', src)
        return
    end

    if type(distance) ~= 'number' or distance > 10.0 then
        print('[FoodDelivery] Invalid distance', src, distance)
        return
    end

    -- remove all ordered items
    for item, amount in pairs(order) do
        local removed = exports.ox_inventory:RemoveItem(src, item, amount)
        if not removed then
            print('[FoodDelivery] Missing item', src, item)
            return
        end
    end

    activeOrders[src] = nil

    local pay = math.random(Config.Pay.min, Config.Pay.max)
    exports.qbx_core:AddMoney(src, 'cash', pay)

    print('[FoodDelivery] Paid', src, pay)

    TriggerClientEvent('fooddelivery:success', src, pay)
end)

AddEventHandler('playerDropped', function()
    activeOrders[source] = nil
end)