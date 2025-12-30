
-- Constants
local utils = loadScript("/WIDGETS/common/utils.lua")()

local textStyle = RIGHT + WHITE + SHADOWED
local lineHeight = 18
local iconPathFmt = "/WIDGETS/ClockWidget/BMP/connection-%s.png"

-- get timers and draw them unless mode == 'off'
local function drawTimer(i, x, y, style)
  local t = model.getTimer(i)
  if t ~= nil and t.mode > 0 then
    local h = math.floor(t.value/3600)
    local m = math.floor(t.value/60) - h*60
    local s = t.value - h*3600 - m*60
    local str = string.format("%s %02d:%02d", t.name, m, s)
    if h > 0 then str = string.format("%s %02d:%02d:%02d", t.name, h, m, s) end
    lcd.drawText(x, y, str, style)
    return true
  end
  return false
end

-- Widget creation: preload bitmaps
local function create(zone, options)
  local icons = {
    red = Bitmap.open(string.format(iconPathFmt, "red")),
    yellow = Bitmap.open(string.format(iconPathFmt, "yellow")),
    green = Bitmap.open(string.format(iconPathFmt, "green")),
    black = Bitmap.open(string.format(iconPathFmt, "black")),
  }

  return {
    zone = zone,
    cfg = options,
    icons = icons,
  }
end

-- Widget config update
local function update(widget, options)
  widget.cfg = options
end

-- Main drawing function
local function refresh(widget, event, touchState)
  local datetime = getDateTime()
  if not datetime then
    lcd.drawText(widget.zone.x + 10, widget.zone.y + 10, "No Date/Time", MIDSIZE + RED)
    return
  end

  local tpwr = tonumber(getValue("TPWR")) or 0
  local iconState

  if tpwr > 0 then
    local rqly = tonumber(getValue("RQly")) or 0
    if rqly < 60 then
      iconState = "red"
    elseif rqly < 80 then
      iconState = "yellow"
    else
      iconState = "green"
    end
  else
    iconState = "black"
  end

  local is24Hour = widget.cfg.Format24H == 1
  local timeStr = utils.getFormattedTime(datetime, is24Hour)
  local dateStr = string.format("%02d %s", datetime.day, utils.months[datetime.mon] or "???")
  local isoStr = string.format("%04d-%02d-%02d %02d:%02d", datetime.year, datetime.mon, datetime.day, datetime.hour, datetime.min)

  local xRight = widget.zone.x + widget.zone.w - 10
  local yStart = widget.zone.y + 5
  local iconRight = xRight - (is24Hour and 85 or 110)
  if widget.cfg.iso8601 == 1 then iconRight = xRight - 160 end

  local icon = widget.icons[iconState]
  if icon then
    lcd.drawBitmap(icon, iconRight, yStart + 2)
  end

  if widget.cfg.iso8601 == 0 then
    lcd.drawText(xRight, yStart, timeStr, textStyle)
    lcd.drawText(xRight, yStart + lineHeight, dateStr, textStyle)
  else
    lcd.drawText(xRight, yStart, isoStr, textStyle)
  end

  if widget.cfg.timers == 1 then
    -- define height - adjust based on one line ISO or two line date/time
    local timerY = yStart + lineHeight
    if widget.cfg.iso8601 == 0 then timerY = timerY + lineHeight end

    -- draw up to three timers (0,1,2)
    for i=0,2 do
      if drawTimer(i,xRight,timerY,textStyle) then
        timerY = timerY + lineHeight
      end
    end
  end
end

-- Return widget definition
return {
  name = "ClockWidget",
  create = create,
  update = update,
  refresh = refresh,
  options = {
    {"Format24H", BOOL, 1}, -- 1 = 24-hour, 0 = 12-hour

    -- show ISO 8601 Timestamp (%Y-%m-%d %H:%M)
    -- instead of two lines with date and time
    { "iso8601", BOOL, 0 },

    -- show timers below timestamp
    -- only shows ones with mode other than 'off'
    { "timers", BOOL, 0 },
  },
}
