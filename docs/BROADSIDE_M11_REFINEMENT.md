# Broadside — Gameplay Refinement Update (M1.1)

The current version is a great foundation. I like the game and want to preserve its core gameplay, visual direction, controls, and architecture. This update focuses on improving naval movement, cannon combat, battlefield awareness, and audio.

Please work from the latest Broadside source in the existing `briang7165/Game-Dock` repository. Make these improvements without rebuilding the game or introducing unrelated features.

## 1. Ship Movement — More Weight and Realistic Sailing Feel

The current movement feels too much like a go-kart. The ship turns and responds too quickly for a large sailing vessel.

Please adjust the physics to provide:

- Gradual acceleration and deceleration.
- More forward momentum when the player releases the throttle.
- Slower, smoother turning with a noticeable turning radius.
- Rudder response influenced by ship speed.
- Limited reverse speed and less effective steering while nearly stationary.
- A modest delay between steering input and the ship reaching its maximum turning rate.
- Natural water resistance and limited sideways drift.

**Goal:** The ship should feel heavy and deliberate, but remain responsive enough for enjoyable arcade combat.

Do not implement a full realistic wind or sailing simulator. Prioritize satisfying naval movement over strict realism.

Make movement values configurable so we can tune them after testing.

## 2. Cannonballs — Improve Accuracy, Prediction, and Dodging

Currently, cannonballs travel so quickly that there is limited opportunity to anticipate or avoid enemy shots, especially when ships are far apart.

Please improve this through a combination of:

- Moderately reducing cannonball speed.
- Increasing visible projectile travel time.
- Adjusting projectile range and lifetime as necessary.
- Improving visibility of incoming shots.
- Providing a short visual warning before enemy cannons fire.

The key gameplay mechanic should be **leading a moving target**.

I want to maneuver my ship into position, anticipate where the enemy will be, and fire my cannons at that location. Likewise, I should be able to anticipate incoming cannonballs and maneuver away when enough distance exists.

Keep realistic projectile travel and collision. No instant hits, guided cannonballs, or automatic targeting.

Retain Spacebar firing, fixed port/starboard cannons, and independent automatic reloading.

## 3. Camera — Increase Battlefield Visibility

Please zoom the camera out approximately 20–30% as an initial test, then adjust based on actual gameplay.

Goals:

- Display more surrounding ocean.
- Give the player additional time to observe incoming cannonballs.
- Make enemy positioning easier to understand.
- Preserve readable ship silhouettes and projectile effects.
- Avoid making ships too small.

Maintain smooth camera tracking and appropriate battlefield boundaries.

## 4. Off-Screen Enemy Indicators

When an enemy ship moves outside the visible screen, display a directional arrow near the appropriate screen edge.

Requirements:

- Arrow points toward the enemy's current world position.
- Arrow follows the enemy as it moves around the player.
- Show distance to the enemy if practical.
- Use a distinct color or symbol for hostile vessels.
- Support multiple enemies later without excessive screen clutter.
- Remove the indicator when the enemy becomes visible.
- Remove it when the enemy is destroyed.

This should help the player maintain situational awareness without introducing a minimap yet.

## 5. Music — Pirate Arcade Soundtrack

The game currently feels too quiet. Please add background music that suits a pirate naval arcade game.

Preferred style:

- Adventurous pirate-themed instrumental music.
- A classic arcade-game feel with energetic percussion and nautical melodies.
- Something enjoyable over repeated battles without becoming distracting.
- Seamless looping without abrupt starts or stops.

Use original, procedurally created, or appropriately licensed audio. Do not use copyrighted commercial game or movie soundtracks.

A single good combat music loop is sufficient for this update. More tracks can come later.

## 6. Sound Effects

Please implement sound effects for:

- Cannons firing, with a satisfying deep boom.
- Cannonballs striking wooden hulls.
- Cannonballs splashing into water.
- Cannonballs striking rocks.
- Ship destruction or sinking.
- Subtle ocean ambience and ship movement.
- Menu selections and victory/defeat events.

Use audio layering and reasonable volume balance. Cannon fire should feel powerful without overpowering the music.

Add separate Music and Sound Effects volume controls to the Settings menu, with mute capability.

All audio should function offline.

## 7. Preserve Existing Features

Do not remove or unintentionally change:

- WASD and arrow-key movement.
- Spacebar to fire cannons.
- Automatic cannon reloading.
- Escape to pause.
- Mouse-free naval combat.
- Fixed broadside firing.
- Existing enemy AI and damage mechanics.
- Current visual style and scene structure.
- Standalone Windows compatibility.
- Game Dock integration.

Keep the game keyboard-accessible, with mouse support in menus.

## 8. Testing and Delivery

Please test the changes together rather than treating each feature in isolation.

Verify that:

1. Ship movement feels heavier without becoming frustrating.
2. Cannonballs remain fast enough to feel powerful but slow enough to observe and lead targets.
3. Medium- and long-range shots can be anticipated and sometimes avoided through maneuvering.
4. The camera improves battlefield awareness.
5. Off-screen enemy indicators point correctly to enemies.
6. Background music loops and sound effects play without errors.
7. Music/SFX settings function correctly.
8. Existing combat controls, victory/defeat, pause, and restart still work.
9. Game Dock and standalone Windows compatibility remain intact.

Keep physics and audio parameters configurable for future balance adjustments.

Use the existing development branch if appropriate, or create a new focused branch and pull request. Run available Godot tests, report actual results, and document changes.

**Priority:** Ship physics and cannon combat first, followed by camera/indicators, then audio.

Do not begin ship purchases, economy, or additional major gameplay systems in this update. I want to test and approve the improved combat experience first.