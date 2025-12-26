#!/bin/bash

# Pre-push hook to block pushes for branches containing "local/"
# This hook is called with the following parameters:
# $1 -- Name of the remote to which the push is being done
# $2 -- URL to which the push is being done

# Read from stdin: <local ref> <local sha1> <remote ref> <remote sha1>
while read local_ref local_sha remote_ref remote_sha
do
    # Extract branch name from ref (refs/heads/branch-name -> branch-name)
    if [ -n "$local_ref" ]; then
        branch_name=$(echo "$local_ref" | sed 's|^refs/heads/||')

        # Check if branch name contains "local/"
        if [[ "$branch_name" == *"local/"* ]]; then
            echo "WAIT!: Cannot push branch '$branch_name' to remote."
            echo "Branches containing 'local/' are restricted to local development only."
            exit 1
        fi
    fi
done

exit 0
