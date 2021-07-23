$TenantDomain=Read-Host "Enter the 365 domain name, for example M365x931694.OnMicrosoft.com"
Import-Module -Name AzureADPreview
Connect-azuread
$user = Get-AzureADUser -Filter "userPrincipalName eq 'user@contoso.com'"


# Remove GA from some users, we already have MOD and Megan with that Role
$globalAdministratorGuid="8c5d3d19-b733-4311-8e7e-8f87e8f3da1a"
$usersToDemote = @('Allan Deyoung','Isaiah Langer','Lidia Holloway','Nestor Wilke')

foreach($user in $usersToDemote)
{
	Remove-AzureADDirectoryRoleMember -ObjectId $globalAdministratorGuid -MemberId (Get-AzureADUser -Filter "DisplayName eq '$user'").objectId
}

# Let's make a Teams Administrator
ChristieC@M365x937694.OnMicrosoft.com

$roleDefinition = Get-AzureADMSRoleDefinition -Filter "displayName eq 'Teams Administrator'"

$roleAssignment = New-AzureADMSRoleAssignment -DirectoryScopeId '/' -RoleDefinitionId $roleDefinition.Id -PrincipalId $user.objectId -ResourceScope '/'
