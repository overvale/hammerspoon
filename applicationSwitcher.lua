-- Application Switcher (macOS 9 style)
-- "Vibe Coded" by Oliver Taylor

local utils = require("utils")

-- Configurable settings
local hotkeyMods = { "cmd", "option" }
local hotkeyKey = "."
local iconSizeMenu = { w = 18, h = 18 }
local iconSizeSwitcher = { w = 20, h = 20 }

-- Create a menubar item
local switcher = hs.menubar.new()

-- Helper: Retrieve and sort running apps by title (uses shared utility)
local function getSortedRunningApps()
    return utils.getRunningApps()
end

-- Generate menu items
local function makeMenu()
    local menuItems = {}
    local currentApp = hs.application.frontmostApplication()
    local runningApps = hs.application.runningApplications()

    -- Add tear-off option at the top
    table.insert(menuItems, {
        title = "Tear Off Menu",
        fn = function() require("appPalette").show() end
    })
    table.insert(menuItems, { title = "-" })

    -- Determine counts for visible and hidden apps
    local visibleCount = 0
    local hasHidden = false
    for _, app in ipairs(runningApps) do
        if app:kind() == 1 then
            if not app:isHidden() and app ~= currentApp then
                visibleCount = visibleCount + 1
            elseif app:isHidden() then
                hasHidden = true
            end
        end
    end

    -- Add hide/show options for the current app
    if currentApp then
        local isFinder = currentApp:bundleID() == "com.apple.finder"
        table.insert(menuItems, {
            title = "Hide " .. currentApp:title(),
            fn = isFinder and nil or function() currentApp:hide() end,
            disabled = isFinder
        })

        table.insert(menuItems, {
            title = "Hide Others",
            fn = function()
                for _, app in ipairs(runningApps) do
                    if app ~= currentApp and app:kind() == 1 and not app:isHidden() then
                        app:hide()
                    end
                end
            end,
            disabled = visibleCount == 0
        })

        table.insert(menuItems, {
            title = "Show All",
            fn = function()
                for _, app in ipairs(runningApps) do
                    if app:kind() == 1 and app:isHidden() then
                        app:unhide()
                    end
                end
            end,
            disabled = not hasHidden
        })

        table.insert(menuItems, { title = "-" }) -- separator
    end

    -- Use a sorted list of running applications for consistent ordering
    local sortedApps = getSortedRunningApps()

    -- Add each running app to the menu with its icon
    for _, app in ipairs(sortedApps) do
        local title = app:title()
        -- Gray out hidden apps
        if app:isHidden() then
            title = hs.styledtext.new(title, {
                color = { red = 0.5, green = 0.5, blue = 0.5 }
            })
        end

        local menuItem = {
            title = title,
            fn = function() app:activate() end
        }

        if app:bundleID() then
            local icon = utils.getCachedIcon(app:bundleID(), iconSizeMenu)
            if icon then
                menuItem.image = icon:template(false)
            end
        end

        table.insert(menuItems, menuItem)
    end

    return menuItems
end

-- Update the menubar icon to the current app's icon
local function updateIcon()
    local app = hs.application.frontmostApplication()
    if app and app:bundleID() then
        local icon = utils.getCachedIcon(app:bundleID(), iconSizeSwitcher)
        if icon then
            switcher:setIcon(icon:template(false), false)
        end
    end
end

-- Set the menu and initial icon
switcher:setMenu(makeMenu)
updateIcon()

-- Register with central event hub for app activation events
utils.onAppEvent("activated", function(appName, appObject)
    updateIcon()
end)

-- Bind a keyboard shortcut to show the switcher menu
hs.hotkey.bind(hotkeyMods, hotkeyKey, function()
    switcher:popupMenu(switcher:frame())
end)
