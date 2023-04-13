function Name() return 'RadioNav' end
function Info() return 'Radio Nav' end

freq_min = 108
freq_max = 118

freq = freq_min

last_steps = nil 
function Change(steps)
    local old_steps = last_steps
    last_steps = steps 
    if (old_steps == nil) then
        return 0 
    end
    return old_steps - steps
end

function BcdEncode(v)
    num = math.ceil(v) % 10000
    bcd = tonumber(string.format("%d", num), 16)
    return bcd
end

function PortList()
    local portTable = {
        ['PortList'] = {
            {['name'] = 'Change', ['type'] = 'In', ['valueType'] = 'Int'},
            {['name'] = 'Freq', ['type'] = 'Out', ['valueType'] = 'String'},
            {['name'] = 'BCD', ['type'] = 'Out', ['valueType'] = 'Int'}
        }
    }
    return portTable
end

function Update(portTable)
    local df = Change(portTable['PortList'][1]) * 0.05
   
    freq = freq + df 
    if (freq < freq_min) then
        freq = freq_min 
    elseif (freq > freq_max) then
        freq = freq_max
    end

    portTable['PortList'][2] = string.format("%.2f", freq) 
    portTable['PortList'][3] = BcdEncode(freq*100)
    return portTable 
end
