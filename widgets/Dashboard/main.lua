-- Minimal Dashboard: show model name big at top-left
-- Fix: reserve a right column for time/timers so center telemetry never overlaps

local utils = loadScript("/WIDGETS/common/utils.lua")()

local options = {
  { "Format24H", BOOL, 1 },
  { "ShowSticks", BOOL, 1 },
  { "ShowRxDetails", BOOL, 1 },
  { "ShowCoordinates", BOOL, 1 },
  { "ShowTimers", BOOL, 1 },
}

-- =========================
-- ELRS Version Helper (CRSF device info)
-- State lives in widget.elrs
-- =========================
local elrs = {}

local function elrs_fieldGetString(data, off)
  local startOff = off
  while off <= #data and data[off] ~= 0 do
    data[off] = string.char(data[off])
    off = off + 1
  end
  return table.concat(data, nil, startOff, off - 1), off + 1
end

local function elrs_parseDeviceInfo(state, data)
  -- Keep identical to your working code: only accept TX info (0xEE)
  if not data or data[2] ~= 0xEE then return false end

  local name, off = elrs_fieldGetString(data, 3)
  state.mod.name = name or "ELRS"

  state.mod.vMaj = data[off + 9]
  state.mod.vMin = data[off + 10]
  state.mod.vRev = data[off + 11]

  if type(state.mod.vMaj) ~= "number"
     or type(state.mod.vMin) ~= "number"
     or type(state.mod.vRev) ~= "number" then
    state.mod.vStr = state.mod.name
    return true
  end

  state.mod.vStr = string.format("%s (%d.%d.%d)",
    state.mod.name,
    state.mod.vMaj,
    state.mod.vMin,
    state.mod.vRev
  )

  return true
end

function elrs.init(state)
  state.mod = {}
  state.lastUpd = 0
  state.done = false
end

function elrs.update(state)
  if not state or state.done then return end
  if not crossfireTelemetryPop or not crossfireTelemetryPush then return end

  local command, data = crossfireTelemetryPop()
  if command == 0x29 then
    if elrs_parseDeviceInfo(state, data) then
      state.done = true
      state.lastUpd = 0
    end
    return
  end

  local now = getTime()
  if (state.lastUpd or 0) + 100 < now then
    crossfireTelemetryPush(0x28, {0x00, 0xEA})
    state.lastUpd = now
  end
end

function elrs.getString(state)
  return (state and state.mod and state.mod.vStr) or "ELRS"
end

local function drawElrsVersion(widget)
  local z = widget.zone or { x = 0, y = 0, w = 320, h = 240 }
  local xLeft = z.x + 5
  local yBottom = z.y + z.h - 18
  local verStr = elrs.getString(widget.elrs)
  utils.text(xLeft, yBottom, verStr, utils.S.left, utils.S.sml, 0)
end

-- -----------------------
-- create / update
-- -----------------------
local function create(zone, options)
  local battIconPath = "/WIDGETS/common/icons/battery-%s.png"
  local connIconPath = "/WIDGETS/common/icons/connection-%s.png"
  local satIconPath  = "/WIDGETS/common/icons/satellite-%s.png"

  local icons = {
    dead   = utils.safeOpen(string.format(battIconPath, "dead")),
    low    = utils.safeOpen(string.format(battIconPath, "low")),
    yellow = utils.safeOpen(string.format(battIconPath, "yellow")),
    ok     = utils.safeOpen(string.format(battIconPath, "ok")),
    full   = utils.safeOpen(string.format(battIconPath, "full")),

    conn_red    = utils.safeOpen(string.format(connIconPath, "red")),
    conn_yellow = utils.safeOpen(string.format(connIconPath, "yellow")),
    conn_green  = utils.safeOpen(string.format(connIconPath, "green")),
    conn_black  = utils.safeOpen(string.format(connIconPath, "black")),

    sat_red    = utils.safeOpen(string.format(satIconPath, "red")),
    sat_yellow = utils.safeOpen(string.format(satIconPath, "yellow")),
    sat_green  = utils.safeOpen(string.format(satIconPath, "green")),
  }

  local stick = {
    rud = (getFieldInfo('rud') or {}).id,
    thr = (getFieldInfo('thr') or {}).id,
    ail = (getFieldInfo('ail') or {}).id,
    ele = (getFieldInfo('ele') or {}).id,
  }

  local widget = {
    zone = zone,
    cfg = options or {},
    icons = icons,
    stick = stick,

    -- ELRS state per widget instance
    elrs = { mod = {}, lastUpd = 0, done = false },

    gpsLat = 0,
    gpsLon = 0,
    gpsValid = false,
    lastFixLat = nil,
    lastFixLon = nil,
    tlm = nil,
    lastTpwr = 0,
  }

  elrs.init(widget.elrs)
  return widget
end

local function update(widget, options)
  widget.cfg = options or {}
end

-- Spacing constants for RX telemetry rows
local lineHeight  = 35
local baseYOffset = 2
local xOffset     = 40 -- spacing between icons and text in center stack

-- -----------------------
-- Top-left: Model + TX batt
-- -----------------------
local function drawModelName(xLeft, yStart)
  local modelName = "Model"
  if model and type(model.getInfo) == "function" then
    local info = model.getInfo()
    if info and info.name and info.name ~= "" then
      modelName = info.name
    end
  end
  utils.text(xLeft, yStart, modelName, utils.S.left, utils.S.mid, utils.S.bold)
end

local function drawTxBattery(widget, xLeft, yStart)
  local txV, state = utils.txBatteryInfo()
  local battText = string.format("%.1fV", txV)

  local iconY = yStart + lineHeight
  local textY = utils.getBaseY(iconY, baseYOffset)

  utils.text(xLeft + 35, textY, battText, utils.S.left, utils.S.mid, 0)

  local icon = widget.icons and widget.icons[state]
  if icon then lcd.drawBitmap(icon, xLeft, iconY) end
end

-- -----------------------
-- Right column: Date/Time + Timers
-- -----------------------
local function drawDateTime(widget, xRight, yStart)
  local datetime = getDateTime()
  if not datetime then return end

  local is24Hour = widget.cfg.Format24H == 1
  local timeStr = utils.getFormattedTime(datetime, is24Hour)
  local dateStr = string.format("%02d %s", datetime.day, utils.months[datetime.mon] or "???")

  utils.text(xRight, yStart,      dateStr, utils.S.right, 0, 0)
  utils.text(xRight, yStart + 18, timeStr, utils.S.right, 0, 0)
end

local function drawTimer(i, x, y)
  local t = model.getTimer(i)
  if t ~= nil and t.mode and t.mode > 0 then
    local h = math.floor(t.value / 3600)
    local m = math.floor(t.value / 60) - h * 60
    local s = t.value - h * 3600 - m * 60
    local label = t.name or ("T" .. (i + 1))
    local str = (h > 0)
      and string.format("%s %02d:%02d:%02d", label, h, m, s)
      or  string.format("%s %02d:%02d", label, m, s)

    utils.text(x, y, str, utils.S.right, 0, 0)
    return true
  end
  return false
end

-- -----------------------
-- Center stack: Connection + LQ + RX batt + Sats
-- -----------------------
local function drawConnectionIcon(widget, xCenter, yStart, tpwr, rqly)
  local state = utils.connectionIconState(tpwr, rqly)
  local icon = (state == "red" and widget.icons and widget.icons.conn_red)
           or  (state == "yellow" and widget.icons and widget.icons.conn_yellow)
           or  (state == "green" and widget.icons and widget.icons.conn_green)
           or  (state == "black" and widget.icons and widget.icons.conn_black)
  if icon then lcd.drawBitmap(icon, xCenter, yStart) end
end

local function drawLinkQualityCenter(widget, xCenter, yStart, tlm, rightColLeft)
  local rqly = (tlm and tlm.rqly) or 0
  local baseY = utils.getBaseY(yStart, baseYOffset)

  local textX = utils.clampToRightCol(xCenter + xOffset, rightColLeft)
  utils.text(textX, baseY - 5, string.format("LQ: %d%%", rqly), utils.S.left, utils.S.mid, utils.S.bold)
end

local function drawRxBatteryBelowLq(widget, xCenter, yStart, tlm, rightColLeft)
  local totalBatt = (tlm and tlm.rxbt) or 0
  local voltagePerCell, cellCount = utils.getVoltagePerCell(totalBatt)
  local rxBt = tonumber(voltagePerCell) or 0

  local baseY = utils.getBaseY(yStart, baseYOffset)
  local rowY = baseY + lineHeight

  local state = utils.rxCellState(rxBt)
  local icon = widget.icons and widget.icons[state]
  if icon then lcd.drawBitmap(icon, xCenter + 5, rowY - 2) end

  local textX = utils.clampToRightCol(xCenter + xOffset, rightColLeft)
  if cellCount > 1 then
    utils.text(textX, rowY, string.format("%.2fV-%dS", rxBt, cellCount), utils.S.left, utils.S.mid, 0)
  else
    utils.text(textX, rowY, string.format("%.1fV", totalBatt), utils.S.left, utils.S.mid, 0)
  end
end

local function drawSatsBelowRx(widget, xCenter, yStart, tlm, rightColLeft)
  local sats = (tlm and tonumber(tlm.sats)) or 0
  local gpsValue = getValue("GPS")
  local hasGpsTable = (type(gpsValue) == "table")
  
  local baseY = utils.getBaseY(yStart, baseYOffset)
  local rowY  = baseY + 2 * lineHeight
  local textX = utils.clampToRightCol(xCenter + xOffset, rightColLeft)

  -- If no GPS table, show "No GPS"
  if not hasGpsTable then
    widget.gpsValid = false
    utils.text(textX, rowY, "No GPS", utils.S.left, utils.S.mid, 0)
    return
  end
  
  -- GPS table exists - extract coordinates
  local latVal = (type(gpsValue.lat) == "number") and gpsValue.lat or 0
  local lonVal = (type(gpsValue.lon) == "number") and gpsValue.lon or 0
  
  -- Cache coordinates and mark as valid (GPS table exists)
  widget.gpsLat = latVal
  widget.gpsLon = lonVal
  widget.gpsValid = true

  -- Update last non-zero fix
  if not (latVal == 0 and lonVal == 0) then
    widget.lastFixLat = latVal
    widget.lastFixLon = lonVal
  end

  -- Always show satellite count if GPS table exists
  local color = utils.satIconColor(sats)
  local icon = (color == "red" and widget.icons and widget.icons.sat_red)
           or  (color == "yellow" and widget.icons and widget.icons.sat_yellow)
           or  (color == "green" and widget.icons and widget.icons.sat_green)
  if icon then lcd.drawBitmap(icon, xCenter + 5, rowY + 2) end

  utils.text(textX, rowY, string.format("Sats: %d", sats), utils.S.left, utils.S.mid, 0)
end

-- -----------------------
-- RX details grid
-- -----------------------
local function drawRxDetailGrid(widget, z, yTop, tlm)
  local rfmd  = (tlm and tlm.rfmd) or 0
  local rssi1 = (tlm and tlm.rssi1) or 0
  local rssi2 = (tlm and tlm.rssi2) or 0
  local ant   = (tlm and tlm.ant) or 0
  local fmode = (tlm and tlm.fmode) or 0
  local tpwr  = (tlm and tlm.tpwr) or 0
  local curr  = (tlm and tlm.curr) or 0
  local capa  = (tlm and tlm.capa) or 0

  local fmodeStr = tostring(fmode)
  local rfmdStr  = utils.getRFMDString(rfmd)

  local leftMargin  = z.x + 5
  local rightMargin = z.x + z.w - 5
  local usableWidth = rightMargin - leftMargin
  local colWidth    = math.floor(usableWidth / 4)

  local col1X = leftMargin
  local col2X = leftMargin + colWidth
  local col3X = leftMargin + colWidth * 2
  local col4X = leftMargin + colWidth * 3

  local rowHeight = 18
  local gridY = yTop

  local A = utils.S.left
  local SZ = utils.S.sml

  utils.text(col1X + 5, gridY,             string.format("CUR: %.2fA", curr), A, SZ, 0)
  utils.text(col2X + 5, gridY,             string.format("Power: %dmW", tpwr), A, SZ, 0)
  utils.text(col3X + 5, gridY,             "FMODE: " .. fmodeStr, A, SZ, 0)
  if rssi1 ~= 0 then utils.text(col4X + 5, gridY, string.format("RSSI1: %ddBm", rssi1), A, SZ, 0) end

  utils.text(col1X + 5, gridY + rowHeight, string.format("CAP: %dmAh", capa), A, SZ, 0)
  utils.text(col2X + 5, gridY + rowHeight, string.format("ANT: %d", ant), A, SZ, 0)
  utils.text(col3X + 5, gridY + rowHeight, "RFMD: " .. rfmdStr, A, SZ, 0)
  if rssi2 ~= 0 then utils.text(col4X + 5, gridY + rowHeight, string.format("RSSI2: %ddBm", rssi2), A, SZ, 0) end

  utils.drawGridLines(leftMargin, rightMargin, col2X, col3X, col4X, gridY, rowHeight, 2, GREY)
end

-- -----------------------
-- Coordinates
-- -----------------------
local function drawGpsCoordinates(widget, yTop)
  if not widget or not widget.gpsValid then return end

  local z = widget.zone or { x = 0, y = 0, w = 320, h = 240 }
  local cx = (z.x or 0) + math.floor((z.w or 320) / 2)

  local latStr, lonStr = utils.formatLatLon(widget.gpsLat, widget.gpsLon)
  utils.textLR(cx, yTop, "Lat: " .. latStr, "Lon: " .. lonStr, 10, utils.S.base, utils.S.sml, 0)
end

-- -----------------------
-- Sticks
-- -----------------------
local function drawSticks(widget, z, yCenter)
  local axis = 45
  local centerX = z.x + math.floor(z.w / 2)
  local leftX  = centerX - 110
  local rightX = centerX + 110

  local function drawAxesAndDot(cx, cy, idX, idY, side)
    for i = -1, 1 do
      lcd.drawLine(cx - axis, cy + i, cx + axis, cy + i, SOLID, WHITE)
      lcd.drawLine(cx + i, cy - axis, cx + i, cy + axis, SOLID, WHITE)
    end

    local vx = idX and (getValue(idX) or 0) or 0
    local vy = idY and (getValue(idY) or 0) or 0
    local px = math.floor(cx + (vx / 1024) * axis + 0.5)
    local py = math.floor(cy - (vy / 1024) * axis + 0.5)

    local vxPercent = math.floor((vx / 1024) * 100 + 0.5)
    local vyPercent = math.floor((vy / 1024) * 100 + 0.5)

    utils.drawSquare(cx, cy, 3, GREY, WHITE)
    utils.drawSquare(px, py, 4, GREEN, WHITE)

    if side == "left" then
      utils.text(cx - axis - 43, cy - 5, string.format("R:%d", vxPercent), utils.S.left, utils.S.sml, 0)
      utils.text(cx - 18, cy - axis - 18, string.format("T:%d", vyPercent), utils.S.left, utils.S.sml, 0)
    else
      utils.text(cx - axis - 43, cy - 5, string.format("A:%d", vxPercent), utils.S.left, utils.S.sml, 0)
      utils.text(cx - 18, cy - axis - 18, string.format("E:%d", vyPercent), utils.S.left, utils.S.sml, 0)
    end
  end

  drawAxesAndDot(leftX,  yCenter, widget.stick.rud, widget.stick.thr, "left")
  drawAxesAndDot(rightX, yCenter, widget.stick.ail, widget.stick.ele, "right")
end

-- -----------------------
-- Telemetry cache
-- -----------------------
local function updateTelemetryCache(widget, tpwr, justConnected, justDisconnected)
  if justDisconnected then
    widget.tlm = nil
    return
  end
  if tpwr <= 0 then return end

  if justConnected then
    widget.tlm = {rfmd=0, rssi1=0, rssi2=0, ant=0, fmode=0, tpwr=0, curr=0, capa=0, sats=0, rxbt=0, rqly=0}
    widget.gpsLat = 0
    widget.gpsLon = 0
    widget.gpsValid = false
    return
  end

  widget.tlm = widget.tlm or {rfmd=0, rssi1=0, rssi2=0, ant=0, fmode=0, tpwr=0, curr=0, capa=0, sats=0, rxbt=0, rqly=0}
  widget.tlm.rfmd  = tonumber(getValue("RFMD")) or 0
  widget.tlm.rssi1 = tonumber(getValue("1RSS")) or 0
  widget.tlm.rssi2 = tonumber(getValue("2RSS")) or 0
  widget.tlm.ant   = tonumber(getValue("ANT")) or 0
  widget.tlm.fmode = getValue("FM") or 0
  widget.tlm.tpwr  = tpwr
  widget.tlm.curr  = tonumber(getValue("Curr")) or 0
  widget.tlm.capa  = tonumber(getValue("Capa")) or 0
  widget.tlm.sats  = tonumber(getValue("Sats")) or 0
  widget.tlm.rxbt  = tonumber(getValue("RxBt")) or 0
  widget.tlm.rqly  = tonumber(getValue("RQly")) or 0
end

local function drawOsVersionBottomRight(widget)
  local z = (widget and widget.zone) or { x = 0, y = 0, w = 320, h = 240 }
  local xRight = z.x + z.w - 5
  local yBottom = z.y + z.h - 18
  local _, _, major, minor, rev, osname = getVersion()
  local strVer = (osname or "EdgeTX") .. " " .. major .. "." .. minor .. "." .. rev
  utils.text(xRight, yBottom, strVer, utils.S.right, utils.S.sml, 0)
end

-- -----------------------
-- Main refresh
-- -----------------------
local function refresh(widget)
  local z = widget.zone or { x = 0, y = 0, w = 320, h = 240 }
  local xLeft  = z.x + 10
  local yStart = z.y + 5
  local xRight = z.x + z.w - 10

  -- Update ELRS version (works even without RX, as long as CRSF device info is available)
  elrs.update(widget.elrs)

  local rightColW = 95
  local rightColLeft = xRight - rightColW
  local xCenter = z.x + math.floor((rightColLeft - z.x) / 2)

  drawModelName(xLeft, yStart)
  drawTxBattery(widget, xLeft, yStart)

  local tpwr = tonumber(getValue("TPWR")) or 0
  local wasConnected = (widget.lastTpwr or 0) > 0
  local justConnected = (not wasConnected) and tpwr > 0
  local justDisconnected = wasConnected and tpwr <= 0

  updateTelemetryCache(widget, tpwr, justConnected, justDisconnected)

  local rqly = (widget.tlm and widget.tlm.rqly) or tonumber(getValue("RQly")) or 0
  drawConnectionIcon(widget, xCenter, yStart, tpwr, rqly)

  widget.lastTpwr = tpwr

  if tpwr > 0 then
    drawLinkQualityCenter(widget, xCenter, yStart, widget.tlm, rightColLeft)
    drawRxBatteryBelowLq(widget, xCenter, yStart, widget.tlm, rightColLeft)
    drawSatsBelowRx(widget, xCenter, yStart, widget.tlm, rightColLeft)

    -- Coordinates just below Sats
    local baseY = utils.getBaseY(yStart, baseYOffset)
    local coordsY = baseY + 3 * lineHeight
    if widget.cfg.ShowCoordinates == 1 then
      drawGpsCoordinates(widget, coordsY)
    end

    -- Grid below coordinates (or just below sats if coords hidden)
    local gridY
    if widget.cfg.ShowCoordinates == 1 then
      gridY = coordsY + 25
    else
      gridY = baseY + 3 * lineHeight + 15
    end
    if widget.cfg.ShowRxDetails == 1 then
      drawRxDetailGrid(widget, z, gridY, widget.tlm)
    end
  else
    utils.text(xCenter + 40, yStart + 5, "No RX telemetry", utils.S.left, 0, 0)

    -- If we have a last GPS fix, show it as last location with label and larger coords
    if widget.cfg.ShowCoordinates == 1 and widget.lastFixLat and widget.lastFixLon then
      widget.gpsLat = widget.lastFixLat
      widget.gpsLon = widget.lastFixLon
      widget.gpsValid = true
      local baseY = utils.getBaseY(yStart, baseYOffset)
      local coordsY = baseY + 3 * lineHeight
      local z = widget.zone or { x = 0, y = 0, w = 320, h = 240 }
      local cx = (z.x or 0) + math.floor((z.w or 320) / 2)
      -- Label above (smaller than coords)
      lcd.drawText(cx, coordsY - 18, "Last location", WHITE + SHADOWED + CENTER)
      -- Larger coordinates
      local latStr, lonStr = utils.formatLatLon(widget.gpsLat, widget.gpsLon)
      utils.textLR(cx, coordsY, "Lat: " .. latStr, "Lon: " .. lonStr, 10, utils.S.base, utils.S.small, 0)
    end
  end

  drawDateTime(widget, xRight, yStart)

  if widget.cfg.ShowTimers == 1 then
    local tLineHeight = 18
    local timerY = yStart + 2 * tLineHeight
    for i = 0, 2 do
      if drawTimer(i, xRight, timerY) then
        timerY = timerY + tLineHeight
      end
    end
  end

  local axisCenterOffset = 45
  local bottomMargin = 25
  local sticksY = z.y + z.h - axisCenterOffset - bottomMargin
  if widget.cfg.ShowSticks == 1 then
    drawSticks(widget, z, sticksY)
  end

  drawElrsVersion(widget)
  drawOsVersionBottomRight(widget)
end

local function destroy(widget)
  if widget and widget.icons then
    for _, bmp in pairs(widget.icons) do
      if bmp and bmp.delete then bmp:delete() end
    end
    widget.icons = nil
  end
end

return {
  name = "Dashboard",
  options = options,
  create = create,
  update = update,
  refresh = refresh,
  destroy = destroy,
}
