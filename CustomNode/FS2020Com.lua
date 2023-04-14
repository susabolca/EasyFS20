function Name() return 'FS2020COM' end
function Info() return 'FS2020模拟器通讯模块' end

-- 返回 bcd 编码
function BcdEncode(v)
    num = math.ceil(math.ceil(v*100)) % 10000
    bcd = tonumber(string.format("%d", num), 16)
    print(string.format("%.3f : %x", v, bcd))
    return bcd
end

-- 返回 Max7219B 数码管编码
function Max7219B(str_in)
    -- Mode B
    --   -6-
    -- 1|   |5
    --   -0-
    -- 2|   |4
    --   -3- .7
    local CharTbl = {
        ' ', '0', '1', '2', '3', '4', '5', '6', '7', '8', '9',
        '-', '_', 'n',
    }
    local TubeSeg = {
        0x00, 0x7e, 0x30, 0x6d, 0x79, 0x33, 0x5b, 0x5f, 0x70, 0x7f, 0x7b,
        0x01, 0x08, 0x15,
    }
    local dotSeg = 0x80
    local array = {0, 0, 0, 0, 0, 0, 0, 0}
    local valDot = 0
    local n = 1
    local str_len = string.len(str_in)
    for i = string.len(str_in), 1, -1 do
        local c = string.sub(str_in, i, i)
        if (c == '.') then
            valDot = dotSeg
        else
            local seg = TubeSeg[1] 
            for j = 1, #CharTbl do
                if (c == CharTbl[j]) then
                    seg = TubeSeg[j] + valDot
                    break
                end
            end
            array[n] = seg
            valDot = 0
            n = n + 1
        end
    end
    local out = ''
    for i = 1, 8 do
        out = out .. array[i]
        if (i < 8) then out = out .. ',' end
    end
    return out
end

-- Single Button
Button = {}

function Button:new(port_index)
    local o = {}
    setmetatable(o, self)
    self.__index = self
    o._port_index = port_index 
    o._port_value = 0
    return o
end

-- key is pressing down
function Button:onKeyDown(portList)
    return portList[self._port_index] 
end

-- key was down and released
function Button:onKeyPress(portList)
    local vin = portList[self._port_index]

    local last_value = self._port_value
    self._port_value = vin

    -- btn release and last port value is pressed 
    if (last_value == 1 and vin == 0) then
        print(self._port_index, 'pressed')
        return 1 
    end
    return 0 
end

-- Encoder with Button
BtnEncoder = {}

function BtnEncoder:new(enc, btn_enc, rev)
    local o = {}
    setmetatable(o, self)
    self.__index = self
    -- Encoder code (begin from 32536)
    o._last_code = nil 
    -- if Encoder is Reversed.
    o._port_enc = enc
    o._port_btn = btn_enc
    o._rev = rev or 0
    return o
end

function BtnEncoder:change(portList)
    local enc = portList[self._port_enc]
    if (self._last_code == nil) then
        self._last_code = enc 
        return 0
    end
    local dv = enc - self._last_code
    if (dv == 0) then
        return 0
    end
    if (dv > 1000) then    -- large tuning only means initialization 
        self._last_code = enc
        return 0
    end
    self._last_code = enc
    local btn = portList[self._port_btn]

    if (btn == 0) then
        dv = dv * 0.001
    end
    if (self._rev > 0) then
        dv = -dv
    end
    print(self._last_code, dv, btn)
    return dv
end

-- Radio 对象， 支持 com 和 nav
Radio = {}

-- 创建一个 Radio 对象
function Radio:new(name, freq_low, freq_high, freq_step, port_index, port_out)
    local o = {}
    setmetatable(o, self)
    self.__index = self
    o._name = name
    o._freq_low = freq_low
    o._freq_high = freq_high
    o._freq_step = freq_step
    o._freq_tmp = 0
    o._freq = freq_low 
    o._in_port = port_index
    o._out_port = port_out
    return o 
end

-- 调频 
function Radio:tune(change)
    local dv = change
    if (math.abs(change) < 1) then
        dv = change * 1000 * self._freq_step
    end
    if (self._freq_tmp == 0) then
        self._freq_tmp = math.max(self._freq, self._freq_low)
    end
    local f = self._freq_tmp + dv
    f = math.min(f, self._freq_high)
    f = math.max(f, self._freq_low)
    self._freq_tmp = f
    print(change, self._freq, self._freq_tmp)
end

-- 输入
function Radio:update(portList)
    self._freq = portList[self._in_port]
    if (self._freq_tmp == 0) then
        return
    elseif (self._freq == self._freq_tmp) then
        self._freq_tmp = 0 
    end
end

-- swap 输出
function Radio:swap(portList)
    local f = self._freq_tmp 
    f = math.min(f, self._freq_high)
    f = math.max(f, self._freq_low)
    portList[self._out_port] = BcdEncode(f)
end

-- Show digital freq
function Radio:show()
    local out
    local c = string.sub(self._name, 1, 1)
    if (c == 'n') then
        if (self._freq_tmp == 0) then
            out = string.format('%2s %.2f', self._name, self._freq)
        else
            out = string.format('%2s. %.2f', self._name, self._freq_tmp)
        end
    else
        if (self._freq_tmp == 0) then
            out = string.format('%2s %.3f', self._name, self._freq)
        else
            out = string.format('%2s. %.3f', self._name, self._freq_tmp)
        end
    end
    return out
end

-- Tunner 调频器
Tuner = {}

function Tuner:new(radio_index, btn_encoder, btn_mode, btn_swap)
    local o = {}
    setmetatable(o, self)
    self.__index = self
    o._radio_index = radio_index
    o._encoder = btn_encoder
    o._button_mode = btn_mode
    o._button_swap = btn_swap
    return o
end

function Tuner:update(portList)
    local rc = 0
    local mod = self._button_mode:onKeyPress(portList)
    if (mod == 1) then
        self._radio_index = self._radio_index + 1
        if (self._radio_index > #RadioTable) then
            self._radio_index = 1
        end
        print(self._radio_index)
        local radio = RadioTable[self._radio_index]
        return radio:show()
    end 
    
    local change = self._encoder:change(portList)
    local radio = RadioTable[self._radio_index]
    if (change ~= 0) then 
        radio:tune(change)
        return radio:show()
    end
    
    local btn = self._button_swap:onKeyPress(portList)
    if (btn == 1) then
        radio:swap(portList)
        return radio:show()
    end
    return nil 
end

-- 定义 PortList
function PortList()
    local portTable = {
        ['PortList'] = {
            -- 1: data in
            {['name'] = 'IN COM1 Freq', ['type'] = 'In', ['valueType'] = 'Int'},
            {['name'] = 'IN COM2 Freq', ['type'] = 'In', ['valueType'] = 'Int'},
            {['name'] = 'IN COM3 Freq', ['type'] = 'In', ['valueType'] = 'Int'},
            {['name'] = 'IN NAV1 Freq', ['type'] = 'In', ['valueType'] = 'Int'},
            {['name'] = 'IN NAV2 Freq', ['type'] = 'In', ['valueType'] = 'Int'},
            {['name'] = 'IN Radio Sound Switches', ['type'] = 'In', ['valueType'] = 'Int'},
            {['name'] = 'IN XPDR Code', ['type'] = 'In', ['valueType'] = 'Int'},
            {['name'] = 'IN FLAPS Handle index', ['type'] = 'In', ['valueType'] = 'Int'},
            {['name'] = 'IN OBS', ['type'] = 'In', ['valueType'] = 'Int'},
            {['name'] = 'IN CDI1', ['type'] = 'In', ['valueType'] = 'Int'},
            {['name'] = 'IN CDI2', ['type'] = 'In', ['valueType'] = 'Int'},

            -- 12: inputs
            {['name'] = 'Encoder1', ['type'] = 'In', ['valueType'] = 'Int'},
            {['name'] = 'EncoderBtn1', ['type'] = 'In', ['valueType'] = 'Int'},
            {['name'] = 'EncoderMode1', ['type'] = 'In', ['valueType'] = 'Int'},
            {['name'] = 'EncoderSwap1', ['type'] = 'In', ['valueType'] = 'Int'},

            -- 16
            {['name'] = 'Encoder2', ['type'] = 'In', ['valueType'] = 'Int'},
            {['name'] = 'EncoderBtn2', ['type'] = 'In', ['valueType'] = 'Int'},
            {['name'] = 'EncoderMode2', ['type'] = 'In', ['valueType'] = 'Int'},
            {['name'] = 'EncoderSwap2', ['type'] = 'In', ['valueType'] = 'Int'},
            
            -- 20 
            {['name'] = 'Encoder3', ['type'] = 'In', ['valueType'] = 'Int'},
            {['name'] = 'EncoderBtn3', ['type'] = 'In', ['valueType'] = 'Int'},
            {['name'] = 'EncoderMode3', ['type'] = 'In', ['valueType'] = 'Int'},
            {['name'] = 'EncoderSwap3', ['type'] = 'In', ['valueType'] = 'Int'},
           
            -- 24
            {['name'] = 'Encoder4', ['type'] = 'In', ['valueType'] = 'Int'},
            {['name'] = 'EncoderBtn4', ['type'] = 'In', ['valueType'] = 'Int'},
            {['name'] = 'EncoderMode4', ['type'] = 'In', ['valueType'] = 'Int'},
            {['name'] = 'EncoderSwap4', ['type'] = 'In', ['valueType'] = 'Int'},

            -- 28
            {['name'] = 'Encoder5', ['type'] = 'In', ['valueType'] = 'Int'},
            {['name'] = 'Encoder5Btn1', ['type'] = 'In', ['valueType'] = 'Int'},
            {['name'] = 'Encoder5Btn2', ['type'] = 'In', ['valueType'] = 'Int'},
            {['name'] = 'Encoder5Btn3', ['type'] = 'In', ['valueType'] = 'Int'},
            {['name'] = 'Encoder5Btn4', ['type'] = 'In', ['valueType'] = 'Int'},
            {['name'] = 'Encoder5Btn5', ['type'] = 'In', ['valueType'] = 'Int'},
           
            -- 34: outputs
            {['name'] = 'COM1(BCD)', ['type'] = 'Out', ['valueType'] = 'Int'},
            {['name'] = 'COM2(BCD)', ['type'] = 'Out', ['valueType'] = 'Int'},
            {['name'] = 'COM3(BCD)', ['type'] = 'Out', ['valueType'] = 'Int'},
            {['name'] = 'NAV1(BCD)', ['type'] = 'Out', ['valueType'] = 'Int'},
            {['name'] = 'NAV2(BCD)', ['type'] = 'Out', ['valueType'] = 'Int'},
            {['name'] = 'ADF(BCD)', ['type'] = 'Out', ['valueType'] = 'Int'},
            {['name'] = 'Radio Sound Switches', ['type'] = 'Out', ['valueType'] = 'Int'},

            -- 41: 8 Leds
            {['name'] = 'LED_BOTH', ['type'] = 'Out', ['valueType'] = 'Int'},
            {['name'] = 'LED_NAV1', ['type'] = 'Out', ['valueType'] = 'Int'},
            {['name'] = 'LED_NAV2', ['type'] = 'Out', ['valueType'] = 'Int'},
            {['name'] = 'LED_ADF', ['type'] = 'Out', ['valueType'] = 'Int'},
            {['name'] = 'LED_DME', ['type'] = 'Out', ['valueType'] = 'Int'},
            {['name'] = 'LED_MKR', ['type'] = 'Out', ['valueType'] = 'Int'},
            {['name'] = 'LED_XPDR', ['type'] = 'Out', ['valueType'] = 'Int'},
            {['name'] = 'LED_OBS', ['type'] = 'Out', ['valueType'] = 'Int'},
           
            -- 49: Max7219 x 5
            {['name'] = 'MAX1', ['type'] = 'Out', ['valueType'] = 'String'},
            {['name'] = 'MAX2', ['type'] = 'Out', ['valueType'] = 'String'},
            {['name'] = 'MAX3', ['type'] = 'Out', ['valueType'] = 'String'},
            {['name'] = 'MAX4', ['type'] = 'Out', ['valueType'] = 'String'},
            {['name'] = 'MAX5', ['type'] = 'Out', ['valueType'] = 'String'}

            -- 54
        }
    }
    return portTable
end

-- 5 Radios
RadioTable = {Radio:new('1', 118.000, 135.975, 0.050, 1, 34), 
              Radio:new('2', 118.000, 135.975, 0.050, 2, 35), 
              Radio:new('3', 118.000, 135.975, 0.050, 3, 36),
              Radio:new('n1', 108.000, 117.95, 0.050, 4, 37),
              Radio:new('n2', 108.000, 117.95, 0.050, 5, 38)
            }

-- tuner1 = Tuner:new(1, BtnEncoder:new(12, 13, 1), Button:new(14), Button:new(15))
tuner1 = Tuner:new(1, BtnEncoder:new(12, 13, 1), Button:new(14), Button:new(15))
tuner2 = Tuner:new(2, BtnEncoder:new(16, 17, 0), Button:new(18), Button:new(19))
tuner3 = Tuner:new(4, BtnEncoder:new(20, 21, 0), Button:new(22), Button:new(23))

-- 更新方法
function Update(portTable)
    local portList = portTable['PortList']
    local a

    -- radio com in 
    for k,v in ipairs(RadioTable) 
    do
        --print(k, v)
        v:update(portList)
    end

    -- tuner 1
    a = tuner1:update(portList)
    if (a ~= nil) then
        portList[49] = Max7219B(a)
    end

    -- radio 2
    a = tuner2:update(portList)
    if (a ~= nil) then
        portList[50] = Max7219B(a)
    end

    -- radio 3
    a = tuner3:update(portList)
    if (a ~= nil) then
        portList[51] = Max7219B(a)
    end


    return portTable
end
