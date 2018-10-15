local ansi = require('ansi-terminal')
local lazy = require('lazy')
local list = require('containers/list')
local pp = {}
local mt = {}

local tag = {
    Fail    =  0,
    Empty   =  1,
    Char    =  2,
    Text    =  3,
    Line    =  4,
    -- Render the first doc, but when flattened, render the second.
    FlatAlt =  5,
    Cat     =  6,
    Nest    =  7,
    -- Invariant: first lines of first doc is no shorter than the
    -- first lines of the second doc.
    Union   =  8,
    Column  =  9,
    Nesting = 10,
    -- Introduces coloring around the embedded document.
    Color         = 11,
    Intensify     = 12,
    Italicize     = 13,
    Underline     = 14,
    RestoreFormat = 15
}

-- Private functions
local function checkDoc(pos, arg)
    if getmetatable(arg) ~= mt then
        error("bad argument #"..pos.." (document expected, got "..type(arg)..")", 3)
    end
end

local function spaces(n)
    if n <= 0 then
        return ""
    else
        return string.rep(" ", n)
    end
end

local wlen
do
    -- Do we have unicode.wlen() from OpenOS? If so we use it.
    local ok, result = pcall(require, 'unicode')
    if ok then
        wlen = result.wlen
    else
        wlen = string.len
    end
end

-- luacheck: ignore flatten
local flatten -- Forward declaration
local _flatten = {
    [tag.Line] = function ()
        return setmetatable({ tag = tag.Fail }, mt)
    end,
    [tag.FlatAlt] = function (src)
        return src.snd
    end,
    [tag.Cat] = function (src)
        local doc = {
            tag = tag.Cat,
            fst = flatten(src.fst),
            snd = lazy.delay(
                function ()
                    return flatten(src.snd())
                end)
        }
        return setmetatable(doc, mt)
    end,
    [tag.Nest] = function (src)
        local doc = {
            tag = tag.Nest,
            lv  = src.lv,
            doc = flatten(src.doc)
        }
        return setmetatable(doc, mt)
    end,
    [tag.Union] = function (src)
        return flatten(src.fst())
    end,
    [tag.Column] = function (src)
        local doc = {
            tag = tag.Column,
            f   = function (k)
                return flatten(src.f(k))
            end
        }
        return setmetatable(doc, mt)
    end,
    [tag.Nesting] = function (src)
        local doc = {
            tag = tag.Nesting,
            f   = function (k)
                return flatten(src.f(k))
            end
        }
        return setmetatable(doc, mt)
    end,
    [tag.Color] = function (src)
        local doc = {
            tag       = tag.Color,
            layer     = src.layer,
            intensity = src.intensity,
            color     = src.color,
            doc       = flatten(src.doc)
        }
        return setmetatable(doc, mt)
    end,
    [tag.Intensify] = function (src)
        local doc = {
            tag       = tag.Intensify,
            intensity = src.intensity,
            doc       = flatten(src.doc)
        }
        return setmetatable(doc, mt)
    end,
    [tag.Italicize] = function (src)
        local doc = {
            tag        = tag.Italicize,
            italicized = src.italicized,
            doc        = flatten(src.doc)
        }
        return setmetatable(doc, mt)
    end,
    [tag.Underline] = function (src)
        local doc = {
            tag       = tag.Underline,
            underline = src.underline,
            doc       = flatten(src.doc)
        }
        return setmetatable(doc, mt)
    end
}
local function flatten(doc)
    local f = _flatten[doc.tag]
    if f then
        return f(doc)
    else
        return doc
    end
end

local function column(f) -- (n: integer): document
    local doc = {
        tag = tag.Column,
        f   = f
    }
    return setmetatable(doc, mt)
end

local function nesting(f) -- (n: integer): document
    local doc = {
        tag = tag.Nesting,
        f   = f
    }
    return setmetatable(doc, mt)
end

local function fold(f, ds)
    if #ds == 0 then
        return pp.empty
    elseif #ds == 1 then
        return ds[1]
    else
        local ret = ds[1]
        for i = 2, #ds do
            ret = f(ret, ds[i])
        end
        return ret
    end
end

local function width(doc, f) -- (n: integer): document
    return column(
        function (k1)
            return doc .. column(
                function (k2)
                    return f(k2 - k1)
                end)
        end)
end

local sTag = {
    Fail  = 0,
    Empty = 1,
    Char  = 2,
    Text  = 3,
    Line  = 4,
    SGR   = 5
}

local function nicest(r, w, fits, n, k, x, y)
    -- r = ribbon width, w = page width,
    -- n = indentation of current line, k = current column
    -- x and y, the (simple) documents to chose from.
    -- precondition: first lines of x are no shorter than the first lines of y.
    local w1 = math.min(w - k, r - k + n)
    if fits(w, math.min(n, k), w1, x) then
        return x
    else
        return y()
    end
end
local function best(r, w, fits, n, k, mb_fc, mb_bc, mb_in, mb_it, mb_un, ds0)
    -- n :: indentation of current line
    -- k :: current column
    local function bestTypical(n1, k1, ds1)
        return best(r, w, fits, n1, k1, mb_fc, mb_bc, mb_in, mb_it, mb_un, ds1)
    end
    if list.null(ds0) then
        return {tag = sTag.Empty}
    else
        -- Indentation and document
        local i, d = table.unpack(list.head(ds0))
        local ds   = list.tail(ds0)

        local dsRestore = lazy.delay(
            function ()
                local restore = {
                    tag   = tag.RestoreFormat,
                    mb_fc = mb_fc,
                    mb_bc = mb_bc,
                    mb_in = mb_in,
                    mb_it = mb_it,
                    mb_un = mb_un
                }
                return list.cons({i, setmetatable(restore, mt)}, ds)
            end)

        if d.tag == tag.Fail then
            return {tag = sTag.Fail}

        elseif d.tag == tag.Empty then
            return bestTypical(n, k, ds)

        elseif d.tag == tag.Char then
            return {
                tag  = sTag.Char,
                char = d.char,
                sDoc = bestTypical(n, k + 1, ds)
            }
        elseif d.tag == tag.Text then
            return {
                tag  = sTag.Text,
                text = d.text,
                sDoc = bestTypical(n, k + d.len, ds)
            }
        elseif d.tag == tag.Line then
            return {
                tag  = sTag.Line,
                lv   = i,
                sDoc = bestTypical(i, i, ds)
            }
        elseif d.tag == tag.FlatAlt then
            return bestTypical(n, k, list.cons({i, d.fst}, ds))

        elseif d.tag == tag.Cat then
            return bestTypical(
                n, k, list.cons({i, d.fst}, list.cons({i, d.snd()}, ds)))

        elseif d.tag == tag.Nest then
            local j = i + d.lv
            return bestTypical(n, k, list.cons({j, d.doc}, ds))

        elseif d.tag == tag.Union then
            return nicest(r, w, fits, n, k,
                          bestTypical(n, k, list.cons({i, d.fst()}, ds)),
                          lazy.delay(
                              function ()
                                  return bestTypical(n, k, list.cons({i, d.snd()}, ds))
                              end))

        elseif d.tag == tag.Column then
            return bestTypical(n, k, list.cons({i, d.f(k)}, ds))

        elseif d.tag == tag.Nesting then
            return bestTypical(n, k, list.cons({i, d.f(i)}, ds))

        elseif d.tag == tag.Color then
            local mb_fc1, mb_bc1
            if d.layer == ansi.ConsoleLayer.Background then
                mb_fc1 = mb_fc
                mb_bc1 = {d.intensity, d.color}
            else
                mb_fc1 = {d.intensity, d.color}
                mb_bc1 = mb_bc
            end
            return {
                tag  = sTag.SGR,
                SGR  = {ansi.SGR.SetColor(d.layer, d.indensity, d.color)},
                sDoc = best(r, w, fits, n, k, mb_fc1, mb_bc1, mb_in, mb_it, mb_un,
                            list.cons({i, d.doc}, dsRestore()))
            }
        elseif d.tag == tag.Intensify then
            return {
                tag  = sTag.SGR,
                SGR  = {ansi.SGR.SetConsoleIntensity(d.intensity)},
                sDoc = best(r, w, fits, n, k, mb_fc, mb_bc, d.intensity, mb_it, mb_un,
                            list.cons({i, d.doc}, dsRestore()))
            }
        elseif d.tag == tag.Italicize then
            return {
                tag  = sTag.SGR,
                SGR  = {ansi.SGR.SetItalicized(d.italicized)},
                sDoc = best(r, w, fits, n, k, mb_fc, mb_bc, mb_in, d.italicized, mb_un,
                            list.cons({i, d.doc}, dsRestore()))
            }
        elseif d.tag == tag.Underline then
            return {
                tag  = sTag.SGR,
                SGR  = {ansi.SGR.SetUnderlining(d.underline)},
                sDoc = best(r, w, fits, n, k, mb_fc, mb_bc, mb_in, mb_it, d.underline,
                            list.cons({i, d.doc}, dsRestore()))
            }
        elseif d.tag == tag.RestoreFormat then
            local sgrs = {ansi.SGR.Reset}
            if d.mb_fc then
                table.insert(sgrs, ansi.SGR.SetColor(
                                 ansi.SGR.ConsoleLayer.Foreground,
                                 table.unpack(d.mb_fc)))
            end
            if d.mb_bc then
                table.insert(sgrs, ansi.SGR.SetColor(
                                 ansi.SGR.ConsoleLayer.Background,
                                 table.unpack(d.mb_bc)))
            end
            if d.mb_in then
                table.insert(sgrs, ansi.SGR.SetConsoleIntensity(d.mb_in))
            end
            if d.mb_it then
                table.insert(sgrs, ansi.SGR.SetItalicized(d.mb_it))
            end
            if d.mb_un then
                table.insert(sgrs, ansi.SGR.SetUnderlining(d.mb_un))
            end
            return {
                tag  = sTag.SGR,
                SGR  = sgrs,
                sDoc = best(r, w, fits, n, k, d.mb_fc, d.mb_bc, d.mb_in, d.mb_it, d.mb_un, ds)
            }
        else
            error("Internal error: unknown document tag: "..d.tag)
        end
    end
end
local function renderFits(fits, rfrac, w, x)
    -- r :: the ribbon width in characters
    local r = math.max(0, math.min(w, math.floor(w * rfrac)))
    return best(r, w, fits, 0, 0, nil, nil, nil, nil, nil, list.of({0, x}))
end

-- fits1 does 1 line lookahead.
local function fits1(p, m, w, d)
    if w < 0 then return false
    elseif d.tag == sTag.Fail  then return false
    elseif d.tag == sTag.Empty then return true
    elseif d.tag == sTag.Char  then return fits1(p, m, w - 1, d.sDoc)
    elseif d.tag == sTag.Text  then return fits1(p, m, w - d.len, d.sDoc)
    elseif d.tag == sTag.Line  then return true
    elseif d.tag == sTag.SGR   then return fits1(p, m, w, d.sDoc)
    else
        error("Internal error: unknown sDoc tag: "..d.tag)
    end
end

-- fitsR has a little more lookahead: assuming that nesting roughly
-- corresponds to syntactic depth, fitsR checks that not only the
-- current line fits, but the entire syntactic structure being
-- formatted at this level of indentation fits. If we were to remove
-- the second case for sTag.Line, we would check that not only the
-- current structure fits, but also the rest of the document, which
-- would be slightly more intelligent but would have exponential
-- runtime (and is prohibitively expensive in practice).
local function fitsR(p, m, w, d)
    -- p = pagewidth
    -- m = minimum nesting level to fit in
    -- w = the width in which to fit the first line
    if w < 0 then return false
    elseif d.tag == sTag.Fail  then return false
    elseif d.tag == sTag.Empty then return false
    elseif d.tag == sTag.Char  then return fitsR(p, m, w - 1, d.sDoc)
    elseif d.tag == sTag.Text  then return fitsR(p, m, w - d.len, d.sDoc)
    elseif d.tag == sTag.Line  then
        if m < 1 then
            return fitsR(p, m, p - 1, d.sDoc)
        else
            return true
        end
    elseif d.tag == sTag.SGR   then return fitsR(p, m, w, d.sDoc)
    else
        error("Internal error: unknown sDoc tag: "..d.tag)
    end
end

local function scan(k, ds0)
    if list.null(ds0) then
        return {tag = sTag.Empty}
    else
        local d, ds = list.uncons(ds0)

        if d.tag == tag.Fail then
            return {tag = sTag.Fail}

        elseif d.tag == tag.Empty then
            return scan(k, ds)

        elseif d.tag == tag.Char then
            return {
                tag  = sTag.Char,
                char = d.char,
                sDoc = scan(k + 1, ds)
            }
        elseif d.tag == tag.Text then
            return {
                tag  = sTag.Text,
                text = d.text,
                len  = d.len,
                sDoc = scan(k + d.len, ds)
            }
        elseif d.tag == tag.FlatAlt then
            return scan(k, list.cons(d.fst, ds))

        elseif d.tag == tag.Line then
            return {
                tag  = sTag.Line,
                lv   = 0,
                sDoc = scan(0, ds)
            }
        elseif d.tag == tag.Cat then
            return scan(k, list.cons(d.fst, list.cons(d.snd(), ds)))

        elseif d.tag == tag.Nest then
            return scan(k, list.cons(d.doc, ds))

        elseif d.tag == tag.Union then
            return scan(k, list.cons(d.snd(), ds))

        elseif d.tag == tag.Column then
            return scan(k, list.cons(d.f(k), ds))

        elseif d.tag == tag.Nesting then
            return scan(k, list.cons(d.f(0), ds))

        elseif d.tag == tag.Color then
            return scan(k, list.cons(d.doc, ds))

        elseif d.tag == tag.Intensify then
            return scan(k, list.cons(d.doc, ds))

        elseif d.tag == tag.Italicize then
            return scan(k, list.cons(d.doc, ds))

        elseif d.tag == tag.Underline then
            return scan(k, list.cons(d.doc, ds))

        elseif d.tag == tag.RestoreFormat then
            return scan(k, ds)

        else
            error("Internal error: unknown document tag: "..d.tag)
        end
    end
end
local function renderCompact(doc)
    return scan(0, list.of(doc))
end

local function displayS(color, d)
    if d.tag == sTag.Fail then
        error("Internal error: sTag.Fail can not appear uncaught in a rendered sDoc")

    elseif d.tag == sTag.Empty then
        return ""

    elseif d.tag == sTag.Char then
        return d.char .. displayS(color, d.sDoc)

    elseif d.tag == sTag.Text then
        return d.text .. displayS(color, d.sDoc)

    elseif d.tag == sTag.Line then
        return '\n' .. spaces(d.lv) .. displayS(color, d.sDoc)

    elseif d.tag == sTag.SGR then
        if color then
            return ansi.setSGRCode(d.SGR) .. displayS(color, d.sDoc)
        else
            return displayS(color, d.sDoc)
        end
    else
        error("Internal error: unknown sDoc tag: "..d.tag)
    end
end

-- Basic combinators

-- The empty document is, indeed, empty. Although empty has no
-- content, it does have a 'height' of 1 and behaves exactly like
-- text("") (and is therefore not a unit of '&').
pp.empty = setmetatable({ tag = tag.Empty }, mt)

-- The document char(c) contains the literal character c.
function pp.char(char)
    -- Invariant: 'char' contains just one letter.
    if char == "\n" then
        return pp.line
    else
        checkArg(1, char, "string")
        assert(#char == 1)
        local doc = {
            tag  = tag.Char,
            char = char
        }
        return setmetatable(doc, mt)
    end
end

-- The document text(s) contains the literal string s. The string may
-- not contain any newline ('\n') characters. If the string contains
-- newline characters, the function string() must be used.
function pp.text(text)
    -- Invariant: 'text' doesn't contain any newlines.
    if text == "" then
        return pp.empty
    else
        checkArg(1, text, "string")
        assert(text:find("\n") == nil)
        local doc = {
            tag  = tag.Text,
            len  = wlen(text),
            text = text
        }
        return setmetatable(doc, mt)
    end
end

-- The document string(s) concatenates all characters in s using
-- 'line' for newline characters and char() for all other
-- characters. It is used instead of text() whenever the text contains
-- newline characters.
function pp.string(str)
    if str == "" then
        return pp.empty
    else
        checkArg(1, str, "string")
        local nl = str:find("\n")
        if nl == nil then
            return pp.text(str)
        elseif nl == 1 then
            return pp.line .. pp.string(str:sub(2))
        else
            return pp.text(str:sub(1, nl-1)) .. pp.string(str:sub(nl))
        end
    end
end

-- The document number(n) shows the literal number n using text().
function pp.number(num)
    checkArg(1, num, "number")
    return pp.text(tostring(num))
end

-- The document boolean(b) shows the literal boolean b using text().
function pp.boolean(bool)
    checkArg(1, bool, "boolean")
    return pp.text(tostring(bool))
end

-- The operator .. concatenates two documents.
function mt.__concat(fst, snd)
    checkDoc(1, fst)
    checkDoc(2, snd)
    local doc = {
        tag = tag.Cat,
        fst = fst,
        snd = lazy.delay(function () return snd end)
    }
    return setmetatable(doc, mt)
end

-- The document (nest i x) renders document x with the current
-- indentation level increased by i (See also hang, align and indent).
function pp.nest(lv, d)
    checkArg(1, lv, "number")
    checkDoc(2, d)
    local doc = {
        tag = tag.Nest,
        lv  = lv,
        doc = d
    }
    return setmetatable(doc, mt)
end

-- A linebreak that will never be flattened; it is guaranteed to
-- render as a newline.
pp.hardline = setmetatable({ tag = tag.Line }, mt)

-- The line document advances to the next line and indents to the
-- current nesting level. Document line behaves like text(" ") if the
-- line break is undone by group().
pp.line = setmetatable(
    { tag = tag.FlatAlt,
      fst = pp.hardline,
      snd = pp.char(' ')
    }, mt)

-- The linebreak document advances to the next line and indents to the
-- current nesting level. Document linebreak behaves like 'empty' if
-- the line break is undone by group().
pp.linebreak = setmetatable(
    { tag = tag.FlatAlt,
      fst = pp.hardline,
      snd = pp.empty
    }, mt)

-- The group combinator is used to specify alternative layouts. The
-- document group(x) undoes all line breaks in document x. The
-- resulting line is added to the current line if that fits the
-- page. Otherwise, the document x is rendered without any changes.
function pp.group(d)
    checkDoc(1, d)
    local doc = {
        tag = tag.Union,
        fst = lazy.delay(function () return flatten(d) end),
        snd = lazy.delay(function () return d end)
    }
    return setmetatable(doc, mt)
end

-- The document softline behaves like 'space' if the resulting output
-- fits the page, otherwise it behaves like 'line'.
pp.softline = pp.group(pp.line)

-- The document softbreak behaves like 'empty' if the resulting output
-- fits the page, otherwise it behaves like 'line'.
pp.softbreak = pp.group(pp.linebreak)

-- A document that is normally rendered as the first argument, but
-- when flattened, is rendered as the second document.
function pp.flatAlt(fst, snd)
    checkDoc(1, fst)
    checkDoc(2, snd)
    local doc = {
        tag = tag.FlatAlt,
        fst = fst,
        snd = snd
    }
    return setmetatable(doc, mt)
end

-- Alignment combinators

-- The document align(x) renders document x with the nesting level set
-- to the current column.
function pp.align(doc)
    return column(
        function (k)
            return nesting(
                function (i)
                    return pp.nest(k-i, doc)
                end)
        end)
end

-- The hang combinator implements hanging indentation. The document
-- hang(i, x) renders document x with a nesting level set to the
-- current column plus i.
function pp.hang(lv, doc)
    return pp.align(pp.nest(lv, doc))
end

-- The document indent(i, x) indents document x with i spaces.
function pp.indent(lv, doc)
    return pp.hang(lv, pp.text(spaces(lv)) .. doc)
end

-- The document encloseSep(l, r, sep, xs) concatenates the documents
-- xs separated by sep and encloses the resulting document by l and
-- r. The documents are rendered horizontally if that fits the
-- page. Otherwise they are aligned vertically. All separators are put
-- in front of the elements.
function pp.encloseSep(left, right, sep, ds)
    checkDoc(1, left)
    checkDoc(2, right)
    checkDoc(3, sep)
    checkArg(4, ds, "table") -- [document]
    if #ds == 0 then
        return left .. right
    elseif #ds == 1 then
        return left .. ds[1] .. right
    else
        local xs = {left}
        for i, d in ipairs(ds) do
            if i > 1 then
                xs[#xs+1] = sep
            end
            xs[#xs+1] = d
        end
        xs[#xs+1] = right
        return pp.align(pp.cat(xs))
    end
end

-- The document list(xs) comma separates the documents xs and encloses
-- them in braces. The documents are rendered horizontally if
-- that fits the page. Otherwise they are aligned vertically. All
-- comma separators are put in front of the elements.
function pp.list(ds)
    checkArg(1, ds, "table") -- [document]
    return pp.encloseSep(pp.lbrace, pp.rbrace, pp.comma, ds)
end

-- Operators

-- The document (x + y) concatenates document x and y with a 'space'
-- in between.
function mt.__add(x, y)
    return x .. pp.space .. y
end

-- The document (x & y) concatenates document x and y with a 'line' in
-- between.
function mt.__band(x, y)
    return x .. pp.line .. y
end

-- The document (x / y) concatenates document x and y with a 'softline'
-- in between. This effectively puts x and y either next to each other
-- (with a space in between) or underneath each other.
function mt.__div(x, y)
    return x .. pp.softline .. y
end

-- The document (x % y) concatenates document x and y with a
-- 'linebreak' in between.
function mt.__mod(x, y)
    return x .. pp.linebreak .. y
end

-- The document (x // y) concatenates document x and y with a
-- softbreak in between. This effectively puts x and y either right
-- next to each other or underneath each other.
function mt.__mod(x, y)
    return x .. pp.softbreak .. y
end

-- List combinators

-- The document hsep(xs) concatenates all documents xs horizontally
-- with '+'.
function pp.hsep(ds)
    checkArg(1, ds, "table") -- [document]
    return fold(function (x, y) return x + y end, ds)
end

-- The document vsep(xs) concatenates all documents xs vertically with
-- '&'. If a group() undoes the line breaks inserted by vsep, all
-- documents are separated with a 'space'.
function pp.vsep(ds)
    checkArg(1, ds, "table") -- [document]
    return fold(function (x, y) return x & y end, ds)
end

-- The document fillSep(xs) concatenates documents xs horizontally
-- with '+' as long as its fits the page, than inserts a line and
-- continues doing that for all documents in xs.
function pp.fillSep(ds)
    checkArg(1, ds, "table") -- [document]
    return fold(function (x, y) return x / y end, ds)
end

-- The document sep(xs) concatenates all documents xs either
-- horizontally with '+', if it fits the page, or vertically with '&'.
function pp.sep(ds)
    return pp.group(pp.vsep(ds))
end

-- The document hcat(xs) concatenates all documents xs horizontally
-- with '..'.
function pp.hcat(ds)
    checkArg(1, ds, "table") -- [document]
    return fold(function (x, y) return x .. y end, ds)
end

-- The document vcat(xs) concatenates all documents xs vertically with
-- '%'. If a group undoes the line breaks inserted by vcat, all
-- documents are directly concatenated.
function pp.vcat(ds)
    checkArg(1, ds, "table") -- [document]
    return fold(function (x, y) return x % y end, ds)
end

-- The document fillCat(xs) concatenates documents xs horizontally
-- with '..' as long as its fits the page, than inserts a 'linebreak'
-- and continues doing that for all documents in xs.
function pp.fillCat(ds)
    checkArg(1, ds, "table") -- [document]
    return fold(function (x, y) return x // y end, ds)
end

-- The document cat(xs) concatenates all documents xs either
-- horizontally with '..', if it fits the page, or vertically with
-- '%'.
function pp.cat(ds)
    return pp.group(pp.vcat(ds))
end

-- punctuate(p, xs) concatenates all documents in xs with document p
-- except for the last document.
function pp.punctuate(p, ds)
    checkDoc(1, p)
    checkArg(2, ds, "table") -- [document]
    if #ds == 0 then
        return {}
    elseif #ds == 1 then
        return ds
    else
        local ret = {}
        for i = 1, #ds-1 do
            ret[#ret+1] = ds[i] .. p
        end
        ret[#ret+1] = ds[#ds]
        return ret
    end
end

-- Filler combinators

-- The document fill(i, x) renders document x. It then appends spaces
-- until the width is equal to i. If the width of x is already larger,
-- nothing is appended.
function pp.fill(n, doc)
    checkArg(1, n, "number")
    checkDoc(2, doc)
    return width(
        doc,
        function (w)
            if w >= n then
                return pp.empty
            else
                return pp.text(spaces(n - w))
            end
        end)
end

-- The document fillBreak(i, x) first renders document x. It then
-- appends spaces until the width is equal to i. If the width of x is
-- already larger than i, the nesting level is increased by i and a
-- 'line' is appended.
function pp.fillBreak(n, doc)
    checkArg(1, n, "number")
    checkDoc(2, doc)
    return width(
        doc,
        function (w)
            if w > n then
                return pp.nest(n, pp.linebreak)
            else
                return pp.text(spaces(n - w))
            end
        end)
end

-- Bracketing combinators

-- The document enclose(l, r, x) encloses document x between documents
-- l and r using '..'.
function pp.enclose(left, right, doc)
    return left .. doc .. right
end

-- Document squotes(x) encloses document x with single quotes "'".
function pp.squotes(doc)
    return pp.enclose(pp.squote, pp.squote, doc)
end

-- Document dquotes(x) encloses document x with double quotes '"'.
function pp.dquotes(doc)
    return pp.enclose(pp.dquote, pp.dquote, doc)
end

-- Document parens(x) encloses document x in parenthesis, "(" and ")".
function pp.parens(doc)
    return pp.enclose(pp.lparen, pp.rparen, doc)
end

-- Document angles(x) encloses document x in angles, "<" and ">".
function pp.angles(doc)
    return pp.enclose(pp.langle, pp.rangle, doc)
end

-- Document braces(x) encloses document x in braces, "{" and "}".
function pp.braces(doc)
    return pp.enclose(pp.lbrace, pp.rbrace, doc)
end

-- Document brackets(x) encloses document x in square brackets, "["
-- and "]".
function pp.brackets(doc)
    return pp.enclose(pp.lbracket, pp.rbracket, doc)
end

-- Named character combinators
local named = {
    lparen    = '(',
    rparen    = ')',
    langle    = '<',
    rangle    = '>',
    lbrace    = '{',
    rbrace    = '}',
    lbracket  = '[',
    rbracket  = ']',
    squote    = "'",
    dquote    = '"',
    semi      = ';',
    colon     = ':',
    comma     = ',',
    space     = ' ',
    dot       = '.',
    backslash = '\\',
    equals    = '='
}
for k, v in pairs(named) do
    pp[k] = pp.char(v)
end
-- The document lparen contains a left parenthesis, "(".
-- The document rparen contains a right parenthesis, ")".
-- The document langle contains a left angle, "<".
-- The document rangle contains a left angle, "<".
-- The document lbrace contains a left brace, "{".
-- The document rbrace contains a right brace, "}".
-- The document lbracket contains a left square bracket, "[".
-- The document rbracket contains a right square bracket, "]".
-- The document squote contains a single quote, "'".
-- The document dquote contains a double quote, '"'.
-- The document semi contains a semicolon, ";".
-- The document colon contains a colon, ":".
-- The document comma contains a comma, ",".
-- The document space contains a single space, " ".
-- The document dot contains a single dot, ".".
-- The document backslash contains a back slash, "\".
-- The document equals contains an equal sign, "=".

-- ANSI formatting combinators

-- Forecolor combinators
for k, v in pairs(ansi.Color) do
    pp[k:lower()] = function (d)
        checkDoc(1, d)
        local doc = {
            tag       = tag.Color,
            layer     = ansi.ConsoleLayer.Foreground,
            intensity = ansi.ColorIntensity.Vivid,
            color     = v,
            doc       = d
        }
        return setmetatable(doc, mt)
    end
    pp['dull' .. k:lower()] = function (d)
        checkDoc(1, d)
        local doc = {
            tag       = tag.Color,
            layer     = ansi.ConsoleLayer.Foreground,
            intensity = ansi.ColorIntensity.Dull,
            color     = v,
            doc       = d
        }
        return setmetatable(doc, mt)
    end
    pp['on' .. k:lower()] = function (d)
        checkDoc(1, d)
        local doc = {
            tag       = tag.Color,
            layer     = ansi.ConsoleLayer.Background,
            intensity = ansi.ColorIntensity.Vivid,
            color     = v,
            doc       = d
        }
        return setmetatable(doc, mt)
    end
    pp['ondull' .. k:lower()] = function (d)
        checkDoc(1, d)
        local doc = {
            tag       = tag.Color,
            layer     = ansi.ConsoleLayer.Background,
            intensity = ansi.ColorIntensity.Dull,
            color     = v,
            doc       = d
        }
        return setmetatable(doc, mt)
    end
end

-- Displays a document in a heavier font weight.
function pp.bold(d)
    checkDoc(1, d)
    local doc = {
        tag       = tag.Intensify,
        intensity = ansi.ConsoleIntensity.Bold,
        doc       = d
    }
    return setmetatable(doc, mt)
end

-- Displays a document in the normal font weight.
function pp.debold(d)
    checkDoc(1, d)
    local doc = {
        tag       = tag.Intensify,
        intensity = ansi.ConsoleIntensity.Normal,
        doc       = d
    }
    return setmetatable(doc, mt)
end

-- Underlining combinators

-- Displays a document with underlining.
function pp.underline(d)
    checkDoc(1, d)
    local doc = {
        tag       = tag.Underline,
        underline = ansi.Underlining.SingleUnderline,
        doc       = d
    }
    return setmetatable(doc, mt)
end

-- Displays a document with no underlining.
function pp.nounderline(d)
    checkDoc(1, d)
    local doc = {
        tag       = tag.Underline,
        underline = ansi.Underlining.NoUnderline,
        doc       = d
    }
    return setmetatable(doc, mt)
end

-- Formatting elimination combinators

-- Removes all colorisation, emboldening and underlining from a
-- document.
local _plain = {
    [tag.FlatAlt] = function (src)
        local doc = {
            tag = tag.FlatAlt,
            fst = pp.plain(src.fst),
            snd = pp.plain(src.snd)
        }
        return setmetatable(doc, mt)
    end,
    [tag.Cat] = function (src)
        local doc = {
            tag = tag.Cat,
            fst = pp.plain(src.fst),
            snd = lazy.delay(
                function ()
                    return pp.plain(src.snd())
                end)
        }
        return setmetatable(doc, mt)
    end,
    [tag.Nest] = function (src)
        local doc = {
            tag = tag.Nest,
            lv  = src.lv,
            doc = pp.plain(src.doc)
        }
        return setmetatable(doc, mt)
    end,
    [tag.Union] = function (src)
        local doc = {
            tag = tag.Union,
            fst = lazy.delay(function () return pp.plain(src.fst()) end),
            snd = lazy.delay(function () return pp.plain(src.snd()) end)
        }
        return setmetatable(doc, mt)
    end,
    [tag.Column] = function (src)
        local doc = {
            tag = tag.Column,
            f   = function (k)
                return pp.plain(src.f(k))
            end
        }
        return setmetatable(doc, mt)
    end,
    [tag.Nesting] = function (src)
        local doc = {
            tag = tag.Nesting,
            f   = function (i)
                return pp.plain(src.f(i))
            end
        }
        return setmetatable(doc, mt)
    end,
    [tag.Color] = function (src)
        return pp.plain(src.doc)
    end,
    [tag.Intensify] = function (src)
        return pp.plain(src.doc)
    end,
    [tag.Italicize] = function (src)
        return pp.plain(src.doc)
    end,
    [tag.Underline] = function (src)
        return pp.plain(src.doc)
    end,
    [tag.RestoreFormat] = function ()
        return pp.empty
    end
}
function pp.plain(doc)
    checkDoc(1, doc)
    local f = _plain[doc.tag]
    if f then
        return f(doc)
    else
        return doc
    end
end

-- Rendering and displaying documents

-- renderPretty(ribbonfrac, width, color, x) renders document x with a
-- page width of width and a ribbon width of (ribbonfrac * width)
-- characters. The ribbon width is the maximal amount of
-- non-indentation characters on a line. The parameter ribbonfrac
-- should be between 0.0 and 1.0. If it is lower or higher, the ribbon
-- width will be 0 or width respectively. ANSI color information will
-- be output if the parameter color is true, or discarded otherwise.
function pp.renderPretty(ribbonfrac, wid, color, doc)
    checkArg(1, ribbonfrac, "number")
    checkArg(2, wid, "number")
    checkArg(3, color, "boolean")
    checkDoc(4, doc)
    return displayS(color, renderFits(fits1, ribbonfrac, wid, doc))
end

-- renderCompact(x) renders document x without adding any
-- indentation. Since no 'pretty' printing is involved, this renderer
-- is very fast. The resulting output contains fewer characters than a
-- pretty printed version and can be used for output that is read by
-- other programs. ANSI color information will be discarded.
function pp.renderCompact(doc)
    checkDoc(1, doc)
    return displayS(false, renderCompact(doc))
end

-- A slightly smarter rendering algorithm with more lookahead. It
-- provides earlier breaking on deeply nested structures.
function pp.renderSmart(ribbonfrac, wid, color, doc)
    checkArg(1, ribbonfrac, "number")
    checkArg(2, wid, "number")
    checkArg(3, color, "boolean")
    checkDoc(4, doc)
    return displayS(color, renderFits(fitsR, ribbonfrac, wid, doc))
end

return pp
