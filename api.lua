local skins_per_page = 16
local S = online_skins.s

local function escape_argument(texture_modifier)
	return texture_modifier:gsub(".", {["\\"] = "\\\\", ["^"] = "\\^", [":"] = "\\:"})
end

function online_skins.set_texture(player, def)
    player_api.set_texture(player, 1, "[png:"..def.base64, true)
    local name = player:get_player_name()
    online_skins.players[name] = def
    local meta = player:get_meta()
    meta:set_int("online_skins_id", def.id)
end

function online_skins.get_preview(base64)
    local skin = "([png:" .. base64 .. ")"
    local modifier = ""

    modifier = modifier .. "([combine:16x32:-16,-12=" .. escape_argument(skin) .. "^[mask:online_skins_body_mask.png)^"
    modifier = modifier .. "([combine:16x32:-4,-8=" .. escape_argument(skin) .. "^[mask:online_skins_head_mask.png)^"
    modifier = modifier .. "([combine:16x32:-36,-8=" .. escape_argument(skin) .. "^[mask:online_skins_head_mask.png)^"
    modifier = modifier .. "([combine:16x32:-44,-12=" .. escape_argument(skin) .. "^[mask:online_skins_left_arm_mask.png)^"
    modifier = modifier .. "([combine:16x32:0,0=" .. escape_argument(skin) .. "^[mask:online_skins_left_leg_mask.png)^"
    modifier = modifier .. "([combine:16x32:-44,-12=" .. escape_argument(skin) .. "^[mask:online_skins_left_arm_mask.png^[transformFX)^"
    modifier = modifier .. "([combine:16x32:0,0=" .. escape_argument(skin) .. "^[mask:online_skins_left_leg_mask.png^[transformFX)"

    modifier = "(" .. modifier .. ")^[resize:64x128^[mask:online_skins_transform.png"
    return escape_argument(modifier)
end

function online_skins.get_formspec(player, page)
    local meta = player:get_meta()
    local skin_id = meta:get_int("online_skins_id")
    local selected_skin = ((skin_id < 1) and 1 or skin_id)

    local total_skins = #online_skins.skins
    local total_pages = math.ceil(total_skins / skins_per_page)
    page = math.max(1, math.min(page or 1, total_pages))

    local start_index = (page - 1) * skins_per_page + 1
    local end_index = math.min(start_index + skins_per_page - 1, total_skins)

    local formspec = "label[0.5,0.45;" .. S("Online Skins") .. "]label[0.5,5.4;" .. S("Page @1 of @2", page, total_pages) .. "]"

    local y = 0.8
    for i = start_index, end_index do
        local skin = online_skins.skins[i]
        local preview = online_skins.get_preview(skin.base64)

        local idx = i - start_index
        local px = 0.5 + (idx % 8) * 1.25
        local py = y + math.floor(idx / 8) * 2.25

        if skin.id == selected_skin then
            formspec = formspec .. "style[online_skins_ID_" .. skin.id .. ";bgcolor=green]"
        end

        formspec = formspec .. "image_button[" .. px .. "," .. py .. ";1,2;" .. preview .. ";online_skins_ID_" .. skin.id .. ";]"
        formspec = formspec .. "tooltip[online_skins_ID_" .. skin.id .. ";" .. S("Skin ID: @1", skin.id) .. "\n\n".. skin.description .. "\n\n" .. S("Likes: @1", skin.likes) .. "\n" .. S("Author: @1", skin.author) .. "]"
    end

    if page > 1 then
        formspec = formspec .. "button[3.25,5.1;1.5,0.5;online_skins_prev_page;" .. S("Previous") .. "]"
    end
    if page < total_pages then
        formspec = formspec .. "button[5,5.1;1.5,0.5;online_skins_next_page;" .. S("Next") .. "]"
    end

    formspec = formspec .. "button_url[7.25,5.1;3,0.5;online_skins_upload_skin;" .. S("Upload your own skin") .. ";" .. ONLINE_SKINS_URL .. "upload]tooltp[online_skins_upload_skin;" .. S("Opens page in browser to upload skin.") .. "]"

    return formspec
end

function online_skins.get_sfinv_formspec(player, page)
    local meta = player:get_meta()
    local skin_id = meta:get_int("online_skins_id")
    local selected_skin = ((skin_id < 1) and 1 or skin_id)

    local total_skins = #online_skins.skins
    local total_pages = math.ceil(total_skins / skins_per_page)
    page = math.max(1, math.min(page or 1, total_pages))

    local start_index = (page - 1) * skins_per_page + 1
    local end_index = math.min(start_index + skins_per_page - 1, total_skins)

    local formspec = "label[5.65,8.5;" .. S("Page @1 of @2", page, total_pages) .. "]"

    for i = start_index, end_index do
        local skin = online_skins.skins[i]
        local preview = online_skins.get_preview(skin.base64)

        local idx = i - start_index
        local px = 0.08 + (idx % 4) * 1.05
        local py = 0.13 + math.floor(idx / 4) * 2.25

        if skin.id == selected_skin then
            formspec = formspec .. "style[online_skins_ID_" .. skin.id .. ";bgcolor=green]"
        end

        formspec = formspec .. "image_button[" .. px .. "," .. py .. ";1.15,2.3;" .. preview .. ";online_skins_ID_" .. skin.id .. ";]"
        formspec = formspec .. "tooltip[online_skins_ID_" .. skin.id .. ";" .. skin.description .. "\n\n" .. S("Author: @1", skin.author) .. "]"
        local hypertext = "<b><big>" .. S("Skin ID: @1", skin.id) .. "</big></b>\n<i>" .. skin.description .. "</i>\n\n" .. S("<b>Likes:</b> @1", skin.likes) .. "\n" .. S("Author: @1", skin.author)
        formspec = formspec .. "hypertext[5,0.63;3,8;description;" .. hypertext .. "]"
    end

    if page > 1 then
        formspec = formspec .. "button[4.5,8.5;1.25,0.5;online_skins_prev_page;" .. S("Previous") .. "]"
    end
    if page < total_pages then
        formspec = formspec .. "button[6.85,8.5;1.25,0.5;online_skins_next_page;" .. S("Next") .. "]"
    end

    formspec = formspec .. "button_url[4.7,0.13;3,0.5;online_skins_upload_skin;" .. S("Upload your own skin") .. ";" .. ONLINE_SKINS_URL .. "upload]tooltp[online_skins_upload_skin;" .. S("Opens page in browser to upload skin.") .. "]"

    return formspec
end