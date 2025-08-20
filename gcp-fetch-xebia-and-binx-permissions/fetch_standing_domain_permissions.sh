#!/bin/bash

# ==============================================================================
# CONFIGURATION
# ==============================================================================

# Your Google Cloud Organization ID
ORG_ID="012345678910"

# The domains you want to find permissions for
TARGET_DOMAINS=("@example.com" "@example2.io" "@example3.eu")

# A list of Folder IDs to exclude from the scan
#EXCLUDED_FOLDERS=()

# The name of the output CSV file
OUTPUT_FILE="standing_iam_permissions_domains.csv"

# ==============================================================================
# SCRIPT LOGIC
# ==============================================================================
set -e # Exit immediately if a command exits with a non-zero status.

# --- Step 1: Retrieve IAM Policies ---
TEMP_JSON_FILE="temp_iam_policies.json"
echo "🔍 Retrieving IAM policies from Cloud Asset Inventory for organization '$ORG_ID'..."
gcloud asset search-all-iam-policies \
  --scope="organizations/$ORG_ID" \
  --format="json" > "$TEMP_JSON_FILE"

# Check if the gcloud command was successful
if [ ! -s "$TEMP_JSON_FILE" ]; then
  echo "❌ No IAM policies found or the gcloud command failed. Exiting."
  exit 1
fi
echo "✅ Successfully retrieved IAM policies."

# --- Step 2: Prepare variables for Python ---
# Convert Bash arrays to Python list string representations (e.g., "['item1','item2']")
printf -v TARGET_DOMAINS_PY "'%s'," "${TARGET_DOMAINS[@]}"
TARGET_DOMAINS_PY="[${TARGET_DOMAINS_PY%,}]"

printf -v EXCLUDED_FOLDERS_PY "'%s'," "${EXCLUDED_FOLDERS[@]}"
EXCLUDED_FOLDERS_PY="[${EXCLUDED_FOLDERS_PY%,}]"


# --- Step 3: Parse Policies and Filter for Target Domains ---
echo "⚙️  Parsing policies and filtering for users from: ${TARGET_DOMAINS[*]}..."

python3 <<EOF
import json
import csv
import sys

# Define target domains and excluded folders from Bash variables
target_domains = ${TARGET_DOMAINS_PY}
excluded_folders = ${EXCLUDED_FOLDERS_PY}

# Load the IAM policy data from the temporary JSON file
try:
    with open("$TEMP_JSON_FILE", "r") as json_file:
        iam_data = json.load(json_file)
except json.JSONDecodeError as e:
    print(f"❌ Error parsing JSON data: {e}", file=sys.stderr)
    sys.exit(1)

# Open the output CSV file for writing
with open("$OUTPUT_FILE", "w", newline="") as csv_file:
    writer = csv.writer(csv_file)
    # Write the CSV header
    writer.writerow(["Resource", "Role", "Member"])

    # Process each policy document
    for policy_info in iam_data:
        resource = policy_info.get("resource", "N/A")

        # Skip resources within excluded folders
        if "folders/" in resource:
            try:
                folder_id = resource.split("folders/")[1].split("/")[0]
                if folder_id in excluded_folders:
                    continue # Skip to the next policy
            except IndexError:
                pass # Not a valid folder resource path, continue processing

        # Iterate through the policy bindings
        for binding in policy_info.get("policy", {}).get("bindings", []):
            role = binding.get("role", "N/A")
            for member in binding.get("members", []):
                # Check if the member is a user and their email matches a target domain
                if member.startswith("user:"):
                    user_email = member.split(":", 1)[1]
                    if any(user_email.endswith(domain) for domain in target_domains):
                        writer.writerow([resource, role, member])

EOF

echo "✅ Success! Overview of standing permissions written to '$OUTPUT_FILE'."

# --- Step 4: Clean up temporary files ---
rm -f "$TEMP_JSON_FILE"
echo "🗑️  Cleaned up temporary files."
