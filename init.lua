party = {}
mod_storage = minetest.get_mod_storage()

-- =======================
-- ===== PLAYER LIST =====
-- =======================
-- add new players to the mod storage playerlist - thanks to Amaz
minetest.register_on_newplayer(function(newplayer)
	local player_list_l = mod_storage:get_string("playerlist")
	if player_list_l == "" then
		player_list_t = {}
	else player_list_t = minetest.deserialize(player_list_l)
	end
	player_list_t[#player_list_t+1] = newplayer:get_player_name()
	local player_list_s = minetest.serialize(player_list_t)
	mod_storage:set_string("playerlist", player_list_s)
end)

-- check if old players are in the playerlist, if not, add them to the list
minetest.register_on_joinplayer(function(player)
	local player_list_l = mod_storage:get_string("playerlist")
	local name = player:get_player_name()
	if player_list_l == "" then
		player_list_lt = {}
	else player_list_lt = minetest.deserialize(player_list_l)
	end

	for _,playernames in ipairs(player_list_lt) do
		if name == playernames then
			return
		end
	end

	if player_list_l == "" then
		player_list_e = {}
	else player_list_e = minetest.deserialize(player_list_l)
	end

	player_list_e[#player_list_e+1] = player:get_player_name()
	local player_list_s = minetest.serialize(player_list_e)
	mod_storage:set_string("playerlist", player_list_s)
end)

-- =======================
-- ======= HELPERS =======
-- =======================
-- group notice
party.send_notice_all = function(name, message)
	for _,players in ipairs(minetest.get_connected_players()) do
		local names = players:get_player_name()
		if mod_storage:get_string(name.."_party") == mod_storage:get_string(names.."_party") then
			minetest.chat_send_player(names, minetest.colorize("limegreen", "[Party] = PARTY-NOTICE = ")..""..message)
		end
	end
end


-- private notice
party.send_notice = function(name, message)
	minetest.chat_send_player(name, minetest.colorize("limegreen", "[Party] = NOTICE = ")..""..message)
end

-- chat spy for admins
minetest.register_privilege("pspy", "")
party.chat_spy = function(name, message)
	for _,players in ipairs(minetest.get_connected_players()) do
		local names = players:get_player_name()
		if minetest.check_player_privs(names, {pspy=true}) then
			local cparty = mod_storage:get_string(name.."_party")
			if cparty ~= nil then
				if cparty ~= mod_storage:get_string(names.."_party") then
					minetest.chat_send_player(names, minetest.colorize("yellow", "[SPY]").." [PARTY:"..mod_storage:get_string(cparty.."_leader").."] <"..name.."> "..message)
				end
			end
		end
	end
end

-- check if player is in a party [1], officer or leader [2], leader [3]
-- if not then return true
party.check = function(name, level)
	local player = minetest.get_player_by_name(name)
	local cparty = mod_storage:get_string(name.."_party")
	if level == 1 and cparty == "" then
		party.send_notice(name, "You are not in a party!")
		return true
	elseif level == 2 then
		if cparty == "" then
			party.send_notice(name, "You are not in a party!")
			return true
		
		elseif cparty ~= "" then
			local cparty_l = mod_storage:get_string(name.."_leader")
			local cparty_o = mod_storage:get_string(name.."_officer")
			if cparty_o == "" and cparty_l == "" then
				party.send_notice(name, "Not authorized to use this command! You are neither the party leader nor an officer of this party!")
				return true
			end
		end
	elseif level == 3 then
		local cparty_l = mod_storage:get_string(name.."_leader")
		if cparty == "" then
			party.send_notice(name, "You are not in a party!")
			return true
		elseif cparty ~= "" and cparty_l == "" then
			party.send_notice(name, "Not authorized to use this command! You are not the party leader!")
			return true
		end
	else
		return false
	end
end

-- check if party name exists
-- if it exists, return true
party.check_tag = function(name, tag)
	local player_list = minetest.deserialize(mod_storage:get_string("playerlist"))
	for _,playernames in ipairs(player_list) do
		if tag == mod_storage:get_string(playernames.."_leader") then
			return true
		end
	end
end

-- =======================
-- ====== LOAD FILES =====
-- =======================
dofile(minetest.get_modpath("party").."/squad.lua")

-- =======================
-- ===== MORE HELPERS ====
-- =======================
party.join = function(name, partyname)
	local cparty_l = mod_storage:get_string(partyname.."_leader")
	local player = minetest.get_player_by_name(name)
	mod_storage:set_string(name.."_party", partyname)
	player:set_attribute("partyinvite", nil)
	player:set_attribute("partypending", nil)
	player:set_nametag_attributes({text = "["..cparty_l.."] "..name})
	party.send_notice_all(name, name.." has joined "..partyname.."'s party ["..cparty_l.."].")
end

party.leave = function(name)
	local player = minetest.get_player_by_name(name)
	
	squad.leave(name)
	
	mod_storage:set_string(name.."_party", nil)
	mod_storage:set_string(name.."_officer", nil)
	mod_storage:set_string(name.."_leader", nil)
	mod_storage:set_string(name.."_lock", nil)
	player:set_nametag_attributes({text = name})
end


minetest.register_chatcommand("p", {
	description = "Create and join a party. For help, use /p help",
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
		local param3 = paramlist[3]
		local player = minetest.get_player_by_name(name)
		local cparty = mod_storage:get_string(name.."_party")
		local cparty_o = mod_storage:get_string(name.."_officer")
		local player_list = minetest.deserialize(mod_storage:get_string("playerlist"))
		
		if param1 == "help" then
			party.send_notice(name, minetest.colorize("cyan", "@<message>").." --- Send message to global chat (if you are in a party).")
			party.send_notice(name, minetest.colorize("cyan", "/all <message>").." --- Send message to global chat (if you are in a party).")
			party.send_notice(name, minetest.colorize("cyan", "/p").." --- List your current party.")
			party.send_notice(name, minetest.colorize("cyan", "/p list").." --- List online members of your party.")
			party.send_notice(name, minetest.colorize("cyan", "/p list all").." --- List all members of your party.")
			party.send_notice(name, minetest.colorize("cyan", "/p partylist").." --- Gives full list of parties created.")
			party.send_notice(name, minetest.colorize("cyan", "/p list <playername>").." --- List party of player.")
			party.send_notice(name, minetest.colorize("cyan", "/p create <partyname>").." --- Create a party.")
			party.send_notice(name, minetest.colorize("cyan", "/p join <partyname>").." --- Join a party.")
			party.send_notice(name, minetest.colorize("cyan", "/p leave").." --- Leave your party.")
			party.send_notice(name, minetest.colorize("cyan", "/p invite <yes/no>").." --- Accept/ reject a party invite.")
			party.send_notice(name, minetest.colorize("cyan", "/p noinvite").." --- Toggle noinvites, if on, reject all parties invites automatically.")
			party.send_notice(name, minetest.colorize("cyan", "/p pvp").." --- Toggle friendly fire, if two players have friendly fire enabled even though they are in the same party, they can fight.")
			
			party.send_notice(name, " ===== PARTY OFFICERS/ PARTY LEADER COMMANDS: ===== ")
			party.send_notice(name, minetest.colorize("cyan", "/p kick <playername>").." --- Kick a player out of your party")
			party.send_notice(name, minetest.colorize("cyan", "/p invite <playername>").." --- Invite a player to join your party")
			party.send_notice(name, minetest.colorize("cyan", "/p <accept/reject> <playername>").." --- Accept/ reject a join request (if joining method is set to [Request Mode])")

			party.send_notice(name, " ===== PARTY LEADER-ONLY COMMANDS: ===== ")
			party.send_notice(name, minetest.colorize("cyan", "/p disband").." --- Disband your party")
			party.send_notice(name, minetest.colorize("cyan", "/p rename <new_partyname>").." --- Rename your party")
			party.send_notice(name, minetest.colorize("cyan", "/p officer <playername>").." --- Toogle a player's officer position. Officers can kick & invite.")
			party.send_notice(name, minetest.colorize("cyan", "/p lock <open/active/request/private>").." --- Toggle joining method for your party")
			party.send_notice(name, minetest.colorize("cyan", "/p title <playername> <title>").." --- Adds a title to a player in party chat.")
			
			party.send_notice(name, " ===== ADMIN COMMANDS: ===== ")
			party.send_notice(name, minetest.colorize("cyan", "/p forcedisband <partyname>").." --- Forcefully disband a party (requires 'ban' privilege)")
			party.send_notice(name, minetest.colorize("cyan", "/p forcejoin <partyname>").." --- Forcefully let yourself in a party regardless of its lock mode (requires 'ban' privilege)")
			party.send_notice(name, minetest.colorize("cyan", "/p forcekick <playername>").." --- Forcefully kick a player from a party (requires 'kick' privilege)")
			
			-- TODO
			-- formspecs equivalents
			-- party.send_notice(name, "/p colour <partycolour> --- Change colour of party tag")
			-- party.send_notice(name, "/p chat <party/ally/global> --- Toggle between party chat, ally chat, global chat")
			-- party.send_notice(name, "/p home --- Teleports to party home (set by leader)")
			-- party.send_notice(name, "/p home set --- Set a party home")
			
			-- party.send_notice(name, "/p ally/enemy/neutral <partyname> --- Toggle diplomacy status with another party. Allied parties will have no friendly fire and there will be ally chat.")
			-- party.send_notice(name, "/p ally list --- Ally list.")
			-- party.send_notice(name, "/p enemy list --- Enemies list.")
			-- party.send_notice(name, "/p motd --- Adds a motd. Player receive this message when they join the game / party. ")
			
		-- =======================
		-- === GENERAL COMMANDS ==
		-- =======================
		elseif param1 == nil then
			if party.check(name, 1) == true then
				return
			end
			local cparty_l = mod_storage:get_string(cparty.."_leader")
			party.send_notice(name, "You are currently in "..cparty.."'s party ["..cparty_l.."].")
			
		elseif param1 == "list" then			
			if param2 == "all" then
				if party.check(name, 1) == true then
					return
				end

				local listnames = ""
				local cparty_l = mod_storage:get_string(cparty.."_leader")
				party.send_notice(name, "Full member list of "..cparty.."'s party ["..cparty_l.."]:")
				for _,playernames in ipairs(player_list) do
					if cparty == mod_storage:get_string(playernames.."_party") then
						listnames = listnames .. playernames .. ", "
					end
				end
				party.send_notice(name, listnames)
			elseif param2 == "officer" then
				if party.check(name, 1) == true then
					return
				end

				local listnames = ""
				local cparty_l = mod_storage:get_string(cparty.."_leader")
				party.send_notice(name, "List of "..cparty.."'s party ["..cparty_l.."] officers:")
				for _,playernames in ipairs(player_list) do
					if cparty == mod_storage:get_string(playernames.."_party") then
						if mod_storage:get_string(playernames.."_officer") ~= "" or mod_storage:get_string(playernames.."_leader") ~= "" then
							listnames = listnames .. playernames .. ", "
						end
					end
				end
				party.send_notice(name, listnames)
			elseif param2 == nil then
				if party.check(name, 1) == true then
					return
				end

				local listnames = ""
				local cparty_l = mod_storage:get_string(cparty.."_leader")
				party.send_notice(name, "Online member list of "..cparty.."'s party ["..cparty_l.."]:")
				for _,players in ipairs(minetest.get_connected_players()) do
					local playernames = players:get_player_name()
					if cparty == mod_storage:get_string(playernames.."_party") then
						listnames = listnames .. playernames .. ", "
					end
				end
				party.send_notice(name, listnames)
			elseif param2 ~= nil then
				if minetest.player_exists(param2) then
					local cparty = mod_storage:get_string(param2.."_party")
					if cparty ~= "" then
						local cparty_l = mod_storage:get_string(cparty.."_leader")
						if cparty_l ~= "" then
							party.send_notice(name, param2.." is currently in "..cparty.."'s party ["..cparty_l.."].")
						elseif cparty == ("@" or "#") then
							party.send_notice(name, param2.." is currently not in any party.")
						local cparty_l = mod_storage:get_string(param2.."_leader")
						elseif cparty_l ~= "" then
							party.send_notice(name, param2.." is currently the leader of "..param2.."'s party ["..cparty_l.."].")
						end
					else party.send_notice(name, param2.." is currently not in any party.")
					end
				else party.send_notice(name, "Player does not exist!")
				end
			end
			
		elseif param1 == "partylist" then
			local player_list = minetest.deserialize(mod_storage:get_string("playerlist"))
			local partylist = ""
			for _,playernames in ipairs(player_list) do
				local cparty_l = mod_storage:get_string(playernames.."_leader")
				if cparty_l ~= "" then
					partylist = partylist .. cparty_l .. ", "
				end
			end
			party.send_notice(name, "Full list of parties: ") 
			party.send_notice(name, partylist)
			
		elseif param1 == "leave" then
			if party.check(name, 1) == true then
				return
			end
			local cparty_l = mod_storage:get_string(cparty.."_leader")
			if mod_storage:get_string(name.."_leader") == "" then
				party.send_notice_all(name, name.." left "..cparty.."'s party ["..cparty_l.."].")
				party.leave(name)
			else party.send_notice(name, "You cannot leave your own party! Use /p disband instead.")
			end
		
		elseif param1 == "create" and param2 ~= nil then
			if string.len(param2) > 8 then
				party.send_notice(name, "Nametag is too long! 8 is the maximum amount of characters")
				return
			end
			
			-- check if tag exists
			if party.check_tag(name, param2) == true then
				party.send_notice(name, "Party name selected already exists. Please choose another one.")
				return
			end
			
			
			if cparty == "" then
				mod_storage:set_string(name.."_party", name)
				mod_storage:set_string(name.."_leader", param2)
				player:set_attribute("partyinvite", nil)
				player:set_nametag_attributes({text = "["..param2.."] "..name})
				
				party.send_notice(name, "You created "..name.."'s party ["..param2.."].")
			else
				local cparty_l = mod_storage:get_string(cparty.."_leader")
				party.send_notice(name, "You are already in "..cparty.."'s party ["..cparty_l.."].")
			end
		
		-- /p join
		elseif param1 == "join" and param2 ~= nil then
			if cparty ~= "" then
				local cparty_l = mod_storage:get_string(cparty.."_leader")
				party.send_notice(name, "You are already in "..cparty.."'s party ["..cparty_l.."].")
				return
			end
			
			if party.check_tag(name, param2) == true then
				local leadername = ""
				for _,playernames in ipairs(player_list) do
					if param2 == mod_storage:get_string(playernames.."_leader") then
						leadername = leadername .. playernames
					end
				end
				local cparty = leadername
				local party_m = mod_storage:get_string(cparty.."_lock")
				-- active mode, only allow if leader is active
				if party_m == "active" then
					if minetest.get_player_by_name(cparty) == nil then
						party.send_notice(name, "Party leader is offline, try again when the party leader is online!")
					else party.join(name, cparty)
					end
				-- request mode, sends a request if officer/leader are online
				elseif party_m == "request" then
					if player:get_attribute("partypending") ~= nil then
						party.send_notice(name, "You have already requested to join another party. Only one join request is allowed to prevent spamming.")
						party.send_notice(name, "Please rejoin the game if you want to make an different request.")
						return
					end
					for _,players in ipairs(minetest.get_connected_players()) do
						local names = players:get_player_name()
						if cparty == mod_storage:get_string(names.."_party") then
							if mod_storage:get_string(names.."_officer") ~= "" or mod_storage:get_string(names.."_leader") ~= "" then
								local off_names = players:get_player_name()
								party.send_notice(off_names, name.." has requested to join the party. Use '/p accept <playername>' to accept, '/p reject <playername>' to reject.")
							end
						end
					end
					party.send_notice(name, "Your request to join "..cparty.."'s party ["..param2.."] has been sent.")
					party.send_notice(name, "Pending approval from an officer/leader. If you do not receive a reply soon, it is likely there's no one online to review your request.")
					party.send_notice(name, "Please do not leave the game, your join request will be rendered void if you do so.")
					player:set_attribute("partypending", cparty)
				-- private mode, denies all requests
				elseif party_m == "private" then
					party.send_notice(name, "Party is private! Public join requests are denied!")
				-- public mode, accept all requests
				else party.join(name, cparty)
				end
				
			else party.send_notice(name, "Party does not exist!")
			end
			
		-- /p noinvite
		elseif param1 == "noinvite" then
			if cparty == "" then
				if player:get_attribute("partynoinvite") == "true" then
					player:set_attribute("partynoinvite", nil)
					party.send_notice(name, "You have disabled noinvite - You will now receive party invites.")
				elseif player:get_attribute("partynoinvite") == nil then
					player:set_attribute("partyinvite", nil)
					player:set_attribute("partynoinvite", "true")
					party.send_notice(name, "You have enabled noinvite - You will now NOT receive party invites.")
				end
			else party.send_notice(name, "You are already in a party! Invites wouldn't be received when you are in a party!")
			end
			
		-- /p pvp
		elseif param1 == "pvp" then
			if player:get_attribute("partypvp") == "true" then
				player:set_attribute("partypvp", nil)
				party.send_notice(name, "NO friendly fire is ENABLED.")
			elseif player:get_attribute("partypvp") == nil then
				player:set_attribute("partypvp", "true")
				party.send_notice(name, "Friendly fire is ENABLED.")
			end

		-- =======================
		-- = LEADERSHIP COMMANDS =
		-- =======================
		-- /p disband
		elseif param1 == "disband" then			
			if party.check(name, 3) == true then
				return
			end
			if cparty == name then
				party.send_notice_all(name, name.."'s party ["..mod_storage:get_string(name.."_leader").."] has been disbanded.")
				-- remove online players
				for _,players in ipairs(minetest.get_connected_players()) do
					local names = players:get_player_name()
					if mod_storage:get_string(names.."_party") == cparty then
						party.leave(names)
					end
				end
				-- mark offline players so they would be notified when they login
				for _,playernames in ipairs(player_list) do
					if minetest.get_player_by_name(playernames) == nil then
						if mod_storage:get_string(playernames.."_party") == cparty then
							mod_storage:set_string(playernames.."_party", "@")
							-- open up the alliance name for taking
							mod_storage:set_string(playernames.."_officer", nil)
							mod_storage:set_string(playernames.."_leader", nil)
							mod_storage:set_string(playernames.."_lock", nil)
						end
					end
				end
				
				-- remove leader's powers
				mod_storage:set_string(name.."_party", nil)
				mod_storage:set_string(name.."_leader", nil)
				mod_storage:set_string(name.."_lock", nil)
				player:set_nametag_attributes({text = name})
			end
		
		elseif param1 == "rename" and param2 ~= nil then
			if party.check(name, 3) == true then
				return
			end
			-- check if new name is too long
			if string.len(param2) > 8 then
				party.send_notice(name, "Nametag is too long! 8 is the maximum amount of characters")
				return
			end
			if party.check_tag(name, param2) == true then
				return
			end
			-- if not, apply rename
			mod_storage:set_string(name.."_leader", param2)
			party.send_notice_all(name, name.." renamed the party tag to ["..param2.."].")
			
			-- update online player nametags
			for _,players in ipairs(minetest.get_connected_players()) do
				local names = players:get_player_name()
				if mod_storage:get_string(names.."_party") == cparty then
					players:set_nametag_attributes({text = "["..param2.."] "..names})
				end
			end
		
		elseif param1 == "lock" then
			if party.check(name, 3) == true then
				return
			end
			
			local cparty_l = mod_storage:get_string(name.."_leader")
			if param2 == "active" then
				mod_storage:set_string(name.."_lock", param2)
				party.send_notice_all(name, "[Active mode] Public joining (Only if leader is online) is enabled for "..name.."'s party ["..cparty_l.."].")
			elseif param2 == "request" then
				mod_storage:set_string(name.."_lock", param2)
				party.send_notice_all(name, "[Request mode] Join requests is enabled for "..name.."'s party ["..cparty_l.."].")
			elseif param2 == "private" then
				mod_storage:set_string(name.."_lock", param2)
				party.send_notice_all(name, "[Private mode] Public joining is disabled for "..name.."'s party ["..cparty_l.."].")
			elseif param2 == "open" then
				mod_storage:set_string(name.."_lock", nil)
				party.send_notice_all(name, "[Open mode] Public joining is enabled for "..name.."'s party ["..cparty_l.."].")
			end
		
		-- /p officer
		elseif param1 == "officer" and param2 ~= nil then
			if party.check(name, 3) == true then
				return
			end
			
			local cparty_l = mod_storage:get_string(name.."_leader")
			if minetest.player_exists(param2) then
			
				local target_party = mod_storage:get_string(param2.."_party")
				
				-- if player is not in same party
				if target_party ~= cparty then
					party.send_notice(name, "Player "..param2.." does not exist or is not in your party! Case sensitive.")
					return
				-- if player is in same party then promote/demote accordingly
				elseif target_party == cparty then
					local target_status = mod_storage:get_string(param2.."_officer")
					if target_status == "" then
						mod_storage:set_string(param2.."_officer", "true")
						party.send_notice_all(name, param2.." has been promoted to an officer!")
					elseif target_status ~= "" then
						mod_storage:set_string(param2.."_officer", nil)
						party.send_notice_all(name, param2.." has been demoted to a member.")
					end
				end
				
			else party.send_notice(name, "Player "..param2.." does not exist! Case sensitive.")
			end
			
		elseif param1 == "title" and param2 ~= nil and param3 ~= nil then
			if party.check(name, 3) == true then
				return
			end
			
			
			if minetest.player_exists(param2) then
				if cparty ~= mod_storage:get_string(param2.."_party") then
					party.send_notice(name, "Player "..param2.." is not in your party!")
					return
				end
			
				if (param3 == "remove" or param3 == "nil") then
					mod_storage:set_string(param2.."_title",nil)
					party.send_notice(name, "Player "..param2.."'s title has been removed")
				else
					mod_storage:set_string(param2.."_title",param3)
					party.send_notice(name, "Player "..param2.."'s title has been set to "..param3)
				end
			end
			
		-- /p kick
		elseif param1 == "kick"	and param2 ~= nil then
			if party.check(name, 2) == true then
				return
			end
			if minetest.player_exists(param2) then
				local cparty = mod_storage:get_string(param2.."_party")
				local self_cparty = mod_storage:get_string(name.."_party")
				-- attempt to kick self
				if param2 == name then
					party.send_notice(name, "You can't kick yourself!")
					return
				-- attempt to kick someone not from your party
				elseif self_cparty ~= cparty then
					party.send_notice(name, "Player "..param2.." does not exist or is not in your party! Case sensitive.")
					return
				-- attempt to kick leader
				elseif param2 == cparty then
					party.send_notice(name, "You can't kick the leader!")
					party.send_notice_all(name, name.." attempted to kick the leader.")
					return
				-- attempt to kick fellow officer (if officer too)
				elseif mod_storage:get_string(name.."_officer") ~= "" and mod_storage:get_string(param2.."_officer") ~= "" then
					party.send_notice(name, "You can't kick a fellow officer!")
					party.send_notice_all(name, name.." attempted to kick a fellow officer.")
					return
				end
				
				-- kicking offline player, give a mark to notify player when he logins
				if minetest.get_player_by_name(param2) == nil then
					party.send_notice_all(name, param2.."[offline] was kicked from "..cparty.."'s party ["..mod_storage:get_string(cparty.."_leader").."] by "..name)
					mod_storage:set_string(param2.."_party", "#")
					mod_storage:set_string(param2.."_officer", nil)
				end
				
				-- kicking online player
				if minetest.get_player_by_name(param2) ~= nil then
					party.send_notice_all(name, param2.." was kicked from "..cparty.."'s party ["..mod_storage:get_string(cparty.."_leader").."] by "..name)
					party.leave(param2)
				end
			
			-- if player doesn't exist
			else party.send_notice(name, "Player "..param2.." does not exist! Case sensitive.")
			end
			
		-- Accept/reject join request
		elseif (param1 == "accept" or param1 == "reject") and param2 ~= nil then
			if party.check(name, 2) == true then
				return
			end
			
			if minetest.player_exists(param2) then
				-- Reject if player is not online
				if minetest.get_player_by_name(param2) == nil then
					party.send_notice(name, "Player "..param2.." is not online right now.")
					return
				end
			
				local target_party = mod_storage:get_string(param2.."_party")
				-- Reject if player did not request to join the party
				if minetest.get_player_by_name(param2):get_attribute("partypending") ~= cparty then
					party.send_notice(name, "Player "..param2.." did not request to join the party!")
					return
				-- Reject if player is already in a party
				elseif target_party ~= "" then
					party.send_notice(name, "Player "..param2.." is already in a party!")
					return
				end
			
				local t_player = minetest.get_player_by_name(param2)
				local cparty_l = mod_storage:get_string(cparty.."_leader")
				if param1 == "accept" then
					t_player:set_attribute("partypending", nil)
					party.send_notice(param2, "Your request to join "..cparty.." ["..cparty_l.."] has been accepted!")
					party.join(param2, cparty)
				elseif param1 == "reject" then
					t_player:set_attribute("partypending", nil)
					party.send_notice(param2, "Your request to join "..cparty.." ["..cparty_l.."] was denied.")
					party.send_notice(name, "You have denied "..param2.."'s request.")
				end
			
			else party.send_notice(name, "Player "..param2.." does not exist!")
			end
		
		elseif param1 == "invite" then
			if cparty ~= "" then
				if party.check(name, 2) == true then
					return
				end
				if minetest.player_exists(param2) then
					-- reject if player is not online
					local target_party = mod_storage:get_string(param2.."_party")
					local t_player = minetest.get_player_by_name(param2)
					if minetest.get_player_by_name(param2) == nil then
						party.send_notice(name, "Player is not online!")
						return
					-- reject if player is already in a party
					elseif target_party ~= "" then
						party.send_notice(name, "Player is already in a party!")
						return
					-- reject if player disabled invites
					elseif t_player:get_attribute("partynoinvite") == "true" then
						party.send_notice(name, "Player has disabled invites!")
						return
					end
					
					local cparty_l = mod_storage:get_string(cparty.."_leader")
					t_player:set_attribute("partyinvite", name)
					party.send_notice(param2, name.." has invited you to "..cparty.."'s party ["..cparty_l.."]! '/p invite yes' to accept or '/p invite no' to decline.")
					party.send_notice(name, "You have invited "..param2.." to your party. Awaiting for their response.")
				
				-- player does not exist
				else party.send_notice(name, "Player "..param2.." does not exist! Case sensitive.")
				end
			elseif cparty == "" and param2 == "no" then
				if player:get_attribute("partyinvite") ~= nil then
					local iname = player:get_attribute("partyinvite")
					local iparty = mod_storage:get_string(iname.."_party")
					local iparty_l = mod_storage:get_string(iparty.."_leader")
					player:set_attribute("partyinvite", nil)
					party.send_notice(name, "You have rejected "..iname.."'s invite to join "..iparty.."'s party ["..iparty_l.."].")
					
					-- if player that sent request is online, send him a message.
					if minetest.get_player_by_name(iname) ~= nil then
						party.send_notice(iname, name.." has denied your invite request.")
					end
				else party.send_notice(name, "You have not received an invite!")
				end
			elseif cparty == "" and param2 == "yes" then
				if player:get_attribute("partyinvite") ~= nil then					
					local iname = player:get_attribute("partyinvite")
					local iparty = mod_storage:get_string(iname.."_party")
					local iparty_l = mod_storage:get_string(iparty.."_leader")
					
					-- if player that sent request is online, send him a message.
					if minetest.get_player_by_name(iparty) ~= nil then
						party.send_notice(iname, name.." has accepted your invite request.")
					end
					player:set_attribute("partyinvite", nil)
					party.join(name, iparty)
					
				else party.send_notice(name, "You have not received an invite!")
				end
			else party.send_notice(name, "You are not in a party!")
			end
			
		
		-- =======================
		-- ==== ADMIN COMMANDS ===
		-- =======================
		elseif param1 == "forcedisband" and param2 ~= nil then
			if not minetest.check_player_privs(name, {ban=true}) then
				party.send_notice(name, "You are not an admin!")
				return
			end
			
			if party.check_tag(name, param2) == true then
				local leadername = ""
				for _,playernames in ipairs(player_list) do
					if param2 == mod_storage:get_string(playernames.."_leader") then
						leadername = leadername .. playernames
					end
				end
				local cparty = leadername
				
				party.send_notice(name, "You have disbanded "..leadername.."'s party ["..param2.."]")
				party.send_notice_all(leadername, leadername.."'s party ["..mod_storage:get_string(leadername.."_leader").."] has been disbanded by "..name..", an admin")
				-- remove online players
				for _,players in ipairs(minetest.get_connected_players()) do
					local names = players:get_player_name()
					if mod_storage:get_string(names.."_party") == cparty then
						party.leave(names)
					end
				end
				-- mark offline players so they would be notified when they login
				for _,playernames in ipairs(player_list) do
					if minetest.get_player_by_name(playernames) == nil then
						if mod_storage:get_string(playernames.."_party") == cparty then
							mod_storage:set_string(playernames.."_party", "=")
							-- open up the alliance name for taking
							mod_storage:set_string(playernames.."_officer", nil)
							mod_storage:set_string(playernames.."_leader", nil)
							mod_storage:set_string(playernames.."_lock", nil)
						end
					end
				end
				
			else party.send_notice(name, "Party does not exist!")
			end
			
		elseif param1 == "forcejoin" and param2 ~= nil then
			if not minetest.check_player_privs(name, {ban=true}) then
				party.send_notice(name, "You are not an admin!")
				return
			end
			
			if cparty ~= "" then
				local cparty_l = mod_storage:get_string(cparty.."_leader")
				party.send_notice(name, "You are already in "..cparty.."'s party ["..cparty_l.."].")
				return
			end
			
			if party.check_tag(name, param2) == true then
				local leadername = ""
				for _,playernames in ipairs(player_list) do
					if param2 == mod_storage:get_string(playernames.."_leader") then
						leadername = leadername .. playernames
					end
				end
				local cparty = leadername
				party.join(name, cparty)
			end
	
		elseif param1 == "forcekick" and param2 ~= nil then
			if not minetest.check_player_privs(name, {kick=true}) then
				party.send_notice(name, "You are not a mod!")
				return
			end
			
			if minetest.player_exists(param2) then
				local cparty = mod_storage:get_string(param2.."_party")
				-- attempt to kick self
				if param2 == name then
					party.send_notice(name, "You can't kick yourself!")
					return
				-- attempt to kick player that doesn't have a party
				elseif cparty == "" then
					party.send_notice(name, param2.." is not in a party!")
					return
				-- attempt to kick leader
				elseif mod_storage:get_string(param2.."_leader") ~= "" then
					party.send_notice(name, "The leader can't be kicked! Use /p forcedisband instead.")
					return
				end
				
				-- kicking offline player, give a mark to notify player when he logins
				if minetest.get_player_by_name(param2) == nil then
					party.send_notice_all(param2, param2.."[offline] was kicked from "..cparty.."'s party ["..mod_storage:get_string(cparty.."_leader").."] by an admin, "..name)
					mod_storage:set_string(param2.."_party", "+")
					mod_storage:set_string(param2.."_officer", nil)
					party.send_notice(name, "Kicked "..param2.."[offline] from "..cparty.."'s party ["..mod_storage:get_string(cparty.."_leader").."]")
				else
					party.send_notice_all(param2, param2.." was kicked from "..cparty.."'s party ["..mod_storage:get_string(cparty.."_leader").."] by an admin, "..name)
					party.leave(param2)
					party.send_notice(name, "Kicked "..param2.." from "..cparty.."'s party ["..mod_storage:get_string(cparty.."_leader").."]")
				end
			end
		
		else party.send_notice(name, "ERROR: Command is invalid! For help, use the command '/p help'")
		end
		
	end,
})

minetest.register_chatcommand("all", {
	description = "Chat on main chat if in party.",
	privs = {shout=true},
	func = function(name, param)
		local player = minetest.get_player_by_name(name)
		local cparty = mod_storage:get_string(name.."_party")
		if cparty == "" then
			party.send_notice(name, "You are not in a party! You can talk normally to main chat without commands.")
		else
			local cparty_l = mod_storage:get_string(cparty.."_leader")
			for _,players in ipairs(minetest.get_connected_players()) do
				local names = players:get_player_name()
				minetest.chat_send_player(names, "<Party:"..cparty_l.." | "..name.."> "..param)
			end
		end
		
		-- chat logging
		if cparty ~= "" then
			minetest.log("action", "CHAT : <"..name.."> : "..param)
		end
	end,
})


minetest.register_on_chat_message(function(name, message)
	local player = minetest.get_player_by_name(name)
	local cparty = mod_storage:get_string(name.."_party")
	local cparty_title = mod_storage:get_string(name.."_title")
	
	-- check if player has shout privs
	if not minetest.check_player_privs(name, {shout=true}) then
		return
	end
	
	for _,players in ipairs(minetest.get_connected_players()) do
		local names = players:get_player_name()
		
		if string.match(message, "^@(.+)") then
			local cparty_l = mod_storage:get_string(cparty.."_leader")
			
			minetest.chat_send_player(names, "<Party:"..cparty_l.." | "..name.."> "..string.gsub(message, "^@", ""))
		end
		
		if cparty ~= "" and cparty == mod_storage:get_string(names.."_party") and not string.match(message, "^@(.+)") then
			if cparty_title ~= "" then
				minetest.chat_send_player(names, minetest.colorize("limegreen", "[Party]").." <"..minetest.colorize("lightgrey", cparty_title).." "..name.."> " ..message)
				party.chat_spy(names, message)
			elseif cparty_title == "" then
				minetest.chat_send_player(names, minetest.colorize("limegreen", "[Party]").." <"..name.."> " ..message)
				party.chat_spy(names, message)
			end
		end
	end

	-- main chat
	for _,players in ipairs(minetest.get_connected_players()) do
		local names = players:get_player_name()
		if cparty == "" then
			minetest.chat_send_player(names, "<"..name.."> " ..message)
			
		end
	end
	
	-- chat logging
	if cparty == "" then
		minetest.log("action", "CHAT : <"..name.."> : "..message)
	elseif cparty ~= "" then
		if string.match(message, "^@(.+)") then
			minetest.log("action", "CHAT : <"..name.."> : "..string.gsub(message, "^@", ""))
		else minetest.log("action", "CHAT [PARTY] : <"..name.."> : "..message)
		end
	end
	
	return true
end)

minetest.register_on_punchplayer(function(player, hitter, time_from_last_punch, tool_capabilities, dir, damage)
	if player and hitter then
		local playername = player:get_player_name()
		local hittername = hitter:get_player_name()
		local p_party = mod_storage:get_string(playername.."_party")
		local h_party = mod_storage:get_string(hittername.."_party")
		local p_pvp = player:get_attribute("partypvp")
		local h_pvp = hitter:get_attribute("partypvp")
		if p_party ~= "" and p_party == h_party then
			if (p_pvp == nil or h_pvp == nil) then
				party.send_notice(hitter:get_player_name(), player:get_player_name().." is in your party and has no friendly fire enabled!")
				return true
			end
		end
	end
end)

minetest.register_on_joinplayer(function(player)
	local name = player:get_player_name()
	local cparty = mod_storage:get_string(name.."_party")
	-- delete invite/join request status when player join, just in case.
	player:set_attribute("partypending", nil)
	player:set_attribute("partyinvite", nil)
	
	-- clear all stats (just in case) if player get kick / party is disbanded / data is corrupted
	if cparty == "@" then
		party.send_notice(name, "While you were away, your party has disbanded!")
		party.leave(name)
	elseif cparty == "#" then
		local cparty_l = mod_storage:get_string(cparty.."_leader")
		party.send_notice(name, "While you were away, you were kicked from your party!")
		party.leave(name)
	elseif cparty == "+" then
		local cparty_l = mod_storage:get_string(cparty.."_leader")
		party.send_notice(name, "While you were away, you were kicked from your party by an admin!")
		party.leave(name)
	elseif cparty == "=" then
		local cparty_l = mod_storage:get_string(cparty.."_leader")
		party.send_notice(name, "While you were away, your party was disbanded by an admin!")
		party.leave(name)
	elseif cparty ~= "" then
		local cparty_l = mod_storage:get_string(cparty.."_leader")
		if cparty_l == "" then
			party.send_notice(name, "ERROR: Unable to load your party's name.")
			party.send_notice(name, "ERROR: While you are away, you were either kicked or the party disbanded and was recreated.")
			party.send_notice(name, "ERROR: Otherwise something became corrupted :/")
			party.send_notice(name, "ERROR: Your party info has been reset.")
			party.leave(name)
			return
		else
			player:set_nametag_attributes({text = "["..cparty_l.."] "..name})
		end
	end
end)


minetest.register_on_leaveplayer(function(player)
	-- delete invite/join request status when player leaves
	player:set_attribute("partypending", nil)
	player:set_attribute("partyinvite", nil)
end)