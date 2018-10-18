local adt  = require('algebraic-data-types')
local ansi = require('ansi-terminal')

local SDoc = adt.define(
    adt.constructor('SFail'),
    adt.constructor('SEmpty'),
    adt.constructor('SChar', adt.field('char'), adt.field('sDoc')),
    adt.constructor('SText', adt.field('len'), adt.field('text'), adt.field('sDoc')),
    adt.constructor('SLine', adt.field('lv'), adt.field('sDoc')),
    adt.constructor('SSGR', adt.field('sgrs'), adt.field('sDoc')))

function SDoc.checkSDoc(pos, arg)
    if type(arg) ~= "table" or not arg:is(SDoc) then
        error("bad argument #"..pos.." (SimpleDoc expected, got "..type(arg)..")", 3)
    end
end

-- fits1 does 1 line lookahead.
function SDoc.fits1(p, m, w, d)
    if w < 0 then
        return false
    else
        return d:match {
            SFail = function ()
                return false
            end,
            SEmpty = function ()
                return true
            end,
            SChar = function (_, sDoc)
                return SDoc.fits1(p, m, w-1, sDoc)
            end,
            SText = function (len, _, sDoc)
                return SDoc.fits1(p, m, w-len, sDoc)
            end,
            SLine = function (_, _)
                return true
            end,
            SSGR = function (_, sDoc)
                return SDoc.fits1(p, m, w, sDoc)
            end
        }
    end
end

-- fitsR has a little more lookahead: assuming that nesting roughly
-- corresponds to syntactic depth, fitsR checks that not only the
-- current line fits, but the entire syntactic structure being
-- formatted at this level of indentation fits. If we were to remove
-- the second case for SLine, we would check that not only the current
-- structure fits, but also the rest of the document, which would be
-- slightly more intelligent but would have exponential runtime (and
-- is prohibitively expensive in practice).
function SDoc.fitsR(p, m, w, d)
    -- p = pagewidth
    -- m = minimum nesting level to fit in
    -- w = the width in which to fit the first line
    if w < 0 then
        return false
    else
        return d:match {
            SFail = function ()
                return false
            end,
            SEmpty = function ()
                return true
            end,
            SChar = function (_, sDoc)
                return SDoc.fitsR(p, m, w-1, sDoc)
            end,
            SText = function (len, _, sDoc)
                return SDoc.fitsR(p, m, w-len, sDoc)
            end,
            SLine = function (_, sDoc)
                if m < 1 then
                    return SDoc.fitsR(p, m, p-1, sDoc)
                else
                    return true
                end
            end,
            SSGR = function (_, sDoc)
                return SDoc.fitsR(p, m, w, sDoc)
            end
        }
    end
end

function SDoc.displayS(color, d)
    return d:match {
        SFail = function ()
            error("Internal error: SFail can not appear uncaught in a rendered SDoc")
        end,
        SEmpty = function ()
            return ""
        end,
        SChar = function (char, sDoc)
            return char .. SDoc.displayS(color, sDoc)
        end,
        SText = function (_, text, sDoc)
            return text .. SDoc.displayS(color, sDoc)
        end,
        SLine = function (lv, sDoc)
            return "\n" .. string.rep(" ", lv) .. SDoc.displayS(color, sDoc)
        end,
        SSGR = function (sgrs, sDoc)
            if color then
                return ansi.setSGRCode(sgrs) .. SDoc.displayS(color, sDoc)
            else
                return SDoc.displayS(color, sDoc)
            end
        end
    }
end

return SDoc
