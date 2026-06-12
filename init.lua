-- init.lua
-- Unity - 22nd Anniversary group mission (Blackburrow: Unity)
-- Created by: RedFrog
-- Created: June 10, 2026
-- Version 0.28 - level-spread warning (>10): wide spread HARD-BLOCKS the
--   shared task request (82 in a 115 group = game refuses at Blevins;
--   threshold TBC). Scaling note: all-115 group drew 112-113 mobs.
-- 0.27 - feather stash after turn-in: arrives on cursor for every
--   member; driver self-checks, boxes checked via DanNet cursor query and
--   sent /autoinventory only when the feather is confirmed there.
-- 0.26 - seek list = page droppers only (AL drop table: digger,
--   gnoll, guard, scout - reavers/shamans drop nothing).
-- 0.25 - TURN_IN state, feather-gated: skipped entirely when the
--   whole group has feathers (farm-only); requires all 7 pages in the
--   DRIVER's bags + whole group in zone (feather fires group-wide on
--   final page); GiveWnd 4-slot batching (giveit/DCM pattern). Collection
--   report announces who still needs the Feather. Triggers on zone-in
--   or mid-sweep the moment page 7 lands in the driver's bags.
-- 0.24 - commander dialogue via [keyword] parsing from NPC chat
--   (sources disagree on name->phrase mapping; the NPC's own brackets are
--   authoritative). Commanders stall INVULNERABLE at ~10-15% (overshoot
--   impossible). Kill loop: doevents mid-fight, deaggro = pacified
--   success. Trash list = gnoll-types only (pages drop from gnolls;
--   snakes/razorgills cut - they still die if they aggro). Burly gnoll
--   PH added. MQ2Rez armed at 90% group-wide on Start.
-- 0.23 - aggro interrupt during travel: nav-to-target stops the
--   moment anything aggros and fights where it stands (blind nav past
--   mob packs trained the group = the wipe). Dungeon movement is now
--   fight-your-way-there.
-- 0.22 - wipe recovery: instance states self-check the zone and
--   reset to IDLE on death/eject (machine was sticking in HOLD after a
--   wipe to PoK, swallowing Start). Start now allowed from HOLD. Kill
--   loop aborts on hover/zone-change.
-- 0.21 - facing is the script's job on manual engages: /face fast
--   at attack + re-face every 3s while target lives (water mobs circle;
--   driver only faces on its own engages). Verified: Boxr has NO
--   kill-target command - mode control only.
-- 0.20 - live page tracking from loot chat events (self + group
--   member messages) - chips update instantly, no queries. Authoritative
--   refreshCollection auto-runs at zone-clear. Gartik observed to
--   RESPAWN in-instance (commanders not one-time spawns).
-- 0.19 - target selection by NAV PATH length not straight line
--   (multi-level zone: mob below the floor "looks" closest; also screens
--   unreachable mobs). ALL aggro'd haters killed before seeking new
--   targets, nearest first (was commanders-only).
-- 0.18 - peer roster scan skipped when group is full. Collection report
--   was already group-only.
-- 0.17 - aggro'd commanders killed before next sweep target (Gartik
--   trained adds while "ignored" - kill-if-aggro, never seek). Axtig
--   aggro = loud warning, never engage.
-- 0.16 - resume detection (Start inside instance -> sweep); loot is
--   user's setup notice; page name confirmed "Torn Old Book - Page N".
-- 0.15 - TRASH SWEEP: spawn names confirmed by in-game recon;
--   sweep loop navs to nearest trash, engages (target + attack, driver
--   fights, boxes assist), one mob per state tick, kill counter in
--   status. Commanders/Axtig excluded. Double-Start guard (pending
--   requestStart outside IDLE swallowed - caused pipeline restart).
-- 0.14 - GUI shows immediately; DanNet loading narrated in main loop.
--   Gather rebuilt per-member (3s settle, 20s re-send).
-- 0.13 - invite checkboxes default UNCHECKED; peer names capitalized;
--   friendly group-full warning incl. suspend-a-merc hint.
-- 0.12 - Gather Group button (boxes /travelto driver zone + nav to
--   driver); ungrouped roster uses Group.Member(name) as authoritative
--   check so joined members drop off the invite list.
-- 0.11 - merc-aware solo detection (mercs count in Group.Members but
--   never answer DanNet - caused slow start AND missed peer scan); invite
--   auto-accept via GroupWindow GW_FollowButton click (mercrez pattern).
-- 0.10 - state machine + GUI: persistent main loop, ImGui window (status/
--   countdowns, Start-Pause-Stop, group panel with DanNet roster + invite
--   checkboxes, page chips, driver override, debug log).
-- 0.08 - solo-start grouping offer via console args (replaced by GUI)
-- 0.07 - group-wide collection report via DanNet dquery
-- 0.06 - group-first: DanNet travel/entry, AnyoneMissing() checks
-- 0.05 - lockout cap 2h + countdown, spawn recon, instance = oldblackburrow_ann22raid (468)
-- 0.04 - request lockout parse/wait; anti-lockout design (Axtig = only completion trigger)
-- 0.03 - instance entry retry ("strange magical presence")
-- 0.02 - [Unity] print helpers; Qeynos Hills = qeytoqrg
-- Quest: https://www.bonzz.com/22ndann.htm (Unity section)
-- Reward: Unified Phoenix Feather (7x Torn Old Book pages to Lorekeeper Ralf)

local mq = require('mq')
require('ImGui')

local version = "0.28"

-- Spawn names from in-game recon 2026-06-11 (208 NPCs in fresh instance).
-- Commanders/Axtig deliberately NOT in this set - commander pipeline handles
-- them; Axtig must NEVER die in PAGES mode (completes mission = 2h30m lockout).
-- Page droppers ONLY (AL-confirmed drop table 2026-06-12): digger, gnoll,
-- guard, scout. Reavers/shamans/snakes/razorgills drop nothing - not
-- sought, but still die if they aggro (hater-first rule). Burly gnolls
-- kept: named chain for the geode aug, not pages.
local TRASH_NAMES = {
    ["a digger"] = true,
    ["a gnoll"] = true,
    ["a guard"] = true,
    ["a scout"] = true,
    ["a burly gnoll"] = true,      -- placeholder for the rare - cycle it
    ["a very burly gnoll"] = true, -- rare named, geode aug - kill on sight
}

-- Commanders are safe to kill (only Axtig completes the mission). The
-- sweep never SEEKS them, but an aggro'd commander chases and trains
-- adds if ignored (Gartik incident 2026-06-11) - so aggro = kill.
local COMMANDER_NAMES = {
    ["Commander Gartik"] = true,
    ["Commander Krolix"] = true,
    ["Commander Xataka"] = true,
}

-- GUI State

local gui = {
    open = true,
    state = 'IDLE',
    status = "Press Start to begin.",
    paused = false,
    fullQuest = false,
    requestStart = false,
    requestStop = false,
    requestInvite = false,
    requestRefresh = false,
    requestGather = false,
    driver = nil,
    driverOverride = 'auto',
    peers = {},        -- ungrouped DanNet peers: {peer, charName, cls, lvl, zone, include}
    members = {},      -- group cache: {name, lvl, cls, zone, feather, pageCount}
    pages = {},        -- [1..7] = {holders = "names" or nil, extra = bool}
    covered = 0,
    collectionFresh = false,
    lockoutUntil = 0,  -- mq.gettime() when next request allowed (0 = unknown)
    killCount = 0,
    debugOpen = false,
    debugLog = {},
}

-- Print Helpers

local function pushDebug(line)
    gui.debugLog[#gui.debugLog + 1] = line
    if #gui.debugLog > 120 then table.remove(gui.debugLog, 1) end
end

local function info(msg)
    print(string.format("\ao[\agUnity\ao]\at %s\ax", msg))
    pushDebug(msg)
end

local function warn(msg)
    print(string.format("\ao[\ayUnity\ao]\at %s\ax", msg))
    pushDebug("WARN: " .. msg)
end

local function fail(msg)
    print(string.format("\ao[\arUnity\ao]\at %s\ax", msg))
    pushDebug("FAIL: " .. msg)
end

local function setStatus(s)
    gui.status = s
end

-- Utility Functions

-- All waits abort when Stop is clicked
local function waitFor(conditionFunc, timeoutMs, checkIntervalMs)
    checkIntervalMs = checkIntervalMs or 100
    local elapsed = 0
    while elapsed < timeoutMs do
        if gui.requestStop then return false end
        if conditionFunc() then return true end
        mq.delay(checkIntervalMs)
        elapsed = elapsed + checkIntervalMs
    end
    return false
end

-- Mercs count in Group.Members() and never answer DanNet - exclude them
local function isSolo()
    for i = 1, (mq.TLO.Group.Members() or 0) do
        if not mq.TLO.Group.Member(i).Mercenary() then return false end
    end
    return true
end

-- Group Helpers (DanNet)

local function othersCmd(fmt, ...)
    if isSolo() then return end
    mq.cmdf('/dgge ' .. fmt, ...)
end

-- DanNet query pattern from rgmercs lib/dannet/helpers.lua (vetted)
local function dquery(peer, query)
    mq.cmdf('/dquery %s -q "%s"', peer, query)
    mq.delay(25)
    mq.delay(1500, function() return (mq.TLO.DanNet(peer).Q(query).Received() or 0) > 0 end)
    return mq.TLO.DanNet(peer).Q(query)()
end

local function groupMemberNames()
    local names = { mq.TLO.Me.CleanName() }
    for i = 1, (mq.TLO.Group.Members() or 0) do
        local member = mq.TLO.Group.Member(i)
        if member.CleanName() and not member.Mercenary() then
            names[#names + 1] = member.CleanName()
        end
    end
    return names
end

-- DanNet peer list minus self and current group members. The
-- Group.Member(name) lookup is the authoritative grouped check - it works
-- regardless of how the peer name was formatted.
local function ungroupedPeers()
    local myName = (mq.TLO.Me.CleanName() or ''):lower()
    local peers = {}
    for peer in (mq.TLO.DanNet.Peers() or ""):gmatch("[^|]+") do
        local charName = peer:match("([^_]+)$") or peer
        charName = charName:sub(1, 1):upper() .. charName:sub(2) -- DanNet names are lowercase
        if charName:lower() ~= myName and not mq.TLO.Group.Member(charName)() then
            peers[#peers + 1] = { peer = peer, charName = charName }
        end
    end
    return peers
end

-- Inventory + bank count for any group member (self local, others DanNet)
local function memberItemCount(memberName, itemName)
    if memberName == mq.TLO.Me.CleanName() then
        return (mq.TLO.FindItemCount('=' .. itemName)() or 0) + (mq.TLO.FindItemBankCount('=' .. itemName)() or 0)
    end
    local result = dquery(memberName:lower(),
        string.format('Math.Calc[${FindItemCount[=%s]}+${FindItemBankCount[=%s]}]', itemName, itemName))
    return tonumber(result) or 0
end

-- Cached Roster + Collection Report (main loop writes, render reads)

local function refreshPeers()
    -- Full group = nobody to invite = no reason to query all of DanNet
    if (mq.TLO.Group.Members() or 0) >= 5 then
        gui.peers = {}
        return
    end
    local peers = ungroupedPeers()
    for i, p in ipairs(peers) do
        setStatus(string.format("Querying online characters... %d/%d (%s)", i, #peers, p.charName))
        p.cls = dquery(p.peer, 'Me.Class.ShortName') or "?"
        p.lvl = dquery(p.peer, 'Me.Level') or "?"
        p.zone = dquery(p.peer, 'Zone.ShortName') or "?"
        p.include = false -- user picks who joins
    end
    gui.peers = peers
end

local function refreshCollection()
    setStatus("Refreshing collection report...")
    local members = {}
    for _, name in ipairs(groupMemberNames()) do
        local m = { name = name, feather = false, pageCount = 0 }
        if name == mq.TLO.Me.CleanName() then
            m.lvl = mq.TLO.Me.Level() or 0
            m.cls = mq.TLO.Me.Class.ShortName() or "?"
            m.zone = mq.TLO.Zone.ShortName() or "?"
        else
            m.lvl = dquery(name:lower(), 'Me.Level') or "?"
            m.cls = dquery(name:lower(), 'Me.Class.ShortName') or "?"
            m.zone = dquery(name:lower(), 'Zone.ShortName') or "?"
        end
        m.feather = memberItemCount(name, "Unified Phoenix Feather") > 0 -- TBC: exact item name
        if m.feather then warn(string.format("%s ALREADY HAS the Unified Phoenix Feather", name)) end
        members[#members + 1] = m
    end

    local covered = 0
    for i = 1, 7 do
        local pageName = string.format("Torn Old Book - Page %d", i) -- confirmed in-game 2026-06-11
        local holders = {}
        local extra = false
        for _, m in ipairs(members) do
            local n = memberItemCount(m.name, pageName)
            if n > 0 then
                m.pageCount = m.pageCount + n
                holders[#holders + 1] = (n > 1) and string.format("%s x%d", m.name, n) or m.name
                if n > 1 then extra = true end
            end
        end
        if #holders > 0 then covered = covered + 1 end
        gui.pages[i] = { holders = (#holders > 0) and table.concat(holders, ", ") or nil, extra = extra }
    end
    gui.members = members
    gui.covered = covered
    gui.collectionFresh = true
    -- Shared task HARD-BLOCKS the request when member levels are too far
    -- apart (82 in a 115 group = game refuses at Blevins; exact threshold
    -- unknown). Warn early, before the trip is wasted.
    local minLvl, maxLvl = 999, 0
    for _, m in ipairs(members) do
        local lvl = tonumber(m.lvl) or 0
        if lvl > 0 then
            if lvl < minLvl then minLvl = lvl end
            if lvl > maxLvl then maxLvl = lvl end
        end
    end
    if maxLvl > 0 and (maxLvl - minLvl) > 10 then
        warn(string.format("level spread %d-%d - the game may REFUSE the shared task request with levels this far apart. Consider a merc instead of the low member.", minLvl, maxLvl))
    end

    local needy = {}
    for _, m in ipairs(members) do
        if not m.feather then needy[#needy + 1] = m.name end
    end
    if #needy == 0 and #members > 0 then
        info("everyone in the group already has the Unified Phoenix Feather.")
    elseif #needy > 0 then
        info("still needs the Feather: " .. table.concat(needy, ", "))
    end
    info(string.format("%d of 7 pages covered across the group", covered))
    setStatus(string.format("Collection report: %d of 7 pages covered.", covered))
end

-- Live page tracking from loot messages - instant chip updates with zero
-- DanNet queries. Full refreshCollection still runs at zone-clear.
local function notePageLooted(who, raw)
    local i = tonumber((raw or ''):match("%d+"))
    if not i or i < 1 or i > 7 then return end
    who = (who or "?"):gsub("^[%-%s]+", "")
    local page = gui.pages[i]
    if page and page.holders then
        if not page.holders:find(who, 1, true) then
            page.holders = page.holders .. ", " .. who
            page.extra = true
        end
    else
        gui.pages[i] = { holders = who, extra = false }
        gui.covered = gui.covered + 1
    end
    info(string.format("%s looted Page %d - %d of 7 covered!", who, i, gui.covered))
end

mq.event('unityPageSelf', "#*#You have looted a Torn Old Book - Page #1#", function(_, n)
    notePageLooted(mq.TLO.Me.CleanName(), n)
end)
mq.event('unityPageOther', "#1# has looted a Torn Old Book - Page #2#", function(_, who, n)
    notePageLooted(who, n)
end)

-- Commanders stall INVULNERABLE at ~10-15% and emote a bracketed
-- [keyword]; saying the keyword advances them. Sources disagree on which
-- commander wants which phrase (Bonzz vs Alla vs AL's own chat log), so
-- we don't map names to phrases - we parse the keyword from the NPC's
-- own dialogue and echo it back. Chains ([stupid gnoll] then [me]) work
-- naturally: each new line triggers its own reply.
mq.event('unityKeyword', "#1# says#*#[#2#]#*#", function(_, npc, keyword)
    if (mq.TLO.Zone.ShortName() or '') ~= 'oldblackburrow_ann22raid' then return end
    npc = npc or ''
    if (COMMANDER_NAMES[npc] or npc:find('Axtig')) and keyword and #keyword > 0 then
        info(string.format('%s wants "[%s]" - responding', npc, keyword))
        mq.cmdf('/say %s', keyword)
    end
end)

-- Combat Driver Adapter

local function detectCombatDriver()
    if gui.driverOverride ~= 'auto' then
        return gui.driverOverride ~= 'none' and gui.driverOverride or nil
    end
    if mq.TLO.Plugin('MQ2Boxr').IsLoaded() then return 'boxr' end
    if mq.TLO.CWTN ~= nil and mq.TLO.CWTN.Command() then return 'cwtn' end
    if (mq.TLO.Lua.Script('rgmercs').Status() or '') == 'RUNNING' then return 'rgmercs' end
    if (mq.TLO.Macro.Name() or ''):lower():find('kissassist') then return 'kissassist' end
    return nil
end

local function driverPause()
    if gui.driver == 'boxr' then
        mq.cmd('/boxr pause')
    elseif gui.driver == 'cwtn' then
        mq.cmdf('/%s pause on', mq.TLO.CWTN.Command())
    elseif gui.driver == 'rgmercs' then
        mq.cmd('/rgl pause')
    elseif gui.driver == 'kissassist' then
        mq.cmd('/backoff on')
    end
end

local function driverUnpause()
    if gui.driver == 'boxr' then
        mq.cmd('/boxr unpause')
    elseif gui.driver == 'cwtn' then
        mq.cmdf('/%s pause off', mq.TLO.CWTN.Command())
    elseif gui.driver == 'rgmercs' then
        mq.cmd('/rgl unpause')
    elseif gui.driver == 'kissassist' then
        mq.cmd('/backoff off')
    end
end

-- Grouping

local function doInvites()
    local room = 5 - (mq.TLO.Group.Members() or 0)
    local selected = 0
    for _, p in ipairs(gui.peers) do
        if p.include then selected = selected + 1 end
    end
    if selected > room then
        local hasMerc = false
        for i = 1, (mq.TLO.Group.Members() or 0) do
            if mq.TLO.Group.Member(i).Mercenary() then hasMerc = true end
        end
        warn(string.format("group only has room for %d more (%d selected).%s",
            math.max(room, 0), selected, hasMerc and " Mercs hold a slot - suspend one to make room." or ""))
        if room <= 0 then return end
    end
    local invited = 0
    for _, p in ipairs(gui.peers) do
        if p.include and invited < room then
            invited = invited + 1
            setStatus(string.format("Inviting %s...", p.charName))
            mq.cmdf('/invite %s', p.charName)
            -- Accept on the box: click the group window Follow button
            -- (pattern from mercrez init.lua:114). Retry until joined.
            local joined = false
            for _ = 1, 6 do
                mq.delay(1000)
                if mq.TLO.Group.Member(p.charName)() then
                    joined = true
                    break
                end
                mq.cmdf('/squelch /dex %s /notify GroupWindow GW_FollowButton leftmouseup', p.peer)
            end
            if joined then
                info(p.charName .. " joined the group")
            else
                warn(p.charName .. " did not accept the invite - check that character")
            end
        end
    end
    if invited == 0 then
        warn("no peers selected to invite.")
        return
    end
    info(string.format("group size now %d", (mq.TLO.Group.Members() or 0) + 1))
    mq.delay(1000) -- let Group TLO settle before rebuilding the roster
    refreshPeers()
    gui.collectionFresh = false
end

-- Bring all grouped boxes to the driver's zone and location. Per-member:
-- each box gets its own nav as IT arrives (3s zone-in settle), re-sent
-- every 20s while still far. One-shot broadcast after everyone arrives
-- left early arrivals idle and late arrivals missed it (v0.12 bug).
local function gatherGroup()
    if isSolo() then
        warn("not in a group - nothing to gather.")
        return
    end
    local myZone = mq.TLO.Zone.ShortName() or ""
    local myName = mq.TLO.Me.CleanName()
    othersCmd('/travelto %s', myZone)

    local arrivedAt = {}
    local lastNav = {}
    local deadline = mq.gettime() + 600000
    while mq.gettime() < deadline do
        if gui.requestStop then return end
        local here = 0
        local total = 0
        local allClose = true
        for i = 1, (mq.TLO.Group.Members() or 0) do
            local member = mq.TLO.Group.Member(i)
            if not member.Mercenary() then
                total = total + 1
                local name = member.CleanName()
                local spawn = member.Spawn
                if name and (spawn.ID() or 0) > 0 then
                    here = here + 1
                    arrivedAt[name] = arrivedAt[name] or mq.gettime()
                    local dist = spawn.Distance3D() or 999
                    if dist > 25 then
                        allClose = false
                        -- 3s settle after zoning in, then nav; re-send every 20s
                        if mq.gettime() - arrivedAt[name] > 3000
                            and (not lastNav[name] or mq.gettime() - lastNav[name] > 20000) then
                            mq.cmdf('/squelch /dex %s /nav spawn pc =%s', name, myName)
                            lastNav[name] = mq.gettime()
                        end
                    end
                else
                    allClose = false
                end
            end
        end
        setStatus(string.format("Gathering: %d/%d in %s...", here, total, myZone))
        if here == total and allClose then
            info("group gathered.")
            setStatus("Group gathered. Press Start when ready.")
            return
        end
        mq.delay(1000)
    end
    warn("gather timed out - check stragglers.")
end

-- Mission Pipeline States

local function stateTravel()
    if (mq.TLO.Zone.ShortName() or ''):lower() ~= 'qeytoqrg' then
        setStatus("Traveling to Qeynos Hills (group)...")
        othersCmd('/travelto qeytoqrg')
        mq.cmd('/travelto qeytoqrg')
        if not waitFor(function() return (mq.TLO.Zone.ShortName() or ''):lower() == 'qeytoqrg' end, 600000, 1000) then
            fail("never reached Qeynos Hills.")
            return false
        end
        mq.delay(3000)
    end
    setStatus("Waiting for group in Qeynos Hills...")
    if not waitFor(function() return not mq.TLO.Group.AnyoneMissing() end, 600000, 1000) then
        warn("group members still missing from Qeynos Hills - continuing anyway")
    end
    return true
end

local function stateRequest()
    setStatus("Requesting mission from Guard Blevins...")
    local blevins = mq.TLO.Spawn("npc Guard Blevins")
    if not blevins() then
        fail("Guard Blevins not found in zone.")
        return false
    end

    mq.cmd('/squelch /nav spawn npc Guard Blevins')
    if not waitFor(function() return not mq.TLO.Navigation.Active() and (blevins.Distance3D() or 999) < 20 end, 120000, 250) then
        fail("could not reach Guard Blevins.")
        return false
    end

    mq.cmd('/target npc Guard Blevins')
    mq.delay(500)
    mq.cmd('/hail')
    mq.delay(1500)

    local lockoutSeconds = nil
    mq.event('unityLockout', "#*#you must wait #1# before you can request another task#*#", function(_, timeStr)
        local d, h, m, s = timeStr:match("(%d+)d:(%d+)h:(%d+)m:(%d+)s")
        if d then
            lockoutSeconds = ((tonumber(d) * 24 + tonumber(h)) * 60 + tonumber(m)) * 60 + tonumber(s)
        end
    end)

    local gotTask = false
    for _ = 1, 3 do
        lockoutSeconds = nil
        mq.cmd('/say Help')
        if waitFor(function()
            mq.doevents()
            return lockoutSeconds ~= nil or mq.TLO.Task("Unity").ID() ~= nil
        end, 10000, 500) and not lockoutSeconds then
            gotTask = true
            break
        end
        if gui.requestStop then break end
        if lockoutSeconds then
            -- Flat 1h request lockout; message quotes exact remaining time
            if lockoutSeconds > 7200 then
                fail(string.format("request lockout is %dm - too long. Stopping.", math.floor(lockoutSeconds / 60)))
                break
            end
            gui.lockoutUntil = mq.gettime() + (lockoutSeconds + 10) * 1000
            info(string.format("request lockout: waiting %dm %ds", math.floor(lockoutSeconds / 60), lockoutSeconds % 60))
            if not waitFor(function()
                local left = math.max(0, gui.lockoutUntil - mq.gettime()) / 1000
                setStatus(string.format("LOCKOUT - next request in %dm %ds", math.floor(left / 60), math.floor(left % 60)))
                return mq.gettime() >= gui.lockoutUntil
            end, (lockoutSeconds + 15) * 1000, 1000) then
                break -- stop clicked
            end
        else
            warn("no task and no lockout message after Help - retrying")
            mq.delay(3000)
        end
    end
    mq.unevent('unityLockout')

    if not gotTask then
        if not gui.requestStop then fail("task never appeared after saying Help.") end
        return false
    end
    info("task acquired.")
    return true
end

local function stateEnter()
    setStatus("Entering instance...")
    local entryBlocked = false
    mq.event('unityBlocked', "#*#strange magical presence prevents you from entering#*#", function()
        entryBlocked = true
    end)

    local startZone = mq.TLO.Zone.ID() or 0
    local zoned = false
    for attempt = 1, 12 do
        if gui.requestStop then break end
        entryBlocked = false
        setStatus(string.format("Saying Ready (attempt %d)...", attempt))
        mq.cmd('/say Ready')
        if waitFor(function()
            mq.doevents()
            return entryBlocked or (mq.TLO.Zone.ID() or 0) ~= startZone
        end, 15000, 500) and not entryBlocked then
            zoned = true
            break
        end
        setStatus(string.format("Instance not ready (attempt %d) - retrying in 15s", attempt))
        mq.delay(15000)
    end
    mq.unevent('unityBlocked')

    if not zoned then
        if not gui.requestStop then fail("never zoned into the instance.") end
        return false
    end
    mq.delay(5000)
    info(string.format("zoned into instance: %s (%s, ID %d)",
        mq.TLO.Zone.Name() or "?", mq.TLO.Zone.ShortName() or "?", mq.TLO.Zone.ID() or 0))

    -- TBC: group entry method - assumed each member says Ready to Blevins
    if not isSolo() then
        setStatus("Bringing group into instance...")
        othersCmd('/target npc Guard Blevins')
        mq.delay(1000)
        othersCmd('/say Ready')
        if waitFor(function() return not mq.TLO.Group.AnyoneMissing() end, 180000, 1000) then
            info("whole group in instance.")
        else
            warn("group members still missing from instance - check them manually")
        end
    end
    return true
end

-- Trash Sweep Pipeline (PAGES mode: trash only, commanders skipped)

-- Straight-line distance lies in a multi-level zone (a mob below the
-- floor looks "closest"). Take the few nearest candidates by line, then
-- pick by actual NAV PATH length - also screens out unreachable mobs.
local function nearestTrash()
    local candidates = {}
    local count = mq.TLO.SpawnCount('npc')() or 0
    for i = 1, count do
        local s = mq.TLO.NearestSpawn(i, 'npc')
        local name = s.CleanName()
        if name and TRASH_NAMES[name] and (s.Type() or '') == 'NPC' then
            candidates[#candidates + 1] = s.ID() or 0
            if #candidates >= 8 then break end
        end
    end
    local bestId, bestLen = 0, 999999
    for _, id in ipairs(candidates) do
        local len = mq.TLO.Navigation.PathLength('id ' .. id)() or -1
        if len >= 0 and len < bestLen then
            bestId, bestLen = id, len
        end
    end
    if bestId == 0 and #candidates > 0 then
        return candidates[1] -- no path resolved on any candidate - try nearest anyway
    end
    return bestId
end

-- ANYTHING on the hater list gets killed before we seek a new target -
-- ignoring aggro builds trains (Gartik incident). Exception: Axtig is
-- never returned - loud warning instead so the user intervenes.
local function aggroedMobId()
    local bestId, bestDist = 0, 999999
    for i = 1, (mq.TLO.Me.XTargetSlots() or 0) do
        local xt = mq.TLO.Me.XTarget(i)
        if (xt.TargetType() or '') == 'Auto Hater' and (xt.ID() or 0) > 0 then
            local name = xt.CleanName() or ''
            if name:find('Axtig') then
                warn("AXTIG HAS AGGRO - do NOT kill him (completes mission, 2h30m lockout)! Move the group away.")
            else
                local d = mq.TLO.Spawn(xt.ID()).Distance3D() or 999999
                if d < bestDist then
                    bestId, bestDist = xt.ID() or 0, d
                end
            end
        end
    end
    return bestId
end

-- Nav to a mob, engage, wait for the kill. Combat driver does the
-- fighting - we provide target + aggro; boxes assist per their settings.
local function killMobById(id, seekIt)
    local spawn = mq.TLO.Spawn(id)
    setStatus(string.format("Sweeping: %s (%d kills this run)", spawn.CleanName() or "?", gui.killCount))

    if seekIt then
        mq.cmdf('/squelch /nav id %d distance=15', id)
        local navDeadline = mq.gettime() + 60000
        local arrived = false
        while mq.gettime() < navDeadline do
            if gui.requestStop then
                mq.cmd('/squelch /nav stop')
                return
            end
            if (not mq.TLO.Navigation.Active()) or ((spawn.Distance3D() or 999) < 20) then
                arrived = true
                break
            end
            -- Aggro en route: STOP and fight where we stand. Marching on
            -- builds a train (cause of the 2026-06-12 wipe). The sweep
            -- loop re-selects; its aggro-first branch takes over.
            if aggroedMobId() > 0 then
                mq.cmd('/squelch /nav stop')
                info("picked up aggro en route - fighting here before moving on")
                return
            end
            mq.delay(250)
        end
        mq.cmd('/squelch /nav stop')
        if not arrived then
            warn("could not reach " .. (spawn.CleanName() or "mob") .. " - skipping")
            return
        end
    end
    if not spawn() or (spawn.Type() or '') ~= 'NPC' then return end

    mq.cmdf('/target id %d', id)
    mq.delay(300)
    mq.cmd('/squelch /face fast')
    mq.cmd('/attack on')
    -- We engaged manually, so facing is OUR job (driver only faces on its
    -- own engages). Re-face every 3s - water mobs swim circles around you.
    local isCommander = COMMANDER_NAMES[spawn.CleanName() or ''] or false
    local deadline = mq.gettime() + 180000
    local lastFace = 0
    local died = false
    local pacified = false
    while mq.gettime() < deadline do
        if gui.requestStop then break end
        mq.doevents() -- commander [keyword] replies must fire MID-fight
        if mq.TLO.Me.Hovering() or (mq.TLO.Zone.ShortName() or '') ~= 'oldblackburrow_ann22raid' then
            warn("we died or left the zone mid-fight - abandoning this kill.")
            break
        end
        local s = mq.TLO.Spawn(id)
        if (not s()) or (s.Type() or 'Corpse') == 'Corpse' then
            died = true
            break
        end
        -- Some commanders DEAGGRO instead of dying after the dialogue -
        -- alive but off the hater list = done with this one
        if isCommander then
            local stillAngry = false
            for i = 1, (mq.TLO.Me.XTargetSlots() or 0) do
                if (mq.TLO.Me.XTarget(i).ID() or 0) == id then
                    stillAngry = true
                    break
                end
            end
            if not stillAngry then
                pacified = true
                break
            end
        end
        if mq.gettime() - lastFace > 3000 then
            mq.cmd('/squelch /face fast')
            lastFace = mq.gettime()
        end
        mq.delay(500)
    end
    mq.cmd('/attack off')
    if died then
        gui.killCount = gui.killCount + 1
    elseif pacified then
        info((spawn.CleanName() or "commander") .. " pacified after dialogue - moving on")
    else
        warn("kill timed out on " .. (spawn.CleanName() or "mob"))
    end
end

-- One sweep step: aggro'd commanders first, then nearest trash.
-- Returns false when no trash remains (zone cleared).
local function sweepOneMob()
    local haterId = aggroedMobId()
    if haterId > 0 then
        local name = mq.TLO.Spawn(haterId).CleanName() or "mob"
        if COMMANDER_NAMES[name] then
            info("commander has aggro - killing it (safe: only Axtig completes the mission)")
        end
        killMobById(haterId, false)
        return true
    end
    local id = nearestTrash()
    if id == 0 then return false end
    killMobById(id, true)
    return true
end

-- Turn-In Pipeline (feather-gated)

local function anyoneNeedsFeather()
    for _, m in ipairs(gui.members) do
        if not m.feather then return true end
    end
    return #gui.members == 0 -- no report yet: assume someone needs it
end

-- Pages in MY bags only - bank pages can't be handed over
local function pagesInMyBags()
    local n = 0
    for i = 1, 7 do
        if (mq.TLO.FindItemCount(string.format("=Torn Old Book - Page %d", i))() or 0) > 0 then
            n = n + 1
        end
    end
    return n
end

local function stateTurnIn()
    local ralf = mq.TLO.Spawn("npc Lorekeeper Ralf")
    if not ralf() then
        fail("Lorekeeper Ralf not found in zone.")
        return false
    end

    -- The feather fires GROUP-WIDE when the final page lands - everyone
    -- must be in zone first or they miss it permanently this run.
    if mq.TLO.Group.GroupSize() ~= nil and mq.TLO.Group.AnyoneMissing() then
        setStatus("Turn-in: waiting for whole group in zone (feather fires on final page)...")
        if not waitFor(function() return not mq.TLO.Group.AnyoneMissing() end, 300000, 1000) then
            fail("group not all present after 5 min - turn-in aborted. Gather everyone and Start again.")
            return false
        end
    end

    setStatus("Turn-in: delivering 7 pages to Lorekeeper Ralf...")
    mq.cmdf('/squelch /nav id %d distance=12', ralf.ID() or 0)
    waitFor(function() return (not mq.TLO.Navigation.Active()) and (ralf.Distance3D() or 999) < 15 end, 120000, 250)
    mq.cmdf('/target id %d', ralf.ID() or 0)
    mq.delay(500)

    -- Give window holds 4: cursor item -> /click left target loads a
    -- slot; Give button hands the batch over (pattern from giveit/DCM)
    local given = 0
    for i = 1, 7 do
        local pageName = string.format("Torn Old Book - Page %d", i)
        if (mq.TLO.FindItemCount('=' .. pageName)() or 0) > 0 then
            mq.cmdf('/itemnotify "%s" leftmouseup', pageName)
            if not waitFor(function() return (mq.TLO.Cursor.Name() or '') == pageName end, 3000, 100) then
                warn("could not pick up " .. pageName .. " - skipping")
            else
                mq.cmd('/click left target')
                waitFor(function() return not mq.TLO.Cursor.ID() end, 3000, 100)
                given = given + 1
                if given % 4 == 0 then
                    mq.cmd('/notify GiveWnd GVW_Give_Button leftmouseup')
                    mq.delay(2000, function() return not mq.TLO.Window('GiveWnd').Open() end)
                end
            end
        end
    end
    if mq.TLO.Window('GiveWnd').Open() then
        mq.cmd('/notify GiveWnd GVW_Give_Button leftmouseup')
        mq.delay(2000, function() return not mq.TLO.Window('GiveWnd').Open() end)
    end
    info(string.format("handed %d pages to Lorekeeper Ralf!", given))

    -- The feather arrives ON THE CURSOR for every member - stash it
    -- before anyone fat-fingers it onto the ground
    mq.delay(1500)
    if (mq.TLO.Cursor.Name() or '') == "Unified Phoenix Feather" then
        info("UNIFIED PHOENIX FEATHER received - putting it in my bags!")
        mq.cmd('/autoinventory')
    end
    for _, m in ipairs(gui.members) do
        if m.name ~= mq.TLO.Me.CleanName() then
            if (dquery(m.name:lower(), 'Cursor.Name') or '') == "Unified Phoenix Feather" then
                info(m.name .. " has the Feather on cursor - stashing it for them.")
                mq.cmdf('/dex %s /autoinventory', m.name)
            end
        end
    end

    refreshCollection()
    return given > 0
end

-- Recon: dump unique NPC names + counts. Remove once spawn names known.
local function reconSpawns()
    local counts = {}
    local total = mq.TLO.SpawnCount('npc')() or 0
    for i = 1, total do
        local name = mq.TLO.NearestSpawn(i, 'npc').CleanName()
        if name then counts[name] = (counts[name] or 0) + 1 end
    end
    local names = {}
    for name in pairs(counts) do names[#names + 1] = name end
    table.sort(names)
    info(string.format("recon: %d NPCs, %d unique names:", total, #names))
    for _, name in ipairs(names) do
        printf("\at  %dx %s\ax", counts[name], name)
        pushDebug(string.format("  %dx %s", counts[name], name))
    end
end

-- State Machine

local function stepStateMachine()
    -- Start clicked while already running: swallow it, or the pending
    -- request silently restarts the pipeline next time we hit IDLE.
    -- Exception: HOLD is a resting state - Start from there = new run.
    if gui.requestStart and gui.state ~= 'IDLE' then
        if gui.state == 'HOLD' then
            gui.state = 'IDLE'
        else
            gui.requestStart = false
        end
    end
    -- Wipe/eject check: instance states are only valid INSIDE the
    -- instance. Death respawn (PoK) or boot must reset, or the machine
    -- sticks in a state that no longer matches reality.
    if (gui.state == 'IN_INSTANCE' or gui.state == 'SWEEPING' or gui.state == 'TURN_IN' or gui.state == 'HOLD')
        and (mq.TLO.Zone.ShortName() or '') ~= 'oldblackburrow_ann22raid' then
        warn("no longer in the instance (death or eject) - press Start to regroup and re-enter.")
        setStatus("Out of instance. Press Start to head back in.")
        gui.state = 'IDLE'
        return
    end
    if gui.state == 'IDLE' then
        if gui.requestStart then
            gui.requestStart = false
            gui.driver = detectCombatDriver()
            if gui.driver then
                info("combat driver: " .. gui.driver)
            else
                warn("no combat driver found - mission combat will need one running.")
            end
            -- Deaths happen (knockbacks, ledges, trains). MQ2Rez owns
            -- accepting; we just make sure it's armed group-wide.
            if mq.TLO.Plugin('MQ2Rez').IsLoaded() then
                mq.cmd('/squelch /rez accept on')
                mq.cmd('/squelch /rez pct 90')
                othersCmd('/squelch /rez accept on')
                othersCmd('/squelch /rez pct 90')
                info("rez auto-accept armed at 90% group-wide (MQ2Rez)")
            else
                warn("MQ2Rez not loaded - deaths will need manual rez accepts.")
            end
            if isSolo() and #gui.peers == 0 then
                fail("solo with no DanNet peers - Unity is a group mission. Use Invite or group up.")
                setStatus("Solo - select peers and click Invite, or group manually.")
                return
            end
            -- Already inside the instance (script restarted mid-run)?
            -- Skip straight to the sweep instead of trying to travel out.
            if (mq.TLO.Zone.ShortName() or '') == 'oldblackburrow_ann22raid' then
                info("already inside the instance - resuming")
                gui.state = 'IN_INSTANCE'
            else
                gui.state = 'TRAVELING'
            end
        end
    elseif gui.state == 'TRAVELING' then
        gui.state = stateTravel() and 'REQUESTING' or 'IDLE'
    elseif gui.state == 'REQUESTING' then
        gui.state = stateRequest() and 'ENTERING' or 'IDLE'
    elseif gui.state == 'ENTERING' then
        gui.state = stateEnter() and 'IN_INSTANCE' or 'IDLE'
    elseif gui.state == 'IN_INSTANCE' then
        reconSpawns()
        gui.killCount = 0
        if not anyoneNeedsFeather() then
            info("everyone in the group already has the Feather - farming pages only, no turn-in.")
        elseif pagesInMyBags() >= 7 then
            info("all 7 pages in my bags and someone needs the Feather - going straight to Ralf!")
            gui.state = 'TURN_IN'
            return
        elseif gui.covered >= 7 then
            warn("all 7 pages exist in the group but not all in MY bags - trade them to me, then they turn in automatically.")
        end
        info("starting trash sweep (commanders handled via dialogue, Axtig never)")
        gui.state = 'SWEEPING'
    elseif gui.state == 'SWEEPING' then
        if anyoneNeedsFeather() and pagesInMyBags() >= 7 then
            info("all 7 pages in my bags - heading to Lorekeeper Ralf!")
            gui.state = 'TURN_IN'
        elseif not sweepOneMob() then
            info(string.format("zone cleared - %d kills this run.", gui.killCount))
            refreshCollection() -- authoritative recount after the run
            setStatus(string.format("Zone cleared, %d kills. %d of 7 pages. (Exit pipeline next version)",
                gui.killCount, gui.covered))
            gui.state = 'HOLD'
        end
    elseif gui.state == 'TURN_IN' then
        if stateTurnIn() then
            setStatus(gui.fullQuest
                and "Feather delivered! Full Quest ON - Axtig pipeline not built yet, holding."
                or "Feather delivered! Drop the task when ready. (Exit pipeline next version)")
        end
        gui.state = 'HOLD'
    elseif gui.state == 'HOLD' then
        -- exit / re-request pipeline lands here next
    end
end

-- GUI Rendering (reads gui table only - no mq.delay, no blocking)

local stateColors = {
    IDLE = { 0.8, 0.8, 0.8, 1 },
    HOLD = { 1.0, 0.8, 0.2, 1 },
}

local function drawGUI()
    if not gui.open then return end
    local shouldDraw
    gui.open, shouldDraw = ImGui.Begin('Unity##UnityGUI', gui.open)
    if not shouldDraw then
        ImGui.End()
        return
    end

    -- Title row: Full Quest toggle
    ImGui.Text("Unity v" .. version)
    ImGui.SameLine(ImGui.GetWindowWidth() - 150)
    if gui.state == 'SWEEPING' then
        ImGui.BeginDisabled()
        ImGui.Checkbox("Full Quest", gui.fullQuest)
        ImGui.EndDisabled()
    else
        gui.fullQuest = ImGui.Checkbox("Full Quest", gui.fullQuest)
    end
    if ImGui.IsItemHovered() then
        ImGui.SetTooltip("ON: kill Axtig after feathers (mission complete, 2h30m lockout)\nOFF: feathers only - never engage Axtig")
    end

    -- Status line
    local c = stateColors[gui.state] or { 0.4, 1.0, 0.4, 1 }
    ImGui.PushStyleColor(ImGuiCol.Text, c[1], c[2], c[3], c[4])
    ImGui.TextWrapped(string.format("[%s]%s %s", gui.state, gui.paused and " PAUSED" or "", gui.status))
    ImGui.PopStyleColor()
    ImGui.Separator()

    -- Buttons (set flags only)
    if ImGui.Button("Start") then gui.requestStart = true end
    ImGui.SameLine()
    if ImGui.Button(gui.paused and "Resume" or "Pause") then
        gui.paused = not gui.paused
        if gui.paused then driverPause() else driverUnpause() end
    end
    ImGui.SameLine()
    if ImGui.Button("Stop") then gui.requestStop = true end
    ImGui.SameLine()
    if ImGui.Button("Refresh") then gui.requestRefresh = true end
    ImGui.SameLine()
    if ImGui.Button("Gather Group") then gui.requestGather = true end
    if ImGui.IsItemHovered() then
        ImGui.SetTooltip("All grouped boxes /travelto your zone, then nav to you.\nUse after grouping so everyone enters together on Start.")
    end
    ImGui.Separator()

    -- Group panel
    if ImGui.CollapsingHeader(string.format("Group (%d/6)###grouphdr", #gui.members), ImGuiTreeNodeFlags.DefaultOpen) then
        for _, m in ipairs(gui.members) do
            ImGui.Text(string.format("  %-12s %3s %-4s %-14s %s  pages: %d",
                m.name, tostring(m.lvl), tostring(m.cls), tostring(m.zone),
                m.feather and "FEATHER" or "       ", m.pageCount))
        end
        if #gui.peers > 0 then
            ImGui.Text("Not grouped:")
            for i, p in ipairs(gui.peers) do
                p.include = ImGui.Checkbox(string.format("%s - %s %s (%s)###peer%d",
                    p.charName, tostring(p.lvl), tostring(p.cls), tostring(p.zone), i), p.include)
            end
            if ImGui.Button("Invite Selected") then gui.requestInvite = true end
        end
    end

    -- Pages panel
    if ImGui.CollapsingHeader(string.format("Pages (%d of 7)###pageshdr", gui.covered), ImGuiTreeNodeFlags.DefaultOpen) then
        for i = 1, 7 do
            local page = gui.pages[i]
            if page and page.holders then
                ImGui.PushStyleColor(ImGuiCol.Text, 0.4, 1.0, 0.4, 1)
                ImGui.Text(string.format("  Page %d: %s%s", i, page.holders, page.extra and " (extras tradeable)" or ""))
            else
                ImGui.PushStyleColor(ImGuiCol.Text, 1.0, 0.4, 0.4, 1)
                ImGui.Text(string.format("  Page %d: MISSING", i))
            end
            ImGui.PopStyleColor()
        end
        if not gui.collectionFresh then
            ImGui.TextDisabled("  (stale - click Refresh)")
        end
    end

    -- Driver row
    ImGui.Separator()
    ImGui.Text("Driver:")
    ImGui.SameLine()
    ImGui.SetNextItemWidth(120)
    if ImGui.BeginCombo("##driver", gui.driverOverride == 'auto'
        and string.format("auto (%s)", gui.driver or "none") or gui.driverOverride) then
        for _, opt in ipairs({ 'auto', 'boxr', 'cwtn', 'rgmercs', 'kissassist', 'none' }) do
            if ImGui.Selectable(opt, gui.driverOverride == opt) then
                gui.driverOverride = opt
                gui.driver = detectCombatDriver()
            end
        end
        ImGui.EndCombo()
    end

    -- Debug log
    if ImGui.CollapsingHeader("Debug log###debughdr") then
        ImGui.BeginChild("##debugchild", 0, 150, ImGuiChildFlags and ImGuiChildFlags.Borders or true)
        for _, line in ipairs(gui.debugLog) do
            ImGui.TextWrapped(line)
        end
        ImGui.EndChild()
    end

    ImGui.End()
end

-- Main Execution

local function main()
    info("v" .. version .. " - state machine + GUI")
    info("looting is handled by YOUR setup (lootnscoot / CWTN loot / manual) - this script kills, it does not loot.")
    gui.driver = detectCombatDriver()

    -- Window FIRST - slow DanNet work happens in the main loop below
    -- while the status line narrates. Never make the user wait blind.
    setStatus("Loading - gathering character data, please wait...")
    mq.imgui.init('UnityGUI', drawGUI)
    gui.requestRefresh = true

    while gui.open do
        mq.doevents()
        if gui.requestStop then
            gui.requestStop = false
            driverUnpause()
            gui.paused = false
            gui.state = 'IDLE'
            setStatus("Stopped. Press Start to begin again.")
        end
        if gui.requestRefresh then
            gui.requestRefresh = false
            refreshPeers()
            refreshCollection()
            if isSolo() and #gui.peers > 0 then
                setStatus(string.format("Ready. %d characters online - select and Invite when ready.", #gui.peers))
            end
        end
        if gui.requestInvite then
            gui.requestInvite = false
            doInvites()
        end
        if gui.requestGather then
            gui.requestGather = false
            gatherGroup()
        end
        if not gui.paused then
            stepStateMachine()
        end
        mq.delay(100)
    end
end

main()
