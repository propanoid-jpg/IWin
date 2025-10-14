# IWin - One-Button Warrior Rotation Addon

![Tests](https://github.com/propanoid-jpg/IWin/workflows/Tests/badge.svg)
![Lua Version](https://img.shields.io/badge/lua-5.1-blue.svg)
![WoW Version](https://img.shields.io/badge/wow-1.12%20vanilla-orange.svg)
![License](https://img.shields.io/badge/license-Open%20Source-green.svg)

**Version:** 2.6.0
**Target:** World of Warcraft 1.12 (Vanilla)
**Author:** Atreyyo @ VanillaGaming.org, Bear-LB @ github.com, Enhanced by Claude
**License:** Open Source

A sophisticated one-button rotation addon for Warriors that provides intelligent, automated ability priority systems for DPS and tanking scenarios. Optimized for SuperWOW with full vanilla client compatibility.

---

## Table of Contents

- [Features](#features)
- [Installation](#installation)
- [Quick Start](#quick-start)
- [Rotations](#rotations)
  - [DPS Single Target](#dps-single-target-dmgst)
  - [DPS AOE](#dps-aoe-dmgaoe)
  - [Tank Single Target](#tank-single-target-tankst)
  - [Tank AOE](#tank-aoe-tankaoe)
- [Configuration](#configuration)
  - [Graphical Interface](#graphical-interface)
  - [Command Reference](#command-reference)
- [SuperWOW Features](#superwow-features)
- [Boss Detection](#boss-detection)
- [Performance](#performance)
- [Troubleshooting](#troubleshooting)
- [Version History](#version-history)
- [Credits](#credits)

---

## Features

### Core Functionality
- **4 Complete Rotations**: Separate optimized rotations for DPS ST, DPS AOE, Tank ST, and Tank AOE
- **Intelligent Priority System**: Smart ability queueing based on cooldowns, rage, stance, and combat conditions
- **Automatic Stance Dancing**: Seamlessly switches between Battle/Defensive/Berserker stances as needed
- **Debuff & Buff Management**: Tracks and maintains Rend, Sunder Armor, Thunder Clap, Demoralizing Shout, Battle Shout
- **Boss Detection**: Automatically adjusts thresholds for bosses vs trash mobs

### SuperWOW Enhancements
When running on SuperWOW, IWin automatically enables:
- **Enhanced Buff/Debuff Detection**: Direct API access for faster, more reliable buff scanning
- **Accurate Distance Calculation**: Precise 8-25 yard charge range detection
- **Swing Timer Integration**: Smart Heroic Strike/Cleave queueing to minimize rage waste
- **Cast Interrupt Detection**: Auto-interrupts enemy spell casts with Pummel/Shield Bash
- **Revenge Proc Detection**: Combat log parsing for dodge/parry/block events

### Configuration System
- **40+ Settings**: Fully customizable rage thresholds, health triggers, debuff refresh timings
- **Graphical UI**: Easy-to-use configuration interface with 7 organized tabs
- **Feature Toggles**: Enable/disable individual features (charge, shout, bloodrage, trinkets, rend, etc.)
- **Boss-Specific Settings**: Separate Execute thresholds and Sunder stack targets for bosses vs trash
- **Profile Persistence**: All settings saved per character in SavedVariables

### Performance Optimizations
- **Spell Caching**: Eliminates repeated spellbook scans (massive performance boost)
- **Configurable Throttling**: Adjustable rotation check frequency (0.05-1.0 seconds)
- **Efficient Debuff Tracking**: Client-side duration tracking reduces server queries
- **Smart Ability Queueing**: Minimizes wasted GCDs and rage expenditure

---

## Installation

### Step 1: Download
1. Clone or download this repository
2. Extract the `IWin` folder

### Step 2: Install
1. Navigate to your WoW installation directory
2. Place the `IWin` folder in `World of Warcraft/Interface/AddOns/`
3. Your directory structure should look like:
   ```
   World of Warcraft/
   └── Interface/
       └── AddOns/
           └── IWin/
               ├── IWin.lua
               ├── IWin.toc
               ├── dmgST.lua
               ├── dmgAOE.lua
               ├── tankST.lua
               ├── tankAOE.lua
               ├── IWinUI.lua
               └── README.md
   ```

### Step 3: Enable
1. Launch World of Warcraft
2. At the character select screen, click "AddOns"
3. Ensure "IWin" is checked and "Load out of date AddOns" is enabled
4. Log in with your Warrior character

### Step 4: Verify
You should see a startup message in your chat:
```
========================================
 IWin v2.6.0 loaded successfully!
 Client: SuperWOW Enhanced / Vanilla
 Rotations: /dmgst, /dmgaoe, /tankst, /tankaoe
 Commands: /iwin, /iwinhelp
========================================
```

---

## Quick Start

### Create Your Macro

1. Open the macro interface (`/macro`)
2. Create a new character-specific macro
3. Choose an icon (Rage icon recommended)
4. Enter one of the following rotation commands:

**DPS Single Target:**
```
/dmgst
```

**DPS AOE:**
```
/dmgaoe
```

**Tank Single Target:**
```
/tankst
```

**Tank AOE:**
```
/tankaoe
```

5. Drag the macro to your action bar
6. Press the button repeatedly during combat

### Configuration

- **Open GUI:** `/iwin ui` or `/iwin config`
- **View Settings:** `/iwin status`
- **Get Help:** `/iwin help`
- **View Rotation Priorities:** `/iwinhelp`

---

## Rotations

### DPS Single Target (`/dmgst`)

**Use Case:** Single-target boss encounters, elite mobs, raid DPS
**Recommended Spec:** Fury or Arms

#### Priority Order
1. **Charge** - Opens combat when out of range (8-25 yards, rage < 50)
2. **Overpower** - Highest priority reactive ability after enemy dodge (5s window)
3. **Interrupt** - Pummel/Shield Bash on enemy spell casts *(SuperWOW only)*
4. **Execute** - When target health < 20% (boss) or < 30% (trash)
5. **Battle Shout** - Maintains buff when out of combat (rage > 10)
6. **Bloodrage** - Generates rage when < 30
7. **Bloodthirst** - Primary Fury attack (6s CD, rage > 30)
8. **Mortal Strike** - Primary Arms attack (6s CD, rage > 30)
9. **Whirlwind** - Secondary DPS ability (10s CD, rage > 25)
10. **Rend** - Bleed DoT, refreshes at 5s remaining (rage > 10, skip on trash if configured)
11. **Heroic Strike** - Rage dump (rage > 30, smart queueing with SuperWOW)

#### Key Features
- Automatically stays in Berserker Stance for DPS
- Switches to Battle Stance for Overpower procs
- Uses offensive trinkets on cooldown (slots 13 & 14)
- Boss-aware Execute thresholds (20% boss, 30% trash by default)
- Skips Rend on trash mobs to save rage (configurable)

---

### DPS AOE (`/dmgaoe`)

**Use Case:** Dungeon trash packs, multi-target encounters
**Recommended Spec:** Fury or Arms with Sweeping Strikes

#### Priority Order
1. **Charge** - Combat opener (rage < 50)
2. **Overpower** - Reactive ability on dodge (5s window)
3. **Interrupt** - Enemy spell casts *(SuperWOW only)*
4. **Battle Shout** - Buff maintenance out of combat
5. **Sweeping Strikes** - Top priority AOE buff (Battle Stance, rage > 30)
6. **Whirlwind** - Primary AOE damage (Berserker Stance, 10s CD, rage > 25)
7. **Bloodrage** - Rage generation (rage < 30)
8. **Bloodthirst / Mortal Strike** - Main attacks (rage > 30)
9. **Execute** - Low health targets (20% boss / 30% trash)
10. **Rend** - Applies to bosses only by default (rage > 10)
11. **Cleave** - Primary AOE rage dump (rage > 30)
12. **Heroic Strike** - Fallback rage dump (rage > 30)

#### Key Features
- Preserves Sweeping Strikes buff (stays in Battle Stance while active)
- Intelligently switches to Berserker for Whirlwind
- Prioritizes Cleave over Heroic Strike for multi-target damage
- Smart stance management to maximize AOE damage

---

### Tank Single Target (`/tankst`)

**Use Case:** Dungeon bosses, raid main tanking, single elite mobs
**Recommended Spec:** Protection with Shield Slam

#### Priority Order
1. **Charge** - Combat opener (rage < 50)
2. **Interrupt** - Enemy spell casts *(SuperWOW only)*
3. **Last Stand** - Emergency survival when health < 20%
4. **Execute** - Low health targets (20% boss / 30% trash)
5. **Concussion Blow** - High threat stun (Berserker Stance, rage > 15)
6. **Defensive Stance Switch** - Returns to Defensive Stance
7. **Revenge** - Highest priority reactive ability after dodge/parry/block *(requires action bar placement)*
8. **Shield Slam** - Uses when Shield Block buff is active (rage > 20)
9. **Shield Block** - Activates before Shield Slam for synergy (rage > 10)
10. **Sunder Armor** - Ramps to 5 stacks ASAP, then maintains (rage > 15)
11. **Thunder Clap** - AOE threat + attack speed slow, refreshes at 5s (rage > 20)
12. **Demoralizing Shout** - Attack power reduction, refreshes at 3s (rage > 10)
13. **Battle Shout** - Buff maintenance in combat (rage > 30)
14. **Sunder Armor Refresh** - Maintains at max stacks (refreshes at 5s remaining)
15. **Bloodrage** - Rage generation (rage < 30)
16. **Rend** - Filler DoT on bosses (rage > 10, skip on trash if configured)
17. **Bloodthirst / Mortal Strike / Heroic Strike** - Filler DPS when Sunder is maxed

#### Key Features
- **Sunder Priority:** Aggressively stacks to 5 sunders before other debuffs
- **Shield Block Synergy:** Automatically uses Shield Block before Shield Slam for damage buff
- **Revenge Automation:** Detects procs via action bar usability *(requires Revenge on bars)*
- **Threat Optimization:** Prioritizes threat-per-rage efficiency
- **Boss-Aware Sunders:** Maintains 5 stacks on bosses, 3 stacks on trash (configurable)

**Important Note:** Revenge is automated using `IsUsableAction()` API. You **must** place Revenge on your action bars for proc detection to work.

---

### Tank AOE (`/tankaoe`)

**Use Case:** Dungeon trash packs, multi-mob tanking
**Recommended Spec:** Protection

#### Priority Order
1. **Charge** - Combat opener
2. **Interrupt** - Enemy spell casts *(SuperWOW only)*
3. **Last Stand** - Emergency survival (health < 20%)
4. **Execute** - Low health targets (20% boss / 30% trash)
5. **Concussion Blow** - High threat stun (Berserker Stance)
6. **Whirlwind** - AOE threat + damage (Berserker Stance, rage > 25)
7. **Defensive Stance Switch** - Returns to Defensive Stance
8. **Revenge** - Reactive ability *(requires action bar placement)*
9. **Sunder Armor** - Ramps to configured stacks (default 3 for trash)
10. **Thunder Clap** - Primary AOE threat + slow (rage > 20)
11. **Demoralizing Shout** - AOE attack power reduction (rage > 10)
12. **Shield Slam** - High threat single-target (rage > 20)
13. **Battle Shout** - Buff maintenance (rage > 30)
14. **Sunder Armor Refresh** - Maintains stacks (refreshes at 5s)
15. **Bloodrage** - Rage generation (rage < 30)
16. **Rend** - Filler DoT on bosses (skip on trash by default)
17. **Cleave** - Primary AOE rage dump (rage > 30)
18. **Bloodthirst / Mortal Strike / Heroic Strike** - Filler when Sunder is maxed

#### Key Features
- **AOE Threat Focus:** Prioritizes Thunder Clap and Demoralizing Shout uptime
- **Rage-Efficient Sunders:** Applies fewer Sunder stacks on trash (default 3 vs 5 for bosses)
- **Stance Dancing:** Switches to Berserker for Whirlwind, then back to Defensive
- **Smart Sunder Management:** Ramps to target stacks quickly, then maintains
- **Cleave Priority:** Uses Cleave as primary rage dump for multi-target threat

---

## Configuration

### Graphical Interface

**Open UI:** `/iwin ui` or `/iwin config`

The configuration UI provides 7 organized tabs:

#### Tab 1: Toggles
Enable/disable automatic features:
- Auto-Charge, Auto-Battle Shout, Auto-Bloodrage
- Auto-Trinkets, Auto-Rend, Auto-Attack
- Auto-Stance, Auto-Shield Block
- SuperWOW Features: Auto-Interrupt, Auto-Revenge, Smart Heroic Strike

#### Tab 2: DPS Rage Thresholds
Configure minimum rage for DPS abilities:
- Bloodthirst, Mortal Strike, Whirlwind, Sweeping Strikes
- Heroic Strike, Cleave, Execute, Rend, Overpower
- Charge Max, Bloodrage Min, Battle Shout Min (OOC/Combat)
- Interrupt Min *(SuperWOW)*

#### Tab 3: Tank Rage Thresholds
Configure minimum rage for tanking abilities:
- Shield Slam, Revenge, Thunder Clap
- Demoralizing Shout, Sunder Armor
- Concussion Blow, Shield Block

#### Tab 4: Health Thresholds
Configure health-based triggers:
- Execute Threshold (target health %)
- Last Stand Threshold (your health %)
- Concussion Blow Threshold (target health %)

#### Tab 5: Debuffs
Configure when to refresh debuffs:
- Rend Refresh (1-20s remaining)
- Sunder Armor Refresh (1-29s remaining)
- Thunder Clap Refresh (1-25s remaining)
- Demoralizing Shout Refresh (1-29s remaining)

#### Tab 6: Boss Detection
Configure boss-specific settings:
- Boss Execute Threshold (default 20%)
- Trash Execute Threshold (default 30%)
- Boss Sunder Stacks (default 5)
- Trash Sunder Stacks (default 3)
- Skip Rend on Trash (toggle)

#### Tab 7: Advanced
Fine-tune performance and mechanics:
- Rotation Throttle (0.05-1.0s) - how often rotation checks run
- Overpower Window (1-10s) - dodge reaction time
- Revenge Window (1-10s) - proc reaction time *(SuperWOW)*
- Sunder Stack Target (1-5) - legacy setting, use Tab 6 instead
- Heroic Strike Queue Window (0.1-2.0s) - swing timer integration *(SuperWOW)*
- AOE Target Threshold (2-10) - min enemies for AOE abilities *(SuperWOW)*
- Skip Thunder Clap with Thunderfury (toggle)
- Clear Spell Cache button

---

### Command Reference

#### Core Commands
- `/iwin` or `/iwin help` - Display all available commands
- `/iwin ui` or `/iwin config` - Open graphical configuration interface
- `/iwin status` - Display current settings with color coding
- `/iwin debug` - Toggle debug mode for rotation logging
- `/iwin cache clear` - Clear spell cache (use after learning new spells)
- `/iwinhelp` - Display rotation priorities in-game

#### Feature Toggles
```
/iwin charge [on|off]              Auto-charge
/iwin shout [on|off]               Auto-battle shout
/iwin bloodrage [on|off]           Auto-bloodrage
/iwin trinkets [on|off]            Auto-trinkets
/iwin rend [on|off]                Auto-rend
/iwin attack [on|off]              Auto-attack
/iwin stance [on|off]              Auto-stance switching
/iwin shieldblock [on|off]         Auto-shield block
/iwin skipthunderclap [on|off]     Skip Thunder Clap with Thunderfury
```

#### DPS Rage Thresholds (0-100)
```
/iwin chargemax [0-100]            Max rage to charge (default: 50)
/iwin bloodragemin [0-100]         Min rage for bloodrage (default: 30)
/iwin bloodthirstmin [0-100]       Min rage for Bloodthirst (default: 30)
/iwin mortalstrikemin [0-100]      Min rage for Mortal Strike (default: 30)
/iwin whirlwindmin [0-100]         Min rage for Whirlwind (default: 25)
/iwin sweepingmin [0-100]          Min rage for Sweeping Strikes (default: 30)
/iwin heroicmin [0-100]            Min rage for Heroic Strike (default: 30)
/iwin cleavemin [0-100]            Min rage for Cleave (default: 30)
/iwin shoutmin [0-100]             Min rage for Battle Shout OOC (default: 10)
/iwin shoutcombatmin [0-100]       Min rage for Battle Shout in combat (default: 30)
/iwin overpowermin [0-100]         Min rage for Overpower (default: 5)
/iwin executemin [0-100]           Min rage for Execute (default: 10)
/iwin rendmin [0-100]              Min rage for Rend (default: 10)
```

#### Tank Rage Thresholds (0-100)
```
/iwin shieldslammin [0-100]        Min rage for Shield Slam (default: 20)
/iwin revengemin [0-100]           Min rage for Revenge (default: 5)
/iwin thunderclapmin [0-100]       Min rage for Thunder Clap (default: 20)
/iwin demoshoutmin [0-100]         Min rage for Demoralizing Shout (default: 10)
/iwin sundermin [0-100]            Min rage for Sunder Armor (default: 15)
/iwin concussionblowmin [0-100]    Min rage for Concussion Blow (default: 15)
/iwin shieldblockmin [0-100]       Min rage for Shield Block (default: 10)
```

#### Health Thresholds (1-99%)
```
/iwin execute [1-99]               Execute threshold % (default: 20)
/iwin laststand [1-99]             Last Stand threshold % (default: 20)
/iwin concussionblow [1-99]        Concussion Blow threshold % (default: 30)
```

#### Debuff Refresh Timings (seconds)
```
/iwin refreshrend [1-20]           Rend refresh time (default: 5s)
/iwin refreshsunder [1-29]         Sunder refresh time (default: 5s)
/iwin refreshthunder [1-25]        Thunder Clap refresh time (default: 5s)
/iwin refreshdemo [1-29]           Demo Shout refresh time (default: 3s)
```

#### Advanced Settings
```
/iwin throttle [0.05-1.0]          Rotation throttle in seconds (default: 0.1)
/iwin opwindow [1-10]              Overpower window in seconds (default: 5)
/iwin sunderstacks [1-5]           Legacy Sunder stack target (default: 5)
```

---

## SuperWOW Features

IWin automatically detects and enables enhanced features when running on SuperWOW:

### Enhanced Buff/Debuff Detection
- **Direct API Access:** Uses `GetUnitBuff()` and `GetUnitDebuff()` for instant, reliable buff/debuff checking
- **Vanilla Fallback:** Automatically uses tooltip scanning on vanilla clients
- **Performance:** 10-20x faster than tooltip scanning

### Accurate Distance Calculation
- **Precise Charge Range:** Uses `GetDistanceToUnit()` for exact 8-25 yard detection
- **Vanilla Approximation:** Falls back to `CheckInteractDistance()` (approximates 10-28 yards)

### Swing Timer Integration
- **Smart Heroic Strike Queueing:** Only queues Heroic Strike/Cleave near swing timer
- **Rage Optimization:** Prevents wasting rage on early queues that get cancelled
- **Configurable Window:** Adjust queue timing (default 0.5s before swing)

### Cast Interrupt Detection
- **UNIT_CASTEVENT Tracking:** Monitors enemy spell casts in real-time
- **Auto-Interrupt:** Automatically uses Pummel (Berserker) or Shield Bash (Defensive)
- **Smart Timing:** Interrupts based on cast duration and priority

### Revenge Proc Detection
- **Combat Log Parsing:** Tracks dodge, parry, and block events from `CHAT_MSG_COMBAT_*`
- **Proc Window:** Configurable reaction time (default 5s)
- **Action Bar Integration:** Uses `IsUsableAction()` for reliable proc detection

### Boss Detection
- **Classification Check:** Identifies worldboss, skull-level (-1), elite skull enemies
- **Dynamic Thresholds:** Adjusts Execute threshold and Sunder stacks automatically
- **No Spam Logging:** Only logs when boss status changes

---

## Boss Detection

IWin automatically detects bosses using the following criteria:

### Detection Logic
A target is classified as a "boss" if it meets ANY of:
1. **Classification:** `UnitClassification("target") == "worldboss"`
2. **Level:** `UnitLevel("target") == -1` (skull level)
3. **Elite Skull:** `UnitLevel("target") == -1 AND UnitClassification("target") == "elite"`

### Boss-Specific Settings

When a boss is detected, IWin automatically uses:
- **Execute Threshold:** 20% (vs 30% for trash) - configurable
- **Sunder Stacks:** 5 stacks (vs 3 for trash) - configurable
- **Rend Application:** Always applies Rend to bosses, even if "Skip Rend on Trash" is enabled

### Checking Boss Status
Use `/iwin status` to see if your current target is detected as a boss:
```
Target: Ragnaros the Firelord
Boss: YES (worldboss)
Execute Threshold: 20% (boss mode)
Sunder Target: 5 stacks (boss mode)
```

---

## Performance

### Optimization Features

#### Spell Caching
- **What:** Caches spell IDs and existence checks in `IWin_Settings.SpellCache`
- **Benefit:** Eliminates repeated spellbook scans (500+ iterations per rotation)
- **Performance Gain:** 90%+ reduction in CPU usage
- **Maintenance:** Automatically rebuilds cache when spells are learned
- **Manual Clear:** `/iwin cache clear` (use if abilities aren't detected)

#### Rotation Throttling
- **What:** Limits how often the rotation executes
- **Default:** 0.1 seconds (10 checks per second)
- **Range:** 0.05-1.0 seconds
- **Lower Values:** Faster response, higher CPU usage
- **Higher Values:** Slower response, lower CPU usage
- **Recommendation:** Use 0.1s for most scenarios, increase to 0.2s if experiencing lag

#### Debuff Duration Tracking
- **What:** Tracks debuff application time client-side in `IWin_Settings.DebuffTracker`
- **Benefit:** Reduces server queries for debuff duration checks
- **Tracked Debuffs:** Rend, Sunder Armor, Thunder Clap, Demoralizing Shout
- **Accuracy:** Checks remaining duration before refresh threshold

#### Smart Ability Queueing
- **What:** Only queues Heroic Strike/Cleave near swing timer (SuperWOW)
- **Benefit:** Prevents early queues that get cancelled by other abilities
- **Rage Savings:** Reduces wasted rage by 10-30%
- **Vanilla Behavior:** Always queues when above rage threshold

---

### Performance Tips

1. **Clear Spell Cache After Learning New Spells**
   - Use `/iwin cache clear` after training at your class trainer
   - Cache automatically rebuilds on next rotation execution

2. **Adjust Throttle for Your System**
   - Low-end systems: Increase throttle to 0.2s or 0.3s
   - High-end systems: Decrease throttle to 0.05s for instant response
   - Default 0.1s works for most players

3. **Use Boss Detection Settings**
   - Configure separate thresholds for bosses vs trash
   - Reduces unnecessary Sunder applications on trash
   - Skip Rend on trash to save rage for threat/damage abilities

4. **Disable Unused Features**
   - Turn off Auto-Rend if you don't want DoT uptime
   - Disable Auto-Trinkets if you prefer manual control
   - Turn off Auto-Stance if you want manual stance control

5. **Optimize Debuff Refresh Timings**
   - Increase refresh times to reduce GCD waste (e.g., 5s → 10s)
   - Lower values = better uptime, higher values = fewer GCDs used
   - Balance based on encounter length and rage availability

---

## Troubleshooting

### Addon Not Loading

**Symptoms:** No startup message, `/iwin` commands don't work
**Solutions:**
1. Verify folder structure: `AddOns/IWin/IWin.toc` must exist
2. Enable "Load out of date AddOns" at character select
3. Check for Lua errors with `/console scriptErrors 1`
4. Try `/reload` or restart WoW client

### Abilities Not Being Used

**Symptoms:** Rotation doesn't cast certain abilities
**Solutions:**
1. **Check Rage Thresholds:** `/iwin status` - ensure thresholds are reasonable
2. **Clear Spell Cache:** `/iwin cache clear` - rebuild after learning new spells
3. **Verify Spell Names:** Addon uses English spell names regardless of client language
4. **Check Feature Toggles:** Ensure abilities aren't disabled (e.g., Auto-Rend, Auto-Stance)

### Revenge Not Working

**Symptoms:** Revenge never casts even after dodge/parry/block
**Requirements:**
1. **Place Revenge on Action Bars:** Addon uses `IsUsableAction()` to detect procs
2. **Enable Auto-Revenge:** `/iwin` → Toggles tab → Auto-Revenge checkbox
3. **Be in Defensive Stance:** Revenge requires Defensive Stance
4. **Check Rage:** Ensure rage > 5 (or configured `revengemin` value)

**Note:** Vanilla WoW 1.12 has no API to directly detect Revenge procs. The addon scans action bars for Revenge usability. If Revenge is not on your bars, the addon cannot detect when it's available.

### "I Can't Do That" Spam

**Symptoms:** Repeated error messages when using rotation
**Solutions:**
1. **Update to Latest Version:** This was a known bug in v2.2.0 and earlier, fixed in v2.2.1
2. **Check Ability Availability:** Ensure target is in range and facing correct direction
3. **Verify Stance Requirements:** Some abilities require specific stances
4. **Check Cooldowns:** Use `/iwin debug` to see cooldown checks

### Charge Not Working

**Symptoms:** Charge never activates
**Solutions:**
1. **Check Distance:** Target must be 8-25 yards away (10-28 yards approximation on vanilla)
2. **Out of Combat Only:** Charge only works when not in combat
3. **Check Rage:** Ensure rage < 50 (or configured `chargemax` value)
4. **Enable Auto-Charge:** `/iwin charge on`
5. **Check Line of Sight:** Must have clear path to target

### High CPU Usage

**Symptoms:** Game lag when using rotation
**Solutions:**
1. **Increase Throttle:** `/iwin throttle 0.2` or `/iwin throttle 0.3`
2. **Disable Unused Features:** Turn off Auto-Rend, Auto-Trinkets if not needed
3. **Clear Old Debuff Trackers:** `/reload` to reset `IWin_Settings.DebuffTracker`
4. **Update to Latest Version:** Performance optimizations added in v2.0.0+

### SuperWOW Features Not Working

**Symptoms:** Interrupts, Revenge procs, smart Heroic Strike not working
**Solutions:**
1. **Verify SuperWOW:** Check startup message - should say "SuperWOW Enhanced"
2. **Check SuperWOW Version:** Requires SuperWOW 1.12 build 7+
3. **Enable SuperWOW Toggles:** Auto-Interrupt, Smart Heroic Strike, Auto-Revenge
4. **Revenge Requires Action Bars:** Even with SuperWOW, Revenge must be on bars

### Settings Not Saving

**Symptoms:** Configuration resets after `/reload` or logout
**Solutions:**
1. **Check WTF Folder Permissions:** Ensure WoW can write to `WTF/Account/ACCOUNT/SavedVariables/`
2. **Verify SavedVariables:** `IWin.lua` file should exist in SavedVariables folder
3. **Use "Save & Close" Button:** In UI, click "Save & Close" instead of closing with X
4. **Check for Errors:** `/console scriptErrors 1` to see if Lua errors are preventing saves

---

## Credits

### Original Development
- **Atreyyo @ VanillaGaming.org** - Original IWin addon concept and implementation

### Continued Development
- **Bear-LB @ github.com** - Fork maintainer, feature additions

### Enhancement & Modernization
- **Claude (Anthropic AI)** - Code refactoring, SuperWOW integration, performance optimizations, configuration system, comprehensive documentation, bug fixes
---

## License

This project is open source and available under the terms specified by the original authors. Feel free to modify, distribute, and contribute improvements.

---

## Support & Contributing

### Reporting Issues
If you encounter bugs or have feature requests:
1. Check the [Troubleshooting](#troubleshooting) section first
2. Verify you're using the latest version
3. Enable script errors: `/console scriptErrors 1`
4. Note the exact error message and steps to reproduce
5. Report on GitHub (if available) or community forums

### Contributing
Contributions are welcome! Areas of interest:
- Additional rotation profiles (PvP, leveling, hybrid)
- Further SuperWOW integration (threat meters, advanced AI)
- Performance optimizations
- UI enhancements
- Bug fixes and testing

---

## Frequently Asked Questions

**Q: Does this work on private servers?**
A: Yes, IWin works on any 1.12 Vanilla WoW server. SuperWOW features require a SuperWOW-enabled client.

**Q: Will this get me banned?**
A: IWin uses only standard WoW API functions available in Vanilla 1.12. It does not modify game memory, inject code, or automate gameplay beyond what macros can do. Use at your own discretion.

**Q: Can I use this with other addons?**
A: Yes, IWin is compatible with most addons. It does not conflict with action bar addons, threat meters, or UI replacements.

**Q: How do I switch between rotations during combat?**
A: Create multiple macros (one for each rotation) and place them on your bars. You can press different macros based on the situation.

**Q: Can I customize the rotation order?**
A: Not directly through the UI, but you can modify the rotation files (`dmgST.lua`, etc.) to change priorities. Advanced users only.

**Q: Does this work for leveling?**
A: Yes, but it's optimized for endgame rotations. You may want to adjust rage thresholds lower for leveling (e.g., Heroic Strike at 20 rage instead of 30).

**Q: Why isn't Overpower working?**
A: Overpower requires a dodge event. If your target hasn't dodged recently (within 5 seconds), Overpower won't be available. Check `/iwin opwindow` to adjust the reaction time.

**Q: Can I use this in PvP?**
A: The addon is designed for PvE rotations. For PvP, you may need to disable certain features (e.g., Auto-Charge, Auto-Rend) and play more manually for better control.

---

**Enjoy your automated warrior rotations!**

For additional help, type `/iwin help` in-game or visit the addon's community forum.
