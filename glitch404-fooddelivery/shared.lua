Shared = {}

Shared.Noti = function(msg, type)
    lib.notify({
        title = 'Food Delivery',
        description = msg,
        type = type or 'inform'
    })
end