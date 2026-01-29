-- Shared Utilities for Hammerspoon Config
-- Icon caching, event hub, and common functions

local utils = {}

-- Icon Cache
-- Structure: iconCache[bundleID][sizeKey] = image
local iconCache = {}

-- Get a cached icon, loading and sizing if needed
-- @param bundleID string: The app's bundle identifier
-- @param size table: { w = width, h = height }
-- @return hs.image or nil
function utils.getCachedIcon(bundleID, size)
    if not bundleID then return nil end

    local sizeKey = size.w .. "x" .. size.h
    iconCache[bundleID] = iconCache[bundleID] or {}

    if not iconCache[bundleID][sizeKey] then
        local icon = hs.image.imageFromAppBundle(bundleID)
        if icon then
            iconCache[bundleID][sizeKey] = icon:setSize(size)
        end
    end

    return iconCache[bundleID][sizeKey]
end

-- Clear the icon cache (useful if apps are updated)
function utils.clearIconCache()
    iconCache = {}
end

-- Event Hub
-- Central dispatcher for application events
local eventCallbacks = {
    activated = {},
    deactivated = {},
    launched = {},
    launching = {},
    terminated = {},
    hidden = {},
    unhidden = {},
}

-- Map Hammerspoon event types to our callback keys
local eventTypeMap = {
    [hs.application.watcher.activated] = "activated",
    [hs.application.watcher.deactivated] = "deactivated",
    [hs.application.watcher.launched] = "launched",
    [hs.application.watcher.launching] = "launching",
    [hs.application.watcher.terminated] = "terminated",
    [hs.application.watcher.hidden] = "hidden",
    [hs.application.watcher.unhidden] = "unhidden",
}

-- Register a callback for an app event
-- @param eventType string: "activated", "launching", "terminated", etc.
-- @param callback function: function(appName, appObject)
-- @return number: callback ID for unregistering
function utils.onAppEvent(eventType, callback)
    if not eventCallbacks[eventType] then
        error("Unknown event type: " .. tostring(eventType))
    end
    table.insert(eventCallbacks[eventType], callback)
    return #eventCallbacks[eventType]
end

-- Unregister a callback
-- @param eventType string
-- @param callbackId number
function utils.offAppEvent(eventType, callbackId)
    if eventCallbacks[eventType] then
        eventCallbacks[eventType][callbackId] = nil
    end
end

-- Dispatch an event to all registered callbacks
-- Called by the central watcher in init.lua
function utils.dispatchEvent(appName, eventType, appObject)
    local eventKey = eventTypeMap[eventType]
    if eventKey and eventCallbacks[eventKey] then
        for _, callback in pairs(eventCallbacks[eventKey]) do
            if callback then
                callback(appName, appObject)
            end
        end
    end
end

-- Shared App List Function
-- Single implementation for getting sorted running apps
-- @return table: sorted list of running app objects
function utils.getRunningApps()
    local apps = hs.application.runningApplications()
    local regularApps = {}

    for _, app in ipairs(apps) do
        local title = app:title()
        if app:kind() == 1 and title and title ~= "" then
            table.insert(regularApps, app)
        end
    end

    table.sort(regularApps, function(a, b)
        return a:title():lower() < b:title():lower()
    end)

    return regularApps
end

return utils
