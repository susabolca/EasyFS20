function Name() return 'APVS' end
function Info() return '垂直速度表' end

range_min = -3000 
range_max =  3000

range_val = 0 

last_steps = nil 
function Change(steps)
    local old_steps = last_steps
    last_steps = steps 
    if (old_steps == nil) then
        return 0 
    end
    return old_steps - steps
end

function PortList()
    local portTable = {
        ['PortList'] = {
            {['name'] = 'Steps', ['type'] = 'In', ['valueType'] = 'Int'},
            {['name'] = '(feat) VS', ['type'] = 'Out', ['valueType'] = 'Int'},
        }
    }
    return portTable
end

function Update(portTable)
    local ds = Change(portTable['PortList'][1]) * 100
    range_val = range_val + ds
    if (range_val < range_min) then
        range_val = range_min
    elseif (range_val > range_max) then
        range_val = range_max
    end
    portTable['PortList'][2] = range_val
    return portTable 
end
