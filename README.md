# StimMeter

StimMeter is an open-source WoW Forever addon that rewards repetitive character movement with floating intensity text and sustained Stim Mode.

## Install

1. Copy the inner `StimMeter/` folder into `World of Warcraft\_forever_\Interface\AddOns\`. The resulting path should be `Interface\AddOns\StimMeter\StimMeter.toc`.
2. Fully restart the client for a first install and enable StimMeter in the character-select AddOns list. After editing an already installed copy, use `/reload`.
3. Install only the inner addon folder. It includes the license and attribution and has no dependencies.

The manifest targets interface `16001`, matching the WoW Forever reference addon.

## Commands

| Command | Action |
| --- | --- |
| `/stim test [0-100]` | Preview a specific intensity out of combat. Omit the value to preview activation and the timer. Enable sound separately with `/stim sound`. Preview activations and streaks are excluded from statistics. |
| `/stim sound` | Toggle the optional activation chime. Off by default. |
| `/stim scale [value]` | Set the main text and timer scale from 0.5 to 2.0 (default 1.0), with a brief preview. Omit the value to see the current scale. |
| `/stim move` or `/stim unlock` | Show text and enable dragging. |
| `/stim lock` | Stop movement and return to normal click-through behavior. |
| `/stim center` | Restore the default position. |
| `/stim reset` | Clear current intensity and movement tracking. |
| `/stim stats` | Show current intensity, real activations, and longest real streak. |

`/stimmeter` is an alias. Position, statistics, sound preference, and scale are account-wide SavedVariables. Move mode starts locked each session.

## Playtest

1. In the open world, on foot and out of combat, run `/stim reset`, jump once, and immediately run `/stim stats`. It should report 2% within the two-second grace period. Step off a ledge, run straight, or turn the camera alone to check that they award zero.
2. From rest, turn the character through one, two, and three continuous rotations. The awards are +10, +15, and +25, for cumulative totals of 10, 25, and 50 before decay. A pause separates sequences. After three rotations, continued turning starts the next scoring sequence. A completed airtime rotation during a confirmed jump applies the 1.5x multiplier to the rotation award and tops up the jump once.
3. Use `/stim test 19`, `/stim test 40`, `/stim test 65`, and `/stim test 95` to inspect visibility, static yellow, and the orange and red brightness pulses. Normal intensity decays by four points per second after two seconds without a scoring action.
4. Run `/stim test` to check the stationary red pulse and timer. The activation is silent by default. Toggle `/stim sound` and retry to hear a single chime. Jump before five seconds elapse to extend the timer. Stop moving and check that Stim Mode ends five seconds after the last qualifying award, then intensity immediately resumes decaying. Reach 100 through real movement to verify the saved streak.
5. Check that combat suppresses new points and timer refreshes. Use `/stim move`, drag the text, lock it, and reload to verify persistence. At zero intensity, run `/stim scale 1.5` to see a three-second preview at the saved position. Run `/stim test` to check that the timer scales proportionally, then reload and run `/stim scale` to verify persistence.

## Detection and compatibility

- A jump requires both a `JumpOrAscendStart` hook and observed `IsFalling()` within a short window. Held-key repeat hops or input that bypasses the hook can be missed. A jump may score while traveling, as an explicit action. Walking, riding, and straight running award no points.
- Rotations sample `GetPlayerFacing()` from the character. A 357-degree arc counts as a full rotation to tolerate sampling undershoot. Ground spins require a readable, nearly zero `GetUnitSpeed("player")` value. Confirmed jumps can score air spins while moving. Restricted facing disables spins where the client withholds it, including instances reported by the reference. Low frame rates or fast turns exceeding 180 degrees between samples can miss or misread rotation.
- Repeated strafing and running circles are deferred. Ground speed alone cannot distinguish lateral input or establish a closed path, and the reference reports that position height is unavailable. The +5 and +8 values are reserved in the configuration.
- Scoring is suppressed during combat, swimming, flying, mounting, and death. An active mode can run out its existing five-second timer during combat. When enabled, the sound uses the same native sound key as the reference's first chime and is skipped if that key is absent.

Tune the score, timing, movement tolerances, and display in `StimMeter/Config.lua`. `Movement.lua` detects actions, `Meter.lua` owns scoring and streaks, `Display.lua` draws and positions text, and `Core.lua` wires the client events and slash commands.

## Development

Run `lua tests/smoke.lua` from the project root with Lua 5.1. The suite uses mocked WoW APIs.

For an install archive, zip only the inner `StimMeter/` directory, retaining that single folder at the archive root. The reference checkout and tests stay outside the install archive.

## License and attribution

StimMeter uses the [MIT license](LICENSE). Movement detection drew on SimpleController: Spin by Piefayth. See the [full attribution](StimMeter/ATTRIBUTION.md).
