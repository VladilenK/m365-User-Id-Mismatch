# Scanning Microsoft 365 tenant for orphan users could be time-consuming depending on tenant size
# This script estitimates number of orphan users in SharePoint Online 
# The scrip
# - gets all tenant sites, and selects a set of random sites to scan for orphan users
# - retrieves all users from the selected sites
# - checks if each user exists in Entra ID
# - collects orphan users (users not found in Entra ID)
# - gets another random set of sites to scann for orphan users
# - repeats the scanning process, but this time notices if the found orphan users were previously detected
# - provides a summary of orphan users and sites containing them
# - calculates the estimated number of orphan users in the tenant
# 

$randomSetSize = 5 # sites

$connectionAdmin = Connect-PnPOnline -ReturnConnection -Url $adminUrl -ClientId $ClientId -Thumbprint $Thumbprint -Tenant $tenantId
$connectionAdmin.url

$allTenantSites = Get-PnPTenantSite -Connection $connectionAdmin -IncludeOneDriveSites -Detailed
$allTenantSites.count
$allTenantSites = $allTenantSites | ?{ $_.Template -ne "RedirectSite#0" }
$allTenantSites.count
$allTenantSites = $allTenantSites | ?{ $_.LockState -eq "Unlock" }
$allTenantSites.count
$allTenantSites = $allTenantSites | ?{ $_.Status -eq "Active" }
$allTenantSites.count
$allTenantSites = $allTenantSites | ?{ $_.ArchiveStatus -eq "NotArchived" }
$allTenantSites.count

$randomSites1 = $allTenantSites | Get-Random -Count $randomSetSize
$orphanUserEntries1 = Get-OrphanUserEntries -Sites $randomSites1 -ConnectionAdmin $connectionAdmin
Write-Host "Orphan user entries from scan 1: $($orphanUserEntries1.Count)"
# $orphanUserEntries1 | Format-Table -Property UPN, Url, AccountEnabled
$orphanUser1 = $orphanUserEntries1 | select-object -Property UPN -ExpandProperty UPN -Unique    
Write-Host "Unique orphan users from scan 1: $($orphanUser1.count)"

$randomSites2 = $allTenantSites | Get-Random -Count $randomSetSize
$orphanUserEntries2 = Get-OrphanUserEntries -Sites $randomSites2 -ConnectionAdmin $connectionAdmin
Write-Host "Orphan user entries from scan 2: $($orphanUserEntries2.Count)"  
# $orphanUserEntries2 | Format-Table -Property UPN, Url, AccountEnabled
$orphanUser2 = $orphanUserEntries2 | select-object -Property UPN -ExpandProperty UPN -Unique    
Write-Host "Unique orphan users from scan 2: $($orphanUser2.count)"

# how many orphan users from scan 2 were already detected in scan 1
$orphanUser2PreviouslyDetected = $orphanUser2 | Where-Object { $orphanUser1 -contains $_ }
Write-Host "Orphan users from scan 2 previously detected in scan 1: $($orphanUser2PreviouslyDetected.count)"









Write-Host "Total sites in tenant: $($allTenantSites.count)"
Write-Host "Total orphan users-sites pairs found: $($orphanUserEntries.count)"
$orphanUsers = $orphanUserEntries | select-object -Property LoginName -ExpandProperty LoginName -Unique
Write-Host "Total unique orphan users found: $($orphanUsers.count)"
$sitesWithorphanUsers = $orphanUserEntries | select-object -Property SiteUrl -ExpandProperty SiteUrl -Unique
Write-Host "Total sites with orphan users found: $($sitesWithorphanUsers.count)"    

$PnPEntraIDUsers = Get-PnPEntraIDUsers -Connection $connectionAdmin -Identity $upn    
Write-Host "PnP Entra ID Users: " $PnPEntraIDUsers.count





