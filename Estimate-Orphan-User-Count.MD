# Estimate Number of Orphan Users in Microsoft 365 Tenant

PowerShell script to estimate - how many orphan users there are in Microsoft 365 tenant

Scanning all Microsoft 365 SharePoint sites for orphan users could be time-consuming, especially for large tenants
The script
- gets all tenant sites, and selects a set of random sites to scan for orphan users
- retrieves all users from the selected sites
  - for each user - checks if user exists in Entra ID
  - collects orphan users (users not found in Entra ID)
- gets another random set of sites to scan for orphan users
  - repeats the scanning process in the same manner 
- selects orphan users found in both sets
- calculates the estimated number of orphan users in the tenant
