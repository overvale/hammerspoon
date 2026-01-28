-- Application Palette (classic Mac OS style)
-- A floating palette showing running apps

local appPalette = {}

-- Configuration
local rowHeight = 24
local iconSize = 18
local padding = 8
local paletteWidth = 160
local bgColor = { red = 0.85, green = 0.85, blue = 0.85 }
local borderColor = { red = 0.5, green = 0.5, blue = 0.5 }
local textColor = { red = 0, green = 0, blue = 0 }
local highlightColor = { red = 0.7, green = 0.7, blue = 0.9 }
local fontSize = 12
local titleBarHeight = 16
local quitButtonSize = 16
local quitButtonPadding = 6

-- State
local canvas = nil
local isVisible = false
local currentApps = {}
local isDragging = false
local dragOffset = { x = 0, y = 0 }
local dragEventTap = nil

-- Create eventtap lazily when first needed
local function getDragEventTap()
    if not dragEventTap then
        dragEventTap = hs.eventtap.new({ hs.eventtap.event.types.leftMouseDragged, hs.eventtap.event.types.leftMouseUp }, function(e)
            if e:getType() == hs.eventtap.event.types.leftMouseUp then
                isDragging = false
                dragEventTap:stop()
                return false
            end

            if isDragging and canvas then
                local mouse = hs.mouse.absolutePosition()
                local newX = mouse.x - dragOffset.x
                local newY = mouse.y - dragOffset.y
                canvas:topLeft({ x = newX, y = newY })
            end
            return false
        end)
    end
    return dragEventTap
end

-- Get sorted running apps
local function getRunningApps()
    local apps = hs.application.runningApplications()
    local regularApps = {}
    for _, app in ipairs(apps) do
        if app:kind() == 1 and app:title() and app:title() ~= "" then
            table.insert(regularApps, app)
        end
    end
    table.sort(regularApps, function(a, b)
        return a:title():lower() < b:title():lower()
    end)
    return regularApps
end

-- Build the palette
local function buildPalette()
    currentApps = getRunningApps()
    local frontApp = hs.application.frontmostApplication()
    local appCount = #currentApps
    local paletteHeight = titleBarHeight + (appCount * rowHeight) + 2

    -- Get saved position or default to top-right
    local screen = hs.screen.mainScreen()
    local screenFrame = screen:frame()
    local x = screenFrame.x + screenFrame.w - paletteWidth - 20
    local y = screenFrame.y + 40

    if canvas then
        local frame = canvas:frame()
        x = frame.x
        y = frame.y
        canvas:delete()
    end

    canvas = hs.canvas.new({ x = x, y = y, w = paletteWidth, h = paletteHeight })

    -- Title bar background
    local closeButtonSize = 10
    local closeButtonPadding = 3
    canvas:appendElements({
        {
            type = "rectangle",
            action = "fill",
            fillColor = { red = 0.75, green = 0.75, blue = 0.75 },
            frame = { x = 0, y = 0, w = paletteWidth, h = titleBarHeight },
        },
        {
            type = "text",
            text = "Applications",
            textColor = textColor,
            textSize = 10,
            textAlignment = "center",
            frame = { x = 0, y = 1, w = paletteWidth, h = titleBarHeight },
        },
        -- Close button
        {
            type = "text",
            text = "×",
            textColor = { red = 0.3, green = 0.3, blue = 0.3 },
            textSize = 12,
            textAlignment = "center",
            frame = { x = closeButtonPadding, y = 0, w = closeButtonSize, h = titleBarHeight },
        },
    })

    -- Main background
    canvas:appendElements({
        {
            type = "rectangle",
            action = "fill",
            fillColor = bgColor,
            frame = { x = 0, y = titleBarHeight, w = paletteWidth, h = paletteHeight - titleBarHeight },
        },
    })

    -- App rows
    for i, app in ipairs(currentApps) do
        local yPos = titleBarHeight + ((i - 1) * rowHeight)
        local isActive = frontApp and app:pid() == frontApp:pid()

        -- Highlight for active app
        if isActive then
            canvas:appendElements({
                {
                    type = "rectangle",
                    action = "fill",
                    fillColor = highlightColor,
                    frame = { x = 1, y = yPos, w = paletteWidth - 2, h = rowHeight },
                },
            })
        end

        -- App icon
        local icon = app:bundleID() and hs.image.imageFromAppBundle(app:bundleID())
        if icon then
            canvas:appendElements({
                {
                    type = "image",
                    image = icon:setSize({ w = iconSize, h = iconSize }),
                    frame = { x = padding, y = yPos + (rowHeight - iconSize) / 2, w = iconSize, h = iconSize },
                },
            })
        end

        -- App name (leave room for quit button)
        canvas:appendElements({
            {
                type = "text",
                text = app:title(),
                textColor = textColor,
                textSize = fontSize,
                textAlignment = "left",
                frame = { x = padding + iconSize + 6, y = yPos + (rowHeight - fontSize) / 2 - 2, w = paletteWidth - padding - iconSize - quitButtonSize - quitButtonPadding - 10, h = rowHeight },
            },
        })

        -- Quit button (×) - hide for Finder since it can't be quit
        local isFinder = app:bundleID() == "com.apple.finder"
        if not isFinder then
            local quitX = paletteWidth - quitButtonSize - quitButtonPadding
            local quitY = yPos + (rowHeight - quitButtonSize) / 2
            canvas:appendElements({
                {
                    type = "text",
                    text = "×",
                    textColor = { red = 0.4, green = 0.4, blue = 0.4 },
                    textSize = 14,
                    textAlignment = "center",
                    frame = { x = quitX, y = quitY - 2, w = quitButtonSize, h = quitButtonSize },
                },
            })
        end
    end

    -- Border
    canvas:appendElements({
        {
            type = "rectangle",
            action = "stroke",
            strokeColor = borderColor,
            strokeWidth = 1,
        },
    })

    -- Configure canvas behavior
    canvas:level(hs.canvas.windowLevels.floating)
    canvas:behavior(hs.canvas.windowBehaviors.canJoinAllSpaces)
    canvas:clickActivating(false)
    canvas:canvasMouseEvents(true, false, false, false)

    canvas:mouseCallback(function(c, msg, id, x, y)
        if msg == "mouseDown" then
            -- Check if click is in title bar
            if y <= titleBarHeight then
                -- Check if click is on close button (left side of title bar)
                if x <= 16 then
                    appPalette.hide()
                else
                    -- Dragging
                    isDragging = true
                    local frame = canvas:frame()
                    local mouse = hs.mouse.absolutePosition()
                    dragOffset.x = mouse.x - frame.x
                    dragOffset.y = mouse.y - frame.y
                    getDragEventTap():start()
                end
            -- Check if click is in app area
            elseif y > titleBarHeight then
                local appIndex = math.floor((y - titleBarHeight) / rowHeight) + 1
                if appIndex >= 1 and appIndex <= #currentApps then
                    local app = currentApps[appIndex]
                    local quitX = paletteWidth - quitButtonSize - quitButtonPadding
                    local isFinder = app:bundleID() == "com.apple.finder"
                    -- Check if click is on quit button (but not for Finder)
                    if x >= quitX and not isFinder then
                        app:kill()
                        hs.timer.doAfter(0.3, function()
                            if isVisible then buildPalette() end
                        end)
                    else
                        hs.application.launchOrFocus(app:name())
                        hs.timer.doAfter(0.1, function()
                            if isVisible then buildPalette() end
                        end)
                    end
                end
            end
        end
    end)

    if isVisible then
        canvas:show()
    end
end

-- Track app count to detect changes
local lastAppCount = 0
local pollTimer = nil

-- Poll for app changes every second when visible
local function startPolling()
    if not pollTimer then
        pollTimer = hs.timer.new(1, function()
            if isVisible and not isDragging then
                local newCount = #getRunningApps()
                if newCount ~= lastAppCount then
                    lastAppCount = newCount
                    buildPalette()
                end
            end
        end)
    end
    pollTimer:start()
end

local function stopPolling()
    if pollTimer then
        pollTimer:stop()
    end
end

-- Toggle visibility
function appPalette.toggle()
    if isVisible then
        appPalette.hide()
    else
        appPalette.show()
    end
end

function appPalette.show()
    if not isVisible then
        buildPalette()
        if canvas then canvas:show() end
        isVisible = true
        startPolling()
    end
end

function appPalette.hide()
    if canvas then canvas:hide() end
    isVisible = false
    stopPolling()
end

-- Hotkey to toggle (Ctrl+Cmd+A)
hs.hotkey.bind({ "ctrl", "cmd" }, "A", appPalette.toggle)

return appPalette
