# GCP IAM Binding Script

To simplify permission reviews, we created a bash script to generate a quick and thorough overview of IAM bindings/roles across Google Cloud Platform.

Keep in mind that in order to run this script in Google Cloud Shell, your account must have the roles/iam.securityReviewer permission at the organizational level.


## Steps

1. **Open Google Cloud Shell** and create a new `.sh` file (e.g., `nano export_permissions.sh`).
2. **Edit the File**: Paste the code into the file, replacing the placeholder with your actual Organization ID.
3. **Exclude Specific Folders (Optional)**: The script includes a function to exclude specific folders. Replace the placeholder with the folder ID(s) you want to exclude, if needed.
4. **Make the Script Executable**: In the terminal, run:
   ```bash
   chmod +x export_permissions.sh

## Execute the Script:
**Run the script with**: 
```bash
./export_permissions.sh
```
## Disclaimer:
**This `README.md` provides a clean and organized overview of your script, with a step-by-step guide for users. Let me know if any additional details are needed**!
