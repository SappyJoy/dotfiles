-- Mappings in the Russian layout. 'langmap' covers vim's own commands (мм = dd) but
-- not mappings, so every global mapping gets a twin with the Russian letters at the
-- same keys (<leader>ву = <leader>sf). Twins are made after startup and after each
-- plugin loads; which-key hides them (plugins/which-key.lua).
local M = {}

-- Latin -> Russian, from the langmap's "ЙQ,йq,…" pairs (a backslash escapes the next)
local latin_to_ru, ru_to_latin = {}, {}
for ru, latin in vim.o.langmap:gmatch '([\192-\244][\128-\191]*)\\?(.)' do
  latin_to_ru[latin] = ru
  ru_to_latin[ru] = latin
end

-- one typed key: a Russian letter becomes the Latin key at its spot
function M.to_latin(char)
  return ru_to_latin[char] or char
end

-- translate the keys outside <…> codes: " sf" -> " ву", "<C-W><S-Left>" stays
local function translate(lhs)
  local out, changed, depth = {}, false, 0
  for ch in lhs:gmatch '[%z\1-\127\194-\244][\128-\191]*' do
    if ch == '<' then
      depth = depth + 1
    elseif ch == '>' and depth > 0 then
      depth = depth - 1
    elseif depth == 0 and latin_to_ru[ch] then
      ch, changed = latin_to_ru[ch], true
    end
    out[#out + 1] = ch
  end
  return changed and table.concat(out) or nil
end

-- A twin types the Latin keys (remap), so it reaches whatever they do now: a lazy
-- plugin's stub before it loads, the real mapping after.
function M.mirror()
  for _, mode in ipairs { 'n', 'x', 'o' } do
    local existing = {}
    for _, map in ipairs(vim.api.nvim_get_keymap(mode)) do
      existing[map.lhs] = true
    end
    for _, map in ipairs(vim.api.nvim_get_keymap(mode)) do
      local lhs = translate(map.lhs)
      if lhs and not existing[lhs] and not map.lhs:find '^<Plug>' then
        vim.keymap.set(mode, lhs, map.lhs, { remap = true, desc = map.desc })
        existing[lhs] = true
      end
    end
  end
end

function M.is_twin(lhs)
  return lhs:find '[\192-\244]' ~= nil
end

vim.api.nvim_create_autocmd('User', {
  group = vim.api.nvim_create_augroup('core.russian', { clear = true }),
  pattern = { 'VeryLazy', 'LazyLoad' },
  callback = function()
    vim.schedule(M.mirror)
  end,
})

return M
