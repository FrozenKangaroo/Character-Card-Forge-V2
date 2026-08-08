# Reported runtime reproduction

Observed after v0.15.40-hotfix1:

1. Open Character Collaborator.
2. Add a Character Card PNG.
3. Choose **Card data + Vision**.
4. Vision begins analysing the reference image.
5. The source list shows one source, but the source label is squeezed to almost one character per line between two very tall action controls.

The metadata source and Vision pipeline remain active; the defect is the final live source-row renderer selected by the refresh chain.
