# This script use "brute force" approach to scan tenant for orphan users
# "Orphan User" in SharePoint refers to a user account that no longer exists in the Entra Id but still has present in the User Information List on SharePoint sites.
# As idividual orphan user can appear at any site, this script scans all sites to identify such users.
# The script works for small to medium-sized tenants due to the "brute force" approach, which can be time-consuming for large tenants.

# Prerequisites
# - Install the PnP.PowerShell module
# - Register an app in Azure AD with appropriate permissions to access SharePoint sites and read user information from Entra Id

# Authentication section. An app with appropriate permissions is required to access all sites and their user information lists.
# Uncomment and specify the values for your tenant and app registration.
# $tenantId = ""
# $adminUrl = ""
# $clientid = ""
# $thumbPrint = ""

$startTime = Get-Date

$connectionAdmin = Connect-PnPOnline -ReturnConnection -Url $adminUrl -ClientId $ClientId -Thumbprint $Thumbprint -Tenant $tenantId
$connectionAdmin.Url

$allTenantSites = Get-PnPTenantSite -Connection $connectionAdmin -IncludeOneDriveSites 
$allTenantSites.count

$sites = $allTenantSites | ?{ $_.ArchiveStatus -eq "NotArchived" }

$orphanUserEntries = [System.Collections.Generic.List[PSObject]]::new()
foreach ($site in $sites) {
    Write-Host "Scanning site: $($site.Url)"
    $connectionSite = Connect-PnPOnline -ReturnConnection -Url $site.Url -ClientId $ClientId -Thumbprint $Thumbprint -Tenant $tenantId
    $allUILEntries = Get-PnPUser -Connection $connectionSite
    $allUsers = $allUILEntries | ?{ $_.LoginName -like "i:0#.f|membership|*" }
    foreach ($user in $allUsers) {
        $user | Add-member -MemberType NoteProperty -Name SiteUrl -Value $site.Url -Force
        $upn = $user.LoginName.Split("|")[-1]
        $userExists = $null
        try {
            $userExists = Get-PnPEntraIDUser -Connection $connectionAdmin -Identity $upn    
        }
        catch {
            $userExists = $false
        }
        if (-not $userExists) {
            $orphanUserEntries.Add($user)
        }
    }
}



# $orphanUserEntries.count
# $orphanUserEntries | Format-Table -Property Title, SiteUrl -AutoSize

$duration = New-TimeSpan -Start $startTime -End (Get-Date)
$orphanUsers = $orphanUserEntries | select-object -Property LoginName -ExpandProperty LoginName -Unique
$sitesWithorphanUsers = $orphanUserEntries | select-object -Property SiteUrl -ExpandProperty SiteUrl -Unique
Write-Host "Total time: $($duration.TotalSeconds) seconds"
Write-Host "Total sites in tenant: $($allTenantSites.count)"
Write-Host "Total not archived sites in tenant: $($sites.count)"
Write-Host "Total orphan users-sites pairs found: $($orphanUserEntries.count)"
Write-Host "Total unique orphan users found: $($orphanUsers.count)"
Write-Host "Total sites with orphan users found: $($sitesWithorphanUsers.count)"    

$PnPEntraIDUsersAll = Get-PnPEntraIDUser -Connection $connectionAdmin 
$PnPEntraIDUsersEnabled = $PnPEntraIDUsersAll | ?{ $_.AccountEnabled -eq $true }
Write-Host "PnP Entra ID Users: " $PnPEntraIDUsersAll.count
Write-Host "PnP Entra ID Enabled Users: " $PnPEntraIDUsersEnabled.count

