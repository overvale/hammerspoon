-- Pop-up Folder Tabs (macOS 8/9 style)
-- Clickable tabs at the bottom of the screen that open folders

local popupTabs = {}

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

-- Create the tabs
local tabSpacing = 12

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
        canvas:behavior(hs.canvas.windowBehaviors.canJoinAllSpaces)
        canvas:show()

        -- Store reference
        popupTabs[i] = canvas

        -- Move x position for next tab
        xOffset = xOffset + tabWidth + tabSpacing
    end
end

-- Initialize
createTabs()

return popupTabs
