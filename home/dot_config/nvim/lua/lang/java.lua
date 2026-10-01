-- Java, Kotlin, Android: jdtls and JetBrains' kotlin-lsp. Both need a newer Java
-- than arch's default 17, so they run on the newest JDK installed.
local function newest_jdk()
  local best, version
  for _, dir in ipairs(vim.fn.glob('/usr/lib/jvm/java-*-openjdk', false, true)) do
    local v = tonumber(dir:match 'java%-(%d+)')
    if v and (not version or v > version) and vim.uv.fs_stat(dir .. '/bin/java') then
      best, version = dir, v
    end
  end
  return best
end

local jdk = newest_jdk()
local env = jdk and { JAVA_HOME = jdk } or nil

return {
  parsers = { 'java', 'kotlin', 'groovy', 'xml' },
  servers = { jdtls = { cmd_env = env }, kotlin_lsp = { cmd_env = env } },
  tools = { { 'jdtls', need = 'java' }, { 'kotlin-lsp', need = 'java' } },
  plugins = { { 'ariedov/android-nvim', ft = { 'java', 'kotlin' }, opts = {} } },
}
