-- Managed by Scene (plugin/scene.lua). Scene overwrites this file.
-- It applies the theme that Scene selected and reloads it when Scene changes it.
-- To detach, use Restore in Scene, or delete this file and colors/scene.lua.
local data_path = [==[/Users/rselbach/Library/Application Support/Scene/Neovim/theme.json]==]
local uv = vim.uv or vim.loop
local state = { previous = nil, applied = false, busy = false, expected = "scene" }

local function read()
  local file = io.open(data_path, "r")
  if not file then return nil end
  local text = file:read("*a")
  file:close()
  local ok, data = pcall(vim.json.decode, text)
  if ok and type(data) == "table" then return data end
  return nil
end

local function restore_previous()
  if not state.applied then return end
  state.applied = false
  if vim.g.colors_name == "scene" then
    vim.cmd("highlight clear")
    if state.previous and state.previous ~= "scene" then pcall(vim.cmd.colorscheme, state.previous) end
  end
end

local function apply()
  if state.busy then return end
  state.busy = true
  local ok, err = pcall(function()
    local data = read()
    if not data or type(data.variants) ~= "table" then restore_previous() return end
    if not state.applied and vim.g.colors_name ~= "scene" then state.previous = vim.g.colors_name end
    local mode = vim.o.background
    if data.variants[mode] == nil then
      mode = data.variants.dark and "dark" or "light"
      if vim.o.background ~= mode then vim.o.background = mode end
    end
    local variant = data.variants[mode]
    local prefer = type(data.prefer) == "table" and data.prefer[mode] or nil
    if prefer then
      state.expected = prefer
      if pcall(vim.cmd.colorscheme, prefer) then state.applied = true return end
    end
    state.expected = "scene"
    vim.cmd("highlight clear")
    if vim.fn.exists("syntax_on") == 1 then vim.cmd("syntax reset") end
    vim.g.colors_name = "scene"
    for name, spec in pairs(variant.groups or {}) do vim.api.nvim_set_hl(0, name, spec) end
    for index, color in ipairs(variant.terminal or {}) do vim.g["terminal_color_" .. (index - 1)] = color end
    state.applied = true
  end)
  state.busy = false
  if not ok then vim.notify("Scene: " .. tostring(err), vim.log.levels.WARN) end
end

_G.SceneApplyTheme = apply

local function watch()
  local dir = vim.fs.dirname(data_path)
  if vim.fn.isdirectory(dir) == 0 then return end
  local handle = uv.new_fs_event()
  if not handle then return end
  handle:start(dir, {}, vim.schedule_wrap(function() apply() end))
end

apply()
watch()

-- Plugins that pick a colorscheme at startup, such as LazyVim or auto-dark-mode.nvim, run after this file.
-- For a few seconds, Scene applies its theme again over them. A colorscheme picked later stays.
local guard_until = uv.now() + (tonumber(vim.g.scene_startup_guard_ms) or 5000)
vim.api.nvim_create_autocmd("ColorScheme", {
  group = vim.api.nvim_create_augroup("Scene", { clear = true }),
  callback = function(event)
    if state.applied and event.match ~= state.expected and uv.now() < guard_until then vim.schedule(apply) end
  end,
})
