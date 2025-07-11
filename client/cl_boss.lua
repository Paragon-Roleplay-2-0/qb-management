if not lib.checkDependency('ox_lib', '3.30.0', true) then return end

local QBCore = exports['qb-core']:GetCoreObject()
local PlayerJob = QBCore.Functions.GetPlayerData().job
local shownBossMenu = false
local DynamicMenuItems = {}

-- UTIL
local function CloseMenuFull()
    lib.hideContext()
    lib.hideTextUI()
    shownBossMenu = false
end

local function AddBossMenuItem(data, id)
    local menuID = id or (#DynamicMenuItems + 1)
    DynamicMenuItems[menuID] = deepcopy(data)
    return menuID
end

exports('AddBossMenuItem', AddBossMenuItem)

local function RemoveBossMenuItem(id)
    DynamicMenuItems[id] = nil
end

exports('RemoveBossMenuItem', RemoveBossMenuItem)

local function openBossStash()
    if Config.Inventory == 'ox' then
        if GetResourceState('ox_inventory') == 'started' and GetCurrentResourceName() then
            local ox_inventory = exports.ox_inventory
            ox_inventory:openInventory('stash', 'boss_stash')
        end
    end
end

-- Events
AddEventHandler('onResourceStart', function(resource)
    if resource == GetCurrentResourceName() then
        PlayerJob = QBCore.Functions.GetPlayerData().job
    end
end)

RegisterNetEvent('QBCore:Client:OnPlayerLoaded', function()
    PlayerJob = QBCore.Functions.GetPlayerData().job
end)

RegisterNetEvent('QBCore:Client:OnJobUpdate', function(JobInfo)
    PlayerJob = JobInfo
end)

RegisterNetEvent('qb-bossmenu:client:stash', function()
    openBossStash()
end)

RegisterNetEvent('qb-bossmenu:client:OpenMenu', function()
    if not PlayerJob.name or not PlayerJob.isboss then return end

    shownBossMenu = true

    if Config.Inventory == 'qb' then
        local menuOptions = {
            {
                title = Lang:t('body.manage'),
                icon = 'fa-solid fa-list',
                iconColor = 'white',
                description = Lang:t('body.managed'),
                arrow = true,
                event = 'qb-bossmenu:client:employeelist'
            },
            {
                title = Lang:t('body.hire'),
                icon = 'fa-solid fa-hand-holding',
                iconColor = 'white',
                description = Lang:t('body.hired'),
                arrow = true,
                event = 'qb-bossmenu:client:HireMenu'
            },
            {
                title = Lang:t('body.storage'),
                icon = 'fa-solid fa-box-open',
                iconColor = 'white',
                description = Lang:t('body.storaged'),
                arrow = true,
                serverEvent = 'qb-bossmenu:server:stash'
            },
            {
                title = Lang:t('body.outfits'),
                icon = 'fa-solid fa-shirt',
                iconColor = 'white',
                description = Lang:t('body.outfitsd'),
                arrow = true,
                event = 'qb-bossmenu:client:Wardrobe'
            }
        }

        for _, v in pairs(DynamicMenuItems) do
            menuOptions[#menuOptions + 1] = v
        end

        lib.registerContext({
            id = 'boss_menu',
            title = Lang:t('headers.bsm') .. string.upper(PlayerJob.label),
            canClose = true,
            position = 'offcenter-right', -- Lation UI
            options = menuOptions
        })

        lib.showContext('boss_menu')
    elseif Config.Inventory == 'ox' then
        local menuOptions = {
            {
                title = Lang:t('body.manage'),
                icon = 'fa-solid fa-list',
                iconColor = 'white',
                description = Lang:t('body.managed'),
                arrow = true,
                event = 'qb-bossmenu:client:employeelist'
            },
            {
                title = Lang:t('body.hire'),
                icon = 'fa-solid fa-hand-holding',
                iconColor = 'white',
                description = Lang:t('body.hired'),
                arrow = true,
                event = 'qb-bossmenu:client:HireMenu'
            },
            {
                title = Lang:t('body.storage'),
                icon = 'fa-solid fa-box-open',
                iconColor = 'white',
                description = Lang:t('body.storaged'),
                arrow = true,
                event = 'qb-bossmenu:client:stash'
            },
            {
                title = Lang:t('body.outfits'),
                icon = 'fa-solid fa-shirt',
                iconColor = 'white',
                description = Lang:t('body.outfitsd'),
                arrow = true,
                event = 'qb-bossmenu:client:Wardrobe'
            }
        }

        for _, v in pairs(DynamicMenuItems) do
            menuOptions[#menuOptions + 1] = v
        end

        lib.registerContext({
            id = 'boss_menu',
            title = Lang:t('headers.bsm') .. string.upper(PlayerJob.label),
            canClose = true,
            position = 'offcenter-right', -- Lation UI
            options = menuOptions
        })

        lib.showContext('boss_menu')
    end
end)

RegisterNetEvent('qb-bossmenu:client:employeelist', function()
    lib.callback('qb-bossmenu:server:GetEmployees', false, function(employees)
        local menuOptions = {}

        for _, v in pairs(employees) do
            menuOptions[#menuOptions + 1] = {
                title = v.name,
                icon = 'fa-solid fa-circle-user',
                iconColor = 'white',
                description = v.grade.name,
                event = 'qb-bossmenu:client:ManageEmployee',
                args = {
                    player = v,
                    work = PlayerJob
                }
            }
        end

        lib.registerContext({
            id = 'manage_menu',
            title = Lang:t('body.mempl') .. string.upper(PlayerJob.label),
            menu = 'boss_menu',
            position = 'offcenter-right', -- Lation UI
            options = menuOptions
        })

        lib.showContext('manage_menu')
    end, PlayerJob.name)
end)

RegisterNetEvent('qb-bossmenu:client:ManageEmployee', function(data)
    local menuOptions = {}
    for i, v in pairs(QBCore.Shared.Jobs[data.work.name].grades) do
        menuOptions[#menuOptions + 1] = {
            title = v.name,
            icon = 'fa-solid fa-file-pen',
            iconColor = 'white',
            description = Lang:t('body.grade') .. i,
            serverEvent = 'qb-bossmenu:server:GradeUpdate',
            args = {
                cid = data.player.empSource,
                grade = tonumber(i),
                gradename = v.name
            }
        }
    end

    menuOptions[#menuOptions + 1] = {
        title = Lang:t('body.fireemp'),
        icon = 'fa-solid fa-user-large-slash',
        iconColor = 'white',
        description = 'Fire employee',
        serverEvent = 'qb-bossmenu:server:FireEmployee',
        args = data.player.empSource
    }

    lib.registerContext({
        id = 'employee_menu',
        title = Lang:t('body.mngpl') .. data.player.name .. ' - ' .. string.upper(PlayerJob.label),
        menu = 'boss_menu',
        position = 'offcenter-right', -- Lation UI
        options = menuOptions
    })

    lib.showContext('employee_menu')
end)

RegisterNetEvent('qb-bossmenu:client:Wardrobe', function()
    TriggerEvent('qb-clothing:client:openOutfitMenu')
end)

RegisterNetEvent('qb-bossmenu:client:HireMenu', function()
    lib.callback('qb-bossmenu:getplayers', false, function(players)
        local menuOptions = {}
        for _, v in pairs(players) do
            if v and v ~= PlayerId() then
                menuOptions[#menuOptions + 1] = {
                    title = v.name,
                    icon = 'fa-solid fa-user-check',
                    iconColor = 'white',
                    description = Lang:t('body.cid') .. v.citizenid .. ' - ID: ' .. v.sourceplayer,
                    serverEvent = 'qb-bossmenu:server:HireEmployee',
                    args = v.sourceplayer
                }
            end
        end

        lib.registerContext({
            id = 'hire_menu',
            title = Lang:t('body.hireemp') .. string.upper(PlayerJob.label),
            menu = 'boss_menu',
            position = 'offcenter-right', -- Lation UI
            options = menuOptions
        })

        lib.showContext('hire_menu')
    end)
end)

-- MAIN THREAD
CreateThread(function()
    if Config.UseTarget then
        for job, zones in pairs(Config.BossMenus) do
            for index, coords in ipairs(zones) do
                local zoneName = job .. '_bossmenu_' .. index
                exports['qb-target']:AddCircleZone(zoneName, coords, 0.5, {
                    name = zoneName,
                    debugPoly = false,
                    useZ = true
                }, {
                    options = {
                        {
                            type = 'client',
                            event = 'qb-bossmenu:client:OpenMenu',
                            icon = 'fas fa-sign-in-alt',
                            label = Lang:t('target.label'),
                            canInteract = function() return job == PlayerJob.name and PlayerJob.isboss end,
                        },
                    },
                    distance = 3.0
                })
            end
        end
    else
        while true do
            local wait = 2500
            local pos = GetEntityCoords(PlayerPedId())
            local inRangeBoss = false
            local nearBossmenu = false
            if PlayerJob then
                wait = 0
                for k, menus in pairs(Config.BossMenus) do
                    for _, coords in ipairs(menus) do
                        if k == PlayerJob.name and PlayerJob.isboss then
                            if #(pos - coords) < 5.0 then
                                inRangeBoss = true
                                if #(pos - coords) <= 1.5 then
                                    nearBossmenu = true
                                    if not shownBossMenu then
                                        lib.showTextUI(Lang:t('drawtext.label'), { position = 'left-center' })
                                        shownBossMenu = true
                                    end
                                    if IsControlJustReleased(0, 38) then
                                        lib.hideTextUI()
                                        TriggerEvent('qb-bossmenu:client:OpenMenu')
                                    end
                                end

                                if not nearBossmenu and shownBossMenu then
                                    CloseMenuFull()
                                    shownBossMenu = false
                                end
                            end
                        end
                    end
                end
                if not inRangeBoss then
                    Wait(1500)
                    if shownBossMenu then
                        CloseMenuFull()
                        shownBossMenu = false
                    end
                end
            end
            Wait(wait)
        end
    end
end)