squad = {}
ids_bg = {}
ids_hp = {}
ids_hptag = {}
ids_tag = {}
--local mod_storage = minetest.get_mod_storage()

squad.send_notice_all = function(name, message)
	for _,players in ipairs(minetest.get_connected_players()) do
		local names = players:get_player_name()
		if mod_storage:get_string(name.."_party") == mod_storage:get_string(names.."_party") and mod_storage:get_string(name.."_squad") == mod_storage:get_string(names.."_squad") then
			minetest.chat_send_player(names, minetest.colorize("orange", "[Squad] = SQUAD-NOTICE = ")..""..message)
		end
	end
end

-- private notice
squad.send_notice = function(name, message)
	minetest.chat_send_player(name, minetest.colorize("orange", "[Squad] = NOTICE = ")..""..message)
end

-- check existance of squad in party, if exists, return true
squad.check_tag = function(name, tag)
	for _,players in ipairs(minetest.get_connected_players()) do
		local playernames = players:get_player_name()
		local squadnames = mod_storage:get_string(playernames.."_squad_leader")
		local cparty = mod_storage:get_string(name.."_party")
		
		if cparty == mod_storage:get_string(playernames.."_party") then
			if squadnames ~= "" and squadnames == tag then
				return true
			end
		end
	end
end

-- find out people in a squad
squad.member_amt = function(name, squad)
	-- if not in a party, return
	local cparty = mod_storage:get_string(name.."_party")
	if squad == "" then
		return
	end
	
	local amt = 0
	for _,players in ipairs(minetest.get_connected_players()) do
		local playernames = players:get_player_name()
		if cparty == mod_storage:get_string(playernames.."_party") and squad == mod_storage:get_string(playernames.."_squad") then
			amt = amt + 1
		end
	end
	
	return amt
end

squad.load_hud_self = function(name)
	local player = minetest.get_player_by_name(name)
	local cparty = mod_storage:get_string(name.."_party")
	local csquad = mod_storage:get_string(name.."_squad")
	local csquad_no = tonumber(mod_storage:get_string(name.."_squad_no"))
	-- add blanks huds to player whic can be modifed later on.
	for i = 1,7 do
		ids_bg[name.."_"..cparty.."_bg_"..csquad.."_"..i] = player:hud_add({
			hud_elem_type = "statbar",
			text = "party_heart_background.png",
			number = 0,
			size = {x=22, y=22},
			position = { x = 0.01, y = 0.87 + (i*-0.07) },
			offset = { x = 0, y = 0 },
			direction = 0,
		})
		ids_hp[name.."_"..cparty.."_hp_"..csquad.."_"..i] = player:hud_add({
			hud_elem_type = "statbar",
			text = "party_heart.png",
			number = 0,
			size = {x=22, y=22},
			position = { x = 0.01, y = 0.87 + (i*-0.07) },
			offset = { x = 0, y = 0 },
			direction = 0,
		})
		ids_hptag[name.."_"..cparty.."_hptag_"..csquad.."_"..i] = player:hud_add({
			hud_elem_type = "text",
			position = { x = 0.01 , y = 0.87 + (i*-0.07) },
			alignment = 0,
			name = "text",
			number = 0xFFFFFF,
			text = "",
			alignment = {x=1,y=0},
			offset = { x = 5, y = 9 },
		})
		ids_tag[name.."_"..cparty.."_tag_"..csquad.."_"..i] = player:hud_add({
			hud_elem_type = "text",
			position = { x = 0.01 , y = 0.87 + (i*-0.07) },
			alignment = 0,
			name = "text",
			number = 0x00FF00,
			text = "",
			alignment = {x=1,y=0},
			offset = { x = 0, y = -8 },
		})
	end
	
	minetest.after(0.1, function()
		-- adds self hud
		player:hud_change(ids_bg[name.."_"..cparty.."_bg_"..csquad.."_"..csquad_no], "number", 20)
		player:hud_change(ids_hp[name.."_"..cparty.."_hp_"..csquad.."_"..csquad_no], "number", player:get_hp())
		player:hud_change(ids_hptag[name.."_"..cparty.."_hptag_"..csquad.."_"..csquad_no], "text", "HP: "..player:get_hp().." / 20")
		player:hud_change(ids_tag[name.."_"..cparty.."_tag_"..csquad.."_"..csquad_no], "text", name)
	end)
end

squad.update_hud_self = function(name)
	local player = minetest.get_player_by_name(name)
	local cparty = mod_storage:get_string(name.."_party")
	local csquad = mod_storage:get_string(name.."_squad")
	for _,players in ipairs(minetest.get_connected_players()) do
		local playernames = players:get_player_name()
		if cparty == mod_storage:get_string(playernames.."_party") and csquad == mod_storage:get_string(playernames.."_squad") and name ~= playernames then
			local csquad_no = tonumber(mod_storage:get_string(playernames.."_squad_no"))
			-- update <name>'s hud with squad members.
			minetest.after(0.3, function()
				player:hud_change(ids_bg[name.."_"..cparty.."_bg_"..csquad.."_"..csquad_no], "number", 20)
				player:hud_change(ids_hp[name.."_"..cparty.."_hp_"..csquad.."_"..csquad_no], "number", players:get_hp())
				player:hud_change(ids_hptag[name.."_"..cparty.."_hptag_"..csquad.."_"..csquad_no], "text", "HP: "..players:get_hp().." / 20")
				player:hud_change(ids_tag[name.."_"..cparty.."_tag_"..csquad.."_"..csquad_no], "text", playernames)
			end)
		end
	end
end

squad.add_hud = function(name)
	local player = minetest.get_player_by_name(name)
	local cparty = mod_storage:get_string(name.."_party")
	local csquad = mod_storage:get_string(name.."_squad")
	local csquad_no = tonumber(mod_storage:get_string(name.."_squad_no"))
	for _,players in ipairs(minetest.get_connected_players()) do
		local playernames = players:get_player_name()
		if cparty == mod_storage:get_string(playernames.."_party") and csquad == mod_storage:get_string(playernames.."_squad") then
			minetest.after(0.2, function()
				-- update squad members' hud with <name>
				players:hud_change(ids_bg[playernames.."_"..cparty.."_bg_"..csquad.."_"..csquad_no], "number", 20)
				players:hud_change(ids_hp[playernames.."_"..cparty.."_hp_"..csquad.."_"..csquad_no], "number", player:get_hp())
				players:hud_change(ids_tag[playernames.."_"..cparty.."_tag_"..csquad.."_"..csquad_no], "text", name)
				players:hud_change(ids_hptag[playernames.."_"..cparty.."_hptag_"..csquad.."_"..csquad_no], "text", "HP: "..player:get_hp().." / 20")
			end)
		end
	end
end

squad.join = function(name, tag)
	local cparty = mod_storage:get_string(name.."_party")
	local cparty_l = mod_storage:get_string(cparty.."_leader")
	local player = minetest.get_player_by_name(name)
	local squad_amt = squad.member_amt(name, tag)
	-- check if squad is full
	if squad_amt > 7 then
		squad.send_notice(name, "Squad ["..tag.."] is full!")
		return
	end
	-- add the storage values to idenitify player
	mod_storage:set_string(name.."_squad", tag)
	mod_storage:set_string(name.."_squad_no", squad_amt + 1)
	
	-- add the huds
	squad.load_hud_self(name)
	squad.add_hud(name)
	squad.update_hud_self(name)
	
	squad.send_notice_all(name, name.." has joined the ["..tag.."] squad")
	local tcolour = mod_storage:get_string(cparty.."_colour")
	if tcolour == "" then
		tcolour = "lightgrey"
	end
	player:set_nametag_attributes({text = minetest.colorize(tcolour, "["..cparty_l.."-"..tag.."]").." "..name})
	player:set_attribute("partychat", "squad")
end

squad.replace_hud = function(name, oldno, newno)
	local player = minetest.get_player_by_name(name)
	local cparty = mod_storage:get_string(name.."_party")
	local csquad = mod_storage:get_string(name.."_squad")
	mod_storage:set_string(name.."_squad_no", newno)
	
	for _,players in ipairs(minetest.get_connected_players()) do
		local playernames = players:get_player_name()
		if cparty == mod_storage:get_string(playernames.."_party") and csquad == mod_storage:get_string(playernames.."_squad") then
			minetest.after(0.2, function()
				players:hud_change(ids_bg[playernames.."_"..cparty.."_bg_"..csquad.."_"..oldno], "number", 0)
				players:hud_change(ids_hp[playernames.."_"..cparty.."_hp_"..csquad.."_"..oldno], "number", 0)
				players:hud_change(ids_hptag[playernames.."_"..cparty.."_hptag_"..csquad.."_"..oldno], "text", "")
				players:hud_change(ids_tag[playernames.."_"..cparty.."_tag_"..csquad.."_"..oldno], "text", "")
			end)
		
			minetest.after(0.3, function()
				players:hud_change(ids_bg[playernames.."_"..cparty.."_bg_"..csquad.."_"..newno], "number", 20)
				players:hud_change(ids_hp[playernames.."_"..cparty.."_hp_"..csquad.."_"..newno], "number", player:get_hp())
				players:hud_change(ids_hptag[playernames.."_"..cparty.."_hptag_"..csquad.."_"..newno], "text", "HP: "..player:get_hp().." / 20")
				players:hud_change(ids_tag[playernames.."_"..cparty.."_tag_"..csquad.."_"..newno], "text", name)
			end)
		end
	end
end

squad.leave = function(name, tag)
	local cparty = mod_storage:get_string(name.."_party")
	local cparty_l = mod_storage:get_string(cparty.."_leader")
	local player = minetest.get_player_by_name(name)
	local csquad = mod_storage:get_string(name.."_squad")
	local csquad_no = tonumber(mod_storage:get_string(name.."_squad_no"))
	player:set_attribute("partychat", "party")
	
	if csquad == "" then
		return
	end
	
	-- remove all huds for player-that-left
	for i = 1,7 do
		player:hud_remove(ids_bg[name.."_"..cparty.."_bg_"..csquad.."_"..i])
		player:hud_remove(ids_hp[name.."_"..cparty.."_hp_"..csquad.."_"..i])
		player:hud_remove(ids_hptag[name.."_"..cparty.."_hptag_"..csquad.."_"..i])
		player:hud_remove(ids_tag[name.."_"..cparty.."_tag_"..csquad.."_"..i])
	end
	
	mod_storage:set_string(name.."_squad", nil)
	mod_storage:set_string(name.."_squad_leader", nil)
	mod_storage:set_string(name.."_squad_lock", nil)
	mod_storage:set_string(name.."_squad_no", nil)
	
	local tcolour = mod_storage:get_string(cparty.."_colour")
	if tcolour == "" then
		tcolour = "lightgrey"
	end
	player:set_nametag_attributes({text = minetest.colorize(tcolour, "["..cparty_l.."]").." "..name})
	
	local squad_amt = squad.member_amt(name, csquad)
	
	for _,players in ipairs(minetest.get_connected_players()) do
		local playernames = players:get_player_name()
		if cparty == mod_storage:get_string(playernames.."_party") and csquad == mod_storage:get_string(playernames.."_squad") and name ~= playernames then
			local msquad_n = tonumber(mod_storage:get_string(playernames.."_squad_no"))
			-- hide player-that-left's hud for other players
			minetest.after(0.1, function()
				players:hud_change(ids_bg[playernames.."_"..cparty.."_bg_"..csquad.."_"..csquad_no], "number", 0)
				players:hud_change(ids_hp[playernames.."_"..cparty.."_hp_"..csquad.."_"..csquad_no], "number", 0)
				players:hud_change(ids_hptag[playernames.."_"..cparty.."_hptag_"..csquad.."_"..csquad_no], "text", "")
				players:hud_change(ids_tag[playernames.."_"..cparty.."_tag_"..csquad.."_"..csquad_no], "text", "")
			end)
		end
	end
	
	for _,players in ipairs(minetest.get_connected_players()) do
		local playernames = players:get_player_name()
		if cparty == mod_storage:get_string(playernames.."_party") and csquad == mod_storage:get_string(playernames.."_squad") and name ~= playernames then
			local msquad_n = tonumber(mod_storage:get_string(playernames.."_squad_no"))
			if msquad_n > squad_amt then
				if msquad_n == 7 then
					squad.replace_hud(playernames,7,csquad_no)
					return
				elseif msquad_n == 6 then
					squad.replace_hud(playernames,6,csquad_no)
					return
				elseif msquad_n == 5 then
					squad.replace_hud(playernames,5,csquad_no)
					return
				elseif msquad_n == 4 then
					squad.replace_hud(playernames,4,csquad_no)
					return
				elseif msquad_n == 3 then
					squad.replace_hud(playernames,3,csquad_no)
					return
				elseif msquad_n == 2 then
					squad.replace_hud(playernames,2,csquad_no)
					return
				end
			end
		end
	end
end

minetest.register_chatcommand("sq", {
	description = "Create and join a squad. For help, use /sq help",
	privs = {shout=true},
	func = function(name, param)
	
		local paramlist = {}
		local index = 1
		for param_split in param:gmatch("%S+") do
			paramlist[index] = param_split
			index = index + 1
		end
		
		local param1 = paramlist[1]
		local param2 = paramlist[2]
		local player = minetest.get_player_by_name(name)
		local cparty = mod_storage:get_string(name.."_party")
		local cparty_o = mod_storage:get_string(name.."_officer")
		local csquad = mod_storage:get_string(name.."_squad")
		local csquad_l = mod_storage:get_string(name.."_squad_leader")
		local player_list = minetest.deserialize(mod_storage:get_string("playerlist"))
		
		if party.check(name, 1) == true then
			return
		end
		
		if param1 == "help" then
			squad.send_notice(name, "NOTE: Unlike parties, squads do not last permanently, you automatically leave if you leave the game and if the squad leader does so, the squad is automatically disbanded.")
			squad.send_notice(name, minetest.colorize("cyan", "/sq join <squadname>").. " --- Join a squad.")
			squad.send_notice(name, minetest.colorize("cyan", "/sq leave").. " --- Leave your squad.")
			squad.send_notice(name, minetest.colorize("cyan", "/sq invite <yes/no>").. " --- Accept / reject an invite.")
			
			squad.send_notice(name, " ===== PARTY OFFICERS/ PARTY LEADER COMMANDS: ===== ")
			squad.send_notice(name, minetest.colorize("cyan", "/sq create <squadname>").. " --- Create a squad.")
			
			squad.send_notice(name, " ===== SQUAD LEADER COMMANDS: ===== ")
			squad.send_notice(name, minetest.colorize("cyan", "/sq disband").. " --- Disband your squad.")
			--squad.send_notice(name, minetest.colorize("cyan", "/sq leader <playername>").. " --- Give your squad leader position to someone else.")
			squad.send_notice(name, minetest.colorize("cyan", "/sq lock <open/private>").. " --- Change joining method for your squad.")
			squad.send_notice(name, minetest.colorize("cyan", "/sq invite <playername>").. " --- Invite a player to your squad.")
			
			squad.send_notice(name, " ===== PARTY LEADER / ADMIN COMMANDS: ===== ")
			squad.send_notice(name, minetest.colorize("cyan", "/sq disband <squadname>").. " --- Disband your squad in your party.")
			
			mod_storage:set_string(name.."_squad", param2)
			mod_storage:set_string(name.."_squad_leader", param2)
		
		elseif param1 == "create" and param2 ~= nil then
			-- check if player is an officer or above.
			if party.check(name, 2) == true then
				return
			end
			-- check if tag is too long
			if string.len(param2) > PARTY_SQUAD_NAME_LENGTH then
				party.send_notice(name, "Nametag is too long! "..PARTY_SQUAD_NAME_LENGTH.." is the maximum amount of characters")
				return
			end
			-- check if tag exists
			if squad.check_tag(name, param2) == true then
				squad.send_notice(name, "Squad name selected already exists. Please choose another one.")
				return
			end
			
			-- if player not in another squad already
			if csquad == "" then
				local cparty_l = mod_storage:get_string(cparty.."_leader")
				party.send_notice_all(name, name.." created the ["..param2.."] squad in "..cparty.."'s party ["..cparty_l.."].")
				
				mod_storage:set_string(name.."_squad_leader", param2)
				mod_storage:set_string(name.."_squad_lock", PARTY_SQUAD_JOIN_MODE)
				squad.join(name, param2)

			else squad.send_notice(name, "You are already in ["..csquad.."] squad.")
			end
			
		elseif param1 == "disband" then
			local cparty_l = mod_storage:get_string(cparty.."_leader")
			if csquad_l == csquad and param2 == nil then
				if csquad == "" then
					squad.send_notice(name, "You are not in a squad!")
					return
				end
				
				squad.send_notice_all(name, "Squad ["..csquad.."] has been disbanded by the squad leader "..name)
				party.send_notice_all(name, "Squad ["..csquad.."] has been disbanded by the squad leader "..name)
				
				-- remove all online squad members
				for _,players in ipairs(minetest.get_connected_players()) do
					local names = players:get_player_name()
					if mod_storage:get_string(names.."_party") == cparty and mod_storage:get_string(names.."_squad") == csquad then
						squad.leave(names)
					end
				end
			-- Allow party leader to disband squads
			elseif (param2 ~= nil or param2 ~= "") then
				if party.check(name, 3) == true then
					return
				end
				
				if squad.check_tag(name, param2) == true and param2 ~= "" then
					party.send_notice_all(name, "Squad ["..param2.."] has been disbanded by the party leader "..name)
					
					for _,players in ipairs(minetest.get_connected_players()) do
						local names = players:get_player_name()
						if mod_storage:get_string(names.."_party") == cparty and mod_storage:get_string(names.."_squad") == param2 then
							squad.leave(names)
						end
					end
				else squad.send_notice(name, "Squad ["..param2.."] does not exist in your party!")
				end
			else squad.send_notice(name, "You are not a squad leader nor the party leader!")
			end
			
		
		elseif param1 == "lock" and param2 ~= nil then
			if csquad_l ~= csquad then
				squad.send_notice(name, "You are not a squad leader.")
				return
			end
				
			if param2 == "open" then
				mod_storage:set_string(name.."_squad_lock", "")
				squad.send_notice_all(name, "[Open mode] Public joining is enabled for "..csquad.." squad")
			elseif param2 == "private" then
				mod_storage:set_string(name.."_squad_lock", "private")
				squad.send_notice_all(name, "[Private mode] Public joining is disabled for "..csquad.." squad")
			end
		
		elseif param1 == "kick" and param2 ~= nil then
			--check if player is squad leader
			if csquad_l ~= csquad then
				squad.send_notice(name, "You are not a squad leader.")
				return
			end
			
			if minetest.player_exists(param2) then
				--check if player is online
				if minetest.get_player_by_name(param2) == nil then
					squad.send_notice(name, "Player "..param2.." is not online now!")
					return
				end
				
				if mod_storage:get_string(param2.."_party") == cparty and mod_storage:get_string(param2.."_squad") == csquad then
					squad.send_notice_all(name, param2.." was kicked from the ["..csquad.."] squad by "..name)
					squad.leave(param2)
				else squad.send_notice(name, "Player "..param2.." is not in your squad / party!")
				end
			else squad.send_notice(name, "Player "..param2.." does not exist!")
			end
		
		elseif param1 == "join" and param2 ~= nil then
			if squad.check_tag(name, param2) ~= true then
				squad.send_notice(name, "Squad name does not exist in your party!")
				return
			end
			
			if csquad ~= "" then
				squad.send_notice(name, "You are already in squad ["..csquad.."].")
				return
			end
			
			for _,players in ipairs(minetest.get_connected_players()) do
				local names = players:get_player_name()
				-- if same party and squad name matches param2
				if mod_storage:get_string(names.."_party") == cparty and mod_storage:get_string(names.."_squad") == param2 then
					if mod_storage:get_string(names.."_squad_leader") ~= "" then
						squadleadername = names
					end
				end
			end
			
			if mod_storage:get_string(squadleadername.."_squad_lock") == "private" then
				squad.send_notice(name, "Squad is private!")
			else
				if squad.member_amt(name, param2) <= 7 then
					squad.join(name, param2)
				else squad.send_notice(name, "Squad ["..param2.."] is full!")
				end
			end
		
		elseif param1 == "leave" then
			if csquad == "" then
				squad.send_notice(name, "You are not in a squad!")
				return
			end
			
			if csquad_l == csquad then
				squad.send_notice(name, "You cannot leave because you are the squad leader! Use '/sq disband' instead.")
				return
			end
			
			squad.send_notice_all(name, name.." has left the ["..csquad.."] squad")
			squad.leave(name)
		
		elseif param1 == "invite" and param2 ~= nil then
			if (param2 == "yes" or param2 == "no") and csquad == "" then
				if player:get_attribute("squadinvite") == nil then
					squad.send_notice(name, "You have not received a squad invite!")
					return
				end
				
				local sender = player:get_attribute("squadinvite")
				local csquad_i = mod_storage:get_string(sender.."_squad")
				if param2 == "yes" then
					if squad.member_amt(name, csquad_i) <= 7 then
						squad.join(name, csquad_i)
						squad.send_notice(sender, name.. "has accepted your invite to join your squad ["..csquad_i.."]")
						player:set_attribute("squadinvite", nil)
					else
						squad.send_notice(sender, name.. "has accepted your invite to join your squad ["..csquad_i.."] BUT your squad is full!")
						squad.send_notice(name, "You have accepted "..sender.."'s invitation to join the squad ["..csquad_i.."] BUT the squad is full!")
					end
				elseif param2 == "no" then
					squad.send_notice(name, "You have rejected "..sender.."'s invitation to join the squad ["..csquad_i.."]")
					squad.send_notice(sender, name.. " has rejected your invitation to join your squad ["..csquad_i.."]")
					player:set_attribute("squadinvite", nil)
				end
				
			elseif csquad ~= "" then
				if csquad_l ~= csquad then
					squad.send_notice(name, "You are not a squad leader.")
					return
				end
				
				if minetest.player_exists(param2) then
					-- check if player is online
					if minetest.get_player_by_name(param2) == nil then
						squad.send_notice(name, "Player "..param2.." is not online!")
						return
					end
					-- check if player is in the same party
					if mod_storage:get_string(param2.."_party") ~= cparty then
						squad.send_notice(name, "Player "..param2.." is not in your party!")
						return
					end
					-- check if player is already part of a squad
					local target_squad = mod_storage:get_string(param2.."_squad")
					if target_squad ~= "" then
						squad.send_notice(name, "Player "..param2.." is already part of the squad "..target_squad.."!")
						return
					end
					-- send invitation
					squad.send_notice(param2, name.." invited you to join the "..csquad.." squad. '/sq invite yes' to accept, '/sq invite no' to reject.")
					minetest.get_player_by_name(param2):set_attribute("squadinvite", name)
					squad.send_notice(name, param2.." has been sent an invitation to join ["..csquad.."] squad. Pending response")
				else squad.send_notice(name, "Player "..param2.." does not exist!")
				end
			else squad.send_notice(name, "You are not in a squad!")
			end
			
		else squad.send_notice(name, "ERROR: Command is invalid! For help, use the command '/sq help'.")
		end
	end,	
})


minetest.register_on_player_hpchange(function(player, hp_change)
	local name = player:get_player_name()
	local cparty = mod_storage:get_string(name.."_party")
	local csquad = mod_storage:get_string(name.."_squad")
	local csquad_no = tonumber(mod_storage:get_string(name.."_squad_no"))
	
	if csquad == "" then
		return
	end
	
	-- update self
	--minetest.after(0.01, function()
		if player:get_hp() + hp_change < 20 then
			player:hud_change(ids_hp[name.."_"..cparty.."_hp_"..csquad.."_"..csquad_no], "number", player:get_hp() + hp_change)
		
			player:hud_change(ids_hptag[name.."_"..cparty.."_hptag_"..csquad.."_"..csquad_no], "text", "HP: "..player:get_hp() + hp_change.." / 20")
		elseif player:get_hp() + hp_change >= 20 then
			player:hud_change(ids_hp[name.."_"..cparty.."_hp_"..csquad.."_"..csquad_no], "number", 20)
		
			player:hud_change(ids_hptag[name.."_"..cparty.."_hptag_"..csquad.."_"..csquad_no], "text", "HP: 20 / 20")
		end
	--end)
	
	-- update squad displays of self
	for _,players in ipairs(minetest.get_connected_players()) do
		local playernames = players:get_player_name()
		if cparty == mod_storage:get_string(playernames.."_party") and csquad == mod_storage:get_string(playernames.."_squad") and name ~= playernames then
			minetest.after(0.02, function()
				if player:get_hp() < 20 then
					players:hud_change(ids_hp[playernames.."_"..cparty.."_hp_"..csquad.."_"..csquad_no], "number", player:get_hp())
		
					players:hud_change(ids_hptag[playernames.."_"..cparty.."_hptag_"..csquad.."_"..csquad_no], "text", "HP: "..player:get_hp().." / 20")
				elseif player:get_hp() >= 20 then
					players:hud_change(ids_hp[playernames.."_"..cparty.."_hp_"..csquad.."_"..csquad_no], "number", 20)
		
					players:hud_change(ids_hptag[playernames.."_"..cparty.."_hptag_"..csquad.."_"..csquad_no], "text", "HP: 20 / 20")
				end
			end)
		end
	end
end)

minetest.register_on_joinplayer(function(player)
	-- clear all stats
	local name = player:get_player_name()
	local csquad = mod_storage:get_string(name.."_squad")
	if csquad ~= "" then
		squad.leave(name)
	end
end)

minetest.register_on_leaveplayer(function(player)
	local name = player:get_player_name()
	local csquad = mod_storage:get_string(name.."_squad")
	local cparty = mod_storage:get_string(name.."_party")
	player:set_attribute("squadinvite", nil)
	
	if csquad == "" then
		return
	end
	-- disband squad if squad leader leaves
	if mod_storage:get_string(name.."_squad_leader") == csquad then
		squad.send_notice_all(name, "The squad ["..csquad.."] is disbanded because the squad leader, "..name..", has left the game.")
		-- remove all members
		for _,players in ipairs(minetest.get_connected_players()) do
			local names = players:get_player_name()
			if mod_storage:get_string(names.."_party") == cparty and mod_storage:get_string(names.."_squad") == csquad then
				squad.leave(names)
			end
		end
	else
		squad.send_notice_all(name, name.." has left the ["..csquad.."] squad because "..name.." left the game.")
		squad.leave(name)
	end
end)