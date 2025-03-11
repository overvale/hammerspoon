-- HammerMenu
-- ----------------------------------------------

hammerMenu = hs.menubar.new()

function hammerMenuItem()
    local hammerMenuTable = {
        { title = "􀪏 Build TODO List", fn = function() runScript("~/src/bin/todo") end },
        { title = "􀞀 Insert Date", fn = insertDate },
        { title = "-" },
        { title = "Open Today's Log Entry", fn = logbookNew },
        { title = "Open Logbook", fn = logbookShow },
        { title = "-" },
        { title = "Backup to Cloud", fn = backupCloud },
        { title = "Latest Backup:", disabled = true },
        { title = lastBackupCloud(), fn = openLastBackup },
        { title = "-" },
        { title = "1923", disabled = true },
        { title = "1923 Log Entry (Today)", fn = logbook1923New },
        { title = "1923 Logbook", fn = logbook1923Show },
        { title = "1923 Tools", disabled = true },
        { title = "Mail BIDPAK", fn = bidPackMailer },
        { title = "Vendor Mailer", fn = vendorMailer },
        { title = "Bid Pack Generator", fn = bidPackGen },
        { title = "Bid Finder", fn = bidFinder },
    }
    return hammerMenuTable
end

hammerIcon = hs.styledtext.new("􀂢", {
    font = { size = 17 },
    baselineOffset = -2,
})

hammerMenu:setTitle(hammerIcon)
hammerMenu:setMenu(hammerMenuItem)
hammerMenu:setTooltip("Hammerspoon Rocks!")

