if not lib.checkDependency('ox_lib', '3.30.0', true) then return end

local QBCore = exports['qb-core']:GetCoreObject()
local PlayerGang = QBCore.Functions.GetPlayerData().gang
local shownGangMenu = false
local DynamicMenuItems = {}

-- UTIL
local function CloseMenuFullGang()
    lib.hideContext()
    lib.hideTextUI()
    shownGangMenu = false
end

local function AddGangMenuItem(data, id)
    local menuID = id or (#DynamicMenuItems + 1)
    DynamicMenuItems[menuID] = deepcopy(data)
    return menuID
end

exports('AddGangMenuItem', AddGangMenuItem)

local function RemoveGangMenuItem(id)
    DynamicMenuItems[id] = nil
end

exports('RemoveGangMenuItem', RemoveGangMenuItem)

local function openGangStash()
    if Config.Inventory == 'ox' then
        if GetResourceState('ox_inventory') == 'started' and GetCurrentResourceName() then
            local ox_inventory = exports.ox_inventory
            ox_inventory:openInventory('stash', 'gang_stash')
        end
    end
end

-- Events
AddEventHandler('onResourceStart', function(resource) --if you restart the resource
    if resource == GetCurrentResourceName() then
        Wait(200)
        PlayerGang = QBCore.Functions.GetPlayerData().gang
    end
end)

RegisterNetEvent('QBCore:Client:OnPlayerLoaded', function()
    PlayerGang = QBCore.Functions.GetPlayerData().gang
end)

RegisterNetEvent('QBCore:Client:OnGangUpdate', function(InfoGang)
    PlayerGang = InfoGang
end)

RegisterNetEvent('qb-gangmenu:client:stash', function()
    openGangStash()
end)

RegisterNetEvent('qb-gangmenu:client:OpenMenu', function()
    if not PlayerGang.name or not PlayerGang.isboss then return end

    shownGangMenu = true

    if Config.Inventory == 'qb' then
        local menuOptions = {
            {
                title = Lang:t('bodygang.manage'),
                icon = 'fa-solid fa-list',
                iconColor = 'white',
                description = Lang:t('bodygang.managed'),
                arrow = true,
                event = 'qb-gangmenu:client:ManageGang'
            },
            {
                title = Lang:t('bodygang.hire'),
                icon = 'fa-solid fa-hand-holding',
                iconColor = 'white',
                description = Lang:t('bodygang.hired'),
                arrow = true,
                event = 'qb-gangmenu:client:HireMembers',
            },
            {
                title = Lang:t('bodygang.storage'),
                icon = 'fa-solid fa-box-open',
                iconColor = 'white',
                description = Lang:t('bodygang.storaged'),
                arrow = true,
                serverEvent = 'qb-gangmenu:server:stash',
            },
            {
                title = Lang:t('bodygang.outfits'),
                icon = 'fa-solid fa-shirt',
                iconColor = 'white',
                description = Lang:t('bodygang.outfitsd'),
                arrow = true,
                event = 'qb-gangmenu:client:Wardrobe',
            }
        }

        for _, v in pairs(DynamicMenuItems) do
            menuOptions[#menuOptions + 1] = v
        end

        lib.registerContext({
            id = 'gang_menu',
            title = Lang:t('headersgang.bsm') .. string.upper(PlayerGang.label),
            canClose = true,
            position = 'offcenter-right', -- Lation UI
            options = menuOptions
        })

        lib.showContext('gang_menu')
    elseif Config.Inventory == 'ox' then
        local menuOptions = {
            {
                title = Lang:t('bodygang.manage'),
                icon = 'fa-solid fa-list',
                iconColor = 'white',
                description = Lang:t('bodygang.managed'),
                arrow = true,
                event = 'qb-gangmenu:client:ManageGang'
            },
            {
                title = Lang:t('bodygang.hire'),
                icon = 'fa-solid fa-hand-holding',
                iconColor = 'white',
                description = Lang:t('bodygang.hired'),
                arrow = true,
                event = 'qb-gangmenu:client:HireMembers',
            },
            {
                title = Lang:t('bodygang.storage'),
                icon = 'fa-solid fa-box-open',
                iconColor = 'white',
                description = Lang:t('bodygang.storaged'),
                arrow = true,
                event = 'qb-gangmenu:client:stash',
            },
            {
                title = Lang:t('bodygang.outfits'),
                icon = 'fa-solid fa-shirt',
                iconColor = 'white',
                description = Lang:t('bodygang.outfitsd'),
                arrow = true,
                event = 'qb-gangmenu:client:Wardrobe',
            }
        }

        for _, v in pairs(DynamicMenuItems) do
            menuOptions[#menuOptions + 1] = v
        end

        lib.registerContext({
            id = 'gang_menu',
            title = Lang:t('headersgang.bsm') .. string.upper(PlayerGang.label),
            canClose = true,
            position = 'offcenter-right', -- Lation UI
            options = menuOptions
        })

        lib.showContext('gang_menu')
    end
end)

RegisterNetEvent('qb-gangmenu:client:ManageGang', function()
    lib.callback('qb-gangmenu:server:GetEmployees', false, function(employees)
        local menuOptions = {}

        for _, v in pairs(employees) do
            menuOptions[#menuOptions + 1] = {
                title = v.name,
                icon = 'fa-solid fa-circle-user',
                iconColor = 'white',
                description = v.grade.name,
                event = 'qb-gangmenu:client:ManageMember',
                args = {
                    player = v,
                    work = PlayerGang
                }
            }
        end

        lib.registerContext({
            id = 'manage_menu',
            title = Lang:t('bodygang.mempl') .. string.upper(PlayerGang.label),
            menu = 'gang_menu',
            options = menuOptions
        })

        lib.showContext('manage_menu')
    end, PlayerGang.name)
end)

RegisterNetEvent('qb-gangmenu:client:ManageMember', function(data)
    local menuOptions = {}
    for i, v in pairs(QBCore.Shared.Gangs[data.work.name].grades) do
        menuOptions[#menuOptions + 1] = {
            title = v.name,
            icon = 'fa-solid fa-file-pen',
            iconColor = 'white',
            description = Lang:t('body.grade') .. i,
            serverEvent = 'qb-gangmenu:server:GradeUpdate',
            args = {
                cid = data.player.empSource,
                grade = tonumber(i),
                gradename = v.name
            }
        }
    end

    menuOptions[#menuOptions + 1] = {
        title = Lang:t('bodygang.fireemp'),
        icon = 'fa-solid fa-user-large-slash',
        iconColor = 'white',
        description = 'Fire gang member',
        serverEvent = 'qb-gangmenu:server:FireMember',
        args = data.player.empSource
    }

    lib.registerContext({
        id = 'member_menu',
        title = Lang:t('bodygang.mngpl') .. data.player.name .. ' - ' .. string.upper(PlayerGang.label),
        menu = 'gang_menu',
        options = menuOptions
    })

    lib.showContext('member_menu')
end)

RegisterNetEvent('qb-gangmenu:client:Wardrobe', function()
    TriggerEvent('qb-clothing:client:openOutfitMenu')
end)

RegisterNetEvent('qb-gangmenu:client:HireMembers', function()
    lib.callback('qb-gangmenu:getplayers', false, function(players)
        local menuOptions = {}

        for _, v in pairs(players) do
            if v and v ~= PlayerId() then
                menuOptions[#menuOptions + 1] = {
                    title = v.name,
                    icon = 'fa-solid fa-user-check',
                    iconColor = 'white',
                    description = Lang:t('bodygang.cid') .. v.citizenid .. ' - ID: ' .. v.sourceplayer,
                    serverEvent = 'qb-gangmenu:server:HireMember',
                    args = v.sourceplayer
                }
            end
        end

        lib.registerContext({
            id = 'hire_menu',
            title = Lang:t('bodygang.hireemp') .. string.upper(PlayerGang.label),
            menu = 'gang_menu',
            options = menuOptions
        })

        lib.showContext('hire_menu')
    end)
end)

-- MAIN THREAD
CreateThread(function()
    if Config.UseTarget then
        for gang, zones in pairs(Config.GangMenus) do
            for index, coords in ipairs(zones) do
                local zoneName = gang .. '_gangmenu_' .. index
                exports['qb-target']:AddCircleZone(zoneName, coords, 0.5, {
                    name = zoneName,
                    debugPoly = false,
                    useZ = true
                }, {
                    options = {
                        {
                            type = 'client',
                            event = 'qb-gangmenu:client:OpenMenu',
                            icon = 'fas fa-sign-in-alt',
                            label = Lang:t('targetgang.label'),
                            canInteract = function() return gang == PlayerGang.name and PlayerGang.isboss end,
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
            local inRangeGang = false
            local nearGangmenu = false
            if PlayerGang then
                wait = 0
                for k, menus in pairs(Config.GangMenus) do
                    for _, coords in ipairs(menus) do
                        if k == PlayerGang.name and PlayerGang.isboss then
                            if #(pos - coords) < 5.0 then
                                inRangeGang = true
                                if #(pos - coords) <= 1.5 then
                                    nearGangmenu = true
                                    if not shownGangMenu then
                                        lib.showTextUI(Lang:t('drawtextgang.label'), { position = 'left-center' })
                                        shownGangMenu = true
                                    end

                                    if IsControlJustReleased(0, 38) then
                                        lib.hideTextUI()
                                        TriggerEvent('qb-gangmenu:client:OpenMenu')
                                    end
                                end

                                if not nearGangmenu and shownGangMenu then
                                    CloseMenuFullGang()
                                    shownGangMenu = false
                                end
                            end
                        end
                    end
                end
                if not inRangeGang then
                    Wait(1500)
                    if shownGangMenu then
                        CloseMenuFullGang()
                        shownGangMenu = false
                    end
                end
            end
            Wait(wait)
        end
    end
end)