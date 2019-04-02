# Raymarched GPU Particles with Screenspace Physics for VRC

By SCRN

[![Preview](https://i.imgur.com/SYW4Thz.png)](https://streamable.com/8y0cc)

Particle positions and velocities are stored on the bottom left of the player screen with two grabpasses then fed into a ray marcher.

# Stuff that Breaks It
1. Mirrors (Kinda Fixed?)
2. Portals (Fixed?)
3. Other grabpasses

# How to Add to Avatars
1. Look in the Prefabs folder
2. Put GrabPass Marcher.prefab in root of avatar.
3. Put GrabPass Spawner.prefab on where you want the particles to come out from. (Make sure the body part doesn't occlude the particle spawn point in game, i.e. move it far enough away)
4. Particles will be spawning out of the +Z local object direction. So rotate it accordingly.
5. The spawner must be minuscule. Scale the size to 0.0001 or smaller.
6. Make sure the "Spawn" property in GrabPass Marcher is always set to 1. It should be by default.
7. If you're not using a Inventory system, make a gesture override to enabled and disabled GrabPass Marcher and GrabPass Spawner objects.
8. Make separate gesture overrides for the "Reset" and "Attract" property to set them to 1 in GrabPass Marcher.
  
If you don't know how to make gesture overrides look up VRC Gesture overrides on Google.
  
I recommend using https://github.com/Xiexe/VRCInventorySystem to keep the objects disabled and free up a gesture override for spawning.

Thanks to Merlin, error.mdl, Lyuma, Neitri, Nave, 1001 for making this possible.
