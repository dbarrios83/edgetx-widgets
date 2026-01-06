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

  return {
    zone = zone,
    cfg = options or {},
    icons = icons,
    stick = stick,
    gpsLat = 0,
    gpsLon = 0,
    gpsValid = false,
    tlm = nil,
    lastTpwr = 0,
  }
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
  local latVal = (hasGpsTable and gpsValue.lat) or 0
  local lonVal = (hasGpsTable and gpsValue.lon) or 0

  -- Require a real GPS table and non-zero coordinates before showing as valid
  local isValid = hasGpsTable and not ((latVal or 0) == 0 and (lonVal or 0) == 0)

  if isValid then
    widget.gpsLat = latVal
    widget.gpsLon = lonVal
    widget.gpsValid = true
  else
    widget.gpsValid = false
  end

  local baseY = utils.getBaseY(yStart, baseYOffset)
  local rowY  = baseY + 2 * lineHeight
  local textX = utils.clampToRightCol(xCenter + xOffset, rightColLeft)

  if not widget.gpsValid then
    local msg = ((widget.gpsLat or 0) == 0 and (widget.gpsLon or 0) == 0) and "No GPS" or "Last GPS fix"
    utils.text(textX, rowY, msg, utils.S.left, utils.S.mid, 0)
    return
  end

  local color = utils.satIconColor(sats)
  local icon = (color == "red" and widget.icons and widget.icons.sat_red)
           or  (color == "yellow" and widget.icons and widget.icons.sat_yellow)
           or  (color == "green" and widget.icons and widget.icons.sat_green)
  if icon then lcd.drawBitmap(icon, xCenter + 5, rowY + 2) end

  utils.text(textX, rowY, string.format("Sats: %d", sats), utils.S.left, utils.S.mid, 0)
end

-- -----------------------
-- RX details grid (secondary typography)
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

  utils.text(col1X + 5, gridY,           string.format("CUR: %.2fA", curr), A, SZ, 0)
  utils.text(col2X + 5, gridY,           string.format("Power: %dmW", tpwr), A, SZ, 0)
  utils.text(col3X + 5, gridY,           "FMODE: " .. fmodeStr, A, SZ, 0)
  if rssi1 ~= 0 then utils.text(col4X + 5, gridY, string.format("RSSI1: %ddBm", rssi1), A, SZ, 0) end

  utils.text(col1X + 5, gridY + rowHeight, string.format("CAP: %dmAh", capa), A, SZ, 0)
  utils.text(col2X + 5, gridY + rowHeight, string.format("ANT: %d", ant), A, SZ, 0)
  utils.text(col3X + 5, gridY + rowHeight, "RFMD: " .. rfmdStr, A, SZ, 0)
  if rssi2 ~= 0 then utils.text(col4X + 5, gridY + rowHeight, string.format("RSSI2: %ddBm", rssi2), A, SZ, 0) end

  utils.drawGridLines(leftMargin, rightMargin, col2X, col3X, col4X, gridY, rowHeight, 2, GREY)
end

-- -----------------------
-- Coordinates (centered pair, consistent style)
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
  local leftX  = centerX - 90
  local rightX = centerX + 90

  local function drawAxesAndDot(cx, cy, idX, idY)
    for i = -1, 1 do
      lcd.drawLine(cx - axis, cy + i, cx + axis, cy + i, SOLID, WHITE)
      lcd.drawLine(cx + i, cy - axis, cx + i, cy + axis, SOLID, WHITE)
    end

    local vx = idX and (getValue(idX) or 0) or 0
    local vy = idY and (getValue(idY) or 0) or 0
    local px = math.floor(cx + (vx / 1024) * axis + 0.5)
    local py = math.floor(cy - (vy / 1024) * axis + 0.5)

    utils.drawSquare(cx, cy, 3, GREY, WHITE)
    utils.drawSquare(px, py, 4, GREEN, WHITE)
  end

  drawAxesAndDot(leftX,  yCenter, widget.stick.rud, widget.stick.thr)
  drawAxesAndDot(rightX, yCenter, widget.stick.ail, widget.stick.ele)
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

  -- Reserve top-right column for Date/Time/Timers to prevent overlap
  local rightColW = 95
  local rightColLeft = xRight - rightColW

  -- Center telemetry should live in the area LEFT of the right column
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

    local gridY = yStart + 120
    if widget.cfg.ShowRxDetails == 1 then
      drawRxDetailGrid(widget, z, gridY, widget.tlm)
    end

    local gpsY = gridY + 50
    if widget.cfg.ShowCoordinates == 1 then
      drawGpsCoordinates(widget, gpsY)
    end
  else
    utils.text(xCenter + 40, yStart + 5, "No RX telemetry", utils.S.left, 0, 0)
  end

  -- Right column: Date/time + timers
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

  -- Sticks
  local axisCenterOffset = 45
  local bottomMargin = 20
  local sticksY = z.y + z.h - axisCenterOffset - bottomMargin
  if widget.cfg.ShowSticks == 1 then
    drawSticks(widget, z, sticksY)
  end

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
