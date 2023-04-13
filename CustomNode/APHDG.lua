function Name() return 'APHDG' end
function Info() return 'AP 方向配置' end

--hdg_min = 1
hdg_max = 360

hdg = hdg_max

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
            {['name'] = 'HDG', ['type'] = 'Out', ['valueType'] = 'Int'},
            {['name'] = '(degree*65535/360) HDG', ['type'] = 'Out', ['valueType'] = 'Int'},
        }
    }
    return portTable
end

function Update(portTable)
    local ds = Change(portTable['PortList'][1])
    hdg = (hdg + ds) % hdg_max
    portTable['PortList'][2] = hdg 
    portTable['PortList'][3] = math.floor(hdg * 65536 / 360) & 0xFFFF
    return portTable 
end
