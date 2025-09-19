local maxDistance = 50.0
local laserPointRadius = 0.1
local originPoints, targetPoints
local originRedoStack, targetRedoStack
local inOriginMode = false
local creationEnabled = false
local snapModes = {"Default", "Grid", "Surface"}
local currentSnap = 0

RegisterNetEvent('mka_lasers:client:startCreation', function(option)
    if option == 'start' and not creationEnabled then
        creationEnabled = true
        inOriginMode = true
        startCreation()
        refreshTextUI()
    elseif option == 'end' and creationEnabled then
        creationEnabled = false
        lib.hideTextUI()
    elseif option == 'save' and creationEnabled then
        if not originPoints or not targetPoints then return end
        local name, randomTargetSelect = getConfigurationInput()
        if not name then return end
        TriggerServerEvent('mka_lasers:save', {
            name = name,
            originPoints = originPoints,
            targetPoints = targetPoints,
            travelTimeBetweenTargets = {1.0, 1.0},
            waitTimeAtTargets = {0.0, 0.0},
            randomTargetSelection = randomTargetSelect
        })
        creationEnabled = false
        lib.hideTextUI()
    end
end)

function refreshTextUI()
    lib.showTextUI(
        '**Laser Creator Controls**  \n' ..
        '[**E**] - Place Point  \n' ..
        '[**X**] - Switch Mode (**' .. tostring(inOriginMode and 'Origin' or 'Target') .. '**)  \n' ..
        '[**LEFT SHIFT**] - Undo Point  \n' ..
        '[**CAPSLOCK**] - Redo Point  \n' ..
        '[**ALT**] - Snapping Mode (**' .. tostring(snapModes[currentSnap+1]) .. '**)'
    )
end

function startCreation()
    if not creationEnabled then return end
    originPoints, targetPoints = {}, {}
    originRedoStack, targetRedoStack = {}, {}

    Citizen.CreateThread(function()
        while creationEnabled do
            if IsControlJustReleased(0, 73) then -- X
                inOriginMode = not inOriginMode
                refreshTextUI()
            end

            if IsControlJustReleased(0, 21) then -- LEFT SHIFT
                undoLastPoint()
            end

            if IsControlJustReleased(0, 171) then -- CAPSLOCK
                redoLastPoint()
            end

            if IsControlJustReleased(0, 19) then -- ALT
                currentSnap = (currentSnap + 1) % 3
                refreshTextUI()
            end

            drawWarnings()
            drawPoints()
            drawLines()
            if inOriginMode then 
                handleLaserOriginPoint() 
            else 
                handleLaserTargetPoints() 
            end
            Wait(0)
        end
    end)
end

function handleLaserOriginPoint()
    local point = handlePoint(0, 255, 0, 255)
    if point then 
        originPoints[#originPoints+1] = point 
        originRedoStack = {}
        print('Add point to laser originPoints:', point) 
    end
end

function handleLaserTargetPoints()
    local point = handlePoint(255, 0, 0, 255)
    if point then 
        targetPoints[#targetPoints+1] = point 
        targetRedoStack = {}
        print('Add point to laser targetPoints:', point) 
    end
end

function snapGrid(vec, step)
    local function snap(value)
        return math.floor((value / step) + 0.5) * step
    end
    return vector3(
        vec.x,
        vec.y,
        snap(vec.z)
    )
end

function handlePoint(r, g, b, a)
    local hit, pos, _, normal = RayCastGamePlayCamera(maxDistance)
    if hit then
        if currentSnap == 1 then
            pos = snapGrid(pos, 0.1)
        elseif currentSnap == 2 then
            pos = pos + normal * 0.01
        end
        DrawSphereMarker(pos, laserPointRadius, r, g, b, a)
        DrawText3D(pos.x, pos.y, pos.z + 0.05, string.format("%.2f", pos.z))
        if IsControlJustReleased(0, 51) then -- E
            return pos
        end
    end
end

function undoLastPoint()
    if inOriginMode and #originPoints > 0 then
        local point = table.remove(originPoints, #originPoints)
        table.insert(originRedoStack, point)
        print("Undo origin point")
    elseif not inOriginMode and #targetPoints > 0 then
        local point = table.remove(targetPoints, #targetPoints)
        table.insert(targetRedoStack, point)
        print("Undo target point")
    end
end

function redoLastPoint()
    if inOriginMode and #originRedoStack > 0 then
        local point = table.remove(originRedoStack, #originRedoStack)
        table.insert(originPoints, point)
        print("Redo origin point")
    elseif not inOriginMode and #targetRedoStack > 0 then
        local point = table.remove(targetRedoStack, #targetRedoStack)
        table.insert(targetPoints, point)
        print("Redo target point")
    end
end

function drawWarnings()
    if not originPoints or not targetPoints then return end
    if #originPoints > 1 and #originPoints ~= #targetPoints then
        local pos = originPoints[#originPoints] or targetPoints[#targetPoints]
        DrawMarker(0, pos.x, pos.y, pos.z + 0.35, 0, 0, 0, 0, 0, 0, 0.3, 0.2, 0.15, 255, 0, 0, 150, false, true, 2, nil, nil, false)
        DrawText3D(pos.x, pos.y, pos.z + 0.2, "~r~Mismatch, Origins & Targets must be equal\nIf there is more then one origin point.")
    end
end

function drawPoints()
    for _, originPoint in ipairs(originPoints) do
        DrawSphereMarker(originPoint, laserPointRadius, 0, 255, 0, 255)
    end
    for _, targetPoint in ipairs(targetPoints) do
        DrawSphereMarker(targetPoint, laserPointRadius, 255, 0, 0, 255)
    end
end

function drawLines()
    if not originPoints or #originPoints == 0 or not targetPoints or #targetPoints == 0 then return end
    if #originPoints == 1 then
        for _, targetPoint in ipairs(targetPoints) do
            DrawLine(originPoints[1].x, originPoints[1].y, originPoints[1].z, targetPoint.x, targetPoint.y, targetPoint.z, 255, 0, 0, 255)
        end
    else
        for i=1, #originPoints do
            if i <= #targetPoints then
                DrawLine(originPoints[i].x, originPoints[i].y, originPoints[i].z, targetPoints[i].x, targetPoints[i].y, targetPoints[i].z, 255, 0, 0, 255)
            end
        end
    end
end