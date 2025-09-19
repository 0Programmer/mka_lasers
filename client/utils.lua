local pi, sin, cos, abs = math.pi, math.sin, math.cos, math.abs
local function RotationToDirection(rotation)
    local piDivBy180 = pi / 180
    local adjustedRotation = vector3(piDivBy180 * rotation.x, piDivBy180 * rotation.y, piDivBy180 * rotation.z)
    local direction = vector3(-sin(adjustedRotation.z) * abs(cos(adjustedRotation.x)), cos(adjustedRotation.z) * abs(cos(adjustedRotation.x)), sin(adjustedRotation.x))
    return direction
end

function RayCastGamePlayCamera(distance)
    local cameraRotation = GetGameplayCamRot()
    local cameraCoord = GetGameplayCamCoord()
    local direction = RotationToDirection(cameraRotation)
    local destination = vector3(cameraCoord.x + direction.x * distance, cameraCoord.y + direction.y * distance, cameraCoord.z + direction.z * distance)
    local ray = StartShapeTestRay(cameraCoord.x, cameraCoord.y, cameraCoord.z, destination.x, destination.y, destination.z, 1, -1, 0)
    local rayHandle, hit, endCoords, surfaceNormal, entityHit = GetShapeTestResult(ray)
    return hit, endCoords, entityHit, surfaceNormal
end

function getConfigurationInput()
    local input = lib.inputDialog('New Laser Configuration', {
        { type = 'input', label = 'Name', description = 'Give the new laser a name', required = true },
        { type = 'checkbox', label = 'Should the laser randomly select it\'s next target point?', checked = true },
    })
    if not input then return nil end
    local name = input[1]
    local randomTargetSelection = input[2]
    return name, randomTargetSelection
end

function DrawText3D(x, y, z, text)
    local onScreen, _x, _y = World3dToScreen2d(x, y, z)
    local pX, pY, pZ = table.unpack(GetGameplayCamCoords())
    SetTextScale(0.4, 0.4)
    SetTextFont(4)
    SetTextProportional(1)
    SetTextEntry("STRING")
    SetTextCentre(true)
    SetTextColour(255, 255, 255, 255)
    SetTextOutline()
    AddTextComponentString(text)
    DrawText(_x, _y)
end

function DrawSphereMarker(pos, radius, r, g, b, a)
    DrawMarker(28, pos.x, pos.y, pos.z, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, radius, radius, radius, r, g, b, a, false, false, 2, nil, nil, false)
end