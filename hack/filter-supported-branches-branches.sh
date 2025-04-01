#!/bin/bash

# Fetch the JSON output from your command
json=$(gh dkp generate dev-versions --json)

# Initialize an empty array to store valid branch names
branches=()

# Use jq to extract the branch_name values and loop through them
for branch_name in $(echo "$json" | jq -r '.releases[].branch_name'); do
    # Check if the branch_name starts with 'release-' and follows the 'release-X.Y' pattern
    if [[ "$branch_name" =~ ^release-([0-9]+)\.([0-9]+)$ ]]; then
        major="${BASH_REMATCH[1]}"
        minor="${BASH_REMATCH[2]}"

        # Compare version numbers to filter out versions >= 2.15
        if [[ "$major" -lt 2 ]] || { [[ "$major" -eq 2 ]] && [[ "$minor" -lt 15 ]]; }; then
            # Append the valid branch name to the array
            branches+=("\"$branch_name\"")
        fi
    else
        branches+=("\"$branch_name\"")
    fi
done

# Print the array in a single line, properly quoted
printf "[%s]\n" "$(IFS=,; echo "${branches[*]}")"
