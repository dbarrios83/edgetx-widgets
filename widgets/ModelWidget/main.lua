-- Define positions and styles
local xLeft = 10
local yStart = 5
local lineHeight = 18
local textStyle = WHITE + LEFT + SHADOWED

local options = {
    -- show nick instead of model name
    { "show_nick", BOOL, 0 },
    { "nick", STRING, "" },
}

-- Function to create the widget
local function create(zone, options)
    return {
        zone = zone,
        cfg = options,
    }
end

local function update(widget, options)
    widget.cfg = options
end

local function drawSticks()
    x = xLeft
    y = yStart + 5 + 5*lineHeight

    -- stick labels and ids
    sticks={
        {name='A', id=getFieldInfo('ail').id},
        {name='E', id=getFieldInfo('ele').id},
        {name='T', id=getFieldInfo('thr').id},
        {name='R', id=getFieldInfo('rud').id},
    }

    for _, st in ipairs (sticks) do
        lcd.drawText (x, y,
            st.name .. ":" .. math.floor (0.5 + getValue(st.id)/10.24),
            textStyle
        )
        x = x + 50
    end
end

local function drawBattery()
    idTxV = getFieldInfo('tx-voltage').id
    local vBatt = tonumber(getValue(idTxV)) or 0
    lcd.drawText(xLeft , yStart + 8 + 3*lineHeight,
                 string.format("%.1fV", vBatt), textStyle + MIDSIZE)

    -- Determine battery icon based on RXBt vBatt
    local iconPath = "/WIDGETS/ModelWidget/BMP/battery-%s.png"
    local iconState
    if vBatt < 7.1 then
        iconState = "low"
    elseif vBatt < 7.5 then
        iconState = "yellow"
    elseif vBatt < 7.9 then
        iconState = "ok"
    else
        iconState = "full"
    end
    local icon = Bitmap.open(string.format(iconPath, iconState))

    -- Draw battery icon
    lcd.drawBitmap(icon, xLeft + 55 , yStart + 5 + 3*lineHeight)

end

local function drawModelInfo(widget)
    -- Get model name
    local modelName = model.getInfo().name or "Unknown"

    -- override model name with nick from options
    if widget.cfg.show_nick == 1 then
        modelName = widget.cfg.nick
    end

    -- Draw Model Name
    lcd.drawText(xLeft, yStart, modelName, textStyle + MIDSIZE + BOLD)

    -- o/s version
    local _, _, major, minor, rev, osname = getVersion()
    strVer = (osname or "EdgeTX") .. " " .. major .. "." .. minor.. "." .. rev

    lcd.drawText(xLeft, yStart + 2*lineHeight, strVer, textStyle + SMLSIZE)
end

local function refresh(widget, event, touchState)
    drawBattery()
    drawModelInfo(widget)
    drawSticks ()
end

return {
    name = "ModelWidget",
    options = options,
    create = create,
    update = update,
    refresh = refresh
}
