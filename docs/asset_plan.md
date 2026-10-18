🟢 BUCKET 1 — READY TO USE (drop-in, same universal rig)
1a. Free
Asset
	
What you get
	
License
	
Notes
UBC base characters ✅ owned	6 models (Superhero/Regular/Teen × M/F) + 20 hairstyles	CC0	Average 13k tris, Godot 4.3-tested
Modular Outfits – Fantasy v2.1 ✅ owned	12 outfits / 62 parts	CC0	Re-download for v2.1 — outfits now work with base-char heads alone
UAL Standard	~45 of 120+ anims (locomotion, sit, emotes)	CC0	Root motion + in-place, 30fps
UAL2 Standard	Free portion of 130+ anims	CC0	Jan 2026, same rig naming as UBC/Outfits
Bestiary – Dungeon Monsters (Standard)	7 monsters × 3 color variants, rigged	QAL (not CC0 — no resale/redistribution-as-assets)	No anims included — pair with UAL, which you already have
  
1b. Paid (one-time itch unlock unless noted)
Asset
	
Price
	
What it unlocks
UAL Pro	$9.99	Full 120+ anims incl. melee combat + gun — the drop-in combat path
UAL Source	$14.99	+ editable source files
UAL2 Source	$14.99	Full 130+ anims + source
Outfits-Fantasy Source	$20	Editable source (modify/refit outfits in Blender)
UBC Source	$19.99	Editable base characters
Bestiary Source	$20	Source zip (178MB vs 45MB)
Patreon Silver	$10/mo	→ $15 claim credit/month; Source kits via Discord #pack-claim (not in $3 tier)
(watch list) Future outfit themes	—	Fantasy is the only theme so far; Quaternius is actively extending compatibility — sci-fi/etc. would be drop-in
  
🟡 BUCKET 2 — FREE, NEEDS RETARGETING / REFITTING
2a. Animations (retarget via Godot BoneMap)
Asset
	
What you get
	
License
	
Caveats
KayKit – Character Animations ⭐ top pick	161 anims: full melee (1H/2H/unarmed/dual/block), ranged (bow/gun/magic), tools, emotes	CC0, $0	Rig_Medium/Large; page names Godot retargeting explicitly. (Optional: $14.99 gets .blend source files — anims themselves are already free)
Legacy Quaternius packs' animations (5 packs, one download)	Ult. Animated Character Pack (52 models), Animated Men/Women (4+4), Ult. Modular Men/Women (11+10) — all rigged & animated	CC0	Free Google Drive via quaternius.com pack pages (ultimatemodularcharacters, ultimatemodularwomen, animatedmen, animatedwomen, ultimatedanimatedcharacter ← real slug, correctly-spelled one 404s). Not on itch, no paid tier exists. Grab while Drive links live
Mixamo	2,500+ anims + auto-rigger	Royalty-free commercial (official Adobe FAQ)	⚠️ No redistribution of raw/retargeted files; service is an open-ended "technology preview" — download your picks now
Rokoko Motion Library	263 free assets (incl. 50 SuperAlloy)	Commercial OK	Account + Rokoko Studio export path
CMU motion capture	Thousands of mocap clips (BVH / FBX conversions: una-dinosauria repo, gbionics/cmu-fbx on HuggingFace — 2,548 FBX)	Public domain	Raw mocap quality — needs cleanup
MoCap Online Free Demo Pack	Samples from Mobility/Rifle/Ninja/Zombie/LIFE packs, 232MB, FBX+Blender included	Standard License: commercial OK capped at 1M end-users / $1M revenue; AI use needs permit	mocaponline.itch.io/mocap-online-demo
Kubold free samples	Movement Animset Pro LITE (8 anims) + UE demo (6)	Kubold EULA	kubold.com/downloads — taste test before paying
Kenney Animated Characters 3	~3 anims	CC0	Pipeline testing only
  
2b. Wardrobe / characters (Blender refit — no verified QUBC-fitting third-party clothes exist, this is the custom-work tier)
Source
	
What it gives you
	
License
	
Refit effort
Legacy Ult. Modular Men/Women (same downloads as above)	Modular body/clothing parts — raw material to refit onto UBC	CC0	High: old rig → re-weight/transfer to universal rig
KayKit character packs (Adventurers, Skeletons, Monsters)	Fully rigged+animated alternative cast + 25+ accessories	CC0	Zero if used as a parallel system; accessories ≠ modular clothing
MakeHuman	Parametric humans + built-in clothing libraries; DAE/FBX/OBJ/MHX2 export	Free/open	Rig via Mixamo auto-rigger, then retarget
The Base Mesh	1,250+ base meshes incl. clothing pieces	CC0	Same: Mixamo auto-rig path
Generic CC0 clothing one-offs (Sketchfab/itch)	Sporadic finds	Per-item check	Unverified fit — shrinkwrap + weight-transfer in Blender
  
🔴 BUCKET 3 — PAID, NEEDS RETARGETING
Asset
	
Price
	
What you get
	
License terms
Kubold Movement Animset Pro	$65 (frequent 50% sales → $32.50, all-time low $19.50)	180+ hand-keyed locomotion anims; HumanIK skeleton = Mixamo-identical naming (retarget-friendly)	Sold via Unity Asset Store (kubold.itch.io is an empty profile — don't hunt there). Official FAQ: other engines explicitly OK (Godot fine), but no source redistribution, non-transferable
MoCap Online paid libraries	Per-pack $1.99–$49.99 (Mobility Pro $49.99 = 223+ anims; Rifle from $5.99; Punch from $1.99; bundles $119–$149.50, 50% sale running)	Production-grade mocap, 6 formats	Same capped Standard License as demo
Rokoko paid clips	Unverified pricing	Extra mocap	Skip unless the free 263 run dry
  

Honest read: this bucket is genuinely small — nothing here is essential. KayKit (free) already covers what Kubold sells for $65, minus hand-keyed polish. The paid money that actually matters in this ecosystem is Bucket 1b's Quaternius unlocks.
📋 License cheat sheet
Tag
	
Meaning for you
CC0	Do anything, no attribution. Legacy packs + all modern Quaternius pack pages still badge CC0
QAL v1.0 (Bestiary, any newly downloaded Quaternius pack)	Free commercial use, but no reselling/redistributing assets as assets. Non-retroactive — your existing CC0 copies stay CC0
MCO Standard	Commercial OK but capped: 1M end-users / $1M revenue + AI-use permit
Kubold EULA	Commercial OK, engine-agnostic (per their own FAQ), no source redistribution, personal non-transferable
  
🔧 Retarget workflow (recap)

    Drop-in (Bucket 1): nothing to do — UBC/Outfits/UAL/UAL2/Bestiary share one rig.
    Cross-rig (Bucket 2): Godot 4 BoneMap editor + SkeletonProfileHumanoid → map KayKit/Mixamo/CMU bones once per skeleton. MixaBridge plugin (Godot Asset Library SV3FDn) automates the Mixamo path. Guides: forum.godotengine.org/t/mixamo-animation-retarget/137067 · 9to5grind.dev/posts/bringing-mixamo-animations-to-life-in-godot
    Clothes refit: Blender — import UBC skeleton, transfer weights / shrinkwrap the CC0 garment mesh onto the universal rig. Budget real time here; this is the one bucket with no shortcuts.

⏱️ Recommended acquisition order

    Today: back up your owned CC0 copies (QAL transition is live — license.html last updated 8/28/2026) → re-download Outfits-Fantasy v2.1
    Today: grab the 5 legacy packs from the Google Drive links (free forever in theory, but Drive folders aren't contractually guaranteed)
    $0 spree: KayKit Character Animations → Bestiary Standard → Mixamo picks → Rokoko batch → MoCap Online demo → Kubold LITE
    Paid when actually needed: combat day arrives → decide KayKit-free-retarget vs UAL Pro $9.99-drop-in (my take: KayKit first — it's free, and 161 anims beats UAL's combat subset; buy UAL Pro only if retargeting friction annoys you)
    Sale-watching: Kubold only on a 50%-off week ($32.50), Bestiary/Outfits Source only if you start editing meshes

🚫 Don't buy (recurring traps)

DAZ 3D (per-product Interactive License) · Reallusion (Enterprise tier needed for customization) · generic Unity/Unreal/Fab store characters (engine-locked EULAs — Kubold is the documented exception) · Booth VRM outfits (per-item licenses, often non-commercial)