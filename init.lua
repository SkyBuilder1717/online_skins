local modname = core.get_current_modname()
local modpath = core.get_modpath(modname)
ONLINE_SKINS_URL = "https://skybuilder.synology.me/onlineskins"

local settings = core.settings

online_skins = {
    version = "0.8.4",
    translate = core.get_translator(modname),
    loading = true,
    players = {},
    current_page = {},
    skins = {},
    pfps = settings:get_bool("online_skins.skin_author_pfp", false),
    users = {},
    skins_by_id = {},
    users_by_name = {},
    preview_cache = {}
}

local mineclonia =
    core.get_modpath("mcl_player")
    and core.global_exists("mcl_player")
    and core.get_modpath("mcl_armor")
    and core.global_exists("mcl_armor")

local S = online_skins.translate

local function log(msg, t)
    core.log(t or "action", string.format("[Online Skins] %s", msg))
end

local http = core.request_http_api and core.request_http_api()
if not http then
    log("No HTTP access! Check your internet connection or add this mod into `secure.http_mods`.", "error")
    return
end

local function time(w)
    log(string.format("Time out connection while %s!", w), "error")
end

local function success(w, data)
    log(string.format("Unsuccessful connection while %s! (%s)", w, data.code), "error")
end

local function get_skins()
    online_skins.loading = true
    http.fetch({
        url = string.format(
            "%s/api/v1/skins/?first=%d&sort=likes",
            ONLINE_SKINS_URL,
            mineclonia and 77 or 1
        ),
        timeout = 5
    }, function(data)
        if data.completed and data.succeeded then
            online_skins.loading = false
            online_skins.skins = core.parse_json(data.data)
            http.fetch({
                url = string.format("%s/api/v1/users/", ONLINE_SKINS_URL),
                timeout = 5
            }, function(data2)
                if data2.completed and data2.succeeded then
                    online_skins.users = core.parse_json(data2.data)
                elseif data2.timeout then
                    time("getting users")
                elseif not data2.succeeded then
                    success("getting users", data2)
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
        url = string.format("%s/api/v1/update/", ONLINE_SKINS_URL),
        timeout = 5
    }, function(data)
        if data.completed and data.succeeded then
            local update = core.parse_json(data.data).update
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
        url = string.format("%s/api/v1/skins/?id=%d", ONLINE_SKINS_URL, skin_id),
        timeout = 5
    }, function(data)
        if data.completed and data.succeeded then
            local def = core.parse_json(data.data)[1]
            if not def then
                fetch_skin(player, mineclonia and 77 or 1)
            else
                online_skins.set_texture(player, def)
            end
        elseif data.timeout then
            time(string.format("getting skin ID %d", skin_id))
        elseif not data.succeeded then
            success(string.format("getting skin ID %d", skin_id), data)
        end
    end)
end

local function alternate_skin(player)
    local meta = player:get_meta()
    if not meta then return end
    local skin_id = meta:get_int("online_skins_id")
    if skin_id > 0 then
        fetch_skin(player, skin_id)
    end
end

core.register_on_joinplayer(function(player)
    local name = player:get_player_name()
    http.fetch({
        url = string.format("%s/api/v1/skin/?nickname=%s", ONLINE_SKINS_URL, name),
        timeout = 5
    }, function(data)
        if data.completed and data.succeeded then
            local json = core.parse_json(data.data)
            if json.error then
                alternate_skin(player)
            elseif json.skin then
                fetch_skin(player, json.skin)
            end
        elseif data.timeout then
            alternate_skin(player)
            time(string.format("getting cloud skin for %s", name))
        elseif not data.succeeded then
            alternate_skin(player)
            success(string.format("getting cloud skin for %s", name), data)
        end
    end)
end)

core.after(1, function()
    log("Checking for updates...")
    http.fetch({
        url = string.format("%s/api/v1/version/", ONLINE_SKINS_URL),
        timeout = 5
    }, function(data)
        if data.completed and data.succeeded then
            local json = core.parse_json(data.data)
            local ver = json.version
            local old = online_skins.version
            if ver and ver ~= old then
                log(
                    string.format(
                        "New update found! (New: %s; Old: %s) Download new update to fix bugs and get new features!",
                        ver,
                        old
                    ),
                    "warning"
                )
            elseif ver then
                log("No new updates.")
            end
        elseif data.timeout then
            time("checking last version")
        elseif not data.succeeded then
            success("checking last version", data)
        end
    end)
end)

if core.get_modpath("player_api") and core.global_exists("player_api") then
    local old = player_api.set_texture
    function player_api.set_texture(player, index, texture, onlineskin)
        if not onlineskin then
            online_skins.players[player:get_player_name()] = nil
        end
        old(player, index, texture)
    end
    dofile(string.format("%s/models.lua", modpath))
elseif mineclonia then
    local old = mcl_player.player_set_skin
    function mcl_player.player_set_skin(player, texture, onlineskin)
        if not onlineskin then
            online_skins.players[player:get_player_name()] = nil
        end
        old(player, texture)
    end
end

core.register_chatcommand("onlineskins", {
    params = "[<reload | verify>]",
    func = function(name, params)
        local p = params:gsub("%s+", "")
        if p == "reload" then
            reload_skins()
            log(string.format("Requested reloading skins by %s", name))
            return true, S("Reloading...")
        elseif p == "verify" then
            core.show_formspec(name, "onlineskins:verify", online_skins.form())
            return true
        elseif p == "" then
            core.show_formspec(
                name,
                "onlineskins:skins",
                online_skins.get_formspec(
                    core.get_player_by_name(name),
                    online_skins.current_page[name] or 1,
                    "sfinv"
                )
            )
            return true
        end
        return false
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
            for _, def in ipairs(online_skins.skins) do
                if fields[string.format("online_skins_ID_%d", def.id)] then
                    online_skins.sync_set_skin(name, def.id)
                    online_skins.set_texture(player, def)
                end
            end
        end
        core.show_formspec(
            name,
            "onlineskins:skins",
            online_skins.get_formspec(
                player,
                online_skins.current_page[name],
                "sfinv"
            )
        )
    elseif formname == "onlineskins:verify" and fields.login then
        http.fetch({
            url = string.format(
                "%s/api/v1/verify/?username=%s&password=%s&nickname=%s",
                ONLINE_SKINS_URL,
                fields.username,
                fields.password,
                name
            ),
            timeout = 5
        }, function(data)
            if data.completed and data.succeeded then
                local json = core.parse_json(data.data)
                if json.error then
                    core.show_formspec(name, "onlineskins:verify", online_skins.form(json.error))
                elseif json.success then
                    core.chat_send_player(name, S("Nickname verified!"))
                    core.close_formspec(name, "onlineskins:verify")
                end
            elseif data.timeout then
                time(string.format("verifying nickname for %s", name))
            elseif not data.succeeded then
                success(string.format("verifying nickname for %s", name), data)
            end
        end)
    end
end)

function online_skins.sync_set_skin(name, id)
    local player = core.get_player_by_name(name)
    if not player then return end
    local meta = player:get_meta()
    local current = meta:get_int("online_skins_id")
    if current < 1 or current == id then return end
    http.fetch({
        url = string.format(
            "%s/api/v1/set/?nickname=%s&skin=%d",
            ONLINE_SKINS_URL,
            name,
            id
        ),
        timeout = 5
    }, function(data)
        if data.completed and data.succeeded then
            local json = core.parse_json(data.data)
            if json.error then
                core.log("warning", string.format("Failed to set cloud skin: %s", json.error))
            elseif json.success then
                core.chat_send_player(name, S("Cloud skin saved: ID @1", id))
            end
        elseif data.timeout then
            time(string.format("set cloud skin ID %d", id))
        elseif not data.succeeded then
            success(string.format("set cloud skin ID %d", id), data)
        end
    end)
end

dofile(string.format("%s/api.lua", modpath))
if core.get_modpath("unified_inventory") and core.global_exists("unified_inventory") then
    dofile(string.format("%s/unified_inventory.lua", modpath))
end
if core.get_modpath("sfinv") and core.global_exists("sfinv") then
    dofile(string.format("%s/sfinv.lua", modpath))
end
