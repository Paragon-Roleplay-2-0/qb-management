if not lib.checkDependency('ox_lib', '3.30.0', true) then return end

local QBCore = exports['qb-core']:GetCoreObject()

local oxInvState = GetResourceState('ox_inventory')

local ox_inventory = exports.ox_inventory

-- Get Employees
lib.callback.register('qb-gangmenu:server:GetEmployees', function(source, gangname)
	local src = source
	local Player = QBCore.Functions.GetPlayer(src)

	if not Player.PlayerData.gang.isboss then
		ExploitBan(src, 'Get Employees Exploiting')
		return
	end

	local employees = {}
	local players = MySQL.query.await("SELECT * FROM `players` WHERE `gang` LIKE '%" .. gangname .. "%'", {})
	if players[1] ~= nil then
		for _, value in pairs(players) do
			local Target = QBCore.Functions.GetPlayerByCitizenId(value.citizenid) or QBCore.Functions.GetOfflinePlayerByCitizenId(value.citizenid)

			if Target then
				local isOnline = Target.PlayerData.source
				employees[#employees + 1] = {
					empSource = Target.PlayerData.citizenid,
					grade = Target.PlayerData.gang.grade,
					isboss = Target.PlayerData.gang.isboss,
					name = (isOnline and '🟢 ' or '❌ ') .. Target.PlayerData.charinfo.firstname .. ' ' .. Target.PlayerData.charinfo.lastname
				}
			end
		end
	end

	return employees
end)

RegisterNetEvent('qb-gangmenu:server:stash', function()
	local src = source
	local Player = QBCore.Functions.GetPlayer(src)
	if not Player then return end
	local playerGang = Player.PlayerData.gang
	if not playerGang.isboss then return end
	local playerPed = GetPlayerPed(src)
	local playerCoords = GetEntityCoords(playerPed)
	if not Config.GangMenus[playerGang.name] then return end
	local bossCoords = Config.GangMenus[playerGang.name]
	for i = 1, #bossCoords do
		local coords = bossCoords[i]
		if #(playerCoords - coords) < 2.5 then
			local stashName = 'boss_' .. playerGang.name
			exports['qb-inventory']:OpenInventory(src, stashName, {
				maxweight = 400000,
				slots = 25,
			})
			return
		end
	end
end)

if Config.Inventory == 'ox' and oxInvState == 'started' then
	local gangStash = {
		id = 'gang_stash',
		label = 'Gang Boss Stash',
		slots = 25,
		weight = 400000,
		owner = true,
	}

	AddEventHandler('onServerResourceStart', function(resourceName)
		if resourceName == 'ox_inventory' or resourceName == GetCurrentResourceName() then
			ox_inventory:RegisterStash(gangStash.id, gangStash.label, gangStash.slots, gangStash.weight, gangStash.owner)
		end
	end)
end

-- Grade Change
RegisterNetEvent('qb-gangmenu:server:GradeUpdate', function(data)
	local src = source
	local Player = QBCore.Functions.GetPlayer(src)
	local Employee = QBCore.Functions.GetPlayerByCitizenId(data.cid) or QBCore.Functions.GetOfflinePlayerByCitizenId(data.cid)

	if not Player.PlayerData.gang.isboss then
		ExploitBan(src, 'Grade Update Exploiting')
		return
	end
	if data.grade > Player.PlayerData.gang.grade.level then
		if Config.Notify == 'qb' then
			TriggerClientEvent('QBCore:Notify', src, 'You cannot promote to this rank!', 'error')
		elseif Config.Notify == 'ox' then
			TriggerClientEvent('ox_lib:notify', src, {
				title = 'Promotion Error',
				description = 'You cannot promote to this rank!',
				position = 'center-right',
				type = 'error'
			})
		end
		return
	end

	if Employee then
		if Employee.Functions.SetGang(Player.PlayerData.gang.name, data.grade) then
			if Config.Notify == 'qb' then
				TriggerClientEvent('QBCore:Notify', src, 'Sucessfully promoted!', 'success')
			elseif Config.Notify == 'ox' then
				TriggerClientEvent('ox_lib:notify', src, {
					title = 'Promotion Successful',
					description = 'Successfully promoted!',
					position = 'center-right',
					type = 'success'
				})
			end
			Employee.Functions.Save()

			if Employee.PlayerData.source then
				if Config.Notify == 'qb' then
					TriggerClientEvent('QBCore:Notify', Employee.PlayerData.source, 'You have been promoted to ' .. data.gradename .. '.', 'success')
				elseif Config.Notify == 'ox' then
					TriggerClientEvent('ox_lib:notify', Employee.PlayerData.source, {
						title = 'Promoted!',
						description = 'You have been promoted to ' .. data.gradename .. '.',
						position = 'center-right',
						type = 'success'
					})
				end
			end
		else
			if Config.Notify == 'qb' then
				TriggerClientEvent('QBCore:Notify', src, 'Promotion grade does not exist.', 'error')
			elseif Config.Notify == 'ox' then
				TriggerClientEvent('ox_lib:notify', src, {
					title = 'Promotion Error',
					description = 'Promotion grade does not exist.',
					position = 'center-right',
					type = 'error'
				})
			end
		end
	end
	TriggerClientEvent('qb-gangmenu:client:OpenMenu', src)
end)

-- Fire Member
RegisterNetEvent('qb-gangmenu:server:FireMember', function(target)
	local src = source
	local Player = QBCore.Functions.GetPlayer(src)
	local Employee = QBCore.Functions.GetPlayerByCitizenId(target) or QBCore.Functions.GetOfflinePlayerByCitizenId(target)

	if not Player.PlayerData.gang.isboss then
		ExploitBan(src, 'Fire Employee Exploiting')
		return
	end

	if Employee then
		if target == Player.PlayerData.citizenid then
			if Config.Notify == 'qb' then
				TriggerClientEvent('QBCore:Notify', src, 'You can\'t kick yourself out of the gang!', 'error')
			elseif Config.Notify == 'ox' then
				TriggerClientEvent('ox_lib:notify', src, {
					title = 'Removal Error',
					description = 'You can\'t kick yourself out of the gang!',
					position = 'center-right',
					type = 'error'
				})
			end
			return
		elseif Employee.PlayerData.gang.grade.level > Player.PlayerData.gang.grade.level then
			if Config.Notify == 'qb' then
				TriggerClientEvent('QBCore:Notify', src, 'You cannot fire this citizen!', 'error')
			elseif Config.Notify == 'ox' then
				TriggerClientEvent('ox_lib:notify', src, {
					title = 'Termination Error',
					description = 'You cannot fire this citizen!',
					position = 'center-right',
					type = 'error'
				})
			end
			return
		end
		if Employee.Functions.SetGang('none', '0') then
			Employee.Functions.Save()
			if Config.Notify == 'qb' then
				TriggerClientEvent('QBCore:Notify', src, 'Gang Member fired!', 'success')
			elseif Config.Notify == 'ox' then
				TriggerClientEvent('ox_lib:notify', src, {
					title = 'Termination Successful',
					description = 'Gang Member fired!',
					position = 'center-right',
					type = 'success'
				})
			end
			TriggerEvent('qb-log:server:CreateLog', 'gangmenu', 'Gang Fire', 'orange', Player.PlayerData.charinfo.firstname .. ' ' .. Player.PlayerData.charinfo.lastname .. ' successfully fired ' .. Employee.PlayerData.charinfo.firstname .. ' ' .. Employee.PlayerData.charinfo.lastname .. ' (' .. Player.PlayerData.gang.name .. ')', false)
			if Employee.PlayerData.source then -- Player is online
				if Config.Notify == 'qb' then
					TriggerClientEvent('QBCore:Notify', Employee.PlayerData.source, 'You have been expelled from the gang! Good luck...', 'error')
				elseif Config.Notify == 'ox' then
					TriggerClientEvent('ox_lib:notify', Employee.PlayerData.source, {
						title = 'You\'re Fired!',
						description = 'You have been expelled from the gang! Good luck...',
						position = 'center-right',
						type = 'error'
					})
				end
			end
		else
			if Config.Notify == 'qb' then
				TriggerClientEvent('QBCore:Notify', src, 'Error...', 'error')
			elseif Config.Notify == 'ox' then
				TriggerClientEvent('ox_lib:notify', src, {
					title = 'Unknown Error',
					description = 'Error...',
					position = 'center-right',
					type = 'error'
				})
			end
		end
	end
	TriggerClientEvent('qb-gangmenu:client:OpenMenu', src)
end)

-- Recruit Player
RegisterNetEvent('qb-gangmenu:server:HireMember', function(recruit)
	local src = source
	local Player = QBCore.Functions.GetPlayer(src)
	local Target = QBCore.Functions.GetPlayer(recruit)

	if not Player.PlayerData.gang.isboss then
		ExploitBan(src, 'Hire Employee Exploiting')
		return
	end

	if Target and Target.Functions.SetGang(Player.PlayerData.gang.name, 0) then
		if Config.Notify == 'qb' then
			TriggerClientEvent('QBCore:Notify', src, 'You hired ' .. (Target.PlayerData.charinfo.firstname .. ' ' .. Target.PlayerData.charinfo.lastname) .. ' for ' .. Player.PlayerData.gang.label .. '.', 'success')
			TriggerClientEvent('QBCore:Notify', Target.PlayerData.source, 'You have been hired as ' .. Player.PlayerData.gang.label .. '.', 'success')
		elseif Config.Notify == 'ox' then
			TriggerClientEvent('ox_lib:notify', src, {
				title = 'Recruitment Successful',
				description = 'You hired ' .. (Target.PlayerData.charinfo.firstname .. ' ' .. Target.PlayerData.charinfo.lastname) .. ' for ' .. Player.PlayerData.gang.label .. '.',
				position = 'center-right',
				type = 'success'
			})
			TriggerClientEvent('ox_lib:notify', Target.PlayerData.source, {
				title = 'You\'re Hired!',
				description = 'You have been hired as ' .. Player.PlayerData.gang.label .. '.',
				position = 'center-right',
				type = 'success'
			})
		end
		TriggerEvent('qb-log:server:CreateLog', 'gangmenu', 'Recruit', 'yellow', (Player.PlayerData.charinfo.firstname .. ' ' .. Player.PlayerData.charinfo.lastname) .. ' successfully recruited ' .. Target.PlayerData.charinfo.firstname .. ' ' .. Target.PlayerData.charinfo.lastname .. ' (' .. Player.PlayerData.gang.name .. ')', false)
	end
	TriggerClientEvent('qb-gangmenu:client:OpenMenu', src)
end)

-- Get closest player sv
lib.callback.register('qb-gangmenu:getplayers', function(source)
	local src = source
	local players = {}
	local PlayerPed = GetPlayerPed(src)
	local pCoords = GetEntityCoords(PlayerPed)
	for _, v in pairs(QBCore.Functions.GetPlayers()) do
		local targetped = GetPlayerPed(v)
		local tCoords = GetEntityCoords(targetped)
		local dist = #(pCoords - tCoords)
		if PlayerPed ~= targetped and dist < 10 then
			local ped = QBCore.Functions.GetPlayer(v)
			players[#players + 1] = {
				id = v,
				coords = GetEntityCoords(targetped),
				name = ped.PlayerData.charinfo.firstname .. ' ' .. ped.PlayerData.charinfo.lastname,
				citizenid = ped.PlayerData.citizenid,
				sources = GetPlayerPed(ped.PlayerData.source),
				sourceplayer = ped.PlayerData.source
			}
		end
	end

	table.sort(players, function(a, b)
		return a.name < b.name
	end)

	return players
end)