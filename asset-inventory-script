#!/bin/bash

# Set variables
ORG_ID="12345678910"
OUTPUT_FILE="iam_policies.csv"
EXCLUDED_FOLDERS=["12345678910","12345678910"]  # Add folder IDs to exclude here

# Function to check if a folder is excluded
is_excluded() {
    local folder=$1
    for excluded_folder in "${EXCLUDED_FOLDERS[@]}"; do
        if [[ "$folder" == "$excluded_folder" ]]; then
            echo "Folder $folder is in the exclusion list. Skipping..."
            return 0  # Folder is excluded
        fi
    done
    return 1  # Folder is not excluded
}

# Run Cloud Asset Inventory to get IAM policies in JSON format
echo "Retrieving IAM policies from Cloud Asset Inventory for organization $ORG_ID..."
gcloud asset search-all-iam-policies \
  --scope="organizations/$ORG_ID" \
  --order-by="resource" \
  --format="json" > temp_iam_policies.json

# Check if the JSON file has content
if [ ! -s temp_iam_policies.json ]; then
  echo "No IAM policies found or failed to retrieve data. Exiting."
  exit 1
fi

echo "Parsing IAM policies and writing results to $OUTPUT_FILE..."

# Use Python to parse JSON and write CSV
python3 <<EOF
import json
import csv
import sys

# Load JSON data
try:
    with open("temp_iam_policies.json", "r") as json_file:
        data = json.load(json_file)
    print("Successfully loaded JSON data.")
except json.JSONDecodeError as e:
    print(f"Error parsing JSON data: {e}")
    sys.exit(1)

# Open CSV for writing
with open("$OUTPUT_FILE", "w", newline="") as csv_file:
    writer = csv.writer(csv_file)
    # Write CSV header
    writer.writerow(["Resource", "Role", "Member", "Permissions"])

    # Parse JSON and write each policy to CSV
    for policy in data:
        resource = policy.get("resource", "N/A")
        
        # Check if the resource is part of an excluded folder
        if 'folders' in resource:
            folder_id = resource.split('/')[3]
            if "$EXCLUDED_FOLDERS".count(folder_id) > 0:
                print(f"Excluding resource from folder {folder_id}.")
                continue

        print(f"Processing resource: {resource}")
        
        for binding in policy.get("policy", {}).get("bindings", []):
            role = binding.get("role", "N/A")
            members = binding.get("members", [])
            permissions = binding.get("condition", {}).get("title", "No Conditions")

            for member in members:
                print(f" - Role: {role}, Member: {member}, Permissions: {permissions}")
                writer.writerow([resource, role, member, permissions])

print(f"Output written to $OUTPUT_FILE")
EOF

# Clean up
echo "Cleaning up temporary files..."
rm temp_iam_policies.json
echo "Temporary files removed."

echo "IAM policy extraction completed successfully and saved to $OUTPUT_FILE."
