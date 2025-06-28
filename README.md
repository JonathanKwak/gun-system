# Gun System

A customizable Roblox gun system supporting both hitscan and projectile-based guns. This kit is a modified version of a gun system specifically designed for one of my older games. It contains features client-server interactions, rig configuration for both R6 and R15 characters, and basic anti-exploit checks on the server.

Note 1: This code was written 1–2 years ago and does not reflect my current coding standards. I've put this forward to demonstrate my skills in the software design process and implementation.
Note 2: This is not a drop-and-go type system. It is not designed to be implemented nor tested outside of ROBLOX studio, especially outside of the kit it was designed for. If you want to test the kit for yourself, download the full kit model here on Roblox:
https://create.roblox.com/store/asset/9112185857/Senseis-Gun-Kit
Note 3: This code was written without widespread user adoption in mind. I quickly modified a few bits of pre-existing code, made it configurable and published it for some use.

## Features
- Supports R6 and R15 character rigs
- Configurable character rigging via `config.lua` (attaching the gun to the hand, arm, etc.)
- Simple modular config system for weapon stats, with inline documentation
- Supports both hitscan and projectile simulation, with the latter utilizing a 3rd party resource called FastCast
- Server-side validation of damage to prevent basic client-side manipulation
- Compatible with mobile devices, not just PC

## File Structure
gun-system
 -> client.lua # Client-side tool behavior (input, visuals, raycast logic)
 -> server.lua # Server-side hit verification and damage application
 -> config.lua # Weapon stats and rig setup options
 -> README.md

## Setup

1. To start with a gun, just clone the 'Template' and set the tool's handle/looks to whatever you please
2. Insert an attachment into one of the parts of the guns, and name it "FiringPoint" (MUST BE "FiringPoint", NOTHING ELSE!)
3. Open up the config and start editing the gun to whatever you please

If you want, you can change the crosshair and the GUI if you dig into the tool. Just make sure the names are the same as they were before you edited them

MAKE SURE EVERYTHING INSIDE THE TOOL IS UNANCHORED, NON COLLIDABLE, AND CanQuery IS TURNED OFF!

## Behavior Logic

### Client-Side
- Handles user input, animations, sound effects, particle effects, and raycasting.
- Upon firing, performs a raycast or projectile simulation to detect hits.
- If a character is hit, it sends the `Humanoid` and `hitPart` to the server via the `VerifyHit` remote (located under the Tool object itself).

### Server-Side
- Validating hits:
  - Ensures `hitPart` is reasonably close to the `HumanoidRootPart` (anti hitbox-extension)
  - Checks for unobstructed line of sight from shooter to target
  - Verifies the humanoid is alive and is a valid enemy (and not a teammate)

## Design Philosophy

- The client handles raycasting and hit logic to keep user responsiveness instant (so that players feel the satisfaction of firing their gun, game design thing)
- The server verifies all damage to make sure the client isn't injecting or executing malicious code
- Configuration is decoupled to make weapon stats and rigging behavior easier to understand and change
