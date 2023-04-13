function Name() return 'APALT' end
function Info() return '高度表' end

range_min = 0
range_max = 50000 

range_val = range_min 

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
            {['name'] = '(feet) ALT', ['type'] = 'Out', ['valueType'] = 'Int'},
            {['name'] = '(meter*65536) ALT', ['type'] = 'Out', ['valueType'] = 'Int'},
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
    portTable['PortList'][3] = math.ceil(range_val * 0.3048 * 65536)
    return portTable 
end
