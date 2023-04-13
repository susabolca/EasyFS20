function Name() return 'FS2020LIGHT' end
function Info() return 'FS2020灯光控制' end

function PortList()
    local portTable = {
        ['PortList'] = {
            {['name'] = 'IN LIGHTS', ['type'] = 'In', ['valueType'] = 'Int'},
            {['name'] = 'OUT LIGHTS', ['type'] = 'Out', ['valueType'] = 'Int'},
            -- 7 switches
            {['name'] = 'SW_CABIN', ['type'] = 'In', ['valueType'] = 'Int'},
            {['name'] = 'LED_CABIN', ['type'] = 'Out', ['valueType'] = 'Int'},
            {['name'] = 'SW_NAV', ['type'] = 'In', ['valueType'] = 'Int'},
            {['name'] = 'LED_NAV', ['type'] = 'Out', ['valueType'] = 'Int'},
            {['name'] = 'SW_STROBE', ['type'] = 'In', ['valueType'] = 'Int'},
            {['name'] = 'LED_STROBE', ['type'] = 'Out', ['valueType'] = 'Int'},
            {['name'] = 'SW_BEACON', ['type'] = 'In', ['valueType'] = 'Int'},
            {['name'] = 'LED_BEACON', ['type'] = 'Out', ['valueType'] = 'Int'},
            {['name'] = 'SW_TAXI', ['type'] = 'In', ['valueType'] = 'Int'},
            {['name'] = 'LED_TAXI', ['type'] = 'Out', ['valueType'] = 'Int'},
            {['name'] = 'SW_LANDING', ['type'] = 'In', ['valueType'] = 'Int'},
            {['name'] = 'LED_LANDING', ['type'] = 'Out', ['valueType'] = 'Int'},
            {['name'] = 'SW_NC', ['type'] = 'In', ['valueType'] = 'Int'},
            {['name'] = 'LED_NC', ['type'] = 'Out', ['valueType'] = 'Int'}
        }
    }
    return portTable
end

function Update(portTable)
    local inl = portTable['PortList'][1]

    portTable['PortList'][4] = (inl >> 9) & 1
    portTable['PortList'][6] = (inl >> 0) & 1
    portTable['PortList'][8] = (inl >> 4) & 1
    portTable['PortList'][10] = (inl >> 1) & 1
    portTable['PortList'][12] = (inl >> 3) & 1
    portTable['PortList'][14] = (inl >> 2) & 1
    portTable['PortList'][16] = (inl >> 7) & 1

    local outl = 0
    if (portTable['PortList'][3] == 0) then outl = outl | (1 << 9) end
    if (portTable['PortList'][5] == 0) then outl = outl | (1 << 0) end
    if (portTable['PortList'][7] == 0) then outl = outl | (1 << 4) end
    if (portTable['PortList'][9] == 0) then outl = outl | (1 << 1) end
    if (portTable['PortList'][11] == 0) then outl = outl | (1 << 3) end
    if (portTable['PortList'][13] == 0) then outl = outl | (1 << 2) end
    if (portTable['PortList'][15] == 0) then outl = outl | (1 << 7) end
    portTable['PortList'][2] = outl

    return portTable 
end