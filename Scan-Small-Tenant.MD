# Orphan users and m365-User-Id-Mismatch in small tenants

PowerShell script to identify and optionally remove orphan users from SharePoint Online sites.

## Background

An **orphan user** is a user account that no longer exists in Entra ID but is still present in a SharePoint site's **User Information List (UIL)**.

Normally, orphan users are harmless. However, they can contribute to **User ID Mismatch** issues when an email address (UPN) is reused and a new user needs access to a site where the previous user existed.

Microsoft recommends removing the old UIL entry as part of the remediation process.

## What This Script Does

- Scans SharePoint Online sites (optionally including OneDrive sites)
- Retrieves users from site User Information Lists
- Checks whether users still exist in Entra ID
- Reports orphan users
- Optionally removes orphan users from UILs

## When to Use It

This script uses a simple **brute-force** approach and is best suited for:

- Small tenants
- One-time cleanup projects
- Proactive User ID Mismatch prevention

## Requirements

- PowerShell
- PnP PowerShell
- SharePoint Administrator permissions
- Permission to query Entra ID users

## Related Article

https://vladilen.com/software/sharepoint/orphan-users-in-small-tenants/

## Disclaimer

Test in a non-production environment first. Review the report before removing orphan users.