local S = online_skins.s

sfinv.register_page("online_skins:browser", {
	title = S("Online Skins"),
	get = function(self, player, context)
        local name = player:get_player_name()
		return sfinv.make_formspec(player, context, online_skins.get_formspec(player, online_skins.current_page[name] or 1, "sfinv"))
	end,
	on_player_receive_fields = function(self, player, context, fields)
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
                    online_skins.set_texture(player, def)
                end
            end
        end
        sfinv.set_player_inventory_formspec(player)
	end
})
