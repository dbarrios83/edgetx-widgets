-- Widget LUA Script: GPS Widget
local utils = loadScript("/WIDGETS/common/utils.lua")()
-- Displays satellite count, latitude, and longitude with small text aligned to the right
-- Includes color-coded satellite count and satellite icon


local textStyle = RIGHT + WHITE + SHADOWED
local midLineHeight = 33
local lineHeight = 18


-- Function to create the widget
local function create(zone, options)
    return {
        zone = zone,
        options = options,
		update = true,
		gpsSATS = 0,
		gpsLAT = 0,
		gpsLON = 0,
		isGPSValid = true,
    }
end

local function update(widget, newOptions)
    widget.options = newOptions
end

-- Helper function to convert decimal degrees to degrees, minutes, and seconds
local function toDMS(value)
    local degrees = math.floor(value)
    local minutes = math.floor((value - degrees) * 60)
    local seconds = ((value - degrees) * 60 - minutes) * 60
    return degrees, minutes, seconds
end


-- Function to draw the satellite icon based on the satellite count
-- Use shared color selection from utils.satIconColor

-- Function to format latitude and longitude
local function formatLatLon(lat, lon)
    local latDeg, latMin, latSec = toDMS(math.abs(lat))
    local lonDeg, lonMin, lonSec = toDMS(math.abs(lon))
    local latDir = lat >= 0 and "N" or "S"
    local lonDir = lon >= 0 and "E" or "W"
    return string.format("%d°%d'%d\"%s", latDeg, latMin, latSec, latDir),
           string.format("%d°%d'%d\"%s", lonDeg, lonMin, lonSec, lonDir)
end

local function drawGpsTelemetry(widget) 

    -- Define positions
    local xRight = widget.zone.x + widget.zone.w - 10
    local yStart = widget.zone.y + 5
    
    -- Get telemetry data
    widget.gpsSATS = tonumber(getValue("Sats")) or 0
    widget.gpsLatLon = getValue("GPS")


    if (type(widget.gpsLatLon) == "table") then 			
        widget.gpsLAT = widget.gpsLatLon.lat or 0
        widget.gpsLON = widget.gpsLatLon.lon or 0	
        widget.isGPSValid = true	
        widget.update = true
    else
        widget.isGPSValid = false
        widget.update = false
    end

    -- Format latitude and longitude
    local latStr, lonStr = formatLatLon(widget.gpsLAT, widget.gpsLON)

    if widget.isGPSValid then
        local iconPath = "/WIDGETS/GPSWidget/BMP/satellite-%s.png"
        local icon = Bitmap.open(string.format(iconPath, utils.satIconColor(widget.gpsSATS)))
        lcd.drawBitmap(icon, xRight-22, yStart)
        lcd.drawText(xRight - 35, yStart + 2, string.format("Sats: %d", widget.gpsSATS), textStyle  + MIDSIZE)

        if widget.options.Coordinates == 1 then
            lcd.drawText(xRight, yStart + midLineHeight, "Lat: " .. latStr, textStyle)
            lcd.drawText(xRight, yStart + midLineHeight + lineHeight, "Lon: " .. lonStr, textStyle)    
        end
    else
        if widget.gpsLAT == 0 and widget.gpsLON == 0 then
            lcd.drawText(xRight - 35, yStart + 2, "No GPS", textStyle + MIDSIZE)
        else
            lcd.drawText(xRight + 10, yStart + 2, "Last location: ", textStyle + MIDSIZE)
            lcd.drawText(xRight, yStart + midLineHeight, "Lat: " .. latStr, textStyle)
            lcd.drawText(xRight, yStart + midLineHeight + lineHeight, "Lon: " .. lonStr, textStyle)
        end
    end

end

local function refresh(widget, event, touchState)

    drawGpsTelemetry(widget)

end

return {
    name = "GPSWidget",
    options = {},
    create = create,
    update = update,
    refresh = refresh,
    options = {
        {"Coordinates", BOOL, 1},
      },
}
