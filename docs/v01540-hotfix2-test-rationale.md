# Test rationale

The important difference from hotfix1 is that hotfix2 never validates the new row component in isolation as its primary proof. The regression reaches the source list through the real application shell and refresh lifecycle, then verifies the final live tree. This is the behavior that matters for the reported runtime bug.
