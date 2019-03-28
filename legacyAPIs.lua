--[[
  @Author xxzhushou
  @Repo   https://github.com/xxzhushou/XMod_LegacyAPIs
]]--

local bit = require('bit32')

-- 可能频繁调用的模块/函数, 使用local加速访问速度
local io = io
local os = os
local string = string
local table = table
local rawset = rawset

local UI = UI
local xmod = xmod
local audio = audio
local touch = touch
local legacy = legacy
local screen = screen
local script = script
local device = device
local storage = storage
local runtime = runtime

local Size = Size
local Rect = Rect
local Point = Point
local Image = Image

local log = log
local sleep = sleep

local os_netTime = os.netTime
local os_milliTime = os.milliTime

local xmod_getConfig = xmod.getConfig
local xmod_setConfig = xmod.setConfig
local xmod_resolvePath = xmod.resolvePath

local touch_down = touch.down
local touch_move = touch.move
local touch_up = touch.up

local screen_keep = screen.keep
local screen_getSize = screen.getSize
local screen_getColorRGB = screen.getColorRGB
local screen_getColorHex = screen.getColorHex
local screen_findImage = screen.findImage
local screen_matchColor = screen.matchColor
local screen_matchColors = screen.matchColors
local screen_findColor = screen.findColor
local screen_findColors = screen.findColors

local storage_get = storage.get
local storage_put = storage.put
local storage_commit = storage.commit

--[[ Lua 5.1 兼容 ]] --
----------------------
-- make unpack back
rawset(_G, 'unpack', table.unpack)

-- legacy support for string
rawset(string, 'gfind', string.gmatch)

-- legacy support for table
rawset(table, 'foreach', function(t, f)
    for k, v in pairs(t) do
        f(k, v)
    end
end)

rawset(table, 'foreachi', function(t, f)
    for k, v in ipairs(t) do
        f(k, v)
    end
end)

rawset(table, 'getn', function(t)
    if type(t.n) == 'number' then return t.n end
    local max = 0
    for i, _ in pairs(t) do
        if type(i) == 'number' and i > max then
            max = i
        end
    end
    return max
end)

-- legacy support for io: 桥接[private]/[public]访问目录
local __orig_io_open__ = io.open
local function __hook_io_open(name, mode)
    if type(name) == 'string' then
        name = xmod_resolvePath(name)
    end
    return __orig_io_open__(name, mode)
end
rawset(io, 'open', __hook_io_open)

local __orig_io_lines__ = io.lines
local function __hook_io_lines(name)
    if type(name) == 'string' then
        name = xmod_resolvePath(name)
    end
    return __orig_io_lines__(name)
end
rawset(io, 'lines', __hook_io_lines)

local __orig_io_input__ = io.input
local function __hook_io_input(...)
    local arg = { ... }
    if #arg > 0 and type(arg[1]) == 'string' then
        arg[1] = xmod_resolvePath(arg[1])
    end
    return __orig_io_input__(unpack(arg))
end
rawset(io, 'input', __hook_io_input)

local __orig_io_output__ = io.output
local function __hook_io_output(...)
    local arg = { ... }
    if #arg > 0 and type(arg[1]) == 'string' then
        arg[1] = xmod_resolvePath(arg[1])
    end
    return __orig_io_output__(unpack(arg))
end
rawset(io, 'output', __hook_io_output)

--[[ tengine 兼容 ]] --
----------------------
local function ori2dir(ori)
    local dir = 0
    if ori == screen.PROTRAIT_UPSIDEDOWN then
        dir = 3
    elseif ori == screen.LANDSCAPE_LEFT then
        dir = 2
    elseif ori == screen.LANDSCAPE_RIGHT then
        dir = 1
    end
    return dir
end

local function dir2ori(dir)
    local orientation = screen.PORTRAIT
    if dir == 1 then
        orientation = screen.LANDSCAPE_RIGHT
    elseif dir == 2 then
        orientation = screen.LANDSCAPE_LEFT
    end
    return orientation
end

local function block2rect(block)
    return Rect(block[1], block[2], block[3] - block[1], block[4] - block[2])
end

local function searchdir2priority(hdir, vdir, priority)
    local horizontal = (hdir == 1) and screen.PRIORITY_RIGHT_FIRST or screen.PRIORITY_LEFT_FIRST
    local vertical = (vdir == 1) and screen.PRIORITY_DOWN_FIRST or screen.PRIORITY_UP_FIRST
    local direction = (priority == 1) and screen.PRIORITY_VERTICAL_FIRST or screen.PRIORITY_HORIZONTAL_FIRST
    return bit.bor(horizontal, vertical, direction)
end

local function keyname2code(name)
    local code = touch.KEY_NONE
    if string.upper(name) == 'HOME' then
        code = touch.KEY_HOME
    elseif string.upper(name) == 'BACK' then
        code = touch.KEY_BACK
    elseif string.upper(name) == 'MENU' then
        code = touch.KEY_MENU
    elseif string.upper(name) == 'POWER' then
        code = touch.KEY_POWER
    elseif string.upper(name) == 'VOLUME_UP' then
        code = touch.KEY_VOLUME_UP
    elseif string.upper(name) == 'VOLUME_DOWN' then
        code = touch.KEY_VOLUME_DOWN
    end
    return code
end

local function __tengine_sysLog(msg)
    log(msg)
end
rawset(_G, 'sysLog', __tengine_sysLog)

local function __tengine_fileLogWrite(name, date_flag, tag, msg)
    log(msg)
end
rawset(_G, 'fileLogWrite', __tengine_fileLogWrite)

local function __tengine_mSleep(ms)
    sleep(ms)
end
rawset(_G, 'mSleep', __tengine_mSleep)

local function __tengine_mTime()
    return os_milliTime()
end
rawset(_G, 'mTime', __tengine_mTime)

local function __tengine_getNetTime()
    return os_netTime()
end
rawset(_G, 'getNetTime', __tengine_getNetTime)

local function __tengine_getOSType()
    if xmod.PLATFORM == xmod.PLATFORM_ANDROID then
        return 'android'
    else
        return 'iOS'
    end
end
rawset(_G, 'getOSType', __tengine_getOSType)

local function __tengine_getEngineVersion()
    return xmod.VERSION_NAME
end
rawset(_G, 'getEngineVersion', __tengine_getEngineVersion)

local function __tengine_isPrivateMode()
    return xmod.PROCESS_MODE == xmod.PROCESS_MODE_STANDALONE and 1 or 0
end
rawset(_G, 'isPrivateMode', __tengine_isPrivateMode)
rawset(_G, 'isPriviateMode', __tengine_isPrivateMode) -- typo compaitable

local function __tengine_lua_exit()
    xmod.exit()
end
rawset(_G, 'lua_exit', __tengine_lua_exit)

local function __tengine_lua_restart()
    xmod.restart()
end
rawset(_G, 'lua_restart', __tengine_lua_restart)

local function __tengine_setSysConfig(key, value)
    if key == screen.SCREENCAP_POLICY then
        value = (value == 'aggressive') and screen.SCREENCAP_POLICY_AGGRESSIVE or screen.SCREENCAP_POLICY_STANDARD
    end
    xmod_setConfig(key, value)
end
rawset(_G, 'setSysConfig', __tengine_setSysConfig)

local function __tengine_setTimer(time, callback, ...)
    local args = { ... }
    return task.execTimer(time, callback, unpack(args))
end
rawset(_G, 'setTimer', __tengine_setTimer)

local function __tengine_asyncExec(arguments)
    local args = { arguments, arguments.callback }
    if arguments.content then
        table.insert(args, arguments.content)
    end
    return task.execAsync(unpack(args))
end
rawset(_G, 'asyncExec', __tengine_asyncExec)

local function __tengine_setStringConfig(key, value)
    storage_put(key, value)
    storage_commit()
end
rawset(_G, 'setStringConfig', __tengine_setStringConfig)

local function __tengine_getStringConfig(key, defVal)
    return storage_get(key, defVal)
end
rawset(_G, 'getStringConfig', __tengine_getStringConfig)

local function __tengine_setNumberConfig(key, value)
    storage_put(key, value)
    storage_commit()
end
rawset(_G, 'setNumberConfig', __tengine_setNumberConfig)

local function __tengine_getNumberConfig(key, defVal)
    return tonumber(storage_get(key, defVal)) or defVal
end
rawset(_G, 'getNumberConfig', __tengine_getNumberConfig)

local function __tengine_getUserID()
    local user_info, code = script.getUserInfo()
    return user_info.id, code
end
rawset(_G, 'getUserID', __tengine_getUserID)

local function __tengine_getUserCredit()
    local user_info, code = script.getUserInfo()
    return user_info.membership, user_info.expiredTime, code
end
rawset(_G, 'getUserCredit', __tengine_getUserCredit)

local function __tengine_getScriptID()
    local script_info, code = script.getScriptInfo()
    return script_info.id, code
end
rawset(_G, 'getScriptID', __tengine_getScriptID)

local function __tengine_getCloudContent(key, token, defMsg)
    local msg, code = script.getBulletinBoard(key, token)
    if code ~= 0 then
        msg = defMsg
    end
    return msg, code
end
rawset(_G, 'getCloudContent', __tengine_getCloudContent)

local function __tengine_getUIContent(src)
    return script.getUIData(src)
end
rawset(_G, 'getUIContent', __tengine_getUIContent)

local function __tengine_init(appID, dir)
    screen.init(dir2ori(dir))
end
rawset(_G, 'init', __tengine_init)

local function __tengine_findImageInRegionFuzzy(picpath, degree, x1, y1, x2, y2, alpha)
    local pos = screen_findImage(block2rect({ x1, y1, x2, y2 }), picpath, degree, screen.PRIORITY_DEFAULT, alpha)
    return pos.x, pos.y
end
rawset(_G, 'findImageInRegionFuzzy', __tengine_findImageInRegionFuzzy)

local function __tengine_findColor(block, color, degree, hdir, vdir, priority)
    if type(color) == 'table' then
        local ct = {}
        for _, v in ipairs(color) do
            table.insert(ct, { pos = Point(v.x, v.y), color = v.color })
        end
        color = ct
    end
    local pos = screen_findColor(block2rect(block), color, degree, searchdir2priority(hdir or 0, vdir or 0, priority or 0))
    return pos.x, pos.y
end
rawset(_G, 'findColor', __tengine_findColor)

local function __tengine_findColors(block, color, degree, hdir, vdir, priority)
    if type(color) == 'table' then
        local ct = {}
        for _, v in ipairs(color) do
            table.insert(ct, { pos = Point(v.x, v.y), color = v.color })
        end
        color = ct
    end
    local points = screen_findColors(block2rect(block), color, degree, searchdir2priority(hdir or 0, vdir or 0, priority or 0), 199)
    local result = {}
    for _, p in ipairs(points) do
        table.insert(result, { x = p.x, y = p.y })
    end
    return result
end
rawset(_G, 'findColors', __tengine_findColors)

local function __tengine_findColorInRegionFuzzy(tcolor, degree, x1, y1, x2, y2, hdir, vdir)
    return __tengine_findColor({ x1, y1, x2, y2 }, tcolor, degree, hdir or 0, vdir or 0)
end
rawset(_G, 'findColorInRegionFuzzy', __tengine_findColorInRegionFuzzy)

local function __tengine_findMultiColorInRegionFuzzy(tcolor, posandcolors, degree, x1, y1, x2, y2, hdir, vdir)
    local color = string.format('0|0|0x%06x,%s', tcolor, posandcolors)
    return __tengine_findColor({ x1, y1, x2, y2 }, color, degree, hdir or 0, vdir or 0)
end
rawset(_G, 'findMultiColorInRegionFuzzy', __tengine_findMultiColorInRegionFuzzy)

local function __tengine_findMultiColorInRegionFuzzy2(tcolor, posandcolors, degree, x1, y1, x2, y2, hdir, vdir)
    table.insert(posandcolors, 1, { x = 0, y = 0, color = tcolor })
    return __tengine_findColor({ x1, y1, x2, y2 }, posandcolors, degree, hdir or 0, vdir or 0)
end
rawset(_G, 'findMultiColorInRegionFuzzy2', __tengine_findMultiColorInRegionFuzzy2)

local function __tengine_findMultiColorInRegionFuzzyExt(tcolor, posandcolors, degree, x1, y1, x2, y2, hdir, vdir)
    local color = string.format('0|0|0x%06x,%s', tcolor, posandcolors)
    return __tengine_findColors({ x1, y1, x2, y2 }, color, degree, hdir or 0, vdir or 0)
end
rawset(_G, 'findMultiColorInRegionFuzzyExt', __tengine_findMultiColorInRegionFuzzyExt)

local function __tengine_findMultiColorInRegionFuzzyExt2(tcolor, posandcolors, degree, x1, y1, x2, y2, hdir, vdir)
    table.insert(posandcolors, 1, { x = 0, y = 0, color = tcolor })
    return __tengine_findColors({ x1, y1, x2, y2 }, posandcolors, degree, hdir or 0, vdir or 0)
end
rawset(_G, 'findMultiColorInRegionFuzzyExt2', __tengine_findMultiColorInRegionFuzzyExt2)

local function __tengine_getColor(x, y)
    return screen_getColorHex(x, y)
end
rawset(_G, 'getColor', __tengine_getColor)

local function __tengine_getColorRGB(x, y)
    return screen_getColorRGB(x, y)
end
rawset(_G, 'getColorRGB', __tengine_getColorRGB)

local function __tengine_keepScreen(enabled)
    screen_keep(enabled)
end
rawset(_G, 'keepScreen', __tengine_keepScreen)

local function __tengine_snapshot(picname, x1, y1, x2, y2, quality)
    local rect = { 0, 0, 0, 0 }
    if y2 ~= nil then
        rect = block2rect({ x1, y1, x2, y2 })
    end
    return screen.snapshot(picname, rect, (quality or 1) * 100)
end
rawset(_G, 'snapshot', __tengine_snapshot)

local function __tengine_getScreenSize()
    local size = screen_getSize()
    if size.width < size.height then
        return size.width, size.height
    else
        return size.height, size.width
    end
end
rawset(_G, 'getScreenSize', __tengine_getScreenSize)

local function __tengine_setScreenScale(width, height, mode)
    local floor = math.floor
    local screenSize = screen_getSize()
    -- 以前getScreenSize()返回值永远是短边为宽
    -- 因此setScreenScale传入参数也是setScreenScale(短边, 长边)的形式
    local scaleW, scaleH
    if xmod_getConfig(xmod.EXPECTED_ORIENTATION, screen.PORTRAIT) == screen.PORTRAIT then
        scaleW, scaleH = screenSize.width / width, screenSize.height / height
    else
        scaleW, scaleH = screenSize.width / height, screenSize.height / width
    end
    screen.setMockMode(mode == 1 and screen.MOCK_INPUT or screen.MOCK_BOTH)
    screen.setMockTransform(function (mode, rect)
        local sw, sh = scaleW, scaleH
        if mode == screen.MOCK_OUTPUT then
            sw = 1 / sw
            sh = 1 / sh
        end
        rect.x = floor(rect.x * sw)
        rect.y = floor(rect.y * sh)
        rect.width = floor(rect.width * sw)
        rect.height = floor(rect.height * sh)
        return rect
    end)
end
rawset(_G, 'setScreenScale', __tengine_setScreenScale)

local function __tengine_resetScreenScale()
    screen.reset()
end
rawset(_G, 'resetScreenScale', __tengine_resetScreenScale)

local function __tengine_getScreenDPI()
    return screen.getDPI()
end
rawset(_G, 'getScreenDPI', __tengine_getScreenDPI)

local function __tengine_getScreenDirection()
    return ori2dir(screen.getOrientation())
end
rawset(_G, 'getScreenDirection', __tengine_getScreenDirection)

local function __tengine_binarizeImage(args)
    local ret = {}
    local img = screen.capture(block2rect(args.rect))
    if img then
        ret = img:binarize(args.diff)
    end
    return ret
end
rawset(_G, 'binarizeImage', __tengine_binarizeImage)

local function __tengine_touchDown(index, x, y)
    touch_down(index, x, y)
end
rawset(_G, 'touchDown', __tengine_touchDown)

local function __tengine_touchMove(index, x, y)
    touch_move(index, x, y)
end
rawset(_G, 'touchMove', __tengine_touchMove)

local function __tengine_touchUp(index, x, y)
    touch_up(index, x, y)
end
rawset(_G, 'touchUp', __tengine_touchUp)

local function __tengine_catchTouchPoint(count, timeout)
    local count = count or 1
    local timeout = timeout or 60 * 1000
    local ret = touch.captureTap(count, timeout)
    if count == 1 then
        return ret.x, ret.y
    else
        return ret
    end
end
rawset(_G, 'catchTouchPoint', __tengine_catchTouchPoint)

local function __tengine_pressHomeKey()
    touch.press(touch.KEY_HOME)
end
rawset(_G, 'pressHomeKey', __tengine_pressHomeKey)

local function __tengine_doublePressHomeKey()
    touch.doublePress(touch.KEY_HOME)
end
rawset(_G, 'doublePressHomeKey', __tengine_doublePressHomeKey)

local function __tengine_pressKey(name, mode)
    touch.press(keyname2code(name), mode)
    return 0
end
rawset(_G, 'pressKey', __tengine_pressKey)

local function __tengine_showUI(json)
    return legacy.showUI(json)
end
rawset(_G, 'showUI', __tengine_showUI)

local function __tengine_resetUIConfig(file)
    legacy.resetUIConfig(file)
end
rawset(_G, 'resetUIConfig', __tengine_resetUIConfig)

local function __tengine_toast(msg)
    UI.toast(tostring(msg))
end
rawset(_G, 'toast', __tengine_toast)

local function __tengine_dialog(text, time)
    legacy.dialog(tostring(text), time or 0)
end
rawset(_G, 'dialog', __tengine_dialog)

local function __tengine_dialogRet(text, button1, button2, button3, time)
    return legacy.dialogRet(tostring(text), tostring(button1), tostring(button2), tostring(button3), time or 0)
end
rawset(_G, 'dialogRet', __tengine_dialogRet)

local function __tengine_dialogInput(title, format, btn)
    return unpack(legacy.dialogInput(title, format, btn))
end
rawset(_G, 'dialogInput', __tengine_dialogInput)

local function __tengine_setUIOrientation(mode)
    return legacy.setUIOrientation(mode)
end
rawset(_G, 'setUIOrientation', __tengine_setUIOrientation)

local function __tengine_createHUD()
    return legacy.createHUD()
end
rawset(_G, 'createHUD', __tengine_createHUD)

local function __tengine_showHUD(id, text, size, color, bg, pos, x, y, width, height)
    legacy.showHUD(id, tostring(text), size, color, bg, pos, x, y, width, height)
end
rawset(_G, 'showHUD', __tengine_showHUD)

local function __tengine_hideHUD(id)
    return legacy.hideHUD(id)
end
rawset(_G, 'hideHUD', __tengine_hideHUD)

local function __tengine_inputText(content)
    runtime.inputText(tostring(content))
end
rawset(_G, 'inputText', __tengine_inputText)

local function __tengine_runApp(appID)
    return runtime.launchApp(appID) and 0 or -1
end
rawset(_G, 'runApp', __tengine_runApp)

local function __tengine_closeApp(appID)
    runtime.killApp(appID)
end
rawset(_G, 'closeApp', __tengine_closeApp)

local function __tengine_appIsRunning(appID)
    return runtime.isAppRunning(appID) and 1 or 0
end
rawset(_G, 'appIsRunning', __tengine_appIsRunning)

local function __tengine_isFrontApp(appID)
    return (runtime.getForegroundApp() == appID) and 1 or 0
end
rawset(_G, 'isFrontApp', __tengine_isFrontApp)

local function __tengine_frontAppName()
    return runtime.getForegroundApp()
end
rawset(_G, 'frontAppName', __tengine_frontAppName)

local function __tengine_setWifiEnable(flag)
    return runtime.setWifiEnable(flag) and 1 or 0
end
rawset(_G, 'setWifiEnable', __tengine_setWifiEnable)

local function __tengine_setAirplaneMode(flag)
    return runtime.setAirplaneMode(flag) and 1 or 0
end
rawset(_G, 'setAirplaneMode', __tengine_setAirplaneMode)

local function __tengine_setBTEnable(flag)
    return runtime.setBTEnable(flag) and 1 or 0
end
rawset(_G, 'setBTEnable', __tengine_setBTEnable)

local function __tengine_vibrator()
    runtime.vibrate(1000)
end
rawset(_G, 'vibrator', __tengine_vibrator)

local function __tengine_playAudio(file)
    audio.play(file)
end
rawset(_G, 'playAudio', __tengine_playAudio)

local function __tengine_stopAudio()
    audio.stop()
end
rawset(_G, 'stopAudio', __tengine_stopAudio)

local function __tengine_readPasteboard()
    return runtime.readClipboard()
end
rawset(_G, 'readPasteboard', __tengine_readPasteboard)

local function __tengine_writePasteboard(content)
    runtime.writeClipboard(tostring(content))
end
rawset(_G, 'writePasteboard', __tengine_writePasteboard)

local function __tengine_getLocalInfo()
    return runtime.getLocalInfo()
end
rawset(_G, 'getLocalInfo', __tengine_getLocalInfo)

local function __tengine_getSystemProperty(key)
    local val = ''
    if xmod.PLATFORM == xmod.PLATFORM_ANDROID then
        val = runtime.android.getSystemProperty(key)
    end
    return val
end
rawset(_G, 'getSystemProperty', __tengine_getSystemProperty)

local function __tengine_getDeviceIMEI()
    return device.getIMEI()
end
rawset(_G, 'getDeviceIMEI', __tengine_getDeviceIMEI)

local function __tengine_getDeviceIMSI()
    return device.getIMSI()
end
rawset(_G, 'getDeviceIMSI', __tengine_getDeviceIMSI)

local function __tengine_getDeviceUUID()
    return device.getUUID()
end
rawset(_G, 'getDeviceUUID', __tengine_getDeviceUUID)

local function __tengine_getBatteryLevel()
    local isCharge, level = runtime.getBatteryInfo()
    local isChargeInt = 0
    if isCharge == true then
        isChargeInt = 1
    end
    return isChargeInt, level;
end
rawset(_G, 'getBatteryLevel', __tengine_getBatteryLevel)

local function __tengine_lockDevice()
    device.lock()
end
rawset(_G, 'lockDevice', __tengine_lockDevice)

local function __tengine_unlockDevice()
    device.unlock()
end
rawset(_G, 'unlockDevice', __tengine_unlockDevice)

local function __tengine_deviceIsLock()
    return device.isLock() and 1 or 0
end
rawset(_G, 'deviceIsLock', __tengine_deviceIsLock)

local function __tengine_resetIDLETimer()
    if xmod.PLATFORM == xmod.PLATFORM_IOS then
        runtime.ios.resetLockTimer()
    end
end
rawset(_G, 'resetIDLETimer', __tengine_resetIDLETimer)

local function __tengine_createOcrDict(dict)
    local dmocr = require('dmocr')
    return dmocr.create(dict)
end
rawset(_G, 'createOcrDict', __tengine_createOcrDict)

local function __tengine_ocrText(instance, x1, y1, x2, y2, diffs, sim, flag, dir)
    local detail = flag == 1
    local result = instance:getText(block2rect({ x1, y1, x2, y2 }), diffs, sim, detail, dir)
    if detail then
        local ret = {}
        for _, v in pairs(result) do
            table.insert(ret, { x = v.pos.x, y = v.pos.y, text = v.char })
        end
        return ret;
    end
    return result
end
rawset(_G, 'ocrText', __tengine_ocrText)

local ocrSpy = {}
function ocrSpy:new(ocr)
    return setmetatable({ ocr = ocr }, { __index = self })
end

function ocrSpy:getText(config)
    if config.psm then self.ocr:setPSM(config.psm) end
    if config.whitelist then self.ocr:setWhitelist(config.whitelist) end
    if config.blacklist then self.ocr:setBlacklist(config.blacklist) end

    if config.rect and config.diff then
        return self.ocr:getText(block2rect({config.rect[1], config.rect[2], config.rect[3], config.rect[4]}), config.diff)
    elseif config.data then
        return self.ocr:getText(config.data)
    else
        return -1, 'parameter error'
    end
end

function ocrSpy:release()
    self.ocr:release()
end

local function __tengine_createOCR(config)
    local tessocr = require('tessocr_3.02.02')
    local ocr, msg = tessocr.create(config)
    if ocr ~= nil then
        ocr = ocrSpy:new(ocr)
    end
    return ocr, msg
end
rawset(_G, 'createOCR', __tengine_createOCR)

local function __tengine_getProduct()
    local ret = 0
    local code = xmod.PRODUCT_CODE
    if code == xmod.PRODUCT_CODE_XXZS then
        ret = 1
    elseif code == xmod.PRODUCT_CODE_DEV then
        ret = 3
    elseif code == xmod.PRODUCT_CODE_IPA then
        ret = 5
    elseif code == xmod.PRODUCT_CODE_SPIRIT then
        ret = 6
    elseif code == xmod.PRODUCT_CODE_KUWAN then
        ret = 7
    end
    return ret
end
rawset(_G, 'getProduct', __tengine_getProduct)

local function __tengine_getRuntimeMode()
    return xmod.PROCESS_MODE == xmod.PROCESS_MODE_STANDALONE and 2 or 0
end
rawset(_G, 'getRuntimeMode', __tengine_getRuntimeMode)

local function __tengine_openUrl(url)
    runtime.openURL(url)
end
rawset(_G, 'openUrl', __tengine_openUrl)
