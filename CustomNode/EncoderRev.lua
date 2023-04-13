function Name() return 'EncoderRev' end
function Info() return '编码器反向器' end

-- last received input
last_code = nil 

-- saved value from 0 +/- steps
last_value = 0

function PortList()
    local portTable = {
        ['PortList'] = {
            {['name'] = 'Encoder In', ['type'] = 'In', ['valueType'] = 'Int'},
            {['name'] = 'Encoder Out', ['type'] = 'Out', ['valueType'] = 'Int'}
        }
    }
    return portTable
end

function Update(portTable)
    local vin = portTable['PortList'][1]
    
    if (last_code == nil) then
        last_code = vin
        return
    end
    
    local dv = vin - last_code
    last_code = vin 

    last_value = last_value + dv 

    portTable['PortList'][2] = last_value 
    return portTable 
end

