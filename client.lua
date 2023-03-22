----------------------------------------->>
-- PURPOSE	: Golf Battle
-- DEVELOPER: Slow
-- FILE	 : golf.lua (client)
----------------------------------------->>

local validGolfBall = 441
local heatbarRange = 240
local CEMcolor = tocolor(167, 4, 242)
local whitecolor = tocolor(255, 255, 255)
local redcolor = tocolor(139, 0, 0)
local scoreboardBg = tocolor(0, 0, 0, 170)
local greencolor = tocolor(0, 152, 0)
local width, height, h_height, r_height, s_width = 200, 300, 30, 20, 15
local screenW, screenH = guiGetScreenSize()
local posX = screenW - (width + 20)
local pressTime, releaseTime = 0, 1
local rotation = 0
local colorInc = 1
local speed = 0
local roundEndsAfter = nil
local multiplier = 2.85
local progress = 0.0
local dimension = 0
local shots = 0
local showEliminationDx = 0
local indexOfPlayerToSpectate = 1
local loadedGolfHoles = {}
local savedPosition = {}
local eventData = {}
local scoreboard = {}
local colors = {
    {255, 255, 255, "white"},
    {0, 128, 0, "green"},
    {154, 205, 54, "yellowgreen"},
    {255, 174, 66, "orange"},
    {255, 69, 0, "orange"},
    {255, 0, 0, "red"},
}
local controls = {
    "handbrake", "accelerate", "change_camera", "brake_reverse", "vehicle_left", "vehicle_right"
}
local playerThatReachedHoleFirst = 'Somebody'
local activeColshape = nil
local playerIndex = nil
local window = nil
local activeUnnamedTimer = nil
local rewarpTimer = nil
local activeSound = nil
local activeCameraDxText = nil
local eliminatedPlayer = nil
local player = nil
local expiration = nil
local veh = nil
local playerIndex = nil
local expirationTimer = nil
local untieRoundEndTime = nil
local winner = nil
local showTip = false
local deathRun = false
local colshapeHandler = false
local isPressing = false
local rewarp = false
local controlsOff = false
local cameraHandler = false
local keysHandler = false
local isDrawDxRunning = false
local showFirstPlayerReachedHoleDx = false
local showUntieRoundDx = false
local color = whitecolor
local canShoot = false
local isScoreboardDrawn = false
local reachedHole = false
local endTime
local userShotInUntieRound = false
local isReady = false
local dxHandlerDrawn = false
local isUntieRound = false
local next = false
local waitingForOpponents = false
local isRoundRunning = false
local isSpectating = false
local roundAboutToStart = false

function holeHit(plr, dim)
    if (not isRoundRunning or isUntieRound) then
        return false
    end
    if (not isElementWithinColShape(plr, activeColshape)) then
        return false
    end
    -- if (not activeColshape) then
    --     return false
    -- end
    if (not roundAboutToStart and localPlayer == plr and isPedInVehicle(plr) and getVehicleModelFromName(getVehicleName(veh)) == validGolfBall and getPedOccupiedVehicleSeat(plr) == 0) then
        activeSound = playSound("sounds/hole.wav")
        if (rewarpTimer) then
            killTimer(rewarpTimer)
            rewarp = false
            rewarpTimer = nil
        end
        reachedHole = true
        setElementFrozen(veh, true)
        local element = loadedGolfHoles[eventData["activeHole"]]
        local x, y, z = element[2], element[3], element[4]
        setElementPosition(veh, x, y, z + 1)
        setElementRotation(veh, 0, 0, 0)
        isSpectating = true
        spectatePlayer()
        triggerServerEvent("reachedHole", root, player, shots)
        return false
    end
end

function spectatePlayer(action)
    if (#scoreboard < 1) then
        return false
    end
    if (action == "left") then
        if (indexOfPlayerToSpectate == 1) then
            indexOfPlayerToSpectate = #scoreboard
        else 
            indexOfPlayerToSpectate = indexOfPlayerToSpectate - 1
        end
    elseif (action == "right") then
        if (indexOfPlayerToSpectate == #scoreboard) then
            indexOfPlayerToSpectate = 1
        else 
            indexOfPlayerToSpectate = indexOfPlayerToSpectate + 1
        end
    elseif (action == "disable") then
        isSpectating = false
        setCameraTarget(localPlayer)
        return
    end
    setCameraTarget(scoreboard[indexOfPlayerToSpectate][4])
end

function clamp(val, lower, upper)
    if (lower > upper) then lower, upper = upper, lower end
    return math.max(lower, math.min(upper, val))
end

function rewarpFunction()
    if (#savedPosition == 0 or isUntieRound or reachedHole) then
        return false
    end
    rewarp = true
    setElementFrozen(veh, true)
    rewarpTimer = setTimer(function() 
        setElementFrozen(veh, false)
        setElementPosition(veh, savedPosition[1], savedPosition[2], savedPosition[3])
        setElementRotation(veh, 0, 0, rotation)
        rewarp = false
        rewarpTimer = nil
    end, 3000, 1)
end

function savePosition(source)
    if (not isElementInWater(veh) and isVehicleWheelOnGround(veh, 0) and isVehicleWheelOnGround(veh, 1) and isVehicleWheelOnGround(veh, 2) and isVehicleWheelOnGround(veh, 3) and speed < 3) then
        local x, y, z = getElementPosition(veh)
        savedPosition = { x, y, z }
        if (source and source == "key") then
            outputChatBox("Position saved successfully.", 0, 150, 0)
        end
    else
        savedPosition = eventData["spawnPoint"]
    end
end

function dxDrawTextOnElement(TheElement, text, height, distance, R, G, B, alpha, size, font,...)
	local x, y, z = getElementPosition(TheElement)
	local x2, y2, z2 = getCameraMatrix()
	local distance = distance or 20
	local height = height or 1
	if (isLineOfSightClear(x, y, z+2, x2, y2, z2, ...)) then
		local sx, sy = getScreenFromWorldPosition(x, y, z+height)
		if (sx) and (sy) then
			local distanceBetweenPoints = getDistanceBetweenPoints3D(x, y, z, x2, y2, z2)
			if(distanceBetweenPoints < distance) then
				dxDrawText(text, sx+2, sy+2, sx, sy, tocolor(R or 255, G or 255, B or 255, alpha or 255), (size or 1)-(distanceBetweenPoints / distance), font or "arial", "center", "center")
			end
		end
	end
end

function drawDxScoreboard()
    if (not isPedInVehicle(localPlayer) or getVehicleModelFromName(getVehicleName(veh)) ~= validGolfBall) then
        return false
    end
    local sX, sY, sZ = getElementVelocity(veh)
    speed = math.sqrt(sX^2 + sY^2 + sZ^2) * 180
    if (speed < 3) then
        canShoot = true
    end
    local c_height = #scoreboard * r_height
    local posY = (screenH/2) - (height/2)
    dxDrawRectangle(posX, posY, width, h_height, tocolor(167, 4, 242, 170))
    dxDrawText('TOP 10', posX, posY, posX + width - 10, posY + h_height, whitecolor, 1, "default-bold", "center", "center")
    dxDrawRectangle(posX, posY + 30, width, 270, scoreboardBg)
    if (not userShotInUntieRound) then
        dxDrawImage(posX - 50, posY + 30, 30, 270, "heatbar.png", 0, 0, 0)
        dxDrawImage(posX - 112, posY + 30 + heatbarRange, 60, 30, "arrow.png", 0, 0, 0)
    end
    if (not controlsOff) then
        for i, v in pairs(controls) do
            toggleControl(v, false)
        end
        controlsOff = true
    end
    if (not isSpectating and isReady and canShoot and getKeyState("mouse1") and speed < 3) then
        if (not userShotInUntieRound) then
            if (heatbarRange > 0 and heatbarRange <= 270) then
                heatbarRange = heatbarRange - 2
            end
        end
    end
    local offsetY = 30
    local value = shots
    for i, v in ipairs(scoreboard) do
        setElementCollidableWith(v[5], veh, false)
        if (isUntieRound) then
            value = math.floor(v[2])
        else
            if (player == v[4]) then
                value = shots + v[2]
            end
        end
        if (i <= 10) then
            offsetY = offsetY * 2
            dxDrawText(""..i..".  "..v[1].."", posX + 15, posY + h_height + offsetY, posX + 30 + width, height, whitecolor, 1, "default-bold", "left", "center")
            dxDrawText(math.floor(v[2]), posX + ( width - 20 ), posY + h_height + offsetY, posX + ( width - 10 ), height, whitecolor, 1, "default-bold", "left", "center")
        end
    end
    if (isReady and isRoundRunning) then
        if (isUntieRound) then
            if (winner) then
                dxDrawTextOnElement(veh, value, 0.5, 20, 255, 255, 255, 255, 2.5, "pricedown")
            end
        else 
            dxDrawTextOnElement(veh, value, 0.5, 20, 255, 255, 255, 255, 2.5, "pricedown")
        end
    end
    if (isElementInWater(veh)) then
        rewarpFunction()
    end
    if (winner) then
        if (getPlayerName(localPlayer) == winner) then
            dxDrawText("You have won!", 0, 0, screenW, screenH / 2.85, greencolor, 1.7, 1.7, "pricedown", "center", "center")
        else
            dxDrawText(""..winner.." has won the event!", 0, 0, screenW, screenH / 2.85, greencolor, 1.7, 1.7, "pricedown", "center", "center")
        end
    end
    if (not isUntieRound and roundEndsAfter and not deathRun and isReady and not isUntieRound and not waitingForOpponents and not isSpectating) then
        dxDrawRectangle(screenW/2 - 680/2, screenH - (screenH/3), 680, h_height, scoreboardBg)
        local countdownOnScreen = math.floor((roundEndsAfter - getTickCount()) / 1000)
        dxDrawText('Use your mouse to boost your vehicle and reach the hole #a704f2(PURPLE CHECKPOINT). #FFFFFFEvent ends in '..countdownOnScreen..' seconds!', (screenW/2) + 15, screenH - (screenH/3) + 15, (screenW/2) + 15, screenH - (screenH/3) + 15, whitecolor, 1, "default-bold", "center", "center", false, false, false, true)
    end 
    if (isSpectating) then
        dxDrawRectangle(screenW/2 - 540/2, screenH - (screenH/3), 540, h_height, scoreboardBg)
        dxDrawText('Use #A704F2ARROW LEFT#FFFFFF or #A704F2ARROW RIGHT#FFFFFF to spectate your opponents', (screenW/2) + 15, screenH - (screenH/3) + 15, (screenW/2) + 15, screenH - (screenH/3) + 15, whitecolor, 1, "default-bold", "center", "center", false, false, false, true)
    end
    if (activeCameraDxText) then
        dxDrawText(activeCameraDxText, 0, 0, screenW, screenH / 2.85, CEMcolor, 2.2, 2.2, "pricedown", "center", "center")
        dxDrawText("Hole #"..eventData["activeHole"].."", 0, 0, screenW, screenH / 2, whitecolor, 1.5, 1.5, "pricedown", "center", "center")    
    end
    if (rewarp) then
        dxDrawText("Rewarping to previous position...",  0, 0, screenW, screenH / 1.7, whitecolor, 1.3, 1.3, "pricedown", "center", "center")
    end
    if (reachedHole) then
        dxDrawText("Hole in "..shots.."!", 0, 0, screenW, screenH / 1.25, CEMcolor, 2.2, 2.2, "pricedown", "center", "center")
        waitingForOpponents = true
        activeUnnamedTimer = setTimer(function() 
            reachedHole = false 
            activeUnnamedTimer = nil
        end, 3500, 1)
    end
    if (not rewarp and #savedPosition > 0 and not isSpectating and not waitingForOpponents and not isUntieRound) then
        dxDrawText("Press #a704f2LSHIFT#ffffff to warp to spawn point", posX, posY + 370, posX + width - 10, posY + 270 + h_height, whitecolor, 1, "default-bold", "center", "center", false, false, false, true)    
        dxDrawText("Press #a704f2ARROW DOWN#ffffff to save position", posX, posY + 400, posX + width - 10, posY + 270 + h_height, whitecolor, 1, "default-bold", "center", "center", false, false, false, true)    
    end
    if (not isUntieRound and roundEndsAfter and not deathRun and waitingForOpponents or isSpectating) then
        dxDrawText("Event ends in "..math.floor((roundEndsAfter - getTickCount()) / 1000).." seconds!", posX, posY + 430, posX + width - 10, posY + 270 + h_height, whitecolor, 1, "default-bold", "center", "center", false, false, false, true)    
    end
    dxDrawText("Press #a704f2ARROW DOWN#ffffff to save position", posX, posY + 400, posX + width - 10, posY + 270 + h_height, whitecolor, 1, "default-bold", "center", "center", false, false, false, true)    
    if (not reachedHole and isReady) then
        dxDrawText("Hole: "..eventData["activeHole"].."/"..#loadedGolfHoles.." | Shots: "..shots.." | Position: "..playerIndex.."/"..#scoreboard.."", posX, posY + 330, posX + width - 10, posY + 270 + h_height, whitecolor, 1, "default-bold", "center", "center")    
    end
    if (not isElementInWater(localPlayer) and speed < 3 and canShoot and isReady and isRoundRunning and showEliminationDx == 0 and not rewarp and not waitingForOpponents) then
        if (userShotInUntieRound) then
            return false
        end
        if (heatbarRange == 250 or heatbarRange == 230 or heatbarRange == 200 or heatbarRange == 170 or heatbarRange == 140 or heatbarRange == 80) then
            if (colorInc == #colors) then
                return false
            end
            colorInc = colorInc + 1
        end
        color = tocolor(colors[colorInc][1], colors[colorInc][2], colors[colorInc][3])
        if (pressTime > 0) then
            dxDrawText("Release to shoot!", 0, 0, screenW, screenH / 1.6, color, 1.1, 1.1, "pricedown", "center", "center")    
        else
            dxDrawText("Left click to load boost!", 0, 0, screenW, screenH / 1.6, CEMcolor, 1.1, 1.1, "pricedown", "center", "center")    
        end
        local circleX, circleY, circleZ = getElementPosition(veh)
        local circleZ = circleZ
        local startAngle = clamp(0, 0, 360)
        local radius, circleWidth, angleAmount = 1, 0.15, 0.09
        local endAngle = clamp(360, 0, 360)
        for i = startAngle, endAngle, angleAmount do
            local _i = i * (math.pi/180)
            dxDrawLine3D(math.cos(_i) * (radius - circleWidth) + circleX, math.sin(_i) * (radius - circleWidth) + circleY, circleZ, math.cos(_i) * (radius + circleWidth) + circleX, math.sin(_i) * (radius + circleWidth) + circleY, circleZ, color, circleWidth, false)
        end
    end
end

function removeHandler(fn, plr)
    if (fn == 'animateCamera') then
        removeEventHandler("onClientRender", root, animateCamera)
        activeCameraDxText = nil
        activeUnnamedTimer = nil
        isReady = true
    elseif (fn == "drawDxScoreboard") then
        removeEventHandler("onClientRender", root, drawDxScoreboard)
        isScoreboardDrawn = false
    elseif (fn == "drawDx") then
        removeEventHandler("onClientRender", root, drawDx)
        dxHandlerDrawn = false
    elseif (fn == "handleKeyPress") then
        removeEventHandler("onClientKey", root, handleKeyPress)
        keysHandler = false    
    elseif (fn == "cameraMovement") then
        removeEventHandler("onClientCursorMove", root, cameraMovement)
        cameraHandler = false    
    elseif (fn == "holeHit") then
        removeEventHandler("onClientColShapeHit", activeColshape, holeHit)
        colshapeHandler = false
    elseif (fn == "all") then
        removeEventHandler("onClientRender", root, drawDx)
        removeEventHandler("onClientKey", root, handleKeyPress)
        removeEventHandler("onClientRender", root, animateCamera)
        removeEventHandler("onClientRender", root, drawDxScoreboard)
        removeEventHandler("onClientCursorMove", root, cameraMovement)
        removeEventHandler("onClientColShapeHit", activeColshape, holeHit)
        cameraHandler = false
        isScoreboardDrawn = false
        dxHandlerDrawn = false
        keysHandler = false
        colshapeHandler = false
    end
end

function findRotation(x1, y1, x2, y2) 
    local t = -math.deg(math.atan2(x2 - x1, y2 - y1))
    return t < 0 and t + 360 or t
end

function animateCamera()
    if (not next or showEliminationDx > 0) then
        return false
    end
    activeCameraDxText = "Ready!"
    if (progress < 1) then 
        progress = progress + 0.01
    end
    local element = loadedGolfHoles[eventData["activeHole"]]
    local x, y, z = element[2], element[3], element[4]
    setCameraMatrix(x, y, z + 15, x, y, z)
    local pX, pY, pZ = getElementPosition(player)
    local iX, iY, iZ = interpolateBetween(x, y, z + 20, pX, pY, pZ, progress, "InBack")
    setCameraMatrix(iX - 5, iY - 8, iZ + 5)
    if (progress >= 1) then
        activeUnnamedTimer = setTimer(function() 
            setElementFrozen(veh, false)
            spectatePlayer("disable")
            activeCameraDxText = "Go!"
            activeSound = playSound("sounds/effect2.wav")
            next = false
            isRoundRunning = true
            activeUnnamedTimer = nil
            activeUnnamedTimer = setTimer(removeHandler, 1800, 1, 'animateCamera', player)
        end, 1000, 1) 
    end
end

function handleKeyPress(button, pressed)
    if (not isRoundRunning or not isReady or userShotInUntieRound) then
        return false
    end
    if (speed < 3 and button == "mouse1" and pressed and not isSpectating and isRoundRunning) then
        canShoot = true
        pressTime = getTickCount()
        heatbarRange = 240
        colorInc = 1
        savePosition()
        return false
    elseif (not isUntieRound and speed < 3 and button == "arrow_d" and pressed and not isSpectating and not isElementInWater(localPlayer)  and isRoundRunning) then
        savePosition('key')
        return false
    elseif (speed < 3 and button == "mouse1" and not pressed and not isSpectating and not isElementInWater(localPlayer) and isRoundRunning) then
        if (isUntieRound) then
            userShotInUntieRound = true
        end
        shots = shots + 1
        heatbarRange = 240
        colorInc = 1
        releaseTime = getTickCount()
        local interval = (math.ceil(math.abs(releaseTime - pressTime)/1000))
        local velocity = multiplier/interval or 1
        local mx, my, mz, mpx, mpy, mpz = getCameraMatrix() 
        local dist = getDistanceBetweenPoints3D(mx, my, mz, mpx, mpy, mpz)
        local vector = { 
            (mx - mpx) / (dist * velocity), 
            (my - mpy) / (dist * velocity), 
            (mz - mpz) / (dist * velocity) 
        } 
        setElementVelocity(veh, -vector[1], -vector[2], -vector[3])
        canShoot = false
        activeSound = playSound("sounds/hiteffect.wav")
        pressTime = 0
        releaseTime = 1
        return false
    elseif (not isUntieRound and button == "lshift" and pressed and isRoundRunning and not reachedHole and not rewarp and not isSpectating) then
        savedPosition = eventData["spawnPoint"]
        rewarpFunction()
        return false
    elseif (not isUntieRound and button == "arrow_l" and pressed and isSpectating) then
        spectatePlayer('left')
        return false
    elseif (not isUntieRound and button == "arrow_r" and pressed and isSpectating) then
        spectatePlayer('right')
        return false
    end
end

function cameraMovement(cX, cY, aX, aY, wX, wY, wZ)
    if (not isRoundRunning or waitingForOpponents or not isReady and not rewarp) then
        return false
    end
    setCameraViewMode(3)
    if (not veh or speed > 0) then
        return false
    end
    local pX, pY, pZ = getElementPosition(player)
    rotation = findRotation(pX, pY, wX, wY)
    setElementRotation(veh, 0, 0, rotation)
    return false
end

function dimensionCheck()
    local isInDimension = true
    if (getElementDimension(localPlayer) ~= dimension) then
        triggerEvent("CITevents.golf.stopGamemode", root)        
        isInDimension = false
		return isInDimension
	end
end

function mainHandler(type, table)
    if (not dimensionCheck()) then
        return false
    end
    if (type == "display") then
        if (table[5] == false) then
            isRoundRunning = false
            return false
        else
            roundAboutToStart = true
        end
        spectatePlayer("disable")
        scoreboard = table[1]
        loadedGolfHoles = table[2]
        eventData = table[3]
        if (not roundEndsAfter and table[6] > 0) then
            roundEndsAfter = getTickCount() + table[6]
        end
        winner = eventData["winner"]
        shots = 0
        waitingForOpponents = false
        if (isUntieRound or eventData["roundsPlayed"] == #loadedGolfHoles) then
            return false
        end
        savedPosition = eventData["spawnPoint"]
        isUntieRound = false
        for i, v in ipairs(scoreboard) do
            if (getPlayerName(localPlayer) == v[1]) then
                player = v[4]
                veh = v[5]
                playerIndex = i
                setElementFrozen(veh, true)
            end
        end
        activeColshape = loadedGolfHoles[eventData["activeHole"]][5]
        isReady = false
        if (eventData["activeHole"] == 1) then
            showTip = true
            activeUnnamedTimer = setTimer(function()
                showTip = false 
                activeUnnamedTimer = nil
            end, 7000, 1)
        end
        fadeCamera(false, 0.3, 0, 0, 0)
        activeUnnamedTimer = setTimer(function() 
            fadeCamera(true, 0.2)
            next = true
            activeUnnamedTimer = nil
            roundAboutToStart = false
        end, 1000, 1)
        activeSound = playSound("sounds/effect1.wav")
        progress = 0.0
        addEventHandler("onClientRender", root, animateCamera)
        if (not cameraHandler) then
            addEventHandler("onClientCursorMove", root, cameraMovement)
            cameraHandler = true
        end
        if (not isScoreboardDrawn) then
            addEventHandler("onClientRender", root, drawDxScoreboard)
            isScoreboardDrawn = true
        end
        if (not keysHandler) then
            addEventHandler("onClientKey", root, handleKeyPress)
            keysHandler = true
        end        
        removeHandler("holeHit")
        addEventHandler("onClientColShapeHit", activeColshape, holeHit)
        colshapeHandler = true
    end
end

addEvent('CITevents.golf.mainHandler', true)
addEventHandler('CITevents.golf.mainHandler', root, mainHandler)

function pickTiedWinner()
    showUntieRoundDx = false
    activeUnnamedTimer = nil
    activeSound = playSound("sounds/effect2.wav")
    untieRoundEndTime = getTickCount() + 20000
    activeUnnamedTimer = setTimer(function() 
        setElementFrozen(veh, true)
        untieRoundEndTime = nil
        dxHandlerDrawn = false
        activeUnnamedTimer = nil
        removeHandler("drawDx")
    end, 20000, 1)
end

function drawDx()
    if (showFirstPlayerReachedHoleDx) then
        dxDrawText(""..playerThatReachedHoleFirst.." reached hole #"..eventData["activeHole"].."!", 0, 0, screenW, screenH / 2.85, CEMcolor, 1.5, 1.5, "pricedown", "center", "center")
    end
    if (expirationTimer) then
        local countdownOnScreen = math.floor((endTime - getTickCount()) / 1000)
        dxDrawText(countdownOnScreen, 0, 0, screenW, screenH / 2.2, whitecolor, 1.5, 1.5, "pricedown", "center", "center")    
    end
    if (showEliminationDx == 2) then
        if (localPlayer == eliminatedPlayer[4]) then
            dxDrawText("You have been eliminated!", 0, 0, screenW, screenH / 2.85, redcolor, 1.3, 1.3, "pricedown", "center", "center")
        else
            dxDrawText(""..eliminatedPlayer[1].." has been eliminated!", 0, 0, screenW, screenH / 2.85, redcolor, 1.3, 1.3, "pricedown", "center", "center")
        end
    elseif (showEliminationDx == 3) then
        if (localPlayer == eliminatedPlayer[4]) then
            dxDrawText("You have been eliminated!", 0, 0, screenW, screenH / 2.85, redcolor, 1.3, 1.3, "pricedown", "center", "center")
        end
    elseif (showEliminationDx == 4) then
        dxDrawText("You have been eliminated!", 0, 0, screenW, screenH / 2.85, redcolor, 1.3, 1.3, "pricedown", "center", "center")
    end    
    if (showUntieRoundDx) then
        dxDrawText("Shootout for 1st place!", 0, 0, screenW, screenH / 2.85, CEMcolor, 2.2, 2.2, "pricedown", "center", "center")
    end     
    if (isUntieRound) then
        if (not userShotInUntieRound) then
            dxDrawRectangle(screenW/2 - 540/2, screenH - (screenH/3), 540, h_height, scoreboardBg)
            dxDrawText('Closest to the flag wins. You got 20 seconds to shoot!', (screenW/2) + 15, screenH - (screenH/3) + 15, (screenW/2) + 15, screenH - (screenH/3) + 15, whitecolor, 1, "default-bold", "center", "center", false, false, false, true)
        elseif (userShotInUntieRound and speed < 3) then
            dxDrawRectangle(screenW/2 - 540/2, screenH - (screenH/3), 540, h_height, scoreboardBg)
            dxDrawText('Waiting for opponents and countdown to end...', (screenW/2) + 15, screenH - (screenH/3) + 15, (screenW/2) + 15, screenH - (screenH/3) + 15, whitecolor, 1, "default-bold", "center", "center", false, false, false, true)
        end
    end     
    if (deathRun and isReady and not showTip and not waitingForOpponents and not isSpectating) then
        dxDrawRectangle(screenW/2 - 540/2, screenH - (screenH/3), 540, h_height, scoreboardBg)
        dxDrawText('DEATH RUN: Reach #a704f2HOLE '..eventData["activeHole"].." #FFFFFFbefore the countdown ends or you will be killed!", (screenW/2) + 15, screenH - (screenH/3) + 15, (screenW/2) + 15, screenH - (screenH/3) + 15, whitecolor, 1, "default-bold", "center", "center", false, false, false, true)
    end 
    if (untieRoundEndTime) then
        local countdownOnScreen = math.floor((untieRoundEndTime - getTickCount()) / 1000)
        if (countdownOnScreen <= 10) then
            dxDrawText("Hurry up!", 0, 0, screenW, screenH / 2.85, redcolor, 1.9, 1.9, "pricedown", "center", "center")
        end
        dxDrawText(countdownOnScreen, 0, 0, screenW, screenH / 2.2, whitecolor, 1.5, 1.5, "pricedown", "center", "center")    
    end   
end

function drawAlternativeDx(type, table)
    if (type == "eliminatePlayers") then
        showEliminationDx = table[2]
        eliminatedPlayer = table[1]
        if (localPlayer == eliminatedPlayer[4]) then
            if (showEliminationDx == 2) then
                outputChatBox("You have been eliminated for holding the last position!", 255, 0, 0, true)
            elseif (showEliminationDx == 3) then
                outputChatBox("You have been eliminated for not reaching the hole on time!", 255, 0, 0, true)  
            elseif (showEliminationDx == 4) then
                outputChatBox("You have been eliminated for not having enough score!", 255, 0, 0, true)
            end
            triggerEvent ( "CITevents.golf.stopGamemode", root)        
        end
        activeUnnamedTimer = setTimer(function() 
            showEliminationDx = 0
            dxHandlerDrawn = false
            activeUnnamedTimer = nil
            removeHandler("drawDx")
        end, 4000, 1)
    elseif (type == "expirationCountdown") then
        showFirstPlayerReachedHoleDx = true
        playerThatReachedHoleFirst = table[2]
        playerThatReachedHoleFirstShots = table[3]
        expiration = table[1]
        if (not reachedHole) then
            outputChatBox("#FFFFFF"..playerThatReachedHoleFirst.."#FF0000 reached hole #"..eventData["activeHole"].." in #FFFFFF"..playerThatReachedHoleFirstShots.." #FF0000shots. Reach the hole before the countdown ends or 10 shots will be added to your count!", 255, 0, 0, true)
        else
            outputChatBox("You have reached hole "..eventData["activeHole"].." in #FFFFFF"..playerThatReachedHoleFirstShots.." shots. #009800Wait for your opponents to arrive!", 0, 152, 0, true)
        end
        endTime = getTickCount() + expiration
        expirationTimer = setTimer(function() 
            expiration = nil
            expirationTimer = nil
            showFirstPlayerReachedHoleDx = false
            dxHandlerDrawn = false
            removeHandler("drawDx")
        end, expiration, 1)    
    elseif (type == "deathRunCountdown") then
        expiration = table[1]
        deathRun = true
        endTime = getTickCount() + expiration
        expirationTimer = setTimer(function() 
            expiration = nil
            expirationTimer = nil
            dxHandlerDrawn = false
            removeHandler("drawDx")
            deathRun = false
        end, expiration, 1)
    elseif (type == "killExpirationCountdown") then
        if (expirationTimer) then
            killTimer(expirationTimer)
            expiration = nil
            expirationTimer = nil
            showFirstPlayerReachedHoleDx = false
            dxHandlerDrawn = false
            removeHandler("drawDx")
        end
    elseif (type == "untieRound") then
        spectatePlayer("disable")
        showEliminationDx = 0
        holeData = table[2]
        scoreboard = table[1]
        showUntieRoundDx = true
        isUntieRound = true
        waitingForOpponents = false
        shots = 0
        rewarp = false
        setElementFrozen(veh, false)
        activeUnnamedTimer = setTimer(pickTiedWinner, 5000, 1)
        isReady = true
        isRoundRunning = true
        outputChatBox("#FF0000TIED ROUND:#FFFFFF Closest to the flag wins!", 255, 0, 0, true)
    end
    if (not dxHandlerDrawn) then
        addEventHandler("onClientRender", root, drawDx)
        dxHandlerDrawn = true
    end
end

addEvent('CITevents.golf.drawDx', true)
addEventHandler('CITevents.golf.drawDx', root, drawAlternativeDx)

function stopGamemode()
    for i, v in pairs(controls) do
        toggleControl(v, true)
    end
    if (activeUnnamedTimer) then
        killTimer(activeUnnamedTimer)
        activeUnnamedTimer = nil
    end    
    untieRoundEndTime = nil
    controlsOff = false
    isReady = false
    roundEndsAfter = nil
    isUntieRound = false
    isRoundRunning = false
    userShotInUntieRound = false
    canShoot = false
    reachedHole = false
    next = false
    winner = nil
    spectatePlayer('disable')
    setElementFrozen(veh, false)
    removeHandler("all")
end

addEvent('CITevents.golf.stopGamemode', true)
addEventHandler('CITevents.golf.stopGamemode', root, stopGamemode)