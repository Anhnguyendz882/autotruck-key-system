-- ============================================================
-- Auto Truck Script for GTA SA:MP
-- Server: 104.234.180.76:7777
-- Author: KN| YouTube: @nguyencudam
-- Decoded & cleaned by deobfuscator
-- ============================================================

-- == LIBRARIES ==
local samp_events = require("lib.samp.events")
local imgui       = require("mimgui")
local encoding    = require("encoding")
local requests    = require("requests")
local ffi         = require("ffi")
local inicfg      = require("inicfg")
require("sampfuncs")

encoding.default = "CP1251"
u8 = encoding.UTF8

local fa_icons    = require("fAwesome6")
local logo_texture = nil
local dpi_scale   = MONET_DPI_SCALE or 1

-- == HELPER: get FontAwesome icon ==
local function get_icon(icon_name)
    if fa_icons and fa_icons[icon_name] then
        return fa_icons[icon_name]
    end
    return "?"
end

-- == FFI: open link ==
ffi.cdef("void _Z12AND_OpenLinkPKc(const char* link);")
local gtasa_lib = ffi.load("GTASA")
imgui.Link = function(url)
    gtasa_lib._Z12AND_OpenLinkPKc(url)
end

-- == CONSTANTS ==
local SERVER_IP  = "104.234.180.76:7777"
local music_path = getWorkingDirectory() .. "/resource/sound/sound.mp3"

-- == MUSIC ==
local music_volume = imgui.new.float(0.5)
local audio_stream = nil
local is_playing   = false
local config = inicfg.load({["music"] = {["volume"] = 0.5}}, "autotruck_config.ini")
music_volume[0] = config.music.volume

function saveMusicConfig()
    config.music.volume = music_volume[0]
    inicfg.save(config, "autotruck_config.ini")
end

function stopMusic()
    if audio_stream then
        setAudioStreamVolume(audio_stream, 0)
        setAudioStreamState(audio_stream, 3)
        audio_stream = nil
    end
    is_playing = false
end

function startMusic()
    stopMusic()
    if doesFileExist(music_path) then
        audio_stream = loadAudioStream(music_path)
        if audio_stream then
            setAudioStreamVolume(audio_stream, music_volume[0])
            setAudioStreamState(audio_stream, 1)
            is_playing = true
        end
    end
end

function togglePlayPause()
    if not audio_stream then
        startMusic()
        return
    end
    if is_playing then
        setAudioStreamState(audio_stream, 2)
        is_playing = false
    else
        setAudioStreamState(audio_stream, 1)
        is_playing = true
    end
end

-- == AUTH SYSTEM ==

local function get_player_name()
    local ok, _, pid = pcall(sampGetPlayerIdByCharHandle, PLAYER_PED)
    if ok and pid then
        local ok2, name = pcall(sampGetPlayerNickname, pid)
        if ok2 and name then return name end
    end
    return nil
end

local function parse_date(date_str)
    local d, m, y = date_str:match("^(%d+)/(%d+)/(%d+)$")
    if not d or not m or not y then return nil end
    d, m, y = tonumber(d), tonumber(m), tonumber(y)
    if not d or not m or not y then return nil end
    local ok, ts = pcall(os.time, {year=y, month=m, day=d, hour=23, min=59, sec=59})
    return (ok and ts) or nil
end

local function check_auth()
    local player_name = get_player_name()
    if not player_name or #auth.keys == 0 then
        auth.authMsg = "Could not find player name or no keys loaded."
        return
    end
    auth.playerName    = player_name
    auth.authenticated = false
    for _, entry in ipairs(auth.keys) do
        local key_name, key_expiry = entry:match("^([^;]+);(.+)$")
        if key_name and key_expiry and key_name == player_name then
            local expiry_ts = parse_date(key_expiry)
            if expiry_ts then
                local now_ts = os.time()
                if now_ts <= expiry_ts then
                    auth.authenticated = true
                    auth.validUntil    = key_expiry
                    auth.remainingDays = math.ceil((expiry_ts - now_ts) / 86400)
                    auth.authMsg       = "Authentication successful!"
                    sampAddChatMessage("{00FF00}[AUTH] {FFFFFF}Key is valid! Remaining: " .. auth.remainingDays .. " days.", -1)
                    return
                else
                    auth.authMsg = "Your key expired on " .. key_expiry
                    sampAddChatMessage("{FF0000}[AUTH] {FFFFFF}" .. auth.authMsg, -1)
                    return
                end
            end
        end
    end
    auth.authMsg = "No valid key found for account: " .. player_name
    sampAddChatMessage("{FFFF00}[AUTH] {FFFFFF}" .. auth.authMsg, -1)
end

local function load_keys()
    if not auth.systemEnabled then
        auth.authMsg = "Cannot load keys, system is under maintenance."
        return
    end
    auth.loading = true
    auth.authMsg = "Loading database..."
    lua_thread.create(function()
        local ok, response = pcall(requests.get, auth.KEYS_URL, {timeout=15})
        auth.loading = false
        if ok and response and response.status_code == 200 then
            auth.keys = {}
            for line in response.text:gmatch("[^\r\n]+") do
                line = line:gsub("^%s*(.-)%s*$", "%1")
                if line ~= "" and not line:match("^[#/%-]") then
                    table.insert(auth.keys, line)
                end
            end
            check_auth()
        else
            auth.authMsg = "Error: Could not load key list."
            sampAddChatMessage("{FF0000}[AUTH] {FFFFFF}" .. auth.authMsg, -1)
        end
    end)
end

local function check_status()
    auth.loading   = true
    auth.statusMsg = "Checking status..."
    lua_thread.create(function()
        local ok, resp = pcall(requests.get, auth.STATUS_URL, {timeout=10})
        if ok and resp and resp.status_code == 200 then
            local status = resp.text:gsub("^%s*(.-)%s*$", "%1"):lower()
            if status == "on" then
                auth.systemEnabled = true
                auth.statusMsg     = "Online"
            elseif status == "off" then
                auth.systemEnabled = false
                auth.authenticated = false
                auth.statusMsg     = "Maintenance"
                sampAddChatMessage("{FF0000}[AUTH] {FFFFFF}The system has been disabled by an admin. Script will unload in 5 seconds...", -1)
                lua_thread.create(function()
                    wait(5000)
                    thisScript():unload()
                end)
                stopAutoSystem()
            else
                auth.systemEnabled = false
                auth.statusMsg     = "Unknown Status"
            end
        else
            auth.systemEnabled = false
            auth.statusMsg     = "Connection Error"
        end
        auth.loading = false
    end)
end

local function do_auth()
    if auth.loading then return end
    check_status()
    lua_thread.create(function()
        wait(2000)
        if auth.systemEnabled then
            load_keys()
        else
            auth.authMsg = "System is under maintenance, cannot authenticate."
        end
    end)
end

-- == ROUTES ==
local routes = {
    pickup_route = {},
    duong_di_1   = {},
    duong_di_1_1 = {},
    duong_di_2   = {},
    duong_di_2_1 = {},
}

local function load_routes()
    if not auth.systemEnabled then
        sampAddChatMessage("{FF0000}[ROUTES] {FFFFFF}Cannot load routes, system is offline.", -1)
        return false
    end
    lua_thread.create(function()
        local ok, resp = pcall(requests.get, auth.ROUTES_URL, {timeout=15})
        if ok and resp and resp.status_code == 200 then
            local text    = resp.text
            local section = nil
            for _, key in pairs(routes) do
                if type(key) == "table" then
                    -- clear
                end
            end
            for _, k in pairs({"pickup_route","duong_di_1","duong_di_1_1","duong_di_2","duong_di_2_1"}) do
                routes[k] = {}
            end
            routes.pickup_route = {
                "-1576.0262,109.6952,3.5454,0.0,10.0,VEHICLE,0,0",
                "-1573.2003,81.5527,3.5424,0.0,10.0,VEHICLE,0,0",
            }
            for line in text:gmatch("[^\r\n]+") do
                line = line:gsub("^%s*(.-)%s*$", "%1")
                if line:match("%]%]") then
                    section = nil
                elseif line:match("pickup_route") then
                    section = nil
                elseif line:match("duong_di_1%.1") then
                    section = "duong_di_1_1"
                elseif line:match("duong_di_1") then
                    section = "duong_di_1"
                elseif line:match("duong_di_2%.1") then
                    section = "duong_di_2_1"
                elseif line:match("duong_di_2") then
                    section = "duong_di_2"
                elseif section and line ~= "" and not line:match("%[%[") then
                    local point = line:match("([%-]?[%d%.]+,[%-]?[%d%.]+,[%-]?[%d%.]+,[%-]?[%d%.]+,[%-]?[%d%.]+,VEHICLE,%d+,%d+)")
                    if point then
                        table.insert(routes[section], point)
                    end
                end
            end
            auth.routesLoaded = true
        else
            auth.routesLoaded = false
            sampAddChatMessage("{FF0000}[ROUTES] {FFFFFF}Failed to load routes from server.", -1)
        end
    end)
    return true
end

-- == UTILS ==
local function chat_msg(msg)
    sampAddChatMessage("{4CAF50}[AUTO TRUCK] {FFFFFF}" .. msg, -1)
end

local function dist3d(x1,y1,z1,x2,y2,z2)
    if not x1 or not x2 then return 9999 end
    return math.sqrt((x2-x1)^2 + (y2-y1)^2 + (z2-z1)^2)
end

-- == LINE DRAWING ==
function draw_line(tx, ty, tz)
    local px, py, pz = getCharCoordinates(PLAYER_PED)
    if not isPointOnScreen(tx, ty, tz or pz, 0) then return end
    local sx, sy = convert3DCoordsToScreen(tx, ty, tz or pz)
    local ox, oy = convert3DCoordsToScreen(px, py, pz)
    if sx and sy and ox and oy then
        renderDrawLine(ox, oy, sx, sy, 2, 0xFF3F7F50)
        renderDrawPolygon(sx, sy, 10, 10, 14, 0, 0xFF000000)
        renderDrawPolygon(ox, oy, 10, 10, 14, 0, 0xFF000000)
    end
end

-- == AUTOPILOT ==
local autopilot_state = {active=imgui.new.bool(false), showWindow=imgui.new.bool(false), fallbackSpeed=30, currentMode="none", target=nil, distanceToTarget=0}
local manual_checkpoint = {active=false, x=0, y=0, z=0}
local route_data = {}
local route_index = 1

local function parse_route_point(str)
    if not str or str == "" then return nil end
    local parts = {}
    for v in str:gmatch("([^,]+)") do table.insert(parts, v) end
    if #parts < 8 then return nil end
    local x,y,z,h,spd = tonumber(parts[1]),tonumber(parts[2]),tonumber(parts[3]),tonumber(parts[4]),tonumber(parts[5])
    if not x then return nil end
    return {x=x, y=y, z=z, heading=h, speed=spd, mode=parts[6], is_marked=tonumber(parts[7])==1, mark_duration=tonumber(parts[8])}
end

local function get_route_points(name)
    local raw = routes[name]
    if not raw or #raw == 0 then return {} end
    local out = {}
    for _, line in ipairs(raw) do
        local p = parse_route_point(line)
        if p then table.insert(out, p) end
    end
    return out
end

-- == TRUCK CONFIG ==
local truck_config = {
    bensonModelId  = 499,
    scan_distance  = 100,
    door_radius    = 7.0,
    enter_radius   = 2.5,
    cooldown       = 2000,
    last_enter_time = 0,
    max_move_time  = 30000,
}
local door_anim = {name="thrw_barl_thrw", lib="AIRPORT"}
local vehicle_state = {
    is_moving_to_vehicle = false,
    is_opening_door      = false,
    is_entering          = false,
    target_vehicle       = nil,
    move_start_time      = 0,
    door_open_time       = 0,
    enter_start_time     = 0,
    last_distance        = 999,
}

-- == AUTO SYSTEM STATE ==
local auto_system = {
    running           = false,
    phase             = "IDLE",
    is_waiting        = false,
    wait_start_time   = 0,
    deliveryStarted   = false,
    lastRestartTime   = 0,
    restartCooldown   = 3000,
    route1_toggle     = false,
    find_car_start_time = 0,
    find_car_timeout  = 60000,
}

local function set_phase(phase)
    if auto_system.phase ~= phase then
        auto_system.phase = phase
        if phase == "FINDING_CAR" then
            auto_system.find_car_start_time = os.clock() * 1000
        end
    end
end

local function reset_auto_system()
    auto_system.running         = false
    auto_system.phase           = "IDLE"
    auto_system.is_waiting      = false
    auto_system.wait_start_time = 0
    auto_system.deliveryStarted = false
end

local cargo_config = {enabled=true, cargoType=2, delay=1000}

-- Delivery checkpoints
local delivery_checkpoints = {
    {x=-1014.29,  y=-304.41, z=32.01, name="Checkpoint 1"},
    {x=-682.84,   y=1116.0,  z=23.71, name="Checkpoint 2"},
}

local current_route = {}
local cargo_type_index = 2
local show_window = imgui.new.bool(false)
local show_line = imgui.new.bool(true)

-- == SERVER CHECK ==
local function check_samp()
    if not sampIsLocalPlayerSpawned() then return true end
    local ok, host, port = pcall(sampGetCurrentServerAddress)
    if not ok or not host then return true end
    local connected_ip = host .. ":" .. port
    if connected_ip ~= SERVER_IP then
        sampAddChatMessage("{FF0000}[Auto Truck] Script only works on the server: " .. SERVER_IP, -1)
        lua_thread.create(function()
            wait(5000)
            thisScript():unload()
        end)
        return false
    end
    return true
end

-- == VEHICLE HELPERS ==
local function is_valid_benson(veh)
    if not veh or not doesVehicleExist(veh) then return false end
    if getCarModel(veh) ~= truck_config.bensonModelId then return false end
    if not isCarPassengerSeatFree(veh, 0) then return false end
    return true
end

local function get_door_position(veh)
    local x,y,z = getCarCoordinates(veh)
    local h = getCarHeading(veh)
    local rad = math.rad(h)
    local dx = (-2.4 * math.cos(rad)) - (1 * math.sin(rad))
    local dy = (-1.5 * math.sin(rad)) + (1 * math.cos(rad))
    return x+dx, y+dy, z
end

local function scan_nearest_benson()
    local px,py,pz = getCharCoordinates(PLAYER_PED)
    if not px then return nil end
    local best_veh, best_dist = nil, truck_config.scan_distance + 1
    for id = 0, 2000 do
        if doesVehicleExist(id) and getCarModel(id) == truck_config.bensonModelId then
            local vx,vy,vz = getCarCoordinates(id)
            if vx and vx ~= 0 then
                local d = dist3d(px,py,pz, vx,vy,vz)
                if d < best_dist and d <= truck_config.scan_distance and isCarPassengerSeatFree(id, 0) then
                    best_veh, best_dist = id, d
                end
            end
        end
    end
    return best_veh
end

local function dist_to_vehicle(veh)
    if not is_valid_benson(veh) then return 999 end
    local px,py,pz = getCharCoordinates(PLAYER_PED)
    local vx,vy,vz = getCarCoordinates(veh)
    return dist3d(px,py,pz, vx,vy,vz)
end

function init_truck()
    vehicle_state.is_moving_to_vehicle = false
    vehicle_state.is_opening_door      = false
    vehicle_state.is_entering          = false
    vehicle_state.target_vehicle       = nil
    vehicle_state.last_distance        = 999
    if isCharOnFoot(PLAYER_PED) then
        clearCharTasks(PLAYER_PED)
        setGameKeyState(1, 0)
        setGameKeyState(16, 0)
    end
end

function runToCoordinates(tx, ty, tz, radius)
    if not tx or not ty or not tz then return end
    while vehicle_state.is_moving_to_vehicle do
        local px,py,pz = getCharCoordinates(PLAYER_PED)
        if not px then break end
        if getDistanceBetweenCoords3d(tx,ty,tz, px,py,pz) < radius then break end
        local heading = getHeadingFromVector2d(tx-px, ty-py)
        setCharHeading(PLAYER_PED, heading)
        setGameKeyState(1, -128)
        setGameKeyState(16, 0)
        setCameraBehindPlayer()
        wait(0)
    end
    setGameKeyState(1, 0)
    setGameKeyState(16, 0)
end

local function move_to_vehicle(veh)
    if not is_valid_benson(veh) then return false end
    local dx, dy, dz = get_door_position(veh)
    if not dx then return false end
    init_truck()
    vehicle_state.is_moving_to_vehicle = true
    vehicle_state.target_vehicle       = veh
    vehicle_state.move_start_time      = os.clock() * 1000
    local px,py,pz = getCharCoordinates(PLAYER_PED)
    vehicle_state.last_distance = dist3d(px,py,pz, dx,dy,dz)
    lua_thread.create(runToCoordinates, dx, dy, dz, truck_config.door_radius)
    return true
end

local function open_door(veh)
    if not is_valid_benson(veh) then return end
    init_truck()
    vehicle_state.is_opening_door  = true
    vehicle_state.door_open_time   = os.clock() * 1000
    vehicle_state.target_vehicle   = veh
    taskPlayAnim(PLAYER_PED, door_anim.name, door_anim.lib, 4, false, true, true, false, 2000)
end

local function enter_vehicle()
    local veh = vehicle_state.target_vehicle
    if not is_valid_benson(veh) then
        init_truck()
        return
    end
    init_truck()
    vehicle_state.is_entering      = true
    vehicle_state.enter_start_time = os.clock() * 1000
    vehicle_state.target_vehicle   = veh
    taskEnterCarAsDriver(PLAYER_PED, veh, -1)
end

local function handle_entering()
    if not isCharOnFoot(PLAYER_PED) then
        truck_config.last_enter_time = os.clock() * 1000
        init_truck()
        return
    end
    if ((os.clock() * 1000) - vehicle_state.enter_start_time) > 8000 then
        init_truck()
    end
end

local function handle_door_opening()
    if not is_valid_benson(vehicle_state.target_vehicle) then return end
    if ((os.clock() * 1000) - vehicle_state.door_open_time) > 2000 then
        enter_vehicle()
    end
end

local function handle_moving_to_vehicle()
    if not is_valid_benson(vehicle_state.target_vehicle) then
        init_truck(); return
    end
    local dx,dy,dz = get_door_position(vehicle_state.target_vehicle)
    if not dx then init_truck(); return end
    if ((os.clock() * 1000) - vehicle_state.move_start_time) > truck_config.max_move_time then
        init_truck(); return
    end
    local px,py,pz = getCharCoordinates(PLAYER_PED)
    if not px then init_truck(); return end
    local d = getDistanceBetweenCoords2d(px,py, dx,dy)
    vehicle_state.last_distance = d
    if d <= truck_config.door_radius then
        vehicle_state.is_moving_to_vehicle = false
        wait(100)
        open_door(vehicle_state.target_vehicle)
    end
end

function find_car()
    if not isCharOnFoot(PLAYER_PED) then
        if vehicle_state.is_moving_to_vehicle or vehicle_state.is_opening_door or vehicle_state.is_entering then
            init_truck()
        end
        return
    end
    local now = os.clock() * 1000
    if (now - truck_config.last_enter_time) < truck_config.cooldown then return end
    if vehicle_state.is_entering then
        handle_entering()
    elseif vehicle_state.is_opening_door then
        handle_door_opening()
    elseif vehicle_state.is_moving_to_vehicle then
        handle_moving_to_vehicle()
    else
        local veh = scan_nearest_benson()
        if veh then
            local d = dist_to_vehicle(veh)
            if d <= truck_config.door_radius then
                open_door(veh)
            elseif d <= truck_config.scan_distance then
                move_to_vehicle(veh)
            end
        end
    end
end

-- == AUTOPILOT ==
local autopilot = {is_playing=false, is_paused=false}
local playback  = {currentRouteData={}, playbackIndex=1}

function AutoPilot()
    if not autopilot.is_playing or #playback.currentRouteData == 0 then return end
    local point = playback.currentRouteData[playback.playbackIndex]
    if not point or type(point.x) ~= "number" then
        stopAutoDrive("Invalid route point"); return
    end
    local px,py,pz = getCharCoordinates(PLAYER_PED)
    if type(px) ~= "number" then
        stopAutoDrive("Player coordinates error"); return
    end
    if show_line[0] then draw_line(point.x, point.y, point.z) end
    if not isCharInAnyCar(PLAYER_PED) then
        stopAutoDrive("Vehicle required"); return
    end
    local car = storeCarCharIsInNoSave(PLAYER_PED)
    if not car or car == 0 then
        stopAutoDrive("Vehicle handle error"); return
    end
    local dist = getDistanceBetweenCoords3d(px,py,pz, point.x,point.y,point.z)
    local is_last = playback.playbackIndex >= #playback.currentRouteData
    local arrival_dist = is_last and 1.2 or 8
    if is_last and dist <= arrival_dist then
        stopAutoDrive("Route completed"); return
    elseif not is_last and dist <= arrival_dist then
        playback.playbackIndex = playback.playbackIndex + 1
    else
        local spd = point.speed or autopilot_state.fallbackSpeed
        taskCarDriveToCoord(PLAYER_PED, car, point.x, point.y, point.z, spd, 1, 0, 0, 10, 10)
    end
    autopilot_state.target            = point
    autopilot_state.distanceToTarget  = dist
    if playback.playbackIndex > #playback.currentRouteData then
        stopAutoDrive("Route completed")
    end
end

function startAutoDrive(mode)
    if autopilot.is_playing or not isCharInAnyCar(PLAYER_PED) then return end
    if #current_route > 0 then
        playback.currentRouteData = {}
        for _, p in ipairs(current_route) do table.insert(playback.currentRouteData, p) end
        autopilot.is_playing         = true
        playback.playbackIndex       = 1
        autopilot_state.active[0]    = true
        autopilot_state.showWindow[0]= true
        autopilot_state.currentMode  = mode
    elseif mode == "checkpoint" and manual_checkpoint.active then
        playback.currentRouteData = {{x=manual_checkpoint.x, y=manual_checkpoint.y, z=manual_checkpoint.z, heading=0, speed=autopilot_state.fallbackSpeed, mode="VEHICLE"}}
        autopilot.is_playing         = true
        playback.playbackIndex       = 1
        autopilot_state.active[0]    = true
        autopilot_state.showWindow[0]= true
        autopilot_state.currentMode  = mode
    end
end

function stopAutoDrive(reason)
    autopilot.is_playing              = false
    autopilot_state.active[0]         = false
    autopilot_state.showWindow[0]     = false
    autopilot_state.currentMode       = "none"
    autopilot_state.target            = nil
    playback.playbackIndex            = 1
    if isCharInAnyCar(PLAYER_PED) then
        local car = storeCarCharIsInNoSave(PLAYER_PED)
        if car and car ~= 0 then pcall(clearCarTasks, car) end
    else
        pcall(clearCharTasks, PLAYER_PED)
    end
end

-- == DIALOG AUTO-RESPONSE ==
local function auto_respond(dialog_id, item, button)
    if cargo_config.enabled and auth.authenticated and auth.systemEnabled then
        lua_thread.create(function()
            wait(cargo_config.delay)
            sampSendDialogResponse(dialog_id, button or 1, item or 0, "")
        end)
    end
end

samp_events.onShowDialog = function(id, style, title, btn1, btn2, text)
    if cargo_config.enabled and auth.authenticated and auth.systemEnabled then
        if id == 670 then auto_respond(670, 0, 1); return false end
        if id == 690 then auto_respond(690, cargo_config.cargoType, 1); return false end
    end
    return true
end

-- == CHECKPOINT DETECTION ==
local function get_next_route(cx, cy, cz)
    for i, cp in ipairs(delivery_checkpoints) do
        if dist3d(cx,cy,cz, cp.x,cp.y,cp.z) < 50 then
            local route_name
            if i == 1 then
                auto_system.route1_toggle = not auto_system.route1_toggle
                route_name = auto_system.route1_toggle and "duong_di_1_1" or "duong_di_1"
            elseif i == 2 then
                route_name = (math.random() > 0.5) and "duong_di_2_1" or "duong_di_2"
            end
            local pts = get_route_points(route_name)
            if #pts > 0 then
                current_route = pts
                return "DELIVERY"
            end
        end
    end
    return "PICKUP"
end

samp_events.onSetCheckpoint = function(pos, radius)
    if not auth.authenticated or not auth.systemEnabled then return true end
    manual_checkpoint.x, manual_checkpoint.y, manual_checkpoint.z, manual_checkpoint.active = pos.x, pos.y, pos.z, true
    local next_phase = get_next_route(pos.x, pos.y, pos.z)
    if next_phase == "PICKUP" then
        if auto_system.phase == "WAITING_PICKUP_CHECKPOINT" then
            set_phase("DRIVING_TO_PICKUP_ROUTE")
            current_route = get_route_points("pickup_route")
            if #current_route > 0 then
                startAutoDrive("route")
            else
                set_phase("DRIVING_TO_PICKUP")
                startAutoDrive("checkpoint")
            end
        end
    elseif next_phase == "DELIVERY" then
        set_phase("DRIVING_TO_DELIVERY")
        auto_system.deliveryStarted = true
        if #current_route > 0 then startAutoDrive("route") end
    end
    return true
end

samp_events.onSetRaceCheckpoint = function(type, pos, next, radius)
    return samp_events.onSetCheckpoint(pos, radius)
end

samp_events.onDisableCheckpoint = function()
    if not auth.authenticated or not auth.systemEnabled then return true end
    manual_checkpoint.active = false
    if (auto_system.phase == "DRIVING_TO_PICKUP_ROUTE" or auto_system.phase == "DRIVING_TO_PICKUP") then
        if autopilot_state.currentMode == "route" or autopilot_state.currentMode == "checkpoint" then
            stopAutoDrive("Arrived at pickup point.")
            auto_system.is_waiting      = true
            auto_system.wait_start_time = os.clock() * 1000
            lua_thread.create(function()
                wait(17000)
                auto_system.is_waiting = false
                set_phase("WAITING_DELIVERY_CHECKPOINT")
            end)
        end
    end
    return true
end

samp_events.onDisableRaceCheckpoint = function() return true end

-- == AUTO SYSTEM CONTROL ==
function startAutoSystem()
    if auto_system.running then return end
    if not auth.authenticated or not auth.systemEnabled then
        sampAddChatMessage("{FF0000}[AUTO TRUCK] {FFFFFF}Cannot start. Auth failed or system is offline.", -1)
        if auth.systemEnabled then
            show_window[0] = true
            do_auth()
        end
        return
    end
    if not auth.routesLoaded then
        sampAddChatMessage("{FFFF00}[AUTO TRUCK] {FFFFFF}Routes not loaded yet. Loading...", -1)
        load_routes()
        lua_thread.create(function()
            wait(3000)
            if auth.routesLoaded then
                startAutoSystem()
            else
                sampAddChatMessage("{FF0000}[AUTO TRUCK] {FFFFFF}Failed to load routes. Cannot start.", -1)
            end
        end)
        return
    end
    cargo_config.cargoType  = cargo_type_index
    auto_system.running     = true
    set_phase("FINDING_CAR")
    auto_system.is_waiting      = false
    auto_system.deliveryStarted = false
    init_truck()
    chat_msg("Auto Truck system has STARTED.")
end

function stopAutoSystem()
    reset_auto_system()
    init_truck()
    stopAutoDrive("System stopped")
    chat_msg("Auto Truck system has STOPPED.")
end

function safeRestartSystem()
    if not auth.authenticated or not auth.systemEnabled then
        stopAutoSystem(); return
    end
    local now = os.clock() * 1000
    if (now - auto_system.lastRestartTime) < auto_system.restartCooldown then return end
    auto_system.lastRestartTime = now
    chat_msg("Vehicle lost or trip completed, restarting cycle...")
    stopAutoDrive("System restart")
    reset_auto_system()
    init_truck()
    lua_thread.create(function()
        wait(2000)
        startAutoSystem()
    end)
end

-- == INTRO / SPLASH SCREEN ==
local intro = {
    isFirstTime = true,
    state       = "IDLE",
    startTime   = 0,
    textLines   = {
        {text="Script Auto Truck By KN", alpha=0},
        {text="Get Key Ib Discord",          alpha=0},
        {text="xxxxx083036",               alpha=0},
    },
    imageAlpha = 0,
    durations  = {imageFadeIn=1.5, textFadeIn=1, hold=1},
}
local intro_done = false
local particles = {}
local snowflakes = {}
local particle_cfg = {count=50, connect_dist=110, snow_count=30}

function initializeParticles(w, h)
    particles = {}
    for i = 1, particle_cfg.count do
        table.insert(particles, {x=math.random(0,w), y=math.random(0,h), vx=math.random()-0.5, vy=math.random()-0.5})
    end
end

function initializeSnowflakes(w, h)
    snowflakes = {}
    for i = 1, particle_cfg.snow_count do
        table.insert(snowflakes, {
            x=math.random(0,w), y=math.random(-h,0),
            radius=math.random(1,2.5), speed_y=math.random(0.5,6),
            speed_x_oscillation=math.random(0.1,5),
            oscillation_phase=math.random(0,360),
            alpha=math.random(150,255)/255,
        })
    end
end

function drawParticleBackground()
    local dl    = imgui.GetWindowDrawList()
    local wpos  = imgui.GetWindowPos()
    local wsize = imgui.GetWindowSize()
    for i, p in ipairs(particles) do
        p.x, p.y = p.x + p.vx, p.y + p.vy
        if p.x < 0 or p.x > wsize.x then p.vx = -p.vx end
        if p.y < 0 or p.y > wsize.y then p.vy = -p.vy end
        for j = i, #particles do
            local q = particles[j]
            if q then
                local d = math.sqrt((p.x-q.x)^2 + (p.y-q.y)^2)
                if d < particle_cfg.connect_dist then
                    local alpha = 1 - (d / particle_cfg.connect_dist)
                    dl:AddLine(imgui.ImVec2(wpos.x+p.x, wpos.y+p.y), imgui.ImVec2(wpos.x+q.x, wpos.y+q.y),
                        imgui.GetColorU32(1,1,1, alpha*0.5))
                end
            end
        end
    end
end

function drawSnowflakes()
    local dl   = imgui.GetWindowDrawList()
    local wpos = imgui.GetWindowPos()
    local wsize= imgui.GetWindowSize()
    local t    = os.clock()
    for _, sf in ipairs(snowflakes) do
        sf.y = sf.y + sf.speed_y
        sf.x = sf.x + (math.sin(t * sf.speed_x_oscillation + sf.oscillation_phase) * 5)
        if sf.y > wsize.y then
            sf.x = math.random(0, wsize.x)
            sf.y = math.random(-wsize.y/2, 0)
        end
        dl:AddCircleFilled(imgui.ImVec2(wpos.x+sf.x, wpos.y+sf.y), sf.radius, imgui.GetColorU32(1,1,1,sf.alpha))
    end
end

function renderSplashScreen()
    local elapsed = os.clock() - intro.startTime
    local avail_w = imgui.GetContentRegionAvail().x
    local win_h   = imgui.GetWindowHeight()
    if intro.state == "IMAGE" then
        intro.imageAlpha = math.min(1, elapsed / intro.durations.imageFadeIn)
        if elapsed >= intro.durations.imageFadeIn then
            intro.state     = "TEXT1"
            intro.startTime = os.clock()
        end
    elseif intro.state == "TEXT1" then
        intro.textLines[1].alpha = math.min(1, elapsed / intro.durations.textFadeIn)
        if elapsed >= intro.durations.textFadeIn then
            intro.state = "TEXT2"; intro.startTime = os.clock()
        end
    elseif intro.state == "TEXT2" then
        intro.textLines[2].alpha = math.min(1, elapsed / intro.durations.textFadeIn)
        if elapsed >= intro.durations.textFadeIn then
            intro.state = "TEXT3"; intro.startTime = os.clock()
        end
    elseif intro.state == "TEXT3" then
        intro.textLines[3].alpha = math.min(1, elapsed / intro.durations.textFadeIn)
        if elapsed >= intro.durations.textFadeIn then
            intro.state = "HOLD"; intro.startTime = os.clock()
        end
    elseif intro.state == "HOLD" and elapsed >= intro.durations.hold then
        intro.state = "FINISHED"
    end
    if logo_texture then
        imgui.SetCursorPos(imgui.ImVec2((avail_w - 100) * 0.5, win_h * 0.15))
        imgui.Image(logo_texture, imgui.ImVec2(100, 150), nil, nil, imgui.ImVec4(1,1,1, intro.imageAlpha))
    end
    imgui.SetCursorPosY(win_h * 0.6)
    for _, line in ipairs(intro.textLines) do
        local sz = imgui.CalcTextSize(u8(line.text))
        imgui.SetCursorPosX((avail_w - sz.x) * 0.5)
        imgui.PushStyleColor(imgui.Col.Text, imgui.ImVec4(1,1,1, line.alpha))
        imgui.Text(u8(line.text))
        imgui.PopStyleColor()
    end
end

-- == IMGUI THEME ==
local function apply_theme()
    local s  = imgui.GetStyle()
    local c  = imgui.GetStyle().Colors
    local C  = imgui.Col
    local V4 = imgui.ImVec4
    s.WindowRounding = 8
    s.FrameRounding  = 6
    s.WindowPadding  = imgui.ImVec2(10, 10)
    s.ItemSpacing    = imgui.ImVec2(8, 6)
    c[C.WindowBg]          = V4(0.06, 0.06, 0.06, 0.94)
    c[C.Text]              = V4(0.95, 0.95, 0.95, 1)
    c[C.TextDisabled]      = V4(0.5,  0.5,  0.5,  1)
    c[C.ChildBg]           = V4(0,    0,    0,    0)
    c[C.PopupBg]           = V4(0.08, 0.08, 0.08, 0.94)
    c[C.Border]            = V4(0.43, 0.43, 0.5,  0.5)
    c[C.BorderShadow]      = V4(0,    0,    0,    0)
    c[C.FrameBg]           = V4(0.16, 0.16, 0.16, 1)
    c[C.FrameBgHovered]    = V4(0.24, 0.24, 0.24, 1)
    c[C.FrameBgActive]     = V4(0.28, 0.28, 0.28, 1)
    c[C.TitleBg]           = V4(0.04, 0.04, 0.04, 1)
    c[C.TitleBgActive]     = V4(0.16, 0.16, 0.16, 1)
    c[C.TitleBgCollapsed]  = V4(0,    0,    0,    0.51)
    c[C.MenuBarBg]         = V4(0.14, 0.14, 0.14, 1)
    c[C.ScrollbarBg]       = V4(0.02, 0.02, 0.02, 0.53)
    c[C.ScrollbarGrab]     = V4(0.31, 0.31, 0.31, 1)
    c[C.ScrollbarGrabHovered] = V4(0.41, 0.41, 0.41, 1)
    c[C.ScrollbarGrabActive]  = V4(0.51, 0.51, 0.51, 1)
    c[C.CheckMark]         = V4(0.9,  0.9,  0.9,  1)
    c[C.SliderGrab]        = V4(0.51, 0.51, 0.51, 1)
    c[C.SliderGrabActive]  = V4(0.86, 0.86, 0.86, 1)
    c[C.Button]            = V4(0.25, 0.25, 0.25, 1)
    c[C.ButtonHovered]     = V4(0.35, 0.35, 0.35, 1)
    c[C.ButtonActive]      = V4(0.45, 0.45, 0.45, 1)
    c[C.Header]            = V4(0.3,  0.3,  0.3,  1)
    c[C.HeaderHovered]     = V4(0.4,  0.4,  0.4,  1)
    c[C.HeaderActive]      = V4(0.2,  0.2,  0.2,  1)
    c[C.Separator]         = c[C.Border]
end

-- == MAIN GUI ==
imgui.OnFrame(function()
    return show_window[0] and auth.systemEnabled
end, function()
    apply_theme()
    local win_w = 450
    if intro.state ~= "FINISHED" then
        imgui.SetNextWindowSize(imgui.ImVec2(win_w, 400), imgui.Cond.Always)
        local flags = imgui.WindowFlags.NoTitleBar + imgui.WindowFlags.NoResize + imgui.WindowFlags.NoMove
        if imgui.Begin("SplashScreen", show_window, flags) then
            drawParticleBackground()
            drawSnowflakes()
            renderSplashScreen()
        end
        imgui.End()
        return
    end
    imgui.SetNextWindowSize(imgui.ImVec2(win_w, 0), imgui.Cond.FirstUseEver)
    local flags = imgui.WindowFlags.NoTitleBar + imgui.WindowFlags.NoResize
    if imgui.Begin("Auto Truck", show_window, flags) then
        -- Header
        if logo_texture then
            imgui.Image(logo_texture, imgui.ImVec2(40, 40))
            imgui.SameLine()
        end
        imgui.Text(u8("Auto Truck - KN"))
        imgui.Separator()
        if imgui.BeginTabBar("##tabs") then
            -- === TAB: CONTROL ===
            if imgui.BeginTabItem(get_icon("GAMEPAD") .. u8(" Control")) then
                local half_w = (imgui.GetContentRegionAvail().x - imgui.GetStyle().ItemSpacing.x) / 2
                imgui.Text("Phase: " .. auto_system.phase)
                imgui.Text("Cargo type:")
                imgui.SameLine()
                imgui.SetNextItemWidth(100)
                if imgui.SliderInt("##cargo", imgui.new.int(cargo_type_index), 1, 5) then
                    cargo_type_index = imgui.new.int(cargo_type_index)[0]
                end
                imgui.Checkbox(u8("Show route line"), show_line)
                imgui.Separator()
                local btn_label = auto_system.running and (get_icon("STOP") .. " STOP") or (get_icon("PLAY") .. " START")
                if imgui.Button(btn_label, imgui.ImVec2(half_w * 2, 40)) then
                    if not auth.authenticated then
                        do_auth()
                    else
                        if auto_system.running then stopAutoSystem() else startAutoSystem() end
                    end
                end
                imgui.EndTabItem()
            end
            -- === TAB: AUTH ===
            if imgui.BeginTabItem(get_icon("SHIELD") .. " Auth") then
                imgui.Text("System:")
                imgui.SameLine()
                imgui.TextColored(
                    (auth.systemEnabled and imgui.ImVec4(0,1,0,1)) or imgui.ImVec4(1,0,0,1),
                    auth.statusMsg)
                imgui.Text("Auth Status:")
                imgui.SameLine()
                imgui.TextColored(
                    (auth.authenticated and imgui.ImVec4(0,1,0,1)) or imgui.ImVec4(1,1,0,1),
                    (auth.authenticated and "AUTHENTICATED") or "NOT AUTHENTICATED")
                imgui.Text("Routes:")
                imgui.SameLine()
                imgui.TextColored(
                    (auth.routesLoaded and imgui.ImVec4(0,1,0,1)) or imgui.ImVec4(1,1,0,1),
                    (auth.routesLoaded and "LOADED") or "NOT LOADED")
                imgui.Text("Account: " .. (auth.playerName or "Not identified"))
                if auth.loading then
                    imgui.SameLine()
                    imgui.TextColored(imgui.ImVec4(1,1,0,1), "(Loading...)")
                end
                if auth.authenticated then
                    imgui.Text("Expires on: " .. auth.validUntil)
                    imgui.Text("Remaining: " .. auth.remainingDays .. " days")
                else
                    imgui.TextWrapped("Notice: " .. auth.authMsg)
                end
                imgui.Separator()
                if imgui.Button(get_icon("ROTATE") .. " Refresh Auth", imgui.ImVec2(-1, 25)) then do_auth() end
                if imgui.Button(get_icon("DOWNLOAD") .. " Load Routes", imgui.ImVec2(-1, 25)) then load_routes() end
                imgui.EndTabItem()
            end
            -- === TAB: MUSIC ===
            if imgui.BeginTabItem(get_icon("MUSIC") .. " Music") then
                if not doesFileExist(music_path) then
                    imgui.Text(get_icon("TRIANGLE_EXCLAMATION") .. " Music file not found:")
                    imgui.Text(music_path)
                else
                    imgui.Text(get_icon("COMPACT_DISC") .. " Player: sound.mp3")
                    imgui.Separator()
                    local half = (imgui.GetContentRegionAvail().x - imgui.GetStyle().ItemSpacing.x) / 2
                    if imgui.Button((is_playing and (get_icon("PAUSE") .. " Pause")) or (get_icon("PLAY") .. " Play"), imgui.ImVec2(half, 40)) then
                        togglePlayPause()
                    end
                    imgui.SameLine()
                    if imgui.Button(get_icon("STOP") .. " Stop", imgui.ImVec2(half, 40)) then
                        stopMusic()
                    end
                    imgui.Separator()
                    imgui.Text(get_icon("VOLUME_HIGH") .. " Volume")
                    if imgui.SliderFloat("##volume", music_volume, 0, 1, "%.2f") then
                        if audio_stream then setAudioStreamVolume(audio_stream, music_volume[0]) end
                        saveMusicConfig()
                    end
                end
                imgui.EndTabItem()
            end
            imgui.EndTabBar()
        end
        imgui.Separator()
        imgui.Text("Get Key: DM KN")
        imgui.SameLine(imgui.GetWindowWidth() - 120)
        imgui.Text(u8("Link"))
        if imgui.IsItemClicked() then
            imgui.Link(" https://youtube.com/@nguyencudam?si=ZSGPoVL8Up3cFEG3")
        end
    end
    imgui.End()
end)

-- == FONT INIT ==
imgui.OnInitialize(function()
    imgui.GetIO().IniFilename = nil
    local io  = imgui.GetIO()
    local cfg = imgui.ImFontConfig()
    io.Fonts:AddFontFromMemoryCompressedBase85TTF(fa_icons.get_font_data_base85("solid"), 16 * dpi_scale, cfg, imgui.new.ImWchar[3](fa_icons.min_range, fa_icons.max_range, 0))
    cfg.MergeMode, cfg.PixelSnapH = true, true
    local logo_path = getWorkingDirectory() .. "/resource/kn.png"
    if doesFileExist(logo_path) then
        logo_texture = imgui.CreateTextureFromFile(logo_path)
    end
end)

-- == DIRECTORIES ==
function check_and_create_directories()
    if not doesDirectoryExist("moonloader/resource") then
        pcall(createDirectory, "moonloader/resource")
    end
    if not doesDirectoryExist(getWorkingDirectory() .. "/resource/sound") then
        pcall(createDirectory, getWorkingDirectory() .. "/resource/sound")
    end
end

-- == AUTO RECHECK ==
local function start_recheck()
    lua_thread.create(function()
        while true do
            wait(1800000) -- 30 minutes
            chat_msg("Auto-rechecking auth...")
            do_auth()
            if auth.systemEnabled then load_routes() end
        end
    end)
end

-- == MAIN ==
function main()
    if not isSampLoaded() or not isSampfuncsLoaded() then return end
    while not isSampAvailable() do wait(100) end
    if not check_samp() then return end
    check_and_create_directories()
    sampAddChatMessage("{4CAF50}[Auto Truck] {FFFFFF}Online Auth version loaded!", -1)
    sampAddChatMessage("{4CAF50}[Auto Truck] {FFFFFF}Commands: /truck, /start, /stop", -1)

    -- Initial auth + route load
    lua_thread.create(function()
        wait(5000)
        do_auth()
        wait(2000)
        load_routes()
    end)

    -- Commands
    sampRegisterChatCommand("truck", function()
        show_window[0] = not show_window[0]
        if show_window[0] and intro.isFirstTime then
            intro.state     = "IMAGE"
            intro.startTime = os.clock()
            intro.isFirstTime = false
            intro_done = false
        elseif not show_window[0] then
            intro_done = false
        end
    end)
    sampRegisterChatCommand("start", startAutoSystem)
    sampRegisterChatCommand("stop",  stopAutoSystem)

    start_recheck()

    -- Find car loop
    lua_thread.create(function()
        while true do
            wait(200)
            if auth.systemEnabled and auto_system.running and auto_system.phase == "FINDING_CAR" then
                find_car()
            end
        end
    end)

    -- Watchdog: timeout + teleport detection
    lua_thread.create(function()
        local lx, ly, lz = nil, nil, nil
        local max_dist = 100
        while true do
            wait(1000)
            if auto_system.running then
                local px,py,pz = getCharCoordinates(PLAYER_PED)
                if px then
                    if lx and ly and lz then
                        local d = getDistanceBetweenCoords3d(px,py,pz, lx,ly,lz)
                        if d > max_dist then
                            chat_msg("{FF0000}Teleport detected! Script stopped for safety.")
                            stopAutoSystem()
                        end
                    end
                    lx, ly, lz = px, py, pz
                end
                if auto_system.phase == "FINDING_CAR" then
                    if ((os.clock() * 1000) - auto_system.find_car_start_time) > auto_system.find_car_timeout then
                        chat_msg("{FFFF00}Could not find a vehicle for 60 seconds. Stopping script.")
                        chat_msg("{FFFF00}Please move to an area with trucks and type /start.")
                        stopAutoSystem()
                    end
                end
                if auto_system.phase ~= "IDLE" and auto_system.phase ~= "FINDING_CAR" and not isCharInAnyCar(PLAYER_PED) then
                    safeRestartSystem()
                end
            else
                lx, ly, lz = nil, nil, nil
            end
        end
    end)

    -- Truck boarding detection
    lua_thread.create(function()
        while true do
            wait(1000)
            if auth.systemEnabled and auto_system.running and auto_system.phase == "FINDING_CAR" and isCharInAnyCar(PLAYER_PED) then
                local car = storeCarCharIsInNoSave(PLAYER_PED)
                if getCarModel(car) == truck_config.bensonModelId then
                    init_truck()
                    wait(1000)
                    sampSendChat("/car engine")
                    wait(1000)
                    sampSendChat("/layhang")
                    set_phase("WAITING_PICKUP_CHECKPOINT")
                else
                    taskLeaveAnyCar(PLAYER_PED)
                end
            end
        end
    end)

    -- Autopilot loop
    lua_thread.create(function()
        while true do
            wait(0)
            if auth.systemEnabled and autopilot.is_playing then
                pcall(AutoPilot)
            end
        end
    end)

    wait(-1)
end
