-- Unified Sim Widget: Combines SimModel and SimStick functionality
-- Displays model info, battery, date/time, and stick positions

local utils = loadScript("/WIDGETS/common/utils.lua")()
local textStyle = WHITE + SHADOWED
local textStyleRight = RIGHT + WHITE + SHADOWED
local lineHeight = 35
local baseYOffset = 2
local xLeft = 10
local yStart = 5

local options = {
  { "Format24H", BOOL, 1 },
}

local idTxV

-- Stick field IDs
local fieldInfo = {
    rud = getFieldInfo('rud').id,
    thr = getFieldInfo('thr').id,
    ail = getFieldInfo('ail').id,
    ele = getFieldInfo('ele').id
}

local sticks = {
    {name = 'A', idX = fieldInfo.ail, idY = fieldInfo.ele, align = RIGHT},
    {name = 'T', idX = fieldInfo.rud, idY = fieldInfo.thr, align = LEFT}
}

local function create(zone, options)
  local battIconPath = "/WIDGETS/common/icons/battery-%s.png"
  local icons = {
    dead   = utils.safeOpen(string.format(battIconPath, "dead")),
    low    = utils.safeOpen(string.format(battIconPath, "low")),
    yellow = utils.safeOpen(string.format(battIconPath, "yellow")),
    ok     = utils.safeOpen(string.format(battIconPath, "ok")),
    full   = utils.safeOpen(string.format(battIconPath, "full")),
  }

  local widget = {
    zone = zone,
    cfg = options,
    icons = icons,
    DEBUG = string.sub(select(2, getVersion()), -5) == "-simu"
  }

  idTxV = getFieldInfo('tx-voltage').id
  return widget
end

local function update(widget, options)
  widget.cfg = options
end

local function drawModelInfo(widget)
  local modelName = model.getInfo().name
  lcd.drawText(xLeft, yStart, modelName, textStyle + MIDSIZE + BOLD)
end

local function drawBattery(widget)
  local txV, state = utils.txBatteryInfo()
  local battText = string.format("%.1fV", txV)

  local iconY = yStart + lineHeight
  local textY = utils.getBaseY(iconY, baseYOffset)

  utils.text(xLeft + 35, textY, battText, utils.S.left, utils.S.mid, 0)

  local icon = widget.icons and widget.icons[state]
  if icon then lcd.drawBitmap(icon, xLeft, iconY) end
end

local function drawOsVersionBottomRight(widget)
  local z = widget.zone or { x = 0, y = 0, w = 320, h = 240 }
  local xRight = z.x + z.w - 5
  local yBottom = z.y + z.h - 18
  local _, _, major, minor, rev, osname = getVersion()
  local strVer = (osname or "EdgeTX") .. " " .. major .. "." .. minor .. "." .. rev
  utils.text(xRight, yBottom, strVer, utils.S.right, utils.S.sml, 0)
end

local function drawDateAndTime(widget)
  local datetime = getDateTime()
  if not datetime then return end

  local xRight = widget.zone.x + widget.zone.w - 10
  local yStart = widget.zone.y + 5

  local is24Hour = widget.cfg.Format24H == 1
  local timeStr = utils.getFormattedTime(datetime, is24Hour)
  local dateStr = string.format("%02d %s", datetime.day, utils.months[datetime.mon] or "???")

  utils.text(xRight, yStart,      dateStr, utils.S.right, 0, 0)
  utils.text(xRight, yStart + 18, timeStr, utils.S.right, 0, 0)
end

local function drawSticksChart(widget)
    local axis = 45
    local centerX = widget.zone.x + math.floor(widget.zone.w / 2)
    local centerY = widget.zone.y + math.floor(widget.zone.h / 2) + 10
    
    local leftX = centerX - 90
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

    drawAxesAndDot(leftX, centerY, sticks[2].idX, sticks[2].idY)
    drawAxesAndDot(rightX, centerY, sticks[1].idX, sticks[1].idY)
end

local function refresh(widget, event, touchState)
  -- Draw model info, battery, date/time
  drawModelInfo(widget)
  drawBattery(widget)
  drawDateAndTime(widget)
  
  -- Draw sticks
  drawSticksChart(widget)
  
  drawOsVersionBottomRight(widget)
end

return {
  name = "SimWidget",
  options = options,
  create = create,
  update = update,
  refresh = refresh
}
