local modname = core.get_current_modname()
local modpath = core.get_modpath(modname)
ONLINE_SKINS_URL = 'https://skybuilder.synology.me/onlineskins/'

local set = core.settings

online_skins = {
    version = "0.7",
    translate = core.get_translator(modname),
    loading = true,
    players = {},
    current_page = {},
    skins = {},
    pfps = set:get_bool("online_skins.skin_author_pfp", false),
    users = {}
}
local mineclonia = core.get_modpath("mcl_player") and core.global_exists("mcl_player") and core.get_modpath("mcl_armor") and core.global_exists("mcl_armor")

local S = online_skins.translate

local function log(msg, type)
    core.log((type or "action"), "[Online Skins] " .. msg)
end

local http = core.request_http_api and core.request_http_api()
if not http then
    log("No HTTP access! Check your internet connection or add this mod into `secure.http_mods`.", "error")
    return
end

local function time(w)
    log("Time out connection while "..w.."!", "error")
end

local function success(w, data)
    log("Unsuccessful connection while "..w.."! ("..data.code..")", "error")
end

local function get_skins()
    online_skins.loading = true
    http.fetch({
        url = ONLINE_SKINS_URL .. "api/skins?first=" .. ((mineclonia) and 77 or 1) .. "&sort=likes",
        timeout = 5
    },
    function(data)
        if data.completed and data.succeeded then
            online_skins.loading = false
            online_skins.skins = core.parse_json(data.data)
            http.fetch({
                url = ONLINE_SKINS_URL .. "api/users",
                timeout = 5
            },
            function(data)
                if data.completed and data.succeeded then
                    online_skins.users = core.parse_json(data.data)
                elseif data.timeout then
                    time("getting users")
                elseif not data.succeeded then
                    success("getting users", data)
                end
            end)
        elseif data.timeout then
            time("getting skins")
        elseif not data.succeeded then
            success("getting skins", data)
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
                log("Requested reloading the skins through checking for updates")
                reload_skins()
            end
        elseif data.timeout then
            time("checking for new skins")
        elseif not data.succeeded then
            success("checking for new skins", data)
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

local function fetch_skin(player, skin_id)
    http.fetch({
        url = ONLINE_SKINS_URL .. "api/skins?id=" .. skin_id,
        timeout = 5
    },
    function(data)
        if data.completed and data.succeeded then
            local def = core.parse_json(data.data)[1]
            if not def then
                fetch_skin(player, ((mineclonia) and 77 or 1))
            else
                online_skins.set_texture(player, def)
            end
        elseif data.timeout then
            time("getting skin ID "..skin_id)
        elseif not data.succeeded then
            success("getting skin ID "..skin_id, data)
        end
    end)
end

local function alternate_skin(player)
    local meta = player:get_meta()
    local skin_id = meta:get_int("online_skins_id")
    if skin_id > 0 then
        fetch_skin(player, skin_id)
    end
end

core.register_on_joinplayer(function(player)
    local name = player:get_player_name()
    http.fetch({
        url = ONLINE_SKINS_URL .. "api/skin?nickname=" .. name,
        timeout = 5
    },
    function(data)
        if data.completed and data.succeeded then
            local json = core.parse_json(data.data)
            if json.error then
                alternate_skin(player)
            elseif json.skin then
                fetch_skin(player, json.skin)
            end
        elseif data.timeout then
            alternate_skin(player)
            time("getting cloud skin for "..name)
        elseif not data.succeeded then
            alternate_skin(player)
            success("getting cloud skin for "..name)
        end
    end)
end)

core.after(1, function()
    log("Checking for updates...")
    http.fetch({
        url = ONLINE_SKINS_URL .. "api/version",
        timeout = 5
    },
    function(data)
        if data.completed and data.succeeded then
            local ver = core.parse_json(data.data).version
            local veo = online_skins.version
            if ver then
                if not (ver == veo) then
                    log("New update found! (New: "..ver.."; Old: "..veo..") Download new update to fix bugs and get new features!", "warning")
                else
                    log("No new updates.")
                end
            end
        elseif data.timeout then
            time("checking last version")
        elseif not data.succeeded then
            success("checking last version", data)
        end
    end)
end)

if core.get_modpath("player_api") and core.global_exists("player_api") then
    local old_set_texture = player_api.set_texture
    function player_api.set_texture(player, index, texture, onlineskin)
        local player_name = player:get_player_name()
        if not onlineskin then
            online_skins.players[player_name] = nil
        end
        old_set_texture(player, index, texture)
    end

    dofile(modpath.."/models.lua")
elseif mineclonia then
    local old_player_set_skin = mcl_player.player_set_skin
    function mcl_player.player_set_skin(player, texture, onlineskin)
        if not onlineskin then
            online_skins.players[player:get_player_name()] = nil
        end
        old_player_set_skin(player, texture)
    end
end

core.register_chatcommand("onlineskins", {
    params = "[<reload>]",
    description = "Opens menu with online skins.",
    func = function(name, params)
        local param = params:gsub("%s+", "")
        if param == "reload" then
            reload_skins()
            core.log("action", "Requested reloading skins by " .. name)
            log("Requested reloading skins by " .. name)
            return true, S("Reloading...")
        elseif param == "verify" then
            core.show_formspec(name, "onlineskins:verify", online_skins.form())
            return true
        elseif param == "" then
            core.show_formspec(name, "onlineskins:skins", online_skins.get_formspec(core.get_player_by_name(name), online_skins.current_page[name] or 1, "sfinv"))
            return true
        else
            return false
        end
    end
})

core.register_on_player_receive_fields(function(player, formname, fields)
    local name = player:get_player_name()
    if formname == "onlineskins:skins" then
        online_skins.current_page[name] = online_skins.current_page[name] or 1

        if fields.quit then
            online_skins.current_page[name] = 1
            return
        elseif fields.online_skins_prev_page then
            online_skins.current_page[name] = online_skins.current_page[name] - 1
        elseif fields.online_skins_next_page then
            online_skins.current_page[name] = online_skins.current_page[name] + 1
        else
            for _, def in pairs(online_skins.skins) do
                if fields["online_skins_ID_"..def.id] then
                    online_skins.set_texture(player, def)
                    online_skins.sync_set_skin(name, def.id)
                end
            end
        end

        core.show_formspec(name, "onlineskins:skins", online_skins.get_formspec(player, online_skins.current_page[name] or 1, "sfinv"))
    elseif (formname == "onlineskins:verify") and fields.login then
        http.fetch({
            url = ONLINE_SKINS_URL .. "api/verify?username=" .. fields.username .. "&password=" .. fields.password .. "&nickname=" .. name,
            timeout = 5
        },
        function(data)
            if data.completed and data.succeeded then
                local json = core.parse_json(data.data)
                if json.error then
                    core.show_formspec(name, "onlineskins:verify", online_skins.form(json.error))
                elseif json.success then
                    core.chat_send_player(name, S("Nickname verified!"))
                    core.close_formspec(name, "onlineskins:verify")
                end
            elseif data.timeout then
                time("verifying nickname for "..name)
            elseif not data.succeeded then
                success("verifying nickname for "..name, data)
            end
        end)
    end
end)

function online_skins.sync_set_skin(name, id)
    http.fetch({
        url = ONLINE_SKINS_URL .. "api/set?nickname=" .. name .. "&skin=" .. id,
        timeout = 5
    },
    function(data)
        if data.completed and data.succeeded then
            local json = core.parse_json(data.data)
            if json.error then
                core.log("warning", "Failed to set cloud skin: " .. json.error)
            elseif json.success then
                core.chat_send_player(name, S("Cloud skin saved: ID @1"))
            end
        elseif data.timeout then
            time("set cloud skin ID "..id)
        elseif not data.succeeded then
            success("set cloud skin ID "..id, data)
        end
    end)
end

dofile(modpath.."/api.lua")
if core.get_modpath("unified_inventory") and core.global_exists("unified_inventory") then
    dofile(modpath.."/unified_inventory.lua")
end
if core.get_modpath("sfinv") and core.global_exists("sfinv") then
    dofile(modpath.."/sfinv.lua")
end