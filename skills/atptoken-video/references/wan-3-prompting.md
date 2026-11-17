# Writing prompts for Wan 3.0 on ATP Token

How to write the `prompt` for `wan-3-0-video`, `wan-3-0-video-pro` and `wan-3-0-video-prime`. The request body is in the parent skill (`atptoken-video`, section "Wan 3.0 / spicy"); this file is only about the words.

Settings belong in body fields, not in the prompt: `duration`, `ratio`, `resolution` (uppercase), `audio`. Writing "16:9, 1080P" in the prompt does not set them. `prompt_extend` defaults to `false` on ATP, so the model uses your prompt as written; set it to `true` only for a short idea you want expanded.

## 1. Write the event first, the look second

A video model first needs to know what changes. Lead with one sentence of visible action:

```text
who + where + what sets the action off + how it continues + where it ends
```

Weak: "cinematic coffee ad, shallow depth of field, particles, slow motion".
Strong: "Coffee beans roll out of a burlap sack, bounce twice across a wooden table and drop into a hand grinder; the crank starts turning, fine grounds pile up in the drawer below, and a last wisp of steam drifts across the frame."

Add camera, light and sound only after the action reads clearly.

## 2. Eight layers, in this order

| Layer | What to write | Example |
|---|---|---|
| Output | Medium and feel only (length and ratio go in body fields) | "realistic handheld documentary look" |
| Identity | 3–5 fixed anchors per person or product, repeated word for word in every shot | "young watchmaker, short curly hair, faint mole above left brow, brick-red work jacket, round silver glasses" |
| World | Place, time, weather, foreground / midground / background | "early morning, narrow repair shop, loose gears in front, wooden bench in the middle, a tram passing outside the window" |
| Action | Cause and effect, with visible results instead of "dynamic" | "picks up the spring → it snaps back → his thumb steadies the gear → the second hand starts moving" |
| Camera | One main move per shot; split complex paths by seconds | "0–3s static macro; 3–7s slow slide along the bench; 7–10s rise to eye level" |
| Look | Key-light direction, colour temperature, contrast, materials, depth of field; no conflicting style tags | "cool window light as key, warm desk-lamp pool, real scratches on metal, soft background" |
| Sound (with `audio: true`) | Dialogue > key action sounds > ambience > music | "gears ticking clearly, distant tram, he says quietly 'it's running'; no music" |
| Constraints | 3–6 that matter for this shot, not a long generic list | "same glasses, jacket and bench layout; one set of tools; natural fingers; no subtitles or logos" |

## 3. By input mode

**Text to video (prompt only).** The prompt carries the whole world. Prove the character and place with a 6–8 second clip before writing a longer multi-shot version. If two places appear, say how the person gets from one to the other.

**First frame (`first_frame`).** The image already fixes composition and appearance, so write motion and its size:

```text
Keep the person, clothes, buildings and framing from the first frame. She blinks once, a breeze from the left lifts two strands of hair, and her right hand rises slowly to shade her eyes. The camera pushes in only 8%, no orbit; only the leaves in the background move.
```

Amounts keep motion from running away: "slightly", "half a step", "turns 30 degrees", "pushes in 8%", "pauses 0.5 seconds".

**First and last frame (`first_frame` + `last_frame`).** Do not just describe the two states; write the path between them, and say what stays fixed.

```text
From the empty table to the finished breakfast: a pair of hands slides a tray in from frame right, sets the cup down first, then the plate, unfolds the napkin and leaves frame. Table, window light and camera stay unchanged.
```

**Reference mode (`reference_images`, `reference_videos`, `reference_audios`).** Give each reference one job. A common convention is to name them by their order in each array:

```text
Image 1: the person's face and clothes only. Image 2: the café interior and colour palette. Video 1: the rhythm of the bartending moves only, not the person in it. Audio 1: the cutting beat. Create a new story and new shots.
```

When identity, motion and setting all come from one reference, the model mixes them up. Frame mode and reference mode cannot be combined in one request.

**Changing an existing clip.** When the clip you pass in `reference_videos` should be changed rather than just borrowed from, use "change only X, keep Y":

```text
Change only the weather from sunny to first snow. Keep the people, their steps, the camera move, buildings, car positions, length and cut points. Snow settles only on still surfaces and never covers faces.
```

## 4. Several shots in one clip

Shots should push one goal forward, not be a collage:

```text
0–3s: establish the place and the goal.
3–7s: the action meets resistance or a surprise.
7–11s: the person makes a choice.
11–15s: end on a visible result.
```

Repeat the identity anchors in every shot and fix screen direction: "the red-jacket person stays on the left of the blue-coat person; the camera never crosses the line between them." Use one natural transition (an object wiping frame, a matched action, a light flicker, a sound bridge) rather than a chain of effects.

## 5. Locking a person or a product

```text
Identity lock: 32-year-old woman, oval face, short black curly hair, faint mole above left brow, brick-red jacket, round silver glasses. Same face, hair, clothes and height in every shot.
```

```text
Product lock: short square clear glass bottle, rounded shoulders, matte silver cap, blank rectangular label area on the front. Same size, cap, liquid level, label position and glass colour from every angle.
```

The more the product moves, the fewer background effects it can take. Get the product's shape right first; add liquid, particles or mechanical unfolding in a later pass. Effects move around the product; the product never bends to the effect.

## 6. Dialogue and other languages

Keep the visual description in one language and the spoken lines in their own language:

```text
Spoken language: Japanese, standard Tokyo accent, soft, natural pace.
The shop assistant says: "雨、まだ止みそうにないですね。"
The customer pauses 0.4 seconds, then answers: "もう少し、ここにいます。"
No subtitles. Natural lip sync for the speaker; the listener keeps their mouth closed and nods once.
```

One speaker at a time, short lines that fit the length, a stated pause between turns. For on-screen text, give the exact short word or leave signs blank and add text in editing.

## 7. Sound

Sound follows cause: a door makes a sound because it closes, a footstep because a foot lands. State layers by distance: "front: the crack of crisp bread being cut; middle: oil hissing; far: muffled restaurant chatter; no music." Dialogue scenes need little or no music; for music videos, line cuts and big moves up with the bar. Sound needs `audio: true`; it is `false` by default on ATP.

## 8. Fixes for common failures

| Problem | Usual cause | Fix |
|---|---|---|
| Face changes between shots | Too many identity words, renamed every shot, big angle jumps, costume changes | Copy the same 3–5 anchors into every shot; drop costume changes; add an in-between angle; "Image 1 is for identity only" |
| Too much motion from a first frame | "make it lively" with no limits | Name the body part and the amount: "only the right hand rises to chest height", "camera pushes in 5%", "background people stay still" |
| Bottle or label warps | Orbit + liquid effects + product spin together | Fix the product facing camera and move only the camera; add a product lock; effects in a later pass; composite exact labels afterwards |
| Movement looks like teleporting | Only start and end written | Add 2–3 steps with physical feedback: "bends knees → pushes off → leaves the ground → dust spreads on landing" |
| Dizzy camera | Push, orbit, pan, zoom and handheld at once | One main move per shot; to combine, split by time with a half-second hold between |
| Left and right swap | Reverse shots without an axis | "A stays frame left of B; the camera never crosses the line between them" |
| Wrong lip sync | Long lines, overlapping speakers, no pacing | Shorter lines, one speaker at a time, listener's mouth closed, language and accent stated, 0.3–0.6 s pauses |
| Garbled text on signs or screens | The scene invites text and the model invents it | "All signs blank or abstract shapes"; add exact text in editing; if it must be generated, one short exact word |
| Pretty but no story | Style words crowd out the event | Make the first sentence the event: "to get X, the person must do Y, ending in Z"; style after |
| Speed turns into stretched objects | "super fast" instead of physical cues | Background parallax, spray from tyres, cloth pushed by wind, motion blur at a fixed shutter, sound change; "the subject's shape does not change" |
| Shots feel randomly glued | Different place, light or time per shot | Shared anchors and colour; each shot starts from the previous shot's result; match cut, wipe or sound bridge |

Retry template, changing one thing at a time:

```text
Retry the previous version and fix only: {one problem}.
Keep: {the identity, place, framing, action and length that must not change}.
Change: {one measurable amount or one camera change}.
Do not add people, props, dialogue, transitions or effects.
```

## 9. Iterate cheaply

1. First pass: one subject, one action, one camera move, at `480P` and a short `duration`.
2. Lock what worked (the character, or a good frame to reuse as `first_frame`).
3. Second pass: add only environment reaction or sound.
4. Third pass: add transitions, more shots or effects.
5. Change one variable per run so a failure can be rolled back.
6. Only then raise `resolution` (and use `-pro` for `2K` / `4K`).

Before the final render, check: the subject and goal read within three seconds; the action has a cause, a middle and a result; camera moves do not fight; anchors match in every shot; the lines fit the length; there are no brands, protected characters or real people's likenesses you have no rights to; on-screen text is truly needed.

## 10. A full example

```json
{
  "model": "wan-3-0-video",
  "prompt": "A restrained vertical micro-drama on an almost empty suburban train platform at blue hour. 0–5s: a courier in a rust-red jacket watches the last train doors close, then notices one unheard voicemail on a scratched phone; the train leaves left to right. 5–12s: over-the-shoulder close shot as the voicemail plays in natural English, an older sibling's voice saying, \"Don't come to the house. Meet me where we buried the blue tin.\" The courier does not speak; their thumb stops above the call button and their expression turns from irritation to concern. 12–18s: they look across the tracks toward a dark community garden, pocket the phone and run down the stairs as the platform clock reaches 21:40. End on the delivery bag left beside the bench. Sound: departing train, compressed voicemail audio, one station chime, footsteps. Keep the face, jacket, phone damage, bag, platform layout, train direction, clock and eyeline the same throughout. No subtitles, readable notifications, extra passengers, teleporting, camera-axis reversal or logos.",
  "resolution": "720P",
  "ratio": "9:16",
  "duration": 18,
  "audio": true,
  "prompt_extend": false
}
```

---

Adapted from [flaqai/awesome_wan-3-0-prompts](https://github.com/flaqai/awesome_wan-3-0-prompts) (prompting guide, troubleshooting and the "voicemail" example), Copyright (c) 2026 Flaq AI, used under the MIT License. Body fields and defaults are ATP Token's, checked against the ATP API guide.
