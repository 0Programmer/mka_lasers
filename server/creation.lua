function round(num, numDecimalPlaces) return tonumber(string.format('%.'.. numDecimalPlaces .. 'f', num)) end
function roundVec(vec, numDecimalPlaces) return vector3(round(vec.x, numDecimalPlaces), round(vec.y, numDecimalPlaces), round(vec.z, numDecimalPlaces)) end
function printoutHeader(name) return '-- Name: ' .. (name or '') .. ' | ' .. os.date('!%Y-%m-%dT%H:%M:%SZ') end

RegisterNetEvent('mka_lasers:save', function(laser)
    if not exports.inf_core:HasPermission(source, 'support') then return end
    local resname = GetCurrentResourceName()
    local txt = LoadResourceFile(resname, 'lasers.txt') or ''
    local newTxt = txt .. parseLaser(laser)
    SaveResourceFile(resname, 'lasers.txt', newTxt, -1)
end)

function parseLaser(laser)
    local out = printoutHeader(laser.name) .. '\n'
    out = out .. 'local laser = exports.mka_lasers:createLaser(\n'

    -- Origin point
    if #laser.originPoints == 1 then
        out = out .. string.format('    %s,\n', roundVec(laser.originPoints[1], 3))
    else
        out = out .. '    {\n'
        for i, originPoint in ipairs(laser.originPoints) do
            out = out .. string.format('        %s', roundVec(originPoint, 3))
            if i < #laser.originPoints then out = out .. ',\n' else out = out .. '\n' end
        end
        out = out .. '    },\n'
    end

    -- Target points
    out = out .. '    {\n'
    for i, targetPoint in ipairs(laser.targetPoints) do
        out = out .. string.format('        %s', roundVec(targetPoint, 3))
        if i < #laser.targetPoints then out = out .. ',\n' else out = out .. '\n' end
    end
    out = out .. '    },\n'

    -- Options
    out = out .. '    {\n'
    out = out .. string.format('        travelTimeBetweenTargets = {%.3f, %.3f},\n',
        laser.travelTimeBetweenTargets[1], laser.travelTimeBetweenTargets[2])
    out = out .. string.format('        waitTimeAtTargets = {%.3f, %.3f},\n',
        laser.waitTimeAtTargets[1], laser.waitTimeAtTargets[2])
    if #laser.originPoints == 1 then
        out = out .. string.format('        randomTargetSelection = %s,\n', tostring(laser.randomTargetSelection))
    end
    if laser.name then
        out = out .. string.format('        name = \'%s\'\n', laser.name)
    end
    out = out .. '    }\n'

    out = out .. ')\n\n'
    return out
end

lib.addCommand('lasers', {
    help = 'Open de laser creator',
	restricted = 'group.admin',
	params = {
		{ name = 'option', type = 'string', help = 'start, end, save', optional = true },
	}
}, function(source, args)
	if not args.option then TriggerClientEvent('ox_lib:notify', source, { type = 'error', description = 'You need to specify an option!' }) return end
	TriggerClientEvent('mka_lasers:client:startCreation', source, args.option)
end)