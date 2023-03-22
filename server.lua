----------------------------------------->>
-- PURPOSE	: Golf Battle
-- DEVELOPER: Slow
-- FILE	 : golf.slua (server)
----------------------------------------->>

local dimension = 0
local mainSpawnPoint = { 2898 }
local validGolfHoleId = 13649
local validGolfBall = 441
local lowestScore = 0
-- COORDINATES OF THE MAP USED FOR TIED ROUNDS 
local coordinates = {
    { 8661, 1278.8, -197.8, 967.70001, 0, 0, 0 },
    { 8661, 1278.8, -177.89999, 967.70001, 0, 0, 0 },
    { 8661, 1278.8, -158, 967.70001, 0, 0, 0 },
    { 8661, 1278.8, -138.10001, 967.70001, 0, 0, 0 },
    { 8661, 1278.8, -118.2, 967.70001, 0, 0, 0 },
    { 8661, 1278.8, -98.3, 967.70001, 0, 0, 0 },
    { 6959, 1279.5, -207.8, 987.59998, 90, 0, 0 },
    { 6959, 1279.5, -88.4, 987.59998, 90, 0, 0 },
    { 6959, 1298.8, -187.10001, 987.59998, 90, 0, 90 },
    { 6959, 1298.8, -145.8, 987.59998, 90, 0, 90 },
    { 6959, 1298.8, -104.5, 987.59998, 90, 0, 90 },
    { 6959, 1258.9, -187.10001, 987.59998, 90, 0, 90 },
    { 6959, 1258.9, -145.8, 987.59998, 90, 0, 90 },
    { 6959, 1258.9, -104.5, 987.59998, 90, 0, 90 },
    { 13646, 1279.3, -111.9, 967.20001, 0, 0, 0 },
}
local eventData = {
    ["activeHole"] = 0,
    ["roundsPlayed"] = 0,
    ["winner"] = nil,
    ["spawnPoint"] = {}
}
local loadedFloorTiles = {}
local hardcodedObjectsForTiedRound = {}
local playersInEvent = {} -- Needs change
local winners = {}
local isRoundRunning = false
local playerThatReachedHoleFirst = nil
local expirationTimer = nil
local deathRun = false
local isUntieRound = false
local activeUnnamedTimer = nil
local killParticipantsSetting = 1
local roundMaxTime = 0
local roundMaxTimer = nil
local expirationTime = 20000 -- Starts after first player has reached the active hole
local isEventLoaded = false
local isEventRunning = false
local playersThatReachedHole = {}
local playersThatReachedHoleMutated = {}
local loadedGolfHoles = {}
local scoreboard = {} -- FORMAT: { username, score, acc, plrValue, vehicle, playedHoles }
local warningMessages = { 
    [1] = "You must be CEM to execute this command!", 
    [2] = "This command can only be executed in the event dimension!", 
    [3] = "SYNTAX: /golf load | /golf start < 1 (normal) - 2 (death run) > | /golf expiration <time in seconds> | /golf kills < 1 (no kills) - 2 (kill last) - 3 (kill many) > | /golf stop | /golf unload",
    [4] = "Event is already running!",
    [5] = "No valid GROUND tiles were found on the map. Valid IDs: 8661, 6959",
    [6] = "No GOLF HOLES were found on the map. Valid ID: 13649. Use /golf load",
    [7] = "No spawn point (ID 2898) was found on the map. Map one at the beginning of the course.",
    [8] = "Expiration time value in SECONDS is missing. Syntax: /golf expiration <number of seconds, minimum value is 20>",
    [9] = "Expiration time value in SECONDS is too low, minimum value is 20.",
    [10] = "Event is not running.",
    [11] = "Tiles have already been loaded. Type /golf unload to unload or /golf start to launch the gamemode.",
    [12] = "Event has been stopped.",
    [13] = "STOPPED: This event requires at least 2 participants.",
    [14] = "Event's max time value in MINUTES is missing. Syntax: /golf time <number of minutes, minimum value is 3>",
    [15] = "Event's max time value in MINUTES is too low, minimum value is 3.",
    [16] = "Cannot use this command while the event is running. Use /golf stop",
}

function commandsHandler(plr, command, argument, arg2)
    -- if (not isPlayerCEM(plr)) then
    --     outputChatBox(warningMessages[1], plr, 255, 0, 0)
    --     return false
    -- end
    if (getElementDimension(plr) ~= dimension) then
		outputChatBox(warningMessages[2], plr, 255, 0, 0)
		return false
	end
    if (not argument or argument == "" or argument == "syntax") then
        outputChatBox(warningMessages[3], plr, 255, 0, 0)
		return false
    end
    if (argument == "load") then
        if (#loadedGolfHoles > 0 or isEventLoaded) then
            outputChatBox(warningMessages[11], plr, 255, 0, 0)
            return false
        end  
        for i, v in ipairs(getElementsByType("object")) do
            if (getElementDimension(v) == dimension and (getElementModel(v) == mainSpawnPoint[1] or getElementModel(v) == validGolfHoleId)) then
                local x, y, z = getElementPosition(v)
                if (getElementModel(v) == validGolfHoleId) then
                    local colShape = createColTube(x, y, z, 2.5, 3)
                    setElementDimension(colShape, dimension)
                    loadedGolfHoles[#loadedGolfHoles + 1] = { v, x, y, z, colShape }
                elseif (getElementModel(v) == mainSpawnPoint[1]) then
                    mainSpawnPoint[2] = { x, y, z }
                    eventData["spawnPoint"] = { x, y, z }
                end
            end
        end           
        if (not mainSpawnPoint[2]) then
            outputChatBox(warningMessages[7], plr, 255, 0, 0)
            return false
        end      
        if (#loadedGolfHoles == 0) then
            outputChatBox(warningMessages[6], plr, 255, 0, 0)
            return false
        end
        outputChatBox('- Loaded '.. #loadedGolfHoles .." holes and 1 spawn point for this event!", plr, 255, 255, 0)
        isEventLoaded = true
    elseif (argument == "start") then
        if (isEventRunning) then
            outputChatBox(warningMessages[4], plr, 255, 0, 0)
            return false
        end
        if (#loadedGolfHoles == 0) then
            outputChatBox(warningMessages[7], plr, 255, 0, 0)
            return false
        end
        if (not tonumber(arg2) or tonumber(arg2) == 1) then
            deathRun = false
            killParticipantsSetting = 1
            roundMaxTime = 180000
            outputChatBox("- Event is starting - death run DISABLED. Event will end in "..math.floor((roundMaxTime/1000)/60).." minutes.", plr, 0, 255, 255)  
        elseif (tonumber(arg2) == 2) then
            deathRun = true
            killParticipantsSetting = 3
            roundMaxTime = 0
            if (expirationTime == 20000) then
                outputChatBox("- Event is starting - death run ENABLED. It is recommended to set the expiration time above 20 seconds (currently "..(expirationTime/1000).."). SYNTAX: /golf expiration <seconds>", plr, 0, 255, 255)  
            else
                outputChatBox("- Event is starting - death run ENABLED. Current expiration time set to "..(expirationTime/1000).." seconds.", plr, 0, 255, 255)  
            end
        end
        -- if (#playersInDashFallout() == 0) then
        --     local numberOfPlayers = #playersInDashFallout()
        --     if (port ~= 22023) then
        --         if (numberOfPlayers < 2) then
        --             outputChatBox(warningMessages[13], plr, 255, 0, 0)
        --             stopGamemode(plr)
        --             return
        --         end
        --     end
        -- end
        launchGamemode()
    elseif (argument == "elim") then
        if (not tonumber(arg2) or tonumber(arg2) == 1) then
            killParticipantsSetting = 1
            outputChatBox("- SETTING CHANGE: Nobody will be killed after each round.", plr, 255, 255, 0)  
        elseif (tonumber(arg2) == 2) then
            killParticipantsSetting = 2
            outputChatBox("- SETTING CHANGE: Last participant in the scoreboard will be killed after each round.", plr, 255, 255, 0)
        elseif (tonumber(arg2) == 3) then
            killParticipantsSetting = 3
            outputChatBox("- SETTING CHANGE: Every player that fails to reach the active hole will be killed after each round.", plr, 255, 255, 0)
        end
    elseif (argument == "exp") then
        if (not arg2) then
            outputChatBox(warningMessages[8], plr, 255, 0, 0)
            return false
        end
        if (tonumber(arg2) * 1000 < 20000) then
            outputChatBox(warningMessages[9], plr, 255, 0, 0)
            return false
        end
        -- if (isRoundRunning) then
        --     outputChatBox(warningMessages[16], plr, 255, 0, 0)
        --     return false
        -- end
        expirationTime = tonumber(arg2) * 1000
        outputChatBox("- Expiration time until round ends set to "..arg2.." seconds.", plr, 255, 255, 0)
        -- exports.CITtrivia:sendMessage("Expiration time until round ends set to "..arg2.." seconds by "..getPlayerName(plr), exports.CITutil:getPlayersInDimension(dimension), 255, 255, 0) 
    elseif (argument == "time") then
        if (isEventRunning) then
            outputChatBox(warningMessages[16], plr, 255, 0, 0)
            return false
        end
        if (not arg2) then
            outputChatBox(warningMessages[14], plr, 255, 0, 0)
            return false
        end
        if (tonumber(arg2) < 3) then
            outputChatBox(warningMessages[15], plr, 255, 0, 0)
            return false
        end
        roundMaxTime = tonumber(arg2) * 60 * 1000
        outputChatBox("- Time until the whole event ends set to "..arg2.." minutes.", plr, 255, 255, 0)
        -- exports.CITtrivia:sendMessage("Time until the whole event ends set to "..arg2.." minutes by "..getPlayerName(plr), exports.CITutil:getPlayersInDimension(dimension), 255, 255, 0)
    elseif (argument == "unload") then
        if (isEventRunning) then
            stopGamemode()
        end 
        if (#loadedGolfHoles == 0) then
            outputChatBox(warningMessages[5], plr, 255, 0, 0)
            return false
        end
        if (#hardcodedObjectsForTiedRound > 0) then
            for i, v in ipairs(hardcodedObjectsForTiedRound) do
                destroyElement(v)
            end        
            -- destroyAllRoadblocks(plr)
            hardcodedObjectsForTiedRound = {}
        end
        loadedGolfHoles = {}
        isEventLoaded = false
        outputChatBox("- Unloaded GOLF BATTLE event", plr, 255, 255, 0)
    elseif (argument == "stop") then
        stopGamemode()    
    end
end

addCommandHandler('golf', commandsHandler)

function launchGamemode()
    if (getPlayersInEvent() == 0) then 
        outputChatBox(warningMessages[13], plr, 255, 0, 0)
        return false
    end
    isEventRunning = true
    setUpNextRound()
    return false
end

function dimensionCheck(i)
    local isInDimension = true
    local player = scoreboard[i][4]
    if (getElementDimension(player) ~= dimension) then
        triggerClientEvent(player, "CITevents.golf.stopGamemode", resourceRoot)
        table.remove(scoreboard, i)
        isInDimension = false
    end
    return isInDimension
end

function setUpPreWinners()
    roundMaxTimer = nil
    table.sort(scoreboard, function(a, b) return a[2] < b[2] end)
    for i, v in ipairs(scoreboard) do
        if (not dimensionCheck(i)) then
            return false
        end
        if (v[6] == #loadedGolfHoles and v[2] == scoreboard[1][2]) then
            winners[#winners + 1] = v
        else
            if (getElementDimension(v[4]) == dimension and killParticipantsSetting == 1 or killParticipantsSetting == 2) then
                local eliminatedPlayer = v
                setElementHealth(eliminatedPlayer[4], -200)
                table.remove(scoreboard, i)
                triggerClientEvent(eliminatedPlayer[4], "CITevents.golf.drawDx", resourceRoot, "eliminatePlayers", { eliminatedPlayer, 4 })
                -- triggerClientEvent(eliminatedPlayer[4], "CITevents.golf.drawDx", resourceRoot, "eliminatePlayers", { eliminatedPlayer, 4 })
            end
        end
    end
    if (#winners > 1) then
        setUpUntieRound(winners)
    else
        pickWinner(winners)
    end
end

function updateScoresOrKillParticipants()
    expirationTimer = nil
    isRoundRunning = false
    triggerClientEvent(playersInEvent, "CITevents.golf.mainHandler", resourceRoot, "display", { false, false, false, false, isRoundRunning })
    table.sort(scoreboard, function(a, b) return a[2] < b[2] end)
    if (#scoreboard > 0 and killParticipantsSetting > 1) then
        if (killParticipantsSetting == 2) then
            local eliminatedPlayer = scoreboard[#scoreboard]
            if (getElementDimension(eliminatedPlayer[4]) == dimension) then
                setElementHealth(eliminatedPlayer[4], -200)
                table.remove(scoreboard, i)
            end
            if (eliminatedPlayer) then
                triggerClientEvent(playersInEvent, "CITevents.golf.drawDx", resourceRoot, "eliminatePlayers", { eliminatedPlayer, killParticipantsSetting })
                -- triggerClientEvent(playersInGolfEvent(true), "CITevents.golf.drawDx", resourceRoot, "eliminatePlayers", { eliminatedPlayer, killParticipantsSetting })
            end
        elseif (killParticipantsSetting == 3) then
            for i, v in ipairs(scoreboard) do
                local key = tostring(v[1])
                if (not playersThatReachedHole[key]) then
                    if (getElementDimension(v[4]) == dimension) then
                        local eliminatedPlayer = v
                        -- setElementHealth(v[4], -200)
                        -- table.remove(scoreboard, i)
                        triggerClientEvent(eliminatedPlayer[4], "CITevents.golf.drawDx", resourceRoot, "eliminatePlayers", { eliminatedPlayer, killParticipantsSetting })
                        -- triggerClientEvent(playersInGolfEvent(true), "CITevents.golf.drawDx", resourceRoot, "eliminatePlayers", { eliminatedPlayer, killParticipantsSetting })
                    end 
                end 
            end
        end
    end
    for i, v in ipairs(scoreboard) do
        if (not dimensionCheck(i)) then
            return false
        end
        local key = tostring(v[1])
        if (not playersThatReachedHole[key]) then
            scoreboard[i][2] = v[2] + 10
        end
    end
    playersThatReachedHole = {}
    playersThatReachedHoleMutated = {}
    playerThatReachedHoleFirst = nil
    getPlayersInEvent()
    setUpNextRound()
    return false
end

function setUpNextRound()
    local activeHole = eventData["activeHole"]
    if (#scoreboard == 0) then
        for i, v in ipairs(playersInEvent) do
            local vehicle = getPedOccupiedVehicle(v)
            setVehicleDamageProof(vehicle, true)
            scoreboard[i] = { getPlayerName(v), 0, getAccountName(getPlayerAccount(v)), v, vehicle, 0 }
            -- FORMATTED AS: { plrName, totalScore, accName, player as value, vehicle, holesReached }
        end
    end
    if (activeHole == 0) then
        if (not deathRun) then
            roundMaxTimer = setTimer(setUpPreWinners, roundMaxTime, 1)
        end
        local spawnPoint = eventData["spawnPoint"]
        local sX, sY, sZ = spawnPoint[1], spawnPoint[2], spawnPoint[3]
        for i, v in ipairs(scoreboard) do
            local vehicle = v[5]
            setElementPosition(vehicle, sX, sY, sZ + 1)
            setElementRotation(vehicle, 0, 0, 0)
            setElementFrozen(vehicle, true)
        end
    else
        eventData["roundsPlayed"] = eventData["roundsPlayed"] + 1
        if (eventData["roundsPlayed"] == #loadedGolfHoles) then
            setUpPreWinners()
            return false
        else
            local currentHole = loadedGolfHoles[activeHole] 
            local chX, chY, chZ = currentHole[2], currentHole[3], currentHole[4]
            if (activeHole == 1) then
                eventData["spawnPoint"] = { loadedGolfHoles[activeHole][2], loadedGolfHoles[activeHole][3], loadedGolfHoles[activeHole][4] + 3 }
            end
            if (activeHole < #loadedGolfHoles) then
                destroyElement(holeMarker)
            end
            for i, v in ipairs(scoreboard) do
                local vehicle = v[5]
                if (activeHole < #loadedGolfHoles) then
                    setElementPosition(vehicle, chX, chY, chZ + 1)
                end
                setElementRotation(vehicle, 0, 0, 0)
                setElementFrozen(vehicle, true)
            end
        end
    end
    local newHole = activeHole + 1
    local nextHole = loadedGolfHoles[newHole]
    local nhX, nhY, nhZ = nextHole[2], nextHole[3], nextHole[4]
    holeMarker = createMarker(nhX, nhY, nhZ, "checkpoint", 3, 167, 4, 242)
    eventData["activeHole"] = newHole
    table.sort(scoreboard, function(a, b) return a[2] < b[2] end)
    if (deathRun) then                       
        expirationTimer = setTimer(updateScoresOrKillParticipants, expirationTime + 8000, 1)
        activeUnnamedTimer = setTimer(function() 
            triggerClientEvent(playersInEvent, "CITevents.golf.drawDx", resourceRoot, "deathRunCountdown", { expirationTime })
            activeUnnamedTimer = nil
            -- triggerClientEvent(playersInGolfEvent(true), "CITevents.golf.drawDx", resourceRoot, "deathRunCountdown", { expirationTime })
        end, 7000, 1)
    end
    isRoundRunning = true
    triggerClientEvent(playersInEvent, "CITevents.golf.mainHandler", resourceRoot, "display", { scoreboard, loadedGolfHoles, eventData, loadedFloorTiles, isRoundRunning, roundMaxTime })
    -- triggerClientEvent(playersInGolfEvent(true), "CITevents.golf.mainHandler", resourceRoot, "display", { scoreboard, loadedGolfHoles, eventData, loadedFloorTiles })
    return false
end

function setUpUntieRound(winnersTable)
    local sX, sY, sZ = coordinates[1][2], coordinates[1][3], coordinates[1][4]
    local holeX, holeY, holeZ = coordinates[15][2], coordinates[15][3], coordinates[15][4]
    if (#hardcodedObjectsForTiedRound == 0) then
        for i, v in ipairs(coordinates) do
            -- createEventObject(plr, v[1], v[2], v[3], v[4], v[5], v[6], v[7], dimension, int, false, false, true, "sh")
            local object = createObject(v[1], v[2], v[3], v[4], v[5], v[6], v[7])
            hardcodedObjectsForTiedRound[i] = object
        end
    end
    for i, v in ipairs(winnersTable) do
        local vehicle = v[5]
        setCameraTarget(v[4])
        setElementPosition(vehicle, sX, sY, sZ + 1)
        setElementRotation(vehicle, 0, 0, 0)
        setElementFrozen(vehicle, true)
    end
    if (holeMarker) then
        destroyElement(holeMarker)
    end
    holeMarker = createMarker(holeX, holeY, holeZ, "checkpoint", 3, 167, 4, 242)
    triggerClientEvent(playersInEvent, "CITevents.golf.drawDx", resourceRoot, "untieRound", { winnersTable, { holeX, holeY, holeZ } })
    -- triggerClientEvent(playersInGolfEvent(true), "CITevents.golf.drawDx", resourceRoot, "untieRound", { winnersTable, { holeX, holeY, holeZ } })
    activeUnnamedTimer = setTimer(calculateDistance, 25000, 1, { holeX, holeY, holeZ })
    return false
end

function pickWinner(table)
    -- if (port ~= 22023) then
        if (#table == 0) then
            outputChatBox("Time is over. Nobody has won this event!", playersInEvent, 255, 139, 0)
            -- outputChatBox("Nobody managed to win this event", exports.CITutil:getPlayersInDimension(dimension), 255, 25, 25)
        elseif (#table == 1) then
            -- outputChatBox("We have a winner: "..table[1]), exports.CITutil:getPlayersInDimension(dimension), 255, 25, 25)
            outputChatBox("We have a winner: "..table[1][1], playersInEvent, 0, 150, 0)
            eventData["winner"] = table[1][1]
        end
        isRoundRunning = false
        triggerClientEvent(playersInEvent, "CITevents.golf.mainHandler", resourceRoot, "display", { table, loadedGolfHoles, eventData, false, isRoundRunning, 0 })
        -- triggerClientEvent(playersInGolfEvent(true), "CITevents.golf.mainHandler", resourceRoot, "display", { table, loadedGolfHoles, eventData })
        if (isEventRunning) then
            stopGamemode()
        end
        return false
    -- end
end

function skipExpirationTimer()
    if (expirationTimer) then
        killTimer(expirationTimer)
        expirationTimer = setTimer(function() 
            triggerClientEvent(playersInEvent, "CITevents.golf.drawDx", resourceRoot, "killExpirationCountdown")
            -- triggerClientEvent(playersInGolfEvent(true), "CITevents.golf.drawDx", resourceRoot, "killExpirationCountdown")
            updateScoresOrKillParticipants()
            expirationTimer = nil
        end, 3000, 1)
        return false
    end
end

function playerReachedHole(player, shots)
    if (not isUntieRound and isRoundRunning) then
        if (not playerThatReachedHoleFirst) then
            playerThatReachedHoleFirst = getPlayerName(player)
            if (not deathRun) then
                expirationTimer = setTimer(updateScoresOrKillParticipants, expirationTime + 3800, 1)
                activeUnnamedTimer = setTimer(function() 
                    triggerClientEvent(playersInEvent, "CITevents.golf.drawDx", resourceRoot, "expirationCountdown", { expirationTime, playerThatReachedHoleFirst, shots })
                    activeUnnamedTimer = nil
                    -- triggerClientEvent(playersInGolfEvent(true), "CITevents.golf.drawDx", resourceRoot, "expirationCountdown", { expirationTime, playerThatReachedHoleFirst, shots })
                end, 3000, 1)
            end
        end
        for i, v in ipairs(scoreboard) do
            if (not dimensionCheck(i)) then
                return false
            end
            if (player == v[4]) then
                scoreboard[i][2] = v[2] + shots 
                scoreboard[i][6] = eventData["activeHole"]
                local key = tostring(v[1])
                playersThatReachedHole[key] = key
                table.insert(playersThatReachedHoleMutated, v[1])
            end
        end
        if (#playersThatReachedHoleMutated == #scoreboard) then
            activeUnnamedTimer = setTimer(function() 
                skipExpirationTimer()
                activeUnnamedTimer = nil
            end, 3500, 1)
        end
    end
end

addEvent("reachedHole", true)
addEventHandler("reachedHole", resourceRoot, playerReachedHole)

function calculateDistance(holeData)
    activeUnnamedTimer = nil
    local lowestDistance = 0
    local lowestDistanceIndex = 0
    local holeX, holeY, holeZ = holeData[1], holeData[2], holeData[3]
    for i, v in ipairs(winners) do
        if (not dimensionCheck(i)) then
            return false
        end
        local x, y, z = getElementPosition(v[5])
        local distance = getDistanceBetweenPoints3D(x, y, z, holeX, holeY, holeZ)
        winners[i][2] = distance
        outputChatBox(""..i..". "..v[1].." ("..math.floor(v[2]).." meters)", playersInEvent, 255, 255, 0)
    end
    table.sort(winners, function(a, b) return a[2] < b[2] end)
    winners = { winners[1] }
    pickWinner(winners)
    return false
end

function stopGamemode()
    if (not isEventRunning) then
        outputChatBox(warningMessages[10], plr, 255, 0, 0)
        return false
    end
    if (activeUnnamedTimer) then
        killTimer(activeUnnamedTimer)
        activeUnnamedTimer = nil
    end        
    if (roundMaxTimer) then
        killTimer(roundMaxTimer)
        roundMaxTimer = nil
    end    
    if (expirationTimer) then
        killTimer(expirationTimer)
        expirationTimer = nil
    end
    triggerClientEvent(playersInEvent, "CITevents.golf.stopGamemode", resourceRoot)
    -- triggerClientEvent(playersInGolfEvent(true), "CITevents.golf.stopGamemode", resourceRoot)
    playerThatReachedHoleFirst = nil
    scoreboard = {}
    playersThatReachedHole = {}
    playersThatReachedHoleMutated = {}
    winners = {}
    eventData = {
        ["activeHole"] = 0,
        ["roundsPlayed"] = 0,
        ["winner"] = nil,
        ["spawnPoint"] = mainSpawnPoint[2]
    }    
    if (holeMarker) then
        destroyElement(holeMarker)
    end
    isEventRunning = false
    outputChatBox(warningMessages[12], plr, 0, 255, 255)
    return false
end

function getPlayersInEvent()
    playersInEvent = {}
    for i, v in ipairs(getElementsByType("player")) do
        if (getElementDimension(v) == dimension) then
            table.insert(playersInEvent, v)
        end
    end
    return tonumber(#playersInEvent)
end

-- function playersInGolfEvent(withCEM)
--     local participantPool = {}
--     local participants = withCEM and getEventParticipantsWithEventManagers() or getEventParticipants()
--     for i, v in pairs(participants) do
--         if (v and isElement(v)) then
--             participantPool[#participantPool + 1] = v
--         end
--     end
--     return participantPool
-- end