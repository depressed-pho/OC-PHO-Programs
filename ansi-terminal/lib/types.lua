local adt   = require('algebraic-data-types')
local types = {}

types.SGR = adt.define(
    adt.constructor('Reset'),
    adt.constructor('SetConsoleIntensity', adt.field('intensity')),
    adt.constructor('SetItalicized', adt.field('italicized')), -- boolean
    adt.constructor('SetUnderlining', adt.field('underlining')),
    adt.constructor('SetBlinkSpeed', adt.field('blinkSpeed')),
    adt.constructor('SetVisible', adt.field('visible')), -- boolean
    adt.constructor('SetSwapForegroundBackground', adt.field('swap')), -- boolean
    adt.constructor(
        'SetColor',
        adt.field('layer'),
        adt.field('intensity'),
        adt.field('color')),
    adt.constructor(
        'SetRGBColor',
        adt.field('layer'),
        adt.field('red'), -- [0.0, 1.0]
        adt.field('green'),
        adt.field('blue')))

types.ConsoleLayer = adt.define(
    adt.constructor('Foreground'),
    adt.constructor('Background'))

types.Color = adt.define(
    adt.constructor('Black'),
    adt.constructor('Red'),
    adt.constructor('Green'),
    adt.constructor('Yellow'),
    adt.constructor('Blue'),
    adt.constructor('Magenta'),
    adt.constructor('Cyan'),
    adt.constructor('White'))

types.ColorIntensity = adt.define(
    adt.constructor('Dull'),
    adt.constructor('Vivid'))

types.ConsoleIntensity = adt.define(
    adt.constructor('Bold'),
    adt.constructor('Faint'),
    adt.constructor('Normal'))

types.Underlining = adt.define(
    adt.constructor('SingleUnderline'),
    adt.constructor('DoubleUnderline'),
    adt.constructor('NoUnderline'))

types.BlinkSpeed = adt.define(
    adt.constructor('SlowBlink'),
    adt.constructor('RapidBlink'),
    adt.constructor('NoBlink'))

return types
