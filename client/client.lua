local Laser = {}
local playerState = LocalPlayer.state
local ShapeTestRay = StartShapeTestRay or StartExpensiveSynchronousShapeTestLosProbe
local function RayCast(origin, destination, flags)
    local ray = ShapeTestRay(origin.x, origin.y, origin.z, destination.x, destination.y, destination.z, flags, nil, 0)
    return GetShapeTestResult(ray)
end

local function randomFloat(lower, greater) return lower + math.random() * (greater - lower); end
local function drawLaser(origin, destination, r, g, b, a)
    DrawLine(origin.x, origin.y, origin.z, destination.x, destination.y, destination.z, r, g, b, a)
    if GlobalState.blackOut or playerState.syncblackOut then
        -- DrawLine is not blacked out by SetArtificialLightsState with this method
        DrawSphere(origin.x, origin.y, origin.z, 0.000001, 0, 0, 255, 0.0)
    end
end

local function calculateCurrentPoint(fromPoint, toPoint, deltaTime, travelTimeBetweenTargets)
    local desiredDirection = toPoint - fromPoint
    local desiredDirectionDist = #desiredDirection
    local percentOfTravelTime = deltaTime / (travelTimeBetweenTargets * 1000)
    local distance = math.min(desiredDirectionDist * percentOfTravelTime, desiredDirectionDist)
    return fromPoint + (norm(desiredDirection) * distance)
end

local function getNextToIndex(fromIndex, targetPointCount, randomTargetSelection)
    local toIndex = fromIndex
    if randomTargetSelection then
        while toIndex == fromIndex do toIndex = math.random(1, targetPointCount) end
    else
        toIndex = (fromIndex % targetPointCount) + 1
    end
    return toIndex
end

function Laser.new(originPoint, targetPoints, options)
    local self = {}
    options = options or {}
    if options.color and #options.color ~= 4 then
        print('^3Warning: Laser color must have four values {r, g, b, a} reverting to {255, 0, 0, 255}^7')
        options.color = {255, 0, 0, 255}
    end
    self.name = options.name
    local visible = true
    local moving = true
    local active = false
    local r, g, b, a = 255, 0, 0, 255
    if options.color then r, g, b, a = table.unpack(options.color) end
    local extensionEnabled = false
    if options.extensionEnabled ~= nil then extensionEnabled = options.extensionEnabled end
    local randomTargetSelection = true
    if options.randomTargetSelection ~= nil then randomTargetSelection = options.randomTargetSelection end
    local maxDistance = options.maxDistance or 20.0
    local travelTimeBetweenTargets = options.travelTimeBetweenTargets or {}
    local minTravelTimeBetweenTargets = travelTimeBetweenTargets[1] or 1.0
    local maxTravelTimeBetweenTargets = travelTimeBetweenTargets[2] or 1.0
    local waitTimeAtTargets = options.waitTimeAtTargets or {}
    local minWaitTimeAtTargets = waitTimeAtTargets ~= nil and waitTimeAtTargets[1] or 0.0
    local maxWaitTimeAtTargets = waitTimeAtTargets ~= nil and waitTimeAtTargets[2] or 0.0
    local onPlayerHitCb, playerBeingHit = nil, false
    local onDestroyCb = nil

    function self.getActive() return active end
    function self.setActive(toggle) if active == toggle then return end active = toggle if active then if type(originPoint) == 'vector3' then self._startLaser() elseif type(originPoint) == 'table' then self._startMultiOriginLaser() end end end
    function self.getVisible() return visible end
    function self.setVisible(toggle) if visible == toggle then return end visible = toggle end
    function self.getMoving() return moving end
    function self.setMoving(toggle) if moving == toggle then return end moving = toggle end
    function self.getColor() return r, g, b, a end
    function self.setColor(_r, _g, _b, _a) if type(_r) ~= 'number' or type(_g) ~= 'number' or type(_b) ~= 'number' or type(_a) ~= 'number' then error('(r, g, b, a) must all be integers ' .. string.format('{r = %s, g = %s, b = %s, a = %s}', _r, _g, _b, _a)) end r, g, b, a = _r, _g, _b, _a end
    function self.onPlayerHit(cb) onPlayerHitCb = cb playerBeingHit = false end
    function self.clearOnPlayerHit() onPlayerHitCb = nil playerBeingHit = false end

    function self._onPlayerHitTest(origin, destination)
        local _, hit, hitPos, _, hitEntity = RayCast(origin, destination, 12)
        local newPlayerBeingHit = hit and hitEntity == PlayerPedId()
        if newPlayerBeingHit ~= playerBeingHit then
            playerBeingHit = newPlayerBeingHit
            local success, err = pcall(function()
                onPlayerHitCb(playerBeingHit, hitPos)
            end)
            if not success then
                print(('^3Warning: OnPlayerHit callback failed: \'%s\', removed callback for laser \'%s\'.^7'):format(err, self.name or 'unknown (no name set)'))
                onPlayerHitCb = nil
                playerBeingHit = false
            end
        end
    end

    function self._startLaser()
        if #targetPoints == 1 then
            Citizen.CreateThread(function ()
                local direction = norm(targetPoints[1] - originPoint)
                local destination = originPoint + direction * maxDistance
                while active do
                    if visible then
                        drawLaser(originPoint, destination, r, g, b, a)
                        if onPlayerHitCb then self._onPlayerHitTest(originPoint, destination) end
                    end
                    Wait(0)
                end
            end)
        else
            Citizen.CreateThread(function ()
                local deltaTime = 0
                local fromIndex = 1
                local toIndex = 2
                if randomTargetSelection then
                    fromIndex = math.random(1, #targetPoints)
                    toIndex = getNextToIndex(fromIndex, #targetPoints, randomTargetSelection)
                end
                local waiting = false
                local waitTime = 0
                local currentTravelTime = randomFloat(minTravelTimeBetweenTargets, maxTravelTimeBetweenTargets)
                while active do
                    local fromPoint = targetPoints[fromIndex]
                    local toPoint = targetPoints[toIndex]
                    local currentPoint = calculateCurrentPoint(fromPoint, toPoint, deltaTime, currentTravelTime)
                    local currentDirection = norm(currentPoint - originPoint)
                    if visible then
                        local destination = currentPoint
                        if extensionEnabled then destination = originPoint + currentDirection * maxDistance end
                        drawLaser(originPoint, destination, r, g, b, a)
                        if onPlayerHitCb then self._onPlayerHitTest(originPoint, destination) end
                    end
                    if moving and not waiting then
                        if #(toPoint - currentPoint) < 0.001 then
                            deltaTime = 0
                            fromIndex = toIndex
                            toIndex = getNextToIndex(fromIndex, #targetPoints, randomTargetSelection)
                            currentTravelTime = randomFloat(minTravelTimeBetweenTargets, maxTravelTimeBetweenTargets)
                            if minWaitTimeAtTargets > 0.0 or maxWaitTimeAtTargets > 0.0 then
                                waiting = true
                                waitTime = randomFloat(minWaitTimeAtTargets, maxWaitTimeAtTargets) * 1000
                            end
                        end
                        deltaTime = deltaTime + (GetFrameTime() * 1000)
                    elseif waiting then
                        waitTime = waitTime - (GetFrameTime() * 1000)
                        if waitTime <= 0.0 then waiting = false end
                    end
                    Wait(0)
                end
            end)
        end
    end

    function self._startMultiOriginLaser()
        if #originPoint ~= #targetPoints then
            print('^3Warning: Multi-origin laser must have same number of origin and target points^7')
            return
        end
        if #originPoint < 2 or #targetPoints < 2 then
            print('^3Warning: Multi-origin laser must have more than one origin and target points^7')
            return
        end
        Citizen.CreateThread(function ()
            local deltaTime = 0
            local fromIndex = 1
            local toIndex = 2
            local step = 1
            local waiting = false
            local waitTime = 0
            local currentTravelTime = randomFloat(minTravelTimeBetweenTargets, maxTravelTimeBetweenTargets)
            while active do
                local fromTargetPoint = targetPoints[fromIndex]
                local toTargetPoint = targetPoints[toIndex]
                local currentTargetPoint = calculateCurrentPoint(fromTargetPoint, toTargetPoint, deltaTime, currentTravelTime)
                local fromOriginPoint = originPoint[fromIndex]
                local toOriginPoint = originPoint[toIndex]
                local currentOriginPoint = calculateCurrentPoint(fromOriginPoint, toOriginPoint, deltaTime, currentTravelTime)
                if visible then
                    drawLaser(currentOriginPoint, currentTargetPoint, r, g, b, a)
                    if onPlayerHitCb then self._onPlayerHitTest(currentOriginPoint, currentTargetPoint) end
                end
                if moving and not waiting then
                    if #(currentTargetPoint - toTargetPoint) < 0.001 then
                        deltaTime = 0
                        if toIndex == 1 or toIndex == #originPoint then
                            step = step * -1
                            fromIndex = toIndex
                            toIndex = fromIndex + step
                        else
                            fromIndex = fromIndex + step
                            toIndex = toIndex + step
                        end
                        currentTravelTime = randomFloat(minTravelTimeBetweenTargets, maxTravelTimeBetweenTargets)
                        if minWaitTimeAtTargets > 0.0 or maxWaitTimeAtTargets > 0.0 then
                            waiting = true
                            waitTime = randomFloat(minWaitTimeAtTargets, maxWaitTimeAtTargets) * 1000
                        end
                    end
                    deltaTime = deltaTime + (GetFrameTime() * 1000)
                elseif waiting then
                    waitTime = waitTime - (GetFrameTime() * 1000)
                    if waitTime <= 0.0 then waiting = false end
                end
                Wait(0)
            end
        end)
    end

    function self.setOrigin(newOrigin)
        if newOrigin ~= nil then originPoint = newOrigin end
    end

    function self.setTargets(newTargets)
        if newTargets ~= nil then targetPoints = newTargets end
    end

    function self.setTravelTimeBetweenTargets(t)
        if t and #t >= 2 then
            minTravelTimeBetweenTargets = t[1] or minTravelTimeBetweenTargets
            maxTravelTimeBetweenTargets = t[2] or maxTravelTimeBetweenTargets
        end
    end

    function self.setWaitTimeAtTargets(t)
        if t and #t >= 2 then
            minWaitTimeAtTargets = t[1] or minWaitTimeAtTargets
            maxWaitTimeAtTargets = t[2] or maxWaitTimeAtTargets
        end
    end

    function self.setRandomTargetSelection(val)
        if type(val) == 'boolean' then randomTargetSelection = val end
    end

    function self.setExtensionEnabled(val)
        if type(val) == 'boolean' then extensionEnabled = val end
    end

    function self.setMaxDistance(d)
        if type(d) == 'number' then maxDistance = d end
    end

    function self.destroy()
        active = false
        visible = false
        moving = false
    end

    return self
end

local LaserWrapper = {}
LaserWrapper.__index = LaserWrapper

local _registry = {}
local _nameRegistry = {}
local _nextId = 1

function LaserWrapper.new(origin, targets, options)
    local self = setmetatable({}, LaserWrapper)
    self._id = _nextId
    _nextId = _nextId + 1

    self._obj = Laser.new(origin, targets, options)

    if options and options.name then
        if _nameRegistry[options.name] ~= nil then
            print(('^3Warning: Laser with name \'%s\' already exists, skipping creation.^7'):format(options.name))
            return nil
        end
        self._name = options.name
        _nameRegistry[self._name] = self._id
    end

    _registry[self._id] = self

    self.Activate = function() if self._obj.setActive then self._obj.setActive(true) end end
    self.Deactivate = function() if self._obj.setActive then self._obj.setActive(false) end end
    self.Toggle = function() if self._obj.getActive and self._obj.setActive then self._obj.setActive(not self._obj.getActive()) end end
    self.GetActive = function() return self._obj.getActive and self._obj.getActive() end
    self.GetVisible = function() return self._obj.getVisible and self._obj.getVisible() end
    self.GetMoving = function() return self._obj.getMoving and self._obj.getMoving() end
    self.SetMoving = function(v) if self._obj.setMoving then self._obj.setMoving(v) end end
    self.SetColor = function(r,g,b,a) if self._obj.setColor then self._obj.setColor(r,g,b,a) end end
    self.GetColor = function() return self._obj.getColor and self._obj.getColor() end
    self.SetVisible = function(v) if self._obj.setVisible then self._obj.setVisible(v) end end

    self.OnPlayerHit = function(cb)
        if self._obj.onPlayerHit then self._obj.onPlayerHit(cb) end
    end
    self.ClearOnPlayerHit = function()
        if self._obj.clearOnPlayerHit then self._obj.clearOnPlayerHit() end
    end

    self.SetOrigin = function(o) if self._obj.setOrigin then self._obj.setOrigin(o) end end
    self.SetTargets = function(t) if self._obj.setTargets then self._obj.setTargets(t) end end
    self.SetTravelTimeBetweenTargets = function(t) if self._obj.setTravelTimeBetweenTargets then self._obj.setTravelTimeBetweenTargets(t) end end
    self.SetWaitTimeAtTargets = function(t) if self._obj.setWaitTimeAtTargets then self._obj.setWaitTimeAtTargets(t) end end
    self.SetRandomTargetSelection = function(v) if self._obj.setRandomTargetSelection then self._obj.setRandomTargetSelection(v) end end
    self.SetExtensionEnabled = function(v) if self._obj.setExtensionEnabled then self._obj.setExtensionEnabled(v) end end
    self.SetMaxDistance = function(d) if self._obj.setMaxDistance then self._obj.setMaxDistance(d) end end

    self.Destroy = function()
        if self._obj.destroy then self._obj.destroy() end
        _registry[self._id] = nil
        if self._name then
            _nameRegistry[self._name] = nil
        end
        return nil
    end

    self.GetId = function() return self._id end
    self.Raw = function() return self._obj end

    return self
end
function CreateLaser(origin, targets, options)
    return LaserWrapper.new(origin, targets, options)
end
exports('createLaser', CreateLaser)
function GetLaserById(id)
    return _registry[id]
end
exports('getLaserById', GetLaserById)
function GetLaserByName(name)
    local id = _nameRegistry[name]
    if id then
        return _registry[id]
    end
    return nil
end
exports('getLaserByName', GetLaserByName)