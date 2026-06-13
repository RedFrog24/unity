-- init.lua
-- Unity - 22nd Anniversary group mission (Blackburrow: Unity)
-- Created by: RedFrog
-- Created: June 10, 2026
-- Version 0.42 - Full Quest Axtig kill BUILT (was just a label): after
--   feathers, nav + kill Axtig; success requires his corpse, aggro-first loop
-- 0.41 - PERMA_NOTRY: two static walled-off gnolls (a guard, a scout)
--   ignored by loc - not counted as trash, never targeted
-- 0.40 - self-review fixes: decodeCollection unknown on junk (not
--   just nil); pause no longer counts as turn-in nav stall; hoard warn on edge
-- 0.39 - page-hoard warn (10+/page breaks digit encoding);
--   driver feather stash now polls 5s instead of one read
-- 0.38 - restore box zone diagnostic (dquery only when elsewhere);
--   partial turn-in clarifies no feather awarded
-- 0.37 - query no-response = "unknown" not zero; Ralf nav stall bail
-- 0.36 - feather verify settle+retry; blacklisted hater log
-- 0.35 - turn-in Axtig hold; DanNet Q key sanity check
-- 0.34 - collection report ~11 queries/member -> 1: ROOT CAUSE
--   was cmdf parsing embedded ${} locally so the DanNet Q key never
--   matched = full 1.5s timeout on EVERY item query (and nil results -
--   boxes read as 0 pages). Fix: /noparse dquery + identical raw key;
--   all 8 item checks encoded in one Math.Calc (pages = base-10 digits,
--   feather = 8th); member lvl/cls/zone from instant local Group TLOs.
-- 0.33 - turn-in success = all 7 handed AND feathers verified on
--   everyone who lacked one (was: given > 0 declared victory on partial
--   hand-ins); Pause now pauses the WHOLE CREW (boxes get the same
--   driver-family command; CWTN via noparse docommand so each box
--   resolves its own class); "already has Feather" announced once per
--   session instead of every refresh.
-- 0.32 - page holders tracked by name table (substring :find
--   suppressed "Ann" when "Joanna" held the page); despawn (leash/depop)
--   no longer counted as a kill and is reported distinctly.
-- 0.31 - Axtig aggro: warning throttled to 1/10s (was 4/sec
--   flooding the debug ring buffer), sweep HOLDS while he's the
--   remaining hater (assists/AE could clip him), TURN_IN transition
--   blocked on his aggro too. Lockout parser sums optional Nd/Nh/Nm/Ns
--   components (full-shape regex died on sub-day messages).
-- 0.30 - Pause is real + thread-safe: button and driver combo
--   set flags only (no mq.cmd from render thread); pauseGate holds in
--   waitFor and every long loop (kill seek/fight with attack off-on,
--   gather, turn-in nav), stopping movement first, resuming travel after.
--   Stop exits silently everywhere (stateTravel, turn-in waits) and can
--   never fall through into the give loop and hand pages over.
-- 0.29 - skip blacklist (2 min expiry, mobs path home): every
--   unreachable/timed-out mob is blacklisted in both nearestTrash and
--   aggroedMobId; candidates[1] fallback removed; nearestTrash returns
--   -1 (nothing reachable, wait) vs 0 (truly cleared). Haters beyond 30
--   units get gap-closing nav. TURN_IN requires clean hater list and
--   the Ralf nav fights through aggro (v0.23 rule applied).
-- 0.28 - level-spread warning (>10): wide spread HARD-BLOCKS the
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

local version = "0.42"

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
    requestPauseToggle = false,
    requestDriverDetect = false,
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

-- Hold here while Pause is on (stops movement first). Returns false if
-- Stop was clicked - callers bail out.
local function pauseGate()
    if not gui.paused then return not gui.requestStop end
    if mq.TLO.Navigation.Active() then mq.cmd('/squelch /nav stop') end
    while gui.paused and not gui.requestStop do
        mq.delay(250)
    end
    return not gui.requestStop
end

-- All waits abort on Stop and hold during Pause (timeout clock frozen)
local function waitFor(conditionFunc, timeoutMs, checkIntervalMs)
    checkIntervalMs = checkIntervalMs or 100
    local elapsed = 0
    while elapsed < timeoutMs do
        if gui.requestStop then return false end
        if gui.paused and not pauseGate() then return false end
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

-- For queries with embedded ${} (Math.Calc over FindItemCount etc):
-- /noparse so the DRIVER doesn't evaluate the ${} before sending. The
-- poll key must be the identical raw string or Received never fires -
-- that key mismatch was burning the full timeout on every item query.
-- One-time sanity check confirms the Q key matches (Received > 0) so a
-- regression to the key-mismatch class surfaces in the log immediately.
-- Returns nil on NO RESPONSE (timeout/blip/peer out of zone) - the caller
-- must distinguish that from a real "0" answer, or a failed query decodes
-- to "needs everything" and can trigger a bogus turn-in.
local _qKeyVerified = false
local function dqueryNoparse(peer, query)
    mq.cmd('/noparse /dquery ' .. peer .. ' -q "' .. query .. '"')
    mq.delay(25)
    mq.delay(1500, function() return (mq.TLO.DanNet(peer).Q(query).Received() or 0) > 0 end)
    local rx = mq.TLO.DanNet(peer).Q(query).Received() or 0
    if rx > 0 and not _qKeyVerified then
        _qKeyVerified = true -- mark only on a real answer; blips keep trying
        info(string.format("DanNet Q key verified (Received: %d) - collection report is fast.", rx))
    end
    if rx == 0 then return nil end
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

-- Whole collection (7 pages + feather) in ONE query: page counts as
-- base-10 digits (page 1 = ones place), feather flag at the 8th digit.
-- One round-trip per member instead of eight. Assumes nobody holds 10+
-- copies of one page (would carry into the next digit).
local PAGE_MULT = { 1, 10, 100, 1000, 10000, 100000, 1000000 }

local function collectionQuery()
    local parts = { '${If[${FindItemCount[=Unified Phoenix Feather]},1,0]}*10000000' }
    for i = 7, 1, -1 do
        local page = string.format("Torn Old Book - Page %d", i)
        parts[#parts + 1] = string.format('(${FindItemCount[=%s]}+${FindItemBankCount[=%s]})*%d', page, page, PAGE_MULT[i])
    end
    return 'Math.Calc[' .. table.concat(parts, '+') .. ']'
end

-- Unparseable value = query failed (no response, OR the peer answered with
-- junk: mid-zone TLOs, a Math.Calc error). Return nil, nil so the caller
-- marks the member "unknown" instead of "has nothing" - a failed query must
-- never read as needs-feather + zero-pages.
local function decodeCollection(value)
    local n = tonumber(value)
    if n == nil then return nil, nil end
    n = math.floor(n)
    local counts = {}
    for i = 1, 7 do
        counts[i] = math.floor(n / PAGE_MULT[i]) % 10
    end
    return n >= 10000000, counts
end

-- Cached Roster + Collection Report (main loop writes, render reads)

local featherAnnounced = {}
local wasHoarding = false

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
    local query = collectionQuery()
    local members = {}

    -- Self: everything local
    local myCounts = {}
    local myHoard = false
    for i = 1, 7 do
        local page = string.format("Torn Old Book - Page %d", i)
        myCounts[i] = (mq.TLO.FindItemCount('=' .. page)() or 0) + (mq.TLO.FindItemBankCount('=' .. page)() or 0)
        if myCounts[i] >= 10 then myHoard = true end -- base-10 digit encoding can't represent 10+ per page
    end
    members[1] = {
        name = mq.TLO.Me.CleanName(),
        lvl = mq.TLO.Me.Level() or 0,
        cls = mq.TLO.Me.Class.ShortName() or "?",
        zone = mq.TLO.Zone.ShortName() or "?",
        feather = (mq.TLO.FindItemCount("=Unified Phoenix Feather")() or 0) > 0,
        counts = myCounts,
        pageCount = 0,
    }

    -- Boxes: lvl/cls/zone from instant local Group TLOs (no DanNet);
    -- whole collection in one decoded round-trip each
    for gi = 1, (mq.TLO.Group.Members() or 0) do
        local gm = mq.TLO.Group.Member(gi)
        if gm.CleanName() and not gm.Mercenary() then
            local name = gm.CleanName()
            setStatus("Checking " .. name .. "...")
            local feather, counts = decodeCollection(dqueryNoparse(name:lower(), query))
            if counts == nil then -- no response: one retry before giving up
                feather, counts = decodeCollection(dqueryNoparse(name:lower(), query))
            end
            members[#members + 1] = {
                name = name,
                lvl = gm.Level() or "?",
                cls = gm.Class.ShortName() or "?",
                -- Spawn visible = same zone instance as me (better than a
                -- ShortName match, which can't tell instances apart). Only
                -- pay a dquery for the actual zone when they're NOT with me.
                zone = (gm.Spawn.ID() or 0) > 0 and (mq.TLO.Zone.ShortName() or "?")
                    or (dquery(name:lower(), 'Zone.ShortName') or "elsewhere"),
                feather = feather,         -- nil = unknown (query failed)
                counts = counts,           -- nil = unknown
                unknown = (counts == nil),
                pageCount = 0,
            }
        end
    end

    for _, m in ipairs(members) do
        if m.feather and not featherAnnounced[m.name] then
            featherAnnounced[m.name] = true -- announce once per session, not every refresh
            info(string.format("%s already has the Unified Phoenix Feather", m.name))
        end
    end

    local covered = 0
    for i = 1, 7 do
        local holders = {}
        local names = {}
        local extra = false
        for _, m in ipairs(members) do
            local n = m.counts and m.counts[i] or 0
            if n > 0 then
                m.pageCount = m.pageCount + n
                names[m.name] = true
                holders[#holders + 1] = (n > 1) and string.format("%s x%d", m.name, n) or m.name
                if n > 1 then extra = true end
            end
        end
        if #holders > 0 then covered = covered + 1 end
        gui.pages[i] = { holders = (#holders > 0) and table.concat(holders, ", ") or nil, names = names, extra = extra }
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
    local unknown = {}
    for _, m in ipairs(members) do
        if m.unknown then unknown[#unknown + 1] = m.name
        elseif m.feather == false then needy[#needy + 1] = m.name end
    end
    if #needy == 0 and #unknown == 0 and #members > 0 then
        info("everyone in the group already has the Unified Phoenix Feather.")
    elseif #needy > 0 then
        info("still needs the Feather: " .. table.concat(needy, ", "))
    end
    if #unknown > 0 then
        warn("could not read collection for: " .. table.concat(unknown, ", ") .. " (DanNet no-response) - their pages/feather are UNKNOWN, not zero. Page coverage may be understated.")
    end
    if myHoard and not wasHoarding then -- warn on the edge, not every refresh (re-arms when it clears)
        warn("you hold 10+ of a single page - the encoded page query can't represent that, so the group's decoded page counts may be wrong. Turn in or hand off the surplus; treat box page counts as approximate until then.")
    end
    wasHoarding = myHoard
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
        -- membership by name table, not substring - "Ann" vs "Joanna"
        page.names = page.names or {}
        if not page.names[who] then
            page.names[who] = true
            page.holders = page.holders .. ", " .. who
            page.extra = true
        end
    else
        gui.pages[i] = { holders = who, names = { [who] = true }, extra = false }
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

-- Pause/unpause the whole crew, not just the driver. Assumes boxes run
-- the same automation family as the driver. CWTN commands are per-class,
-- so boxes get a noparse /docommand and resolve their own ${CWTN.Command}.
local function driverPause()
    if gui.driver == 'boxr' then
        mq.cmd('/boxr pause')
        othersCmd('/boxr pause')
    elseif gui.driver == 'cwtn' then
        mq.cmdf('/%s pause on', mq.TLO.CWTN.Command())
        if not isSolo() then mq.cmd('/noparse /dgge /docommand /${CWTN.Command} pause on') end
    elseif gui.driver == 'rgmercs' then
        mq.cmd('/rgl pause')
        othersCmd('/rgl pause')
    elseif gui.driver == 'kissassist' then
        mq.cmd('/backoff on')
        othersCmd('/backoff on')
    end
end

local function driverUnpause()
    if gui.driver == 'boxr' then
        mq.cmd('/boxr unpause')
        othersCmd('/boxr unpause')
    elseif gui.driver == 'cwtn' then
        mq.cmdf('/%s pause off', mq.TLO.CWTN.Command())
        if not isSolo() then mq.cmd('/noparse /dgge /docommand /${CWTN.Command} pause off') end
    elseif gui.driver == 'rgmercs' then
        mq.cmd('/rgl unpause')
        othersCmd('/rgl unpause')
    elseif gui.driver == 'kissassist' then
        mq.cmd('/backoff off')
        othersCmd('/backoff off')
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
        if gui.paused and not pauseGate() then return end
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
            if not gui.requestStop then fail("never reached Qeynos Hills.") end
            return false
        end
        mq.delay(3000)
    end
    setStatus("Waiting for group in Qeynos Hills...")
    if not waitFor(function() return not mq.TLO.Group.AnyoneMissing() end, 600000, 1000) then
        if gui.requestStop then return false end
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
    -- Sum whatever Nd/Nh/Nm/Ns components appear - the server may omit
    -- leading units ("59m:12s"), and demanding the full d:h:m:s shape
    -- would silently drop the event into the retry-and-fail branch
    mq.event('unityLockout', "#*#you must wait #1# before you can request another task#*#", function(_, timeStr)
        local total = 0
        for n, unit in (timeStr or ''):gmatch("(%d+)([dhms])") do
            local mult = (unit == 'd' and 86400) or (unit == 'h' and 3600) or (unit == 'm' and 60) or 1
            total = total + (tonumber(n) or 0) * mult
        end
        if total > 0 then lockoutSeconds = total end
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

-- Skip blacklist: unreachable/unkillable mobs get timed out instead of
-- reselected forever (infinite-loop fix). Expiry matters - mobs path home.
local skippedIds = {}

local function isSkipped(id)
    local expiry = skippedIds[id]
    if expiry and mq.gettime() < expiry then return true end
    skippedIds[id] = nil
    return false
end

local function skipFor(id, ms)
    skippedIds[id] = mq.gettime() + ms
end

-- Two static gnolls (a guard, a scout) sit walled off in part of the normal
-- zone that's sealed in the anniversary instance - reachable nowhere, almost
-- certainly a dev oversight. Permanently ignore anything parked on these exact
-- locs (loc order Y, X, Z) so the sweep never counts them as trash or burns a
-- pathing attempt on them. Static spawns land on the same spot every instance.
local PERMA_NOTRY = {
    { y = 59.00, x = -563.00, z = -179.81 },
    { y = 72.00, x = -553.00, z = -179.80 },
}

local function isPermaNoTry(spawn)
    local sx, sy, sz = spawn.X() or 0, spawn.Y() or 0, spawn.Z() or 0
    for _, p in ipairs(PERMA_NOTRY) do
        if math.abs(sx - p.x) < 5 and math.abs(sy - p.y) < 5 and math.abs(sz - p.z) < 5 then
            return true
        end
    end
    return false
end

-- Straight-line distance lies in a multi-level zone (a mob below the
-- floor looks "closest"). Take the few nearest candidates by line, then
-- pick by actual NAV PATH length. Returns: id to kill, 0 = zone truly
-- cleared, -1 = trash exists but nothing reachable right now.
local function nearestTrash()
    local candidates = {}
    local totalTrash = 0
    local count = mq.TLO.SpawnCount('npc')() or 0
    for i = 1, count do
        local s = mq.TLO.NearestSpawn(i, 'npc')
        local name = s.CleanName()
        if name and TRASH_NAMES[name] and (s.Type() or '') == 'NPC' and not isPermaNoTry(s) then
            totalTrash = totalTrash + 1
            local id = s.ID() or 0
            if id > 0 and not isSkipped(id) and #candidates < 8 then
                candidates[#candidates + 1] = id
            end
        end
    end
    if totalTrash == 0 then return 0 end
    local bestId, bestLen = -1, 999999
    for _, id in ipairs(candidates) do
        local len = mq.TLO.Navigation.PathLength('id ' .. id)() or -1
        if len < 0 then
            skipFor(id, 120000) -- no nav path: blacklist, retry when it moves
        elseif len < bestLen then
            bestId, bestLen = id, len
        end
    end
    return bestId
end

-- ANYTHING on the hater list gets killed before we seek a new target -
-- ignoring aggro builds trains (Gartik incident). Exception: Axtig is
-- never returned. Returns (haterId, axtigAggro) - callers hold/abort
-- when Axtig is on the list.
local axtigWarnAt = 0
local skippedWarnAt = {}

local function aggroedMobId()
    local bestId, bestDist = 0, 999999
    local axtigAggro = false
    for i = 1, (mq.TLO.Me.XTargetSlots() or 0) do
        local xt = mq.TLO.Me.XTarget(i)
        if (xt.TargetType() or '') == 'Auto Hater' and (xt.ID() or 0) > 0 then
            local id = xt.ID() or 0
            local name = xt.CleanName() or ''
            if name:find('Axtig') then
                axtigAggro = true
                if mq.gettime() - axtigWarnAt > 10000 then -- throttled: called 4x/sec
                    axtigWarnAt = mq.gettime()
                    warn("AXTIG HAS AGGRO - do NOT kill him (completes mission, 2h30m lockout)! Move the group away.")
                end
            elseif isSkipped(id) then
                -- Mob is on xtarget but blacklisted (unreachable/timed-out).
                -- Log once per expiry window so the user knows why we're
                -- ignoring an active aggro indicator instead of looking hung.
                local now = mq.gettime()
                if not skippedWarnAt[id] or now - skippedWarnAt[id] > 30000 then
                    skippedWarnAt[id] = now
                    info(string.format("%s [%d] has aggro but is blacklisted (unreachable/leashed) - ignoring until expiry.", name, id))
                end
            else
                local d = mq.TLO.Spawn(id).Distance3D() or 999999
                if d < bestDist then
                    bestId, bestDist = id, d
                end
            end
        end
    end
    return bestId, axtigAggro
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
            if gui.paused then
                if not pauseGate() then return end
                mq.cmdf('/squelch /nav id %d distance=15', id) -- resume travel
            end
            if (spawn.Distance3D() or 999) < 20 then
                arrived = true
                break
            end
            if not spawn() then break end
            if not mq.TLO.Navigation.Active() then
                mq.cmdf('/squelch /nav id %d distance=15', id) -- nav ended short - re-issue, deadline caps it
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
            skipFor(id, 120000)
            warn("could not reach " .. (spawn.CleanName() or "mob") .. " - blacklisted for 2 min")
            return
        end
    else
        -- Hater: usually inbound, but one stuck under the world never
        -- arrives - close the gap ourselves. No aggro interrupt here:
        -- the target IS the aggro.
        if (spawn.Distance3D() or 999) > 30 then
            mq.cmdf('/squelch /nav id %d distance=15', id)
            if not waitFor(function()
                return (not mq.TLO.Navigation.Active()) or ((spawn.Distance3D() or 999) < 20)
            end, 30000, 250) then
                mq.cmd('/squelch /nav stop')
                skipFor(id, 120000)
                warn((spawn.CleanName() or "hater") .. " unreachable - blacklisted for 2 min")
                return
            end
            mq.cmd('/squelch /nav stop')
        end
    end
    if not spawn() or (spawn.Type() or '') ~= 'NPC' then return end

    mq.cmdf('/target id %d', id)
    mq.delay(300)
    mq.cmd('/squelch /face fast')
    mq.cmd('/attack on')
    -- We engaged manually, so facing is OUR job (driver only faces on its
    -- own engages). Re-face every 3s - water mobs swim circles around you.
    local mobName = spawn.CleanName() or "mob" -- capture before it can despawn
    local isCommander = COMMANDER_NAMES[mobName] or false
    local deadline = mq.gettime() + 180000
    local lastFace = 0
    local died = false
    local despawned = false
    local pacified = false
    while mq.gettime() < deadline do
        if gui.requestStop then break end
        if gui.paused then
            mq.cmd('/attack off')
            if not pauseGate() then break end
            mq.cmd('/attack on')
        end
        mq.doevents() -- commander [keyword] replies must fire MID-fight
        if mq.TLO.Me.Hovering() or (mq.TLO.Zone.ShortName() or '') ~= 'oldblackburrow_ann22raid' then
            warn("we died or left the zone mid-fight - abandoning this kill.")
            break
        end
        local s = mq.TLO.Spawn(id)
        if not s() then
            despawned = true -- leashed/depopped/gated: NOT a kill
            break
        end
        if (s.Type() or '') == 'Corpse' then
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
    elseif despawned then
        info(mobName .. " despawned mid-fight (leash/depop?) - not counted")
    elseif pacified then
        info(mobName .. " pacified after dialogue - moving on")
    else
        skipFor(id, 120000)
        warn("kill timed out on " .. mobName .. " - blacklisted for 2 min")
    end
end

-- One sweep step: aggro'd commanders first, then nearest trash.
-- Returns false when no trash remains (zone cleared).
local function sweepOneMob()
    local haterId, axtigAggro = aggroedMobId()
    if haterId > 0 then
        local name = mq.TLO.Spawn(haterId).CleanName() or "mob"
        if COMMANDER_NAMES[name] then
            info("commander has aggro - killing it (safe: only Axtig completes the mission)")
        end
        killMobById(haterId, false)
        return true
    end
    -- Axtig is the remaining aggro: HOLD the sweep. Seeking new targets
    -- with him in tow risks assists/AE clipping him = mission complete.
    if axtigAggro then
        setStatus("AXTIG HAS AGGRO - sweep held. Move the group away from him!")
        mq.delay(2000)
        return true
    end
    local id = nearestTrash()
    if id == 0 then return false end
    if id == -1 then
        setStatus("No reachable trash right now - waiting for blacklist to expire / mobs to move...")
        mq.delay(5000)
        return true
    end
    killMobById(id, true)
    return true
end

-- Turn-In Pipeline (feather-gated)

local function anyoneNeedsFeather()
    for _, m in ipairs(gui.members) do
        if m.feather == false then return true end -- == false: unknown (nil) doesn't force a turn-in
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
            if not gui.requestStop then
                fail("group not all present after 5 min - turn-in aborted. Gather everyone and Start again.")
            end
            return false
        end
    end
    if gui.requestStop then return false end

    -- Snapshot who lacks a feather - success is verified against this
    local needyBefore = {}
    for _, m in ipairs(gui.members) do
        if m.feather == false then needyBefore[#needyBefore + 1] = m.name end
    end

    -- Fight-your-way-there, same as the sweep (v0.23 rule) - aggro en
    -- route to Ralf gets killed in place, then we resume. Stall detection
    -- gives up early if the path never closes (navmesh gap, Ralf moved) -
    -- the 180s blanket is only the absolute backstop.
    setStatus("Turn-in: heading to Lorekeeper Ralf (fighting through if needed)...")
    local navDeadline = mq.gettime() + 180000
    local lastDist, stallSince = ralf.Distance3D() or 999, mq.gettime()
    while (ralf.Distance3D() or 999) > 15 do
        if gui.requestStop or mq.gettime() > navDeadline then
            mq.cmd('/squelch /nav stop')
            if not gui.requestStop then fail("could not reach Lorekeeper Ralf - turn-in aborted.") end
            return false
        end
        if not ralf() then
            mq.cmd('/squelch /nav stop')
            fail("Lorekeeper Ralf despawned during approach - turn-in aborted.")
            return false
        end
        if gui.paused then
            local pausedAt = mq.gettime()
            if not pauseGate() then return false end
            local pausedFor = mq.gettime() - pausedAt -- paused time isn't a stall; shift both clocks
            stallSince = stallSince + pausedFor
            navDeadline = navDeadline + pausedFor
        end
        local haterId, axtigAggro = aggroedMobId()
        if haterId > 0 then
            mq.cmd('/squelch /nav stop')
            info("aggro on the way to Ralf - clearing it first")
            killMobById(haterId, false)
            stallSince = mq.gettime() -- fighting isn't stalling; reset the clock
        elseif axtigAggro then
            -- Axtig is the only hater: hold nav. The driver's assists/AE
            -- can clip him if we keep moving = mission complete + 2h30m lockout.
            mq.cmd('/squelch /nav stop')
            setStatus("Turn-in HELD - Axtig has aggro! Move the group away from him.")
            mq.delay(2000)
            stallSince = mq.gettime() -- holding isn't stalling
        else
            -- Travelling: track progress. 20s with no distance closed means
            -- /nav can't reach Ralf - bail instead of spinning for 3 minutes.
            local dist = ralf.Distance3D() or 999
            if dist < lastDist - 1 then
                lastDist, stallSince = dist, mq.gettime()
            elseif mq.gettime() - stallSince > 20000 then
                mq.cmd('/squelch /nav stop')
                fail("no path to Lorekeeper Ralf (20s no progress) - turn-in aborted. Move the driver closer and Start again.")
                return false
            end
            if not mq.TLO.Navigation.Active() then
                mq.cmdf('/squelch /nav id %d distance=12', ralf.ID() or 0)
            end
        end
        mq.delay(250)
    end
    mq.cmd('/squelch /nav stop')
    setStatus("Turn-in: delivering 7 pages to Lorekeeper Ralf...")
    mq.cmdf('/target id %d', ralf.ID() or 0)
    mq.delay(500)

    -- Give window holds 4: cursor item -> /click left target loads a
    -- slot; Give button hands the batch over (pattern from giveit/DCM)
    local given = 0
    for i = 1, 7 do
        if gui.requestStop then return false end -- never hand over pages mid-Stop
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
    if given < 7 then
        fail(string.format("only %d of 7 pages were handed over - turn-in INCOMPLETE. Check bags/cursor and Start again.", given))
        info("no feather is awarded on a partial turn-in - the report below still lists everyone as needing one, which is correct.")
        refreshCollection()
        return false
    end
    info("handed all 7 pages to Lorekeeper Ralf!")

    -- The feather arrives ON THE CURSOR for every member - stash it
    -- before anyone fat-fingers it onto the ground. Poll rather than a
    -- single read: a late cursor would miss the stash and risk a drop.
    -- This wait also gives the boxes' feathers time to land before the loop.
    if waitFor(function() return (mq.TLO.Cursor.Name() or '') == "Unified Phoenix Feather" end, 5000, 100) then
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

    -- Settle before verify: /dex autoinventory is async (command travel +
    -- server round-trip + DanNet propagation = 3-5s on a busy server).
    -- Querying immediately would race and show the feather still on cursor.
    mq.delay(4000)

    -- Verify: did everyone who lacked a feather actually get one?
    local function checkStillWithout()
        local t = {}
        for _, m in ipairs(gui.members) do
            for _, name in ipairs(needyBefore) do
                if m.name == name and m.feather == false then -- == false: don't flag unknown as a miss
                    t[#t + 1] = name
                end
            end
        end
        return t
    end

    refreshCollection()
    local stillWithout = checkStillWithout()
    if #stillWithout > 0 then
        -- One retry in case autoinventory was still in-flight during the
        -- first check. A real miss should still show on the second pass.
        info("re-checking feathers in 4s (autoinventory may still be propagating)...")
        mq.delay(4000)
        refreshCollection()
        stillWithout = checkStillWithout()
    end
    if #stillWithout > 0 then
        warn("7 pages handed in but NO Feather detected on: " .. table.concat(stillWithout, ", ") .. " - verify in-game.")
        return #stillWithout < #needyBefore
    end
    info("Feather CONFIRMED for everyone who needed one!")
    return true
end

-- Full Quest only: kill Axtig the Uniter AFTER feathers are done. Killing
-- him COMPLETES the mission (~2h30m lockout) - the Full Quest toggle is the
-- consent (its tooltip warns of the lockout). Knockback is NOT mitigated per
-- AL's config. Reuses killMobById (nav + engage + re-face + wipe/zone abort)
-- in a guarded loop so an en-route aggro bail or short nav just retries.
local function stateAxtig()
    if not gui.fullQuest then return end -- toggled off mid-flight
    if anyoneNeedsFeather() then
        warn("Full Quest: not everyone has a Feather yet - feather ALWAYS first, NOT engaging Axtig. Holding.")
        return
    end
    local axtigId = mq.TLO.Spawn("npc Axtig").ID() or 0
    if axtigId == 0 then
        warn("Full Quest ON but Axtig isn't spawned (he appears after the commanders die). Holding - kill the commanders, then Start again.")
        return
    end
    warn("Full Quest: engaging AXTIG THE UNITER - this COMPLETES the mission (~2h30m lockout). Knockback expected (no levitate per config).")

    local deadline = mq.gettime() + 360000
    local axtigDied = false
    while mq.gettime() < deadline do
        if gui.requestStop then return end
        if mq.TLO.Me.Hovering() or (mq.TLO.Zone.ShortName() or '') ~= 'oldblackburrow_ann22raid' then
            warn("died or left the zone before Axtig fell - Full Quest aborted.")
            return
        end
        local s = mq.TLO.Spawn(axtigId)
        if not s() then break end                            -- despawned (NOT a confirmed kill)
        if (s.Type() or '') == 'Corpse' then axtigDied = true; break end
        -- Clear any non-Axtig aggro first (en-route trash) so we don't keep
        -- re-navving into the same mob - aggroedMobId never returns Axtig.
        local haterId = aggroedMobId()
        if haterId > 0 then
            killMobById(haterId, false)
        else
            killMobById(axtigId, true)
        end
    end

    if axtigDied then
        info("AXTIG THE UNITER IS DOWN - mission COMPLETE. ~2h30m completion lockout now active; coins + rewards delivered. Drop the task / exit when ready.")
    else
        fail("Axtig not confirmed dead (despawn, timeout, or abort) - mission may NOT be complete. Verify in-game before assuming the lockout.")
    end
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
    if (gui.state == 'IN_INSTANCE' or gui.state == 'SWEEPING' or gui.state == 'TURN_IN' or gui.state == 'AXTIG' or gui.state == 'HOLD')
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
        -- Turn-in only with a clean hater list (Axtig included) - page 7
        -- can land while mobs are still mid-chase, and blind-navving to
        -- Ralf with live aggro is the exact pattern that caused the wipe
        local haterId, axtigAggro = aggroedMobId()
        if anyoneNeedsFeather() and pagesInMyBags() >= 7 and haterId == 0 and not axtigAggro then
            info("all 7 pages in my bags and no live aggro - heading to Lorekeeper Ralf!")
            gui.state = 'TURN_IN'
        elseif not sweepOneMob() then
            info(string.format("zone cleared - %d kills this run.", gui.killCount))
            refreshCollection() -- authoritative recount after the run
            if gui.fullQuest and not anyoneNeedsFeather() then
                info("Full Quest ON and everyone has feathers - proceeding to Axtig.")
                gui.state = 'AXTIG'
            else
                setStatus(string.format("Zone cleared, %d kills. %d of 7 pages. (Exit pipeline next version)",
                    gui.killCount, gui.covered))
                gui.state = 'HOLD'
            end
        end
    elseif gui.state == 'TURN_IN' then
        local delivered = stateTurnIn()
        if delivered and gui.fullQuest then
            info("Feather delivered! Full Quest ON - proceeding to Axtig.")
            gui.state = 'AXTIG'
        else
            if delivered then
                setStatus("Feather delivered! Drop the task when ready. (Exit pipeline next version)")
            end
            gui.state = 'HOLD'
        end
    elseif gui.state == 'AXTIG' then
        stateAxtig()
        gui.state = 'HOLD'
    elseif gui.state == 'HOLD' then
        -- exit / re-request pipeline lands here next
    end
end

-- GUI Rendering (reads gui table only - no mq.delay, no blocking)

local stateColors = {
    IDLE = { 0.8, 0.8, 0.8, 1 },
    HOLD = { 1.0, 0.8, 0.2, 1 },
    AXTIG = { 1.0, 0.3, 0.3, 1 }, -- danger: mission-completing kill in progress
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
    if ImGui.Button(gui.paused and "Resume" or "Pause") then gui.requestPauseToggle = true end
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
            ImGui.Text(string.format("  %-12s %3s %-4s %-14s %s  pages: %s",
                m.name, tostring(m.lvl), tostring(m.cls), tostring(m.zone),
                m.unknown and "   ?   " or (m.feather and "FEATHER" or "       "),
                m.unknown and "?" or tostring(m.pageCount)))
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
                gui.requestDriverDetect = true -- detection runs in main loop, not render
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
        if gui.requestPauseToggle then
            gui.requestPauseToggle = false
            gui.paused = not gui.paused
            if gui.paused then driverPause() else driverUnpause() end
        end
        if gui.requestDriverDetect then
            gui.requestDriverDetect = false
            gui.driver = detectCombatDriver()
            info("driver set: " .. (gui.driver or "none"))
        end
        if not gui.paused then
            stepStateMachine()
        end
        mq.delay(100)
    end
end

main()
