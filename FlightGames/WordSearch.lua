-- Word Search: find eight Warcraft words hidden in an 11x11 grid.
-- Words run in any of the eight directions, including backwards.

local _, ns = ...

local N, CELL, PAD = 11, 30, 9          -- 11 * 30 + 2 * 9 = 348
local WORD_COUNT   = 8
local LIST_H       = 72
local LIST_TOP     = -86 - ns.BOARD_PX - 8

local DIRS = {
    { 0, 1 }, { 1, 0 }, { 1, 1 }, { -1, 1 },
    { 0, -1 }, { -1, 0 }, { -1, -1 }, { 1, -1 },
}

-- One color per word, from the item quality palette.
local FOUND_COLORS = {
    { 0.12, 1.00, 0.00 }, -- Uncommon
    { 0.25, 0.60, 1.00 }, -- Rare
    { 0.75, 0.45, 1.00 }, -- Epic
    { 1.00, 0.50, 0.00 }, -- Legendary
    { 0.00, 0.80, 1.00 }, -- Heirloom
    { 1.00, 0.82, 0.00 }, -- Gold
    { 1.00, 0.35, 0.35 }, -- Red
    { 0.90, 0.80, 0.50 }, -- Artifact
}

local Game = {
    key      = "wordsearch",
    name     = "Word Search",
    desc     = "Find eight hidden Warcraft words.",
    icon     = "Interface\\Icons\\INV_Misc_Spyglass_03",
    height   = -LIST_TOP + LIST_H + 102,
    newText  = "New Puzzle",
    keys     = "Drag across a word, or click its first and last letter",
    defaults = { solved = 0 },
}
ns.RegisterGame(Game)

local db
local cells = {}
local labels = {}
local ui = {}
local selection = {}  -- idx -> true for the squares being selected
local anchor          -- { r, c } where the current selection starts
local pending         -- true after a single click, waiting for the end letter
local dragging

local function Idx(r, c) return (r - 1) * N + c end
local function Sign(x) return (x > 0 and 1) or (x < 0 and -1) or 0 end

--------------------------------------------------------------------------------
-- Puzzle generation
--------------------------------------------------------------------------------

local function Fits(grid, word, r, c, dr, dc)
    local L = #word
    local er, ec = r + dr * (L - 1), c + dc * (L - 1)
    if er < 1 or er > N or ec < 1 or ec > N then return false end
    local overlap = 0
    for i = 1, L do
        local ex = grid[Idx(r + dr * (i - 1), c + dc * (i - 1))]
        if ex then
            if ex ~= word:sub(i, i) then return false end
            overlap = overlap + 1
        end
    end
    return overlap < L
end

local function TryTheme(theme)
    for _ = 1, 30 do
        local pool = {}
        for _, w in ipairs(theme.words) do
            if #w <= N then pool[#pool + 1] = w end
        end
        ns.Shuffle(pool)
        local picked = {}
        for i = 1, math.min(WORD_COUNT, #pool) do picked[i] = pool[i] end
        table.sort(picked, function(a, b) return #a > #b end)

        local grid, words, ok = {}, {}, true
        for _, w in ipairs(picked) do
            local placed
            for _ = 1, 300 do
                local d = DIRS[math.random(#DIRS)]
                local r, c = math.random(N), math.random(N)
                if Fits(grid, w, r, c, d[1], d[2]) then
                    for i = 1, #w do
                        grid[Idx(r + d[1] * (i - 1), c + d[2] * (i - 1))] = w:sub(i, i)
                    end
                    placed = { word = w, r = r, c = c, dr = d[1], dc = d[2], found = false }
                    break
                end
            end
            if not placed then ok = false break end
            words[#words + 1] = placed
        end

        if ok then
            local rows = {}
            for r = 1, N do
                local t = {}
                for c = 1, N do
                    t[c] = grid[Idx(r, c)] or string.char(64 + math.random(26))
                end
                rows[r] = table.concat(t)
            end
            table.sort(words, function(a, b) return a.word < b.word end)
            return rows, words
        end
    end
end

--------------------------------------------------------------------------------
-- Rendering
--------------------------------------------------------------------------------

local function Letter(r, c) return db.grid[r]:sub(c, c) end

local function FoundCount()
    local n = 0
    for _, w in ipairs(db.words) do
        if w.found then n = n + 1 end
    end
    return n
end

local function Render()
    local colorAt = {}
    for i, w in ipairs(db.words) do
        if w.found then
            local col = FOUND_COLORS[(i - 1) % #FOUND_COLORS + 1]
            for k = 0, #w.word - 1 do
                colorAt[Idx(w.r + w.dr * k, w.c + w.dc * k)] = col
            end
        end
    end

    for r = 1, N do
        for c = 1, N do
            local idx = Idx(r, c)
            local cell = cells[idx]
            local col = colorAt[idx]
            cell.text:SetText(Letter(r, c))
            if selection[idx] then
                cell.bg:SetColorTexture(1, 0.82, 0, 0.45)
                cell.text:SetTextColor(1, 1, 1)
            elseif col then
                cell.bg:SetColorTexture(col[1] * 0.35, col[2] * 0.35, col[3] * 0.35, 0.95)
                cell.text:SetTextColor(col[1], col[2], col[3])
            else
                cell.bg:SetColorTexture(0, 0, 0, 0)
                cell.text:SetTextColor(0.85, 0.8, 0.65)
            end
        end
    end

    for i, label in ipairs(labels) do
        local w = db.words[i]
        if w then
            label:SetText(w.word)
            label:Show()
            if w.found then
                local col = FOUND_COLORS[(i - 1) % #FOUND_COLORS + 1]
                label:SetTextColor(col[1], col[2], col[3])
                label.strike:SetColorTexture(col[1], col[2], col[3], 0.9)
                label.strike:SetWidth(label:GetStringWidth() + 6)
                label.strike:Show()
            else
                label:SetTextColor(1, 1, 1)
                label.strike:Hide()
            end
        else
            label:Hide()
            label.strike:Hide()
        end
    end

    ui.found:SetText(FoundCount() .. "/" .. #db.words)
    ui.solved:SetText(db.solved)
    ui.theme:SetText("Theme: " .. db.theme)
end

--------------------------------------------------------------------------------
-- Selection
--------------------------------------------------------------------------------

-- The squares from the anchor to (r, c), if they form a straight line.
local function Line(ar, ac, r, c)
    local dr, dc = r - ar, c - ac
    if dr ~= 0 and dc ~= 0 and math.abs(dr) ~= math.abs(dc) then return nil end
    local sr, sc = Sign(dr), Sign(dc)
    local line = {}
    for k = 0, math.max(math.abs(dr), math.abs(dc)) do
        line[#line + 1] = { ar + sr * k, ac + sc * k }
    end
    return line, sr, sc
end

local function SetSelection(r, c)
    wipe(selection)
    if not anchor then return end
    local line = r and Line(anchor[1], anchor[2], r, c)
    if line then
        for _, p in ipairs(line) do selection[Idx(p[1], p[2])] = true end
    else
        selection[Idx(anchor[1], anchor[2])] = true
    end
end

local function ClearSelection()
    anchor, pending, dragging = nil, nil, nil
    wipe(selection)
end

local function ShowSolved()
    ui.overlay:Present("Puzzle Complete!", 1, 0.82, 0,
        "Word searches solved: " .. db.solved, "New Puzzle", function() Game:NewGame() end)
end

local function TrySelect(ar, ac, r, c)
    local line, sr, sc = Line(ar, ac, r, c)
    if not line then return end
    local t = {}
    for _, p in ipairs(line) do t[#t + 1] = Letter(p[1], p[2]) end
    local str = table.concat(t)
    local rev = str:reverse()

    for _, w in ipairs(db.words) do
        if not w.found and (w.word == str or w.word == rev) then
            w.found = true
            -- Record where it was actually found, in reading order.
            if w.word == str then
                w.r, w.c, w.dr, w.dc = ar, ac, sr, sc
            else
                w.r, w.c, w.dr, w.dc = r, c, -sr, -sc
            end
            if FoundCount() == #db.words then
                db.done = true
                db.solved = db.solved + 1
                ns.Sound("LEVEL_UP")
                C_Timer.After(0.4, function()
                    if db.done then ShowSolved() end
                end)
            else
                ns.Sound("IG_QUEST_LIST_COMPLETE")
            end
            return
        end
    end
end

--------------------------------------------------------------------------------
-- Game flow
--------------------------------------------------------------------------------

function Game:NewGame()
    local themes = ns.WORDSEARCH_THEMES
    local rows, words, theme
    repeat
        theme = themes[math.random(#themes)]
        rows, words = TryTheme(theme)
    until rows

    db.theme = theme.name
    db.grid = rows
    db.words = words
    db.done = false
    ClearSelection()
    ui.overlay:Hide()
    Render()
end

function Game:OnShow()
    if not db.grid then
        self:NewGame()
        return
    end
    ClearSelection()
    Render()
    if db.done then ShowSolved() else ui.overlay:Hide() end
end

function Game:Stat()
    if db.words and not db.done then
        return string.format("Solved: %d  -  Found %d of %d", db.solved, FoundCount(), #db.words)
    end
    return "Solved: " .. db.solved
end

--------------------------------------------------------------------------------
-- Frame construction
--------------------------------------------------------------------------------

function Game:Build(view)
    db = self.db

    local _, hint = ns.CreateHeading(view, "Word Search", "")
    ui.theme = hint
    local solvedBox, solvedText = ns.ScoreBox(view, "SOLVED")
    local _, foundText = ns.ScoreBox(view, "FOUND", solvedBox, -6)
    ui.solved, ui.found = solvedText, foundText

    local board = ns.CreateBoard(view, ns.BOARD_PX)
    for r = 1, N do
        for c = 1, N do
            local cell = CreateFrame("Frame", nil, board)
            cell:SetSize(CELL, CELL)
            cell:SetPoint("TOPLEFT", PAD + (c - 1) * CELL, -(PAD + (r - 1) * CELL))
            cell.bg = cell:CreateTexture(nil, "BACKGROUND")
            cell.bg:SetPoint("TOPLEFT", 1, -1)
            cell.bg:SetPoint("BOTTOMRIGHT", -1, 1)
            cell.text = cell:CreateFontString(nil, "OVERLAY")
            cell.text:SetFont(STANDARD_TEXT_FONT, 17, "OUTLINE")
            cell.text:SetPoint("CENTER", 0, 0)
            cells[Idx(r, c)] = cell
        end
    end

    -- Drag from the first letter to the last, or click one then the other.
    board:EnableMouse(true)
    board:SetScript("OnMouseDown", function(self, button)
        if button ~= "LeftButton" or db.done then return end
        local r, c = ns.CellAtCursor(self, PAD, CELL, N)
        if not r then return end
        if not pending then anchor = { r, c } end
        dragging = true
        SetSelection(r, c)
        Render()
    end)
    board:SetScript("OnMouseUp", function(self, button)
        if button ~= "LeftButton" or not anchor then return end
        dragging = false
        local r, c = ns.CellAtCursor(self, PAD, CELL, N)
        if r and r == anchor[1] and c == anchor[2] then
            if pending then
                ClearSelection()          -- clicked the start again: cancel
            else
                pending = true            -- first click: wait for the last letter
            end
        else
            if r then TrySelect(anchor[1], anchor[2], r, c) end
            ClearSelection()
        end
        Render()
    end)

    -- Preview the line under the mouse while choosing the end letter.
    local lastR, lastC
    board:SetScript("OnUpdate", function(self)
        if not (dragging or pending) or not anchor then return end
        local r, c = ns.CellAtCursor(self, PAD, CELL, N)
        if r == lastR and c == lastC then return end
        lastR, lastC = r, c
        SetSelection(r, c)
        Render()
    end)

    -- Word list
    local list = CreateFrame("Frame", nil, view, "BackdropTemplate")
    list:SetSize(ns.BOARD_PX, LIST_H)
    list:SetPoint("TOP", 0, LIST_TOP)
    ns.PanelBackdrop(list, 0, 0, 0, 0.6)
    local perColumn = WORD_COUNT / 2
    for i = 1, WORD_COUNT do
        local col = math.floor((i - 1) / perColumn)
        local row = (i - 1) % perColumn
        local label = list:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        label:SetPoint("TOPLEFT", 20 + col * (ns.BOARD_PX / 2), -10 - row * 13)
        label.strike = list:CreateTexture(nil, "OVERLAY")
        label.strike:SetHeight(1)
        label.strike:SetPoint("LEFT", label, "LEFT", -3, 0)
        label.strike:Hide()
        labels[i] = label
    end

    ui.overlay = ns.CreateOverlay(board)
end
