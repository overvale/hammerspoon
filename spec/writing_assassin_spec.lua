---@diagnostic disable: undefined-field
package.path = package.path .. ";./?.lua"

local mock = require("spec.support.mock_hs")

local function load()
    package.loaded["writingAssassin"] = nil
    return require("writingAssassin")
end

local function makeApp()
    local killed = false
    return {
        kill      = function(self) killed = true end,
        wasKilled = function() return killed end,
    }
end

describe("writingAssassin", function()
    local wa

    before_each(function()
        mock.reset()
        wa = load()
    end)

    -- -----------------------------------------------------------------------

    describe("isActive()", function()
        it("returns false by default", function()
            assert.is_false(wa.isActive())
        end)
    end)

    -- -----------------------------------------------------------------------

    describe("URL events", function()
        it("writing-mode-start activates", function()
            mock.urlHandlers["writing-mode-start"]()
            assert.is_true(wa.isActive())
        end)

        it("writing-mode-exit does not deactivate without approval", function()
            mock.urlHandlers["writing-mode-start"]()
            mock.urlHandlers["writing-mode-exit"]()
            assert.is_true(wa.isActive())
        end)

        it("writing-mode-exit deactivates when exit is approved", function()
            mock.urlHandlers["writing-mode-start"]()
            wa.approveExit()
            mock.urlHandlers["writing-mode-exit"]()
            assert.is_false(wa.isActive())
        end)

        it("writing-mode-toggle activates when inactive", function()
            mock.urlHandlers["writing-mode-toggle"]()
            assert.is_true(wa.isActive())
        end)

        it("writing-mode-toggle does not deactivate without approval", function()
            mock.urlHandlers["writing-mode-start"]()
            mock.urlHandlers["writing-mode-toggle"]()
            assert.is_true(wa.isActive())
        end)

        it("writing-mode-toggle deactivates when exit is approved", function()
            mock.urlHandlers["writing-mode-start"]()
            wa.approveExit()
            mock.urlHandlers["writing-mode-toggle"]()
            assert.is_false(wa.isActive())
        end)
    end)

    -- -----------------------------------------------------------------------

    describe("handleAppEvent()", function()
        it("returns false when writing mode is inactive", function()
            local app = makeApp()
            assert.is_false(wa.handleAppEvent("Mail", hs.application.watcher.launching, app))
            assert.is_false(app:wasKilled())
        end)

        it("returns false for non-targeted apps when active", function()
            mock.urlHandlers["writing-mode-start"]()
            local app = makeApp()
            assert.is_false(wa.handleAppEvent("Photoshop", hs.application.watcher.launching, app))
            assert.is_false(app:wasKilled())
        end)

        it("kills a targeted app on launch and returns true", function()
            mock.urlHandlers["writing-mode-start"]()
            local app = makeApp()
            assert.is_true(wa.handleAppEvent("Mail", hs.application.watcher.launching, app))
            assert.is_true(app:wasKilled())
        end)

        it("kills a targeted app on activation and returns true", function()
            mock.urlHandlers["writing-mode-start"]()
            local app = makeApp()
            assert.is_true(wa.handleAppEvent("Mail", hs.application.watcher.activated, app))
            assert.is_true(app:wasKilled())
        end)

        it("sends a notification when killing an app", function()
            mock.urlHandlers["writing-mode-start"]()
            wa.handleAppEvent("Mail", hs.application.watcher.launching, makeApp())
            assert.is_not_nil(mock.calls.notifications)
            assert.equals(1, #mock.calls.notifications)
            assert.equals("Mail was blocked", mock.calls.notifications[1].msg)
        end)

        it("dedupes notifications for the same app within 1 second", function()
            mock.urlHandlers["writing-mode-start"]()
            local app = makeApp()
            wa.handleAppEvent("Mail", hs.application.watcher.launching, app)
            wa.handleAppEvent("Mail", hs.application.watcher.activated, app)
            assert.equals(1, #mock.calls.notifications)
        end)

        it("sends a second notification after the dedup window passes", function()
            mock.urlHandlers["writing-mode-start"]()
            local app = makeApp()
            wa.handleAppEvent("Mail", hs.application.watcher.launching, app)
            mock.currentTime = mock.currentTime + 2
            wa.handleAppEvent("Mail", hs.application.watcher.activated, app)
            assert.equals(2, #mock.calls.notifications)
        end)

        it("does not dedupe notifications for different apps", function()
            mock.urlHandlers["writing-mode-start"]()
            wa.handleAppEvent("Mail",     hs.application.watcher.launching, makeApp())
            wa.handleAppEvent("Calendar", hs.application.watcher.launching, makeApp())
            assert.equals(2, #mock.calls.notifications)
        end)
    end)

    -- -----------------------------------------------------------------------

    describe("entry confirmation (running blocked apps)", function()
        it("activates immediately when no blocked apps are running", function()
            mock.urlHandlers["writing-mode-toggle"]()
            assert.is_true(wa.isActive())
        end)

        it("activates when user confirms with blocked apps running", function()
            mock.runningApps["Mail"] = makeApp()
            mock.applescriptResponse = function() return true, "Enter Writing Mode" end
            mock.urlHandlers["writing-mode-toggle"]()
            assert.is_true(wa.isActive())
        end)

        it("kills running blocked apps on confirmed entry", function()
            local app = makeApp()
            mock.runningApps["Mail"] = app
            mock.applescriptResponse = function() return true, "Enter Writing Mode" end
            mock.urlHandlers["writing-mode-toggle"]()
            assert.is_true(app:wasKilled())
        end)

        it("does not activate when user cancels", function()
            mock.runningApps["Mail"] = makeApp()
            mock.applescriptResponse = function() return false, nil end -- Cancel
            mock.urlHandlers["writing-mode-toggle"]()
            assert.is_false(wa.isActive())
        end)
    end)

    -- -----------------------------------------------------------------------

    describe("ignoringNextToggle (cancel bounce prevention)", function()
        it("ignores the immediate bounce-back toggle after a cancelled entry", function()
            mock.runningApps["Mail"] = makeApp()
            mock.applescriptResponse = function() return false, nil end

            -- Toggle 1: user cancels → focus is toggled back off
            mock.urlHandlers["writing-mode-toggle"]()
            assert.is_false(wa.isActive())

            -- Toggle 2: the bounce-back should be swallowed
            mock.runningApps = {} -- clear so it would succeed if not ignored
            mock.urlHandlers["writing-mode-toggle"]()
            assert.is_false(wa.isActive())
        end)

        it("accepts a toggle again after the bounce is consumed", function()
            mock.runningApps["Mail"] = makeApp()
            mock.applescriptResponse = function() return false, nil end

            mock.urlHandlers["writing-mode-toggle"]() -- cancel
            mock.runningApps = {}
            mock.urlHandlers["writing-mode-toggle"]() -- bounce (ignored)
            mock.urlHandlers["writing-mode-toggle"]() -- should now activate
            assert.is_true(wa.isActive())
        end)
    end)

    -- -----------------------------------------------------------------------

    describe("system bypass (Focus turned off at OS level)", function()
        it("re-enables focus when user denies exit", function()
            mock.urlHandlers["writing-mode-start"]()
            mock.applescriptResponse = function() return true, "" end -- Nevermind
            mock.urlHandlers["writing-mode-exit"]()
            -- Fire countdown to completion
            for i = 1, 15 do
                mock.lastTimerCallback()
            end
            -- Should still be active
            assert.is_true(wa.isActive())
            -- Should have called toggle() to re-enable Focus
            assert.is_not_nil(mock.calls.execute)
            local lastCmd = mock.calls.execute[#mock.calls.execute]
            assert.truthy(lastCmd:find("Toggle Writing Focus"))
        end)

        it("exits writing mode when user approves exit", function()
            mock.urlHandlers["writing-mode-start"]()
            mock.applescriptResponse = function() return true, "I want to stop writing" end
            mock.urlHandlers["writing-mode-exit"]()
            -- Fire countdown to completion
            for i = 1, 15 do
                mock.lastTimerCallback()
            end
            assert.is_false(wa.isActive())
        end)

        it("writing-mode-start is a no-op when already active", function()
            mock.urlHandlers["writing-mode-start"]()
            assert.is_true(wa.isActive())
            -- Second start should not error or create duplicate state
            mock.urlHandlers["writing-mode-start"]()
            assert.is_true(wa.isActive())
        end)
    end)

    -- -----------------------------------------------------------------------

    describe("onToggle() callbacks", function()
        it("fires callback with true when writing mode starts", function()
            local received = nil
            wa.onToggle(function(active) received = active end)
            mock.urlHandlers["writing-mode-start"]()
            assert.is_true(received)
        end)

        it("fires callback with false when writing mode exits", function()
            local received = nil
            mock.urlHandlers["writing-mode-start"]()
            wa.onToggle(function(active) received = active end)
            wa.approveExit()
            mock.urlHandlers["writing-mode-exit"]()
            assert.is_false(received)
        end)

        it("fires multiple registered callbacks", function()
            local a, b = nil, nil
            wa.onToggle(function(active) a = active end)
            wa.onToggle(function(active) b = active end)
            mock.urlHandlers["writing-mode-start"]()
            assert.is_true(a)
            assert.is_true(b)
        end)
    end)
end)
