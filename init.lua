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

function lastBackupCloud()
    local output, _, _ = hs.execute("/Users/oliver/src/rsync-backup/last-backup-cloud.sh")
    return output
end

function openLastBackup()
    os.execute('open "$(echo ~/src/rsync-backup/logs/$(ls ~/src/rsync-backup/logs | tail -1))"')
end

---- Logbook ----

function logbookNew()
    os.execute("~/src/bin/logg")
end

function logbookShow()
    os.execute("open ~/Documents/log/")
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

function toggleMenubar()
    hs.applescript([[
  tell application "System Events"
    tell dock preferences to set autohide menu bar to not autohide menu bar
  end tell]])
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


-- Global Key Bindings
-- ----------------------------------------------
-- These bindings are global, and will work in any application.

-- Accepts only function names
keyBindings = {
    { { 'alt', 'cmd' },         'm',     toggleMenubar },
    { { 'ctrl', 'alt', 'cmd' }, 'd',     toggleDarkMode },
    { { 'alt', 'shift' },       'space', talk2ChatGPT },
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

-- Work menu items
local fMenuItemsWork = {
    {title = "Mail BIDPAK",        fn = bidPackMailer },
    {title = "Vendor Mailer",      fn = vendorMailer },
    {title = "Bid Pack Generator", fn = bidPackGen },
    {title = "XLookup",            fn = xLookupHelper},
    {title = "Received Thanks",    fn = receivedThanks}
}
function fMenuWork() fMenu(fMenuItemsWork) end

local fMenuItemsAI = {
    {title = "ChatGPT",    shortcut = "c", fn = openApp("ChatGPT")},
    {title = "Perplexity", shortcut = "p", fn = function() hs.urlevent.openURL("https://www.perplexity.ai") end},
    {title = "Gemini",     shortcut = "g", fn = function() hs.urlevent.openURL("https://gemini.google.com") end},
    {title = "Grok",       shortcut = "r", fn = function() hs.urlevent.openURL("https://grok.com") end},
    {title = "Claude",     shortcut = "l", fn = function() hs.urlevent.openURL("https://claude.ai") end}
} 
function fMenuAI() fMenu(fMenuItemsAI) end

local fMenuItemsMain = {
    {title = "Favorites",    shortcut = "F", fn = openFolder("~/Favorites/")},
    {title = "The Material", shortcut = "!", fn = openFolder("~/Documents/The Material/")},
    {title = "AI Tools…",    shortcut = "i", fn = fMenuAI },
    {title = "Tweets",       shortcut = "T", fn = openFolder("~/Documents/tweets.txt")},

    {title = "-"},
    {title = "Applications", disabled = true},

    {title = "Calendar",  shortcut = "c", fn = openApp("Calendar")}, 
    {title = "Mail",      shortcut = "m", fn = openApp("Mail")},
    {title = "Messages",  shortcut = "M", fn = openApp("Messages")},
    {title = "Music",     shortcut = "a", fn = openApp("Music")},
    {title = "Notes",     shortcut = "n", fn = openApp("Notes")},
    {title = "Safari",    shortcut = "s", fn = openApp("Safari")},
    {title = "    Open All",  shortcut = "A", fn = openApp("Calendar", "Mail", "Messages", "Music", "Notes", "Safari")},
    
    {title = "-"},
    
    {title = "BBEdit",    shortcut = "b", fn = openApp("BBEdit")},
    {title = "Excel",     shortcut = "x", fn = openApp("Microsoft Excel")},
    {title = "iPhone",    shortcut = "I", fn = openApp("iPhone Mirroring")},
    {title = "Reminders", shortcut = "R", fn = openApp("Reminders")},
    {title = "Terminal",  shortcut = "t", fn = openApp("Terminal")},
    {title = "VSCode",    shortcut = "v", fn = openApp("Visual Studio Code")},

    {title = "-"},
    { title = "Backups", menu = {
        { title = "Backup to Cloud", fn = backupCloud },
        { title = "Latest Backup:",  disabled = true },
        { title = lastBackupCloud(), fn = openLastBackup },
    }},
    {title = "Logbook", menu = {
        {title = "Open Today's Log Entry", fn = logbookNew },
        {title = "Open Logbook",           fn = logbookShow },
    }},
    {title = "Work...",   shortcut = "w", fn = fMenuWork },
    {title = "-"}, 
    {title = "Reload Hammerspoon", fn = function() hs.reload() end},
    {title = "Open Console",       fn = function() hs.openConsole() end},
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

-- App Activation Watcher
function appActivation(appName, eventType, appObject)
    if (eventType == hs.application.watcher.activated) then
        -- Readline Mode Map -- active for every app except Terminal and Excel
        if appName == "Terminal" or appName == "Microsoft Excel" then
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

appActivationWatcher = hs.application.watcher.new(appActivation)
appActivationWatcher:start()


-- End of Config
-- -----------------------------------------------
-- Nofity user that config has loaded correctly.

hs.notify.new({title="Hammerspoon", informativeText="Ready to rock 🤘"}):send()

-- END HAMMERSPOON CONFIG --
