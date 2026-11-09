# Animation Implementation Prompt

Implement motion according to `docs/ANIMATION_SPECIFICATION.md`. Use AnimationController/flutter_animate where appropriate; Lottie/Rive only for bundled assets that materially improve the experience. Dispose controllers, stop offscreen loops, keep radar active only while matching, and keep the UI responsive. Respect system and in-app reduced-motion preferences. Avoid excessive blur/glow and unbounded particles. Profile representative screens and document measured issues.
