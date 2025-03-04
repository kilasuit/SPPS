#----------------------------------------------------------------------------- 
# Filename : spps.usersandgroups.ps1 
#----------------------------------------------------------------------------- 
# Author : Jeffrey Paarhuis
#----------------------------------------------------------------------------- 
# Contains methods to manage users, groups and permissions.

function Set-ListPermissions
{
	[CmdletBinding()]
	param
	(	
		[Parameter(Mandatory=$true, Position=1)]
		[string]$groupname,

		[Parameter(Mandatory=$true, Position=2)]
		[string]$listname,

		[Parameter(Mandatory=$true, Position=3)]
		[string]$roleType
	)

	process
	{
		Write-Host "Creating permissions for list $listname for the group $groupname and role $roleType" -foregroundcolor black -backgroundcolor yellow

		# Try getting the SPWeb object

        $web = $Spps.Web

        # get the Role
        $roleTypeObject = [Microsoft.SharePoint.Client.RoleType]$roleType
        $role = Get-SPRole $roleTypeObject

        # get the group principal object
        $group = Get-Group $groupname
 
        # get the list
        $list = $web.Lists.GetByTitle($listname)


        # calling nongeneric method Spps.Load(list, x => x.HasUniqueRoleAssignments)
        $method = [Microsoft.Sharepoint.Client.ClientContext].GetMethod("Load")
        $loadMethod = $method.MakeGenericMethod([Microsoft.Sharepoint.Client.List])

        $parameter = [System.Linq.Expressions.Expression]::Parameter(([Microsoft.SharePoint.Client.List]), "x")
        $expression = [System.Linq.Expressions.Expression]::Lambda([System.Linq.Expressions.Expression]::Convert([System.Linq.Expressions.Expression]::Property($parameter, ([Microsoft.SharePoint.Client.List]).GetProperty("HasUniqueRoleAssignments")), ([System.Object])), $($parameter))
        $expressionArray = [System.Array]::CreateInstance($expression.GetType(), 1)
        $expressionArray.SetValue($expression, 0)

        $loadMethod.Invoke( $Spps, @( $list, $expressionArray ) )


        $Spps.ExecuteQuery()
 
        # break the inheritance if not done already
        if (-not $list.HasUniqueRoleAssignments)
        {
            $list.BreakRoleInheritance($false, $false) # don't keep the existing permissions and don't clear listitems permissions
        }

        $Spps.ExecuteQuery()
 
        # create the role definition binding collection
        $rdb = New-Object Microsoft.SharePoint.Client.RoleDefinitionBindingCollection($Spps)
 
        # add the role definition to the collection
        $rdb.Add($role)
 
        # create a RoleAssigment with the group and role definition
        $ra = $list.RoleAssignments.Add($group, $rdb)
 
        # execute the query to add everything
        $Spps.ExecuteQuery()		

		Write-Host "Succesfully created permissions" -foregroundcolor black -backgroundcolor green
	}
}

function Set-DocumentPermissions
{
	[CmdletBinding()]
	param
	(	
		[Parameter(Mandatory=$true, Position=1)]
		[string]$groupname,

		[Parameter(Mandatory=$true, Position=2)]
		[string]$listname,

        [Parameter(Mandatory=$true, Position=3)]
        [string]$listItemName,

		[Parameter(Mandatory=$true, Position=4)]
		[string]$roleType
	)

	process
	{
		Write-Host "Creating permissions for document $listItemName in list $listname for the group $groupname and role $roleType" -foregroundcolor black -backgroundcolor yellow

		# Try getting the SPWeb object

        $web = $Spps.Web

        # get the Role
        $roleTypeObject = [Microsoft.SharePoint.Client.RoleType]$roleType
        $role = Get-SPRole $roleTypeObject

        # get the group principal object
        $group = Get-Group $groupname
 
        # get the list
        $list = $web.Lists.GetByTitle($listname)


        $camlQuery = new-object Microsoft.SharePoint.Client.CamlQuery
        $camlQuery.ViewXml = "<View><Query><Where><Eq><FieldRef Name='FileLeafRef' /><Value Type='Text'>$listItemName</Value></Eq></Where></Query></View>"

        $listItems = $list.GetItems($camlQuery)


        
        $Spps.Load($listItems)
        $Spps.ExecuteQuery()

        if ($listItems.Count -gt 0)
        {
            
            $listItem = $listItems[0]

            $Spps.Load($listItem)
            $Spps.ExecuteQuery()


            # calling nongeneric method Spps.Load(list, x => x.HasUniqueRoleAssignments)
            $method = [Microsoft.Sharepoint.Client.ClientContext].GetMethod("Load")
            $loadMethod = $method.MakeGenericMethod([Microsoft.Sharepoint.Client.ListItem])

            $parameter = [System.Linq.Expressions.Expression]::Parameter(([Microsoft.SharePoint.Client.ListItem]), "x")
            $expression = [System.Linq.Expressions.Expression]::Lambda([System.Linq.Expressions.Expression]::Convert([System.Linq.Expressions.Expression]::Property($parameter, ([Microsoft.SharePoint.Client.ListItem]).GetProperty("HasUniqueRoleAssignments")), ([System.Object])), $($parameter))
            $expressionArray = [System.Array]::CreateInstance($expression.GetType(), 1)
            $expressionArray.SetValue($expression, 0)

            $loadMethod.Invoke( $Spps, @( $listItem, $expressionArray ) )

            $Spps.ExecuteQuery()


            # break the inheritance if not done already
            if (-not $listItem.HasUniqueRoleAssignments)
            {
                $listItem.BreakRoleInheritance($false, $false) # don't keep the existing permissions and don't clear listitems permissions
            }

            $Spps.ExecuteQuery()
 
            # create the role definition binding collection
            $rdb = New-Object Microsoft.SharePoint.Client.RoleDefinitionBindingCollection($Spps)
 
            # add the role definition to the collection
            $rdb.Add($role)
 
            # create a RoleAssigment with the group and role definition
            $ra = $listItem.RoleAssignments.Add($group, $rdb)
 
            # execute the query to add everything
            $Spps.ExecuteQuery()		

			Write-Host "Succesfully created permissions" -foregroundcolor black -backgroundcolor green

        } else {
			Write-Host "Item $listItemName could not be found" -foregroundcolor black -backgroundcolor red
        }
	}
}

function Set-WebPermissions
{
	[CmdletBinding()]
	param
	(	
		[Parameter(Mandatory=$true, Position=1)]
		[string]$groupname,

		[Parameter(Mandatory=$true, Position=2)]
		[string]$roleType
	)

	process
	{
		Write-Host "Creating permissions for the web for the group $groupname and role $roleType" -foregroundcolor black -backgroundcolor yellow
		

		# Try getting the SPWeb object

        $web = $Spps.Web

        # get the Role
        $roleTypeObject = [Microsoft.SharePoint.Client.RoleType]$roleType
        $role = Get-SPRole $roleTypeObject

        # get the group principal object
        $group = Get-Group $groupname

        # create the role definition binding collection
        $rdb = New-Object Microsoft.SharePoint.Client.RoleDefinitionBindingCollection($Spps)
 
        # add the role definition to the collection
        $rdb.Add($role)
 
        # create a RoleAssigment with the group and role definition
        $ra = $web.RoleAssignments.Add($group, $rdb)
 
        # execute the query to add everything
        $Spps.ExecuteQuery()	

		Write-Host "Succesfully created permissions" -foregroundcolor black -backgroundcolor green
	}
}

Function Get-SPRole
{
	[CmdletBinding()]
	param
	(
		[Parameter(Mandatory=$true, Position=1)]
		[Microsoft.SharePoint.Client.RoleType]$rType
	)

	$web = $Spps.Web
	if ($web -ne $null)
	{
	 $roleDefs = $web.RoleDefinitions
	 $Spps.Load($roleDefs)
	 $Spps.ExecuteQuery()
	 $roleDef = $roleDefs | where {$_.RoleTypeKind -eq $rType}
	 return $roleDef
	}
	return $null
}

Function Get-Group
{
	[CmdletBinding()]
	param
	(
		[Parameter(Mandatory=$true, Position=1)]
		[string]$name
	)

	
		$groups = $web.SiteGroups
		$Spps.Load($groups)
		$Spps.ExecuteQuery()
		$Global:group = $groups | where {$_.Title -eq $name}
        $spps.Load($group)
        $spps.ExecuteQuery()
}

function Add-Group
{
	[CmdletBinding()]
	param
	(	

		[Parameter(Mandatory=$true, Position=1)]
		[string]$name
	)

	process
	{
		Write-Host "Create SharePoint group $name" -foregroundcolor black -backgroundcolor yellow

        $groupCreation = new-object Microsoft.SharePoint.Client.GroupCreationInformation
        $groupCreation.Title = $name

        try {
            
			$group = $Spps.Web.SiteGroups.Add($groupCreation)
			$Spps.ExecuteQuery()
			Write-Host "SharePoint group succesfully created" -foregroundcolor black -backgroundcolor green
			
		} catch {

			Write-Host "Group already exists" -foregroundcolor black -backgroundcolor yellow
			
        }
	}
}

Function Get-Principal
{
	[CmdletBinding()]
	param
	(
		[Parameter(Mandatory=$true, Position=1)]
		[string]$username
	)
	
	$principal = $Spps.Web.EnsureUser($username)

	$Spps.Load($principal)
	$Spps.ExecuteQuery()
	
	return $principal
}

function Add-PrincipalToGroup
{
	<#
	.SYNOPSIS
		Adds users or security groups to a SharePoint group
	.DESCRIPTION
		Adds users or security groups to a SharePoint group
	.PARAMETER username
		Username of the user or group including the domain. E.g. DOMAIN\User
	.PARAMETER groupname
		Name of the SharePoint group
	#>
	[CmdletBinding()]
	param
	(	
		[Parameter(Mandatory=$true, Position=1)]
		[string]$username,
		
		[Parameter(Mandatory=$true, Position=1)]
		[string]$groupname
	)

	process
	{
		Write-Host "Adding principal with username $username to group $groupname" -foregroundcolor black -backgroundcolor yellow

        $principal = Get-Principal -username $username

		$group = Get-Group -name $groupname
		
		$userExists = $group.Users.GetById($principal.Id)
		$Spps.Load($userExists)
		
		try
		{
			$Spps.ExecuteQuery()
			
			# If no error then the principal already exists in the group
			
			Write-Host "Principal already added to the group" -foregroundcolor black -backgroundcolor yellow
			
		} 
		catch
		{
			# Error thrown that user doesn't exist
			
			$addedPrincipal = $group.Users.AddUser($principal)
		
			$Spps.Load($addedPrincipal)
			$Spps.ExecuteQuery()
			
			Write-Host "Succesfully added principal to the group" -foregroundcolor black -backgroundcolor green
		}
		
		
	}
}