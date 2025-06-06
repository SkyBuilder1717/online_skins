local modname = core.get_current_modname()
local modpath = core.get_modpath(modname)
ONLINE_SKINS_URL = 'http://79.174.62.204/'

online_skins = {
    s = core.get_translator(modname),
    loading = true,
    players = {},
    current_page = {},
    skins = {}
}

local S = online_skins.s

local http = core.request_http_api and core.request_http_api()
if not http then
    core.log("error",
        "Online Skins has no access to the Internet. Please add this mod to secure.http_mods to continue."
    )
    return
end

local function get_skins()
    online_skins.loading = true
    http.fetch({
        url = ONLINE_SKINS_URL .. "api/skins?sort=likes",
        timeout = 5
    },
    function(data)
        if data.completed and data.succeeded then
            online_skins.loading = false
            online_skins.skins = core.parse_json(data.data)
        elseif data.timeout then
            core.log("error",
                "Online Skins has time out connection!"
            )
        elseif not data.succeeded then
            core.log("error",
                "Online Skins has unsuccessful connection! (".. data.code ..")"
            )
        end
    end)
end

local function load()
    core.after(1, function()
        if online_skins.loading then
            load()
        end
    end)
end

local function reload_skins()
    get_skins()
    load()
end

reload_skins()

local function check_for_updates()
    http.fetch({
        url = ONLINE_SKINS_URL .. "api/update",
        timeout = 5
    },
    function(data)
        if data.completed and data.succeeded then
            local update = core.parse_json(data.data)["update"]
            if update then
                core.log("action", "Requested reloading the online skins through checking for updates")
                reload_skins()
            end
        elseif data.timeout then
            core.log("error",
                "Online Skins has time out connection while checking for updates!"
            )
        elseif not data.succeeded then
            core.log("error",
                "Online Skins has unsuccessful connection checking for updates! (".. data.code ..")"
            )
        end
    end)
end

local function check_updates()
    core.after(5, function()
        check_for_updates()
        check_updates()
    end)
end

check_updates()

local old_set_texture = player_api.set_texture
function player_api.set_texture(player, index, texture, onlineskin)
    local player_name = player:get_player_name()
    if not onlineskin then
        online_skins.players[player_name] = nil
    end
    old_set_texture(player, index, texture)
end

dofile(modpath.."/api.lua")

if core.global_exists("unified_inventory") and unified_inventory then
    dofile(modpath.."/unified_inventory.lua")
end
if core.global_exists("sfinv") and sfinv then
    dofile(modpath.."/sfinv.lua")
end

local function fetch_skin(player, skin_id)
    http.fetch({
        url = ONLINE_SKINS_URL .. "api/skins?id=" .. skin_id,
        timeout = 5
    },
    function(data)
        if data.completed and data.succeeded then
            local def = core.parse_json(data.data)[1]
            if not def then
                fetch_skin(player, 1)
            else
                online_skins.set_texture(player, def)
            end
        elseif data.timeout then
            core.log("error",
                "Online Skins has time out connection while getting skin ID "..skin_id.."!"
            )
        elseif not data.succeeded then
            core.log("error",
                "Online Skins has unsuccessful connection while getting skin ID "..skin_id.."! (".. data.code ..")"
            )
        end
    end)
end

core.register_on_joinplayer(function(player)
    local meta = player:get_meta()
    local skin_id = meta:get_int("online_skins_id")
    if skin_id > 0 then
        fetch_skin(player, skin_id)
    end
end)

core.register_chatcommand("reload_online_skins", {
    privs = {server = true},
    description = S("Force loaded skins to reload."),
    func = function(name)
        reload_skins()
        core.log("action", "Requested reloading the online skins by " .. name)
        return true, S("Reloading...")
    end
})