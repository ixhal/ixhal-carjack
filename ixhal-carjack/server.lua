Framework = Config.Framework == 'qbcore' and exports['qb-core']:GetCoreObject() or Config.Framework == 'esxlegacy' and exports['es_extended']:getSharedObject() or nil

if Config.Framework == 'qbcore' then
    Framework.Functions.CreateUseableItem(Config.Item_Name, function(source,item)
        TriggerClientEvent('client:UseCarJack', source)
    end)
elseif Config.Framework == 'esxlegacy' then
    Framework.RegisterUsableItem(Config.Item_Name, function(source,item)
        TriggerClientEvent('client:UseCarJack', source)
    end)
end

RegisterNetEvent('ixhal-carjack:server:AddStateBagToEntity', function(net, key, value)
    local entity = NetworkGetEntityFromNetworkId(net)
    if DoesEntityExist(entity) then Entity(entity).state[key] = value end
end)

RegisterNetEvent('ixhal-carjack:server:DeleteEntity', function(net)
    local entity = NetworkGetEntityFromNetworkId(net)
    if DoesEntityExist(entity) then DeleteEntity(entity) end
end)