# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Godot 4.6 2D platformer game. Uses GDScript for game logic, Forward+ renderer, Jolt Physics, and Direct3D 12 on Windows.

## Commands

Open the project in the Godot editor to run, debug, and test — there is no headless CLI build pipeline.

## Asset Conventions

- **Character sprites**: `assets/images/Pink Man/` — multi-frame sprite sheets named by action (Idle, Run, Jump, Double Jump, Fall, Wall Jump, Hit). Dimensions noted in filename, e.g. `(32x32)`.
- **Enemy sprites**: `assets/images/Snail/` — includes shell states for hit mechanics.
- **Tilemap**: `assets/images/Tilemap/Terrain (16x16).png` for level geometry; `Checkpoint (Flag Idle)(64x64).png` for checkpoints.
- **Pickups**: `assets/images/Collectibles/` (Apple, Collected states).
- **Backgrounds**: `assets/images/Background/` — solid color backgrounds (Blue, Brown, Gray, Green).
- **Audio**: `assets/sounds/` — WAV for SFX (collect_apple, death, jump), OGG for music.
- **Fonts**: `assets/fonts/Square-Black.ttf` — pixel-art style font.

## Godot Project Config

- **Physics**: Jolt Physics 3D (even though game is 2D)
- **Renderer**: Forward Plus, D3D12 on Windows
- **Project name**: "platformer" (`res://project.godot`)
