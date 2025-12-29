local skins_per_page = 16
local S = online_skins.translate
local F = core.formspec_escape

local ESCAPE_MAP = {
    ["\\"] = "\\\\",
    ["^"]  = "\\^",
    [":"]  = "\\:"
}

local function escape_argument(str)
    return str:gsub("[\\^:]", ESCAPE_MAP)
end

function online_skins.rebuild_indexes()
    for _, skin in ipairs(online_skins.skins or {}) do
        online_skins.skins_by_id[skin.id] = skin
    end
    for _, user in ipairs(online_skins.users or {}) do
        online_skins.users_by_name[user.username] = user
    end
end

function online_skins.get_user(username)
    return online_skins.users_by_name[username]
end

function online_skins.set_texture(player, def)
    local width  = def.size.x
    local height = def.size.y

    local png = string.format("[png:%s", def.base64)
    local texture = png

    if width == height then
        height = math.floor(height / 2)
        texture = escape_argument(string.format(
            "([combine:%dx%d:0,0=%s)",
            width, height, png
        ))
    end

    local name = player:get_player_name()
    online_skins.players[name] = def

    if core.get_modpath("3d_armor") and core.global_exists("player_api") then
        player_api.set_model(
            player,
            def.slim and "3d_armor_character_slim.glb" or "3d_armor_character.b3d"
        )
        armor.textures[name].skin = texture
        armor:update_player_visuals(player)

    elseif core.get_modpath("player_api") then
        player_api.set_model(
            player,
            def.slim and "character_slim.glb" or "character.b3d"
        )
        player_api.set_texture(player, 1, texture, true)

    elseif core.get_modpath("mcl_player") and core.get_modpath("mcl_armor") then
        mcl_player.player_set_skin(player, texture, true)
        mcl_player.player_set_model(
            player,
            def.slim and "mcl_armor_character_female.b3d" or "mcl_armor_character.b3d"
        )
    end

    player:get_meta():set_int("online_skins_id", def.id)
end

function online_skins.get_preview(def)
    local slim = def.slim
    local width = def.size.x
    local height = def.size.y
    local skin = string.format("[png:%s", def.base64)
    if width == height then
        height = math.floor(height / 2)
        skin = string.format("[combine:%sx%s:0,0=%s", width, height, escape_argument(string.format("(%s)", skin)))
    end
    skin = string.format("(%s)", skin)
    local modifier = ""

    local sx = width / 64
    local sy = height / 32

    local so = slim and sx or 0
    local sa = slim and "online_skins_slim_arm_mask.png" or "online_skins_arm_mask.png"

    skin = escape_argument(skin)

    modifier = modifier .. string.format("([combine:%sx%s:%s,%s=%s^[mask:online_skins_body_mask.png)^", 16*sx, 32*sy, -16*sx, -12*sy, skin)
    modifier = modifier .. string.format("([combine:%sx%s:%s,%s=%s^[mask:online_skins_head_mask.png)^", 16*sx, 32*sy, -4*sx, -8*sy, skin)
    modifier = modifier .. string.format("([combine:%sx%s:%s,%s=%s^[mask:online_skins_head_mask.png)^", 16*sx, 32*sy, -36*sx, -8*sy, skin)
    modifier = modifier .. string.format("([combine:%sx%s:%s,%s=%s^[mask:%s)^", 16*sx, 32*sy, -44*sx+so, -12*sy, skin, sa)
    modifier = modifier .. string.format("([combine:%sx%s:0,0=%s^[mask:online_skins_leg_mask.png)^", 16*sx, 32*sy, skin)
    modifier = modifier .. string.format("([combine:%sx%s:%s,%s=%s^[mask:%s^[transformFX)^", 16*sx, 32*sy, -44*sx+so, -12*sy, skin, sa)
    modifier = modifier .. string.format("([combine:%sx%s:0,0=%s^[mask:online_skins_leg_mask.png^[transformFX)", 16*sx, 32*sy, skin)

    modifier = string.format(
        "(%s)^[resize:%sx%s^[mask:online_skins_transform.png",
        modifier,
        width,
        height
    )
    return escape_argument(modifier)
end

function online_skins.unified_inventory(page, pages, start_i, end_i, selected)
    local fs = {
        string.format("label[0.5,0.45;%s]", F(S("Online Skins"))),
        string.format("label[0.5,5.4;%s]", F(S("Page @1 of @2", page, pages)))
    }

    for i = start_i, end_i do
        local skin = online_skins.skins[i]
        local idx  = i - start_i
        local px   = 0.5 + (idx % 8) * 1.25
        local py   = 0.8 + math.floor(idx / 8) * 2.25

        if skin.id == selected then
            fs[#fs+1] = string.format("style[online_skins_ID_%d;bgcolor=green]", skin.id)
        end

        fs[#fs+1] = string.format(
            "image_button[%f,%f;1,2;%s;online_skins_ID_%d;]",
            px, py,
            online_skins.get_preview(skin),
            skin.id
        )

        fs[#fs+1] = string.format(
            "tooltip[online_skins_ID_%d;%s\n\n%s\n\n%s\n%s]",
            skin.id,
            F(S("Skin ID: @1", skin.id)),
            skin.description,
            F(S("Likes: @1", skin.likes)),
            F(S("Author: @1", skin.author))
        )
    end

    if page > 1 then
        fs[#fs+1] = string.format("button[3.25,5.1;1.5,0.5;online_skins_prev_page;%s]", F(S("Previous")))
    end
    if page < pages then
        fs[#fs+1] = string.format("button[5,5.1;1.5,0.5;online_skins_next_page;%s]", F(S("Next")))
    end

    fs[#fs+1] = string.format(
        "button_url[7.25,5.1;3,0.5;online_skins_upload_skin;%s;%s]",
        F(S("Upload your own skin")),
        string.format("%s/upload", ONLINE_SKINS_URL)
    )

    return table.concat(fs)
end

function online_skins.sfinv(page, pages, start_i, end_i, selected)
    local fs = {
        "size[8,9.1]",
        string.format("label[5.65,8.5;%s]", F(S("Page @1 of @2", page, pages)))
    }

    local selected_def = online_skins.skins_by_id and online_skins.skins_by_id[selected]
    if selected_def then
        if online_skins.pfps then
            local user = online_skins.users_by_name and online_skins.users_by_name[selected_def.author]
            if user and user.base64 then
                fs[#fs + 1] = string.format(
                    "image[4.7,0.85;1.5,1.5;%s]",
                    core.formspec_escape(string.format("[png:%s", user.base64))
                )
            end
        end

        local hyper = {
            core.global_exists("mcl_formspec") and
                string.format("<style color='%s'>", mcl_formspec.label_color) or "",
            string.format("<b><big>%s</big></b>", F(S("Skin ID: @1", selected_def.id))),
            "\n",
            string.format("<i>%s</i>", selected_def.description),
            "\n\n",
            F(S("<b>Likes:</b> @1", selected_def.likes)),
            "\n",
            F(S("Author: @1", selected_def.author))
        }

        if online_skins.pfps then
            fs[#fs + 1] = string.format(
                "hypertext[5,2.2;3,6.5;description;%s]style[online_skins_ID_%d;bgcolor=green]",
                table.concat(hyper),
                selected_def.id
            )
        else
            fs[#fs + 1] = string.format(
                "hypertext[5,0.7;3,8;description;%s]style[online_skins_ID_%d;bgcolor=green]",
                table.concat(hyper),
                selected_def.id
            )
        end
    end

    for i = start_i, end_i do
        local skin = online_skins.skins[i]
        local idx = i - start_i
        local px = 0.08 + (idx % 4) * 1.05
        local py = 0.13 + math.floor(idx / 4) * 2.25

        if skin.id == selected then
            fs[#fs + 1] = string.format("style[online_skins_ID_%d;bgcolor=green]", skin.id)
        end

        fs[#fs + 1] = string.format(
            "image_button[%f,%f;1,2;%s;online_skins_ID_%d;]",
            px,
            py,
            online_skins.get_preview(skin),
            skin.id
        )

        fs[#fs + 1] = string.format(
            "tooltip[online_skins_ID_%d;%s\n\n%s]",
            skin.id,
            skin.description,
            F(S("Author: @1", skin.author))
        )
    end

    if page > 1 then
        fs[#fs + 1] = string.format(
            "button[4.5,8.5;1.25,0.5;online_skins_prev_page;%s]",
            F(S("Previous"))
        )
    end

    if page < pages then
        fs[#fs + 1] = string.format(
            "button[6.85,8.5;1.25,0.5;online_skins_next_page;%s]",
            F(S("Next"))
        )
    end

    fs[#fs + 1] = string.format(
        "button_url[4.7,0.13;3,0.5;online_skins_upload_skin;%s;%s]",
        F(S("Upload your own skin")),
        string.format("%s/upload", ONLINE_SKINS_URL)
    )

    return table.concat(fs)
end

function online_skins.form(message)
    local fs = {
        "formspec_version[6]",
        "size[10.5,6.25]",
        string.format("field[0.2,0.5;10.1,1.4;username;%s;]", F(S("Username"))),
        string.format("pwdfield[0.2,2.5;10.1,1.4;password;%s]", F(S("Password"))),
        string.format("button[0.2,4.5;10.1,1.4;login;%s]", F(S("Verify nickname"))),
        string.format("label[0.2,4.2;%s]", message or "")
    }
    return table.concat(fs)
end

function online_skins.get_formspec(player, page, interface)
    local meta = player:get_meta()
    local skin_id = meta:get_int("online_skins_id")
    local selected = (skin_id < 1)
        and (core.global_exists("mcl_armor") and 77 or 1)
        or skin_id

    local total = #online_skins.skins
    local pages = math.max(1, math.ceil(total / skins_per_page))
    page = math.max(1, math.min(page or 1, pages))

    local start_i = (page - 1) * skins_per_page + 1
    local end_i   = math.min(start_i + skins_per_page - 1, total)

    return online_skins[interface](page, pages, start_i, end_i, selected)
end