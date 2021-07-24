#Customize-M365EnterpriseDemo.ps1
#Author: Andrés Gorzelany
#Description:
# This Script is intended to be used with M365 Enterprise Demo tenants
# The whole idea behind it is to assign different Azure AD Built-in roles to different users
# This is useful to test different scenarios where it would be better not to use a can-do-all user like Global Administrator
# Some users have more than one role as I would like all Administrative users to also have the licenses provided by the Demo tenant.
# Contributions are very well welcomed!

# Some important variables
$usersAndRolesCSV="userAndRoles.csv"
$globalAdministratorGuid="8c5d3d19-b733-4311-8e7e-8f87e8f3da1a"
$usersToDemote = @('Allan Deyoung','Isaiah Langer','Lidia Holloway','Nestor Wilke')

$TenantDomain=Read-Host "Enter the 365 domain name, for example M365x931694.OnMicrosoft.com"
Import-Module -Name AzureADPreview
Connect-AzureAD

# Remove GA from some users, we already have MOD and Megan with that Role

foreach($user in $usersToDemote)
{
	Write-Host "Removing Global Administrator role from $user" 
	Remove-AzureADDirectoryRoleMember -ObjectId $globalAdministratorGuid -MemberId (Get-AzureADUser -Filter "DisplayName eq '$user'").objectId
}

# Let's make a some Administrators

$userAndRoles=Import-Csv -Delimiter ";" -Path $usersAndRolesCSV

foreach ($entry in $userAndRoles) {
	$role=$entry.role
	$user=$entry.username
	Write-Host "Making $user a $role"
	$roleDefinition = Get-AzureADMSRoleDefinition -Filter "displayName eq '$role'"
	#$roleDefinition
	New-AzureADMSRoleAssignment -DirectoryScopeId '/' -RoleDefinitionId $roleDefinition.Id -PrincipalId (Get-AzureADUser -Filter "MailNickName eq '$user'").objectId -ResourceScope '/'
}

#There is an unassigned E3 license, let's assign it to one of our administrators

$unassignedLicenseUser="BiancaP"
$planName="ENTERPRISEPACK"
$License = New-Object -TypeName Microsoft.Open.AzureAD.Model.AssignedLicense
$License.SkuId = (Get-AzureADSubscribedSku | Where-Object -Property SkuPartNumber -Value $planName -EQ).SkuID
$LicensesToAssign = New-Object -TypeName Microsoft.Open.AzureAD.Model.AssignedLicenses
$LicensesToAssign.AddLicenses = $License
$user=Get-AzureADUser -Filter "MailNickName eq '$unassignedLicenseUser'"
Set-AzureADUserLicense -ObjectId $user.UserPrincipalName -AssignedLicenses $LicensesToAssign


