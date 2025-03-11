-- Transient Keymaps
-- ----------------------------------------------

screen = hs.screen.mainScreen()
screenFrame = screen:frame()
menubarHeight = screen:frame().y

transientBanner = {}
transientBindings = {}
transientKeys = hs.hotkey.modal.new()

-- When the modal keymap is activated...
function transientKeys:entered()
    -- First create a menubar item
    myKeysMenuItem = hs.menubar.new():setTitle("􀇳 Transient Keymap!")
    myKeysMenuItem:setTooltip("Press Escape to deactivate.")

    -- Then create the notification banner atop the menubar
    transientBanner = hs.canvas.new({ x = screenFrame.x, y = menubarHeight - 7, w = screenFrame.w, h = 10 })
    transientBanner:appendElements({
        type = "rectangle",
        action = "fill",
        fillColor = { red = 1, green = 0, blue = 0, alpha = 1 },
        frame = { x = 0, y = 0, w = "100%", h = "100%" }
    })

    -- And show it
    transientBanner:show()
end

-- When the modal keymap is exited, kill the displayed helpers
function transientKeys:exited()
    myKeysMenuItem:delete()
    transientBanner:delete()
end

-- Bind keys for activating the transient keymap and cheetsheat
do
    local mod = { 'shift', 'cmd' }
    local key = 'space'
    hs.hotkey.bind(mod, key, function() transientKeys:enter() end)
    -- prevent recursion by exiting if the hotkey is repeated
    transientKeys:bind(mod, key, function() transientKeys:exit() end)
    -- escape should also work as a way to exit
    transientKeys:bind('', 'escape', function() transientKeys:exit() end)
end

-- Accepts strings and function names
-- Strings are assumed to be Application names
transientBindings = {
    { {},          'm', 'Mail' },
    { { 'shift' }, 'm', 'Messages' },
    { {},          'c', 'Calendar' },
    { {},          's', 'Safari' },
    { {},          'a', 'Music' },
    { {},          't', 'Terminal' },
    { {},          'f',  openFaves },
    { {},          'n', 'Notes' },
    { {},          'v', 'Visual Studio Code' },
    { {},          'r', 'Cursor' },
    { {},          'e', 'BBEdit' },
    { {},          'g', 'ChatGPT' },
    -- Work
    { { 'cmd' },   'x', xLookupHelper },
    { { 'cmd' },   'r', receivedThanks },
    -- Util
    { {'alt'},     'r', reloadHSConfig },
}

for i, mapping in ipairs(transientBindings) do
    local mod = mapping[1]
    local key = mapping[2]
    local fn  = mapping[3]
    transientKeys:bind(mod, key, function()
        if (type(fn) == 'string') then
            hs.application.launchOrFocus(fn)
        else
            fn()
        end
        transientKeys:exit()
    end)
end
