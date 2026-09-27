-- Word lists for the word games. All answers are uppercase letters only.

local _, ns = ...

--------------------------------------------------------------------------------
-- Wordle answers: common five-letter words (plus a few with a Warcraft feel).
--------------------------------------------------------------------------------

ns.WORDLE_WORDS = {
    "ABOUT", "ABOVE", "ACTOR", "ACUTE", "ADMIT", "ADOPT", "ADULT", "AFTER", "AGAIN", "AGENT",
    "AGREE", "AHEAD", "ALARM", "ALBUM", "ALERT", "ALIKE", "ALIVE", "ALLOW", "ALONE", "ALONG",
    "ALTER", "AMBER", "AMONG", "ANGEL", "ANGER", "ANGLE", "ANGRY", "APART", "APPLE", "APPLY",
    "ARENA", "ARGUE", "ARISE", "ARMOR", "ARROW", "ASIDE", "AWARD", "AWARE", "BADGE", "BAKER",
    "BASIC", "BEACH", "BEAST", "BEGIN", "BEING", "BELOW", "BENCH", "BERRY", "BIRTH", "BLACK",
    "BLADE", "BLAME", "BLANK", "BLAST", "BLAZE", "BLEND", "BLESS", "BLIND", "BLOCK", "BLOOD",
    "BLOOM", "BOARD", "BOAST", "BONUS", "BOOST", "BOOTH", "BRAIN", "BRAND", "BRAVE", "BREAD",
    "BREAK", "BRICK", "BRIDE", "BRIEF", "BRING", "BROAD", "BROOK", "BROWN", "BRUSH", "BUILD",
    "BUNCH", "BURST", "CABIN", "CABLE", "CANDY", "CANOE", "CARGO", "CARRY", "CATCH", "CAUSE",
    "CHAIN", "CHAIR", "CHALK", "CHARM", "CHART", "CHASE", "CHEAP", "CHECK", "CHEST", "CHIEF",
    "CHILD", "CHILL", "CLAIM", "CLASS", "CLEAN", "CLEAR", "CLIMB", "CLOCK", "CLOSE", "CLOUD",
    "COAST", "COUNT", "COURT", "COVER", "CRAFT", "CRANE", "CRASH", "CREAM", "CREEK", "CREST",
    "CROWD", "CROWN", "CRUSH", "CURVE", "CYCLE", "DAILY", "DANCE", "DEPTH", "DIRTY", "DOUBT",
    "DOZEN", "DRAFT", "DRAIN", "DRAMA", "DREAM", "DRESS", "DRIFT", "DRINK", "DRIVE", "DWARF",
    "EAGER", "EAGLE", "EARLY", "EARTH", "EMBER", "EMPTY", "ENEMY", "ENJOY", "ENTER", "ENTRY",
    "EQUAL", "ERROR", "EVENT", "EVERY", "EXACT", "EXTRA", "FAINT", "FAITH", "FALSE", "FEAST",
    "FENCE", "FIELD", "FIERY", "FIGHT", "FINAL", "FLAME", "FLASH", "FLEET", "FLOAT", "FLOCK",
    "FLOOR", "FLOUR", "FOCUS", "FORCE", "FORGE", "FORTH", "FOUND", "FRAME", "FRESH", "FRONT",
    "FROST", "FRUIT", "GHOST", "GIANT", "GLASS", "GLOBE", "GLORY", "GLOVE", "GNOME", "GRACE",
    "GRADE", "GRAIN", "GRAND", "GRANT", "GRAPE", "GRASS", "GREAT", "GREEN", "GRIEF", "GROUP",
    "GUARD", "GUESS", "GUEST", "GUIDE", "GUILD", "HABIT", "HAPPY", "HASTE", "HEART", "HEAVY",
    "HONEY", "HORSE", "HOTEL", "HOUSE", "HUMAN", "HUMOR", "IDEAL", "IMAGE", "INNER", "IVORY",
    "JEWEL", "JOINT", "JUDGE", "JUICE", "KNIFE", "KNOCK", "LANCE", "LARGE", "LAUGH", "LAYER",
    "LEARN", "LEMON", "LEVEL", "LIGHT", "LIMIT", "LOYAL", "LUCKY", "LUNAR", "MAGIC", "MAJOR",
    "MANOR", "MAPLE", "MARCH", "MATCH", "MAYOR", "MEDAL", "MERCY", "MERIT", "METAL", "MIGHT",
    "MINOR", "MIRTH", "MODEL", "MONEY", "MONTH", "MORAL", "MOTOR", "MOUNT", "MOUSE", "MOUTH",
    "MUSIC", "NERVE", "NIGHT", "NOBLE", "NOISE", "NORTH", "NOVEL", "NURSE", "OCEAN", "OFFER",
    "OFTEN", "OLIVE", "ONION", "OPERA", "ORBIT", "ORDER", "OTHER", "OUTER", "OWNER", "PAINT",
    "PANEL", "PAPER", "PARTY", "PEACE", "PEARL", "PENNY", "PHASE", "PIANO", "PIECE", "PILOT",
    "PITCH", "PLACE", "PLAIN", "PLANE", "PLANT", "PLATE", "POINT", "POUND", "POWER", "PRESS",
    "PRICE", "PRIDE", "PRIME", "PRINT", "PRIZE", "PROOF", "PROUD", "QUEEN", "QUEST", "QUICK",
    "QUIET", "QUOTE", "RADIO", "RAISE", "RANGE", "RAPID", "RAVEN", "REACH", "READY", "REALM",
    "RELIC", "RIDER", "RIDGE", "RIGHT", "RIVAL", "RIVER", "ROBIN", "ROCKY", "ROUGH", "ROUND",
    "ROUTE", "ROYAL", "RURAL", "SAINT", "SALAD", "SAUCE", "SCALE", "SCARF", "SCENE", "SCOUT",
    "SENSE", "SERVE", "SEVEN", "SHADE", "SHAKE", "SHAPE", "SHARE", "SHARP", "SHEEP", "SHELF",
    "SHELL", "SHIFT", "SHINE", "SHIRT", "SHOCK", "SHORE", "SHORT", "SIGHT", "SKILL", "SLEEP",
    "SLICE", "SLIDE", "SMALL", "SMART", "SMILE", "SMOKE", "SNAKE", "SOLID", "SOLVE", "SOUND",
    "SOUTH", "SPACE", "SPARE", "SPARK", "SPEAK", "SPEAR", "SPEED", "SPELL", "SPEND", "SPICE",
    "SPINE", "SPOON", "SPORT", "STACK", "STAFF", "STAGE", "STAIR", "STAKE", "STAND", "START",
    "STEAM", "STEEL", "STICK", "STILL", "STONE", "STORM", "STORY", "STOVE", "STRAW", "SUGAR",
    "SUNNY", "SWEET", "SWIFT", "SWORD", "TABLE", "TASTE", "TEACH", "THEME", "THICK", "THIEF",
    "THING", "THINK", "THORN", "THREE", "THROW", "THUMB", "TIGER", "TIMER", "TOAST", "TODAY",
    "TOKEN", "TOOTH", "TORCH", "TOTAL", "TOTEM", "TOUCH", "TOWER", "TRACK", "TRADE", "TRAIL",
    "TRAIN", "TREAT", "TREND", "TRIAL", "TRIBE", "TRICK", "TROLL", "TRUCK", "TRULY", "TRUST",
    "TRUTH", "TWICE", "UNCLE", "UNDER", "UNION", "UNITY", "UPPER", "URBAN", "USUAL", "VALID",
    "VALUE", "VAULT", "VIDEO", "VIGOR", "VISIT", "VITAL", "VIVID", "VOICE", "WAGON", "WATCH",
    "WATER", "WHALE", "WHEAT", "WHEEL", "WHITE", "WHOLE", "WITCH", "WOMAN", "WORLD", "WORRY",
    "WORTH", "WOUND", "WRIST", "WRITE", "YIELD", "YOUNG", "YOUTH", "ZEBRA",
}

--------------------------------------------------------------------------------
-- Word Search themes. Each puzzle picks one theme and eight of its words.
-- Words must be 11 letters or fewer.
--------------------------------------------------------------------------------

ns.WORDSEARCH_THEMES = {
    { name = "Classes", words = {
        "WARRIOR", "PALADIN", "HUNTER", "ROGUE", "PRIEST", "SHAMAN", "MAGE", "WARLOCK", "DRUID",
    } },
    { name = "Races", words = {
        "HUMAN", "DWARF", "GNOME", "NIGHTELF", "ORC", "UNDEAD", "TAUREN", "TROLL", "DRAENEI",
        "BLOODELF", "GOBLIN", "WORGEN",
    } },
    { name = "Cities and Towns", words = {
        "STORMWIND", "IRONFORGE", "DARNASSUS", "ORGRIMMAR", "UNDERCITY", "EXODAR", "SILVERMOON",
        "GADGETZAN", "BOOTYBAY", "DARKSHIRE", "GOLDSHIRE", "RATCHET", "SOUTHSHORE",
    } },
    { name = "Zones", words = {
        "ELWYNN", "WESTFALL", "DUSKWOOD", "REDRIDGE", "DARKSHORE", "ASHENVALE", "TANARIS",
        "FERALAS", "SILITHUS", "FELWOOD", "DUROTAR", "MULGORE", "BARRENS", "BADLANDS", "WETLANDS",
    } },
    { name = "Dungeons and Raids", words = {
        "DEADMINES", "STOCKADES", "SCHOLOMANCE", "STRATHOLME", "MARAUDON", "ULDAMAN", "GNOMEREGAN",
        "ZULFARRAK", "RAZORFEN", "NAXXRAMAS", "MOLTENCORE", "ONYXIA", "KARAZHAN",
    } },
    { name = "Creatures", words = {
        "MURLOC", "GNOLL", "KOBOLD", "HARPY", "CENTAUR", "DRAGON", "TROGG", "SATYR", "OGRE",
        "NAGA", "QUILBOAR", "FURBOLG", "BASILISK", "GHOUL", "WENDIGO",
    } },
    { name = "Professions", words = {
        "ALCHEMY", "MINING", "SKINNING", "HERBALISM", "ENCHANTING", "TAILORING", "FISHING",
        "COOKING", "ENGINEERING", "FIRSTAID", "ARCHAEOLOGY", "INSCRIPTION",
    } },
    { name = "Heroes and Villains", words = {
        "THRALL", "JAINA", "ARTHAS", "SYLVANAS", "ILLIDAN", "TYRANDE", "ANDUIN", "VARIAN",
        "CAIRNE", "GARROSH", "RAGNAROS", "DEATHWING", "MEDIVH", "KHADGAR", "HOGGER", "VANCLEEF",
    } },
}

--------------------------------------------------------------------------------
-- Crossword clue bank: { ANSWER, clue }. Answers are 3 to 11 letters.
--------------------------------------------------------------------------------

ns.CROSSWORD_CLUES = {
    -- People
    { "THRALL",      "Orc Warchief who founded Orgrimmar" },
    { "JAINA",       "Proudmoore sorceress who founded Theramore" },
    { "ARTHAS",      "Prince of Lordaeron who took up Frostmourne" },
    { "SYLVANAS",    "Banshee Queen of the Forsaken" },
    { "ILLIDAN",     "The Betrayer, twin brother of Malfurion" },
    { "MALFURION",   "Archdruid Stormrage" },
    { "TYRANDE",     "High Priestess of Elune" },
    { "ANDUIN",      "Son of King Varian Wrynn" },
    { "VARIAN",      "King of Stormwind, once a gladiator called Lo'Gosh" },
    { "CAIRNE",      "Bloodhoof chieftain of Thunder Bluff" },
    { "VOLJIN",      "Chieftain of the Darkspear trolls" },
    { "GARROSH",     "Hellscream who followed Thrall as Warchief" },
    { "RAGNAROS",    "The Firelord of the Molten Core" },
    { "ONYXIA",      "Black dragon broodmother of Dustwallow Marsh" },
    { "NEFARIAN",    "Son of Deathwing, master of Blackwing Lair" },
    { "DEATHWING",   "The Destroyer, Aspect of the black dragonflight" },
    { "ALEXSTRASZA", "The Life-Binder, queen of the red dragons" },
    { "HOGGER",      "Gnoll chieftain feared across Elwynn Forest" },
    { "VANCLEEF",    "Edwin, leader of the Defias Brotherhood" },
    { "KELTHUZAD",   "Lich who rules Naxxramas" },
    { "MEDIVH",      "The Last Guardian of Tirisfal" },
    { "KHADGAR",     "Archmage who was Medivh's apprentice" },
    { "GULDAN",      "Orc warlock who led the Shadow Council" },

    -- Places
    { "STORMWIND",   "Human capital in Elwynn Forest" },
    { "ORGRIMMAR",   "Orc capital in Durotar" },
    { "IRONFORGE",   "Dwarven capital carved into a mountain" },
    { "DARNASSUS",   "Night elf capital atop Teldrassil" },
    { "UNDERCITY",   "Forsaken capital under Lordaeron's ruins" },
    { "SILVERMOON",  "Blood elf capital in Eversong Woods" },
    { "EXODAR",      "Draenei capital, a crashed ship" },
    { "GADGETZAN",   "Goblin town in the Tanaris desert" },
    { "BOOTYBAY",    "Pirate port at the tip of Stranglethorn" },
    { "DUROTAR",     "Orc homeland named for Thrall's father" },
    { "TANARIS",     "Desert zone that hides the Caverns of Time" },
    { "WESTFALL",    "Farmland zone overrun by the Defias" },
    { "DUSKWOOD",    "Gloomy forest zone around Darkshire" },
    { "MULGORE",     "Grassland home of the tauren" },
    { "AZEROTH",     "The world of Warcraft" },
    { "OUTLAND",     "The shattered remains of Draenor" },
    { "NORTHREND",   "Frozen continent of the Lich King" },
    { "KALIMDOR",    "Western continent, home of Orgrimmar" },
    { "DRAENOR",     "The orcs' homeworld" },
    { "KARAZHAN",    "Medivh's tower in Deadwind Pass" },
    { "DALARAN",     "City of the Kirin Tor" },
    { "LORDAERON",   "Fallen human kingdom, now home of the Forsaken" },
    { "TELDRASSIL",  "World tree off the coast of Darkshore" },
    { "BLACKROCK",   "Mountain home of the Dark Iron dwarves" },

    -- Dungeons, raids and battlegrounds
    { "DEADMINES",   "Defias hideout beneath Moonbrook" },
    { "STOCKADES",   "Stormwind's prison dungeon" },
    { "GNOMEREGAN",  "Irradiated gnome city dungeon" },
    { "SCHOLOMANCE", "School of necromancy in Caer Darrow" },
    { "STRATHOLME",  "Plagued city that Arthas purged" },
    { "MOLTENCORE",  "Raid deep in Blackrock where Ragnaros waits" },
    { "NAXXRAMAS",   "Floating necropolis raid" },
    { "WARSONG",     "Gulch battleground of capture-the-flag" },
    { "ALTERAC",     "Valley battleground of forty against forty" },
    { "ARATHI",      "Basin battleground with five resource nodes" },

    -- Classes and races
    { "PALADIN",     "Holy warrior who wields the Light" },
    { "WARLOCK",     "Class that summons demons" },
    { "ROGUE",       "Stealthy class known for Backstab" },
    { "DRUID",       "Shapeshifting class of nature" },
    { "SHAMAN",      "Class that calls the elements with totems" },
    { "HUNTER",      "Class with a bow and an animal companion" },
    { "PRIEST",      "Class of holy and shadow magic" },
    { "MAGE",        "Class that conjures food and water" },
    { "WARRIOR",     "Class that fights with rage" },
    { "GNOME",       "Tinkerers driven out of Gnomeregan" },
    { "TAUREN",      "Bovine people of Mulgore" },
    { "DRAENEI",     "Exiled eredar who crashed on Azeroth" },
    { "FORSAKEN",    "Undead who broke free of the Lich King" },
    { "TROLL",       "Race of the Darkspear tribe" },
    { "DWARF",       "Race of Ironforge" },
    { "GOBLIN",      "Greedy engineers of the Steamwheedle Cartel" },
    { "WORGEN",      "Cursed wolf-folk of Gilneas" },
    { "PANDAREN",    "Bear-like race of brewmasters" },

    -- Creatures
    { "MURLOC",      "Gurgling fish-folk of the coast" },
    { "GNOLL",       "Hyena-like humanoid, like Hogger" },
    { "KOBOLD",      "Candle-wearing miner: \"You no take candle!\"" },
    { "CENTAUR",     "Horse-bodied raiders of the Barrens" },
    { "SCOURGE",     "Undead army of the Lich King" },
    { "LEGION",      "The Burning ___, an army of demons" },
    { "NAARU",       "Beings of Holy Light, like A'dal" },
    { "ELUNE",       "Moon goddess of the night elves" },

    -- Items and gear
    { "HEARTHSTONE", "Stone that takes you back to your inn" },
    { "FROSTMOURNE", "The Lich King's runeblade" },
    { "ASHBRINGER",  "Legendary blade of the Mograine family" },
    { "THUNDERFURY", "Blessed Blade of the Windseeker" },
    { "ARCANITE",    "Metal alchemists transmute from thorium" },
    { "THORIUM",     "Ore mined in the toughest Classic zones" },
    { "COPPER",      "The first ore a new miner digs up" },
    { "MITHRIL",     "Ore between iron and thorium" },

    -- Travel
    { "GRYPHON",     "Alliance flight path mount" },
    { "WYVERN",      "Horde flight path mount" },
    { "ZEPPELIN",    "Goblin airship between Orgrimmar and Undercity" },
    { "FLIGHT",      "What you're on right now, probably" },

    -- Playing the game
    { "HORDE",       "Faction of orcs, trolls and tauren" },
    { "ALLIANCE",    "Faction of humans, dwarves and night elves" },
    { "MANA",        "Blue resource that powers spells" },
    { "AGGRO",       "Threat that a tank must hold" },
    { "TANK",        "Role that keeps the boss's attention" },
    { "HEALER",      "Role that keeps the party alive" },
    { "RAID",        "Group of up to forty adventurers" },
    { "GUILD",       "Player group with its own tabard" },
    { "QUEST",       "Task from an NPC with a yellow \"!\"" },
    { "LOOT",        "What a slain monster drops" },
    { "EPIC",        "Purple item quality" },
    { "INN",         "Where you set your hearthstone" },
    { "GOLD",        "Coin worth a hundred silver" },
    { "AUCTION",     "House where players buy and sell" },
    { "TOTEM",       "A shaman drops one on the ground" },
    { "MOUNT",       "Ride you can first train at level forty in Classic" },
    { "TALENT",      "Point you spend in a class tree" },
    { "DUNGEON",     "Instance for a party of five" },
}
