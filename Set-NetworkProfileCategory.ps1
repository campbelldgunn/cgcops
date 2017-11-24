<#
.SYNOPSIS
    Changes the network profile category
.DESCRIPTION
    In 'Network and Sharing Center' your networks are shown as 'Public', "Private' or 'Domain'
    You can change that here in all supported versions of Windows
.PARAMETER NetworkName
    The name of the network
.PARAMETER Public
    Change to public
.PARAMETER Private
    Change to private
.PARAMETER Domain
    Change to domain type

.NOTES

    Author:  Campbell Gunn
    Created: November 24th, 2017 
    
.LINK
    https://github.com/campbelldgunn/
#>

[CmdletBinding(DefaultParameterSetName="list")]  
param(
  [parameter(Mandatory=$true,ParameterSetName="public")]
  [parameter(Mandatory=$true,ParameterSetName="domain")]
  [parameter(Mandatory=$true,ParameterSetName="private")]
  [string]$Name,
  [parameter(Mandatory=$true,ParameterSetName="public")]
  [switch]$public,
  [parameter(Mandatory=$true,ParameterSetName="private")]
  [switch]$private,
  [parameter(Mandatory=$true,ParameterSetName="domain")]
  [switch]$domain,
  [parameter(Mandatory=$false,ParameterSetName="list")]
  [switch]$list
  )

[int]$newCategory = -1

if ($public) {$newCategory = 0}
if ($private) {$newCategory = 1}
if ($domain) {$newCategory = 2}

# Public	0
# Private	1
# Domain	2
$types = "Public","Private","Domain"

$CurrentBuild = [int](get-itemproperty "HKLM:\Software\Microsoft\Windows NT\CurrentVersion").CurrentBuild 

Function Find-ProfileName([string]$term)
{
    $name = Check-ProfileName -term $term

    if ($name -ne "")
    {
        return $name
    }

    $term = $term -replace " ","  "
    $name = Check-ProfileName -term $term

    if ($name -ne "")
    {
        return $name
    }

    $term = $term -replace "  ","   "
    $name = Check-ProfileName -term $term

    if ($name -ne "")
    {
        return $name
    }

    return ""
}

Function Check-ProfileName([string]$term)
{
    $name = ""
    
    Write-Verbose "looking for `'$term`'"

    Get-ChildItem "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\NetworkList\Profiles" | foreach {

        $CurrentKey = Get-ItemProperty -Path $_.PsPath

        if ($CurrentKey.ProfileName -eq $term)
        {
            $name = $CurrentKey.ProfileName
        }
    }

    return $name
}

Function List()
{
    if ($CurrentBuild -lt 9600)
    {
        Get-ChildItem "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\NetworkList\Profiles" | foreach {

            $CurrentKey = Get-ItemProperty -Path $_.PsPath
            Write-Host "Name            : $($CurrentKey.ProfileName)"
            Write-Host "NetworkCategory : $($types[[int]$CurrentKey.Category])`r`n"
        }
    }
    else
    {
        Get-NetConnectionProfile
    }
    
    Write-Host "Specify -Name and a category to change a profile"

    exit 0
}

if ($newCategory -eq -1)
{
    List
}

$ProfileName = Find-ProfileName -term $Name

If ($ProfileName -eq "")
{
    Write-Warning "Network `'$Name`' not found"
}

if ($CurrentBuild -lt 9600)
{
    if ($newCategory -gt -1)
    {
        Get-ChildItem "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\NetworkList\Profiles" | foreach {

            $CurrentKey = Get-ItemProperty -Path $_.PsPath

            if ($CurrentKey.ProfileName -eq $ProfileName)
            {
                Write-Verbose $CurrentKey.ProfileName
                Set-ItemProperty -Path $_.PsPath -Name "Category" -Value $newCategory
                Write-Host "Changed profile for `'$($CurrentKey.ProfileName)`' to $($types[$newCategory])"
            }

        }
    }

    Write-Output "`n`rCurrent profiles:"

    Get-ChildItem "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\NetworkList\Profiles" | foreach {

        $CurrentKey = Get-ItemProperty -Path $_.PsPath
        Write-Host "$($CurrentKey.ProfileName) = $($types[[int]$CurrentKey.Category])"
    }

}
else
{
    if ($newCategory -gt -1)
    {
        $network = Get-NetConnectionProfile | Where Name -eq $ProfileName

        If ($public)
        {
            Set-NetConnectionProfile  -InterfaceIndex $network.InterfaceIndex -NetworkCategory Public
        }
        elseif ($private)
        {
            Set-NetConnectionProfile  -InterfaceIndex $network.InterfaceIndex -NetworkCategory Private
        }
        elseif ($domain)
        {
            Set-NetConnectionProfile  -InterfaceIndex $network.InterfaceIndex -NetworkCategory Domain
        }
    }

    Get-NetConnectionProfile | Where Name -eq $ProfileName

}