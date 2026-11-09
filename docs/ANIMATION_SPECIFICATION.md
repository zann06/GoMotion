# Animation Specification

## Quality target
Aim for consistent 60 FPS on representative mid-range devices. Prioritize responsive interaction over decorative motion. Use reduced-motion settings to replace long transitions with short fades or no motion.

## Motion language
- Enter/exit: 180–280 ms, easeOutCubic / easeInOut.
- Press feedback: 90–140 ms scale or tonal response.
- Bottom sheet: 260–340 ms with restrained spring.
- Number/ETA transitions: 180–240 ms.
- Success moment: 500–900 ms; confetti brief and skippable.
- Radar: 1.8–2.4 s loop, only while matching and paused offscreen.

## Required moments
Splash, onboarding, service shortcuts, promo carousel, bottom navigation, page transitions, sheets, search expansion, matching radar, driver assignment, route marker, ETA, booking confirmation, payment success, receipt, rating, skeletons, empty states, haptics, rewards.

## Engineering rules
Dispose every AnimationController. Stop offscreen and terminal animations. Avoid multiple blur layers, huge particle counts, and unbounded tickers. Use RepaintBoundary for isolated custom-painted animation where profiling supports it. Respect system reduce-motion preference and provide an in-app override.
