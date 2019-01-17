--[[
  @Author xxzhushou
  @Repo   https://github.com/xxzhushou/XMod_LegacyAPIs
]]--

local bit = require('bit32')

local os = os
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
local screen_getRGB = screen.getRGB
local screen_getColor = screen.getColor
local screen_findImage = screen.findImage
local screen_matchColor = screen.matchColor
local screen_matchColors = screen.matchColors
local screen_findColor = screen.findColor
local screen_findColors = screen.findColors

local storage_get = storage.get
local storage_put = storage.put
local storage_commit = storage.commit

-- (legacy) hook io函数，桥接[private]/[public]访问目录
local __old_open__ = io.open
io.open = function(name, mode)
    if type(name) == 'string' then
        name = xmod_resolvePath(name)
    end
    return __old_open__(name, mode)
end

local __old_lines__ = io.lines
io.lines = function(name)
    if type(name) == 'string' then
        name = xmod_resolvePath(name)
    end
    return __old_lines__(name)
end

local __old_input__ = io.input
io.input = function(...)
    local arg = { ... }
    if #arg > 0 and type(arg[1]) == 'string' then
        arg[1] = xmod_resolvePath(arg[1])
    end
    return __old_input__(unpack(arg))
end

local __old_output__ = io.output
io.output = function(...)
    local arg = { ... }
    if #arg > 0 and type(arg[1]) == 'string' then
        arg[1] = xmod_resolvePath(arg[1])
    end
    return __old_output__(unpack(arg))
end

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

function sysLog(msg)
    log(msg)
end

function fileLogWrite(name, date_flag, tag, msg)
    log(msg)
end

function mSleep(ms)
    sleep(ms)
end

function mTime()
    return os_milliTime()
end

function getNetTime()
    return os_netTime()
end

function getOSType()
    if xmod.PLATFORM == xmod.PLATFORM_ANDROID then
        return 'android'
    else
        return 'iOS'
    end
end

function getEngineVersion()
    return xmod.VERSION_NAME
end

function isPrivateMode()
    return xmod.PRODUCT_CODE == xmod.PRODUCT_CODE_IPA or
           xmod.PRODUCT_CODE == xmod.PRODUCT_CODE_KUWAN
end

-- typo compaitable
function isPriviateMode()
    return isPrivateMode()
end

function lua_exit()
    xmod.exit()
end

function lua_restart()
    xmod.restart()
end

function setSysConfig(key, value)
    if key == screen.SCREENCAP_POLICY then
        value = (value == 'aggressive') and screen.SCREENCAP_POLICY_AGGRESSIVE or screen.SCREENCAP_POLICY_STANDARD
    end
    xmod_setConfig(key, value)
end

function setTimer(time, callback, ...)
    local args = { ... }
    return task.execTimer(time, callback, unpack(args))
end

function asyncExec(arguments)
    local args = { arguments, arguments.callback }
    if arguments.content then
        table.insert(args, arguments.content)
    end
    return task.execAsync(unpack(args))
end

function setStringConfig(key, value)
    storage_put(key, value)
    storage_commit()
end

function getStringConfig(key, defVal)
    return storage_get(key, defVal)
end

function setNumberConfig(key, value)
    storage_put(key, value)
    storage_commit()
end

function getNumberConfig(key, defVal)
    return tonumber(storage_get(key, defVal)) or defVal
end

function getUserID()
    local user_info, code = script.getUserInfo()
    return user_info.id, code
end

function getUserCredit()
    local user_info, code = script.getUserInfo()
    return user_info.membership, user_info.expiredTime, code
end

function getScriptID()
    local script_info, code = script.getScriptInfo()
    return script_info.id, code
end

function getCloudContent(key, token, defMsg)
    local msg, code = script.getBulletinBoard(key, token)
    if code ~= 0 then
        msg = defMsg
    end
    return msg, code
end

function getUIContent(src)
    return script.getUIData(src)
end

function init(appID, dir)
    screen.init(dir2ori(dir))
end

function findImageInRegionFuzzy(picpath, degree, x1, y1, x2, y2, alpha)
    local pos = screen_findImage(block2rect({ x1, y1, x2, y2 }), picpath, degree, screen.PRIORITY_DEFAULT, alpha)
    return pos.x, pos.y
end

function findColor(block, color, degree, hdir, vdir, priority)
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

function findColors(block, color, degree, hdir, vdir, priority)
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

function findColorInRegionFuzzy(tcolor, degree, x1, y1, x2, y2, hdir, vdir)
    return findColor({ x1, y1, x2, y2 }, tcolor, degree, hdir or 0, vdir or 0)
end

function findMultiColorInRegionFuzzy(tcolor, posandcolors, degree, x1, y1, x2, y2, hdir, vdir)
    local color = string.format('0|0|0x%06x,%s', tcolor, posandcolors)
    return findColor({ x1, y1, x2, y2 }, color, degree, hdir or 0, vdir or 0)
end

function findMultiColorInRegionFuzzy2(tcolor, posandcolors, degree, x1, y1, x2, y2, hdir, vdir)
    table.insert(posandcolors, 1, { x = 0, y = 0, color = tcolor })
    return findColor({ x1, y1, x2, y2 }, posandcolors, degree, hdir or 0, vdir or 0)
end

function findMultiColorInRegionFuzzyExt(tcolor, posandcolors, degree, x1, y1, x2, y2, hdir, vdir)
    local color = string.format('0|0|0x%06x,%s', tcolor, posandcolors)
    return findColors({ x1, y1, x2, y2 }, color, degree, hdir or 0, vdir or 0)
end

function findMultiColorInRegionFuzzyExt2(tcolor, posandcolors, degree, x1, y1, x2, y2, hdir, vdir)
    table.insert(posandcolors, 1, { x = 0, y = 0, color = tcolor })
    return findColors({ x1, y1, x2, y2 }, posandcolors, degree, hdir or 0, vdir or 0)
end

function getColor(x, y)
    return screen_getColor(x, y):toInt()
end

function getColorRGB(x, y)
    return screen_getRGB(x, y)
end

function keepScreen(enabled)
    screen_keep(enabled)
end

function snapshot(picname, x1, y1, x2, y2, quality)
    local rect = { 0, 0, 0, 0 }
    if y2 ~= nil then
        rect = block2rect({ x1, y1, x2, y2 })
    end
    return screen.snapshot(picname, rect, (quality or 1) * 100)
end

function getScreenSize()
    local size = screen_getSize()
    if size.width < size.height then
        return size.width, size.height
    else
        return size.height, size.width
    end
end

function setScreenScale(width, height, mode)
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

function resetScreenScale()
    screen.reset()
end

function getScreenDPI()
    return screen.getDPI()
end

function getScreenDirection()
    return ori2dir(screen.getOrientation())
end

function binarizeImage(args)
    local img = screen.capture(block2rect(args.rect))
    return img:binarize(args.diff)
end

function touchDown(index, x, y)
    touch_down(index, x, y)
end

function touchMove(index, x, y)
    touch_move(index, x, y)
end

function touchUp(index, x, y)
    touch_up(index, x, y)
end

function catchTouchPoint(count, timeout)
    local count = count or 1
    local timeout = timeout or 60 * 1000
    local ret = touch.captureTap(count, timeout)
    if count == 1 then
        return ret.x, ret.y
    else
        return ret
    end
end

function pressHomeKey()
    touch.press(touch.KEY_HOME)
end

function doublePressHomeKey()
    touch.doublePress(touch.KEY_HOME)
end

function pressKey(name, mode)
    touch.press(keyname2code(name), mode)
    return 0
end

function showUI(json)
    return legacy.showUI(json)
end

function resetUIConfig(file)
    legacy.resetUIConfig(file)
end

function toast(msg)
    UI.toast(tostring(msg))
end

function dialog(text, time)
    legacy.dialog(tostring(text), time or 0)
end

function dialogRet(text, button1, button2, button3, time)
    return legacy.dialogRet(tostring(text), tostring(button1), tostring(button2), tostring(button3), time or 0)
end

function dialogInput(title, format, btn)
    return unpack(legacy.dialogInput(title, format, btn))
end

function setUIOrientation(mode)
    return legacy.setUIOrientation(mode)
end

function createHUD()
    return legacy.createHUD()
end

function showHUD(id, text, size, color, bg, pos, x, y, width, height)
    legacy.showHUD(id, tostring(text), size, color, bg, pos, x, y, width, height)
end

function hideHUD(id)
    return legacy.hideHUD(id)
end

function inputText(content)
    runtime.inputText(tostring(content))
end

function runApp(appID)
    return runtime.launchApp(appID) and 0 or -1
end

function closeApp(appID)
    runtime.killApp(appID)
end

function appIsRunning(appID)
    return runtime.isAppRunning(appID) and 1 or 0
end

function isFrontApp(appID)
    return (runtime.getForegroundApp() == appID) and 1 or 0
end

function frontAppName()
    return runtime.getForegroundApp()
end

function setWifiEnable(flag)
    return runtime.setWifiEnable(flag) and 1 or 0
end

function setAirplaneMode(flag)
    return runtime.setAirplaneMode(flag) and 1 or 0
end

function setBTEnable(flag)
    return runtime.setBTEnable(flag) and 1 or 0
end

function vibrator()
    runtime.vibrate(1000)
end

function playAudio(file)
    audio.play(file)
end

function stopAudio()
    audio.stop()
end

function readPasteboard()
    return runtime.readClipboard()
end

function writePasteboard(content)
    runtime.writeClipboard(tostring(content))
end

function getLocalInfo()
    return runtime.getLocalInfo()
end

function getSystemProperty(key)
    local val = ''
    if xmod.PLATFORM == xmod.PLATFORM_ANDROID then
        val = runtime.android.getSystemProperty(key)
    end
    return val
end

function getDeviceIMEI()
    return device.getIMEI()
end

function getDeviceIMSI()
    return device.getIMSI()
end

function getDeviceUUID()
    return device.getUUID()
end

function getBatteryLevel()
    local isCharge, level = runtime.getBatteryInfo()
    local isChargeInt = 0
    if isCharge == true then
        isChargeInt = 1
    end
    return isChargeInt, level;
end

function lockDevice()
    device.lock()
end

function unlockDevice()
    device.unlock()
end

function deviceIsLock()
    return device.isLock()
end

function resetIDLETimer()
    if xmod.PLATFORM == xmod.PLATFORM_IOS then
        runtime.ios.resetLockTimer()
    end
end

function createOcrDict(dict)
    local dmocr = require('dmocr')
    return dmocr.create(dict)
end

function ocrText(instance, x1, y1, x2, y2, diffs, sim, flag, dir)
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

function createOCR(config)
    local tessocr = require('tessocr_3.02.02')
    local ocr, msg = tessocr.create(config)
    if ocr ~= nil then
        ocr = ocrSpy:new(ocr)
    end
    return ocr, msg
end

function getProduct()
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

function openUrl(url)
    runtime.openURL(url)
end
