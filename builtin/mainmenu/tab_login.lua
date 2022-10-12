local function get_formspec_login(tabview, name, tabdata)
    common_update_cached_supp_proto()

	if not tabdata.search_for then
		tabdata.search_for = ""
	end

    local retval =

		-- -- Name / Password
		"container[3.8,0.6]" ..
		"label[0,0.1;" .. fgettext("Name") .. "]" ..
		"label[0,1.6;" .. fgettext("Password") .. "]" ..
		"field[0,0.4;4,0.75;username;;]" ..
		"pwdfield[0,1.9;4,0.75;password;]" ..
		-- Connect
		"button[0,3;2.5,0.75;btn_leanbot_login;" .. fgettext("Login") .. "]"..
		"container_end[]"
		return retval, "size[14,6,false]real_coordinates[true]"
end

local function main_button_login_handler(tabview, fields, name, tabdata)
    if (fields.btn_leanbot_login) then
        --check sso-token
		
		local ssoBody = {}
		ssoBody.client_id = SSO.client_id
		
		ssoBody.grant_type = "password"
		ssoBody.username = fields.username
		ssoBody.password = fields.password

		--ssoBody.username = "student"
		--ssoBody.password = "Dtt@123!"

		core.log("username: "..ssoBody.username)
		core.log("pass: "..ssoBody.password)

		local ssoHeader = {}
		ssoHeader["Content-Type"] = "application/x-www-form-urlencoded"	
		
		local ssoData = callFunction(SSO.url,"POST",ssoHeader,false,ssoBody)

		-- core.log(response.data)
		if ssoData.access_token == nil then
			core.log("Incorrect username or password")		
			local text = "Incorrect username or password"
			local dlg = create_notice_dialog(text)
			dlg:set_parent(tabview)
			tabview:hide()
			dlg:show()
		else
			core.log("login sucessfuly...with token:"..ssoData.access_token)

			local pBody='{"func": "28","body": {"username":"'..fields.username..'","token":"'..ssoData.access_token..'","password":"" }}'
			pBody =base64.encode(pBody)
			local pURL = PYTHAVERSE.url.."/post?jsonRequest="..pBody

			local pCall = callFunction(pURL,"POST",{"Authorization: Bearer "..ssoData.access_token},true,{})
		

			
		
			-- core.start()
			local dlg = create_login_dialog(fields.username, fields.password, ssoData.access_token)
			dlg:set_parent(tabview)
			tabview:hide()
			dlg:show()
		end
    end

    return true
end



local function on_change(type, old_tab, new_tab)
	if type == "LEAVE" then return end
	serverlistmgr.sync()
end

return {
	name = "online",
	caption = fgettext("Join Pythaverse"),
	cbf_formspec = get_formspec_login,
	cbf_button_handler = main_button_login_handler,
	on_change = on_change
}