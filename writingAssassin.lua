-- Writing Assassin
-- When writing mode is active, apps in the target list are automatically
-- killed if they launch or are activated.

local writingAssassin = {}

local assassinTargets = {
    ["Mail"] = true,
    ["TV"] = true,
    ["Messages"] = true,
    ["News"] = true,
    ["Calendar"] = true,
    ["Brave Browser"] = true,
    ["Games"] = true,
    ["NetNewsWire"] = true,
}

local writingModeActive = false
local writingMenu
local recentBlockNotifications = {}
local notificationDedupeSeconds = 1
local ignoringNextToggle = false

local function startWritingMode()
    -- Check for running assassin targets
    local running = {}
    for appName in pairs(assassinTargets) do
        if hs.application.get(appName) then
            table.insert(running, appName)
        end
    end

    if #running > 0 then
        table.sort(running)
        local appList = table.concat(running, "\n")
        local ok, result = hs.osascript.applescript(string.format([[
            display dialog "The following blocked apps are running:\n\n%s\n\nWould you like to enter writing mode?" with title "Enter Writing Mode" buttons {"Cancel", "Enter Writing Mode"} default button "Enter Writing Mode"
            return button returned of result
        ]], appList))
        if not ok or result ~= "Enter Writing Mode" then
            ignoringNextToggle = true
            writingAssassin.toggle()
            return
        end
        for _, appName in ipairs(running) do
            local app = hs.application.get(appName)
            if app then app:kill() end
        end
    end

    writingModeActive = true
    writingMenu = hs.menubar.new()
    writingMenu:setTitle("Writing...")
    writingMenu:setMenu({ { title = "Exit Writing Mode", fn = writingAssassin.confirmExit } })
    toggleMenubar("hide")
end

local function exitWritingMode()
    writingModeActive = false
    if writingMenu then
        writingMenu:removeFromMenuBar()
        writingMenu = nil
    end
    toggleMenubar("show")
end

function writingAssassin.isActive()
    return writingModeActive
end

function writingAssassin.toggle()
    hs.execute('shortcuts run "Toggle Writing Focus"')
end

function writingAssassin.confirmExit()
    local countdown = 15
    local screen = hs.screen.mainScreen()
    local sf = screen:frame()
    local w, h = 320, 160
    local canvas = hs.canvas.new({
        x = sf.x + (sf.w - w) / 2,
        y = sf.y + (sf.h - h) / 2,
        w = w, h = h
    })
    canvas:appendElements({
        {
            type = "rectangle", action = "fill",
            fillColor = { red = 0, green = 0, blue = 0, alpha = 0.85 },
            roundedRectRadii = { xRadius = 12, yRadius = 12 },
        },
        {
            type = "text", text = "Exiting writing mode in...",
            textColor = { red = 1, green = 1, blue = 1, alpha = 0.8 },
            textSize = 16, textAlignment = "center",
            frame = { x = 0, y = 24, w = w, h = 30 },
        },
        {
            id = "countdown", type = "text", text = tostring(countdown),
            textColor = { red = 1, green = 1, blue = 1, alpha = 1 },
            textSize = 72, textAlignment = "center",
            frame = { x = 0, y = 54, w = w, h = 90 },
        },
    })
    canvas:level(hs.canvas.windowLevels.modalPanel)
    canvas:behavior(hs.canvas.windowBehaviors.canJoinAllSpaces)
    canvas:show()

    local timer
    timer = hs.timer.new(1, function()
        countdown = countdown - 1
        if countdown <= 0 then
            timer:stop()
            canvas:delete()
            local ok, result = hs.osascript.applescript([[
                set d to display dialog "To exit writing mode, type the following:" & return & return & "\"I want to stop writing\"" default answer "" with title "Exit Writing Mode" buttons {"Nevermind", "I'm finished writing"} default button "Nevermind"
                if button returned of d is "Nevermind" then
                    return ""
                end if
                return text returned of d
            ]])
            if ok and result == "I want to stop writing" then
                writingAssassin.toggle()
            end
        else
            canvas["countdown"].text = tostring(countdown)
        end
    end)
    timer:start()
end

-- Called from the unified watcher in init.lua
function writingAssassin.handleAppEvent(appName, eventType, appObject)
    if not writingModeActive then return false end
    if not assassinTargets[appName] then return false end
    if eventType == hs.application.watcher.launching or
       eventType == hs.application.watcher.activated then
        appObject:kill()
        local now = hs.timer.secondsSinceEpoch()
        local lastNotifiedAt = recentBlockNotifications[appName]
        if not lastNotifiedAt or (now - lastNotifiedAt) > notificationDedupeSeconds then
            hs.notify.new({
                title = "Writing Mode",
                informativeText = appName .. " was blocked"
            }):send()
            recentBlockNotifications[appName] = now
        end
        return true
    end
    return false
end

hs.urlevent.bind("writing-mode-start", function()
    startWritingMode()
end)

hs.urlevent.bind("writing-mode-exit", function()
    exitWritingMode()
end)

hs.urlevent.bind("writing-mode-toggle", function()
    if ignoringNextToggle then
        ignoringNextToggle = false
        return
    end
    if writingModeActive then
        exitWritingMode()
    else
        startWritingMode()
    end
end)

return writingAssassin
