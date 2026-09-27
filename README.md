# Flight Games

**Play Crossword, Word Search, Wordle or 2048 while you ride a flight path in WoW Forever.**

Flight Games is a World of Warcraft add-on for the WoW Forever client. When you take a flight path, a window opens in the classic WoW dialog style with a game selector. Pick a game and play until you land. The window closes when you land, and every game is saved for your next flight.

![Flight Games in game}(https://github.com/chase-hunter/FlightGames-Forever/blob/main/Photos/flightgames.gif?raw=true)

## Features

- **A game selector.** The window opens to a menu with four games. Each card shows your progress, such as your Wordle streak or your 2048 best score.
- **Opens when your flight starts.** Take any flight path and the selector appears. When you land it closes, and your games are saved.
- **Every game carries over between flights.** A half-finished crossword or a 2048 board is still there next time.
- **Classic WoW look.** The window uses the old dialog box border, the gold title header, the red close button and the standard buttons. You can drag it around, and Escape closes it.
- **Flight status line.** Shows where you're flying and how long you've been in the air, for example *Flying to Stormwind – 1:23*.

## The games

### Crossword
A new puzzle every time. The add-on fits 9 to 12 words from a bank of more than 100 Warcraft clues onto an 11×11 grid. Every word crosses another, and no stray letters form words without a clue.

- Click a square to select it. Click it again to switch between across and down.
- Type to fill in letters. The selected clue is shown under the grid. Click the clue bar for the next clue.
- **Check** marks wrong letters in red. **Reveal** fills in the selected word, with the letters shown in blue.

### Word Search
Find eight words from a Warcraft theme (classes, zones, dungeons, creatures and more) in an 11×11 grid. Words run in all eight directions, including backwards.

- Drag from the first letter to the last, or click the first letter and then the last.
- Found words are highlighted in item quality colors and crossed off the list.

### Wordle
Guess the hidden five-letter word in six tries. Green means the right letter in the right spot, gold means the letter is in the word but in a different spot, and gray means it isn't in the word.

- Type on your keyboard or click the on-screen keys.
- The game tracks your win streak and your best streak. Starting a new word partway through counts as a loss.
- Any five letters are accepted as a guess. There is no dictionary check.

### 2048
The same game as Flight 2048: a 4×4 board, tiles colored by item quality, and a *You Win!* screen when you reach 2048.

## Installation

1. Download the latest release, or click **Code → Download ZIP** on this page.
2. Copy the `FlightGames` folder into your WoW Forever client's `Interface\AddOns\` folder.
3. Make sure the folder layout looks like this:
   ```
   Interface\AddOns\FlightGames\FlightGames.toc
   Interface\AddOns\FlightGames\Core.lua
   Interface\AddOns\FlightGames\...
   ```
   The folder **must** be named `FlightGames`, the same name as the `.toc` file, or the game won't load it.
4. Restart the game, or `/reload` if you're already logged in. Check that **Flight Games** is enabled in the AddOns list on the character select screen.

Flight Games and Flight 2048 are separate add-ons and can be installed together. Their 2048 scores are saved separately.

## Controls

| Game | Input | Action |
|---|---|---|
| All | Drag the window border | Move the window |
| All | `Esc` | Close the window |
| Crossword | Click a square | Select it (click again to switch direction) |
| Crossword | Letters, `Backspace` | Fill in or erase letters |
| Crossword | Arrow keys | Move between squares |
| Crossword | `Space` / `Tab` | Switch direction / go to the next clue |
| Word Search | Drag, or click two letters | Select a word |
| Wordle | Letters, `Enter`, `Backspace` | Type, guess and erase |
| 2048 | Arrow keys, `W` `A` `S` `D`, or drag on the board | Slide the tiles |

While you're flying, the keys work wherever your mouse is, since you can't move your character anyway. On the ground, they only work while your mouse is over the window, so they never stop you from walking. Keys a game doesn't use pass through to your normal keybinds. In Wordle, `Enter` still opens chat until you start typing a word.

## Slash commands

`/fg` and `/flightgames` are the same command.

| Command | What it does |
|---|---|
| `/fg` | Show or hide the window |
| `/fg menu` | Go to the game selector |
| `/fg crossword`, `/fg wordsearch`, `/fg wordle`, `/fg 2048` | Open that game (`cw` and `ws` also work) |
| `/fg new` | Start the current game over |
| `/fg auto` | Turn opening when a flight starts on or off (default: **on**) |
| `/fg close` | Turn closing when you land on or off (default: **on**) |
| `/fg reset` | Move the window back to the center of the screen |
| `/fg help` | List the commands in chat |

## How it's built

Flight Games is plain Lua against the WoW UI API. It has **no build step and no libraries**: the files in `FlightGames/` are exactly what the game loads.

```
FlightGames/
├── FlightGames.toc  # Add-on manifest: interface version, title, saved variables, file order
├── Core.lua         # Window, game selector, shared UI helpers, flight detection, slash commands
├── Words.lua        # Wordle answers, Word Search themes and the Crossword clue bank
├── Crossword.lua    # Crossword generator and game
├── WordSearch.lua   # Word Search generator and game
├── Wordle.lua       # Wordle
└── Game2048.lua     # 2048
```

### Target client

WoW Forever reports **interface version `16001`** and uses the modern (Midnight-era, 12.x) UI API, not the old 1.12 Classic one. The add-on relies on modern API pieces such as `BackdropTemplate`, `C_Timer`, `SetColorTexture`, the Scale/Alpha/Translation animations and `SOUNDKIT`.

### How the games plug in

Each game file builds a table and calls `ns.RegisterGame(game)`. The menu shows the games in `.toc` order. A game provides:

| Field | Meaning |
|---|---|
| `key`, `name`, `desc`, `icon` | Saved-data key and what the menu card shows |
| `height` | Window height for this game |
| `newText`, `keys`, `extra` | The New Game button label, the controls hint, and an optional middle button |
| `defaults` | Default saved values, copied into `FlightGamesDB[key]` |
| `Build(view)` | Creates the game's frames once, inside its own view |
| `OnShow()`, `NewGame()`, `Stat()` | Called when the game is opened, restarted, or shown on the menu |
| `OnKey(key)` | Optional. Returns true if the game used the key |

`Core.lua` owns everything shared: the dialog frame, the bottom buttons, the status line, the keyboard handler and helpers such as `ScoreBox`, `CreateBoard`, `CreateOverlay` and `CreateToast`.

### Puzzle generation

- **Crossword.** Starting from one word in the middle, the generator tries each candidate word at every spot where it shares a letter with the grid. A spot is allowed only if the new word doesn't touch any other word except where it crosses it. It keeps the spot with the most crossings. It makes up to 12 tries and keeps the fullest grid, then centers it and numbers the clues in reading order.
- **Word Search.** Words are placed longest first, in random directions, and may share letters. Empty squares get random letters.

### Flight detection

This works the same way as Flight 2048. The add-on checks `UnitOnTaxi("player")` on `PLAYER_CONTROL_LOST`, `PLAYER_CONTROL_GAINED`, `TAXIMAP_CLOSED` and `PLAYER_ENTERING_WORLD`. It checks right away, again 0.5 s and 1.5 s later, and on a one-second backup ticker. A hook on `TakeTaxiNode` records the destination for the status line.

### Saved data

Saved per account in `WTF\Account\<ACCOUNT>\SavedVariables\FlightGames.lua` as `FlightGamesDB`. It holds `autoOpen` and `autoClose`, plus one table per game (`crossword`, `wordsearch`, `wordle`, `2048`) with that game's current puzzle and stats. To wipe everything, log out and delete that file.

## Troubleshooting

- **The add-on doesn't show in the AddOns list.** Check that the folder is named `FlightGames` and holds the `.toc` directly, not in another subfolder. If the list says it's *out of date*, tick **Load out of date AddOns**.
- **The window didn't open on a flight.** Run `/fg auto` and check that chat says *on*. You can always open it by hand with `/fg`.
- **A Lua error appears.** Please open an issue and paste the full error text. Enabling Lua errors (`/console scriptErrors 1`) will show it.

## Contributing

Issues and pull requests are welcome. There is nothing to build: edit the files in `FlightGames/`, copy the folder into your `AddOns` folder, and `/reload` in game to test. To add crossword clues or word search themes, edit `Words.lua`. Please keep the classic WoW UI style and keep the add-on free of outside libraries.

---

[github.com/chase-hunter/FlightGames-Forever](https://github.com/chase-hunter/FlightGames-Forever)
