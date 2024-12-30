--196x169 right half
--392x84 top half
--196x56 1 + 3
--196x42 1 + 4

-- Define positions
local xLeft = 10
local yStart = 5
local lineHeight = 18
local textStyle = WHITE + LEFT + SHADOWED

  
-- Variables used across all instances
local vcache -- valueId cache
local mod = {} -- module info

local function getV(id)
  -- Return the getValue of ID or nil if it does not exist
  local cid = vcache[id]
  if cid == nil then
    local info = getFieldInfo(id)
    -- use 0 to prevent future lookups
    cid = info and info.id or 0
    vcache[id] = cid
  end
  return cid ~= 0 and getValue(cid) or nil
end

local function create(zone, options)
  local widget = {
    zone = zone,
    cfg = options,
  }

  local _, rv = getVersion()
  widget.DEBUG = string.sub(rv, -5) == "-simu"

  vcache = {}
  return widget
end

local function update(widget, options)
  -- Runs if options are changed from the Widget Settings menu
  widget.cfg = options
end


local function drawRfModeText(widget, tlm, yStart)
  local modestr = (mod.RFMOD and mod.RFMOD[tlm.rfmd+1]) or ("RFMD" .. tostring(tlm.rfmd)) 
  tlm.fmode = getV("FM") or 0
  lcd.drawText(xLeft, yStart + lineHeight, "RX Connected", textStyle)
  lcd.drawText(xLeft, yStart + 2*lineHeight, modestr, textStyle)
  lcd.drawText(xLeft, yStart + 3*lineHeight, tlm.fmode, textStyle)
  return yStart
end

local function drawRssiLq(widget, tlm, yStart)
  local rssi = (tlm.ant == 1) and tlm.rssi2 or tlm.rssi1
  lcd.drawText(xLeft, yStart + 4*lineHeight, "LQ: " .. tostring(tlm.rqly) .. "%", textStyle)
  lcd.drawText(xLeft, yStart + 5*lineHeight, "RSSI: " .. tostring(rssi) .. "dBm", textStyle)
  return yStart
end

local function fieldGetString(data, off)
  local startOff = off
  while data[off] ~= 0 do
    data[off] = string.char(data[off])
    off = off + 1
  end

  return table.concat(data, nil, startOff, off - 1), off + 1
end

local function parseDeviceInfo(data)
  if data[2] ~= 0xEE then return end -- only interested in TX info
  local name, off = fieldGetString(data, 3)
  mod.name = name
  -- off = serNo ('ELRS') off+4 = hwVer off+8 = swVer
  mod.vMaj = data[off+9]
  mod.vMin = data[off+10]
  mod.vRev = data[off+11]
  mod.vStr = string.format("%s (%d.%d.%d)",
    mod.name, mod.vMaj, mod.vMin, mod.vRev)
  if mod.vMaj == 3 then
    mod.RFMOD = {"", "25Hz", "50Hz", "100Hz", "100HzFull", "150Hz", "200Hz", "250Hz", "333HzFull", "500Hz", "D250", "D500", "F500", "F1000" }
   -- Note: Always use 2.4 limits
    mod.RFRSSI = {-128, -123, -115, -117, -112, -112, -112, -108, -105, -105, -104, -104, -104, -104}
  else
    mod.RFMOD = {"", "25Hz", "50Hz", "100Hz", "150Hz", "200Hz", "250Hz", "500Hz"}
    mod.RFRSSI = {-128, -123, -115, -117, -112, -112, -108, -105}
  end
  return true
end

local function updateElrsVer()
  local command, data = crossfireTelemetryPop()
  if command == 0x29 then
    if parseDeviceInfo(data) then
      -- Get rid of all the functions, only update once
      parseDeviceInfo = nil
      fieldGetString = nil
      updateElrsVer = nil
      mod.lastUpd = nil
    end
    return
  end

  local now = getTime()
  -- Poll the module every second
  if (mod.lastUpd or 0) + 100 < now then
    crossfireTelemetryPush(0x28, {0x00, 0xEA})
    mod.lastUpd = now
  end
end

local function refresh(widget, event, touchState)

  -- Runs periodically only when widget instance is visible
  -- If full screen, then event is 0 or event value, otherwise nil
  if updateElrsVer then updateElrsVer() end
  --updateWidgetSize(widget, event)
  local yStart = 5

  local tlm = { tpwr = getV("TPWR") }
  
  if not widget.DEBUG and (tlm.tpwr == nil or tlm.tpwr == 0) then
    lcd.drawText(xLeft, yStart + lineHeight, "No RX Connected", textStyle)
    widget.ctx = nil
    return
  end

  if widget.DEBUG then
    tlm.rfmd = 7 tlm.rssi1 = -87 tlm.rssi2 = -93 tlm.rqly = 99 tlm.ant = 1 tlm.tpwr = 50
  else
    tlm.rfmd = getV("RFMD") tlm.rssi1 = getV("1RSS") tlm.rssi2 = getV("2RSS") tlm.rqly = getV("RQly") tlm.ant = getV("ANT")
  end
  if widget.ctx == nil then
    widget.ctx = {}
  end

  -- Rf Mode + FMode
  yStart = drawRfModeText(widget, tlm, yStart)
  -- RSSI / LQ + FMode
  yStart = drawRssiLq(widget, tlm, yStart)
  -- TX Power
  lcd.drawText(xLeft, yStart + 6*lineHeight, "Power: " .. tostring(tlm.tpwr) .. "mW", textStyle)


end

return {
  name = "TXWidget",
  options = {},
  create = create,
  update = update,
  refresh = refresh,
  options = {}
}

