-- Everything this config downloads or builds after its plugins, headless and waiting
-- for each part, so nvim's first start has nothing left to install or ask:
-- treesitter parsers, mason's tools, blink's matcher, orgmode's grammar, the Russian
-- spell file. chezmoi runs it on a new machine and when its inputs change
-- (run_onchange_after_40-nvim-plugins.sh.tmpl):
--   nvim --headless '+Lazy! restore' '+lua require("install").run()' +qa
-- A part whose tool is missing here (tree-sitter-cli, cc, network) is skipped with
-- a note; a real failure is reported as "error" (the script greps for it).
local M = {}

-- on a line of its own (the script greps for it): headless nvim ends its messages
-- without a newline
local function say(part, msg)
  io.stdout:write(('\nnvim install: %s: %s\n'):format(part, msg))
end

local function load(name)
  require('lazy').load { plugins = { name } }
end

local parts = {}

function parts.parsers()
  local task, why = require('parsers').install()
  if not task then
    return say('parsers', why)
  end
  local ok, err = pcall(task.wait, task, 20 * 60 * 1000)
  local left = require('parsers').missing()
  if not ok or #left > 0 then
    say('parsers', 'error: not installed: ' .. table.concat(left, ' ') .. (ok and '' or ' (' .. tostring(err) .. ')'))
  else
    say('parsers', 'installed')
  end
end

function parts.mason()
  load 'mason-tool-installer.nvim'
  vim.cmd 'MasonToolsInstallSync'
  say('mason', 'done')
end

-- blink's matcher comes prebuilt for its release tag; on the path only, not set up,
-- so its own setup doesn't download at the same time
function parts.blink()
  vim.opt.rtp:prepend(require('lazy.core.config').plugins['blink.cmp'].dir)
  local result
  require('blink.cmp.fuzzy.download').ensure_downloaded(function(err, implementation)
    result = err and ('error: ' .. err) or implementation
  end)
  vim.wait(5 * 60 * 1000, function()
    return result ~= nil
  end, 200)
  say('blink', 'matcher: ' .. (result or 'error: no answer after 5 min'))
end

function parts.orgmode()
  if not require('lazy.core.config').plugins['orgmode'] then
    return say('orgmode', 'skipped (no C compiler)')
  end
  load 'orgmode' -- its setup builds the grammar
  local install = require 'orgmode.utils.treesitter.install'
  local ok = vim.wait(5 * 60 * 1000, function()
    return install.get_version_info().installed
  end, 200)
  say('orgmode', ok and 'grammar installed' or 'error: no grammar after 5 min')
end

-- Also checked where nvim.spellfile saves it: lazy rebuilds the runtimepath from the
-- dirs that exist when it loads a plugin, so on a new machine site/ (made later by
-- the parsers or this download) isn't on it until the next start.
function parts.spell()
  local function there()
    return vim.uv.fs_stat(vim.fn.stdpath 'data' .. '/site/spell/ru.utf-8.spl') ~= nil or #vim.api.nvim_get_runtime_file('spell/ru.utf-8.spl', false) > 0
  end
  if there() then
    return say('spell', 'ru there')
  end
  local spellfile = require 'nvim.spellfile'
  spellfile.config { confirm = false }
  spellfile.get 'ru'
  say('spell', there() and 'ru downloaded' or 'ru not downloaded (network?)')
end

function M.run()
  for _, name in ipairs { 'parsers', 'mason', 'blink', 'orgmode', 'spell' } do
    local ok, err = pcall(parts[name])
    if not ok then
      say(name, 'error: ' .. tostring(err))
    end
  end
end

return M
