local ansi  = require('ansi-terminal')
local lazy  = require('lazy')
local list  = require('containers/list')
local maybe = require('containers/maybe')

local Doc   = require('wl-pprint/document')
local SDoc  = require('wl-pprint/simple-document')

local pp = {}

-- Private functions
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
        -- Do we have utf8.len() from Lua 5.3? It's still better than
        -- string.len().
        if type(utf8) == "table" and utf8.len then
            wlen = utf8.len
        else
            wlen = string.len
        end
    end
end

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
        return SDoc.SEmpty
    else
        -- Indentation and document
        local i, d = table.unpack(list.head(ds0))
        local ds   = list.tail(ds0)

        local dsRestore = lazy.delay(
            function ()
                -- dsRestore is not always used, hence the laziness.
                local restore = Doc.RestoreFormat(mb_fc, mb_bc, mb_in, mb_it, mb_un)
                return list.cons({i, restore}, ds)
            end)

        return d:match {
            Fail = function ()
                return SDoc.SFail
            end,
            Empty = function ()
                return bestTypical(n, k, ds)
            end,
            Char = function (char)
                return SDoc.SChar(char, bestTypical(n, k+1, ds))
            end,
            Text = function (len, text)
                return SDoc.SText(len, text, bestTypical(n, k+len, ds))
            end,
            Line = function ()
                return SDoc.SLine(i, bestTypical(i, i, ds))
            end,
            FlatAlt = function (fst, _)
                return bestTypical(n, k, list.cons({i, fst}, ds))
            end,
            Cat = function (fst, snd)
                return bestTypical(
                    n, k, list.cons({i, fst}, list.cons({i, snd}, ds)))
            end,
            Nest = function (lv, doc)
                return bestTypical(n, k, list.cons({i+lv, doc}, ds))
            end,
            Union = function (fst, sndL)
                return nicest(r, w, fits, n, k,
                              bestTypical(n, k, list.cons({i, fst()}, ds)),
                              sndL:map(
                                  function (snd)
                                      return bestTypical(n, k, list.cons({i, snd}, ds))
                                  end))
            end,
            Column = function (f)
                return bestTypical(n, k, list.cons({i, f(k)}, ds))
            end,
            Nesting = function (f)
                return bestTypical(n, k, list.cons({i, f(i)}, ds))
            end,
            Color = function (layer, intensity, color, doc)
                local mb_fc1, mb_bc1
                if layer:is(ansi.ConsoleLayer.Background) then
                    mb_fc1 = mb_fc
                    mb_bc1 = maybe.Just({intensity, color})
                else
                    mb_fc1 = maybe.Just({intensity, color})
                    mb_bc1 = mb_bc
                end
                return SDoc.SSGR(
                    {ansi.SGR.SetColor(layer, intensity, color)},
                    best(r, w, fits, n, k, mb_fc1, mb_bc1, mb_in, mb_it, mb_un,
                         list.cons({i, doc}, dsRestore())))
            end,
            Intensify = function (intensity, doc)
                return SDoc.SSGR(
                    {ansi.SGR.SetConsoleIntensity(intensity)},
                    best(r, w, fits, n, k, mb_fc, mb_bc, maybe.Just(intensity), mb_it, mb_un,
                         list.cons({i, doc}, dsRestore())))
            end,
            Italicize = function (italicized, doc)
                return SDoc.SSGR(
                    {ansi.SGR.SetItalicized(italicized)},
                    best(r, w, fits, n, k, mb_fc, mb_bc, mb_in, maybe.Just(italicized), mb_un,
                         list.cons({i, doc}, dsRestore())))
            end,
            Underline = function (underline, doc)
                return SDoc.SSGR(
                    {ansi.SGR.SetUnderlining(underline)},
                    best(r, w, fits, n, k, mb_fc, mb_bc, mb_in, mb_it, maybe.Just(underline),
                         list.cons({i, doc}, dsRestore())))
            end,
            RestoreFormat = function (mb_fc1, mb_bc1, mb_in1, mb_it1, mb_un1)
                local sgrs = {
                    ansi.SGR.Reset,
                    table.unpack(
                        maybe.catMaybes {
                            mb_fc1:map(
                                function (inCol) -- {intensity, color}
                                    return ansi.SGR.SetColor(
                                        ansi.SGR.ConsoleLayer.Foreground,
                                        table.unpack(inCol))
                                end),
                            mb_bc1:map(
                                function (inCol)
                                    return ansi.SGR.SetColor(
                                        ansi.SGR.ConsoleLayer.Background,
                                        table.unpack(inCol))
                                end),
                            mb_in1:map(
                                function (intensity)
                                    return ansi.SGR.SetConsoleIntensity(intensity)
                                end),
                            mb_it1:map(
                                function (italicized)
                                    return ansi.SGR.SetItalicized(italicized)
                                end),
                            mb_un1:map(
                                function (underlining)
                                    return ansi.SGR.SetUnderlining(underlining)
                                end)
                        })
                }
                return SDoc.SSGR(
                    sgrs,
                    best(r, w, fits, n, k, mb_fc1, mb_bc1, mb_in1, mb_it1, mb_un1, ds))
            end
        }
    end
end
local function renderFits(fits, rfrac, w, x)
    -- r :: the ribbon width in characters
    local r = math.max(0, math.min(w, math.floor(w * rfrac)))
    return best(r, w, fits, 0, 0,
                maybe.Nothing,
                maybe.Nothing,
                maybe.Nothing,
                maybe.Nothing,
                maybe.Nothing,
                list.of({0, x}))
end

local function scan(k, ds0)
    if list.null(ds0) then
        return SDoc.SEmpty
    else
        local d, ds = list.uncons(ds0)
        return d:match {
            Fail = function ()
                return SDoc.SFail
            end,
            Empty = function ()
                return scan(k, ds)
            end,
            Char = function (char)
                return SDoc.SChar(char, scan(k+1, ds))
            end,
            Text = function (len, text)
                return SDoc.SText(len, text, scan(k+len, ds))
            end,
            FlatAlt = function (fst, _)
                return scan(k, list.cons(fst, ds))
            end,
            Line = function ()
                return SDoc.SLine(0, scan(0, ds))
            end,
            Cat = function (fst, snd)
                return scan(k, list.cons(fst, list.cons(snd, ds)))
            end,
            Nest = function (_, doc)
                return scan(k, list.cons(doc, ds))
            end,
            Union = function (_, snd)
                return scan(k, list.cons(snd(), ds))
            end,
            Column = function (f)
                return scan(k, list.cons(f(k), ds))
            end,
            Nesting = function (f)
                return scan(k, list.cons(f(0), ds))
            end,
            Color = function (_, _, _, doc)
                return scan(k, list.cons(doc, ds))
            end,
            Intensify = function (_, doc)
                return scan(k, list.cons(doc, ds))
            end,
            Italicize = function (_, doc)
                return scan(k, list.cons(doc, ds))
            end,
            Underline = function (_, doc)
                return scan(k, list.cons(doc, ds))
            end,
            RestoreFormat = function (_, _, _, _, _)
                return scan(k, ds)
            end
        }
    end
end

-- Basic combinators

-- The empty document is, indeed, empty. Although empty has no
-- content, it does have a 'height' of 1 and behaves exactly like
-- text("") (and is therefore not a unit of '&').
pp.empty = Doc.Empty

-- The document char(c) contains the literal character c.
function pp.char(char)
    -- Invariant: 'char' contains just one letter.
    if char == "\n" then
        return pp.line
    else
        checkArg(1, char, "string")
        assert(#char == 1)
        return Doc.Char(char)
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
        return Doc.Text(wlen(text), text)
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

-- The document (nest i x) renders document x with the current
-- indentation level increased by i (See also hang, align and indent).
function pp.nest(lv, doc)
    checkArg(1, lv, "number")
    Doc.checkDoc(2, doc)
    return Doc.Nest(lv, doc)
end

-- Re-export some combinators.
pp.hardline  = Doc.hardline
pp.line      = Doc.line
pp.linebreak = Doc.linebreak
pp.group     = Doc.group
pp.softline  = Doc.softline
pp.softbreak = Doc.softbreak

-- A document that is normally rendered as the first argument, but
-- when flattened, is rendered as the second document.
function pp.flatAlt(fst, snd)
    Doc.checkDoc(1, fst)
    Doc.checkDoc(2, snd)
    -- Are these worth being lazy? These are potentially expensive to
    -- construct, but it would be too inconvenient if we require our
    -- users to pass lazy documents to the function.
    return Doc.FlatAlt(fst, snd)
end

-- Alignment combinators

-- The document align(x) renders document x with the nesting level set
-- to the current column.
function pp.align(doc)
    return Doc.Column(
        function (k)
            return Doc.Nesting(
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
    Doc.checkDoc(1, left)
    Doc.checkDoc(2, right)
    Doc.checkDoc(3, sep)
    checkArg(4, ds, "table") -- [Doc]
    if #ds == 0 then
        return left .. right
    elseif #ds == 1 then
        return left .. ds[1] .. right
    else
        local xs = {}
        for i, d in ipairs(ds) do
            if i == 1 then
                xs[#xs+1] = left .. d
            else
                xs[#xs+1] = sep .. d
            end
        end
        return pp.align(pp.cat(xs) .. right)
    end
end

-- The document list(xs) comma separates the documents xs and encloses
-- them in braces. The documents are rendered horizontally if
-- that fits the page. Otherwise they are aligned vertically. All
-- comma separators are put in front of the elements.
function pp.list(ds)
    checkArg(1, ds, "table") -- [Doc]
    return pp.encloseSep(pp.lbrace, pp.rbrace, pp.comma, ds)
end

-- List combinators

-- The document hsep(xs) concatenates all documents xs horizontally
-- with '+'.
function pp.hsep(ds)
    checkArg(1, ds, "table") -- [Doc]
    return Doc.fold(function (x, y) return x + y end, ds)
end

-- The document vsep(xs) concatenates all documents xs vertically with
-- '&'. If a group() undoes the line breaks inserted by vsep, all
-- documents are separated with a 'space'.
function pp.vsep(ds)
    checkArg(1, ds, "table") -- [Doc]
    return Doc.fold(function (x, y) return x & y end, ds)
end

-- The document fillSep(xs) concatenates documents xs horizontally
-- with '+' as long as its fits the page, than inserts a line and
-- continues doing that for all documents in xs.
function pp.fillSep(ds)
    checkArg(1, ds, "table") -- [Doc]
    return Doc.fold(function (x, y) return x / y end, ds)
end

-- The document sep(xs) concatenates all documents xs either
-- horizontally with '+', if it fits the page, or vertically with '&'.
function pp.sep(ds)
    return pp.group(pp.vsep(ds))
end

-- The document hcat(xs) concatenates all documents xs horizontally
-- with '..'.
function pp.hcat(ds)
    checkArg(1, ds, "table") -- [Doc]
    return Doc.fold(function (x, y) return x .. y end, ds)
end

-- The document vcat(xs) concatenates all documents xs vertically with
-- '%'. If a group undoes the line breaks inserted by vcat, all
-- documents are directly concatenated.
function pp.vcat(ds)
    checkArg(1, ds, "table") -- [Doc]
    return Doc.fold(function (x, y) return x % y end, ds)
end

-- The document fillCat(xs) concatenates documents xs horizontally
-- with '..' as long as its fits the page, than inserts a 'linebreak'
-- and continues doing that for all documents in xs.
function pp.fillCat(ds)
    checkArg(1, ds, "table") -- [Doc]
    return Doc.fold(function (x, y) return x // y end, ds)
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
    Doc.checkDoc(1, p)
    checkArg(2, ds, "table") -- [Doc]
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
    Doc.checkDoc(2, doc)
    return Doc.width(
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
    Doc.checkDoc(2, doc)
    return Doc.width(
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

-- Color combinators
for k, v in pairs(ansi.Color) do
    -- This assumes every constructor of ansi.Color is nullary.
    pp[k:lower()] = function (doc)
        Doc.checkDoc(1, doc)
        return Doc.Color(ansi.ConsoleLayer.Foreground, ansi.ColorIntensity.Vivid, v, doc)
    end
    pp['dull'..k] = function (doc)
        Doc.checkDoc(1, doc)
        return Doc.Color(ansi.ConsoleLayer.Foreground, ansi.ColorIntensity.Dull, v, doc)
    end
    pp['on'..k] = function (doc)
        Doc.checkDoc(1, doc)
        return Doc.Color(ansi.ConsoleLayer.Background, ansi.ColorIntensity.Vivid, v, doc)
    end
    pp['onDull'..k] = function (doc)
        Doc.checkDoc(1, doc)
        return Doc.Color(ansi.ConsoleLayer.Background, ansi.ColorIntensity.Dull, v, doc)
    end
end

-- Displays a document in a heavier font weight.
function pp.bold(doc)
    Doc.checkDoc(1, doc)
    return Doc.Intensify(ansi.ConsoleIntensity.Bold, doc)
end

-- Displays a document in the normal font weight.
function pp.debold(doc)
    Doc.checkDoc(1, doc)
    return Doc.Intensify(ansi.ConsoleIntensity.Normal, doc)
end

-- Underlining combinators

-- Displays a document with underlining.
function pp.underline(doc)
    Doc.checkDoc(1, doc)
    return Doc.Underline(ansi.Underlining.SingleUnderline, doc)
end

-- Displays a document with no underlining.
function pp.noUnderline(doc)
    Doc.checkDoc(1, doc)
    return Doc.Underline(ansi.Underlining.NoUnderline, doc)
end

-- Formatting elimination combinators

-- Removes all colorisation, emboldening and underlining from a
-- document.
function pp.plain(doc)
    Doc.checkDoc(1, doc)
    return Doc.plain(doc)
end

-- Rendering and displaying documents

-- renderPretty(ribbonfrac, width, x) renders document x with a page
-- width of width and a ribbon width of (ribbonfrac * width)
-- characters. The ribbon width is the maximal amount of
-- non-indentation characters on a line. The parameter ribbonfrac
-- should be between 0.0 and 1.0. If it is lower or higher, the ribbon
-- width will be 0 or width respectively.
function pp.renderPretty(rfrac, w, doc)
    checkArg(1, rfrac, "number")
    checkArg(2, w, "number")
    Doc.checkDoc(3, doc)
    return renderFits(SDoc.fits1, rfrac, w, doc)
end

-- renderCompact(x) renders document x without adding any
-- indentation. Since no 'pretty' printing is involved, this renderer
-- is very fast. The resulting output contains fewer characters than a
-- pretty printed version and can be used for output that is read by
-- other programs. This rendering function does not add any
-- colorisation information.
function pp.renderCompact(doc)
    Doc.checkDoc(1, doc)
    return scan(0, list.of(doc))
end

-- A slightly smarter rendering algorithm with more lookahead. It
-- provides earlier breaking on deeply nested structures.
function pp.renderSmart(rfrac, w, doc)
    checkArg(1, rfrac, "number")
    checkArg(2, w, "number")
    Doc.checkDoc(3, doc)
    return renderFits(SDoc.fitsR, rfrac, w, doc)
end

-- displayS(color, simpleDoc) takes the output simpleDoc from a
-- rendering function and transforms it to a string. ANSI color
-- information will be output if the parameter "color" is true, or
-- discarded otherwise.
function pp.displayS(color, sDoc)
    checkArg(1, color, "boolean")
    SDoc.checkSDoc(2, sDoc)
    return SDoc.displayS(color, sDoc)
end

-- displayIO(handle, [color, ]simpleDoc) writes simpleDoc to the file
-- handle "handle". If the optional parameter "color" is given, ANSI
-- color information will be output if the parameter "color" is true,
-- or discarded otherwise. If it is omitted, the function tries to
-- determine if the file handle is actually a TTY, and if it looks
-- like a TTY it will output ANSI color information.
function pp.displayIO(handle, ...)
    local args = table.pack(...)
    local color, sDoc
    if type(args[1]) == "boolean" then
        color = args[1]
        sDoc  = args[2]
        SDoc.checkSDoc(3, sDoc)
    else
        if type(handle) == "table" and handle.tty then
            -- Looks like an OpenOS tty.
            color = true
        else
            color = false
        end
        sDoc = args[1]
        SDoc.checkSDoc(2, sDoc)
    end
    SDoc.displayIO(handle, color, sDoc)
end

return pp
