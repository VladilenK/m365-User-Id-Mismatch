# This script use "brute force" approach to scan tenant for orphan users
# "Orphan User" in SharePoint refers to a user account that no longer exists in the Entra Id but still has present in the User Information List on SharePoint sites.
# As idividual orphan user can appear at any site, this script scans all sites to identify such users.

# Prerequisites
# - Install the PnP.PowerShell module
# - Register an app in Azure AD with appropriate permissions to access SharePoint sites and read user information from Entra Id

# Authentication section. An app with appropriate permissions is required to access all sites and their user information lists.
# Uncomment and specify the values for your tenant and app registration.
# $tenantId = ""
# $adminUrl = ""
# $clientid = ""
# $thumbPrint = ""

$connectionAdmin = Connect-PnPOnline -ReturnConnection -Url $adminUrl -ClientId $ClientId -Thumbprint $Thumbprint -Tenant $tenantId
$connectionAdmin.Url

$allTenantSites = Get-PnPTenantSite -Connection $connectionAdmin -IncludeOneDriveSites 
$allTenantSites.count

$site = $allTenantSites[-1]
$site = $allTenantSites | ?{ $_.Url -eq "https://jvkdev.sharepoint.com/sites/Test-02" }
$site = $allTenantSites[0]
$site
$orphanUsers = [System.Collections.Generic.List[PSObject]]::new()
foreach ($site in $allTenantSites) {
    Write-Host "Scanning site: $($site.Url)"
    $connectionSite = Connect-PnPOnline -ReturnConnection -Url $site.Url -ClientId $ClientId -Thumbprint $Thumbprint -Tenant $tenantId
    $allUILEntries = Get-PnPUser -Connection $connectionSite
    $allUsers = $allUILEntries | ?{ $_.LoginName -like "i:0#.f|membership|*" }
    # $user = $allUsers[1]; $user | fl
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
            $orphanUsers.Add($user)
        }
    }
}



$orphanUsers.count
$orphanUsers | Format-Table -Property Title, SiteUrl -AutoSize

