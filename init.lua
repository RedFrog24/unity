-- init.lua
-- Unity - 22nd Anniversary group mission (Blackburrow: Unity)
-- Created by: RedFrog
-- Created: June 10, 2026
-- Version 0.79 - art consolidated into an assets/ subfolder (loader path now
--   <scriptdir>/assets/). To run/ship: copy init.lua + the assets/ folder.
-- 0.78 - STUCK-BOX AUTO-UNSTICK (AL data 2026-06-15): two ramp spots
--   where chasing boxes wedge; fix = grow to size 14 via MQ2AutoSize, restore 3.
--   runStuckCheck (1/sec, in-instance + active) detects a box parked within 8u
--   of a spot for 5s and grows it loose (30s cooldown). Ensures MQ2AutoSize
--   loaded on the crew at start.
-- 0.77 - page cards (AL): removed the red "MISS" label (red outline
--   stays); "Pg N" label now gold instead of white.
-- 0.76 - button texture swapped to a GREY desaturated feather-swirl
--   crop (alpha 180); header bar darkened + 70% opacity.
-- 0.75 - tuning (AL): button texture 150; header bar 75% opacity.
-- 0.74 - tuning (AL): button texture 255->200 (was too strong); header
--   bar darker + slightly transparent (0.19/0.14/0.30 @ 0.82a).
-- 0.73 - group table header row restyled (AL): purple bar
--   (TableHeaderBg) + gold column labels, replacing the default grey.
-- 0.72 - button texture fixed: was the EQ uiresources file not resolving
--   + too dark to see. Replaced with a BUNDLED unity_btntex.png (sheen + grain,
--   generated) loaded from the script dir, drawn at full alpha - now visible.
-- 0.71 - REAL class icons from a rendered sheet: unity_classicons.png
--   (4x4, rendered from Grimmier's full fa-solid-900.ttf via Pillow) gives the
--   glyphs MQ's bundled font lacks - real skull (SHD), skull+crossbones (NEC),
--   fist (MNK), wizard hat (WIZ), ninja (ROG), khanda (WAR), etc. drawClassIcon
--   UV-crops the cell + tints purple via DrawList. Technique now in root CLAUDE.
-- 0.70 - icon/header polish (AL): improved class icons (added MD set -
--   security/wb_sunny/healing/pets/spa/visibility_off for better fits); Pages
--   header is now a gold book-icon button (no arrow, matches Group); button
--   texture opacity 38 -> 100 (was invisible).
-- 0.69 - roster + button polish (AL): class-type icons per member
--   (ShortName->FA glyph map, FA_USER fallback); bigger roster font (1.2x) +
--   bigger icons to match; subtle EQ texture inside every button (uiresources
--   background_dark.png via EverQuest.Path, alpha 38); checkmark nudged left.
-- 0.68 - feather AS BACKGROUND + opacity (AL): swapped to AL's new
--   feather_bg art (1024x512 2:1 opaque plate, dark swirls left / feather right)
--   drawn full-width BEHIND the table (RowBg dropped so it shows through);
--   WindowBg now fully opaque (no see-through); Group header icon+label gold;
--   Full Quest checkmark nudged back left a touch.
-- 0.67 - feather + group layout (AL): feather PNG re-keyed (dark
--   starfield bg -> transparent + faded edges) so no more harsh rectangle line;
--   Group header is now a people-icon button (FA_USERS, no dropdown arrow);
--   each member/merc row gets a purple FA_USER avatar in a new lead column;
--   roomier rows (CellPadding) using the taller window; checkmark nudged right.
-- 0.66 - group panel reworked (AL): the ugly table-width cut is gone -
--   the table now SHRINK-WRAPS to its columns (SizingFixedFit + NoHostExtendX)
--   and ends right after Pages; the feather fills the right in a TALLER region
--   (min 230px -> longer window) at full vibrancy (alpha 100 -> 230). Checkmark
--   nudged up.
-- 0.65 - group table given an explicit outer width that ENDS before the
--   feather (rows/borders no longer run across the feather graphic); Full Quest
--   checkmark nudged right.
-- 0.64 - header calibration round 3 (AL): buttons now equal-width,
--   taller (28), filling the row edge-to-edge; status line + dot nudged down +
--   right; Full Quest checkmark nudged up + right.
-- 0.63 - header calibration round 2 (AL): status now two-tone (gold
--   [STATE] + WHITE message); status dot vertically centered on the text via
--   CalcTextSize; Full Quest checkmark recolored PURPLE + re-centered; buttons
--   nudged down (plateH*0.86) to clear the plate's bottom gold border.
-- 0.62 - header calibration (AL in-game feedback): version tucked under
--   "TY"; close X nudged up; content pulled up to kill the blank gap (buttons
--   sit over the plate's lower edge); status line now GOLD + faux-bold (drawn
--   twice, 1px offset) via DrawList AddText; Full Quest check realigned onto the
--   baked box so it actually toggles.
-- 0.61 - BAKED HEADER PLATE: unity_header.png (bird + UNITY + ornate
--   gold frame + texture, AL's concept art) becomes the title bar (NoTitleBar);
--   live bits ride on top - version, state-colored dot + status line, clickable
--   Full Quest check (in the baked box), custom close X. Graceful fallback to
--   the v0.60 phoenix+title layout when the plate is absent.
-- 0.60 - card + button polish (AL batch): buttons now gold (glyphs +
--   labels); page cards cleaned up - HELD cards lose the green outline AND the
--   "HELD" label (the found-scroll art conveys it), MISSING cards keep the red
--   outline + "MISS" so what's needed stands out.
-- 0.59 - gold serif "UNITY" title wordmark (unity_title.png, cropped
--   + alpha-keyed from concept_01) drawn next to the phoenix; version stays
--   live text beside it (MQ Lua can't load a custom TTF, so the title is art).
-- 0.58 - window + chrome pass toward the concept: wider fixed width
--   (520) with auto-fit height (no more long half-empty window); rounded
--   corners + thin gold frame borders (theme style vars); buttons now have
--   FontAwesome icons (play/pause/stop/refresh/users). Feather reverted to its
--   native 1:2 aspect (distorting it looked bad); single alpha knob.
-- 0.57 - feather resized wider+shorter via knobs (REVERTED in 0.58 - distorted).
-- 0.56 - feather backdrop wired: unity_feather.png drawn behind the
--   group table (right-anchored, keeps 1:2 aspect so no squash, RowBg dropped
--   so it shows through, clipped to the panel). First pass - tune alpha/size
--   in-game.
-- 0.55 - real art wired: phoenix emblem at the title + two painted
--   scroll states on the page cards (found scroll = HELD, sealed "?" scroll =
--   MISSING), all cropped from AL's concept art. Feather backdrop still a hook
--   (needs in-game height tuning - tall feather vs compact table).
-- 0.54 - art-slot scaffold: lazy getArt() loader (CreateTexture +
--   cache-false-on-miss, PetGear technique). Phoenix emblem wired at the
--   title, parchment wired behind page cards - both graceful no-ops until
--   the PNGs are dropped in. Feather backdrop left as a documented hook.
-- 0.53 - merc row no longer dimmed (reads as "unavailable"); now
--   styled like every other member row, just tagged "merc"
-- 0.52 - GUI pass 2 (AL feedback): zone cell hover-tooltip shows the
--   full name (column clips); mercs now listed as dimmed display-only rows;
--   page cards auto-size to window width so all 7 fit
-- 0.51 - GUI redesign FIRST PASS: purple/gold theme, no-resize window,
--   gold title, BeginTable group panel (long zone name now, gating still uses
--   ShortName), page cards (HELD/MISS). Structure-only; art assets layer later.
-- 0.50 - lockout message now caught: real text is "...before you can
--   DO another task of this type", not "request another task" - pattern was
--   never matching, so the wait time was never parsed (AL screenshot)
-- 0.49 - release self-check: recovery success now verified by the box
--   being VISIBLE to the driver (same instance), not just zone shortname
-- 0.48 - razorgill log spam fixed: announce ONCE per session (was
--   per-id 30s throttle = one line per fish; a school never leashes in an
--   instance so it spammed forever)
-- 0.47 - two more walled-off scouts added to PERMA_NOTRY (4 total)
-- 0.46 - dead-box recovery: a member that dies + respawns in PoK is
--   driven back via Qeynos Hills -> Blevins -> Ready (sweep pauses); fixed
--   gatherGroup's broken /travelto-into-instance; cooldown stops recovery loops
-- 0.45 - combat control rewritten for MIXED teams (tower model):
--   Boxr-first universal, else broadcast ALL families (CWTN/KA/RGMercs) so
--   every box self-selects; Start now unpauses + sets the crew to chase the
--   driver (fixes boxes stranded paused/idle at zone-in)
-- 0.44 - sweep re-widened to ALL trash (reaver/shaman/snake added) so
--   commanders get pulled (Axtig spawns) + no missed pages; razorgills now
--   disengaged (water mob - blacklist + move on); Axtig kill confirmed via the
--   "Defeat Axtig" task objective (Status Done) with corpse as fallback
-- 0.43 - Full Quest exit: after a confirmed Axtig kill, /taskquit
--   the whole crew and wait out the ~1-2 min boot to Blevins, then IDLE
-- 0.42 - Full Quest Axtig kill BUILT (was just a label): after
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
local Icons = require('mq.ICONS')

local version = "0.79"

-- Spawn names from in-game recon 2026-06-11 (208 NPCs in fresh instance).
-- Commanders/Axtig deliberately NOT in this set - commander pipeline handles
-- them; Axtig must NEVER die in PAGES mode (completes mission = 2h30m lockout).
-- Page droppers ONLY (AL-confirmed drop table 2026-06-12): digger, gnoll,
-- guard, scout. Reavers/shamans/snakes/razorgills drop nothing - not
-- sought, but still die if they aggro (hater-first rule). Burly gnolls
-- kept: named chain for the geode aug, not pages.
-- Sweep targets ALL trash, not just confirmed page-droppers. A full clear is
-- free (1h request lockout), and narrowing to droppers (v0.26) backfired:
-- missed pages (a shaman DID drop one) and the narrow path skipped commanders
-- so they didn't get pulled = Axtig wouldn't spawn for Full Quest (AL 2026-06-13).
-- Killing everything makes the drop table irrelevant and pulls every commander.
-- Razorgills are deliberately OMITTED - they're water mobs we disengage from
-- (see aggroedMobId), not seek.
local TRASH_NAMES = {
    ["a digger"] = true,
    ["a gnoll"] = true,
    ["a guard"] = true,
    ["a scout"] = true,
    ["a reaver"] = true,
    ["a shaman"] = true,
    ["a giant snake"] = true,
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
    groupOpen = true,  -- custom Group header (people-icon button, no arrow)
    pagesOpen = true,  -- custom Pages header (book-icon button, no arrow)
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
        p.zone = dquery(p.peer, 'Zone.Name') or "?" -- long/normal name for display (gating uses ShortName)
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
        zone = mq.TLO.Zone.Name() or "?", -- long/normal name for display (gating uses ShortName)
        feather = (mq.TLO.FindItemCount("=Unified Phoenix Feather")() or 0) > 0,
        counts = myCounts,
        pageCount = 0,
    }

    -- Boxes: lvl/cls/zone from instant local Group TLOs (no DanNet);
    -- whole collection in one decoded round-trip each. Mercs are display-only
    -- (gui.mercs) - never queried/commanded, never in the members logic list.
    local mercs = {}
    for gi = 1, (mq.TLO.Group.Members() or 0) do
        local gm = mq.TLO.Group.Member(gi)
        if gm.CleanName() and gm.Mercenary() then
            mercs[#mercs + 1] = { name = gm.CleanName(), lvl = gm.Level() or "?", cls = gm.Class.ShortName() or "?" }
        elseif gm.CleanName() then
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
                zone = (gm.Spawn.ID() or 0) > 0 and (mq.TLO.Zone.Name() or "?")
                    or (dquery(name:lower(), 'Zone.Name') or "elsewhere"),
                feather = feather,         -- nil = unknown (query failed)
                counts = counts,           -- nil = unknown
                unknown = (counts == nil),
                pageCount = 0,
            }
        end
    end
    gui.mercs = mercs

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

-- Combat Driver Adapter (broadcast-all model, from missions_anniversarytower)
-- gui.driver = the DRIVER's OWN automation (one family) - used for its own
-- pause/unpause + the GUI label. Commands to the BOXES are broadcast: Boxr-
-- first (its /boxr command is universal across CWTN/KA/RGMercs/MuleAssist/
-- Entropy); without Boxr we send EVERY family's command and each box obeys its
-- own + ignores the rest - so a MIXED crew (CWTN tank/KA healer/RGMercs DPS)
-- needs no per-member detection.

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

-- Which families to broadcast to the boxes. Override forces one; else Boxr-
-- first (universal), else all non-boxr families at once.
local function broadcastFamilies()
    if gui.driverOverride ~= 'auto' then
        if gui.driverOverride == 'none' then return {} end
        return { gui.driverOverride }
    end
    if mq.TLO.Plugin('MQ2Boxr').IsLoaded() then return { 'boxr' } end
    return { 'cwtn', 'kissassist', 'rgmercs' }
end

-- Pause/unpause the DRIVER's own automation (one family we run ourselves).
local function selfCombat(pause)
    if gui.driver == 'boxr' then
        mq.cmd(pause and '/boxr pause' or '/boxr unpause')
    elseif gui.driver == 'cwtn' then
        mq.cmdf('/%s pause %s', mq.TLO.CWTN.Command(), pause and 'on' or 'off')
    elseif gui.driver == 'rgmercs' then
        mq.cmd(pause and '/rgl pause' or '/rgl unpause')
    elseif gui.driver == 'kissassist' then
        mq.cmd(pause and '/backoff on' or '/backoff off')
    end
end

-- Broadcast pause/unpause to the boxes across every active family.
local function othersCombat(pause)
    if isSolo() then return end
    for _, fam in ipairs(broadcastFamilies()) do
        if fam == 'boxr' then
            othersCmd(pause and '/boxr pause' or '/boxr unpause')
        elseif fam == 'cwtn' then
            mq.cmd('/noparse /dgge /docommand /${CWTN.Command} pause ' .. (pause and 'on' or 'off'))
        elseif fam == 'rgmercs' then
            othersCmd(pause and '/rgl pause' or '/rgl unpause')
        elseif fam == 'kissassist' then
            othersCmd(pause and '/backoff on' or '/backoff off')
        end
    end
end

local function driverPause()
    selfCombat(true)
    othersCombat(true)
end

local function driverUnpause()
    selfCombat(false)
    othersCombat(false)
end

-- Set the boxes to chase the driver during the sweep (boxes only - the script
-- navs the driver itself). Leaves each box's MA/assist target as its own
-- config (per AL): CWTN mode 2 / KA chase / RGMercs chaseon follow whatever
-- assist they're already set to. Commands from the tower's SetGroupChaseMode.
-- CHASE-ON only: there's no consistent cross-family "stop chasing but keep
-- fighting" (CWTN's off is mode 0 = combat OFF, unlike KA/RGMercs which just
-- stop following), so we never broadcast an "off" - Stop pauses instead.
local function setCrewChase()
    if isSolo() then return end
    for _, fam in ipairs(broadcastFamilies()) do
        if fam == 'boxr' then
            othersCmd('/boxr chase')
        elseif fam == 'cwtn' then
            mq.cmd('/noparse /dgge /docommand /${CWTN.Command} mode 2')
        elseif fam == 'kissassist' then
            othersCmd('/chase on')
        elseif fam == 'rgmercs' then
            othersCmd('/rg chaseon')
            othersCmd('/rgl chaseon')
        end
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

-- Dead-box recovery. A box that dies respawns at bind (PoK) and won't return
-- on its own - and you CAN'T /travelto an instance, so the only way back is
-- Qeynos Hills -> Blevins -> Ready (the shared task is still in its journal
-- after death). recoverCooldown stops a box that can't make it back from
-- looping the sweep forever (failure-path memory).
local recoverCooldown = {}
local missingSince = nil

-- True if some non-merc member is out of our zone instance and not on the
-- recovery cooldown - i.e. worth pausing the sweep to bring back.
local function hasRecoverableMember()
    if isSolo() then return false end
    for i = 1, (mq.TLO.Group.Members() or 0) do
        local m = mq.TLO.Group.Member(i)
        if m.CleanName() and not m.Mercenary() and (m.Spawn.ID() or 0) == 0 then
            local cd = recoverCooldown[m.CleanName()]
            if not cd or mq.gettime() > cd then return true end
        end
    end
    return false
end

-- Drive one out-of-zone box back into the instance. Remote-polls the box's
-- own Zone via DanNet (it's not in our zone, so Spawn won't see it).
local function recoverBox(name)
    local lower = name:lower()
    info(name .. " is out of the instance (died?) - recovering via Blevins re-entry.")
    setStatus("Recovering " .. name .. " - sending to Qeynos Hills...")
    mq.cmdf('/dex %s /travelto qeytoqrg', lower)
    if not waitFor(function()
        return gui.requestStop
            or (mq.TLO.Zone.ShortName() or '') ~= 'oldblackburrow_ann22raid' -- driver itself left/died
            or (dquery(lower, 'Zone.ShortName') or ''):lower() == 'qeytoqrg'
    end, 300000, 3000) or gui.requestStop or (mq.TLO.Zone.ShortName() or '') ~= 'oldblackburrow_ann22raid' then
        if not gui.requestStop then warn(name .. ": recovery aborted (timeout, or the driver left the instance) - recover manually.") end
        recoverCooldown[name] = mq.gettime() + 120000
        return false
    end
    mq.delay(3000)

    setStatus("Recovering " .. name .. " - re-entering at Blevins...")
    for attempt = 1, 12 do
        if gui.requestStop or (mq.TLO.Zone.ShortName() or '') ~= 'oldblackburrow_ann22raid' then return false end
        mq.cmdf('/dex %s /nav spawn npc Guard Blevins', lower)
        mq.delay(6000) -- let it path to Blevins
        mq.cmdf('/dex %s /target npc Guard Blevins', lower)
        mq.delay(500)
        mq.cmdf('/dex %s /say Ready', lower)
        if waitFor(function()
            -- Visible to US = back in the DRIVER's instance (zone shortname
            -- alone can't tell one instance from another).
            return (mq.TLO.Spawn('pc =' .. name).ID() or 0) > 0
        end, 15000, 1000) then
            info(name .. " re-entered the instance.")
            return true
        end
        setStatus(string.format("Recovering %s - re-entry attempt %d...", name, attempt))
    end
    warn(name .. ": could not re-enter after several tries - leaving for now (2 min cooldown), continuing short-handed.")
    recoverCooldown[name] = mq.gettime() + 120000
    return false
end

-- Recover every out-of-zone (non-cooldown) member, one at a time. Sweep is
-- paused by the caller. Returns when none are left to recover.
local function recoverMissingBoxes()
    for i = 1, (mq.TLO.Group.Members() or 0) do
        local m = mq.TLO.Group.Member(i)
        if m.CleanName() and not m.Mercenary() and (m.Spawn.ID() or 0) == 0 then
            local cd = recoverCooldown[m.CleanName()]
            if not cd or mq.gettime() > cd then
                if gui.requestStop then return end
                recoverBox(m.CleanName())
            end
        end
    end
end

-- Ramp STUCK-SPOTS: two stair-element spots where chasing boxes wedge (captured
-- AL 2026-06-15, loc order Y, X, Z). Fix CONFIRMED in-game: momentarily GROW the
-- box to size 14 via MQ2AutoSize, then restore (the old "client-side resize won't
-- help" belief was wrong). sizeself is a PERSISTENT setting, so we set it back.
local STUCK_SPOTS = {
    { y = 311.37, x = 72.63, z = -130.27 },
    { y = 294.45, x = 27.50, z = -154.24 },
}
local STUCK_RADIUS = 8        -- within this of a spot = candidate
local STUCK_MS = 5000         -- not moving this long near a spot = stuck
local UNSTICK_SIZE = 14       -- AL: size 14 pops it loose
local NORMAL_SIZE = 3         -- their MQ2AutoSize SizeSelf (restore target)
local stuckTrack = {}         -- name -> { y, x, z, since }
local unstickCD = {}          -- name -> cooldown gettime

local function nearStuckSpot(y, x, z)
    for _, s in ipairs(STUCK_SPOTS) do
        if math.abs(y - s.y) < STUCK_RADIUS and math.abs(x - s.x) < STUCK_RADIUS and math.abs(z - s.z) < STUCK_RADIUS then
            return true
        end
    end
    return false
end

local function unstickBox(name)
    info(name .. " wedged on the ramp - growing to size " .. UNSTICK_SIZE .. " to pop loose")
    setStatus(name .. " stuck on the ramp - unsticking...")
    mq.cmdf('/dex %s /autosize sizeself %d', name, UNSTICK_SIZE)
    mq.delay(2500)
    mq.cmdf('/dex %s /autosize sizeself %d', name, NORMAL_SIZE)
    unstickCD[name] = mq.gettime() + 30000 -- 30s per-box cooldown (anti-loop)
end

-- Scan grouped boxes (not self/mercs): if one sits within STUCK_RADIUS of a spot
-- and hasn't moved for STUCK_MS while the driver pulls away, grow it loose.
local function runStuckCheck()
    for i = 1, (mq.TLO.Group.Members() or 0) do
        local m = mq.TLO.Group.Member(i)
        local name = m.CleanName()
        if name and not m.Mercenary() and (m.Spawn.ID() or 0) > 0 then
            local y, x, z = m.Spawn.Y() or 0, m.Spawn.X() or 0, m.Spawn.Z() or 0
            if nearStuckSpot(y, x, z) and (not unstickCD[name] or mq.gettime() > unstickCD[name]) then
                local t = stuckTrack[name]
                if t and math.abs(y - t.y) < 2 and math.abs(x - t.x) < 2 and math.abs(z - t.z) < 2 then
                    if mq.gettime() - t.since > STUCK_MS then
                        unstickBox(name)
                        stuckTrack[name] = nil
                    end
                else
                    stuckTrack[name] = { y = y, x = x, z = z, since = mq.gettime() }
                end
            else
                stuckTrack[name] = nil -- moved off the spot, or not near one
            end
        end
    end
end

-- Bring all grouped boxes to the driver's zone and location. Per-member:
-- each box gets its own nav as IT arrives (3s zone-in settle), re-sent
-- every 20s while still far. One-shot broadcast after everyone arrives
-- left early arrivals idle and late arrivals missed it (v0.12 bug).
-- Inside the instance you can't /travelto in - missing boxes get the
-- Blevins re-entry instead (the broken /travelto-instance was the v0.45 bug).
local function gatherGroup()
    if isSolo() then
        warn("not in a group - nothing to gather.")
        return
    end
    local myZone = mq.TLO.Zone.ShortName() or ""
    local myName = mq.TLO.Me.CleanName()
    if myZone == 'oldblackburrow_ann22raid' then
        recoverMissingBoxes()
        return
    end
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
    -- Real message (AL 2026-06-13): "...you must wait 0d:0h:25m:12s before you
    -- can do another task of this type." The old pattern demanded "request
    -- another task" (wrong word) so it never fired. Match only the stable
    -- "you must wait <time> before" - the suffix wording varies.
    mq.event('unityLockout', "#*#you must wait #1# before#*#", function(_, timeStr)
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
    { y = 59.00, x = -563.00, z = -179.81 },   -- a guard (walled off)
    { y = 72.00, x = -553.00, z = -179.80 },   -- a scout (walled off)
    { y = -328.25, x = -831.62, z = -202.80 }, -- a scout (walled off)
    { y = -112.00, x = -755.00, z = -203.07 }, -- a scout (walled off)
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
local razorgillNoted = false

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
            elseif name:find('razorgill') then
                -- Water mobs: fighting them traps us in the water (often can't
                -- even land a hit) and they NEVER leash in an instance, so a
                -- school of them sits on the hate list forever. We just ignore
                -- them - skip + move on to land targets. Announce ONCE per
                -- session (per-id throttle = one line per fish = spam).
                if not razorgillNoted then
                    razorgillNoted = true
                    info("ignoring razorgills (water mobs - they hold aggro but we never engage them).")
                end
                skipFor(id, 60000)
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

-- Authoritative mission-complete check: the "Defeat Axtig" task objective
-- flips to Status "Done" the instant he dies (verified in-game: "0/1" while
-- alive, "Done" when dead; the objective only exists once he spawns). Scan
-- by text so a shifting objective index can't break it.
local function axtigObjectiveDone()
    local task = mq.TLO.Task("Unity")
    if not task() then return false end
    for i = 1, 10 do
        if (task.Objective(i)() or "") == "Defeat Axtig" then
            return (task.Objective(i).Status() or "") == "Done"
        end
    end
    return false
end

-- Full Quest only: kill Axtig the Uniter AFTER feathers are done. Killing
-- him COMPLETES the mission (~2h30m lockout) - the Full Quest toggle is the
-- consent (its tooltip warns of the lockout). Knockback is NOT mitigated per
-- AL's config. Reuses killMobById (nav + engage + re-face + wipe/zone abort)
-- in a guarded loop so an en-route aggro bail or short nav just retries.
-- Returns true only when the mission is CONFIRMED complete (task objective
-- "Defeat Axtig" = Done, or his corpse observed) - caller drops task on true.
local function stateAxtig()
    if not gui.fullQuest then return false end -- toggled off mid-flight
    if anyoneNeedsFeather() then
        warn("Full Quest: not everyone has a Feather yet - feather ALWAYS first, NOT engaging Axtig. Holding.")
        return false
    end
    local axtigId = mq.TLO.Spawn("npc Axtig").ID() or 0
    if axtigId == 0 then
        warn("Full Quest ON but Axtig isn't spawned (he appears after the commanders die). Holding - kill the commanders, then Start again.")
        return false
    end
    warn("Full Quest: engaging AXTIG THE UNITER - this COMPLETES the mission (~2h30m lockout). Knockback expected (no levitate per config).")

    local deadline = mq.gettime() + 360000
    local axtigDied = false
    while mq.gettime() < deadline do
        if gui.requestStop then return false end
        if mq.TLO.Me.Hovering() or (mq.TLO.Zone.ShortName() or '') ~= 'oldblackburrow_ann22raid' then
            warn("died or left the zone before Axtig fell - Full Quest aborted.")
            return false
        end
        if axtigObjectiveDone() then axtigDied = true; break end -- authoritative: mission complete
        local s = mq.TLO.Spawn(axtigId)
        if not s() then break end                            -- gone + objective not Done = not confirmed
        if (s.Type() or '') == 'Corpse' then axtigDied = true; break end -- fallback signal
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
        info("AXTIG THE UNITER IS DOWN - mission COMPLETE. ~2h30m completion lockout now active; coins + rewards delivered.")
    else
        fail("Axtig not confirmed dead (despawn, timeout, or abort) - mission may NOT be complete. NOT dropping the task. Verify in-game.")
    end
    return axtigDied
end

-- Leave the instance: drop the shared task for the whole crew, then wait for
-- the ~1-2 min auto-boot that ejects everyone to Blevins (AL: /taskquit, then
-- wait it out). Boxes drop first so a booted driver can't miss them. Returns
-- true once we're actually outside the instance.
local function dropTaskAndExit()
    info("Mission complete - dropping the shared task (whole crew). Auto-boot to Blevins in ~1-2 min.")
    othersCmd('/taskquit') -- boxes drop their own membership (/dgge, skipped if solo)
    mq.delay(500)
    mq.cmd('/taskquit')    -- driver drops
    setStatus("Mission complete - waiting for boot-out to Blevins...")
    local bootDeadline = mq.gettime() + 240000
    while (mq.TLO.Zone.ShortName() or '') == 'oldblackburrow_ann22raid' do
        if gui.requestStop then return false end
        if mq.gettime() > bootDeadline then
            warn("still in the instance after 4 min - boot didn't fire. /taskquit may have failed; drop the task manually.")
            return false
        end
        mq.delay(1000)
    end
    info("booted out of the instance - back near Blevins. Full Quest run complete.")
    return true
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
    if (gui.state == 'IN_INSTANCE' or gui.state == 'SWEEPING' or gui.state == 'TURN_IN' or gui.state == 'AXTIG' or gui.state == 'RECOVERING' or gui.state == 'HOLD')
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
            -- Make the whole crew active for the run: unpause every automation
            -- family and set the boxes to chase the driver. Broadcast-all so a
            -- mixed team (CWTN/KA/RGMercs) all responds - fixes boxes left
            -- paused/idle at zone-in (the stranded-bard bug).
            driverUnpause()
            setCrewChase()
            info("crew unpaused + set to chase the driver.")
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
        -- A member out of the instance (died -> respawned in PoK) won't return
        -- on its own. Debounce against transient zoning, then pause to recover.
        if hasRecoverableMember() then
            missingSince = missingSince or mq.gettime()
            if mq.gettime() - missingSince > 10000 then
                missingSince = nil
                gui.state = 'RECOVERING'
                return
            end
        else
            missingSince = nil
        end
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
        if stateAxtig() and dropTaskAndExit() then
            setStatus("Full Quest COMPLETE - mission done, booted out. ~2.5h lockout active.")
            gui.state = 'IDLE'
        else
            gui.state = 'HOLD' -- Axtig unconfirmed, or still inside after the drop
        end
    elseif gui.state == 'RECOVERING' then
        -- Sweep paused: bring back every out-of-zone member, then resume.
        -- A box that can't make it goes on cooldown so we don't loop.
        setStatus("Sweep paused - recovering out-of-zone member(s)...")
        recoverMissingBoxes()
        driverUnpause() -- a returned box may have respawned paused; re-activate
        setCrewChase()  -- and make sure it chases the driver again
        if gui.state == 'RECOVERING' then gui.state = 'SWEEPING' end
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

-- Art assets (v0.54 redesign - the showpiece layer). Textures load lazily
-- from the script's own folder and cache a `false` sentinel on miss, so a
-- missing PNG is a one-time no-op, never a per-frame CreateTexture retry.
-- Every draw site guards on a non-nil return, so the pure-ImGui look is
-- identical until the art is dropped in. PetGear technique: mq.CreateTexture
-- + GetTextureID. Art lives in the `assets/` subfolder next to init.lua - to
-- run/ship, copy init.lua AND the assets/ folder to the MQ lua/unity folder.
local artDir = (debug.getinfo(1, 'S').source:sub(2):match('(.*[/\\])') or '') .. 'assets' .. package.config:sub(1, 1)
local ART_FILES = {
    header        = 'unity_header.png',         -- full baked header plate (bird+UNITY+frame+texture)
    phoenix       = 'unity_phoenix.png',        -- emblem by the title (fallback when no header plate)
    title         = 'unity_title.png',          -- gold serif "UNITY" wordmark (fallback)
    feather       = 'unity_feather.png',        -- glow-baked backdrop behind the group panel
    scrollFound   = 'unity_scroll_found.png',   -- page-card art when the page is HELD
    scrollMissing = 'unity_scroll_missing.png', -- page-card art when the page is MISSING
    classIcons    = 'unity_classicons.png',     -- 4x4 class-icon sheet (rendered from full FA solid)
    btnTex        = 'unity_btntex.png',          -- sheen + grain overlay for buttons
}
local artCache = {}

-- Returns the texture for an art slot, or nil if the file is absent / the
-- binding lacks CreateTexture. Caches false on failure (one attempt only).
local function getArt(key)
    if artCache[key] ~= nil then return artCache[key] or nil end
    local fname = ART_FILES[key]
    if not fname or not mq.CreateTexture then
        artCache[key] = false
        return nil
    end
    local tex = mq.CreateTexture(artDir .. fname)
    if tex and tex.GetTextureID and tex:GetTextureID() then
        artCache[key] = tex
        return tex
    end
    artCache[key] = false
    return nil
end

-- Overlay our bundled button texture (sheen + grain) over the LAST-drawn item
-- (a button) for a tactile, glassy look. Lower alpha = subtler.
local function textureLastItem(alpha)
    local tex = getArt('btnTex')
    if not tex then return end
    local minx, miny = ImGui.GetItemRectMin()
    local maxx, maxy = ImGui.GetItemRectMax()
    ImGui.GetWindowDrawList():AddImage(tex:GetTextureID(), ImVec2(minx, miny), ImVec2(maxx, maxy),
        ImVec2(0, 0), ImVec2(1, 1), IM_COL32(255, 255, 255, alpha))
end

-- Class ShortName -> cell index in unity_classicons.png (a 4x4 sheet rendered
-- from the FULL FontAwesome solid set, so we get real skull/swords/fist/etc.
-- that MQ's bundled font lacks). drawClassIcon UV-crops the cell + tints purple.
-- Cell order: WAR CLR PAL RNG / SHD DRU MNK BRD / ROG SHM NEC WIZ / MAG ENC BST BER
local CLASS_INDEX = {
    WAR = 0, CLR = 1, PAL = 2, RNG = 3, SHD = 4, DRU = 5, MNK = 6, BRD = 7,
    ROG = 8, SHM = 9, NEC = 10, WIZ = 11, MAG = 12, ENC = 13, BST = 14, BER = 15,
}
local function drawClassIcon(cls, size)
    local tex = getArt('classIcons')
    local idx = CLASS_INDEX[(cls or ""):upper()]
    if not tex or not idx then -- fallback to the built-in person glyph
        ImGui.PushStyleColor(ImGuiCol.Text, 0.66, 0.44, 0.91, 1); ImGui.Text(Icons.FA_USER); ImGui.PopStyleColor()
        return
    end
    local col, row = idx % 4, math.floor(idx / 4)
    local cx, cy = ImGui.GetCursorScreenPos()
    ImGui.GetWindowDrawList():AddImage(tex:GetTextureID(), ImVec2(cx, cy), ImVec2(cx + size, cy + size),
        ImVec2(col / 4, row / 4), ImVec2((col + 1) / 4, (row + 1) / 4), IM_COL32(173, 130, 235, 255))
    ImGui.Dummy(size, size)
end

-- Purple/gold "phoenix" theme (v0.51 redesign, first pass). Pushed before
-- Begin so it skins the window chrome too; the caller pops the same count.
local function pushUnityTheme()
    ImGui.PushStyleColor(ImGuiCol.WindowBg, 0.07, 0.055, 0.11, 1)
    ImGui.PushStyleColor(ImGuiCol.TitleBg, 0.10, 0.08, 0.16, 1)
    ImGui.PushStyleColor(ImGuiCol.TitleBgActive, 0.15, 0.11, 0.24, 1)
    ImGui.PushStyleColor(ImGuiCol.Border, 0.72, 0.57, 0.25, 0.85)
    ImGui.PushStyleColor(ImGuiCol.Text, 0.86, 0.83, 0.93, 1)
    ImGui.PushStyleColor(ImGuiCol.Button, 0.24, 0.18, 0.40, 0.9)
    ImGui.PushStyleColor(ImGuiCol.ButtonHovered, 0.42, 0.31, 0.66, 1)
    ImGui.PushStyleColor(ImGuiCol.ButtonActive, 0.52, 0.40, 0.78, 1)
    ImGui.PushStyleColor(ImGuiCol.FrameBg, 0.13, 0.10, 0.21, 1)
    ImGui.PushStyleColor(ImGuiCol.FrameBgHovered, 0.21, 0.16, 0.34, 1)
    ImGui.PushStyleColor(ImGuiCol.FrameBgActive, 0.28, 0.21, 0.44, 1)
    ImGui.PushStyleColor(ImGuiCol.Header, 0.26, 0.20, 0.42, 0.55)
    ImGui.PushStyleColor(ImGuiCol.HeaderHovered, 0.34, 0.26, 0.54, 0.8)
    ImGui.PushStyleColor(ImGuiCol.HeaderActive, 0.40, 0.30, 0.62, 1)
    ImGui.PushStyleColor(ImGuiCol.CheckMark, 0.85, 0.70, 0.32, 1)
    ImGui.PushStyleColor(ImGuiCol.Separator, 0.50, 0.40, 0.22, 0.5)
    -- Rounded chrome (Grimmier/magegear style) + thin gold frame borders.
    ImGui.PushStyleVar(ImGuiStyleVar.WindowRounding, 9)
    ImGui.PushStyleVar(ImGuiStyleVar.ChildRounding, 6)
    ImGui.PushStyleVar(ImGuiStyleVar.FrameRounding, 5)
    ImGui.PushStyleVar(ImGuiStyleVar.PopupRounding, 5)
    ImGui.PushStyleVar(ImGuiStyleVar.GrabRounding, 4)
    ImGui.PushStyleVar(ImGuiStyleVar.FrameBorderSize, 1)
    return 16, 6 -- color count, style-var count (caller pops both, incl. early return)
end

-- Header plate: one baked PNG (bird + UNITY + ornate gold frame + texture) used
-- as the window's title bar (window gets NoTitleBar when this art is present).
-- The DYNAMIC bits ride on top, positioned as fractions of the plate's rect -
-- nudge the *Frac numbers against the real art. Advances the cursor below it.
-- PNG is a 1024x512 canvas with the plate in the top 358px (transparent below).
local function drawHeaderPlate(header)
    local wx, wy = ImGui.GetWindowPos()
    local winW = ImGui.GetWindowWidth()
    local imgH = winW * 0.5          -- 1024x512 canvas drawn edge-to-edge
    local plateH = imgH * 0.70       -- the plate occupies the top ~70% of the canvas
    local dl = ImGui.GetWindowDrawList()
    dl:AddImageRounded(header:GetTextureID(), ImVec2(wx, wy), ImVec2(wx + winW, wy + imgH),
        ImVec2(0, 0), ImVec2(1, 1), IM_COL32(255, 255, 255, 255), 9,
        ImDrawFlags and ImDrawFlags.RoundCornersTop or 0)

    -- live version, tucked under the "TY" of the baked UNITY
    ImGui.SetCursorPos(winW * 0.34, plateH * 0.50)
    ImGui.PushStyleColor(ImGuiCol.Text, 0.90, 0.76, 0.36, 1)
    ImGui.Text("v" .. version)
    ImGui.PopStyleColor()

    -- status: state-colored dot + GOLD [STATE] tag + WHITE message, faux-bold
    -- (no real bold font in MQ, so draw each twice with a 1px offset to thicken)
    local c = stateColors[gui.state] or { 0.4, 1.0, 0.4, 1 }
    local sx, sy = wx + winW * 0.11, wy + plateH * 0.68
    local stateTag = string.format("[%s]%s", gui.state, gui.paused and " PAUSED" or "")
    local msg = " " .. gui.status
    local tagW, textH = ImGui.CalcTextSize(stateTag)
    local gold = IM_COL32(232, 196, 104, 255)
    local white = IM_COL32(238, 236, 245, 255)
    dl:AddCircleFilled(ImVec2(wx + winW * 0.078, sy + textH * 0.5), 5,
        IM_COL32(math.floor(c[1] * 255), math.floor(c[2] * 255), math.floor(c[3] * 255), 255))
    dl:AddText(ImVec2(sx, sy), gold, stateTag)
    dl:AddText(ImVec2(sx + 1, sy), gold, stateTag)
    dl:AddText(ImVec2(sx + tagW, sy), white, msg)
    dl:AddText(ImVec2(sx + tagW + 1, sy), white, msg)

    -- Full Quest: clickable check inside the BAKED box (no ImGui frame = no double box)
    local boxSize = plateH * 0.16
    ImGui.SetCursorPos(winW * 0.70, plateH * 0.27)
    local fqx, fqy = ImGui.GetCursorScreenPos()
    ImGui.InvisibleButton("##fqtoggle", boxSize, boxSize)
    if ImGui.IsItemHovered() then
        ImGui.SetTooltip("ON: kill Axtig after feathers (mission complete, 2h30m lockout)\nOFF: feathers only - never engage Axtig")
    end
    if ImGui.IsItemClicked() and gui.state ~= 'SWEEPING' then gui.fullQuest = not gui.fullQuest end
    if gui.fullQuest then
        local purple = IM_COL32(168, 112, 232, 255)
        dl:AddLine(ImVec2(fqx + boxSize * 0.40, fqy + boxSize * 0.42), ImVec2(fqx + boxSize * 0.60, fqy + boxSize * 0.62), purple, 3)
        dl:AddLine(ImVec2(fqx + boxSize * 0.60, fqy + boxSize * 0.62), ImVec2(fqx + boxSize * 0.94, fqy + boxSize * 0.20), purple, 3)
    end

    -- close (X) top-right
    ImGui.SetCursorPos(winW - 32, plateH * 0.02)
    local xx, xy = ImGui.GetCursorScreenPos()
    ImGui.InvisibleButton("##close", 18, 18)
    if ImGui.IsItemClicked() then gui.open = false end
    local xcol = ImGui.IsItemHovered() and IM_COL32(255, 225, 150, 255) or IM_COL32(190, 160, 90, 255)
    dl:AddLine(ImVec2(xx + 4, xy + 4), ImVec2(xx + 14, xy + 14), xcol, 2)
    dl:AddLine(ImVec2(xx + 14, xy + 4), ImVec2(xx + 4, xy + 14), xcol, 2)

    -- continue content just under the visible frame (tuned so the buttons clear
    -- the plate's bottom gold border without leaving a blank gap)
    ImGui.SetCursorPos(8, plateH * 0.86)
end

local function drawGUI()
    if not gui.open then return end
    local themeColors, themeVars = pushUnityTheme()
    -- Lock the width (wider, closer to the concept) and let height auto-fit the
    -- content, so the window is never a long half-empty box.
    ImGui.SetNextWindowSizeConstraints(520, 0, 520, 4000)
    -- When the baked header plate exists it BECOMES the title bar (NoTitleBar);
    -- otherwise keep the native title bar (+ its close X) for the text fallback.
    local header = getArt('header')
    local winFlags = header and bit32.bor(ImGuiWindowFlags.AlwaysAutoResize, ImGuiWindowFlags.NoTitleBar)
        or ImGuiWindowFlags.AlwaysAutoResize
    local shouldDraw
    gui.open, shouldDraw = ImGui.Begin('Unity##UnityGUI', gui.open, winFlags)
    if not shouldDraw then
        ImGui.End()
        ImGui.PopStyleColor(themeColors)
        ImGui.PopStyleVar(themeVars)
        return
    end

    if header then
        drawHeaderPlate(header)
    else
        -- Fallback (no plate): phoenix emblem + gold "UNITY" wordmark + version + Full Quest
        local phoenix = getArt('phoenix')
        if phoenix then
            ImGui.Image(phoenix:GetTextureID(), ImVec2(30, 30))
            ImGui.SameLine(0, 8)
        end
        local titleArt = getArt('title')
        ImGui.PushStyleColor(ImGuiCol.Text, 0.90, 0.76, 0.36, 1)
        if titleArt then
            ImGui.Image(titleArt:GetTextureID(), ImVec2(120, 30)) -- 256x64 wordmark, 4:1
            ImGui.SameLine(0, 8)
            ImGui.AlignTextToFramePadding()
            ImGui.Text("v" .. version)
        else
            ImGui.AlignTextToFramePadding()
            ImGui.Text("UNITY v" .. version)
        end
        ImGui.PopStyleColor()
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
        local c = stateColors[gui.state] or { 0.4, 1.0, 0.4, 1 }
        ImGui.PushStyleColor(ImGuiCol.Text, c[1], c[2], c[3], c[4])
        ImGui.TextWrapped(string.format("[%s]%s %s", gui.state, gui.paused and " PAUSED" or "", gui.status))
        ImGui.PopStyleColor()
        ImGui.Separator()
    end

    -- Buttons (set flags only)
    ImGui.PushStyleColor(ImGuiCol.Text, 0.90, 0.76, 0.36, 1) -- gold button glyphs + labels
    local btnGap = 5
    local btnW = (ImGui.GetContentRegionAvail() - btnGap * 4) / 5 -- 5 equal buttons fill the row
    local btnH = 28
    if ImGui.Button(Icons.FA_PLAY .. "  Start", btnW, btnH) then gui.requestStart = true end
    textureLastItem(180)
    ImGui.SameLine(0, btnGap)
    if ImGui.Button((gui.paused and Icons.FA_PLAY or Icons.FA_PAUSE) .. "  " .. (gui.paused and "Resume" or "Pause"), btnW, btnH) then gui.requestPauseToggle = true end
    textureLastItem(180)
    ImGui.SameLine(0, btnGap)
    if ImGui.Button(Icons.FA_STOP .. "  Stop", btnW, btnH) then gui.requestStop = true end
    textureLastItem(180)
    ImGui.SameLine(0, btnGap)
    if ImGui.Button(Icons.FA_REFRESH .. "  Refresh", btnW, btnH) then gui.requestRefresh = true end
    textureLastItem(180)
    ImGui.SameLine(0, btnGap)
    if ImGui.Button(Icons.FA_USERS .. "  Gather", btnW, btnH) then gui.requestGather = true end
    textureLastItem(180)
    ImGui.PopStyleColor()
    if ImGui.IsItemHovered() then
        ImGui.SetTooltip("All grouped boxes /travelto your zone, then nav to you.\nUse after grouping so everyone enters together on Start.")
    end
    ImGui.Separator()

    -- Group panel (table)
    -- ART HOOK (feather): unity_feather.png (256x512, dark glow baked in) goes
    -- BEHIND this table. Drawn FIRST on the window draw list so the table text
    -- renders on top; RowBg dropped (only when the feather exists) so the rows
    -- are transparent and it shows through. The feather keeps its 1:2 aspect
    -- (anchored right, height = estimated panel height) so it never squashes -
    -- it just scales down to a narrow strip on the right, like the concept.
    -- Group header: full-width button styled as a header bar - people icon, NO
    -- dropdown arrow (concept style). Toggles gui.groupOpen.
    ImGui.PushStyleVar(ImGuiStyleVar.ButtonTextAlign, 0.02, 0.5)
    ImGui.PushStyleColor(ImGuiCol.Text, 0.90, 0.76, 0.36, 1) -- gold icon + label
    if ImGui.Button(string.format("%s  Group (%d/6)###grouphdr", Icons.FA_USERS, #gui.members), ImGui.GetContentRegionAvail(), 0) then
        gui.groupOpen = not gui.groupOpen
    end
    textureLastItem(180)
    ImGui.PopStyleColor()
    ImGui.PopStyleVar()
    if gui.groupOpen then
        local feather = #gui.members > 0 and getArt('feather')
        local availW = ImGui.GetContentRegionAvail()
        -- *1.25 + pad estimates the table height with the bigger row font below.
        local rowsH = ((#gui.members + #(gui.mercs or {})) + 1.5) * ImGui.GetTextLineHeightWithSpacing() * 1.25 + 16
        -- feather_bg is a 2:1 opaque plate (dark swirls left, feather right) drawn
        -- full-width BEHIND the table - at least its native height so the whole
        -- feather shows; the table shrink-wraps over the dark-left.
        local regionH = feather and math.max(rowsH, availW * 0.5) or rowsH
        local panelTopY = ImGui.GetCursorPosY()
        if feather then
            local fx, fy = ImGui.GetCursorScreenPos()
            ImGui.GetWindowDrawList():AddImage(feather:GetTextureID(), ImVec2(fx, fy), ImVec2(fx + availW, fy + regionH),
                ImVec2(0, 0), ImVec2(1, 1), IM_COL32(255, 255, 255, 255)) -- opaque background
        end
        -- drop RowBg when the bg image is shown so the texture shows through the rows
        local tblFlags = feather and ImGuiTableFlags.BordersInnerH
            or bit32.bor(ImGuiTableFlags.RowBg, ImGuiTableFlags.BordersInnerH)
        if feather then -- shrink-wrap so the table ends right after the Pages column
            tblFlags = bit32.bor(tblFlags, ImGuiTableFlags.SizingFixedFit, ImGuiTableFlags.NoHostExtendX)
        end
        ImGui.PushFont(ImGui.GetFont(), ImGui.GetFontSize() * 1.2) -- bigger roster text + icons
        ImGui.PushStyleVar(ImGuiStyleVar.CellPadding, 4, 5) -- roomier rows (concept style)
        ImGui.PushStyleColor(ImGuiCol.TableHeaderBg, 0.16, 0.12, 0.26, 0.70) -- purple header bar (darker, slightly transparent)
        if #gui.members > 0 and ImGui.BeginTable("##grouptbl", 7, tblFlags) then
            ImGui.TableSetupColumn("##av")
            ImGui.TableSetupColumn("Name")
            ImGui.TableSetupColumn("Lv")
            ImGui.TableSetupColumn("Cls")
            ImGui.TableSetupColumn("Zone")
            ImGui.TableSetupColumn("Feather")
            ImGui.TableSetupColumn("Pages")
            ImGui.PushStyleColor(ImGuiCol.Text, 0.90, 0.76, 0.36, 1) -- gold header labels
            ImGui.TableHeadersRow()
            ImGui.PopStyleColor()
            for _, m in ipairs(gui.members) do
                ImGui.TableNextRow()
                ImGui.TableNextColumn(); drawClassIcon(m.cls, 20)
                ImGui.TableNextColumn(); ImGui.Text(tostring(m.name))
                ImGui.TableNextColumn(); ImGui.Text(tostring(m.lvl))
                ImGui.TableNextColumn(); ImGui.Text(tostring(m.cls))
                ImGui.TableNextColumn(); ImGui.Text(tostring(m.zone))
                if ImGui.IsItemHovered() then ImGui.SetTooltip(tostring(m.zone)) end -- full name (column clips)
                ImGui.TableNextColumn()
                if m.unknown then
                    ImGui.TextDisabled("?")
                elseif m.feather then
                    ImGui.PushStyleColor(ImGuiCol.Text, 0.45, 0.95, 0.5, 1); ImGui.Text("Yes"); ImGui.PopStyleColor()
                else
                    ImGui.PushStyleColor(ImGuiCol.Text, 0.95, 0.45, 0.45, 1); ImGui.Text("No"); ImGui.PopStyleColor()
                end
                ImGui.TableNextColumn(); ImGui.Text(m.unknown and "?" or tostring(m.pageCount))
            end -- (avatar cell prepended at the top of each row)
            -- Mercs: display-only rows so the roster matches the slot count;
            -- never queried, so no feather/pages. Styled like everyone else
            -- (NOT dimmed - dimming reads as "unavailable", which it isn't).
            for _, mc in ipairs(gui.mercs or {}) do
                ImGui.TableNextRow()
                ImGui.TableNextColumn(); drawClassIcon(mc.cls, 20)
                ImGui.TableNextColumn(); ImGui.Text(tostring(mc.name))
                ImGui.TableNextColumn(); ImGui.Text(tostring(mc.lvl))
                ImGui.TableNextColumn(); ImGui.Text(tostring(mc.cls))
                ImGui.TableNextColumn(); ImGui.Text("merc")
                ImGui.TableNextColumn(); ImGui.Text("-")
                ImGui.TableNextColumn(); ImGui.Text("-")
            end
            ImGui.EndTable()
        end
        ImGui.PopStyleColor() -- TableHeaderBg
        ImGui.PopStyleVar() -- CellPadding
        ImGui.PopFont()
        if #gui.peers > 0 then
            ImGui.Text("Not grouped:")
            for i, p in ipairs(gui.peers) do
                p.include = ImGui.Checkbox(string.format("%s - %s %s (%s)###peer%d",
                    p.charName, tostring(p.lvl), tostring(p.cls), tostring(p.zone), i), p.include)
            end
            if ImGui.Button("Invite Selected") then gui.requestInvite = true end
        end
        if feather then -- extend the panel down so it's as tall as the feather
            local needY = panelTopY + regionH
            if ImGui.GetCursorPosY() < needY then ImGui.SetCursorPosY(needY) end
        end
    end

    -- Pages panel (cards). Size cards to the live content width so all 7
    -- always fit (was a fixed 52px - page 7 fell off the window).
    -- Pages header: book-icon button, gold, no arrow (same as Group header)
    ImGui.PushStyleVar(ImGuiStyleVar.ButtonTextAlign, 0.02, 0.5)
    ImGui.PushStyleColor(ImGuiCol.Text, 0.90, 0.76, 0.36, 1)
    if ImGui.Button(string.format("%s  Pages (%d of 7)###pageshdr", Icons.FA_BOOK, gui.covered), ImGui.GetContentRegionAvail(), 0) then
        gui.pagesOpen = not gui.pagesOpen
    end
    textureLastItem(180)
    ImGui.PopStyleColor()
    ImGui.PopStyleVar()
    if gui.pagesOpen then
        local availW = ImGui.GetContentRegionAvail()
        local cardW = math.max(38, math.floor((availW - 6 * 4) / 7)) -- 7 cards, 6 gaps of 4px
        -- Two painted scroll states (cropped from AL's concept art): a written
        -- scroll when HELD, a sealed "?" scroll when MISSING. HELD cards are
        -- left clean (the found-scroll art says it all - no outline, no label);
        -- MISSING cards get a red outline (no label) so what's needed stands out.
        -- Every card has a gold "Pg N". No art present -> the old solid colored card.
        local scrollFound = getArt('scrollFound')
        local scrollMissing = getArt('scrollMissing')
        local haveScrolls = scrollFound or scrollMissing
        local cardH = haveScrolls and 74 or 56
        for i = 1, 7 do
            local page = gui.pages[i]
            local held = page and page.holders
            if i > 1 then ImGui.SameLine(0, 4) end
            local scroll = held and scrollFound or scrollMissing
            if scroll then
                local cx, cy = ImGui.GetCursorScreenPos()
                local dl = ImGui.GetWindowDrawList()
                dl:AddImageRounded(scroll:GetTextureID(), ImVec2(cx, cy), ImVec2(cx + cardW, cy + cardH),
                    ImVec2(0, 0), ImVec2(1, 1), IM_COL32(255, 255, 255, 255), 4)
                if not held then -- red outline only on what's missing (held cards stay clean)
                    dl:AddRect(ImVec2(cx, cy), ImVec2(cx + cardW, cy + cardH),
                        IM_COL32(200, 90, 90, 255), 4, 0, 2)
                end
                ImGui.PushStyleColor(ImGuiCol.ChildBg, 0, 0, 0, 0)
            else
                ImGui.PushStyleColor(ImGuiCol.ChildBg, held and 0.14 or 0.26, held and 0.24 or 0.13, held and 0.16 or 0.13, 1)
            end
            -- No child border when a scroll is drawn - the red AddRect (missing only) IS the border.
            ImGui.BeginChild("##page" .. i, cardW, cardH,
                (not scroll and ImGuiChildFlags and ImGuiChildFlags.Borders) or false)
            -- gold "Pg N" label; no state text (the scroll art + red outline say it)
            ImGui.PushStyleColor(ImGuiCol.Text, 0.90, 0.76, 0.36, 1); ImGui.Text("Pg " .. i); ImGui.PopStyleColor()
            ImGui.EndChild()
            ImGui.PopStyleColor()
        end
        if not gui.collectionFresh then
            ImGui.TextDisabled("(stale - click Refresh)")
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
    ImGui.PopStyleColor(themeColors)
    ImGui.PopStyleVar(themeVars)
end

-- Main Execution

local function main()
    info("v" .. version .. " - state machine + GUI")
    info("looting is handled by YOUR setup (lootnscoot / CWTN loot / manual) - this script kills, it does not loot.")
    gui.driver = detectCombatDriver()

    -- Auto-unstick relies on MQ2AutoSize being loaded on the boxes (size 14 pops
    -- a ramp-wedged box loose). Ensure it across the crew (harmless if already on).
    if not mq.TLO.Plugin('MQ2AutoSize').IsLoaded() then mq.cmd('/plugin mq2autosize load') end
    if not isSolo() then mq.cmd('/dgga /plugin mq2autosize load') end

    -- Window FIRST - slow DanNet work happens in the main loop below
    -- while the status line narrates. Never make the user wait blind.
    setStatus("Loading - gathering character data, please wait...")
    mq.imgui.init('UnityGUI', drawGUI)
    gui.requestRefresh = true

    local lastStuckCheck = 0
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
        -- auto-unstick: only inside the instance, while actively running, ~1/sec
        if not gui.paused and gui.state ~= 'IDLE' and gui.state ~= 'HOLD'
            and (mq.TLO.Zone.ShortName() or '') == 'oldblackburrow_ann22raid'
            and mq.gettime() - lastStuckCheck > 1000 then
            lastStuckCheck = mq.gettime()
            runStuckCheck()
        end
        mq.delay(100)
    end
end

main()
