local adt  = require('algebraic-data-types')
local lazy = require('lazy')

-- Forward declaration
local Doc

-- The operator .. concatenates two documents.
local function __concat(fst, snd)
    Doc.checkDoc(1, fst)
    Doc.checkDoc(2, snd)
    return Doc.Cat(fst, snd)
end

-- The document (x + y) concatenates document x and y with a 'space'
-- in between.
local function __add(x, y)
    return x .. Doc.space .. y
end

-- The document (x & y) concatenates document x and y with a 'line' in
-- between.
local function __band(x, y)
    return x .. Doc.line .. y
end

-- The document (x / y) concatenates document x and y with a 'softline'
-- in between. This effectively puts x and y either next to each other
-- (with a space in between) or underneath each other.
local function __div(x, y)
    return x .. Doc.softline .. y
end

-- The document (x % y) concatenates document x and y with a
-- 'linebreak' in between.
local function __mod(x, y)
    return x .. Doc.linebreak .. y
end

-- The document (x // y) concatenates document x and y with a
-- softbreak in between. This effectively puts x and y either right
-- next to each other or underneath each other.
local function __idiv(x, y)
    return x .. Doc.softbreak .. y
end

-- The abstract data type Doc represents pretty documents. More
-- specifically, a value of type Doc represents a non-empty set of
-- possible renderings of a document. The rendering functions select
-- one of these possibilities.
Doc = adt.define(
    adt.constructor('Fail'),
    adt.constructor('Empty'),
    adt.constructor('Char', adt.field('char')),
    adt.constructor('Text', adt.field('len'), adt.field('text')),
    adt.constructor('Line'),
    -- Render the first doc, but when flattened, render the second.
    adt.constructor('FlatAlt', adt.field('fst'), adt.field('snd')),
    adt.constructor('Cat', adt.field('fst'), adt.field('snd')),
    adt.constructor('Nest', adt.field('lv'), adt.field('doc')),
    -- Invariant: first lines of first doc is no shorter than the
    -- first lines of the second doc.
    adt.constructor('Union', adt.field('fst'), adt.field('snd')),
    -- Generate a document with a function and render it. The function
    -- will be applied to the current column position.
    adt.constructor('Column', adt.field('f')),
    -- Generate a document with a function and render it. The function
    -- will be applied to the current nesting level.
    adt.constructor('Nesting', adt.field('f')),
    -- Introduce coloring around the embedded document.
    adt.constructor(
        'Color',
        adt.field('layer'),
        adt.field('intensity'),
        adt.field('color'),
        adt.field('doc')),
    adt.constructor('Intensify', adt.field('intensity'), adt.field('doc')),
    adt.constructor('Italicize', adt.field('italicized'), adt.field('doc')),
    adt.constructor('Underline', adt.field('underline'), adt.field('doc')),
    adt.constructor(
        'RestoreFormat',
        adt.field('mb_fc'),  -- forecolor
        adt.field('mb_bc'),  -- backcolor
        adt.field('mb_in'),  -- intensify
        adt.field('mb_it'),  -- italicize
        adt.field('mb_un')), -- underlining
    adt.metamethod('__concat', __concat),
    adt.metamethod('__add'   , __add),
    adt.metamethod('__band'  , __band),
    adt.metamethod('__div'   , __div),
    adt.metamethod('__mod'   , __mod),
    adt.metamethod('__idiv'  , __idiv))

function Doc.checkDoc(pos, arg)
    if type(arg) ~= "table" or not arg:is(Doc) then
        error("bad argument #"..pos.." (Doc expected, got "..type(arg)..")", 3)
    end
end

-- The document space contains a single space, " ".
Doc.space = Doc.Char(' ')

-- A linebreak that will never be flattened; it is guaranteed to
-- render as a newline.
Doc.hardline = Doc.Line

-- The line document advances to the next line and indents to the
-- current nesting level. Document line behaves like text(" ") if the
-- line break is undone by group().
Doc.line = Doc.FlatAlt(Doc.hardline, Doc.Char(' '))

-- The linebreak document advances to the next line and indents to the
-- current nesting level. Document linebreak behaves like 'empty' if
-- the line break is undone by group().
Doc.linebreak = Doc.FlatAlt(Doc.hardline, Doc.Empty)

-- The group combinator is used to specify alternative layouts. The
-- document group(x) undoes all line breaks in document x. The
-- resulting line is added to the current line if that fits the
-- page. Otherwise, the document x is rendered without any changes.
function Doc.group(doc)
    Doc.checkDoc(1, doc)
    return Doc.Union(
        lazy.delay(function () return Doc.flatten(doc) end),
        lazy.delay(function () return doc end))
end

-- The document softline behaves like 'space' if the resulting output
-- fits the page, otherwise it behaves like 'line'.
Doc.softline = Doc.group(Doc.line)

-- The document softbreak behaves like 'empty' if the resulting output
-- fits the page, otherwise it behaves like 'line'.
Doc.softbreak = Doc.group(Doc.linebreak)

function Doc.flatten(d)
    return d:match {
        Line = function ()
            return Doc.Fail
        end,
        FlatAlt = function (_, snd)
            return snd
        end,
        Cat = function (fst, snd)
            return Doc.Cat(Doc.flatten(fst), Doc.flatten(snd))
        end,
        Nest = function (lv, doc)
            return Doc.Nest(lv, Doc.flatten(doc))
        end,
        Union = function (fst, _)
            return Doc.flatten(fst())
        end,
        Column = function (f)
            return Doc.Column(
                function (k)
                    return Doc.flatten(f(k))
                end)
        end,
        Nesting = function (f)
            return Doc.Nesting(
                function (k)
                    return Doc.flatten(f(k))
                end)
        end,
        Color = function (layer, intensity, color, doc)
            return Doc.Color(layer, intensity, color, Doc.flatten(doc))
        end,
        Intensify = function (intensity, doc)
            return Doc.Intensify(intensity, Doc.flatten(doc))
        end,
        Italicize = function (italicized, doc)
            return Doc.Italicize(italicized, Doc.flatten(doc))
        end,
        Underline = function (underline, doc)
            return Doc.Underline(underline, Doc.flatten(doc))
        end,
        _ = function (doc)
            return doc
        end
    }
end

function Doc.fold(f, ds)
    if #ds == 0 then
        return Doc.Empty
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

function Doc.width(doc, f) -- (n: integer): document
    return Doc.Column(
        function (k1)
            return doc .. Doc.Column(
                function (k2)
                    return f(k2 - k1)
                end)
        end)
end

function Doc.plain(d)
    return d:match {
        FlatAlt = function (fst, snd)
            return Doc.FlatAlt(Doc.plain(fst), Doc.plain(snd))
        end,
        Cat = function (fst, snd)
            return Doc.Cat(Doc.plain(fst), Doc.plain(snd))
        end,
        Nest = function (lv, doc)
            return Doc.Nest(lv, Doc.plain(doc))
        end,
        Union = function (fst, snd)
            return Doc.Union(
                lazy.delay(function () return Doc.plain(fst()) end),
                lazy.delay(function () return Doc.plain(snd()) end))
        end,
        Column = function (f)
            return Doc.Column(
                function (k)
                    return Doc.plain(f(k))
                end)
        end,
        Nesting = function (f)
            return Doc.Nesting(
                function (i)
                    return Doc.plain(f(i))
                end)
        end,
        Color = function (_, _, _, doc)
            return Doc.plain(doc)
        end,
        Intensify = function (_, doc)
            return Doc.plain(doc)
        end,
        Italicize = function (_, doc)
            return Doc.plain(doc)
        end,
        Underline = function (_, doc)
            return Doc.plain(doc)
        end,
        RestoreFormat = function ()
            return Doc.Empty
        end,
        _ = function (doc)
            return doc
        end
    }
end

return Doc
