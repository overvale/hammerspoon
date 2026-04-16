-- Oliver Taylor's Hammerspoon Config

local utils = require("utils")
local writingAssassin = require("writingAssassin")

-- Setup
-- -----------------------------------------------

function keyUpDown(modifiers, key)
    hs.eventtap.keyStroke(modifiers, key, 0)
end

anycomplete = hs.loadSpoon("Anycomplete")
anycomplete.engine = "duckduckgo"
anycomplete.bindHotkeys()

-- Functions
-- -----------------------------------------------

function menuCapitalize()
    local app = hs.application.frontmostApplication()
    app:selectMenuItem({ "Edit", "Transformations", "Capitalize" })
end

function menuUpperCase()
    local app = hs.application.frontmostApplication()
    app:selectMenuItem({ "Edit", "Transformations", "Make Upper Case" })
end

function menuLowerCase()
    local app = hs.application.frontmostApplication()
    app:selectMenuItem({ "Edit", "Transformations", "Make Lower Case" })
end

function openFolder(path)
    return function()
        -- Expand ~ to home directory if present
        if string.sub(path, 1, 2) == "~/" then
            path = os.getenv("HOME") .. string.sub(path, 2)
        end
        os.execute('open "' .. path .. '"')
    end
end

function openApp(...)
    local apps = { ... }
    return function()
        for _, appName in ipairs(apps) do
            hs.application.launchOrFocus(appName)
        end
    end
end

function emacsAgenda()
    return function()
        hs.task.new("/Users/oliver/Applications/Emacs.app/Contents/MacOS/Emacs", function()
            hs.application.launchOrFocus("Emacs")
        end, {
            "--eval", '(org-agenda nil "1")',
            "--eval", "(delete-other-windows)",
        }):start()
    end
end

function openSpotlight()
    keyUpDown({ "cmd" }, "space")
end

-- Window Management
-- -----------------------------------------------

function menuWindowLeft()
    local app = hs.application.frontmostApplication()
    app:selectMenuItem({ "Window", "Move & Resize", "Left" })
end

function menuWindowRight()
    local app = hs.application.frontmostApplication()
    app:selectMenuItem({ "Window", "Move & Resize", "Right" })
end

function menuWindowCenter()
    local app = hs.application.frontmostApplication()
    app:selectMenuItem({ "Window", "Center" })
end

function menuWindowRestore()
    local app = hs.application.frontmostApplication()
    app:selectMenuItem({ "Window", "Move & Resize", "Return to Previous Size" })
end

---- Backups ----


function backupCloud()
    local cmd = "/Users/oliver/code/rsync-backup/backup-cloud.sh backup"
    hs.task.new("/Users/oliver/.local/bin/term", nil, {cmd}):start()
end

function lastBackupEpoch()
    local backupDir = os.getenv("HOME") .. "/code/rsync-backup"
    local stateFile = backupDir .. "/.last-success-epoch"
    local attr = hs.fs.attributes(stateFile)
    if attr and attr.mode == "file" then
        local f = io.open(stateFile, "r")
        if f then
            local content = f:read("*l")
            f:close()
            local epoch = tonumber(content)
            if epoch then
                return epoch
            end
        end
    end

    return nil
end

function backupAgeDays()
    local epoch = lastBackupEpoch()
    if not epoch then return nil end
    local now = os.time()
    local delta = now - epoch
    if delta < 0 then delta = 0 end
    return math.floor(delta / 86400)
end

function backupsAreStale()
    local days = backupAgeDays()
    if not days then return true end
    return days >= 4
end

function backupsMenuTitle()
    if backupsAreStale() then
        return "Backups 􀇿"
    end
    return "Backups"
end

function lastBackupLabel()
    local epoch = lastBackupEpoch()
    if epoch then
        return "Last Backup: " .. os.date("%Y-%m-%d %H:%M:%S", epoch)
    end
    return "Last Backup: No successful backup recorded"
end

function backupMenuItems()
    local items = {
        { title = lastBackupLabel(), disabled = true },
    }

    if backupsAreStale() then
        table.insert(items, {
            title = "􀇿 Backup is stale (4+ days old)",
            disabled = true
        })
    end

    table.insert(items, { title = "-" })
    table.insert(items, { title = "Back Up Now", fn = backupCloud })

    return items
end

-- In Pages there is no button or menu item to TOGGLE the sidebar.
-- Thus this function is a bit of a hack.
function pagesSidebarToggle()
    local app = hs.application.frontmostApplication()
    if app:name() ~= "Pages" then
        hs.alert.show("Error: Pages is not the active application!")
        return
    end

    local menuBar = app:findMenuItem({ "View", "Table of Contents" })
    if menuBar and menuBar["ticked"] then
        app:selectMenuItem({ "View", "Document Only" })
    else
        app:selectMenuItem({ "View", "Table of Contents" })
    end
end

---- Log ----


---- Menu Bar ----

-- AppleScript template for setting (or toggling) the menu bar autohide
local menubarCMD = [[
tell application "System Events" to tell dock preferences
  set autohide menu bar to %s
end tell
]]

--- hide, show or toggle the menu bar autohide setting
-- @param mode string: "hide", "show", or "toggle" (default: toggle)
function toggleMenubar(mode)
    -- default to "toggle" when mode is nil or empty
    local m = (mode and mode:lower() ~= "" and mode:lower()) or "toggle"

    local lookup = {
        hide   = "true",
        show   = "false",
        toggle = "not autohide menu bar"
    }

    local cmd = lookup[m]
    if not cmd then
        hs.alert.show("toggleMenubar: bad mode “" .. tostring(mode) .. "”")
        return
    end

    hs.applescript(menubarCMD:format(cmd))
end

---- Dark Mode ----

function darkModeStatus()
    -- return the status of Dark Mode
    local _, darkModeState = hs.osascript.javascript(
        'Application("System Events").appearancePreferences.darkMode()'
    )
    return darkModeState
end

function setDarkMode(state)
    -- Function for setting Dark Mode on/off.
    -- Argument should be either 'true' or 'false'.
    return hs.osascript.javascript(
        string.format(
            "Application('System Events').appearancePreferences.darkMode.set(%s)", state
        ))
end

function toggleDarkMode()
    -- Toggle Dark Mode status
    -- Argument should be either 'true' or 'false'.
    if darkModeStatus() then
        setDarkMode(false)
    else
        setDarkMode(true)
    end
end


-- App Block List
-- ----------------------------------------------
-- Apps in this list are automatically killed on launch.
-- This runs all the time, unlike Writing Assassin which is toggled.

local blockedApps = {
    ["News"] = true,
}


-- Global Key Bindings
-- ----------------------------------------------
-- These bindings are global, and will work in any application.

-- Accepts only function names
keyBindings = {
    { { 'alt', 'cmd' },         'm',     toggleMenubar },
    { { 'ctrl', 'alt', 'cmd' }, 'd',     toggleDarkMode },

    -- Window Management
    { { 'ctrl', 'alt', 'cmd' }, 'left',  menuWindowLeft },
    { { 'ctrl', 'alt', 'cmd' }, 'right', menuWindowRight },
    { { 'ctrl', 'alt', 'cmd' }, 'c',     menuWindowCenter },
    { { 'ctrl', 'alt', 'cmd' }, 'r',     menuWindowRestore },
}

for i, mapping in ipairs(keyBindings) do
    local mod = mapping[1]
    local key = mapping[2]
    local fn  = mapping[3]
    hs.hotkey.bind(mod, key, function() fn() end)
end


-- Floating Menu
-- ----------------------------------------------
-- Quick access to frequently used apps and functions directly under
-- the current mouse position.
-- Remember that sub-menus must be declared before the main menu.

-- Generalized floating menu function
function fMenu(menuItems)
    local mousePos = hs.mouse.absolutePosition()
    local menu = hs.menubar.new(false)
    menu:setMenu(menuItems)
    menu:popupMenu(mousePos)
    -- delete when done
    menu:delete()
end

function fMenuItems()
    return {
        { title = "Calendar", shortcut = "l", fn = openApp("Calendar") },
        { title = "Mail", shortcut = "m", fn = openApp("Mail") },
        { title = "Messages", shortcut = "M", fn = openApp("Messages") },
        { title = "Agenda", shortcut = "g", fn = emacsAgenda() },
        { title = "↑ Open All", shortcut = "A", fn = openApp("Calendar", "Mail", "Messages") },
        { title = "-" },
        { title = "Reading", shortcut = "r", fn = function()
            fMenu({
                { title = "Reading", disabled = true },
                { title = "-" },
                { title = "The Economist", fn = function() hs.urlevent.openURL("https://www.economist.com") end },
                { title = "Bloomberg", fn = function() hs.urlevent.openURL("https://www.bloomberg.com") end },
                { title = "Marginal Revolution", fn = function() hs.urlevent.openURL("https://marginalrevolution.com") end },
                { title = "Simon Willison", fn = function() hs.urlevent.openURL("https://simonwillison.net") end },
                { title = "Fratello Watches", fn = function() hs.urlevent.openURL("https://www.fratellowatches.com/archives/") end },
                { title = "Hacker News (Best)", fn = function() hs.urlevent.openURL("https://news.ycombinator.com/best") end },
                { title = "HN Under-commented", fn = function() hs.task.new("/Users/oliver/code/ai-sandbox/hn-undercommented.py", nil, {"-w"}):start() end },
                { title = "Recommended Link", fn = function()
                    hs.task.new("/bin/zsh", function(_, stdout)
                        local url = stdout:gsub("%s+$", "")
                        if url ~= "" then hs.urlevent.openURL(url) end
                    end, {"-l", "-c", "/Users/oliver/code/reading-explorer/re -1"}):start()
                end },
                { title = "-" },
                { title = "Open All", shortcut = "a", fn = function()
                    hs.urlevent.openURL("https://www.economist.com")
                    hs.urlevent.openURL("https://www.bloomberg.com")
                    hs.urlevent.openURL("https://marginalrevolution.com")
                    hs.urlevent.openURL("https://simonwillison.net")
                    hs.urlevent.openURL("https://www.fratellowatches.com/archives/")
                    hs.urlevent.openURL("https://news.ycombinator.com/best")
                end },
            })
        end },
        { title = "-" },
        { title = "Safari", shortcut = "s", fn = openApp("Safari") },
        { title = "Music", shortcut = "a", fn = openApp("Music") },
        { title = "Emacs", shortcut = "e", fn = openApp("Emacs") },
        { title = "Claude", shortcut = "c", fn = openApp("Claude") },
        { title = "Ghostty", shortcut = "t", fn = openApp("Ghostty") },
        { title = "Zed", shortcut = "z", fn = openApp("Zed") },
        { title = "Codex", shortcut = "x", fn = openApp("Codex") },
        { title = "-" },
        { title = "Log Entry", shortcut = "L", fn = function() os.execute("/Users/oliver/.local/bin/logg") end },
        { title = "Open Logs", fn = openFolder("~/Documents/log/") },
        { title = "-" },
        { title = backupsMenuTitle(), shortcut = "b", menu = backupMenuItems() },
        { title = "Toggle Writing Mode", shortcut = "W", fn = writingAssassin.isActive() and writingAssassin.confirmExit or writingAssassin.toggle },
        { title = "Settings", shortcut = ",", fn = openApp("Hammerspoon") },
    }
end

function fMenuMain()
    fMenu(fMenuItems())
end

-- Persistent menubar item
fMenuBar = hs.menubar.new()
local boltCanvas = hs.canvas.new({x=0, y=0, w=22, h=22})
boltCanvas:appendElements({
    type = "segments",
    closed = true,
    action = "fill",
    fillColor = {white = 0, alpha = 1},
    coordinates = {
        {x=12, y=1}, {x=5, y=12}, {x=10, y=12},
        {x=8, y=21}, {x=17, y=9}, {x=12, y=9},
    },
})
fMenuBar:setIcon(boltCanvas:imageFromCanvas():template(true))
boltCanvas:delete()
fMenuBar:setMenu(fMenuItems)

hs.hotkey.bind({ "shift", "cmd" }, "space", fMenuMain)


-- App-Specific Keymaps
-- ----------------------------------------------
-- This creates keymaps for specific apps, and creates an application watcher
-- that activates and deactivates the mappings when the associated app
-- activates.

-- Create maps you'd like to turn on and off
readlineModeMap = hs.hotkey.modal.new()
pagesModeMap = hs.hotkey.modal.new()

-- Readline
readlineModeMap:bind({ 'alt' }, 'l', function() menuLowerCase() end)
readlineModeMap:bind({ 'alt' }, 'c', function() menuCapitalize() end)
readlineModeMap:bind({ 'alt' }, 'u', function() menuUpperCase() end)
readlineModeMap:bind({ 'alt' }, 'b', function() keyUpDown({ 'alt' }, 'left') end)
readlineModeMap:bind({ 'alt' }, 'f', function() keyUpDown({ 'alt' }, 'right') end)
readlineModeMap:bind({ 'alt' }, 'd', function() keyUpDown({ 'alt' }, 'forwarddelete') end)

-- Pages
pagesModeMap:bind({ 'cmd', 'alt' }, 's', function() pagesSidebarToggle() end)

-- Apps where readline mode should NOT be active
local readlineExcludedApps = {
    ["Terminal"] = true,
    ["Microsoft Excel"] = true,
    ["Emacs"] = true,
}

-- Unified Application Watcher
-- Consolidates all app event handling into a single watcher
unifiedWatcher = hs.application.watcher.new(function(appName, eventType, appObject)
    -- Handle launching events
    if eventType == hs.application.watcher.launching then
        -- Writing assassin takes priority while writing mode is active.
        if writingAssassin.handleAppEvent(appName, eventType, appObject) then return end
        -- App blocker - always active
        if blockedApps[appName] then
            appObject:kill()
            hs.notify.new({
                title = "App Blocked",
                informativeText = appName .. " was blocked from launching"
            }):send()
            return
        end
    end

    -- Handle activated events
    if eventType == hs.application.watcher.activated then
        -- Writing assassin - kill on activation too
        if writingAssassin.handleAppEvent(appName, eventType, appObject) then return end
        -- Readline Mode Map - active for every app except excluded ones
        if readlineExcludedApps[appName] then
            readlineModeMap:exit()
        else
            readlineModeMap:enter()
        end
        -- Pages Mode Map - active ONLY for Pages
        if appName == "Pages" then
            pagesModeMap:enter()
        else
            pagesModeMap:exit()
        end
    end

    -- Dispatch to registered callbacks in other modules
    utils.dispatchEvent(appName, eventType, appObject)
end)
unifiedWatcher:start()

-- Nofity user that config has loaded correctly.
hs.notify.new({ title = "Hammerspoon", informativeText = "Ready to rock 🤘" }):send()

-- END HAMMERSPOON CONFIG --
