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

$randomSetSizeMin = 100 # sites
$randomSetSizeMax = 1000 # sites

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
# $allTenantSites.count

Write-Host "Total sites in tenant: $($allTenantSites.count)"

if (!$randomSetSize) {
    $randomSetSize = [Math]::Max($randomSetSizeMin, $allTenantSites.Count/50)
    $randomSetSize = [Math]::Min($randomSetSizeMax, $randomSetSize)
}
Write-Host "Random set size for scanning: $randomSetSize"

$randomSites1 = $allTenantSites | Get-Random -Count $randomSetSize
$orphanUserEntries1 = Get-OrphanUserEntries -Sites $randomSites1 -ConnectionAdmin $connectionAdmin
Write-Host "Orphan user entries from scan 1: $($orphanUserEntries1.Count)"
# $orphanUserEntries1 | Format-Table -Property UPN, Url, AccountEnabled
$orphanUser1 = $orphanUserEntries1 | select-object -Property UPN -ExpandProperty UPN -Unique    
if ($orphanUser1.Count -eq 0) {
    Write-Host "No orphan users detected during scan 1. Exiting script."
    exit
}
Write-Host "Unique orphan users from scan 1: $($orphanUser1.count)"

$randomSites2 = $allTenantSites | Get-Random -Count $randomSetSize
$orphanUserEntries2 = Get-OrphanUserEntries -Sites $randomSites2 -ConnectionAdmin $connectionAdmin
Write-Host "Orphan user entries from scan 2: $($orphanUserEntries2.Count)"  
# $orphanUserEntries2 | Format-Table -Property UPN, Url, AccountEnabled
$orphanUser2 = $orphanUserEntries2 | select-object -Property UPN -ExpandProperty UPN -Unique    
if ($orphanUser2.Count -eq 0) {
    Write-Host "No orphan users detected during scan 2. Exiting script."
    exit
}
Write-Host "Unique orphan users from scan 2: $($orphanUser2.count)"

# how many orphan users from scan 2 were already detected in scan 1
$orphanUser2PreviouslyDetected = $orphanUser2 | Where-Object { $orphanUser1 -contains $_ }
Write-Host "Orphan users from scan 2 previously detected in scan 1: $($orphanUser2PreviouslyDetected.count)"

# use Chao2
$chao2Estimate = ($orphanUser1.count * $orphanUser2.count) / ($orphanUser2PreviouslyDetected.count)
Write-Host "Chao2 estimate of orphan users in the tenant: $([int]$chao2Estimate)"

# use my own estimation method based on the number of sites
$myEstimate = 3000*[Math]::Pow(($allTenantSites.count), 0.376)
Write-Host "My estimate of orphan users in the tenant: $([int]$myEstimate)"

[Math]::Pow($myEstimate * $chao2Estimate, 0.5)
Write-Host "Combined estimate of orphan users in the tenant: $([int][Math]::Pow($myEstimate * $chao2Estimate, 0.5))"

Write-Host "Total sites in tenant: $($allTenantSites.count)"
$PnPEntraIDUsers = Get-PnPEntraIDUser -Connection $connectionAdmin 
Write-Host "PnP Entra ID Users count: " $PnPEntraIDUsers.count





