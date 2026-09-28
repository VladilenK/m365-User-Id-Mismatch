# Functions for the estimation of orphan users in a Microsoft 365 tenant

function Get-OrphanUserEntries {
    param (
        [Parameter(Mandatory = $true)]
        [PSObject[]]$Sites,
        [Parameter(Mandatory = $true)]
        $ConnectionAdmin
    )

    $orphanUserEntries = [System.Collections.Generic.List[PSObject]]::new()
    foreach ($site in $Sites) {
        # Write-Host "Scanning site: $($site.Url)"
        Write-Progress -Activity "Scanning sites for orphan users" -Status "Scanning $($site.Url)" -PercentComplete (($Sites.IndexOf($site) / $Sites.Count) * 100)
        $connectionSite = Connect-PnPOnline -ReturnConnection -Url $site.Url -ClientId $ClientId -Thumbprint $Thumbprint -Tenant $tenantId
        # Get-PnPSite -Connection $connectionSite
        $allUILEntries = Get-PnPUser -Connection $connectionSite
        $allUsers = $allUILEntries | ?{ $_.LoginName -like "i:0#.f|membership|*" }
        foreach ($user in $allUsers) {
            $upn = $user.LoginName.Split("|")[-1]
            $userExists = $null
            $AccountEnabled = $null
            try {
                $userExists = Get-PnPEntraIDUser -Connection $ConnectionAdmin -Identity $upn    
                $AccountEnabled = $userExists.AccountEnabled
            }
            catch {
                $userExists = $false
            }
            if ((-not $userExists) -or (-not $AccountEnabled) ) {
                $orphanUserEntries.Add(
                    [PSCustomObject]@{
                        UPN = $upn
                        Url = $Site.Url
                        AccountEnabled = $AccountEnabled
                    }
                )
            }
        }
    }
    Write-Progress -Activity "Processing" -Completed
    return $orphanUserEntries
}
