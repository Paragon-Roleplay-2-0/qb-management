Config = Config or {}

Config.Notify = 'ox' -- supported: 'ox' or 'qb'

Config.Inventory = 'ox' -- supported: 'ox' or 'qb'

Config.UseTarget = GetConvar('UseTarget', 'false') == 'true' -- Use qb-target interactions (don't change this, go to your server.cfg and add `setr UseTarget true` to use this and just that from true to false or the other way around)

-- Zones for Menus
Config.BossMenus = {
    police = {
        vector3(434.69, -999.03, 35.68), -- Kiiya MRPD
    },
    ambulance = {
        vector3(311.21, -599.36, 43.29),
    },
    cardealer = {
        vector3(-32.94, -1114.64, 26.42),
    },
    mechanic = {
        vector3(-347.59, -133.35, 39.01),
    },
    lssd = {
        vector3(1824.84, 3690.89, 39.13), -- G&N Sandy Sheriff's Department
    }
}

Config.GangMenus = {
    lostmc = {
        vector3(0, 0, 0),
    },
    ballas = {
        vector3(0, 0, 0),
    },
    vagos = {
        vector3(0, 0, 0),
    },
    cartel = {
        vector3(0, 0, 0),
    },
    families = {
        vector3(0, 0, 0),
    },
}