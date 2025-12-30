-- Battery Widget Optimized with Preloading and Destroy
local utils = loadScript("/WIDGETS/common/utils.lua")()
local textStyle = RIGHT + WHITE + SHADOWED
local midLineHeight = 33
local lineHeight = 18

-- Use shared helper from utils

local function drawBatteryTelemetry(widget)
  local xRight = widget.zone.x + widget.zone.w - 10
  local yStart = widget.zone.y + 15

  local totalBatt = tonumber(getValue("RxBt")) or 0
  local voltagePerCell, cellCount = utils.getVoltagePerCell(totalBatt)
  local rxBt = tonumber(voltagePerCell) or 0

  local curr = tonumber(getValue("Curr")) or 0
  local capa = tonumber(getValue("Capa")) or 0

  -- Select icon based on voltage per cell
  local icon
  if rxBt < 3.2 then
    icon = widget.icons.dead
  elseif rxBt < 3.6 then
    icon = widget.icons.low
  elseif rxBt < 3.8 then
    icon = widget.icons.yellow
  elseif rxBt < 4.0 then
    icon = widget.icons.ok
  else
    icon = widget.icons.full
  end

  if icon then
    lcd.drawBitmap(icon, xRight - 22, yStart - 2)
  end

  -- Draw voltage text
  if cellCount > 1 then
    lcd.drawText(xRight - 25, yStart + 2, string.format("%.2fV", rxBt) .. "-" .. cellCount .. "S", textStyle + MIDSIZE)
  else
    lcd.drawText(xRight - 29, yStart + 2, string.format("%.1fV", rxBt), textStyle + MIDSIZE)
  end

  -- Draw current and capacity
  lcd.drawText(xRight, yStart + midLineHeight, string.format("Curr: %.2fA", curr), textStyle)
  lcd.drawText(xRight, yStart + midLineHeight + lineHeight, string.format("Cap: %dmAh", capa), textStyle)
end

local function create(zone, options)
  -- Preload icons once during widget creation
  local iconPath = "/WIDGETS/common/icons/battery-%s.png"
  local icons = {
    dead = Bitmap.open(string.format(iconPath, "dead")),
    low = Bitmap.open(string.format(iconPath, "low")),
    yellow = Bitmap.open(string.format(iconPath, "yellow")),
    ok = Bitmap.open(string.format(iconPath, "ok")),
    full = Bitmap.open(string.format(iconPath, "full")),
  }

  return {
    zone = zone,
    cfg = options,
    icons = icons,
  }
end

local function update(widget, options)
  widget.cfg = options
end

local function refresh(widget, event, touchState)
  local tpwr = tonumber(getValue("TPWR")) or 0
  if tpwr > 0 then
    drawBatteryTelemetry(widget)
  else
    local xRight = widget.zone.x + widget.zone.w - 10
    local yStart = widget.zone.y + 15 + midLineHeight
    lcd.drawText(xRight, yStart, string.format("No battery telemetry"), textStyle)
  end
end

local function destroy(widget)
  -- Clean up bitmaps when widget is destroyed
  for key, bmp in pairs(widget.icons or {}) do
    if bmp and bmp.delete then
      bmp:delete()
    end
  end
  widget.icons = nil
end

return {
  name = "BattWidget",
  options = {},
  create = create,
  update = update,
  refresh = refresh,
  destroy = destroy,  -- Important to release memory
}
