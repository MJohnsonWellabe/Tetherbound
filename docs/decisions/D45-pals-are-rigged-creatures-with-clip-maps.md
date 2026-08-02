# D45. Each pal species is its own rigged creature, addressed by verb

Kind: implementation

Every species names a distinct skeletal-animated GLB in `models.json`. Gameplay
never names an animation clip: it calls `driver.play('run')` and the driver
resolves the verb through that model's `clips` map.

The species were tinted capsules with a `body` type from a set of six. Identity
came from colour and proportion, which at the size a pal occupies on screen is
close to no identity at all. The licensing waiver (D42) opened up Quaternius'
animated creature packs, so each species now has a creature that matches its
written read.

The clip map is the whole design. These models come from several packs and
their AnimationGroups are named inconsistently: `CharacterArmature|Idle` in
one, plain `Idle` in another, `EnemyArmature|EnemyArmature|EnemyArmature|Attack`
in a third, `FrogArmature|Frog_Jump` in a fourth. Mapping verb to exact clip
name in data means a swapped model is a data edit, and code that says
`play('attack')` keeps working across every pack.

Three consequences worth stating:

- **A missing verb is data, not a crash.** A model with no hit reaction maps
  `hit` to null and the driver does nothing for it. The procedural pose layer
  covers the gaps rather than driving everything.
- **Mounting is asynchronous over a placeholder.** Constructors never go async.
  Callers build their capsule now, call `mountRig`, and keep moving; the rig
  swaps in when the container lands, and the returned cancel function makes the
  gap leak-proof if the entity dies first.
- **One-shot verbs win.** `attack`, `hit`, `faint`, `interact`, `dodge` and
  `wave` block the locomotion verb that gets called every frame, or a walking
  pal would stomp its own hit reaction the frame after it started. `faint`
  holds its last frame and is terminal until `revive()`.

Instantiation is per entity, so two foxes animate independently. The budget is
about fifteen concurrent skinned meshes: twelve pooled wild pals, the
companion, and the combat stage.
