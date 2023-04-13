function Name() return 'FS2020COM' end
function Info() return 'FS2020模拟器通讯模块' end

-- 返回 bcd 编码
function BcdEncode(v)
    num = math.ceil(v) % 10000
    bcd = tonumber(string.format("%d", num), 16)
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
    local TubeSeg2 = {  -- with dot
        0x80, 0xfe, 0xb0, 0xed, 0xf9, 0xb3, 0xdb, 0xdf, 0xf0, 0xff, 0xfb,
        0x81, 0xc0, 0x95,
    }
    local array = {}
    local n = 1
    for i = 1, string.len(str_in) do
        local c = string.sub(str_in, i, i)
        if (c ~= '.') then 
            local seg = TubeSeg[1] 
            for j = 1, #CharTbl do
                if (c == CharTbl[j]) then
                    seg = TubeSeg[j]
                    break
                end
            end
            array[n] = seg
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
function Radio:new(name, freq_low, freq_high, freq_step, port_index)
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
    print(name)
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

-- Show digital freq
function Radio:show()
    local out = self._name 
    if (self._freq_tmp == 0) then
        out = out .. " " .. string.format('%.3f', self._freq)
    else
        out = out .. ". " .. string.format('%.3f', self._freq_tmp)
    end
    return out 
end

RadioTable = {Radio:new('1', 118.000, 135.975, 0.025, 1), 
              Radio:new('2', 118.000, 135.975, 0.025, 2), 
              Radio:new('3', 118.000, 135.975, 0.025, 3),
              Radio:new('n1', 108.000, 117.95, 0.050, 4),
              Radio:new('n2', 108.000, 117.95, 0.050, 5)
            }

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
        radio:swap()
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


btnCom1Mode = Button:new(14)
btnCom1Swap = Button:new(15)
btnEncoder1 = BtnEncoder:new(12, 13, 1)
btnEncoder2 = BtnEncoder:new(16, 17)

-- tuner1 = Tuner:new(1, BtnEncoder:new(12, 13, 1), Button:new(14), Button:new(15))
tuner1 = Tuner:new(1, btnEncoder1, btnCom1Mode, btnCom1Swap)

-- 更新方法
function Update(portTable)
    local portList = portTable['PortList']

    -- radio com 1
    for k,v in ipairs(RadioTable) 
    do
        --print(k, v)
        v:update(portList)
    end

    -- tuner 1
    local a = tuner1:update(portList)
    if (a ~= nil) then
        portList[49] = Max7219B(a)
    end

    -- radio 2

    -- radio 3

    return portTable
end
