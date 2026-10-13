# Contributing to Cache-Chan

Small, focused contributions are welcome. Start with an issue for a new cleaning target or a change to the deletion behavior.

1. Fork and clone the repository.
2. Run `bash build.sh` to compile and run the isolated self-test.
3. Run `open build/Cache-Chan.app` and check the affected interactions.
4. Submit a pull request describing the behavior and your validation.

Keep the project native, dependency-free and entirely in English. New cache targets must be fixed paths under the current user's home, rebuildable, documented and explicitly confirmed before deletion. Do not add broad directory deletion, administrator access, silent cleanup, telemetry or cloud services.

UI changes should cover the idle, scanning, confirmation, success and error states. Avatar changes should preserve keyboard access and persistence. Check drag placement near screen edges and on multiple monitors when available.

Code and the original default mascot are MIT licensed. Only contribute assets you have the right to license.
