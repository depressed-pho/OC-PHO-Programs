local ansi = {}

local SGRTag = {
    Reset               = 0,
    SetConsoleIntensity = 1,
    SetItalicized       = 2,
    SetUnderlining      = 3,
    SetBlinkSpeed       = 4,
    SetVisible          = 5,
    SetSwapForegroundBackground = 6,
    SetColor            = 7,
    SetRGBColor         = 8
}

ansi.ConsoleLayer = {
    Foreground = 0,
    Background = 1
}

ansi.Color = {
    Black   = 0,
    Red     = 1,
    Green   = 2,
    Yellow  = 3,
    Blue    = 4,
    Magenta = 5,
    Cyan    = 6,
    White   = 7
}

ansi.ColorIntensity = {
    Dull  = 0,
    Vivid = 1,
}

ansi.ConsoleIntensity = {
    Bold   = 0,
    Faint  = 1,
    Normal = 2
}

ansi.Underlining = {
    SingleUnderline = 0,
    DoubleUnderline = 1,
    NoUnderline     = 2
}

ansi.BlinkSpeed = {
    SlowBlink  = 0,
    RapidBlink = 1,
    NoBlink    = 2
}

ansi.SGR = {}

ansi.SGR.Reset = setmetatable({ tag = SGRTag.Reset }, ansi.SGR)

function ansi.SGR.SetConsoleIntensity(intensity)
    checkArg(1, intensity, "number")
    return setmetatable(
        { tag       = SGRTag.SetConsoleIntensity,
          intensity = intensity
        }, ansi.SGR)
end

function ansi.SGR.SetItalicized(italicized)
    checkArg(1, italicized, "boolean")
    return setmetatable(
        { tag        = SGRTag.SetItalicized,
          italicized = italicized
        }, ansi.SGR)
end

function ansi.SGR.SetUnderlining(underlining)
    checkArg(1, underlining, "number")
    return setmetatable(
        { tag         = SGRTag.SetUnderlining,
          underlining = underlining
        }, ansi.SGR)
end

function ansi.SGR.SetBlinkSpeed(blinkSpeed)
    checkArg(1, blinkSpeed, "number")
    return setmetatable(
        { tag        = SGRTag.SetBlinkSpeed,
          blinkSpeed = blinkSpeed
        }, ansi.SGR)
end

function ansi.SGR.SetVisible(visible)
    checkArg(1, visible, "boolean")
    return setmetatable(
        { tag     = SGRTag.SetVisible,
          visible = visible
        }, ansi.SGR)
end

function ansi.SGR.SetSwapForegroundBackground(swap)
    checkArg(1, swap, "boolean")
    return setmetatable(
        { tag  = SGRTag.SetSwapForegroundBackground,
          swap = swap
        }, ansi.SGR)
end

function ansi.SGR.SetColor(layer, intensity, color)
    checkArg(1, layer, "number")
    checkArg(2, intensity, "number")
    checkArg(3, color, "number")
    return setmetatable(
        { tag       = SGRTag.SetColor,
          layer     = layer,
          intensity = intensity,
          color     = color
        }, ansi.SGR)
end

function ansi.SGR.SetRGBColor(layer, red, green, blue) -- [0.0, 1.0]
    checkArg(1, layer, "number")
    checkArg(2, red, "number")
    checkArg(3, green, "number")
    checkArg(4, blue, "number")
    return setmetatable(
        { tag   = SGRTag.SetColor,
          layer = layer,
          red   = red,
          green = green,
          blue  = blue
        }, ansi.SGR)
end

function ansi.setSGRCode(sgrs) -- luacheck: ignore sgrs
    error("FIXME: not implemented")
end

return ansi
