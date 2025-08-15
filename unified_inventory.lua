local S = online_skins.translate

unified_inventory.register_page("online_skins", {
	get_formspec = function(player, perplayer_formspec)
        local name = player:get_player_name()
		return {formspec=perplayer_formspec.standard_inv_bg..online_skins.get_formspec(player, online_skins.current_page[name] or 1, "unified_inventory")}
	end,
})

unified_inventory.register_button("online_skins", {
	type = "image",
	image = "online_skins_button.png",
	tooltip = S("Online Skins")
})

core.register_on_player_receive_fields(function(player, formname, fields)
    if formname ~= "" then
		return
	end
    local name = player:get_player_name()
    online_skins.current_page[name] = online_skins.current_page[name] or 1

    if fields.quit then
        online_skins.current_page[name] = 1
    elseif fields.online_skins_prev_page then
        online_skins.current_page[name] = online_skins.current_page[name] - 1
    elseif fields.online_skins_next_page then
        online_skins.current_page[name] = online_skins.current_page[name] + 1
    else
        for _, def in pairs(online_skins.skins) do
            if fields["online_skins_ID_"..def.id] then
                online_skins.sync_set_skin(name, def.id)
                online_skins.set_texture(player, def)
            end
        end
    end
    unified_inventory.set_inventory_formspec(player, "online_skins")
end)
