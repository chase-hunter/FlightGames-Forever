-- 2048: slide and merge tiles on a 4x4 board. Same rules and look as Flight 2048.

local _, ns = ...

local SIZE     = 4
local TILE     = 68
local GAP      = 8
local BOARD_PX = SIZE * TILE + (SIZE + 1) * GAP
local WIN_TILE = 2048

-- Tiles use item quality colors: 2 is Poor, 4 is Common, 8 is Uncommon...
local TILE_COLORS = {
    [2]    = { 0.62, 0.62, 0.62 }, -- Poor
    [4]    = { 1.00, 1.00, 1.00 }, -- Common
    [8]    = { 0.12, 1.00, 0.00 }, -- Uncommon
    [16]   = { 0.00, 0.44, 0.87 }, -- Rare
    [32]   = { 0.64, 0.21, 0.93 }, -- Epic
    [64]   = { 1.00, 0.50, 0.00 }, -- Legendary
    [128]  = { 0.90, 0.80, 0.50 }, -- Artifact
    [256]  = { 0.00, 0.80, 1.00 }, -- Heirloom
    [512]  = { 1.00, 0.30, 0.30 },
    [1024] = { 1.00, 0.82, 0.00 },
    [2048] = { 1.00, 0.95, 0.60 },
}
local TOP_COLOR = { 1.00, 0.95, 0.60 }

local KEYMAP = {
    UP = "UP", W = "UP",
    DOWN = "DOWN", S = "DOWN",
    LEFT = "LEFT", A = "LEFT",
    RIGHT = "RIGHT", D = "RIGHT",
}

local Game = {
    key      = "2048",
    name     = "2048",
    desc     = "Slide the tiles and merge them to reach 2048.",
    icon     = "Interface\\Icons\\Ability_Mount_Gryphon_01",
    height   = 536,
    newText  = "New Game",
    keys     = "Arrow keys, WASD, or drag on the board to move tiles",
    defaults = { best = 0, score = 0, won = false },
}
ns.RegisterGame(Game)

local db
local cells = {}
local ui = {}

--------------------------------------------------------------------------------
-- Game logic
--------------------------------------------------------------------------------

local function NewBoard()
    local b = {}
    for r = 1, SIZE do
        b[r] = {}
        for c = 1, SIZE do b[r][c] = 0 end
    end
    return b
end

local function SpawnTile(b)
    local empty = {}
    for r = 1, SIZE do
        for c = 1, SIZE do
            if b[r][c] == 0 then empty[#empty + 1] = { r, c } end
        end
    end
    if #empty == 0 then return nil end
    local p = empty[math.random(#empty)]
    b[p[1]][p[2]] = (math.random() < 0.9) and 2 or 4
    return p
end

local function CanMove(b)
    for r = 1, SIZE do
        for c = 1, SIZE do
            local v = b[r][c]
            if v == 0 then return true end
            if c < SIZE and b[r][c + 1] == v then return true end
            if r < SIZE and b[r + 1][c] == v then return true end
        end
    end
    return false
end

local function HasTile(b, value)
    for r = 1, SIZE do
        for c = 1, SIZE do
            if b[r][c] >= value then return true end
        end
    end
    return false
end

-- Coordinates of line i, ordered from the edge the tiles slide toward.
local function LineCoords(dir, i)
    local t = {}
    for k = 1, SIZE do
        if dir == "LEFT" then
            t[k] = { i, k }
        elseif dir == "RIGHT" then
            t[k] = { i, SIZE + 1 - k }
        elseif dir == "UP" then
            t[k] = { k, i }
        else -- DOWN
            t[k] = { SIZE + 1 - k, i }
        end
    end
    return t
end

-- Slides and merges the board in place. Returns moved, points gained, merged cells.
local function Slide(b, dir)
    local moved, gained, merged = false, 0, {}
    for i = 1, SIZE do
        local coords = LineCoords(dir, i)
        local vals = {}
        for _, p in ipairs(coords) do
            local v = b[p[1]][p[2]]
            if v ~= 0 then vals[#vals + 1] = v end
        end

        local out, mergedAt, j = {}, {}, 1
        while j <= #vals do
            if vals[j + 1] and vals[j] == vals[j + 1] then
                out[#out + 1] = vals[j] * 2
                gained = gained + vals[j] * 2
                mergedAt[#out] = true
                j = j + 2
            else
                out[#out + 1] = vals[j]
                j = j + 1
            end
        end

        for k, p in ipairs(coords) do
            local nv = out[k] or 0
            if b[p[1]][p[2]] ~= nv then moved = true end
            b[p[1]][p[2]] = nv
            if mergedAt[k] then merged[#merged + 1] = p end
        end
    end
    return moved, gained, merged
end

--------------------------------------------------------------------------------
-- Rendering
--------------------------------------------------------------------------------

local function UpdateCell(cell, value)
    if value == 0 then
        cell:SetBackdropColor(0, 0, 0, 0.55)
        cell:SetBackdropBorderColor(0.35, 0.35, 0.35, 0.9)
        cell.text:SetText("")
        return
    end

    local col = TILE_COLORS[value] or TOP_COLOR
    cell:SetBackdropColor(col[1] * 0.28, col[2] * 0.28, col[3] * 0.28, 0.95)
    cell:SetBackdropBorderColor(col[1], col[2], col[3], 1)

    local size = (value < 100 and 30) or (value < 1000 and 26) or (value < 10000 and 21) or 17
    cell.text:SetFont(STANDARD_TEXT_FONT, size, "OUTLINE")
    cell.text:SetTextColor(col[1], col[2], col[3])
    cell.text:SetText(value)
end

local function Render()
    for r = 1, SIZE do
        for c = 1, SIZE do
            UpdateCell(cells[r][c], db.board[r][c])
        end
    end
    ui.score:SetText(db.score)
    ui.best:SetText(db.best)
end

--------------------------------------------------------------------------------
-- Game flow
--------------------------------------------------------------------------------

local function ShowGameOver()
    ui.overlay:Present("Game Over", 1, 0.2, 0.2, "Score: " .. db.score, "Try Again",
        function() Game:NewGame() end)
end

local function CheckEndStates()
    if not db.won and HasTile(db.board, WIN_TILE) then
        db.won = true
        ns.Sound("LEVEL_UP")
        ui.overlay:Present("You Win!", 1, 0.82, 0, "Score: " .. db.score, "Keep Playing",
            function() ui.overlay:Hide() end)
    elseif not CanMove(db.board) then
        ns.Sound("IG_QUEST_FAILED")
        ShowGameOver()
    end
end

local function DoMove(dir)
    if ui.overlay:IsShown() then return end

    local moved, gained, merged = Slide(db.board, dir)
    if not moved then return end

    local spawned = SpawnTile(db.board)
    db.score = db.score + gained
    if db.score > db.best then db.best = db.score end
    Render()

    for _, p in ipairs(merged) do
        local cell = cells[p[1]][p[2]]
        if cell.merge then cell.merge:Stop(); cell.merge:Play() end
    end
    if spawned then
        local cell = cells[spawned[1]][spawned[2]]
        if cell.spawn then cell.spawn:Stop(); cell.spawn:Play() end
    end
    if gained > 0 then ui.gain:Pop("+" .. gained) end

    CheckEndStates()
end

function Game:NewGame()
    db.board = NewBoard()
    db.score = 0
    db.won = false
    SpawnTile(db.board)
    SpawnTile(db.board)
    ui.overlay:Hide()
    Render()
end

function Game:OnShow()
    if not db.board then
        self:NewGame()
        return
    end
    Render()
    if not CanMove(db.board) then ShowGameOver() end
end

function Game:OnKey(key)
    local dir = KEYMAP[key]
    if not dir then return false end
    DoMove(dir)
    return true
end

function Game:Stat()
    if db.board and db.score > 0 then
        return string.format("Best: %d  -  Current game: %d", db.best, db.score)
    end
    return "Best: " .. db.best
end

--------------------------------------------------------------------------------
-- Frame construction
--------------------------------------------------------------------------------

function Game:Build(view)
    db = self.db

    ns.CreateHeading(view, "2048", "Join the tiles!")
    local bestBox, bestText = ns.ScoreBox(view, "BEST")
    local scoreBox, scoreText = ns.ScoreBox(view, "SCORE", bestBox, -6)
    ui.best, ui.score = bestText, scoreText
    ui.gain = ns.CreateGain(view, scoreBox)

    local board = ns.CreateBoard(view, BOARD_PX)
    for r = 1, SIZE do
        cells[r] = {}
        for c = 1, SIZE do
            local cell = CreateFrame("Frame", nil, board, "BackdropTemplate")
            cell:SetSize(TILE, TILE)
            cell:SetPoint("TOPLEFT", GAP + (c - 1) * (TILE + GAP), -(GAP + (r - 1) * (TILE + GAP)))
            ns.PanelBackdrop(cell, 0, 0, 0, 0.55)
            cell.text = cell:CreateFontString(nil, "OVERLAY")
            cell.text:SetFont(STANDARD_TEXT_FONT, 30, "OUTLINE")
            cell.text:SetPoint("CENTER", 0, 0)
            cell.spawn = ns.CreatePop(cell, 0.2, 0.12)
            cell.merge = ns.CreatePop(cell, 1.2, 0.15)
            cells[r][c] = cell
        end
    end

    -- Mouse swipe on the board
    board:EnableMouse(true)
    board:SetScript("OnMouseDown", function(self)
        self.dragX, self.dragY = GetCursorPosition()
    end)
    board:SetScript("OnMouseUp", function(self)
        if not self.dragX then return end
        local x, y = GetCursorPosition()
        local scale = self:GetEffectiveScale()
        local dx, dy = (x - self.dragX) / scale, (y - self.dragY) / scale
        self.dragX, self.dragY = nil, nil
        if math.max(math.abs(dx), math.abs(dy)) < 20 then return end
        if math.abs(dx) > math.abs(dy) then
            DoMove(dx > 0 and "RIGHT" or "LEFT")
        else
            DoMove(dy > 0 and "UP" or "DOWN")
        end
    end)

    ui.overlay = ns.CreateOverlay(board)
end
