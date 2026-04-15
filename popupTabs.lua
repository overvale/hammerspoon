-- Pop-up Folder Tabs (macOS 8/9 style)
-- Clickable tabs at the bottom of the screen that open folders

local popupTabs = {}
local screenWatcher = nil
local rightClickTap = nil
local hidden = false

-- Max depth for recursive submenu population (prevents slowdowns on deep trees)
local maxMenuDepth = 5

-- Set to true to hide tabs when writing mode is active
popupTabs.hideInWritingMode = true

-- Configuration
local tabHeight = 24
local tabPadding = 20
local cornerRadius = 6
local tabColor = { red = 0.9, green = 0.9, blue = 0.9 }
local tabBorderColor = { red = 0.6, green = 0.6, blue = 0.6 }
local textColor = { red = 0, green = 0, blue = 0 }
local fontSize = 12
local iconSize = 16
local iconPadding = 4  -- space between icon and text

-- Get the system folder icon
local folderIcon = hs.image.imageFromName("NSFolder"):setSize({ w = iconSize, h = iconSize })

-- Define your folder tabs here
local folders = {
   { name = "Documents", path = "~/Documents" },
   { name = "Code", path = "~/code" },
   { name = "Overveil", path = "~/Documents/the-overveil" },
   { name = "Downloads", path = "~/Downloads" },
   { name = "Team Taylor", path = "~/Team Taylor" },
}

-- Expand ~ to home directory
local function expandPath(path)
    if string.sub(path, 1, 2) == "~/" then
        return os.getenv("HOME") .. string.sub(path, 2)
    end
    return path
end

-- Open folder in Finder
local function openFolder(path)
    local expanded = expandPath(path)
    hs.execute('open "' .. expanded .. '"')
end

local menuIconSize = 16

-- Redraws an hs.image at an exact pixel size by rendering it through a canvas.
-- NSMenu ignores hs.image:setSize() hints, so we produce a bitmap of the
-- target size so the menu can't scale it up.
local function resizeIcon(img, size)
    if not img then return nil end
    local c = hs.canvas.new({ x = 0, y = 0, w = size, h = size })
    c[1] = {
        type = "image",
        image = img,
        frame = { x = 0, y = 0, w = size, h = size },
        imageScaling = "scaleToFit",
    }
    local out = c:imageFromCanvas()
    c:delete()
    return out
end

-- Build a recursive menu table listing the contents of a folder (Dock-style).
local function buildMenuItems(folderPath, depth)
    local items = {}
    local expanded = expandPath(folderPath)

    local attrs = hs.fs.attributes(expanded)
    if not attrs or attrs.mode ~= "directory" then
        table.insert(items, { title = "(folder not found)", disabled = true })
        return items
    end

    if depth == 0 then
        table.insert(items, {
            title = "Open in Finder",
            fn = function() openFolder(folderPath) end,
        })
        table.insert(items, { title = "-" })
    end

    if depth >= maxMenuDepth then
        return items
    end

    local entries = {}
    local ok, err = pcall(function()
        for file in hs.fs.dir(expanded) do
            if file ~= "." and file ~= ".." and not file:match("^%.") then
                local fullPath = expanded .. "/" .. file
                local a = hs.fs.attributes(fullPath)
                if a then
                    table.insert(entries, {
                        name = file,
                        path = fullPath,
                        isDir = a.mode == "directory",
                    })
                end
            end
        end
    end)
    if not ok then
        table.insert(items, { title = "(unable to read folder)", disabled = true })
        return items
    end

    table.sort(entries, function(a, b)
        if a.isDir ~= b.isDir then return a.isDir end
        return a.name:lower() < b.name:lower()
    end)

    if #entries == 0 then
        table.insert(items, { title = "(empty)", disabled = true })
        return items
    end

    for _, entry in ipairs(entries) do
        local icon = resizeIcon(hs.image.iconForFile(entry.path), menuIconSize)

        if entry.isDir then
            local subPath = entry.path
            table.insert(items, {
                title = entry.name,
                image = icon,
                fn = function() hs.execute('open "' .. subPath .. '"') end,
                menu = buildMenuItems(entry.path, depth + 1),
            })
        else
            local filePath = entry.path
            table.insert(items, {
                title = entry.name,
                image = icon,
                fn = function()
                    hs.execute('open "' .. filePath .. '"')
                end,
            })
        end
    end

    return items
end

local function showFolderMenu(folderPath, position)
    local items = buildMenuItems(folderPath, 0)
    local menu = hs.menubar.new(false)
    menu:setMenu(items)
    menu:popupMenu(position)
    menu:delete()
end

local function findTabAtPoint(point)
    for i, tab in ipairs(popupTabs) do
        if tab then
            local frame = tab:frame()
            if point.x >= frame.x and point.x < frame.x + frame.w
               and point.y >= frame.y and point.y < frame.y + frame.h then
                return folders[i]
            end
        end
    end
    return nil
end

-- Create the tabs
local tabSpacing = 12

local function clearTabs()
    for i, tab in ipairs(popupTabs) do
        if tab then
            tab:delete()
            popupTabs[i] = nil
        end
    end
end

local function createTabs()
    local screen = hs.screen.mainScreen()
    local screenFrame = screen:frame()

    -- First pass: calculate total width of all tabs
    local totalWidth = 0
    local tabWidths = {}
    for i, folder in ipairs(folders) do
        local textWidth = hs.drawing.getTextDrawingSize(folder.name, { size = fontSize }).w
        local tabWidth = tabPadding + iconSize + iconPadding + textWidth + tabPadding
        tabWidths[i] = tabWidth
        totalWidth = totalWidth + tabWidth
        if i < #folders then
            totalWidth = totalWidth + tabSpacing
        end
    end

    -- Calculate starting x position to center the group
    local xOffset = (screenFrame.w - totalWidth) / 2

    for i, folder in ipairs(folders) do
        local tabWidth = tabWidths[i]

        -- Create canvas for this tab
        local canvas = hs.canvas.new({
            x = screenFrame.x + xOffset,
            y = screenFrame.y + screenFrame.h - tabHeight,
            w = tabWidth,
            h = tabHeight
        })

        -- Tab background
        local iconX = tabPadding
        local iconY = (tabHeight - iconSize) / 2
        local textX = tabPadding + iconSize + iconPadding

        canvas:appendElements({
            {
                type = "rectangle",
                action = "fill",
                fillColor = tabColor,
                roundedRectRadii = { xRadius = cornerRadius, yRadius = cornerRadius },
            },
            {
                type = "rectangle",
                action = "stroke",
                strokeColor = tabBorderColor,
                strokeWidth = 1,
                roundedRectRadii = { xRadius = cornerRadius, yRadius = cornerRadius },
            },
            {
                type = "image",
                image = folderIcon,
                frame = { x = iconX, y = iconY, w = iconSize, h = iconSize },
            },
            {
                type = "text",
                text = folder.name,
                textColor = textColor,
                textSize = fontSize,
                textAlignment = "left",
                frame = { x = textX, y = (tabHeight - fontSize) / 2 - 2, w = tabWidth - textX, h = tabHeight }
            }
        })

        -- Make it clickable
        canvas:clickActivating(false)
        canvas:canvasMouseEvents(true, false, false, false)
        local folderPath = folder.path  -- capture in closure
        canvas:mouseCallback(function(c, msg, id, x, y)
            if msg == "mouseDown" then
                openFolder(folderPath)
            end
        end)

        -- Show the tab (below normal windows, above desktop)
        canvas:level(hs.canvas.windowLevels.normal - 1)
        canvas:behavior(hs.canvas.windowBehaviors.canJoinAllSpaces
                      + hs.canvas.windowBehaviors.stationary)
        canvas:show()

        -- Store reference
        popupTabs[i] = canvas

        -- Move x position for next tab
        xOffset = xOffset + tabWidth + tabSpacing
    end
end

function popupTabs.hide()
    hidden = true
    clearTabs()
end

function popupTabs.show()
    hidden = false
    createTabs()
end

function popupTabs.refresh()
    clearTabs()
    if not hidden then
        createTabs()
    end
end

local function startScreenWatcher()
    if screenWatcher then
        return
    end

    screenWatcher = hs.screen.watcher.new(function()
        popupTabs.refresh()
    end)
    screenWatcher:start()
end

local function startRightClickTap()
    if rightClickTap then return end

    rightClickTap = hs.eventtap.new({ hs.eventtap.event.types.rightMouseDown }, function(event)
        if hidden then return false end
        local pos = event:location()
        local folder = findTabAtPoint(pos)
        if folder then
            local folderPath = folder.path
            -- Defer so we don't show the menu from inside the eventtap callback.
            hs.timer.doAfter(0, function()
                showFolderMenu(folderPath, pos)
            end)
            return true
        end
        return false
    end)
    rightClickTap:start()
end

function popupTabs.stop()
    if screenWatcher then
        screenWatcher:stop()
        screenWatcher = nil
    end
    if rightClickTap then
        rightClickTap:stop()
        rightClickTap = nil
    end
    clearTabs()
end

-- Initialize
popupTabs.refresh()
startScreenWatcher()
startRightClickTap()

return popupTabs
