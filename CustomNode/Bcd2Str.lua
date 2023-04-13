function Name() return 'Bcd2Str' end
function Info() return 'BCD 编码转字符串' end

function PortList()
    local portTable = {
        ['PortList'] = {
            {['name'] = 'BCD', ['type'] = 'In', ['valueType'] = 'Int'},
            {['name'] = 'String', ['type'] = 'Out', ['valueType'] = 'String'},
        }
    }
    return portTable
end

function Update(portTable)
    local v = portTable['PortList'][1]
    portTable['PortList'][2] = string.format("%x", v) 
    return portTable 
end

