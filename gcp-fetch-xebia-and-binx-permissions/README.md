## Google Cloud IAM Permission Audit Script

This script provides a simple and effective way to audit standing IAM (Identity and Access Management) permissions within a Google Cloud Organization. It queries all IAM policies, filters them for specific user domains, and exports the results to a clean CSV file for easy analysis and review.

This is particularly useful for security audits, compliance checks, or for getting a clear overview of which external or internal users have access to which resources.

## Features
1. **Organization-Wide Scan:** Recursively discovers all IAM policies at the organization, folder, project, and resource level.
2. **Domain-Specific Filtering:** Narrows down the results to show permissions granted only to users from specified domains (e.g., @example.com, @example2.io, example3.eu).
3. **Folder Exclusion:** Allows you to exclude specific folders from the scan to reduce noise or ignore non-relevant environments.
4. **CSV Export:** Outputs the findings into a standing_iam_permissions_domains.csv file with a clear Resource, Role, Member structure.
5. **User-Focused:** The script is configured to specifically scoped to look for standing user permissions: principals, ignoring service accounts and groups.

## Prerequisites
Before running this script, ensure you have the following installed and configured:
1. **Google Cloud SDK (gcloud):** The script relies on gcloud to interact with the Google Cloud Asset Inventory API. Make sure you are authenticated with an account that has the necessary permissions to view IAM policies (e.g., roles/cloudasset.viewer).
2. **Python 3:** The script uses an embedded Python script for efficient JSON parsing and CSV generation.

## configuration
* **ORG_ID:** Your unique Google Cloud Organization ID.
* **TARGET_DOMAINS:** A list of the email domains you want to audit. The script will only report on users whose email address ends with one of these domains.
* **EXCLUDED_FOLDERS:** A list of Folder IDs that you wish to skip during the scan.
* **OUTPUT_FILE:** The name of the resulting CSV file.

## Understanding the Output
The generated CSV file will have three columns:
* **Resource:** The full path of the Google Cloud resource where the permission is granted. This shows you exactly where the role is attached (e.g., a specific project, folder, or the organization itself).
* **Role:** The IAM role that has been granted (e.g., roles/owner, roles/storage.admin).
* **Member:** The user principal who has been granted the role (e.g., user:jane.doe@example.com).

## Note on IAM Inheritance
This script reports direct permissions—it shows where a role is explicitly bound to a resource. It does not list out all the inherited permissions. For example, if a user is granted roles/viewer on a folder, they can also view all projects within that folder. The script will correctly report this as a single permission on the folder, which is the source of that access.
