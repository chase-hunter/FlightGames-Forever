-- Flight Games
-- A small arcade for flight paths. Pick Crossword, Word Search, Wordle or 2048
-- from the game selector. Opens when a flight starts and (optionally) closes
-- when you land. Every game is saved between flights.

local ADDON_NAME, ns = ...

ns.WIDTH    = 396
ns.BOARD_PX = 348
ns.REPO_URL = "github.com/chase-hunter/FlightGames-Forever"

local MENU_HEIGHT = 510
local CARD_H      = 72
local CARD_GAP    = 8

StaticPopupDialogs["FLIGHTGAMES_COPY_URL"] = {
    text = "Flight Games on GitHub\nPress Ctrl+C to copy:",
    button1 = OKAY or "Okay",
    hasEditBox = true,
    editBoxWidth = 280,
    OnShow = function(self)
        local eb = self.EditBox or self.editBox
        eb:SetText("https://" .. ns.REPO_URL)
        eb:SetFocus()
        eb:HighlightText()
    end,
    EditBoxOnEscapePressed = function(self) self:GetParent():Hide() end,
    EditBoxOnEnterPressed = function(self) self:GetParent():Hide() end,
    timeout = 0,
    whileDead = true,
    hideOnEscape = true,
}

local DEFAULTS = {
    autoOpen  = true,   -- open when a flight starts
    autoClose = true,   -- close when you land
}

ns.games = {}   -- key -> game table
ns.order = {}   -- keys in menu order (the .toc file order)

local DB
local frame
local views = {}
local activeKey = "menu"
local onTaxi = false
local flightStart
local destination

function ns.Print(msg)
    DEFAULT_CHAT_FRAME:AddMessage("|cffffd100Flight Games:|r " .. msg)
end

function ns.Sound(name)
    if SOUNDKIT and SOUNDKIT[name] then
        PlaySound(SOUNDKIT[name])
    end
end

function ns.Shuffle(t)
    for i = #t, 2, -1 do
        local j = math.random(i)
        t[i], t[j] = t[j], t[i]
    end
    return t
end

-- Each game file calls this once. A game provides:
--   key, name, desc, icon, height, newText, keys, defaults, extra (optional)
--   Build(view), OnShow(), NewGame(), Stat(), OnKey(key) (optional)
function ns.RegisterGame(game)
    ns.games[game.key] = game
    ns.order[#ns.order + 1] = game.key
end

--------------------------------------------------------------------------------
-- Shared UI helpers
--------------------------------------------------------------------------------

function ns.CreatePop(f, fromScale, duration)
    local ag = f:CreateAnimationGroup()
    local s = ag:CreateAnimation("Scale")
    if not s.SetScaleFrom then return nil end
    s:SetScaleFrom(fromScale, fromScale)
    s:SetScaleTo(1, 1)
    s:SetDuration(duration)
    s:SetOrigin("CENTER", 0, 0)
    return ag
end

function ns.PanelBackdrop(f, r, g, b, a)
    f:SetBackdrop({
        bgFile   = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        edgeSize = 12,
        insets   = { left = 3, right = 3, top = 3, bottom = 3 },
    })
    f:SetBackdropColor(r, g, b, a)
    f:SetBackdropBorderColor(0.6, 0.6, 0.6, 1)
end

-- A flat 1px border, for small squares where the tooltip border is too heavy.
function ns.ThinBackdrop(f)
    f:SetBackdrop({
        bgFile   = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Buttons\\WHITE8X8",
        edgeSize = 1,
    })
end

-- Big gold game name in the top left, with a small gray line under it.
function ns.CreateHeading(view, logoText, hintText)
    local logo = view:CreateFontString(nil, "OVERLAY", "GameFontNormalHuge")
    logo:SetPoint("TOPLEFT", 26, -40)
    logo:SetText(logoText)

    local hint = view:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    hint:SetPoint("TOPLEFT", logo, "BOTTOMLEFT", 0, -4)
    hint:SetText(hintText or "")
    return logo, hint
end

-- The first box sits in the top right corner; pass it as anchorTo for the next.
function ns.ScoreBox(parent, label, anchorTo, x)
    local box = CreateFrame("Frame", nil, parent, "BackdropTemplate")
    box:SetSize(92, 42)
    ns.PanelBackdrop(box, 0, 0, 0, 0.6)
    if anchorTo then
        box:SetPoint("RIGHT", anchorTo, "LEFT", x, 0)
    else
        box:SetPoint("TOPRIGHT", -24, -34)
    end
    local l = box:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    l:SetPoint("TOP", 0, -6)
    l:SetText(label)
    local v = box:CreateFontString(nil, "OVERLAY", "GameFontHighlightLarge")
    v:SetPoint("BOTTOM", 0, 6)
    return box, v
end

-- The dark, gold-bordered panel every game is played on.
function ns.CreateBoard(view, height)
    local board = CreateFrame("Frame", nil, view, "BackdropTemplate")
    board:SetSize(ns.BOARD_PX, height or ns.BOARD_PX)
    board:SetPoint("TOP", 0, -86)
    ns.PanelBackdrop(board, 0.05, 0.05, 0.05, 0.85)
    board:SetBackdropBorderColor(0.8, 0.7, 0.4, 1)
    return board
end

-- Floating green "+N" that rises out of a score box.
function ns.CreateGain(parent, anchor)
    local gain = parent:CreateFontString(nil, "OVERLAY", "GameFontGreenLarge")
    gain:SetPoint("CENTER", anchor, "CENTER", 0, 0)
    gain:Hide()
    local ag = gain:CreateAnimationGroup()
    local move = ag:CreateAnimation("Translation")
    move:SetOffset(0, 26)
    move:SetDuration(0.7)
    local fade = ag:CreateAnimation("Alpha")
    fade:SetFromAlpha(1)
    fade:SetToAlpha(0)
    fade:SetDuration(0.7)
    ag:SetScript("OnFinished", function() gain:Hide() end)

    function gain:Pop(text)
        self:SetText(text)
        ag:Stop()
        self:Show()
        ag:Play()
    end
    return gain
end

-- Win / game over screen that covers a board.
function ns.CreateOverlay(board)
    local overlay = CreateFrame("Frame", nil, board)
    overlay:SetAllPoints()
    overlay:SetFrameLevel(board:GetFrameLevel() + 10)
    overlay:EnableMouse(true)
    local shade = overlay:CreateTexture(nil, "BACKGROUND")
    shade:SetAllPoints()
    shade:SetColorTexture(0, 0, 0, 0.75)
    overlay.title = overlay:CreateFontString(nil, "OVERLAY", "GameFontNormalHuge")
    overlay.title:SetPoint("CENTER", 0, 34)
    overlay.sub = overlay:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    overlay.sub:SetPoint("CENTER", 0, 4)
    overlay.sub:SetWidth(board:GetWidth() - 40)
    overlay.button = CreateFrame("Button", nil, overlay, "UIPanelButtonTemplate")
    overlay.button:SetSize(120, 24)
    overlay.button:SetPoint("CENTER", 0, -32)
    overlay:Hide()

    function overlay:Present(title, r, g, b, sub, buttonText, onClick)
        self.title:SetText(title)
        self.title:SetTextColor(r, g, b)
        self.sub:SetText(sub or "")
        self.button:SetText(buttonText)
        self.button:SetScript("OnClick", onClick)
        self:Show()
    end
    return overlay
end

-- A short message box that fades out on its own ("Not enough letters").
function ns.CreateToast(parent)
    local t = CreateFrame("Frame", nil, parent, "BackdropTemplate")
    t:SetSize(200, 30)
    t:SetFrameLevel(parent:GetFrameLevel() + 20)
    ns.PanelBackdrop(t, 0, 0, 0, 0.9)
    t:SetBackdropBorderColor(1, 0.82, 0, 1)
    t.text = t:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    t.text:SetPoint("CENTER")
    t:Hide()

    local ag = t:CreateAnimationGroup()
    local fade = ag:CreateAnimation("Alpha")
    fade:SetFromAlpha(1)
    fade:SetToAlpha(0)
    fade:SetStartDelay(1.2)
    fade:SetDuration(0.4)
    ag:SetScript("OnFinished", function() t:Hide() end)

    function t:Flash(msg)
        self.text:SetText(msg)
        self:SetWidth(self.text:GetStringWidth() + 30)
        ag:Stop()
        self:Show()
        ag:Play()
    end
    return t
end

-- Row and column of the grid square under the mouse, or nil.
function ns.CellAtCursor(grid, pad, step, n)
    local left, top = grid:GetLeft(), grid:GetTop()
    if not left then return end
    local x, y = GetCursorPosition()
    local scale = grid:GetEffectiveScale()
    x, y = x / scale, y / scale
    local c = math.floor((x - left - pad) / step) + 1
    local r = math.floor((top - y - pad) / step) + 1
    if r < 1 or r > n or c < 1 or c > n then return end
    return r, c
end

local function FormatTime(sec)
    sec = math.floor(sec)
    return string.format("%d:%02d", math.floor(sec / 60), sec % 60)
end

--------------------------------------------------------------------------------
-- Game selector
--------------------------------------------------------------------------------

local function RefreshMenu()
    for key, card in pairs(views.menu.cards) do
        card.stat:SetText(ns.games[key]:Stat())
    end
end

local function StyleCard(card, hover)
    if hover then
        card:SetBackdropColor(0.16, 0.12, 0.02, 0.8)
        card:SetBackdropBorderColor(1, 0.82, 0, 1)
    else
        card:SetBackdropColor(0, 0, 0, 0.6)
        card:SetBackdropBorderColor(0.6, 0.6, 0.6, 1)
    end
end

local function ApplyView(key)
    activeKey = key
    for k, v in pairs(views) do v:SetShown(k == key) end

    local game = ns.games[key]
    if game then
        frame:SetHeight(game.height)
        frame.keys:SetText(game.keys)
        frame.backBtn:Show()
        frame.mainBtn:SetText(game.newText or "New Game")
        if game.extra then
            frame.extraBtn:SetText(game.extra.text)
            frame.extraBtn:Show()
        else
            frame.extraBtn:Hide()
        end
        game:OnShow()
    else
        frame:SetHeight(MENU_HEIGHT)
        frame.keys:SetText("Pick a game. Each one is saved between flights.")
        frame.backBtn:Hide()
        frame.extraBtn:Hide()
        frame.mainBtn:SetText(CLOSE or "Close")
        RefreshMenu()
    end
end
ns.ShowView = ApplyView

local function BuildMenu()
    local view = CreateFrame("Frame", nil, frame)
    view:SetAllPoints()
    views.menu = view

    local logo = view:CreateFontString(nil, "OVERLAY", "GameFontNormalHuge")
    logo:SetPoint("TOP", 0, -40)
    logo:SetText("Choose a Game")

    local hint = view:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    hint:SetPoint("TOP", logo, "BOTTOM", 0, -4)
    hint:SetText("Something to do while you fly")

    view.cards = {}
    for i, key in ipairs(ns.order) do
        local game = ns.games[key]
        local card = CreateFrame("Button", nil, view, "BackdropTemplate")
        card:SetSize(ns.BOARD_PX, CARD_H)
        card:SetPoint("TOP", 0, -86 - (i - 1) * (CARD_H + CARD_GAP))
        ns.PanelBackdrop(card, 0, 0, 0, 0.6)

        local icon = card:CreateTexture(nil, "ARTWORK")
        icon:SetSize(48, 48)
        icon:SetPoint("LEFT", 12, 0)
        icon:SetTexture(game.icon)
        icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)

        local iconBorder = CreateFrame("Frame", nil, card, "BackdropTemplate")
        iconBorder:SetPoint("TOPLEFT", icon, -1, 1)
        iconBorder:SetPoint("BOTTOMRIGHT", icon, 1, -1)
        iconBorder:SetBackdrop({ edgeFile = "Interface\\Buttons\\WHITE8X8", edgeSize = 1 })
        iconBorder:SetBackdropBorderColor(0, 0, 0, 1)

        local name = card:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
        name:SetPoint("TOPLEFT", icon, "TOPRIGHT", 12, -1)
        name:SetText(game.name)

        local desc = card:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        desc:SetPoint("TOPLEFT", name, "BOTTOMLEFT", 0, -4)
        desc:SetWidth(ns.BOARD_PX - 72 - 40)
        desc:SetJustifyH("LEFT")
        desc:SetWordWrap(false) -- one line only, so it never runs into the stat line
        desc:SetText(game.desc)

        card.stat = card:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
        card.stat:SetPoint("BOTTOMLEFT", icon, "BOTTOMRIGHT", 12, 1)
        card.stat:SetTextColor(0.5, 0.8, 0.5)

        local arrow = card:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
        arrow:SetPoint("RIGHT", -14, 0)
        arrow:SetText(">")

        card:SetScript("OnEnter", function(self) StyleCard(self, true) end)
        card:SetScript("OnLeave", function(self) StyleCard(self, false) end)
        card:SetScript("OnClick", function()
            ns.Sound("IG_MAINMENU_OPTION")
            ApplyView(key)
        end)
        view.cards[key] = card
    end
end

--------------------------------------------------------------------------------
-- Frame construction
--------------------------------------------------------------------------------

local function ResetPosition()
    frame:ClearAllPoints()
    frame:SetPoint("TOP", UIParent, "CENTER", 0, 290)
end

local function BuildFrame()
    local f = CreateFrame("Frame", "FlightGamesFrame", UIParent, "BackdropTemplate")
    frame = f
    ns.frame = f
    f:SetSize(ns.WIDTH, MENU_HEIGHT)
    f:SetFrameStrata("DIALOG")
    f:SetToplevel(true)
    f:SetClampedToScreen(true)
    f:SetMovable(true)
    f:EnableMouse(true)
    f:RegisterForDrag("LeftButton")
    f:SetScript("OnDragStart", f.StartMoving)
    f:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        -- Keep the top edge fixed, since each game has its own height.
        local left, top = self:GetLeft(), self:GetTop()
        self:ClearAllPoints()
        self:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", left, top)
    end)
    ResetPosition()
    f:Hide()

    -- Classic dialog box look
    f:SetBackdrop({
        bgFile   = "Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
        tile = true, tileSize = 32, edgeSize = 32,
        insets = { left = 11, right = 12, top = 12, bottom = 11 },
    })

    local header = f:CreateTexture(nil, "ARTWORK")
    header:SetTexture("Interface\\DialogFrame\\UI-DialogBox-Header")
    header:SetSize(256, 64)
    header:SetPoint("TOP", 0, 12)

    local title = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    title:SetPoint("TOP", header, "TOP", 0, -14)
    title:SetText("Flight Games")

    local close = CreateFrame("Button", nil, f, "UIPanelCloseButton")
    close:SetPoint("TOPRIGHT", -6, -6)

    -- One view per screen: the selector plus each game
    BuildMenu()
    for _, key in ipairs(ns.order) do
        local view = CreateFrame("Frame", nil, f)
        view:SetAllPoints()
        view:Hide()
        ns.games[key]:Build(view)
        views[key] = view
    end

    -- Flight status and control hints, pinned to the bottom
    local keys = f:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    keys:SetPoint("BOTTOM", 0, 66)
    keys:SetWidth(ns.BOARD_PX)
    f.keys = keys

    local status = f:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    status:SetPoint("BOTTOM", keys, "TOP", 0, 4)
    status:SetWidth(ns.BOARD_PX)

    -- Bottom buttons: Games | (game extra) | New Game / Close
    local backBtn = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
    backBtn:SetSize(110, 22)
    backBtn:SetPoint("BOTTOMLEFT", 24, 36)
    backBtn:SetText("Games")
    backBtn:SetScript("OnClick", function()
        ns.Sound("IG_MAINMENU_OPTION")
        ApplyView("menu")
    end)
    f.backBtn = backBtn

    local extraBtn = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
    extraBtn:SetSize(110, 22)
    extraBtn:SetPoint("BOTTOM", 0, 36)
    extraBtn:SetScript("OnClick", function()
        local game = ns.games[activeKey]
        if game and game.extra then game.extra.onClick(game) end
    end)
    f.extraBtn = extraBtn

    local mainBtn = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
    mainBtn:SetSize(110, 22)
    mainBtn:SetPoint("BOTTOMRIGHT", -24, 36)
    mainBtn:SetScript("OnClick", function()
        local game = ns.games[activeKey]
        if game then game:NewGame() else f:Hide() end
    end)
    f.mainBtn = mainBtn

    -- Branding footer (click to get a copyable link)
    local brand = CreateFrame("Button", nil, f)
    brand:SetPoint("BOTTOM", 0, 17)
    local brandText = brand:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    brandText:SetPoint("CENTER")
    brandText:SetText(ns.REPO_URL)
    brand:SetSize(brandText:GetStringWidth() + 8, 14)
    brand:SetScript("OnEnter", function(self)
        brandText:SetTextColor(1, 0.82, 0)
        GameTooltip:SetOwner(self, "ANCHOR_TOP")
        GameTooltip:SetText("Flight Games for WoW Forever")
        GameTooltip:AddLine("Click to copy the GitHub link.", 1, 1, 1)
        GameTooltip:Show()
    end)
    brand:SetScript("OnLeave", function()
        brandText:SetTextColor(0.5, 0.5, 0.5)
        GameTooltip:Hide()
    end)
    brand:SetScript("OnClick", function()
        StaticPopup_Show("FLIGHTGAMES_COPY_URL")
    end)

    -- Keyboard: game keys always work while the mouse is over the window;
    -- they also work anywhere while flying (you can't move anyway).
    -- Keys the game doesn't use pass through to the normal bindings.
    f:EnableKeyboard(true)
    f:SetScript("OnKeyDown", function(self, key)
        local game = ns.games[activeKey]
        local handled = false
        if game and game.OnKey and (onTaxi or self:IsMouseOver()) and not IsModifierKeyDown() then
            handled = game:OnKey(key) and true or false
        end
        if not InCombatLockdown() then
            self:SetPropagateKeyboardInput(not handled)
        end
    end)

    -- Flight timer
    local elapsed = 0
    f:SetScript("OnUpdate", function(self, dt)
        elapsed = elapsed + dt
        if elapsed < 0.25 then return end
        elapsed = 0
        if onTaxi and flightStart then
            local where = destination and ("Flying to |cffffd100" .. destination .. "|r") or "In flight"
            status:SetText(where .. "  -  " .. FormatTime(GetTime() - flightStart))
        else
            status:SetText("|cff808080Not flying. /fg to toggle this window.|r")
        end
    end)

    f:SetScript("OnShow", function() ns.Sound("IG_MAINMENU_OPEN") end)
    f:SetScript("OnHide", function() ns.Sound("IG_MAINMENU_CLOSE") end)

    tinsert(UISpecialFrames, "FlightGamesFrame") -- Escape closes it
end

--------------------------------------------------------------------------------
-- Flight detection
--------------------------------------------------------------------------------

local function OnFlightStart()
    flightStart = GetTime()
    if not DB.autoOpen or frame:IsShown() then return end
    ApplyView("menu")
    frame:Show()
end

local function OnFlightEnd()
    destination = nil
    flightStart = nil
    if DB.autoClose and frame:IsShown() then
        frame:Hide()
        ns.Print("Landed! Your games are saved for the next flight.")
    end
end

local function CheckTaxi()
    local now = UnitOnTaxi("player") and true or false
    if now == onTaxi then return end
    onTaxi = now
    if now then OnFlightStart() else OnFlightEnd() end
end

local function CheckTaxiSoon()
    CheckTaxi()
    C_Timer.After(0.5, CheckTaxi)
    C_Timer.After(1.5, CheckTaxi)
end

--------------------------------------------------------------------------------
-- Init and events
--------------------------------------------------------------------------------

local events = CreateFrame("Frame")
events:RegisterEvent("ADDON_LOADED")
events:RegisterEvent("PLAYER_ENTERING_WORLD")
events:RegisterEvent("PLAYER_CONTROL_LOST")
events:RegisterEvent("PLAYER_CONTROL_GAINED")
events:RegisterEvent("TAXIMAP_CLOSED")

events:SetScript("OnEvent", function(self, event, arg1)
    if event == "ADDON_LOADED" then
        if arg1 ~= ADDON_NAME then return end
        FlightGamesDB = FlightGamesDB or {}
        DB = FlightGamesDB
        for k, v in pairs(DEFAULTS) do
            if DB[k] == nil then DB[k] = v end
        end

        -- Each game keeps its own saved table: FlightGamesDB[game.key]
        for _, key in ipairs(ns.order) do
            local game = ns.games[key]
            DB[key] = DB[key] or {}
            for k, v in pairs(game.defaults or {}) do
                if DB[key][k] == nil then DB[key][k] = v end
            end
            game.db = DB[key]
        end

        BuildFrame()
        ApplyView("menu")

        -- Remember where we're flying to
        if TakeTaxiNode and TaxiNodeName then
            hooksecurefunc("TakeTaxiNode", function(index)
                local name = TaxiNodeName(index)
                destination = name and name:match("^([^,]+)") or name
            end)
        end

        -- Backup poll in case an event is missed
        C_Timer.NewTicker(1, CheckTaxi)
        self:UnregisterEvent("ADDON_LOADED")
    elseif DB then
        CheckTaxiSoon()
    end
end)

--------------------------------------------------------------------------------
-- Slash commands
--------------------------------------------------------------------------------

local ALIASES = {
    ["2048"]   = "2048",
    wordle     = "wordle",
    ws         = "wordsearch",
    search     = "wordsearch",
    wordsearch = "wordsearch",
    cw         = "crossword",
    crossword  = "crossword",
}

SLASH_FLIGHTGAMES1 = "/fg"
SLASH_FLIGHTGAMES2 = "/flightgames"
SlashCmdList.FLIGHTGAMES = function(msg)
    msg = strlower(strtrim(msg or ""))
    if msg == "" then
        frame:SetShown(not frame:IsShown())
    elseif msg == "menu" or msg == "games" then
        ApplyView("menu")
        frame:Show()
    elseif ALIASES[msg] then
        ApplyView(ALIASES[msg])
        frame:Show()
    elseif msg == "new" then
        local game = ns.games[activeKey]
        if game then
            game:NewGame()
            frame:Show()
        else
            ns.Print("Pick a game first, then /fg new starts it over.")
        end
    elseif msg == "auto" then
        DB.autoOpen = not DB.autoOpen
        ns.Print("Open on flight: " .. (DB.autoOpen and "|cff00ff00on|r" or "|cffff0000off|r"))
    elseif msg == "close" then
        DB.autoClose = not DB.autoClose
        ns.Print("Close on landing: " .. (DB.autoClose and "|cff00ff00on|r" or "|cffff0000off|r"))
    elseif msg == "reset" then
        ResetPosition()
        ns.Print("Window position reset.")
    else
        ns.Print("Commands:")
        ns.Print("  /fg - show or hide the window")
        ns.Print("  /fg menu - go to the game selector")
        ns.Print("  /fg crossword, wordsearch, wordle or 2048 - open that game")
        ns.Print("  /fg new - start the current game over")
        ns.Print("  /fg auto - toggle opening when a flight starts")
        ns.Print("  /fg close - toggle closing when you land")
        ns.Print("  /fg reset - reset the window position")
        ns.Print("  https://" .. ns.REPO_URL)
    end
end
