-- PhrozenByte Stunt Drag Markers (SDM)
--
-- Copyright (C) 2015-2016  Daniel Rudolf <http://www.daniel-rudolf.de/>
--
-- This program is free software: you can redistribute it and/or modify it
-- under the terms of the GNU Affero General Public License as published
-- by the Free Software Foundation, version 3 of the License only.
--
-- This program is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
-- GNU Affero General Public License for more details.
--
-- You should have received a copy of the GNU Affero General Public License
-- along with this program.  If not, see <http://www.gnu.org/licenses/>.

-- global table containing all SDMs
stuntDragMarkers = {}

-- import phrozenbyte-debug as debug
-- editor mode doesn't start this resource automatically, we've to deal with it on our own
debug, debugResourceName = nil, "phrozenbyte-debug"
addEventHandler("onResourceStart", root, function (res) if (getResourceName(res) == debugResourceName) then debug = exports[debugResourceName] end end)

--
-- server mode
--
addEventHandler("onResourceStart", resourceRoot,
    function ()
        -- don't do anything when the editor is running
        -- the editor starts this using the EDF scriptreader (see onStart() function below)
        local editorResource = getResourceFromName("editor")
        if ((not editorResource) or (getResourceState(editorResource) ~= "running")) then
            -- import debug resource
            debug = exports[debugResourceName]

            debug:notice("onResourceStart(stunt-drag-markers)")
            setElementData(root, "sdmEditorMode", "false")
            setElementData(root, "sdmEditorTestMode", "false")

            -- init stunt drag markers when a map is running
            -- otherwise this will be triggered through onGamemodeMapStart
            local currentMap = exports["mapmanager"]:getRunningGamemodeMap()
            if (currentMap) then
                initStuntDragMarkers(currentMap)
            end

            -- reload on map changes
            addEvent("onGamemodeMapStart")
            addEventHandler("onGamemodeMapStart", root,
                function (startedMap)
                    debug:notice("onGamemodeMapStart(" .. getResourceName(startedMap) .. ")")
                    initStuntDragMarkers(startedMap)
                end
            )

            addEvent("onGamemodeMapStop")
            addEventHandler("onGamemodeMapStop", root,
                function (stoppedMap)
                    -- bug workaround: :race/race_server.lua (lines 40 and 844)
                    -- triggers this event without the stoppedMap argument
                    if (not stoppedMap) then
                        stoppedMap = exports["mapmanager"]:getRunningGamemodeMap()
                    end

                    debug:notice("onGamemodeMapStop(" .. (stoppedMap and getResourceName(stoppedMap) or "") .. ")")
                    cleanupStuntDragMarkers()
                end
            )

            -- cleanup on shutdown
            addEventHandler("onResourceStop", resourceRoot,
                function ()
                    debug:notice("onResourceStop(stunt-drag-markers)")

                    -- cleanup stunt drag markers
                    cleanupStuntDragMarkers()
                end
            )
        end
    end
)

--
-- editor mode
--
function onStart()
    outputDebugString("edfScriptReader.onStart(stunt-drag-markers)", 3)
    setElementData(root, "sdmEditorMode", "true")
    setElementData(root, "sdmEditorTestMode", "false")

    -- start required phrozenbyte-debug resource
    local debugResource = getResourceFromName(debugResourceName)
    if (not debugResource) then
        outputDebugString("edfScriptReader: Unable to load resource 'stunt-drag-markers': Required resource '" .. debugResourceName .. "' not found", 1)
        return false
    end

    -- proceed with onEditorDependenciesReady() after we've started the phrozenbyte-debug resource
    local debugResourceState = getResourceState(debugResource)
    if (debugResourceState == "running") then
        -- import debug resource
        debug = exports[debugResourceName]

        onEditorDependenciesReady(debugResource)
    else
        -- no need to import the debug resource during onEditorDependenciesReady,
        -- there's a distinct event handler for that
        outputDebugString("edfScriptReader.startResource(" .. debugResourceName .. ")", 3)
        addEventHandler("onResourceStart", root, onEditorDependenciesReady, true, "normal-10")

        if (debugResourceState ~= "starting") then
            if (not startResource(debugResource)) then
                outputDebugString("edfScriptReader: Unable to load resource 'stunt-drag-markers': Unable to start required resource '" .. debugResourceName .. "'", 1)
                return false
            end
        end
    end

    -- make SDM markers rotateable
    addEventHandler("onMapOpened", root,
        function ()
            local rootElement = getResourceRootElement(getResourceFromName("editor_main"))
            for sdmType,_ in pairs(stuntDragMarkerDefinitions) do
                local elementType = "sdm" .. string.upper(string.sub(sdmType, 1, 1)) .. string.sub(sdmType, 2)
                local elements = getElementsByType(elementType, rootElement)
                for _,element in ipairs(elements) do
                    onEditorStuntDragMarkerUpdate(element)
                end
            end
        end
    )
    addEventHandler("onElementPropertyChanged", root,
        function (propertyName)
            if ((propertyName == "rotation") or (propertyName == "position")) then
                if (string.sub(getElementType(source), 1, 3) == "sdm") then
                    onEditorStuntDragMarkerUpdate(source)
                end
            end
        end
    )

    return true
end

function onStop()
    debug:notice("edfScriptReader.onStop(stunt-drag-markers)")

    -- we must remove the above onResourceStart() event handlers on our own
    removeEventHandler("onResourceStart", root, onEditorDependenciesReady)
    removeEventHandler("onResourceStart", root, onEditorTestResourceStart)
end

function onEditorDependenciesReady(startedResource)
    if (getResourceName(startedResource) == debugResourceName) then
        debug:notice("onResourceStart(" .. getResourceName(startedResource) .. ")", 3)

        -- don't call this function multiple times
        removeEventHandler("onResourceStart", root, onEditorDependenciesReady)

        -- wait for onResourceStart(editor_test)
        -- we can't bind the event handler directly to the editor_test resource,
        -- because the resource is destroyed and re-created on every test
        addEventHandler("onResourceStart", root, onEditorTestResourceStart)

        local editorTestResource = getResourceFromName("editor_test")
        if (editorTestResource and (getResourceState(editorTestResource) == "running")) then
            onEditorTestResourceStart(editorTestResource)
        end
    end
end

function onEditorTestResourceStart(startedResource)
    if (getResourceName(startedResource) == "editor_test") then
        debug:notice("onResourceStart(editor_test)")
        setElementData(root, "sdmEditorTestMode", "true")

        -- init stunt drag markers
        initStuntDragMarkers(startedResource)

        -- cleanup SDMs after testing
        -- this event handler is destroyed automatically by the editor after testing
        addEventHandler("onResourceStop", getResourceRootElement(startedResource),
            function ()
                debug:notice("onResourceStop(editor_test)")
                debug:dump(stuntDragMarkers, "stuntDragMarkers")
                setElementData(root, "sdmEditorTestMode", "false")
                cleanupStuntDragMarkers()
            end
        )
    end
end

function onEditorStuntDragMarkerUpdate(marker)
    if (
        (edfGetElementProperty(marker, "type") == "ring")
        or ((getElementType(marker) == "sdmTeleportTarget") and (edfGetElementProperty(marker, "type") == "checkpoint"))
    ) then
        -- ignore rotation on Y axis, the marker acts mirror-inverted otherwise
        local markerPosition = Vector3(exports["edf"]:edfGetElementPosition(marker))
        local markerRotation = Vector3(exports["edf"]:edfGetElementRotation(marker))
        local markerMatrix = Matrix(markerPosition, Vector3(markerRotation.x, 0, markerRotation.z))

        local markerTarget = markerPosition + markerMatrix.forward
        setMarkerTarget(marker, markerTarget.x, markerTarget.y, markerTarget.z)
    end
end

function isEditorMode() return (getElementData(root, "sdmEditorMode", false) == "true") end
function isEditorTestMode() return (getElementData(root, "sdmEditorTestMode", false) == "true") end

--
-- init SDMs
--
function initStuntDragMarkers(mapResource)
    if (not mapResource) then
        debug:error("Bad argument @ 'initStuntDragMarkers' [Expected resource at argument 1, got nil]")
        return
    end

    debug:notice("initStuntDragMarkers(" .. getResourceName(mapResource) .. ")")

    -- parse SDM map settings
    parseStuntDragMarkerMapSettings(mapResource)

    -- parse SDM map elements
    parseStuntDragMarkers(mapResource)
end

--
-- cleanup SDMs
--
function cleanupStuntDragMarkers()
    debug:notice("cleanupStuntDragMarkers()")

    -- destroy SDM elements
    for _,markersByType in pairs(stuntDragMarkers) do
        for _,sdmMarker in ipairs(markersByType) do
            local marker = getElementData(sdmMarker, "orig", false)
            removeElementData(marker, "marker")

            destroyElement(sdmMarker)
        end
    end

    stuntDragMarkers = {}
end

--
-- parse SDM map settings
--
function parseStuntDragMarkerMapSettings(mapResource)
    debug:notice("parseStuntDragMarkerMapSettings(" .. getResourceName(mapResource) .. ")")
    local settingsPrefix = getResourceName(mapResource) .. "."

    local gravity = tonumber(get(settingsPrefix .. "gravity"))
    applyGravityMapSetting(gravity)

    local skyTopColor = get(settingsPrefix .. "skyTopColor")
    local skyBottomColor = get(settingsPrefix .. "skyBottomColor")
    applySkyMapSetting(skyTopColor, skyBottomColor)

    local waterColor = get(settingsPrefix .. "waterColor")
    applyWaterMapSetting(waterColor)
end

--
-- gravity map setting [exported function]
--
function applyGravityMapSetting(gravity)
    if (gravity) then
        debug:notice("setGravity(" .. gravity .. ")")
        setGravity(gravity)
    end
end

--
-- sky map setting [exported function]
--
function applySkyMapSetting(skyTopColor, skyBottomColor)
    if (skyTopColor and (skyTopColor ~= "#00000000") and skyBottomColor and (skyBottomColor ~= "#00000000")) then
        local validSkyColors = true

        local skyTopRed, skyTopGreen, skyTopBlue, skyTopAlpha = getColorFromString(skyTopColor)
        if ((not skyTopRed) or (not skyTopGreen) or (not skyTopBlue) or (not skyTopAlpha)) then
            validSkyColors = false
        elseif (skyTopAlpha < 255) then
            skyTopRed = ((255 - skyTopRed) * (skyTopAlpha / 255) + skyTopRed)
            skyTopGreen = ((255 - skyTopGreen) * (skyTopAlpha / 255) + skyTopGreen)
            skyTopBlue = ((255 - skyTopBlue) * (skyTopAlpha / 255) + skyTopBlue)
        end

        local skyBottomRed, skyBottomGreen, skyBottomBlue, skyBottomAlpha = getColorFromString(skyBottomColor)
        if ((not skyBottomRed) or (not skyBottomGreen) or (not skyBottomBlue) or (not skyBottomAlpha)) then
            validSkyColors = false
        elseif (skyBottomAlpha < 255) then
            skyBottomRed = ((255 - skyBottomRed) * (skyBottomAlpha / 255) + skyBottomRed)
            skyBottomGreen = ((255 - skyBottomGreen) * (skyBottomAlpha / 255) + skyBottomGreen)
            skyBottomBlue = ((255 - skyBottomBlue) * (skyBottomAlpha / 255) + skyBottomBlue)
        end

        if (validSkyColors) then
            debug:notice("setSkyGradient(" .. skyTopColor .. ", " .. skyBottomColor .. ")")
            setSkyGradient(skyTopRed, skyTopGreen, skyTopBlue, skyBottomRed, skyBottomGreen, skyBottomBlue)
        end
    end
end

--
-- water map setting [exported function]
--
function applyWaterMapSetting(waterColor)
    if (waterColor and (waterColor ~= "#00000000")) then
        local waterRed, waterGreen, waterBlue, waterAlpha = getColorFromString(waterColor)
        if (waterRed and waterGreen and waterBlue and waterAlpha) then
            debug:notice("setWaterColor(" .. waterColor .. ")")
            setWaterColor(waterRed, waterGreen, waterBlue, waterAlpha)
        end
    end
end

--
-- parse SDM elements in the map
--
function parseStuntDragMarkers(mapResource)
    debug:notice("parseStuntDragMarkers(" .. getResourceName(mapResource) .. ")")

    -- create markers
    local initMarkers = {}
    for sdmType,sdmData in pairs(stuntDragMarkerDefinitions) do
        local elementType = "sdm" .. string.upper(string.sub(sdmType, 1, 1)) .. string.sub(sdmType, 2)
        local elements = getElementsByType(elementType, getResourceRootElement(mapResource))
        for _,element in ipairs(elements) do
            -- prepare marker parameters
            local value
            if (type(sdmData.value) == "string") then
                value = getElementData(element, sdmData.value, false)
            elseif (type(sdmData.value) == "table") then
                local elementData = getAllElementData(element)

                value = {}
                for _,valueKey in ipairs(sdmData.value) do
                    if (elementData[valueKey] ~= nil) then
                        value[valueKey] = elementData[valueKey]
                    end
                end
            end

            -- create marker representation
            local sdmMarker = createStuntDragMarker(element, sdmType, value, mapResource)

            -- remember marker for later initialization
            if (sdmData.init) then
                table.insert(initMarkers, {
                    ["init"] = sdmData.init,
                    ["element"] = sdmMarker,
                    ["value"] = value
                })
            end
        end
    end

    -- init initializable markers
    for _,sdmMarkerData in ipairs(initMarkers) do
        sdmMarkerData.init(sdmMarkerData.element, sdmMarkerData.value)
    end
end

--
-- add new SDM [exported function]
--
function addStuntDragMarker(marker, sdmType, value)
    if (stuntDragMarkerDefinitions[sdmType] ~= nil) then
        if (isElement(marker)) then
            local sdmMarker = createStuntDragMarker(marker, sdmType, value)
            return stuntDragMarkerDefinitions[sdmType].init(sdmMarker, value)
        else
            debug:warn("Invalid Stunt Drag Marker \"" .. id .. "\": No such element")
            return false
        end
    else
        debug:warn("Invalid Stunt Drag Marker \"" .. id .. "\": Unknown marker type \"" .. sdmType .. "\"")
        return false
    end
end

--
-- create a single SDM
--
function createStuntDragMarker(marker, sdmType, value, mapResource)
    local markerPosition = Vector3(getElementData(marker, "posX", false), getElementData(marker, "posY", false), getElementData(marker, "posZ", false))
    local markerRotation = Vector3((getElementData(marker, "rotX", false) or 0), (getElementData(marker, "rotY", false) or 0), (getElementData(marker, "rotZ", false) or 0))
    local markerColorRed, markerColorGreen, markerColorBlue, markerColorAlpha = getColorFromString(getElementData(marker, "color", false) or "#0000FFFF")
    local markerType = (getElementData(marker, "type", false) or "cylinder")
    local markerSize = (getElementData(marker, "size", false) or 1)

    -- clone marker
    local sdmMarker = createMarker(
        markerPosition.x, markerPosition.y, markerPosition.z,
        markerType, markerSize,
        markerColorRed, markerColorGreen, markerColorBlue, markerColorAlpha
    )

    setElementData(sdmMarker, "orig", marker, false)
    setElementData(sdmMarker, "origName", getElementID(marker), false)
    setElementData(sdmMarker, "definition", sdmType, false)
    setElementData(sdmMarker, "resource", getResourceName(mapResource), false)

    if (markerType == "ring") then
        local markerMatrix = Matrix(markerPosition, Vector3(markerRotation.x, 0, markerRotation.z))

        local markerTarget = markerPosition + markerMatrix.forward
        setMarkerTarget(sdmMarker, markerTarget.x, markerTarget.y, markerTarget.z)
    end

    -- hide marker
    if (getElementData(marker, "visibility", false) == "Hidden") then
        setElementVisibleTo(sdmMarker, root, false)
    end

    -- reference marker
    setElementData(marker, "marker", sdmMarker, false)

    -- remember marker for cleanup
    if (not stuntDragMarkers[sdmType]) then stuntDragMarkers[sdmType] = {} end
    table.insert(stuntDragMarkers[sdmType], sdmMarker)

    return sdmMarker
end

--
-- text marker
--
function initTextStuntDragMarker(marker, value)
    local text, textSize, textColor, textPositionX, textPositionY, textAlignX, textAlignY, textDuration
    if (type(value) == "table") then
        text = (value.text and tostring(value.text) or nil)
        textSize = tonumber(value.textSize)
        textColor = (value.textColor and tostring(value.textColor) or nil)
        textPositionX = tonumber(value.textPositionX)
        textPositionY = tonumber(value.textPositionY)
        textAlignX = (value.textAlignX and tostring(value.textAlignX) or nil)
        textAlignY = (value.textAlignY and tostring(value.textAlignY) or nil)
        textDuration = tonumber(value.textDuration)
    elseif (type(value) == "string") then
        text = value
    end

    setElementData(marker, "text", (text or ""), false)
    setElementData(marker, "textSize", (textSize or 12), false)
    setElementData(marker, "textColor", (textColor or "#ffffffff"), false)
    setElementData(marker, "textPositionX", (textPositionX or 0.5), false)
    setElementData(marker, "textPositionY", (textPositionY or 0.5), false)
    setElementData(marker, "textAlignX", (textAlignX or "center"), false)
    setElementData(marker, "textAlignY", (textAlignY or "center"), false)
    setElementData(marker, "textDuration", (textDuration or 3000), false)

    debug:notice("initTextStuntDragMarker(" .. getElementData(marker, "origName", false) .. ")")

    addEventHandler("onMarkerHit", marker, textOnMarkerHit)
    return true
end

function textOnMarkerHit(hitElement)
    if (getElementType(hitElement) == "player") then
        local text = getElementData(source, "text", false)
        local textSize = getElementData(source, "textSize", false)
        local textColor = getElementData(source, "textColor", false)
        local textPositionX = getElementData(source, "textPositionX", false)
        local textPositionY = getElementData(source, "textPositionY", false)
        local textAlignX = getElementData(source, "textAlignX", false)
        local textAlignY = getElementData(source, "textAlignY", false)
        local textDuration = getElementData(source, "textDuration", false)

        debug:notice(
            hitElement,
            "textOnMarkerHit(" .. getElementData(source, "origName", false) .. ", "
                .. "\"" .. text .. "\", " .. textSize .. "px, " .. textColor .. ", "
                .. textPositionX .. "/" .. textPositionY .. ", "
                .. textAlignX .. "/" .. textAlignY .. ", "
                .. textDuration .. "ms)"
        )

        local textColorRed, textColorGreen, textColorBlue, textColorAlpha = getColorFromString(textColor)
        if ((not textColorRed) or (not textColorGreen) or (not textColorBlue) or (not textColorAlpha)) then
            textColorRed, textColorGreen, textColorBlue, textColorAlpha = getColorFromString("#ffffffff")
        end

        local display = textCreateDisplay()
        local displayText = textCreateTextItem(
            text, textPositionX, textPositionY, "medium",
            textColorRed, textColorGreen, textColorBlue, textColorAlpha,
            (textSize / 12), textAlignX, textAlignY, 255
        )

        textDisplayAddObserver(display, hitElement)
        textDisplayAddText(display, displayText)

        if (textDuration > 0) then
            setTimer(textDestroyDisplay, textDuration, 1, display)
        end
    end
end

--
-- magnet marker
--
function initMagnetStuntDragMarker(marker, value)
    local rawEnable, mode
    if (type(value) == "table") then
        rawEnable = value.enable
        if (value.mode) then
            mode = tostring(value.mode)
            mode = string.lower(mode)
        end
    else
        rawEnable = value
    end

    local enable = true
    if (type(rawEnable) == "boolean") then
        enable = rawEnable
    elseif (type(rawEnable) == "string") then
        rawEnable = string.lower(rawEnable)
        enable = ((rawEnable == "enable") or (rawEnable == "yes") or (rawEnable == "true"))
    end

    setElementData(marker, "enable", tostring(enable), false)
    setElementData(marker, "mode", (mode or "default"), false)

    debug:notice("initMagnetStuntDragMarker(" .. getElementData(marker, "origName", false) .. ")")

    addEventHandler("onMarkerHit", marker, magnetOnMarkerHit)
    return true
end

function magnetOnMarkerHit(hitElement)
    if (getElementType(hitElement) == "player") then
        local vehicle = getPedOccupiedVehicle(hitElement)
        if (not vehicle) then return end

        local enable = (getElementData(source, "enable", false) == "true")
        local mode = getElementData(source, "mode", false)

        debug:notice(hitElement, "magnetOnMarkerHit(" .. getElementData(source, "origName", false) .. ", " .. tostring(enable) .. ", " .. mode .. ")")

        if (enable) then
            triggerClientEvent(hitElement, "onClientEnableVehicleMagnet", resourceRoot, vehicle, mode)
        else
            triggerClientEvent(hitElement, "onClientDisableVehicleMagnet", resourceRoot, vehicle)
        end
    end
end

--
-- gravity marker
--
function initGravityStuntDragMarker(marker, value)
    local mode, gravityX, gravityY, gravityZ
    if (type(value) == "table") then
        if (type(value.mode) == "string") then mode = string.lower(value.mode) end
        gravityX, gravityY, gravityZ = tonumber(value.gravityX), tonumber(value.gravityY), tonumber(value.gravityZ)
    end

    if (((mode == "world") or (mode == "client") or (mode == "vehicle-boost")) and (((gravityX ~= nil) and (gravityX ~= 0)) or ((gravityY ~= nil) and (gravityY ~= 0)))) then
        debug:warn("Invalid Stunt Drag Marker \"" .. getElementData(marker, "origName", false) .. "\": "
            .. "You mustn't combine gravity mode \"world\", \"client\" or \"vehicle-boost\" "
            .. "with a gravity specified on the X or Y axis, "
            .. gravityX .. "/" .. gravityY .. "/" .. gravityZ .. " given")
        return false
    end
    if ((mode ~= nil) and (mode ~= "world") and (mode ~= "client") and (mode ~= "vehicle") and (mode ~= "vehicle-boost")) then
        debug:warn("Invalid Stunt Drag Marker \"" .. getElementData(marker, "origName", false) .. "\": Invalid gravity mode \"" .. mode .. "\"")
        return false
    end

    setElementData(marker, "mode", (mode or "vehicle"), false)
    setElementData(marker, "gravityX", (gravityX or 0), false)
    setElementData(marker, "gravityY", (gravityY or 0), false)
    setElementData(marker, "gravityZ", (gravityZ or -1), false)

    debug:notice("initGravityStuntDragMarker(" .. getElementData(marker, "origName", false) .. ")")

    addEventHandler("onMarkerHit", marker, gravityOnMarkerHit)
    return true
end

function gravityOnMarkerHit(hitElement)
    local mode = getElementData(source, "mode", false)
    local vehicleVehicleMode = (((mode == "vehicle") or (mode == "vehicle-boost")) and (getElementType(hitElement) == "vehicle") and getVehicleController(hitElement))
    local playerPlayerMode = ((mode ~= "vehicle") and (mode ~= "vehicle-boost") and (getElementType(hitElement) == "player"))
    if (vehicleVehicleMode or playerPlayerMode) then
        local gravityX = getElementData(source, "gravityX", false)
        local gravityY = getElementData(source, "gravityY", false)
        local gravityZ = getElementData(source, "gravityZ", false)

        debug:notice(
            (((mode == "vehicle") or (mode == "vehicle-boost")) and getVehicleOccupant(hitElement) or hitElement),
            "gravityOnMarkerHit(" .. getElementData(source, "origName", false) .. ", " .. mode .. ", "
                .. gravityX .. "/" .. gravityY .. "/" .. gravityZ .. ")"
        )

        if (mode == "world") then
            setGravity((- gravityZ) * 0.008)
        elseif (mode == "client") then
            triggerClientEvent(hitElement, "onClientSetGravity", resourceRoot, (- gravityZ) * getGravity())
        else
            local players = getElementsByType("player")
            for _,player in ipairs(players) do
                triggerClientEvent(player, "onClientSetVehicleGravity", resourceRoot, hitElement, mode, gravityX, gravityY, gravityZ)
            end
        end
    end
end

--
-- teleport marker
--
function initTeleportStuntDragMarker(marker, value)
    local target, targetX, targetY, targetZ
    local velocity, velocityX, velocityY, velocityZ
    local rotation, rotationX, rotationY, rotationZ
    if (type(value) == "table") then
        if (value.targetX and value.targetY and value.targetZ) then
            targetX, targetY, targetZ = tonumber(value.targetX), tonumber(value.targetY), tonumber(value.targetZ)
        elseif ((type(value.target) == "string") or isElement(value.target)) then
            local targetName
            if (type(value.target) == "string") then
                target = getMapElementByID(value.target, resource)
                    or getMapElementByID(value.target, getResourceFromName(getElementData(marker, "resource", false)))
                    or getElementByID(value.target)
                targetName = value.target
            else
                target = value.target
                targetName = getElementID(value.target)
            end

            if (target) then
                targetX, targetY, targetZ = getElementPosition(target)
            else
                outputDebugString("Invalid Stunt Drag Marker \"" .. getElementData(marker, "origName", false) .. "\": Invalid teleporter target \"" .. tostring(targetName) .. "\"", 2)
                return false
            end
        end

        if (value.velocity) then
            velocity = tonumber(value.velocity) -- strings (e.g. "keep" and "false") become nil
        end

        if (value.velocityX and value.velocityY and value.velocityZ) then
            velocityX, velocityY, velocityZ = tonumber(velocityX), tonumber(velocityY), tonumber(velocityZ)
        end

        rotation = true
        if (type(value.keepRotation) == "boolean") then
            rotation = value.keepRotation
        elseif (type(value.keepRotation) == "string") then
            value.keepRotation = string.lower(value.keepRotation)
            rotation = ((value.keepRotation == "keep") or (value.keepRotation == "yes") or (value.keepRotation == "true"))
        end

        if (value.rotationX and value.rotationY and value.rotationZ) then
            rotationX, rotationY, rotationZ = tonumber(rotationX), tonumber(rotationY), tonumber(rotationZ)
        end
    end

    local momentum = ((not velocity) and (not velocityX) and (not velocityY) and (not velocityZ))

    if (velocity and (velocityX or velocityY or velocityZ)) then
        debug:warn("Invalid Stunt Drag Marker \"" .. getElementData(marker, "origName", false) .. "\": "
            .. "Contradictory velocity data: You've specified both the velocity \"" .. velocity .. " km/h\" "
            .. "and " .. velocityX .. "/" .. velocityY .. "/" .. velocityZ)
        return false
    end
    if (rotation and (rotationX or rotationY or rotationZ)) then
        debug:warn("Invalid Stunt Drag Marker \"" .. getElementData(marker, "origName", false) .. "\": "
            .. "Contradictory rotation data: You've specified both \"rotation\" == true and "
            .. "the rotation " .. rotationX .. "/" .. rotationY .. "/" .. rotationZ)
        return false
    end
    if ((not rotation) and (not target) and ((not rotationX) or (not rotationY) or (not rotationZ))) then
        debug:warn("Invalid Stunt Drag Marker \"" .. getElementData(marker, "origName", false) .. "\": "
            .. "Contradictory rotation data: You've specified \"rotation\" == false, "
            .. "but neither a explicit rotation nor a target element is given")
        return false
    end

    if ((not rotation) and (not rotationX) and (not rotationY) and (not rotationZ)) then
        if (string.sub(getElementType(target), 1, 3) == "sdm") then
            -- use raw rotX/rotY/rotZ element data of sdm* elements
            rotationX = tonumber(getElementData(target, "rotX", false))
            rotationY = tonumber(getElementData(target, "rotY", false))
            rotationZ = tonumber(getElementData(target, "rotZ", false))
        elseif (getElementType(target) == "marker") then
            -- you'll loose the rotation on the Y axis (i.e. you can't flip a vehicle top-down)
            local markerTargetX, markerTargetY, markerTargetZ = getMarkerTarget(target)
            if (markerTargetX and markerTargetY and markerTargetZ) then
                rotationX = math.deg(math.atan2(markerTargetZ - targetZ, getDistanceBetweenPoints2D(markerTargetX, markerTargetY, targetX, targetY)))
                rotationY = 0
                rotationZ = math.deg((2 * math.pi) - math.atan2((markerTargetX - targetX), (markerTargetY - targetY)) % (2 * math.pi))
            end
        else
            rotationX, rotationY, rotationZ = getElementRotation(target)
        end
    end

    setElementData(marker, "teleportX", (targetX or 0), false)
    setElementData(marker, "teleportY", (targetY or 0), false)
    setElementData(marker, "teleportZ", (targetZ or 0), false)
    setElementData(marker, "momentum", tostring(momentum), false)
    setElementData(marker, "velocity", (velocity or 0), false)
    setElementData(marker, "velocityX", (velocityX or 0), false)
    setElementData(marker, "velocityY", (velocityY or 0), false)
    setElementData(marker, "velocityZ", (velocityZ or 0), false)
    setElementData(marker, "rotation", tostring(rotation), false)
    setElementData(marker, "rotationX", (rotationX or 0), false)
    setElementData(marker, "rotationY", (rotationY or 0), false)
    setElementData(marker, "rotationZ", (rotationZ or 0), false)

    debug:notice("initTeleportStuntDragMarker(" .. getElementData(marker, "origName", false) .. ")")

    addEventHandler("onMarkerHit", marker, teleportOnMarkerHit)
    return true
end

function teleportOnMarkerHit(hitElement)
    if ((getElementType(hitElement) == "vehicle") and getVehicleController(hitElement)) then
        local targetX = getElementData(source, "teleportX", false)
        local targetY = getElementData(source, "teleportY", false)
        local targetZ = getElementData(source, "teleportZ", false)
        local momentum = (getElementData(source, "momentum", false) == "true")
        local velocity = getElementData(source, "velocity", false)
        local velocityX = getElementData(source, "velocityX", false)
        local velocityY = getElementData(source, "velocityY", false)
        local velocityZ = getElementData(source, "velocityZ", false)
        local rotation = (getElementData(source, "rotation", false) == "true")
        local rotationX = getElementData(source, "rotationX", false)
        local rotationY = getElementData(source, "rotationY", false)
        local rotationZ = getElementData(source, "rotationZ", false)

        debug:notice(
            getVehicleOccupant(hitElement),
            "teleportOnMarkerHit(" .. getElementData(source, "origName", false) .. ", "
                .. targetX .. "/" .. targetY .. "/" .. targetZ .. ", "
                .. tostring(momentum) .. ((not momentum) and (", " .. (velocity and (velocity .. " km/h") or (velocityX .. "/" .. velocityY .. "/" .. velocityZ))) or "")  .. ", "
                .. tostring(rotation) .. ((not rotation) and (", " .. rotationX .. "/" .. rotationY .. "/" .. rotationZ) or "")  .. ")"
        )

        setElementFrozen(hitElement, true)
        setElementPosition(hitElement, targetX, targetY, targetZ + getVehicleBaseOffset(hitElement), false)

        if (rotation) then rotationX, rotationY, rotationZ = getVehicleRotation(hitElement) end
        setElementRotation(hitElement, rotationX, rotationY, rotationZ)

        if (momentum) then
            velocityX, velocityY, velocityZ = getElementVelocity(hitElement)
            velocity = ((not rotation) and (math.sqrt(velocityX ^ 2 + velocityY ^ 2 + velocityZ ^ 2) * 180) or nil)
        end
        if (velocity) then
            local velocityVector = hitElement.matrix.forward * velocity / 180
            velocityX, velocityY, velocityZ = velocityVector.x, velocityVector.y, velocityVector.z
        end

        setTimer(function (hitElement, velocityX, velocityY, velocityZ)
            setElementFrozen(hitElement, false)
            setElementVelocity(hitElement, velocityX, velocityY, velocityZ)
        end, 500, 1, hitElement, velocityX, velocityY, velocityZ)
    end
end

--
-- health marker
--
function initHealthStuntDragMarker(marker, value)
    local health
    if ((type(value) == "string") or (type(value) == "number")) then
        health = tonumber(value)
    end

    setElementData(marker, "health", (health or 1000), false)

    debug:notice("initHealthStuntDragMarker(" .. getElementData(marker, "origName", false) .. ")")

    addEventHandler("onMarkerHit", marker, healthOnMarkerHit)
    return true
end

function healthOnMarkerHit(hitElement)
    if ((getElementType(hitElement) == "vehicle") and getVehicleController(hitElement)) then
        local health = getElementData(source, "health", false)

        debug:notice(getVehicleOccupant(hitElement), "healthOnMarkerHit(" .. getElementData(source, "origName", false) .. ", " .. health .. ")")

        setElementHealth(hitElement, health)
    end
end

--
-- sky marker
--
function initSkyStuntDragMarker(marker, value)
    local mode, topColor, bottomColor
    if (type(value) == "table") then
        if (type(value.mode) == "string") then mode = string.lower(value.mode) end
        topColor = (value.topColor and tostring(value.topColor) or nil)
        bottomColor = (value.bottomColor and tostring(value.bottomColor) or nil)
    elseif (type(value) == "string") then
        topColor, bottomColor = value, value
    end
    if ((mode ~= nil) and (mode ~= "client") and (mode ~= "world")) then
        debug:warn("Invalid Stunt Drag Marker \"" .. getElementData(marker, "origName", false) .. "\": Invalid sky mode \"" .. mode .. "\"")
        return false
    end

    -- default colors: special value (transparent black) --> resetSkyGradient()
    setElementData(marker, "mode", (mode or "client"), false)
    setElementData(marker, "topColor", (topColor or "#00000000"), false)
    setElementData(marker, "bottomColor", (bottomColor or "#00000000"), false)

    debug:notice("initSkyStuntDragMarker(" .. getElementData(marker, "origName", false) .. ")")

    addEventHandler("onMarkerHit", marker, skyOnMarkerHit)
    return true
end

function skyOnMarkerHit(hitElement)
    if (getElementType(hitElement) == "player") then
        local mode = getElementData(source, "mode", false)
        local topColor = getElementData(source, "topColor", false)
        local bottomColor = getElementData(source, "bottomColor", false)

        debug:notice(hitElement, "skyOnMarkerHit(" .. getElementData(source, "origName", false) .. ", " .. mode.. ", " .. topColor .. ", " .. bottomColor .. ")")

        if (mode == "client") then
            triggerClientEvent(hitElement, "onClientSetSkyGradient", resourceRoot, topColor, bottomColor)
        else
            if ((topColor == "#00000000") and (bottomColor == "#00000000")) then
                resetSkyGradient()
            else
                local topRed, topGreen, topBlue, topAlpha = getColorFromString(topColor)
                if ((not topRed) or (not topGreen) or (not topBlue) or (not topAlpha)) then
                    -- default: weather 0 (Blue Sky, Sunny) at 12:00
                    topRed, topGreen, topBlue, topAlpha = getColorFromString("#4475D2")
                elseif (topAlpha < 255) then
                    topRed = ((255 - topRed) * (topAlpha / 255) + topRed)
                    topGreen = ((255 - topGreen) * (topAlpha / 255) + topGreen)
                    topBlue = ((255 - topBlue) * (topAlpha / 255) + topBlue)
                end

                local bottomRed, bottomGreen, bottomBlue, bottomAlpha = getColorFromString(bottomColor)
                if ((not bottomRed) or (not bottomGreen) or (not bottomBlue) or (not bottomAlpha)) then
                    -- default: weather 0 (Blue Sky, Sunny) at 12:00
                    bottomRed, bottomGreen, bottomBlue, bottomAlpha = getColorFromString("#2475C6")
                elseif (bottomAlpha < 255) then
                    bottomRed = ((255 - bottomRed) * (bottomAlpha / 255) + bottomRed)
                    bottomGreen = ((255 - bottomGreen) * (bottomAlpha / 255) + bottomGreen)
                    bottomBlue = ((255 - bottomBlue) * (bottomAlpha / 255) + bottomBlue)
                end

                setSkyGradient(topRed, topGreen, topBlue, bottomRed, bottomGreen, bottomBlue)
            end
        end
    end
end

--
-- water marker
--
function initWaterStuntDragMarker(marker, value)
    local mode, color
    if (type(value) == "table") then
        if (type(value.mode) == "string") then mode = string.lower(value.mode) end
        color = (value.waterColor and tostring(value.waterColor) or nil)
    elseif (type(value) == "string") then
        color = value
    end
    if ((mode ~= nil) and (mode ~= "client") and (mode ~= "world")) then
        debug:warn("Invalid Stunt Drag Marker \"" .. getElementData(marker, "origName", false) .. "\": Invalid water mode \"" .. mode .. "\"")
        return false
    end

    -- default color: special value (transparent black) --> resetWaterColor()
    setElementData(marker, "mode", (mode or "client"), false)
    setElementData(marker, "color", (color or "#00000000"), false)

    debug:notice("initWaterStuntDragMarker(" .. getElementData(marker, "origName", false) .. ")")

    addEventHandler("onMarkerHit", marker, waterOnMarkerHit)
    return true
end

function waterOnMarkerHit(hitElement)
    if (getElementType(hitElement) == "player") then
        local mode = getElementData(source, "mode", false)
        local color = getElementData(source, "color", false)

        debug:notice(hitElement, "waterOnMarkerHit(" .. getElementData(source, "origName", false) .. ", " .. mode .. ", " .. color .. ")")

        if (mode == "client") then
            triggerClientEvent(hitElement, "onClientSetWaterColor", resourceRoot, color)
        else
            if (color == "#00000000") then
                resetWaterColor()
            else
                local red, green, blue, alpha = getColorFromString(color)
                if ((not red) or (not green) or (not blue)) then
                    -- default: weather 0 (Blue Sky, Sunny) at 12:00
                    red, green, blue, alpha = getColorFromString("#59A9A9F0")
                end

                setWaterColor(red, green, blue, alpha)
            end
        end
    end
end

--
-- helper
--

function getMapElementByID(id, resource)
    local bloodlines = { getElementChildren(getResourceRootElement(resource), "map") }
    while (#bloodlines > 0) do
        local checkBloodlines = bloodlines
        bloodlines = {}

        for _,children in ipairs(checkBloodlines) do
            for _,child in ipairs(children) do
                if (getElementID(child) == id) then
                    return child
                end

                local grandChildren = getElementChildren(child)
                if (grandChildren and (#grandChildren > 0)) then
                    table.insert(bloodlines, grandChildren)
                end
            end
        end
    end
end

addCommandHandler("license",
    function (playerSource, commandName, resourceName)
        outputChatBox(" ", playerSource)
        outputChatBox("PhrozenByte Stunt Drag Markers", playerSource, 233, 100, 100)
        outputChatBox("Copyright (C) 2015-2016  Daniel Rudolf <http://www.daniel-rudolf.de/>", playerSource, 225, 170, 90)
        outputChatBox("This MTA resource is free software under the terms of the GNU AGPL version 3. It comes with ABSOLUTELY NO WARRANTY.  "
            .. "See MTA's console (press the F8 or ~ key) for details.", playerSource)

        outputConsole(" ", playerSource)
        outputConsole("Please refer to the \"README.md\" and \"DOWNLOAD.md\" files for details. You should have received a copy "
            .. "of them along with the client-side files of this resource (see MTA's resources download directory, usually the "
            .. "\"mods/deathmatch/resources/stunt-drag-markers/\" folder in the installation path of MTA).", playerSource)
        outputConsole(" ", playerSource)
        outputConsole("This program is free software: you can redistribute it and/or modify it under the terms of the GNU Affero "
            .. "General Public License as published by the Free Software Foundation, version 3 of the License only.", playerSource)
        outputConsole(" ", playerSource)
        outputConsole("This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the "
            .. "implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU Affero General Public License "
            .. "for more details.", playerSource)
        outputConsole(" ", playerSource)
        outputConsole("You should have received a copy of the GNU Affero General Public License along with this program.  "
            .. "If not, see <http://www.gnu.org/licenses/>.", playerSource)
        outputConsole(" ", playerSource)
    end
)

--
-- SDM definitions
--
stuntDragMarkerDefinitions = {
    ["text"] = {
        ["init"] = initTextStuntDragMarker,
        ["value"] = {
            "text", "textSize", "textColor",
            "textPositionX", "textPositionY",
            "textAlignX", "textAlignY",
            "textDuration"
        }
    },
    ["gravity"] = {
        ["init"] = initGravityStuntDragMarker,
        ["value"] = { "mode", "gravityX", "gravityY", "gravityZ" }
    },
    ["magnet"] = {
        ["init"] = initMagnetStuntDragMarker,
        ["value"] = { "mode", "enable" }
    },
    ["teleport"] = {
        ["init"] = initTeleportStuntDragMarker,
        ["value"] = {
            "target", "targetX", "targetY", "targetZ",
            "velocity", "velocityX", "velocityY", "velocityZ",
            "keepRotation", "rotationX", "rotationY", "rotationZ",
            "keepVehicle", "vehicleModel"
        }
    },
    ["teleportTarget"] = {},
    ["health"] = {
        ["init"] = initHealthStuntDragMarker,
        ["value"] = "health"
    },
    ["sky"] = {
        ["init"] = initSkyStuntDragMarker,
        ["value"] = { "mode", "topColor", "bottomColor" }
    },
    ["water"] = {
        ["init"] = initWaterStuntDragMarker,
        ["value"] = { "mode", "waterColor" }
    }
}
