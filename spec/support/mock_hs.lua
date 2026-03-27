-- Mock of the Hammerspoon `hs` global for use in tests.
-- Sets _G.hs and _G.toggleMenubar before any module under test is loaded.

local M = {}

M.urlHandlers = {}
M.calls = {}
M.runningApps = {}
M.currentTime = 1000000
M.lastTimerCallback = nil

function M.reset()
    M.urlHandlers = {}
    M.calls = {}
    M.runningApps = {}
    M.currentTime = 1000000
    M.applescriptResponse = nil
    M.lastTimerCallback = nil

    _G.hs = {
        urlevent = {
            bind = function(name, fn)
                M.urlHandlers[name] = fn
            end,
        },
        application = {
            watcher = {
                launching  = 0,
                activated  = 1,
                terminated = 2,
                launched   = 3,
                deactivated = 4,
                hidden     = 5,
                unhidden   = 6,
            },
            get = function(name)
                return M.runningApps[name]
            end,
        },
        menubar = {
            new = function()
                local mb = {}
                mb.setTitle = function(self, t) self.title = t end
                mb.setMenu  = function(self, m) self.menu  = m end
                mb.removeFromMenuBar = function(self) self.removed = true end
                return mb
            end,
        },
        notify = {
            new = function(t)
                local n = { title = t.title, informativeText = t.informativeText }
                n.send = function(self)
                    M.calls.notifications = M.calls.notifications or {}
                    table.insert(M.calls.notifications, {
                        title = self.title,
                        msg   = self.informativeText,
                    })
                end
                return n
            end,
        },
        timer = {
            secondsSinceEpoch = function() return M.currentTime end,
            new = function(_, callback)
                M.lastTimerCallback = callback
                return { start = function() end, stop = function() end }
            end,
        },
        canvas = {
            new = function()
                local c = {}
                setmetatable(c, {
                    __index = function()
                        return setmetatable({}, { __newindex = function() end })
                    end
                })
                c.appendElements = function() end
                c.level          = function() end
                c.behavior       = function() end
                c.show           = function() end
                c.delete         = function() end
                return c
            end,
            windowLevels    = { modalPanel = 100, floating = 101 },
            windowBehaviors = { canJoinAllSpaces = 1 },
        },
        screen = {
            mainScreen = function()
                return { frame = function() return { x = 0, y = 0, w = 1920, h = 1080 } end }
            end,
        },
        osascript = {
            applescript = function()
                if M.applescriptResponse then
                    return M.applescriptResponse()
                end
                return true, ""
            end,
        },
        execute = function(cmd)
            M.calls.execute = M.calls.execute or {}
            table.insert(M.calls.execute, cmd)
        end,
        alert = { show = function() end },
        image = {
            imageFromAppBundle = function() return nil end,
            imageFromName = function()
                return { setSize = function(self) return self end }
            end,
        },
        fs = {
            attributes = function() return nil end,
            dir = function() return function() return nil end end,
        },
    }

    _G.toggleMenubar = function(mode)
        M.calls.toggleMenubar = M.calls.toggleMenubar or {}
        table.insert(M.calls.toggleMenubar, mode)
    end
end

M.reset()

return M
