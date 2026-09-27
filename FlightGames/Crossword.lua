-- Crossword: a new puzzle every time, built from a bank of Warcraft clues.
-- Words are fitted together on an 11x11 grid so that every one crosses another.

local _, ns = ...

local N, CELL, PAD = 11, 30, 9          -- 11 * 30 + 2 * 9 = 348
local MAX_WORDS    = 12
local ATTEMPTS     = 12
local POOL_SIZE    = 45                 -- candidate words tried per attempt
local CLUE_H       = 46
local CLUE_TOP     = -86 - ns.BOARD_PX - 8

local Game = {
    key      = "crossword",
    name     = "Crossword",
    desc     = "Fill in the grid from Warcraft clues.",
    icon     = "Interface\\Icons\\INV_Misc_Note_01",
    height   = -CLUE_TOP + CLUE_H + 102,
    newText  = "New Puzzle",
    keys     = "Click a square and type. Space turns, Tab = next clue",
    defaults = { solved = 0 },
}
ns.RegisterGame(Game)

local db
local cells = {}
local ui = {}
local L        -- layout of the current puzzle, rebuilt from db.words
local wrong = {}  -- squares flagged by Check, cleared when retyped

local function Idx(r, c) return (r - 1) * N + c end
local function RowCol(idx) return math.floor((idx - 1) / N) + 1, (idx - 1) % N + 1 end
local function Step(d) if d == "A" then return 0, 1 end return 1, 0 end

--------------------------------------------------------------------------------
-- Puzzle generation
--------------------------------------------------------------------------------

local function TryBuild(bank)
    local grid, used, placed = {}, {}, {}

    local function Get(r, c)
        if r < 1 or r > N or c < 1 or c > N then return nil end
        return grid[Idx(r, c)]
    end

    -- Number of crossings if the word fits at (r, c) going d, else nil.
    -- A fit must not touch other words except where it crosses them.
    local function Crossings(word, r, c, d)
        local dr, dc = Step(d)
        local len = #word
        local er, ec = r + dr * (len - 1), c + dc * (len - 1)
        if r < 1 or c < 1 or er > N or ec > N then return nil end
        if Get(r - dr, c - dc) or Get(er + dr, ec + dc) then return nil end
        local crosses = 0
        for i = 1, len do
            local rr, cc = r + dr * (i - 1), c + dc * (i - 1)
            local ex = grid[Idx(rr, cc)]
            if ex then
                if ex ~= word:sub(i, i) or used[Idx(rr, cc)][d] then return nil end
                crosses = crosses + 1
            elseif Get(rr + dc, cc + dr) or Get(rr - dc, cc - dr) then
                return nil
            end
        end
        if crosses == len then return nil end
        return crosses
    end

    local function Place(entry, r, c, d)
        local word = entry[1]
        local dr, dc = Step(d)
        for i = 1, #word do
            local idx = Idx(r + dr * (i - 1), c + dc * (i - 1))
            grid[idx] = word:sub(i, i)
            used[idx] = used[idx] or {}
            used[idx][d] = true
        end
        placed[#placed + 1] = { a = word, clue = entry[2], r = r, c = c, d = d }
    end

    -- Seed with a mid-length word through the middle.
    local first = 1
    for i, e in ipairs(bank) do
        if #e[1] >= 5 and #e[1] <= 9 then first = i break end
    end
    local seed = bank[first]
    local d = (math.random(2) == 1) and "A" or "D"
    local offset = math.floor((N - #seed[1]) / 2) + 1
    local mid = math.ceil(N / 2)
    if d == "A" then Place(seed, mid, offset, d) else Place(seed, offset, mid, d) end

    for i = 1, math.min(#bank, POOL_SIZE) do
        if #placed >= MAX_WORDS then break end
        if i ~= first then
            local entry = bank[i]
            local word = entry[1]
            local best, bestScore = {}, 0
            for idx, ch in pairs(grid) do
                local r0, c0 = RowCol(idx)
                for k = 1, #word do
                    if word:sub(k, k) == ch then
                        for _, dir in ipairs({ "A", "D" }) do
                            local dr, dc = Step(dir)
                            local r, c = r0 - dr * (k - 1), c0 - dc * (k - 1)
                            local x = Crossings(word, r, c, dir)
                            if x and x > 0 then
                                if x > bestScore then
                                    best, bestScore = { { r, c, dir } }, x
                                elseif x == bestScore then
                                    best[#best + 1] = { r, c, dir }
                                end
                            end
                        end
                    end
                end
            end
            if #best > 0 then
                local p = best[math.random(#best)]
                Place(entry, p[1], p[2], p[3])
            end
        end
    end
    return placed
end

-- Move the puzzle to the middle of the grid.
local function Center(words)
    local minR, maxR, minC, maxC = N, 1, N, 1
    for _, w in ipairs(words) do
        local dr, dc = Step(w.d)
        minR = math.min(minR, w.r)
        minC = math.min(minC, w.c)
        maxR = math.max(maxR, w.r + dr * (#w.a - 1))
        maxC = math.max(maxC, w.c + dc * (#w.a - 1))
    end
    local shiftR = math.floor((N - (maxR - minR + 1)) / 2) + 1 - minR
    local shiftC = math.floor((N - (maxC - minC + 1)) / 2) + 1 - minC
    for _, w in ipairs(words) do
        w.r, w.c = w.r + shiftR, w.c + shiftC
    end
end

-- Standard numbering: reading order, across before down on a shared square.
local function Number(words)
    table.sort(words, function(a, b)
        if a.r ~= b.r then return a.r < b.r end
        if a.c ~= b.c then return a.c < b.c end
        return a.d == "A" and b.d ~= "A"
    end)
    local n, last = 0, nil
    for _, w in ipairs(words) do
        local idx = Idx(w.r, w.c)
        if idx ~= last then
            n = n + 1
            last = idx
        end
        w.n = n
    end
end

local function Generate()
    local bank = {}
    for _, e in ipairs(ns.CROSSWORD_CLUES) do
        if #e[1] >= 3 and #e[1] <= N then bank[#bank + 1] = e end
    end
    local best
    for _ = 1, ATTEMPTS do
        ns.Shuffle(bank)
        local set = TryBuild(bank)
        if not best or #set > #best then best = set end
        if #best >= MAX_WORDS then break end
    end
    Center(best)
    Number(best)
    return best
end

--------------------------------------------------------------------------------
-- Layout helpers
--------------------------------------------------------------------------------

local function BuildLayout()
    L = { sol = {}, at = {}, nums = {}, order = {} }
    for wi, w in ipairs(db.words) do
        local dr, dc = Step(w.d)
        for i = 1, #w.a do
            local idx = Idx(w.r + dr * (i - 1), w.c + dc * (i - 1))
            L.sol[idx] = w.a:sub(i, i)
            L.at[idx] = L.at[idx] or {}
            L.at[idx][w.d] = wi
        end
        L.nums[Idx(w.r, w.c)] = w.n
        L.order[#L.order + 1] = wi
    end
    -- Tab order: all across clues, then all down clues.
    table.sort(L.order, function(a, b)
        local wa, wb = db.words[a], db.words[b]
        if wa.d ~= wb.d then return wa.d == "A" end
        return wa.n < wb.n
    end)
end

local function WordCells(wi)
    local w = db.words[wi]
    local dr, dc = Step(w.d)
    local list = {}
    for i = 1, #w.a do
        list[i] = Idx(w.r + dr * (i - 1), w.c + dc * (i - 1))
    end
    return list
end

local function ActiveWord()
    if not db.sel then return nil end
    return L.at[db.sel.idx][db.sel.d]
end

--------------------------------------------------------------------------------
-- Rendering
--------------------------------------------------------------------------------

local function Render()
    local wi = ActiveWord()
    local inWord = {}
    if wi then
        for _, idx in ipairs(WordCells(wi)) do inWord[idx] = true end
    end

    local filled, total = 0, 0
    for idx = 1, N * N do
        local cell = cells[idx]
        if not L.sol[idx] then
            cell:Hide()
        else
            cell:Show()
            total = total + 1
            local ch = db.fill[idx]
            if ch then filled = filled + 1 end
            cell.letter:SetText(ch or "")
            cell.num:SetText(L.nums[idx] or "")

            if db.sel and idx == db.sel.idx then
                cell:SetBackdropColor(0.5, 0.38, 0.04, 0.95)
                cell:SetBackdropBorderColor(1, 0.82, 0, 1)
            elseif inWord[idx] then
                cell:SetBackdropColor(0.24, 0.18, 0.04, 0.95)
                cell:SetBackdropBorderColor(0.8, 0.65, 0.2, 1)
            else
                cell:SetBackdropColor(0.1, 0.09, 0.07, 0.95)
                cell:SetBackdropBorderColor(0.4, 0.36, 0.25, 1)
            end

            if wrong[idx] then
                cell.letter:SetTextColor(1, 0.3, 0.3)
            elseif db.revealed[idx] then
                cell.letter:SetTextColor(0.4, 0.8, 1)
            else
                cell.letter:SetTextColor(1, 1, 1)
            end
        end
    end

    if wi then
        local w = db.words[wi]
        ui.clue:SetText(string.format("|cffffd100%d %s|r  %s", w.n, w.d == "A" and "Across" or "Down", w.clue))
    else
        ui.clue:SetText("|cff808080Click a square to see its clue.|r")
    end
    ui.filled:SetText(filled .. "/" .. total)
    ui.solved:SetText(db.solved)
end

--------------------------------------------------------------------------------
-- Game flow
--------------------------------------------------------------------------------

local function ShowSolved()
    ui.overlay:Present("Puzzle Solved!", 1, 0.82, 0,
        "Crosswords solved: " .. db.solved, "New Puzzle", function() Game:NewGame() end)
end

local function CheckSolved()
    for idx, ch in pairs(L.sol) do
        if db.fill[idx] ~= ch then return end
    end
    db.done = true
    db.solved = db.solved + 1
    Render()
    ns.Sound("LEVEL_UP")
    C_Timer.After(0.4, function()
        if db.done then ShowSolved() end
    end)
end

-- Select a square. Keeps direction d if a word runs that way there.
local function Select(idx, d)
    local at = L.at[idx]
    if not at then return end
    if not at[d] then d = at.A and "A" or "D" end
    db.sel = { idx = idx, d = d }
    Render()
end

local function Toggle()
    Select(db.sel.idx, db.sel.d == "A" and "D" or "A")
end

-- Move within the selected word by +1 / -1 squares.
local function MoveInWord(delta)
    local list = WordCells(ActiveWord())
    for k, idx in ipairs(list) do
        if idx == db.sel.idx then
            if list[k + delta] then db.sel.idx = list[k + delta] end
            return
        end
    end
end

local function NextWord(delta)
    local wi = ActiveWord()
    local pos = 0
    for k, v in ipairs(L.order) do
        if v == wi then pos = k break end
    end
    local nextWi = L.order[(pos - 1 + delta) % #L.order + 1]
    local list = WordCells(nextWi)
    local target = list[1]
    for _, idx in ipairs(list) do
        if not db.fill[idx] then target = idx break end
    end
    Select(target, db.words[nextWi].d)
end

local function MoveArrow(dr, dc)
    local r, c = RowCol(db.sel.idx)
    repeat
        r, c = r + dr, c + dc
    until r < 1 or r > N or c < 1 or c > N or L.sol[Idx(r, c)]
    local d = (dc ~= 0) and "A" or "D"
    if r >= 1 and r <= N and c >= 1 and c <= N then
        Select(Idx(r, c), d)
    else
        Select(db.sel.idx, d)
    end
end

local function Type(letter)
    local idx = db.sel.idx
    db.fill[idx] = letter
    wrong[idx] = nil
    db.revealed[idx] = nil
    MoveInWord(1)
    Render()
    local cell = cells[idx]
    if cell.bump then cell.bump:Stop(); cell.bump:Play() end
    CheckSolved()
end

local function Erase()
    local idx = db.sel.idx
    if not db.fill[idx] then
        MoveInWord(-1)
        idx = db.sel.idx
    end
    db.fill[idx] = nil
    wrong[idx] = nil
    db.revealed[idx] = nil
    Render()
end

local function Check()
    if db.done then return end
    local count = 0
    for idx, ch in pairs(db.fill) do
        if L.sol[idx] and ch ~= L.sol[idx] then
            wrong[idx] = true
            count = count + 1
        end
    end
    Render()
    if count == 0 then
        ui.toast:Flash("No mistakes so far")
    else
        ui.toast:Flash(count == 1 and "1 wrong letter" or (count .. " wrong letters"))
        ns.Sound("IG_QUEST_FAILED")
    end
end

local function RevealWord()
    if db.done or not db.sel then return end
    for _, idx in ipairs(WordCells(ActiveWord())) do
        if db.fill[idx] ~= L.sol[idx] then
            db.fill[idx] = L.sol[idx]
            db.revealed[idx] = true
            wrong[idx] = nil
        end
    end
    Render()
    CheckSolved()
end

Game.extra = { text = "Check", onClick = Check }

function Game:NewGame()
    db.words = Generate()
    db.fill = {}
    db.revealed = {}
    db.done = false
    wipe(wrong)
    BuildLayout()
    local first = db.words[L.order[1]]
    db.sel = nil
    Select(Idx(first.r, first.c), first.d)
    ui.overlay:Hide()
end

function Game:OnShow()
    if not db.words then
        self:NewGame()
        return
    end
    db.fill = db.fill or {}
    db.revealed = db.revealed or {}
    BuildLayout()
    Render()
    if db.done then ShowSolved() else ui.overlay:Hide() end
end

local ARROWS = { UP = { -1, 0 }, DOWN = { 1, 0 }, LEFT = { 0, -1 }, RIGHT = { 0, 1 } }

function Game:OnKey(key)
    if db.done or not db.sel or ui.overlay:IsShown() then return false end
    if key:match("^%u$") then
        Type(key)
    elseif key == "BACKSPACE" or key == "DELETE" then
        Erase()
    elseif key == "SPACE" then
        Toggle()
    elseif key == "TAB" then
        NextWord(1)
    elseif ARROWS[key] then
        MoveArrow(ARROWS[key][1], ARROWS[key][2])
    else
        return false
    end
    return true
end

function Game:Stat()
    if db.words and not db.done then
        return "Solved: " .. db.solved .. "  -  Puzzle in progress"
    end
    return "Solved: " .. db.solved
end

--------------------------------------------------------------------------------
-- Frame construction
--------------------------------------------------------------------------------

function Game:Build(view)
    db = self.db

    ns.CreateHeading(view, "Crossword", "Warcraft clues")
    local solvedBox, solvedText = ns.ScoreBox(view, "SOLVED")
    local _, filledText = ns.ScoreBox(view, "FILLED", solvedBox, -6)
    ui.solved, ui.filled = solvedText, filledText

    local board = ns.CreateBoard(view, ns.BOARD_PX)
    for r = 1, N do
        for c = 1, N do
            local cell = CreateFrame("Frame", nil, board, "BackdropTemplate")
            cell:SetSize(CELL - 2, CELL - 2)
            cell:SetPoint("TOPLEFT", PAD + (c - 1) * CELL + 1, -(PAD + (r - 1) * CELL + 1))
            ns.ThinBackdrop(cell)
            cell.num = cell:CreateFontString(nil, "OVERLAY")
            cell.num:SetFont(STANDARD_TEXT_FONT, 8)
            cell.num:SetPoint("TOPLEFT", 2, -1)
            cell.num:SetTextColor(0.9, 0.8, 0.5)
            cell.letter = cell:CreateFontString(nil, "OVERLAY")
            cell.letter:SetFont(STANDARD_TEXT_FONT, 16, "OUTLINE")
            cell.letter:SetPoint("CENTER", 1, -2)
            cell.bump = ns.CreatePop(cell, 1.15, 0.08)
            cell:Hide()
            cells[Idx(r, c)] = cell
        end
    end

    -- Click a square to select it; click it again to switch direction.
    board:EnableMouse(true)
    board:SetScript("OnMouseDown", function(self, button)
        if button ~= "LeftButton" or db.done or not L then return end
        local r, c = ns.CellAtCursor(self, PAD, CELL, N)
        if not r or not L.sol[Idx(r, c)] then return end
        local idx = Idx(r, c)
        if db.sel and db.sel.idx == idx then
            Toggle()
        else
            Select(idx, db.sel and db.sel.d or "A")
        end
    end)

    -- Clue bar: shows the selected clue. Click it for the next clue.
    local bar = CreateFrame("Frame", nil, view, "BackdropTemplate")
    bar:SetSize(ns.BOARD_PX, CLUE_H)
    bar:SetPoint("TOP", 0, CLUE_TOP)
    ns.PanelBackdrop(bar, 0, 0, 0, 0.6)
    bar:EnableMouse(true)
    bar:SetScript("OnMouseUp", function()
        if db.sel and not db.done then NextWord(1) end
    end)

    ui.clue = bar:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    ui.clue:SetPoint("LEFT", 10, 0)
    ui.clue:SetWidth(ns.BOARD_PX - 10 - 80)
    ui.clue:SetJustifyH("LEFT")
    if ui.clue.SetMaxLines then ui.clue:SetMaxLines(2) end

    local reveal = CreateFrame("Button", nil, bar, "UIPanelButtonTemplate")
    reveal:SetSize(66, 22)
    reveal:SetPoint("RIGHT", -8, 0)
    reveal:SetText("Reveal")
    reveal:SetScript("OnClick", RevealWord)
    reveal:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_TOP")
        GameTooltip:SetText("Reveal word")
        GameTooltip:AddLine("Fill in the selected word. Revealed letters show in blue.", 1, 1, 1, true)
        GameTooltip:Show()
    end)
    reveal:SetScript("OnLeave", function() GameTooltip:Hide() end)

    ui.toast = ns.CreateToast(board)
    ui.toast:SetPoint("CENTER", board, "CENTER", 0, 0)
    ui.overlay = ns.CreateOverlay(board)
end
