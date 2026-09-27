-- Wordle: guess the hidden five-letter word in six tries.
-- Green = right letter, right spot. Gold = in the word, wrong spot. Gray = not in the word.

local _, ns = ...

local ROWS, COLS = 6, 5
local TILE, GAP  = 42, 6
local ROW_W      = COLS * TILE + (COLS - 1) * GAP
local BOARD_H    = ROWS * TILE + (ROWS - 1) * GAP + 20
local KEY_W, KEY_H, KEY_GAP, WIDE_W = 30, 32, 4, 46
local KB_ROWS    = { "QWERTYUIOP", "ASDFGHJKL", "ZXCVBNM" }
local KB_TOP     = -86 - BOARD_H - 8

local COLORS = {
    correct = { 0.12, 1.00, 0.00 }, -- Uncommon green
    present = { 1.00, 0.82, 0.00 }, -- Gold
    absent  = { 0.40, 0.40, 0.40 },
}
local RANK = { absent = 1, present = 2, correct = 3 }

local Game = {
    key      = "wordle",
    name     = "Wordle",
    desc     = "Guess the hidden five-letter word in six tries.",
    icon     = "Interface\\Icons\\INV_Misc_Book_09",
    height   = -KB_TOP + 3 * KEY_H + 2 * KEY_GAP + 102,
    newText  = "New Word",
    keys     = "Type letters, Enter to guess, Backspace to erase",
    defaults = { played = 0, wins = 0, streak = 0, bestStreak = 0 },
}
ns.RegisterGame(Game)

local db
local tiles = {}      -- tiles[row][col]
local rows = {}       -- row frames (for the shake)
local keyButtons = {} -- letter -> key button
local ui = {}

--------------------------------------------------------------------------------
-- Game logic
--------------------------------------------------------------------------------

-- Two passes so repeated letters are scored like the real game: exact matches
-- first, then "present" only for as many copies as the answer has left.
local function Score(guess, answer)
    local res, left = {}, {}
    for i = 1, COLS do
        local a = answer:sub(i, i)
        if guess:sub(i, i) == a then
            res[i] = "correct"
        else
            left[a] = (left[a] or 0) + 1
        end
    end
    for i = 1, COLS do
        if not res[i] then
            local g = guess:sub(i, i)
            if (left[g] or 0) > 0 then
                res[i] = "present"
                left[g] = left[g] - 1
            else
                res[i] = "absent"
            end
        end
    end
    return res
end

--------------------------------------------------------------------------------
-- Rendering
--------------------------------------------------------------------------------

local function StyleTile(tile, letter, state)
    if state == "absent" then
        tile:SetBackdropColor(0.08, 0.08, 0.08, 0.95)
        tile:SetBackdropBorderColor(0.3, 0.3, 0.3, 1)
        tile.text:SetTextColor(0.55, 0.55, 0.55)
    elseif state then
        local col = COLORS[state]
        tile:SetBackdropColor(col[1] * 0.28, col[2] * 0.28, col[3] * 0.28, 0.95)
        tile:SetBackdropBorderColor(col[1], col[2], col[3], 1)
        tile.text:SetTextColor(col[1], col[2], col[3])
    elseif letter ~= "" then
        tile:SetBackdropColor(0, 0, 0, 0.55)
        tile:SetBackdropBorderColor(0.85, 0.85, 0.85, 1)
        tile.text:SetTextColor(1, 1, 1)
    else
        tile:SetBackdropColor(0, 0, 0, 0.55)
        tile:SetBackdropBorderColor(0.35, 0.35, 0.35, 0.9)
    end
    tile.text:SetText(letter)
end

local function StyleKey(key)
    local col = COLORS[key.state]
    if key.state == "absent" then
        key:SetBackdropColor(0.04, 0.04, 0.04, 0.9)
        key.text:SetTextColor(0.35, 0.35, 0.35)
    elseif col then
        key:SetBackdropColor(col[1] * 0.3, col[2] * 0.3, col[3] * 0.3, 0.95)
        key.text:SetTextColor(col[1], col[2], col[3])
    else
        key:SetBackdropColor(0.18, 0.18, 0.18, 0.95)
        key.text:SetTextColor(1, 1, 1)
    end
    if key.hover then
        key:SetBackdropBorderColor(1, 0.82, 0, 1)
    elseif col and key.state ~= "absent" then
        key:SetBackdropBorderColor(col[1], col[2], col[3], 1)
    else
        key:SetBackdropBorderColor(0.45, 0.45, 0.45, 1)
    end
end

local function Render()
    local states = {}
    for r = 1, ROWS do
        local guess = db.guesses[r]
        local res = guess and Score(guess, db.answer)
        for c = 1, COLS do
            if guess then
                local letter = guess:sub(c, c)
                StyleTile(tiles[r][c], letter, res[c])
                if not states[letter] or RANK[res[c]] > RANK[states[letter]] then
                    states[letter] = res[c]
                end
            elseif r == #db.guesses + 1 and not db.done then
                StyleTile(tiles[r][c], db.current:sub(c, c), nil)
            else
                StyleTile(tiles[r][c], "", nil)
            end
        end
    end
    for letter, key in pairs(keyButtons) do
        key.state = states[letter]
        StyleKey(key)
    end
    ui.streak:SetText(db.streak)
    ui.best:SetText(db.bestStreak)
end

--------------------------------------------------------------------------------
-- Game flow
--------------------------------------------------------------------------------

local function ShowResult()
    if db.won then
        ui.overlay:Present("Victory!", 1, 0.82, 0,
            string.format("You found |cffffffff%s|r in %d/%d.", db.answer, #db.guesses, ROWS),
            "New Word", function() Game:NewGame() end)
    else
        ui.overlay:Present("Defeat", 1, 0.2, 0.2,
            "The word was |cffffd100" .. db.answer .. "|r.",
            "New Word", function() Game:NewGame() end)
    end
end

local function Finish(won)
    db.done, db.won = true, won
    db.played = db.played + 1
    if won then
        db.wins = db.wins + 1
        db.streak = db.streak + 1
        if db.streak > db.bestStreak then db.bestStreak = db.streak end
        ns.Sound("LEVEL_UP")
    else
        db.streak = 0
        ns.Sound("IG_QUEST_FAILED")
    end
    Render()

    -- Let the last row pop in before covering the board.
    local answer = db.answer
    C_Timer.After(0.7, function()
        if db.done and db.answer == answer then ShowResult() end
    end)
end

local function Submit()
    if #db.current < COLS then
        rows[#db.guesses + 1].shake:Play()
        ui.toast:Flash("Not enough letters")
        return
    end

    local guess = db.current
    db.guesses[#db.guesses + 1] = guess
    db.current = ""
    local row = #db.guesses
    Render()
    for c = 1, COLS do
        C_Timer.After((c - 1) * 0.08, function()
            local tile = tiles[row][c]
            if tile.reveal then tile.reveal:Stop(); tile.reveal:Play() end
        end)
    end

    if guess == db.answer then
        Finish(true)
    elseif #db.guesses >= ROWS then
        Finish(false)
    end
end

local function Input(k)
    if db.done or ui.overlay:IsShown() then return end
    if k == "ENTER" then
        Submit()
    elseif k == "BACKSPACE" then
        if #db.current > 0 then
            db.current = db.current:sub(1, -2)
            Render()
        end
    elseif #db.current < COLS then
        db.current = db.current .. k
        Render()
        local tile = tiles[#db.guesses + 1][#db.current]
        if tile.bump then tile.bump:Stop(); tile.bump:Play() end
    end
end

function Game:NewGame()
    -- Walking away from a started word counts as a loss.
    if db.answer and not db.done and #db.guesses > 0 then
        db.played = db.played + 1
        db.streak = 0
    end

    local list, word = ns.WORDLE_WORDS
    repeat
        word = list[math.random(#list)]
    until word ~= db.answer or #list < 2

    db.answer = word
    db.guesses = {}
    db.current = ""
    db.done, db.won = false, false
    ui.overlay:Hide()
    Render()
end

function Game:OnShow()
    if not db.answer then
        self:NewGame()
        return
    end
    Render()
    if db.done then ShowResult() else ui.overlay:Hide() end
end

function Game:OnKey(key)
    if db.done then return false end
    if key:match("^%u$") then
        Input(key)
        return true
    end
    -- Enter and Backspace only count once you've started typing, so Enter
    -- still opens chat the rest of the time.
    if (key == "ENTER" or key == "BACKSPACE") and #db.current > 0 then
        Input(key)
        return true
    end
    return false
end

function Game:Stat()
    return string.format("Streak: %d  -  Won %d of %d", db.streak, db.wins, db.played)
end

--------------------------------------------------------------------------------
-- Frame construction
--------------------------------------------------------------------------------

local function CreateShake(f)
    local ag = f:CreateAnimationGroup()
    for i, dx in ipairs({ 8, -16, 16, -16, 8 }) do
        local t = ag:CreateAnimation("Translation")
        t:SetOffset(dx, 0)
        t:SetDuration(0.05)
        t:SetOrder(i)
    end
    return ag
end

local function CreateKey(view, label, value, width, x, y)
    local key = CreateFrame("Button", nil, view, "BackdropTemplate")
    key:SetSize(width, KEY_H)
    key:SetPoint("TOPLEFT", view, "TOP", x, y)
    ns.ThinBackdrop(key)
    key.text = key:CreateFontString(nil, "OVERLAY", #label > 1 and "GameFontHighlightSmall" or "GameFontHighlight")
    key.text:SetPoint("CENTER", 0, 0)
    key.text:SetText(label)
    key:SetScript("OnEnter", function(self) self.hover = true; StyleKey(self) end)
    key:SetScript("OnLeave", function(self) self.hover = false; StyleKey(self) end)
    key:SetScript("OnClick", function() Input(value) end)
    StyleKey(key)
    return key
end

function Game:Build(view)
    db = self.db

    ns.CreateHeading(view, "Wordle", "Guess the word in six tries")
    local bestBox, bestText = ns.ScoreBox(view, "BEST STREAK")
    local _, streakText = ns.ScoreBox(view, "STREAK", bestBox, -6)
    ui.best, ui.streak = bestText, streakText

    local board = ns.CreateBoard(view, BOARD_H)
    for r = 1, ROWS do
        local row = CreateFrame("Frame", nil, board)
        row:SetSize(ROW_W, TILE)
        row:SetPoint("TOP", 0, -(10 + (r - 1) * (TILE + GAP)))
        row.shake = CreateShake(row)
        rows[r] = row
        tiles[r] = {}
        for c = 1, COLS do
            local tile = CreateFrame("Frame", nil, row, "BackdropTemplate")
            tile:SetSize(TILE, TILE)
            tile:SetPoint("LEFT", (c - 1) * (TILE + GAP), 0)
            ns.PanelBackdrop(tile, 0, 0, 0, 0.55)
            tile.text = tile:CreateFontString(nil, "OVERLAY")
            tile.text:SetFont(STANDARD_TEXT_FONT, 24, "OUTLINE")
            tile.text:SetPoint("CENTER", 0, 0)
            tile.bump = ns.CreatePop(tile, 1.15, 0.08)
            tile.reveal = ns.CreatePop(tile, 0.3, 0.15)
            tiles[r][c] = tile
        end
    end

    -- On-screen keyboard
    for i, letters in ipairs(KB_ROWS) do
        local keys = {}
        if i == 3 then keys[1] = { "ENTER", "ENTER", WIDE_W } end
        for j = 1, #letters do
            local l = letters:sub(j, j)
            keys[#keys + 1] = { l, l, KEY_W }
        end
        if i == 3 then keys[#keys + 1] = { "DEL", "BACKSPACE", WIDE_W } end

        local total = -KEY_GAP
        for _, k in ipairs(keys) do total = total + k[3] + KEY_GAP end
        local x = -total / 2
        local y = KB_TOP - (i - 1) * (KEY_H + KEY_GAP)
        for _, k in ipairs(keys) do
            local key = CreateKey(view, k[1], k[2], k[3], x, y)
            if #k[2] == 1 then keyButtons[k[2]] = key end
            x = x + k[3] + KEY_GAP
        end
    end

    ui.toast = ns.CreateToast(board)
    ui.toast:SetPoint("CENTER", board, "CENTER", 0, 0)
    ui.overlay = ns.CreateOverlay(board)
end
