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

function reloadHSConfig()
    hs.reload()
end

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

function newFinderWindow()
    local finder = hs.appfinder.appFromName("Finder")
    hs.osascript.applescript('tell application "Finder" to make new Finder window')
    finder:activate()
end

function openFolder(folderPath)
    os.execute('open "' .. folderPath .. '"')
end

function openApp(appName)
    os.execute('open -a "' .. appName .. '"')
end

function runScript(script)
    os.execute(script)
end

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

function logbookNew()
    os.execute("~/src/bin/logg")
end

function logbookShow()
    os.execute("open ~/Documents/log/")
end

function openTODO()
    os.execute("open ~/Documents/todo.txt")
end

function insertDate()
    local dateStr = os.date("%a, %d %B %Y")
    hs.eventtap.keyStrokes(dateStr)
end

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

function logbook1923New()
    os.execute("~/src/bin/log1923")
end

function logbook1923Show()
    os.execute("open ~/Documents/Work/1923/log/")
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

-- Key Bindings
-- ----------------------------------------------

-- Accepts only function names
keyBindings = {
    { { 'alt', 'cmd' },         'm', toggleMenubar },
    { { 'ctrl', 'alt', 'cmd' }, 'd', toggleDarkMode },
    { { 'alt', 'shift' },     'space', talk2ChatGPT },
}

for i, mapping in ipairs(keyBindings) do
    local mod = mapping[1]
    local key = mapping[2]
    local fn  = mapping[3]
    hs.hotkey.bind(mod, key, function() fn() end)
end


-- Floating Menu
-- ----------------------------------------------

function floatingMenu()
    -- Get current mouse position
    local mousePos = hs.mouse.absolutePosition()
    
    -- Create menu items with keyboard shortcuts
    local menuItems = {
        {title = "Favorites", shortcut = "f", fn = function() os.execute("open ~/Favorites/") end},
        {title = "-"},
        {title = "Applications", disabled = true},
        {title = "ChatGPT",   shortcut = "g", fn = function() hs.application.launchOrFocus("ChatGPT") end},

        {title = "Mail",      shortcut = "m", fn = function() hs.application.launchOrFocus("Mail") end},
        {title = "Messages",  shortcut = "M", fn = function() hs.application.launchOrFocus("Messages") end},
        {title = "Calendar",  shortcut = "c", fn = function() hs.application.launchOrFocus("Calendar") end}, 
        {title = "Notes",     shortcut = "n", fn = function() hs.application.launchOrFocus("Notes") end},
        {title = "Reminders", shortcut = "r", fn = function() hs.application.launchOrFocus("Reminders") end},

        {title = "Safari",    shortcut = "s", fn = function() hs.application.launchOrFocus("Safari") end},
        {title = "Music",     shortcut = "a", fn = function() hs.application.launchOrFocus("Music") end},
        {title = "Terminal",  shortcut = "t", fn = function() hs.application.launchOrFocus("Terminal") end},

        {title = "Cursor",    shortcut = "R", fn = function() hs.application.launchOrFocus("Cursor") end},
        {title = "BBEdit",    shortcut = "e", fn = function() hs.application.launchOrFocus("BBEdit") end},

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
        {title = "Work", menu ={
            {title = "Mail BIDPAK",        fn = bidPackMailer },
            {title = "Vendor Mailer",      fn = vendorMailer },
            {title = "Bid Pack Generator", fn = bidPackGen },
            {title = "XLookup",            fn = xLookupHelper},
            {title = "Received Thanks",    fn = receivedThanks},
        }},
        {title = "-"}, 
        {title = "Reload Hammerspoon", fn = function() reloadHSConfig() end},
        {title = "Open Console",       fn = function() hs.openConsole() end},
    }

    -- Create a temporary menubar item (invisible)
    local floatMenu = hs.menubar.new(false)
    
    -- Show popup menu at mouse position
    floatMenu:setMenu(menuItems)
    floatMenu:popupMenu(mousePos)
    
    -- Delete the menubar item when done
    floatMenu:delete()
end

hs.hotkey.bind({"shift", "cmd"}, "space", floatingMenu)


-- App-Specific Keymaps
-- ----------------------------------------------
-- This creates keymaps for specific apps, and creates an application watcher
-- that activates and deactivates the mappings when the associated app
-- activates.

-- Create maps you'd like to turn on and off
-- There can be more than one
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
        -- Readline Mode Map
        if appName == "Terminal" or appName == "Microsoft Excel" then
            readlineModeMap:exit()
        else
            readlineModeMap:enter()
        end
        -- Pages Mode Map
        if appName == "Pages" then
            pagesModeMap:enter()
        else
            pagesModeMap:exit()
        end
    end
end

appActivationWatcher = hs.application.watcher.new(appActivation)
appActivationWatcher:start()


hs.notify.new({title="Hammerspoon", informativeText="Ready to rock 🤘"}):send()
-- END HAMMERSPOON CONFIG --
