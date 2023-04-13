function Name() return 'FS2020' end

function Info() return 'FS2020数据1' end

function PortList()
    local portTable = {
        ['PortList'] = {
            -- air speed
            {['name'] = 'Raw Air Speed', ['type'] = 'In', ['valueType'] = 'Int'},
            {['name'] = 'Air Speed', ['type'] = 'Out', ['valueType'] = 'String'},
            -- Magenet Heading
            {['name'] = 'Raw Mag Heading', ['type'] = 'In', ['valueType'] = 'Int'},
            {['name'] = 'Mag Heading', ['type'] = 'Out', ['valueType'] = 'String'},
            -- Altitude
            {['name'] = 'Raw Altitude', ['type'] = 'In', ['valueType'] = 'Int'},
            {['name'] = 'Altitude', ['type'] = 'Out', ['valueType'] = 'String'},


            -- Radio --
            -- ADF Freq
            {['name'] = 'Raw ADF Freq', ['type'] = 'In', ['valueType'] = 'Int'},
            {['name'] = 'ADF Freq', ['type'] = 'Out', ['valueType'] = 'String'},
            -- COM Freq
            {['name'] = 'Raw COM Freq', ['type'] = 'In', ['valueType'] = 'Int'},
            {['name'] = 'COM Freq', ['type'] = 'Out', ['valueType'] = 'String'},

            -- --
            -- Elevator Trim
            {['name'] = 'Raw Elevator Trim', ['type'] = 'In', ['valueType'] = 'Float'},
            {['name'] = 'Elevator Trim', ['type'] = 'Out', ['valueType'] = 'String'},
            -- Aileron Trim
            {['name'] = 'Raw Aileron Trim', ['type'] = 'In', ['valueType'] = 'Float'},
            {['name'] = 'Aileron Trim', ['type'] = 'Out', ['valueType'] = 'String'},
            -- Rudder Trim
            {['name'] = 'Raw Rudder Trim', ['type'] = 'In', ['valueType'] = 'Float'},
            {['name'] = 'Rudder Trim', ['type'] = 'Out', ['valueType'] = 'String'},

            -- AutoPilot --
            {['name'] = 'Raw AP HDG', ['type'] = 'In', ['valueType'] = 'Int'},
            {['name'] = 'AP HDG', ['type'] = 'Out', ['valueType'] = 'String'},

            {['name'] = 'Raw AP ALT', ['type'] = 'In', ['valueType'] = 'Int'},
            {['name'] = 'AP ALT', ['type'] = 'Out', ['valueType'] = 'String'},
            
            {['name'] = 'Raw AP VS', ['type'] = 'In', ['valueType'] = 'Int'},
            {['name'] = 'AP VS', ['type'] = 'Out', ['valueType'] = 'String'}
        }
    }
    return portTable
end

function Update(portTable)
    -- knots
    portTable['PortList'][2] = string.format("%.0f", portTable['PortList'][1] / 128)
    -- heading 
    portTable['PortList'][4] = string.format("%.0f", portTable['PortList'][3])
    -- altitude
    portTable['PortList'][6] = string.format("%.0f", portTable['PortList'][5] * 3.28084 / 65535 / 65535)
    -- Freq
    portTable['PortList'][8] = string.format("1%04x", portTable['PortList'][7])
    portTable['PortList'][10] = string.format("1%04x", portTable['PortList'][9])
    -- Trim
    portTable['PortList'][12] = string.format("%.0f", portTable['PortList'][11]*100000)
    portTable['PortList'][14] = string.format("%.0f", portTable['PortList'][13]*100000)
    portTable['PortList'][16] = string.format("%.0f", portTable['PortList'][15]*100000)
    
    -- AP HDG
    portTable['PortList'][18] = string.format("%d", math.ceil(portTable['PortList'][17] * 360 / 65536))
    -- AP ALT
    portTable['PortList'][20] = string.format("%d", math.ceil(portTable['PortList'][19] / 65536 * 3.2808399))
    -- AP VS
    portTable['PortList'][22] = string.format("%d", portTable['PortList'][21])

    return portTable 
end

function bcd2freq(v)
    return ((tonumber(x) / 10000) + 1) * 1000
end