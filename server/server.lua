local cooldown = {}
RegisterNetEvent('mka_lasers:server:laserDestroyed', function(id)
    local now = os.time()
    for k, v in pairs(cooldown) do
        if v <= now then cooldown[k] = nil end
    end
    if cooldown[id] and cooldown[id] > now then return end
    cooldown[id] = now + 5
    TriggerClientEvent('mka_lasers:client:laserDestroyed', -1, id)
end)