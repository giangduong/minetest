local function get_sorted_servers(username,pass)
	local servers = {
		fav = {},
		public = {},
		incompatible = {}
	}

	local favs = serverlistmgr.get_favorites(username,pass)
	local taken_favs = {}
	local result = menudata.search_result or serverlistmgr.servers
	for _, server in ipairs(result) do
		server.is_favorite = false
		for index, fav in ipairs(favs) do
			if server.address == fav.address and server.port == fav.port then
				taken_favs[index] = true
				server.is_favorite = true
				break
			end
		end
		server.is_compatible = is_server_protocol_compat(server.proto_min, server.proto_max)
		if server.is_favorite then
			table.insert(servers.fav, server)
		elseif server.is_compatible then
			table.insert(servers.public, server)
		else
			table.insert(servers.incompatible, server)
		end
	end

	if not menudata.search_result then
		for index, fav in ipairs(favs) do
			if not taken_favs[index] then
				table.insert(servers.fav, fav)
			end
		end
	end

	return servers
end



local function set_selected_server(tabdata, idx, server, username,pass)
	-- reset selection
	if idx == nil or server == nil then
		tabdata.selected = nil

		core.settings:set("address", "")
		core.settings:set("remote_port", "30000")
		return
	end

	local address = server.address
	local port    = server.port
	gamedata.serverdescription = server.description

	gamedata.fav = false
	for _, fav in ipairs(serverlistmgr.get_favorites(username,pass)) do
		if address == fav.address and port == fav.port then
			gamedata.fav = true
			break
		end
	end

	if address and port then
		core.settings:set("address", address)
		core.settings:set("remote_port", port)
	end
	tabdata.selected = idx
end





local function login_formspec(dialogdata)
	
	local retval = "size[12,6]"..
        "label[0.25,0.25;" .. fgettext("Welcome:").. dialogdata.username .. "]" ..
        "button[0.25,4.5;2.5,0.75;btn_login;" .. fgettext("Join") .. "]"..
		"field[0,0;0,0;te_address;;" ..
			core.formspec_escape(core.settings:get("address")) .. "]" ..
		"field[0,0;0,0;te_port;;" ..
			core.formspec_escape(core.settings:get("remote_port")) .. "]" ..
		"tablecolumns[" ..
		"image,tooltip=" .. fgettext("") .. "," ..
		
		"5=" .. core.formspec_escape(defaulttexturedir .. "server_favorite.png") .. "," ..
		"6=" .. core.formspec_escape(defaulttexturedir .. "server_public.png") .. "," ..
		"7=" .. core.formspec_escape(defaulttexturedir .. "server_incompatible.png") .. ";" ..
		"color,span=1;" ..
		"text,align=inline;"..
		"color,span=1;" ..
		"text,align=inline,width=0;" ..
		"image,tooltip=" .. fgettext("") .. "," ..
		
		"align=inline,padding=0.25,width=0;" ..
		
		"image,tooltip=" .. fgettext("") .. "," ..
		
		"align=inline,padding=0.25,width=0;" ..
		"color,align=inline,span=1;" ..
		"text,align=inline,padding=1]" ..
		"table[0.25,1;9.25,3;servers;"
        
	
	local servers = get_sorted_servers(dialogdata.username,dialogdata.pass)

	local dividers = {
		fav = "5,#ffff00," .. fgettext("Pythaverse list (Please select to join)") .. ",,,0,0,,",
	}
	--local order = {"fav", "public", "incompatible"}
	local order = {"fav"}

	dialogdata.lookup = {} -- maps row number to server
	local rows = {}
	for _, section in ipairs(order) do
		local section_servers = servers[section]
		if next(section_servers) ~= nil then
			rows[#rows + 1] = dividers[section]
			for _, server in ipairs(section_servers) do
				dialogdata.lookup[#rows + 1] = server
				rows[#rows + 1] = render_serverlist_row(server)
			end
		end
	end

	retval = retval .. table.concat(rows, ",")


	return retval, "size[15.5,9,true]real_coordinates[true]"
end

--------------------------------------------------------------------------------
local function login_buttonhandler(this, fields)
	-- this.data.name = fields.name
	-- this.data.error = nil
	-- core.log(fields.te_address)
	
	-- core.log(tonumber(fields.te_port))
	if fields.servers then

		local event = core.explode_table_event(fields.servers)
		local server = this.data.lookup[event.row]
		-- core.log(server.port)
		-- core.log(server.address)
		if server then
			if event.type == "DCL" then
				if not is_server_protocol_compat_or_error(
							server.proto_min, server.proto_max) then
					return true
				end

				gamedata.address    = server.address
				gamedata.port       = server.port
				gamedata.playername = this.data.username
				gamedata.selected_world = 0

				if fields.password then
					gamedata.password = fields.password
				end

				gamedata.servername        = server.name
				gamedata.serverdescription = server.description

				if gamedata.address and gamedata.port then
					core.settings:set("address", gamedata.address)
					core.settings:set("remote_port", gamedata.port)
					core.start()
				end
				return true
			end
			if event.type == "CHG" then
				set_selected_server(this.data, event.row, server,this.data.username,this.data.pass)
				return true
			end
		end
	end

	if (fields.btn_login) then
		gamedata.playername = this.data.username
		gamedata.password   = ""
		--gamedata.playername = "liemnn"
		
		--gamedata.password   = "dtt@123"
		gamedata.address    = fields.te_address
		gamedata.port       = tonumber(fields.te_port)

		local enable_split_login_register = core.settings:get_bool("enable_split_login_register")
		gamedata.allow_login_or_register = enable_split_login_register and "login" or "any"
		gamedata.selected_world = 0

		local idx = core.get_table_index("servers")
		local server = idx and this.data.lookup[idx]

		if server == nil then
			-- this.data.error = fgettext("Missing server")
			return true
		end

		set_selected_server(this.data)

		core.log(gamedata.address)
		core.log(gamedata.port)
		core.log(gamedata.playername)
		if server and server.address == gamedata.address and
				server.port == gamedata.port then

			serverlistmgr.add_favorite(server)

			gamedata.servername        = server.name
			gamedata.serverdescription = server.description

			if not is_server_protocol_compat_or_error(
						server.proto_min, server.proto_max) then
				return true
			end
		else
			gamedata.servername        = ""
			gamedata.serverdescription = ""
			serverlistmgr.add_favorite({
				address = gamedata.address,
				port = gamedata.port,
			})
		end

		core.settings:set("address",     gamedata.address)
		core.settings:set("remote_port", gamedata.port)
		core.log("Token: "..this.data.token)

			local jsonBody = '{	"func": "22","body": { "username": "'..this.data.username..'", "token":"'..this.data.token..'"}}'
			jsonBody =base64.encode(jsonBody)
			core.log("jsonRequest="..jsonBody)

			local authoURL = PYTHAVERSE.url.."/post?jsonRequest="..jsonBody
			
			core.log("body:"..jsonBody)			

			local createLogin =callFunction(authoURL,"POST",{"Authorization: Bearer "..this.data.token},true,{})
			if createLogin.code == nil then		
				core.log("not update for username token")			
			else 
				core.start()
			end

		
		return true
	end

	

	return false
end

--------------------------------------------------------------------------------
function create_login_dialog(username, pass, token)

	local retval = dialog_create("dlg_login",
			login_formspec,
			login_buttonhandler,
			nil)
	retval.data.username = username
	retval.data.pass = pass
	retval.data.token = token
	retval.data.name = core.settings:get("name") or ""
	return retval, "size[5.5,1,false]real_coordinates[true]"
end
