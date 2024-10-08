local ls = require("luasnip")
-- local s = ls.snippet
local sn = ls.snippet_node
local isn = ls.indent_snippet_node
local t = ls.text_node
local i = ls.insert_node
local f = ls.function_node
local c = ls.choice_node
local d = ls.dynamic_node
local r = ls.restore_node
local events = require("luasnip.util.events")
local ai = require("luasnip.nodes.absolute_indexer")
local extras = require("luasnip.extras")
local l = extras.lambda
local rep = extras.rep
local p = extras.partial
local m = extras.match
local n = extras.nonempty
local dl = extras.dynamic_lambda
local fmt = require("luasnip.extras.fmt").fmt
local fmta = require("luasnip.extras.fmt").fmta
local conds = require("luasnip.extras.expand_conditions")
local postfix = require("luasnip.extras.postfix").postfix
local types = require("luasnip.util.types")
local parse = require("luasnip.util.parser").parse_snippet
local ms = ls.multi_snippet
local k = require("luasnip.nodes.key_indexer").new_key

function in_math() 
  return vim.api.nvim_eval("vimtex#syntax#in_mathzone()") == 1
end

local s = ls.extend_decorator.apply(ls.snippet, { condition = in_math, show_condition = in_math, wordTrig = false, trigEngine = 'pattern' })
local aus = ls.extend_decorator.apply(ls.snippet, { condition = in_math, show_condition = in_math, wordTrig = false, snippetType = 'autosnippet', trigEngine = 'pattern' })

function aub(tr, defi) -- auto basic
  return aus(tr, t(defi..' '))
end

function raus(tr, streplace, nodevec) -- regex autosnippet
  return aus(
    {trig = "[^%a]" .. tr},
    fmta("<>"..streplace, {
      f( function(_, snip) return snip.captures[1] end ),
      unpack(nodevec) -- eclipse.org/forums/index.php/t/628382 
    })
  )
end

-- i hate lua --

M = {
  -- s({trig = "testMath"}, t("math.lua LOADED")),
  -- **
  -- auto
  aub('@@', '\\cdot'),
  aub('xx', '\\times'),

  aub('pdd', '\\partial'), -- P. Diddy
  aub('ddd', '\\mathrm{d}'),
  
  aub('EE', '\\exists'),
  aub('NE', '\\nexists'),
  aub('FAL', '\\forall'),

  aub('cc', '\\in'),
  aub('ncc', '\\notin'),
  aub('subs', '\\subset'),
  aub('sups', '\\supset'),
  aub('sube', '\\subseteq'),
  aub('supe', '\\supseteq'),
  aub('ssup', '\\sup'),
  aub('sinf', '\\inf'),

  aub('arrl', '\\leftarrow'),
  aub('arrr', '\\rightarrow'),
  aub('arrL', '\\Leftarrow'),
  aub('arrR', '\\Rightarrow'),

  aub('!=', '\\neq'),
  aub('>=', '\\geq'),
  aub('<=', '\\leq'),

  aub('ooo', '\\infty'),

  aub('inv', '^{-1}'),

  aub('nab', '\\nabla'),

  aub('qed', '\\blacksquare'),
  aub('thfr', '\\therefore'),
  aub('becs', '\\because'),
  
  -- power & subscript
  --aus({trig = "++"}, fmta([[^{<>}]], {i(1)})),
  --aus({trig = "--"}, fmta([[_{<>}]], {i(1)})),

  -- e^{}
  raus("ee", [[e^{<>}]], {i(1)}),

  -- derivative
  aus({trig = "dydx"}, fmta([[\frac{\mathrm{d}<>}{\mathrm{d}<>}]], {i(1), i(2)})),
  aus({trig = "ddx"}, fmta([[\frac{\mathrm{d}}{\mathrm{d}<>}]], {i(1)})),
  aus({trig = "pdpx"}, fmta([[\frac{{\partial}<>}{{\partial}<>}]], {i(1), i(2)})),
  aus({trig = "ppx"}, fmta([[\frac{\partial}{{\partial}<>}]], {i(1)})),

  -- fraction & binomial
  aus({trig = 'ff'}, fmta([[\frac{<>}{<>}]], {i(1), i(2)})),
  aus({trig = 'ncr'}, fmta([[\binom{<>}{<>}]], {i(1), i(2)})),

  -- function
  aus({trig = 'func'}, fmta([[<> : <> \to <> ; <> \mapsto <> ]], {i(1, 'f'), i(2, '\\mathbb{R}'), i(3, '\\mathbb{R}'), i(4, 'x'), i(0)})),

  -- limit
  aus({trig = 'lim'}, fmta([[\lim_{<>\to{<>}}\left(<>\right)]], {i(1), i(2), i(0)})), 

  -- integral
  aus({trig = 'int'}, fmta([[\int_{<>}^{<>}<>\,\mathrm{d}<>]], {i(1), i(2), i(0), i(3)})),

  -- fonts
  aus({trig = 'mtb'}, fmta([[\mathbb{<>}]], {i(1)})), -- blackboard bold
  aus({trig = 'mtc'}, fmta([[\mathcal{<>}]], {i(1)})), -- calligraphic
  aus({trig = 'mtr'}, fmta([[\mathrm{<>}]], {i(1)})),  -- roman

  -- left-right delimiters
  aus({trig = 'lrp'}, fmta([[\left(<>\right)]], {i(1)})),
  aus({trig = 'lr|'}, fmta([[\left|<>\right|]], {i(1)})),
  aus({trig = 'lrr'}, fmta([=[\left\[<>\right\]]=], {i(1)})),
  aus({trig = 'lre'}, fmta([[\left.<>\right\vert]], {i(1)})),
  aus({trig = 'lrn'}, fmta([[\left\Vert<>\right\Vert]], {i(1)})),
  aus({trig = 'lrb'}, fmta([[\left\{<>\right\}]], {i(1)})),
  aus({trig = 'lrv'}, fmta([[\left\langle<>\right\rangle]], {i(1)})),

  -- taylor-maclaurin
  aus({trig = 'taylor'}, fmta([[\sum_{n=0}^{<>}\frac{f^{(n)}\left(<>\right)}{n!}\left(x-<>\right)^n]], {i(1), i(2, 'c'), rep(2)})),
  aus({trig = 'maclau'}, fmta([[\sum_{n=0}^{<>}\frac{f^{(n)}(0)x^n}{n!}]], {i(1)})),
  

}

local auto_cmdparenth = {
  "exp",
  "Im",
  "Re",
  "Pr",
}

local auto_cmdbracket = {
  "vec",
  "bar",
  "hat",
  "dot",
}

local auto_bigcmdparenth = {
  "sum",
  "prod",
  "coprod",
  "bigcap",
  "bigcup",
}

local auto_cmd = {
  "aleph", -- non-func
  "ast",
  "star",
  "perp",
  "propto",
  "deg",
  "angle",
  "approx",
  "neg",
  "emptyset",
  "log", -- func
  "ln",
  "sin",
  "cos",
  "tan",
  "arcsin",
  "arccos",
  "arctan",
  "csc",
  "cot",
  "sec",
  "det", 
  "max",
  "min",
  "argmax",
  "argmin",

}

local auto_greek = {
  ['a'] = 'alpha',
  ['b'] = 'beta',
  ['g'] = 'gamma',
  ['G'] = 'Gamma',
  ['d'] = 'delta',
  ['D'] = 'Delta',
  ['ep'] = 'epsilon',
  ['ve'] = 'varepsilon',
  ['z'] = 'zeta',
  ['et'] = 'eta',
  ['h'] = 'theta',
  ['H'] = 'Theta',
  ['l'] = 'lambda',
  ['L'] = 'Lambda',
  ['m'] = 'mu',
  ['x'] = 'xi',
  ['X'] = 'Xi',
  ['r'] = 'rho',
  ['s'] = 'sigma',
  ['t'] = 'tau',
  ['ph'] = 'phi',
  ['vp'] = 'varphi',
  ['Ph'] = 'Phi',
  ['x'] = 'chi',
  ['ps'] = 'psi',
  ['Ps'] = 'Psi',
  ['o'] = 'omega',
  ['O'] = 'Omega',
}

local auto_cmdparenth_snippets = {}
for _, v in ipairs(auto_cmdparenth) do
  table.insert( auto_cmdparenth_snippets, aus( { trig = v, }, fmta([[\<>\left(<>\right)]], {v, i(0)}) ) )
  --table.insert( auto_cmdparenth_snippets, aus( {regTrig = true, wordTrig = false, trig = [[(^\\)]]..v, }, fmta([[\<>\left(<>\right)]], {v, i(0)}) ) )
end
vim.list_extend(M, auto_cmdparenth_snippets)

local auto_cmdbracket_snippets = {}
for _, v in ipairs(auto_cmdbracket) do
  table.insert( auto_cmdbracket_snippets, aus( { trig = v, }, fmta([[\<>{<>}]], {v, i(1)}) ) )
end
vim.list_extend(M, auto_cmdbracket_snippets)

local auto_bigcmdparenth_snippets = {}
for _, v in ipairs(auto_bigcmdparenth) do
  table.insert( auto_bigcmdparenth_snippets, aus( { trig = v, }, fmta([[\<>_{<>}^{<>}]], {v, i(1), i(2)}) ) )
  --table.insert( auto_bigcmdparenth_snippets, aus( { regTrig = true, wordTrig = false, trig = [[(^\\)]]..v, }, fmta([[\<>_{<>}^{<>}]], {v, i(1), i(2)}) ) )
end
vim.list_extend(M, auto_bigcmdparenth_snippets)


local auto_cmd_snippets = {}
for _, v in ipairs(auto_cmd) do
  table.insert( auto_cmd_snippets, aus( { trig = v, }, fmta([[\<> ]], {v}) ) )
  --table.insert( auto_cmd_snippets, aus( {regTrig = true, wordTrig = false, trig = [[(^\\)]]..v, }, fmta([[\<> ]], {v}) ) )
end
vim.list_extend(M, auto_cmd_snippets)

local auto_greek_snippets = {}
for k, v in pairs(auto_greek) do 
  table.insert( auto_greek_snippets, aus( { trig = ';' .. k, }, fmta([[\<> ]], {v}) ) )
end
vim.list_extend(M, auto_greek_snippets)

return M
