function Name() return 'Encoder10' end
function Info() return '编码器, 10ms间隔, 单倍速' end

-- last received input
last_code = 0

-- last clock in (ms, percis 10ms) 
last_tick = os.clock()

-- in fast mode count
keep_cnt = 0

-- saved value from 0 +/- steps
last_value = 0

function PortList()
    local portTable = {
        ['PortList'] = {
            {['name'] = 'Encoder', ['type'] = 'In', ['valueType'] = 'Int'},
            {['name'] = 'Steps', ['type'] = 'Out', ['valueType'] = 'Int'}
        }
    }
    return portTable
end

function Update(portTable)
    local vin = portTable['PortList'][1]
	local tick = os.clock()
    
    local dt = tick - last_tick
    -- 10ms 一个触发
    if (dt < 0.01) then
        return portTable
    end
    last_tick = tick
    local dv = vin - last_code 
    last_code = vin 

    local fi = 1
    if (dv < 0) then
        fi = -fi
    end
    last_value = last_value + fi
    portTable['PortList'][2] = last_value 
    return portTable 
end

