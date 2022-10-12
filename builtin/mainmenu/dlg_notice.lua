--Minetest
--Copyright (C) 2022 rubenwardy
--
--This program is free software; you can redistribute it and/or modify
--it under the terms of the GNU Lesser General Public License as published by
--the Free Software Foundation; either version 2.1 of the License, or
--(at your option) any later version.
--
--This program is distributed in the hope that it will be useful,
--but WITHOUT ANY WARRANTY; without even the implied warranty of
--MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
--GNU Lesser General Public License for more details.
--
--You should have received a copy of the GNU Lesser General Public License along
--with this program; if not, write to the Free Software Foundation, Inc.,
--51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.

--------------------------------------------------------------------------------

local function notice_formspec(dialogdata)
	

	local retval = {
        "label[0.375,0.2;", fgettext(dialogdata.text), "]"
	}

	if dialogdata.error then
		table.insert_all(retval, {
			"box[0.375,", tostring(buttons_y - 0.9), ";7.25,0.6;darkred]",
		})
	end

	table.insert_all(retval, {
		"container[0.375,", tostring(buttons_y), "]",
		"button[0,0.8;2.5,0.8;dlg_register_cancel;", fgettext("Back"), "]",
		"container_end[]",
	})

	return table.concat(retval, "")
end

--------------------------------------------------------------------------------
local function notice_buttonhandler(this, fields)

	if fields["dlg_register_cancel"] then
		this:delete()
		return true
	end

	return false
end

--------------------------------------------------------------------------------
function create_notice_dialog(txt)

	local retval = dialog_create("dlg_notice",
			notice_formspec,
			notice_buttonhandler,
			nil)
    retval.data.text = txt
	return retval, "size[14,6,false]real_coordinates[true]"
end


