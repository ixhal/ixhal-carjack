Framework = Config.Framework == 'qbcore' and exports['qb-core']:GetCoreObject() or Config.Framework == 'esxlegacy' and exports['es_extended']:getSharedObject() or nil

local function RotationToDirection(rotation)
	local adjustedRotation = 
	{ 
		x = (math.pi / 180) * rotation.x, 
		y = (math.pi / 180) * rotation.y, 
		z = (math.pi / 180) * rotation.z 
	}
	local direction = 
	{
		x = -math.sin(adjustedRotation.z) * math.abs(math.cos(adjustedRotation.x)), 
		y = math.cos(adjustedRotation.z) * math.abs(math.cos(adjustedRotation.x)), 
		z = math.sin(adjustedRotation.x)
	}
	return direction
end

local function RayCastGamePlayCamera(distance, flag, collider, entity)
  if flag == nil then flag = -1 end
  if collider == nil then collider = 1 end
    local ped = entity or GetPlayerPed(-1)
	local cameraRotation = GetGameplayCamRot()
	local cameraCoord = GetGameplayCamCoord()
	local direction = RotationToDirection(cameraRotation)
	local destination = 
	{ 
		x = cameraCoord.x + direction.x * distance, 
		y = cameraCoord.y + direction.y * distance, 
		z = cameraCoord.z + direction.z * distance 
	}
	local ret, hit, endCoords, surfaceNormal, EntityHit = GetShapeTestResult(StartShapeTestRay(cameraCoord.x, cameraCoord.y, cameraCoord.z, destination.x, destination.y, destination.z, flag, ped, collider))
	return ret, hit, endCoords, surfaceNormal, EntityHit
end

local function PlayerHasItem(name)
    if Config.Inventory == 'ox-inventory' then
        return exports.ox_inventory:Search('count', name) > 0
    end
    if Config.Framework == 'qbcore' then
        return Framework.Functions.HasItem(Config.Item_Name, 1)
    elseif Config.Framework == 'esxlegacy' then
        return Framework.SearchInventory(Config.Item_Name, count)
    end
end

local function Notify(txt, notif_type, time)
    if Config.Framework == 'qbcore' then
        Framework.Functions.Notify(txt, notif_type, time)
    elseif Config.Framework == 'esxlegacy' then
        Framework.ShowNotification(txt, notif_type, time)
    end
end

local function RequestNetworkControlOfEntity(entity)
    NetworkRequestControlOfEntity(entity)

    local timeout = 10

    while timeout > 0 and not NetworkHasControlOfEntity(entity) do
        Wait(100)
        timeout = timeout - 1
    end

    timeout = 10
    SetEntityAsMissionEntity(entity, true, true)
    while timeout > 0 and not IsEntityAMissionEntity(entity) do
        Wait(100)
        timeout = timeout - 1
    end
end

local function ShowHelpNotification(msg, thisFrame, beep, duration)
	AddTextEntry('HelpNotification', msg)

	if thisFrame then
		DisplayHelpTextThisFrame('HelpNotification', false)
	else
		if beep == (nil or false) then beep = false else beep = true end
		BeginTextCommandDisplayHelp('HelpNotification')
		EndTextCommandDisplayHelp(0, false, beep, duration or -1)
	end
end

local function JackUpVehicle()
    local vehicle = nil
    local playerPed = PlayerPedId()
    if IsPedInAnyVehicle(playerPed, true) then return end
  
    while vehicle == nil do
        DisableControlAction(1, 140, true)
        DisableControlAction(1, 141, true)
        DisableControlAction(1, 142, true)
        DisablePlayerFiring(PlayerId(), true)
        DisableControlAction(0,24) -- INPUT_ATTACK
        DisableControlAction(0,69) -- INPUT_VEH_ATTACK
        DisableControlAction(0,70) -- INPUT_VEH_ATTACK2
        DisableControlAction(0,92) -- INPUT_VEH_PASSENGER_ATTACK
        DisableControlAction(0,114) -- INPUT_VEH_FLY_ATTACK
        DisableControlAction(0,257) -- INPUT_ATTACK2
        DisableControlAction(0,331) -- INPUT_VEH_FLY_ATTACK2
    
        local ret, hit, endCoords, surfaceNormal, EntityHit = RayCastGamePlayCamera(10.0, 2)
    
        if EntityHit then
            if GetEntityType(EntityHit) == 2 then
                local _, d1 = GetModelDimensions(GetEntityModel(EntityHit))
                local coords = GetEntityCoords(EntityHit)
                coords = vector3(coords.x, coords.y, coords.z + d1.z)
                DrawMarker(20, coords.x, coords.y, coords.z, 0.0, 0.0, 0.0, 180.0, 0.0, 0.0, 0.5, 0.5, 0.5, 0.0, 155, 0, 150, true, true)
                if IsDisabledControlJustPressed(2, 24) then
                    local distance = #(GetEntityCoords(playerPed) - GetEntityCoords(EntityHit))
                    if distance <= 4 then
                        vehicle = EntityHit
                    end
                end
            else
                ret, hit, endCoords, surfaceNormal, EntityHit = RayCastGamePlayCamera(10.0)
                DrawMarker(28, endCoords.x, endCoords.y, endCoords.z, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.09, 0.09, 0.09, 0, 255, 0, 255, false, false)
            end
        end
    
        ShowHelpNotification('Press ~INPUT_ATTACK~ to jack\nPress ~INPUT_AIM~ to cancel')
        
        if IsDisabledControlJustPressed(2, 25) then break end
    
        Wait(0)
    end
    
    if vehicle ~= nil then
        local vehCoords = GetEntityCoords(vehicle)
        local numOfSeats = GetVehicleModelNumberOfSeats(GetEntityModel(vehicle))
        local hasPassanger = false
    
        for i = -1, (numOfSeats -2) do
            if not IsVehicleSeatFree(vehicle, i) then
                hasPassanger = true
                break
            end
        end

        if hasPassanger then Notify("You cant do that when someone is in the vehicle.", "error") return end
    
        local isVehicleJacked = Entity(vehicle).state.CarIsJacked
    
        if isVehicleJacked == true then
            local NetId = VehToNet(vehicle)
            TriggerServerEvent('ixhal-carjack:server:AddStateBagToEntity', NetId, 'CarIsJacked', false)
            TaskTurnPedToFaceEntity(playerPed, vehicle, 1.0)
            local carJackProp = GetClosestObjectOfType(vehCoords.x, vehCoords.y, vehCoords.z, 1.0, GetHashKey('prop_carjack'), false, false, false)
    
            RequestNetworkControlOfEntity(vehicle)
            RequestNetworkControlOfEntity(carJackProp)
            SetEntityAsMissionEntity(vehicle)
    
            FreezeEntityPosition(vehicle, true)
            FreezeEntityPosition(carJackProp, true)
    
            local anim = {dict = 'anim@amb@business@weed@weed_inspecting_lo_med_hi@', lib = 'weed_crouch_checkingleaves_idle_02_inspector'}
            RequestAnimDict(anim.dict); while not HasAnimDictLoaded(anim.dict) do Wait(1) end
            TaskPlayAnim(playerPed, anim.dict, anim.lib, 2.0, -3.5, -1, 1, false, false, false, false)
    
            Wait(1000)
    
            for i = 1, 5, 1 do
                vehCoords = GetEntityCoords(vehicle)
                objCoords = GetEntityCoords(carJackProp)
                TaskPlayAnim(playerPed, anim.dict, anim.lib, 3.5, -3.5, -1, 1, false, false, false, false)
                Wait(2000)
                ClearPedTasks(playerPed)
                SetEntityCoordsNoOffset(vehicle, vehCoords.x, vehCoords.y, (vehCoords.z-0.10), true, false, false, true)
                SetEntityCoordsNoOffset(carJackProp, objCoords.x, objCoords.y, (objCoords.z-0.10), true, false, false, true)
                FreezeEntityPosition(vehicle, true)
                FreezeEntityPosition(carJackProp, true)
            end
    
            TriggerServerEvent('ixhal-carjack:server:DeleteEntity', ObjToNet(carJackProp))

            SetVehicleOnGroundProperly(vehicle)
            FreezeEntityPosition(vehicle, false)
        else
            local hasItem = PlayerHasItem(Config.Item_Name, 1)
    
            if not hasItem then Notify("You need a Car Jack in order to do this.", "error") return end
    
            local NetId = VehToNet(vehicle)
            TriggerServerEvent('ixhal-carjack:server:AddStateBagToEntity', NetId, 'CarIsJacked', true)
            TaskTurnPedToFaceEntity(playerPed, vehicle, 1.0)
    
            RequestModel('prop_carjack'); while not HasModelLoaded('prop_carjack') do Wait(1) end
    
            RequestNetworkControlOfEntity(vehicle)
            SetEntityAsMissionEntity(vehicle)
            local carJackProp = CreateObject(GetHashKey('prop_carjack'), vehCoords.x, vehCoords.y, vehCoords.z-1.1, true, true, true)
    
            SetEntityHeading(carJackProp, (GetEntityHeading(vehicle) - 90.0 ))
            FreezeEntityPosition(vehicle, true)
            FreezeEntityPosition(carJackProp, true)
            SetVehicleOnGroundProperly(vehicle)
    
            local anim = {dict = 'anim@amb@business@weed@weed_inspecting_lo_med_hi@', lib = 'weed_crouch_checkingleaves_idle_02_inspector'}
            RequestAnimDict(anim.dict); while not HasAnimDictLoaded(anim.dict) do Wait(1) end
            TaskPlayAnim(playerPed, anim.dict, anim.lib, 2.0, -3.5, -1, 1, false, false, false, false)

            Wait(500)

            for i = 1, 5, 1 do
                vehCoords = GetEntityCoords(vehicle)
                objCoords = GetEntityCoords(carJackProp)
                TaskPlayAnim(playerPed, anim.dict, anim.lib, 3.5, -3.5, -1, 1, false, false, false, false)
                Wait(2000)
                ClearPedTasks(playerPed)
                SetEntityCoordsNoOffset(vehicle, vehCoords.x, vehCoords.y, (vehCoords.z+0.075), true, false, false, true)
                SetEntityCoordsNoOffset(carJackProp, objCoords.x, objCoords.y, (objCoords.z+0.075), true, false, false, true)
                FreezeEntityPosition(vehicle, true)
                FreezeEntityPosition(carJackProp, true)
            end
        end
    end
end

RegisterNetEvent('client:UseCarJack')
AddEventHandler('client:UseCarJack', JackUpVehicle)

RegisterCommand('car-jack', function()
    TriggerEvent('client:UseCarJack')
end)