<#
  .SYNOPSIS
  This Script is intended to be used with M365 Enterprise Demo tenants to assign different Azure AD Built-in roles to different users
  
  .DESCRIPTION
  This Script is intended to be used with M365 Enterprise Demo tenants
  The whole idea behind it is to assign different Azure AD Built-in roles to different users
  This is useful to test different scenarios where it would be better not to use a can-do-all user like Global Administrator
  Some users have more than one role as I would like all Administrative users to also have the licenses provided by the Demo tenant.
  Contributions are very well welcomed!
  Version: 0.1
  .NOTES
  Author: Andrés Gorzelany https://github.com/get-itips
  Contains error handling portions by Robert Dyjas https://github.com/robdy
  It takes a .csv file as input, this file can be customized to fit your environment.
  .EXAMPLE
  Customize-M365EnterpriseDemo.ps1
#>

# ================
#region Variables
# ================
$usersAndRolesCSV="userAndRoles.csv"
$globalAdministratorGuid="8c5d3d19-b733-4311-8e7e-8f87e8f3da1a"
$usersToDemote = @('Allan Deyoung','Isaiah Langer','Lidia Holloway','Nestor Wilke')
$unassignedLicenseUser="BiancaP"
$planName="ENTERPRISEPACK"
$azADModuleName="AzureADPreview"
# ================
#endregion Variables
# ================

# ================
#region Processing
# ================
try {
	$ErrorActionPreference = 'Stop'
	$startTime = Get-Date
	Write-Host "Starting script at $startTime"
	Import-Module -Name $azADModuleName
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
		New-AzureADMSRoleAssignment -DirectoryScopeId '/' -RoleDefinitionId $roleDefinition.Id -PrincipalId (Get-AzureADUser -Filter "MailNickName eq '$user'").objectId -ResourceScope '/'
	}

	#There is an unassigned E3 license, let's assign it to one of our administrators


	$License = New-Object -TypeName Microsoft.Open.AzureAD.Model.AssignedLicense
	$License.SkuId = (Get-AzureADSubscribedSku | Where-Object -Property SkuPartNumber -Value $planName -EQ).SkuID
	$LicensesToAssign = New-Object -TypeName Microsoft.Open.AzureAD.Model.AssignedLicenses
	$LicensesToAssign.AddLicenses = $License
	$user=Get-AzureADUser -Filter "MailNickName eq '$unassignedLicenseUser'"
	Set-AzureADUserLicense -ObjectId $user.UserPrincipalName -AssignedLicenses $LicensesToAssign

} catch {
	$err = $_
	Write-Host "ERROR at $($err.ScriptStackTrace)"
	Write-Host $err.Exception.Message
  } finally {
	$endTime = Get-Date
	$processedInSeconds = [math]::round(($endTime - $startTime).TotalSeconds)
	Write-Host "Script finished in $processedInSeconds seconds"
	# Uncomment for debugging
	# Write-Host $currentContent
  }

# ================
#endregion Processing
# ================

