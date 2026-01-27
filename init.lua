-- Oliver Taylor's Hammerspoon Config


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

function openSpotlight()
    keyUpDown({"cmd"}, "space")
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
    hs.osascript.applescript('tell app \"Terminal\" to do script \"backup-cloud\"')
    hs.application.launchOrFocus("Terminal")
end

-- In Pages there is no button or menu item to TOGGLE the sidebar.
-- Thus this function is a bit of a hack.
function pagesSidebarToggle()
    local app = hs.application.frontmostApplication()
    if app:name() ~= "Pages" then
        hs.alert.show("Error: Pages is not the active application!")
        return
    end

    local menuBar = app:findMenuItem({"View", "Table of Contents"})
    if menuBar and menuBar["ticked"] then
        app:selectMenuItem({"View", "Document Only"})
    else
        app:selectMenuItem({"View", "Table of Contents"})
    end
end

-- Why doesn't ChatGTP have a shortcut for voice input?
function talk2ChatGPT()
    hs.execute('shortcuts run "Talk to ChatGPT Voice"')
end

-- Why doens't reminders have a shortcut for a new reminder?
function newReminder()
    hs.execute('shortcuts run "Create New Reminder"')
end

---- Work ----

function receivedThanks()
    local win = hs.window.focusedWindow()
    if win then
        win:focus()
        -- Wait briefly before sending keystrokes
        hs.timer.doAfter(0.05, function()
            hs.eventtap.keyStrokes("Bid received, thank you!")
        end)
    else
        hs.alert.show("No window focused")
    end
end

function xLookupHelper()
    local win = hs.window.focusedWindow()
    if win then
        win:focus()
        -- Wait briefly before sending keystrokes
        hs.timer.doAfter(0.05, function()
            hs.eventtap.keyStrokes("=XLOOKUP([@[Shot Code]],")
        end)
    else
        hs.alert.show("No window focused")
    end
end

function vendorMailer()
    hs.osascript.applescript(
        'tell app \"Terminal\" to do script \"cd ~/src/vendor-mailer/ && python3 vendor_mailer.py\"')
    hs.application.launchOrFocus("Terminal")
end

function bidPackGen()
    hs.osascript.applescript(
        'tell app \"Terminal\" to do script \"cd ~/src/bid-pack-generator/ && ./bid-pack-generator.sh"')
    hs.application.launchOrFocus("Terminal")
end

function bidPackMailer()
    hs.osascript.applescript(
        'tell app \"Terminal\" to do script \"cd ~/src/vendor-mailer/ && ./bidpak_gen.py\"')
    hs.application.launchOrFocus("Terminal")
end


function bidFinder()
    hs.osascript.applescript('tell app \"Terminal\" to do script \"cd ~/src/bid-finder/ && ./bid-finder"')
    hs.application.launchOrFocus("Terminal")
end

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


-- Writing Assassin
-- ----------------------------------------------

-- Code for starting and stopping "WRITING MODE".
-- When this mode is active the apps in the below list are
-- automatically killed if they launch.

local assassinTargets = {
    "Mail",
    "Safari", "Chrome", "Firefox",
    "TV",
    "Messages",
    "News",
    "Reminders",
    "Calendar",
    "Visual Studio Code",
}

function writingAssassin(appName, eventType, appObject)
    if (eventType == hs.application.watcher.launching or
        eventType == hs.application.watcher.activated) then
      for _, target in ipairs(assassinTargets) do
        if appName == target then
        --   hs.notify.new({ title="Writing Assassin", informativeText=appName.." killed!" }):send()
          appObject:kill()
        end
      end
    end
  end

-- Create a watcher for the writing assassin
local writingAssassinWatcher = hs.application.watcher.new(writingAssassin)

-- Create a menu bar item for writing mode
local writingMenu

function startWritingMode()
    writingAssassinWatcher:start()
    writingMenu = hs.menubar.new()
    writingMenu:setTitle("Writing...")
    writingMenu:setMenu({ { title = "Exit Writing Mode", fn = exitWritingMode } })
    toggleMenubar(hide)
end

function exitWritingMode()
    writingAssassinWatcher:stop()
    if writingMenu then
      writingMenu:removeFromMenuBar()
      writingMenu = nil
    end
    toggleMenubar(show)
end

hs.urlevent.bind("writing-mode-start", function(eventName, params)
    startWritingMode()
end)

hs.urlevent.bind("writing-mode-exit", function(eventName, params)
    exitWritingMode()
end)

-- I have a shortcut to toggle a writing focus, and it includes
-- callbacks to the above functions.
function toggleWritingMode()
    hs.execute('shortcuts run "Toggle Writing Focus"')
end

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

-- Recursively generate menu items for a folder
function folderMenuItems(path)
    local items = {}
    local expandedPath = path
    if string.sub(path, 1, 2) == "~/" then
        expandedPath = os.getenv("HOME") .. string.sub(path, 2)
    end
    local handle = io.popen('ls -A1 "' .. expandedPath .. '"')
    if not handle then return items end
    for entry in handle:lines() do
        -- Skip hidden files (those starting with a dot)
        if string.sub(entry, 1, 1) ~= "." then
            local fullPath = expandedPath .. "/" .. entry
            local attr = hs.fs.attributes(fullPath)
            if attr then
                if attr.mode == "directory" then
                    table.insert(items, {
                        title = entry,
                        menu = folderMenuItems(fullPath)
                    })
                else
                    table.insert(items, {
                        title = entry,
                        fn = function() os.execute('open "' .. fullPath .. '"') end
                    })
                end
            end
        end
    end
    handle:close()
    return items
end

-- Work menu items
local fMenuItemsWork = {
    {title = "Mail BIDPAK",        fn = bidPackMailer },
    {title = "Vendor Mailer",      fn = vendorMailer },
    {title = "Bid Pack Generator", fn = bidPackGen },
    {title = "XLookup",            fn = xLookupHelper},
    {title = "Received Thanks",    fn = receivedThanks}
}
function fMenuWork() fMenu(fMenuItemsWork) end

local fMenuItemsMain = {
    {title = "The Material", menu = folderMenuItems("~/Documents/the-overveil/") },
    {title = "Claude",      shortcut = "d", fn = openApp("Claude") },

    {title = "-"},
    {title = "Calendar",  shortcut = "c", fn = openApp("Calendar")}, 
    {title = "Mail",      shortcut = "m", fn = openApp("Mail")},
    {title = "Messages",  shortcut = "M", fn = openApp("Messages")},
    {title = "Reminders", shortcut = "r", fn = openApp("Reminders")},
    {title = "↑ Open All",  shortcut = "A", fn = openApp("Calendar", "Mail", "Messages", "Reminders")},
    
    {title = "-"},
    
    {title = "Music",     shortcut = "a", fn = openApp("Music")},
    {title = "Notes",     shortcut = "n", fn = openApp("Notes")},
    {title = "Safari",    shortcut = "s", fn = openApp("Safari")},
    {title = "Emacs",     shortcut = "e", fn = openApp("Emacs")},
    {title = "Terminal",  shortcut = "t", fn = openApp("Terminal")},

    {title = "-"},
    {title = "Backup to Cloud", fn = backupCloud },
    {title = "Settings",  shortcut = ",", fn = openApp("Hammerspoon")},
}
function fMenuMain() fMenu(fMenuItemsMain) end

hs.hotkey.bind({"shift", "cmd"}, "space", fMenuMain)


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

-- App Activation Watcher
function appModeMaps(appName, eventType, appObject)
    if (eventType == hs.application.watcher.activated) then
        -- Readline Mode Map -- active for every app except those in readlineExcludedApps
        if readlineExcludedApps[appName] then
            readlineModeMap:exit()
        else
            readlineModeMap:enter()
        end
        -- Pages Mode Map -- active ONLY for Pages
        if appName == "Pages" then
            pagesModeMap:enter()
        else
            pagesModeMap:exit()
        end
    end
end

appModeMapWatcher = hs.application.watcher.new(appModeMaps)
appModeMapWatcher:start()


-- End of Config
-- -----------------------------------------------
-- Nofity user that config has loaded correctly.

hs.notify.new({title="Hammerspoon", informativeText="Ready to rock 🤘"}):send()

-- END HAMMERSPOON CONFIG --
