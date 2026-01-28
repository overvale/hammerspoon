---- Work ----

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

function vendorMailer()
    hs.osascript.applescript(
        'tell app \"Terminal\" to do script \"cd ~/code/vendor-mailer/ && python3 vendor_mailer.py\"')
    hs.application.launchOrFocus("Terminal")
end

function bidPackGen()
    hs.osascript.applescript(
        'tell app \"Terminal\" to do script \"cd ~/code/bid-pack-generator/ && ./bid-pack-generator.sh"')
    hs.application.launchOrFocus("Terminal")
end

function bidPackMailer()
    hs.osascript.applescript(
        'tell app \"Terminal\" to do script \"cd ~/code/vendor-mailer/ && ./bidpak_gen.py\"')
    hs.application.launchOrFocus("Terminal")
end


function bidFinder()
    hs.osascript.applescript('tell app \"Terminal\" to do script \"cd ~/code/bid-finder/ && ./bid-finder"')
    hs.application.launchOrFocus("Terminal")
end