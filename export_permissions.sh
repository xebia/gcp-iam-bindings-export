#!/bin/bash

# Set the organization ID for the specific customer
ORGANIZATION_ID="123456789"  # Replace with your actual organization ID

# Define folders to exclude (comma-separated list of folder IDs to ignore)
FOLDER_EXCLUSIONS="12345678910"  # Replace with actual folder IDs

# Output CSV file
OUTPUT_FILE="gcp_permissions.csv"

# Initialize CSV with headers
echo "Resource Type,Resource ID,Resource Name,Member,Role" > "$OUTPUT_FILE"

# Function to check if a folder should be excluded
is_excluded_folder() {
  local folder_id="$1"
  [[ ",$FOLDER_EXCLUSIONS," == *",$folder_id,"* ]]
}

# Function to handle IAM policy processing and append results to CSV
process_policy() {
  local resource_type="$1"
  local resource_id="$2"
  local resource_name="$3"
  local policy_json="$4"
  echo "Processing IAM policy for $resource_type: $resource_id ($resource_name)"
  # Check if .bindings exists and is not null
  if jq -e '.bindings' <<< "$policy_json" >/dev/null; then
    jq -c '.bindings[]?' <<< "$policy_json" | while read -r binding; do
      # Check if role exists in binding, default to "UNKNOWN_ROLE" if null
      role=$(jq -r '.role // "UNKNOWN_ROLE"' <<< "$binding")
      
      # Check if members array exists and is not null
      if jq -e '.members' <<< "$binding" >/dev/null; then
        members=$(jq -r '.members[]?' <<< "$binding")
        
        # Process each member, defaulting to "UNKNOWN_MEMBER" if null
        for member in $members; do
          if [ -z "$member" ] || [ "$member" == "null" ]; then
            member="UNKNOWN_MEMBER"
            echo "Warning: Null or empty member found for role $role in $resource_type $resource_id"
          fi
          echo "$resource_type,$resource_id,$resource_name,$member,$role" >> "$OUTPUT_FILE"
        done
      else
        echo "Warning: No members found for role $role in $resource_type $resource_id"
      fi
    done
  else
    echo "Warning: No bindings found for $resource_type $resource_id ($resource_name)"
  fi
}

# Recursive function to process folders and their projects
process_folder() {
  local folder_id="$1"
  
  if is_excluded_folder "$folder_id"; then
    echo "Excluding Folder: $folder_id" >&2
    return
  fi

  # Fetch the folder name for clarity in output
  folder_name=$(gcloud resource-manager folders describe "$folder_id" --format="value(displayName)")
  echo "Processing Folder: $folder_id ($folder_name)"
  
  # Fetch and process folder IAM policy
  folder_policy=$(gcloud resource-manager folders get-iam-policy "$folder_id" --format=json)
  process_policy "Folder" "$folder_id" "$folder_name" "$folder_policy"

  # List and process all projects within the folder
  for project in $(gcloud projects list --filter="parent.id=$folder_id" --format="value(projectId)"); do
    project_name=$(gcloud projects describe "$project" --format="value(name)")
    echo "Processing Project: $project ($project_name)"
    project_policy=$(gcloud projects get-iam-policy "$project" --format=json)
    process_policy "Project" "$project" "$project_name" "$project_policy"

    ## IN CASE NEEDED - Add your resource-level policies here ##
  done

  # Recursively process any subfolders
  for subfolder in $(gcloud resource-manager folders list --folder="$folder_id" --format="value(name)"); do
    process_folder "$subfolder"
  done
}

# Process organization-level IAM policy
echo "Processing Organization IAM policy for Org ID: $ORGANIZATION_ID"
org_name=$(gcloud organizations describe "$ORGANIZATION_ID" --format="value(displayName)")
org_policy=$(gcloud organizations get-iam-policy "$ORGANIZATION_ID" --format=json)
process_policy "Organization" "$ORGANIZATION_ID" "$org_name" "$org_policy"

# Process all top-level folders in the organization
echo "Listing top-level folders for Organization ID: $ORGANIZATION_ID"
for folder in $(gcloud resource-manager folders list --organization="$ORGANIZATION_ID" --format="value(name)"); do
  process_folder "$folder"
done

echo "Permissions export completed. Results saved to $OUTPUT_FILE"
