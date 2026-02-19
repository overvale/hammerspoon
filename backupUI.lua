local backupUI = {}

local HOME = os.getenv("HOME")
local SCRIPT_PATH = HOME .. "/code/rsync-backup/backup-cloud.sh"
local LOG_DIR = HOME .. "/code/rsync-backup/logs"

local activeTask = nil
local activeLabel = nil

local function notify(text)
    hs.notify.new({
        title = "Backup",
        informativeText = text,
    }):send()
end

local function isFile(path)
    local attr = hs.fs.attributes(path)
    return attr and attr.mode == "file"
end

local function newestLogFile()
    local iter, dirObj = hs.fs.dir(LOG_DIR)
    if not iter then return nil end

    local latestPath = nil
    local latestMtime = 0

    for entry in iter, dirObj do
        if string.sub(entry, 1, 1) ~= "." then
            local fullPath = LOG_DIR .. "/" .. entry
            local attr = hs.fs.attributes(fullPath)
            if attr and attr.mode == "file" and attr.modification and attr.modification > latestMtime then
                latestMtime = attr.modification
                latestPath = fullPath
            end
        end
    end

    return latestPath
end

local function runBackup(args, label)
    if activeTask then
        hs.alert.show("Backup already running")
        return
    end

    if not isFile(SCRIPT_PATH) then
        hs.alert.show("Backup script not found")
        return
    end

    activeLabel = label
    notify("Starting: " .. label)

    activeTask = hs.task.new("/bin/bash", function(exitCode, stdOut, stdErr)
        activeTask = nil

        if exitCode == 0 then
            notify("Finished: " .. activeLabel)
        else
            hs.alert.show("Backup failed: " .. activeLabel)
            notify("Failed: " .. activeLabel)
        end

        activeLabel = nil
        return true
    end, nil, { SCRIPT_PATH, table.unpack(args) })

    if not activeTask then
        activeLabel = nil
        hs.alert.show("Could not start backup task")
        return
    end

    if not activeTask:start() then
        activeTask = nil
        activeLabel = nil
        hs.alert.show("Failed to launch backup task")
    end
end

local function runDeleteEnabledBackup()
    local choice = hs.dialog.blockAlert(
        "Run Full Backup?",
        "This runs rsync with --delete enabled. Files removed locally may be removed remotely.",
        "Run",
        "Cancel"
    )

    if choice == "Run" then
        runBackup({ "--yes-delete" }, "Full backup (delete enabled)")
    end
end

function backupUI.showChooser()
    local choices = {
        {
            text = "Run Safe Backup",
            subText = "Runs with --no-delete",
            action = function() runBackup({ "--no-delete" }, "Safe backup (no delete)") end,
        },
        {
            text = "Run Dry-Run Backup",
            subText = "Runs with --dry-run --no-delete",
            action = function() runBackup({ "--dry-run", "--no-delete" }, "Dry-run backup") end,
        },
        {
            text = "Run Full Backup",
            subText = "Runs with delete enabled after confirmation",
            action = runDeleteEnabledBackup,
        },
        {
            text = "Open Logs Folder",
            subText = LOG_DIR,
            action = function() os.execute('open "' .. LOG_DIR .. '"') end,
        },
        {
            text = "Open Latest Log",
            subText = "Open most recent backup log file",
            action = function()
                local latest = newestLogFile()
                if latest then
                    os.execute('open "' .. latest .. '"')
                else
                    hs.alert.show("No log files found")
                end
            end,
        },
    }

    local chooser = hs.chooser.new(function(selection)
        if selection and selection.action then
            selection.action()
        end
    end)

    chooser:placeholderText("Backup actions")
    chooser:searchSubText(true)
    chooser:choices(choices)
    chooser:show()
end

function backupUI.backupCloud()
    runBackup({ "--yes-delete" }, "Full backup (delete enabled)")
end

return backupUI
