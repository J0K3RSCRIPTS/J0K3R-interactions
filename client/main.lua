local PickerIsOpen        = false
local CurrentInteraction  = nil
local InteractionMarker   = nil
local StartingCoords      = nil
local CanStartInteraction = true
local MaxRadius           = 0.0
local NearbyAvailable     = false
local NearbyActionLabel   = nil
local OpenPrompt          = nil
local LastPromptText      = nil
local NextRestartAttempt  = 0

local function GetNearbyObjects(coords)
    local itemset = CreateItemset(true)
    local size    = Citizen.InvokeNative(0x59B57C4B06531E1E, coords, MaxRadius, itemset, 3, Citizen.ResultAsInteger())
    local objects = {}

    if size > 0 then
        for i = 0, size - 1 do
            objects[#objects + 1] = GetIndexedItemInItemset(i, itemset)
        end
    end

    if IsItemsetValid(itemset) then
        DestroyItemset(itemset)
    end

    return objects
end

local function HasCompatibleModel(entity, models)
    local entityModel = GetEntityModel(entity)
    for i = 1, #models do
        if entityModel == GetHashKey(models[i]) then
            return models[i]
        end
    end
    return nil
end

local function CanStartAtObject(interaction, object, playerCoords, objectCoords)
    if #(playerCoords - objectCoords) > interaction.radius then
        return nil
    end
    return HasCompatibleModel(object, interaction.objects)
end

local function IsCompatible(t, ped)
    return not t.isCompatible or t.isCompatible(ped)
end

local function PlayAnimation(ped, anim)
    if not LoadAnimDict(anim.dict) then
        print(('[J0K3R-interactions] Animation dict konnte nicht geladen werden: %s'):format(anim.dict))
        return
    end
    TaskPlayAnim(ped, anim.dict, anim.name, 0.0, 0.0, -1, 1, 1.0, false, false, false, '', false)
    RemoveAnimDict(anim.dict)
end

local ScenarioProps = {
    PROP_HUMAN_SEAT_BENCH_FIDDLE         = { `p_violin01x`, `p_violinBow01x` },
    PROP_HUMAN_SEAT_BENCH_CONCERTINA     = { `p_concertina01x` },
    PROP_HUMAN_SEAT_BENCH_JAW_HARP       = { `p_jawharp01x` },
    PROP_HUMAN_SEAT_BENCH_MANDOLIN       = { `p_mandolin01x` },
    PROP_HUMAN_SEAT_CHAIR_BANJO          = { `p_banjo01x` },
    PROP_HUMAN_SEAT_CHAIR_GUITAR         = { `p_guitarAcoustic01x` },
    PROP_HUMAN_SEAT_CHAIR_CIGAR          = { `p_cigar01x`, `p_cigar02x` },
    PROP_HUMAN_SEAT_CHAIR_KNITTING       = { `p_knittingNeedles01x`, `p_knittingYarn01x` },
    PROP_HUMAN_SEAT_CHAIR_KNIFE_BADASS   = { `p_knife01x` },
    PROP_HUMAN_SEAT_CHAIR_CLEAN_RIFLE    = { `p_rifle01x` },
    PROP_HUMAN_SEAT_CHAIR_CLEAN_SADDLE   = { `p_saddle01x` },
    PROP_HUMAN_SEAT_CHAIR_READING        = { `p_book01x`, `p_book02x` },
    PROP_HUMAN_SEAT_CHAIR_TABLE_DRINKING = { `p_whiskeybottle01x`, `p_glassWhiskey01x` },
    MP_LOBBY_PROP_HUMAN_SEAT_BENCH_PORCH_DRINKING = { `p_whiskeybottle01x`, `p_glassWhiskey01x` },
    MP_LOBBY_PROP_HUMAN_SEAT_BENCH_PORCH_SMOKING  = { `p_cigarette01x` },
    MP_LOBBY_PROP_HUMAN_SEAT_CHAIR_KNIFE_BADASS   = { `p_knife01x` },
    MP_LOBBY_PROP_HUMAN_SEAT_CHAIR_WHITTLE        = { `p_knife01x`, `p_woodCarving01x` },
}

local function CleanupScenarioProps(scenarioName)
    if not scenarioName then return end
    local props = ScenarioProps[scenarioName]
    if not props then return end

    local ped = PlayerPedId()
    local pedCoords = GetEntityCoords(ped)

    for i = 1, #props do
        local hash = props[i]
        local found = GetClosestObjectOfType(pedCoords.x, pedCoords.y, pedCoords.z, 2.5, hash, false, true, true)
        if found ~= 0 and DoesEntityExist(found) then
            SetEntityAsMissionEntity(found, false, false)
            DeleteObject(found)
        end
    end
end

local function StartInteractionAtCoords(interaction)
    local x, y, z, h = interaction.x, interaction.y, interaction.z, interaction.heading
    local ped = PlayerPedId()

    if not StartingCoords then
        StartingCoords = GetEntityCoords(ped)
    end

    local previousScenario = CurrentInteraction and CurrentInteraction.scenario

    ClearPedTasksImmediately(ped)
    Citizen.InvokeNative(0x4899CB088EDF59B8, ped)
    CleanupScenarioProps(previousScenario)
    FreezeEntityPosition(ped, true)

    if interaction.scenario then
        TaskStartScenarioAtPosition(ped, GetHashKey(interaction.scenario), x, y, z, h, -1, false, true)
    elseif interaction.animation then
        SetEntityCoordsNoOffset(ped, x, y, z)
        SetEntityHeading(ped, h)
        PlayAnimation(ped, interaction.animation)
    end

    if interaction.effect and Config.Effects[interaction.effect] then
        Config.Effects[interaction.effect]()
    end

    CurrentInteraction = interaction
end

local function StartInteractionAtObject(interaction)
    local objectHeading = GetEntityHeading(interaction.object)
    local objectCoords  = GetEntityCoords(interaction.object)

    local r    = math.rad(objectHeading)
    local cosr = math.cos(r)
    local sinr = math.sin(r)

    local localX = interaction.x
    local localY = interaction.y

    interaction.x       = localX * cosr - localY * sinr + objectCoords.x
    interaction.y       = localX * sinr + localY * cosr + objectCoords.y
    interaction.z       = interaction.z + objectCoords.z
    interaction.heading = interaction.heading + objectHeading

    StartInteractionAtCoords(interaction)
end

local function StopInteraction()
    local previousScenario = CurrentInteraction and CurrentInteraction.scenario
    CurrentInteraction = nil
    local ped = PlayerPedId()

    ClearPedTasksImmediately(ped)
    Citizen.InvokeNative(0x4899CB088EDF59B8, ped)
    CleanupScenarioProps(previousScenario)
    FreezeEntityPosition(ped, false)
    Citizen.Wait(100)

    if StartingCoords then
        SetEntityCoordsNoOffset(ped, StartingCoords.x, StartingCoords.y, StartingCoords.z)
        StartingCoords = nil
    end
end

local function IsPedUsingInteraction(ped, interaction)
    if interaction.scenario then
        return IsPedUsingScenarioHash(ped, GetHashKey(interaction.scenario))
    elseif interaction.animation then
        return IsEntityPlayingAnim(ped, interaction.animation.dict, interaction.animation.name, 1)
    end
    return false
end

local function SetMarker(target)
    InteractionMarker = target
end

local function DrawMarker()
    local x, y, z
    if type(InteractionMarker) == 'number' then
        x, y, z = table.unpack(GetEntityCoords(InteractionMarker))
    else
        x, y, z = table.unpack(InteractionMarker)
    end
    DrawInteractionMarker(Config.Marker.type, x, y, z, Config.Marker.color)
end

local function BuildDisplayLabel(entry)
    local locale = L()
    local parts  = {}

    if entry.category then
        local cat = TranslateCategory(entry.category)
        if cat then parts[#parts + 1] = cat end
    end

    local action
    if entry.scenario then
        action = TranslateScenario(entry.scenario)
    elseif entry.animation then
        action = TranslateAnimation(entry.animation.labelKey)
    end

    if action then
        if #parts > 0 then
            parts[#parts] = parts[#parts] .. ': ' .. action
        else
            parts[#parts + 1] = action
        end
    end

    if entry.label then
        local pos = TranslatePosition(entry.label)
        if pos then parts[#parts] = parts[#parts] .. ' (' .. pos .. ')' end
    end

    return table.concat(parts, ' ')
end

local function ResolvePromptLabel(available)
    local locale       = L()
    local promptLocale = locale.prompt or {}
    local actions      = promptLocale.actions or {}

    if #available == 0 then return nil end

    local firstCategory = available[1].category
    local allSame       = firstCategory ~= nil
    if allSame then
        for i = 2, #available do
            if available[i].category ~= firstCategory then
                allSame = false
                break
            end
        end
    end

    if allSame and actions[firstCategory] then
        return actions[firstCategory]
    end

    return promptLocale.action or 'Interact'
end

local function CreateOpenPrompt()
    if OpenPrompt then return end
    local locale = L()
    local label  = (locale.prompt and locale.prompt.action) or 'Interact'

    OpenPrompt = PromptRegisterBegin()
    PromptSetControlAction(OpenPrompt, Config.OpenKey)
    PromptSetText(OpenPrompt, CreateVarString(10, 'LITERAL_STRING', label))
    PromptSetEnabled(OpenPrompt, false)
    PromptSetVisible(OpenPrompt, false)
    PromptSetStandardMode(OpenPrompt, true)
    PromptRegisterEnd(OpenPrompt)
    LastPromptText = label
end

local function DestroyOpenPrompt()
    if not OpenPrompt then return end
    PromptDelete(OpenPrompt)
    OpenPrompt     = nil
    LastPromptText = nil
end

local function UpdateOpenPrompt()
    if not OpenPrompt then return end

    local shouldShow = NearbyAvailable
        and CanStartInteraction
        and not PickerIsOpen
        and not CurrentInteraction

    if shouldShow then
        if NearbyActionLabel and NearbyActionLabel ~= LastPromptText then
            PromptSetText(OpenPrompt, CreateVarString(10, 'LITERAL_STRING', NearbyActionLabel))
            LastPromptText = NearbyActionLabel
        end
        PromptSetEnabled(OpenPrompt, true)
        PromptSetVisible(OpenPrompt, true)
    else
        PromptSetEnabled(OpenPrompt, false)
        PromptSetVisible(OpenPrompt, false)
    end
end

local function CollectInteractions(list, interaction, ped, playerCoords, targetCoords, modelName, object)
    local distance = #(playerCoords - targetCoords)

    if interaction.scenarios then
        for i = 1, #interaction.scenarios do
            local scenario = interaction.scenarios[i]
            if IsCompatible(scenario, ped) then
                list[#list + 1] = {
                    x = interaction.x, y = interaction.y, z = interaction.z, heading = interaction.heading,
                    scenario   = scenario.name,
                    object     = object,
                    modelName  = modelName,
                    distance   = distance,
                    label      = interaction.label,
                    category   = interaction.category,
                    effect     = interaction.effect,
                    displayLabel = nil,
                }
            end
        end
    end

    if interaction.animations then
        for i = 1, #interaction.animations do
            local animation = interaction.animations[i]
            if IsCompatible(animation, ped) then
                list[#list + 1] = {
                    x = interaction.x, y = interaction.y, z = interaction.z, heading = interaction.heading,
                    animation  = animation,
                    object     = object,
                    modelName  = modelName,
                    distance   = distance,
                    label      = interaction.label,
                    category   = interaction.category,
                    effect     = interaction.effect,
                    displayLabel = nil,
                }
            end
        end
    end
end

local function GetAvailableInteractions()
    local ped          = PlayerPedId()
    local playerCoords = GetEntityCoords(ped)
    local available    = {}
    local nearbyCache  = nil

    for i = 1, #Interactions do
        local interaction = Interactions[i]
        if IsCompatible(interaction, ped) then
            if interaction.objects then
                if not nearbyCache then
                    nearbyCache = GetNearbyObjects(playerCoords)
                end
                for j = 1, #nearbyCache do
                    local object       = nearbyCache[j]
                    local objectCoords = GetEntityCoords(object)
                    local modelName    = CanStartAtObject(interaction, object, playerCoords, objectCoords)
                    if modelName then
                        CollectInteractions(available, interaction, ped, playerCoords, objectCoords, modelName, object)
                    end
                end
            else
                local target = vector3(interaction.x, interaction.y, interaction.z)
                if #(playerCoords - target) <= interaction.radius then
                    CollectInteractions(available, interaction, ped, playerCoords, target)
                end
            end
        end
    end

    table.sort(available, function(a, b)
        if a.distance ~= b.distance then return a.distance < b.distance end
        if a.object   ~= b.object   then return (a.object or 0) < (b.object or 0) end
        local aLabel = a.scenario or (a.animation and a.animation.labelKey) or ''
        local bLabel = b.scenario or (b.animation and b.animation.labelKey) or ''
        return aLabel < bLabel
    end)

    for i = 1, #available do
        available[i].displayLabel = BuildDisplayLabel(available[i])
    end

    return available
end

local function OpenPicker()
    if PickerIsOpen or not CanStartInteraction then return end

    local available = GetAvailableInteractions()

    if #available == 0 then
        if CurrentInteraction then
            StopInteraction()
        end
        return
    end

    local locale = L()

    SendNUIMessage({
        type         = 'showInteractionPicker',
        interactions = json.encode(available),
        title        = locale.menu.title,
        cancelLabel  = locale.menu.end_,
        theme        = Config.Theme,
    })

    PickerIsOpen = true
    UpdateOpenPrompt()
end

local function ClosePicker(startSelected)
    SendNUIMessage({
        type    = startSelected and 'startInteraction' or 'hideInteractionPicker',
    })
    SetMarker(nil)
    PickerIsOpen = false
end

RegisterNUICallback('startInteraction', function(data, cb)
    if data.object and data.object ~= 0 then
        StartInteractionAtObject(data)
    else
        StartInteractionAtCoords(data)
    end
    cb({})
end)

RegisterNUICallback('stopInteraction', function(data, cb)
    StopInteraction()
    cb({})
end)

RegisterNUICallback('setInteractionMarker', function(data, cb)
    if data.entity and data.entity ~= 0 then
        SetMarker(data.entity)
    elseif data.x and data.y and data.z then
        SetMarker(vector3(data.x, data.y, data.z))
    else
        SetMarker(nil)
    end
    cb({})
end)

RegisterCommand('interact', function()
    if PickerIsOpen then
        ClosePicker(false)
    elseif CurrentInteraction then
        StopInteraction()
    else
        OpenPicker()
    end
end, false)

Citizen.CreateThread(function()
    for i = 1, #Interactions do
        if Interactions[i].radius and Interactions[i].radius > MaxRadius then
            MaxRadius = Interactions[i].radius
        end
    end

    CreateOpenPrompt()

    while true do
        local ped = PlayerPedId()
        CanStartInteraction = not IsPedDeadOrDying(ped) and not IsPedInCombat(ped)

        if CanStartInteraction and not PickerIsOpen and not CurrentInteraction then
            local available = GetAvailableInteractions()
            if #available > 0 then
                NearbyAvailable   = true
                NearbyActionLabel = ResolvePromptLabel(available)
            else
                NearbyAvailable   = false
                NearbyActionLabel = nil
            end
        else
            NearbyAvailable   = false
            NearbyActionLabel = nil
        end

        UpdateOpenPrompt()

        Citizen.Wait(Config.NearbyCheckInterval)
    end
end)

Citizen.CreateThread(function()
    while true do
        local wait = 500

        if PickerIsOpen then
            wait = 0
            DisableAllControlActions(0)

            if IsDisabledControlJustPressed(0, Config.Controls.menuUp) then
                SendNUIMessage({ type = 'moveSelectionUp' })
            end
            if IsDisabledControlJustPressed(0, Config.Controls.menuDown) then
                SendNUIMessage({ type = 'moveSelectionDown' })
            end
            if IsDisabledControlJustPressed(0, Config.Controls.menuAccept) then
                ClosePicker(true)
            end
            if IsDisabledControlJustPressed(0, Config.Controls.menuCancel) or not CanStartInteraction then
                ClosePicker(false)
            end

            if InteractionMarker then
                DrawMarker()
            end
        elseif CurrentInteraction then
            wait = 0
            local ped = PlayerPedId()
            if not CanStartInteraction then
                StopInteraction()
            elseif IsControlJustPressed(0, Config.OpenKey) then
                OpenPicker()
            elseif not IsPedUsingInteraction(ped, CurrentInteraction) then
                local now = GetGameTimer()
                if now >= NextRestartAttempt then
                    NextRestartAttempt = now + 1000
                    StartInteractionAtCoords(CurrentInteraction)
                end
            end
        elseif NearbyAvailable and CanStartInteraction then
            wait = 0
            if IsControlJustPressed(0, Config.OpenKey) then
                OpenPicker()
            end
        end

        Citizen.Wait(wait)
    end
end)

AddEventHandler('onResourceStop', function(name)
    if name ~= GetCurrentResourceName() then return end
    if CurrentInteraction then
        StopInteraction()
    end
    DestroyOpenPrompt()
    SendNUIMessage({ type = 'hideInteractionPicker' })
end)
