# WIP
# 
# Orphan users in SharePoint Online are users who exist in SharePoint sites but not in Entra ID
# User Id Mismatch issue occurs when a new user gets a UPN that matches one of orphan users 
# Scanning Microsoft 365 tenant for orphan users could be time-consuming depending on tenant size
# This script estitimates number of orphan users in SharePoint Online by using Species-Area Relationship (SAR) method
# The script
# - gets all tenant sites, and selects N random sites to scan for orphan users
# - retrieves all users from the selected sites, 
# - identifies unique orphan users 
# - gets another N random sites and repeats the scanning process
# - identifies unique orphan users on 2xN sites
# - gets another 2xN random sites and repeats the scanning process
# - identifies unique orphan users on 4xN sites, and so on
# - do the same 5 times
# - use Arrenius formula for estimating the total number of orphan users in the tenant

$totalTenantSites = 700000
$randomSetSize = 2
# total scanned sites would be 16x the random set size
# e.g. if random set size is 50, total scanned sites would be 16x50 = 800
$iterations = 5

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

Write-Host "Random set size for scanning: $randomSetSize"
Write-Host "Iterations for scanning: $iterations"


$results = @()
$randomSitesCount = $randomSetSize
$cumulativeScannedSitesCount = 0
$cumulativeOrphanUser = @()
for ($i = 1; $i -le $iterations; $i++) {
    Write-Host "Random sites count for scan $i :" $randomSitesCount
    $randomSites = $allTenantSites | Get-Random -Count $randomSitesCount
    $orphanUserEntries = Get-OrphanUserEntries -Sites $randomSites 
    $orphanUser = $orphanUserEntries | select-object -Property UPN -ExpandProperty UPN -Unique    
    Write-Host "Unique orphan users from scan $i :" $($orphanUser.count)
    $cumulativeOrphanUser += $orphanUser; 
    $cumulativeOrphanUser = $cumulativeOrphanUser | Select-Object -Unique
    Write-Host "Cumulative unique orphan users after scan $i :" $($cumulativeOrphanUser.count)
    $cumulativeScannedSitesCount += $randomSites.Count
    $results += [PSCustomObject]@{
        Scan = $i
        SitesCount = $randomSites.Count
        CumulativeSitesCount = $cumulativeScannedSitesCount
        UniqueOrphanUsersCount = $orphanUser.Count
        CumulativeUniqueOrphanUsersCount = $cumulativeOrphanUser.count
    }
    $randomSitesCount = $randomSetSize*[Math]::Pow(2, $i-1) 
}

$results | ft -AutoSize

# LOGARITHMIC LINEAR REGRESSION (Calculates z and c)
$logA = @()
$logS = @()

foreach ($cp in $results) {
    $logA += [Math]::Log($cp.SitesCount)
    $logS += [Math]::Log($cp.UniqueOrphanUsersCount)
}

# Calculate means
$meanLogA = ($logA | Measure-Object -Average).Average
$meanLogS = ($logS | Measure-Object -Average).Average

# Calculate slope (z) and intercept (ln_c)
$numerator = 0
$denominator = 0

for ($i = 0; $i -lt $results.Count; $i++) {
    $diffA = $logA[$i] - $meanLogA
    $diffS = $logS[$i] - $meanLogS
    
    $numerator += ($diffA * $diffS)
    $denominator += [Math]::Pow($diffA, 2)
}

$z = $numerator / $denominator
$ln_c = $meanLogS - ($z * $meanLogA)
$c = [Math]::Exp($ln_c)

# EXTRAPOLATION TO FULL TENANT SIZE

$c * [Math]::Pow($totalTenantSites, $z)

$lastCheckpoint = $results[-1]
$Asample = $lastCheckpoint.SitesCount
$Ssample = $lastCheckpoint.UniqueOrphanUsersCount

# Sampling ratio and dampened exponent
$samplingRatio = $Asample / $totalTenantSites
$dampenedExponent = $z * (1.0 - [Math]::Sqrt($samplingRatio))

# Extrapolate total orphans
$estimatedTotalOrphans = $Ssample * [Math]::Pow(($totalTenantSites / $Asample), $dampenedExponent)


