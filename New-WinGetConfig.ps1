
# PowerShell script to create or update a WinGet configuration file
param (
  [string]$AppList = $(Read-Host -Prompt 'Enter a comma-separated list of applications (optional)'),
  [string]$TargetOS = $(Read-Host -Prompt 'Enter the target OS version (e.g., 10.0.22000, optional)'),
  [string]$SavePath = $(Read-Host -Prompt 'Enter the full path to save the configuration file (optional)'),
  [string]$Version = $(Read-Host -Prompt 'Enter the version override, ie nothing "" or "latest", "pre-release"')
)
# Function to check if WinGet is installed
function Test-WinGetInstalled {
  $wingetPath = Get-Command 'winget' -ErrorAction SilentlyContinue
  if (-not $wingetPath) {
    Write-Error "WinGet is not installed or not in the system path. Please install WinGet to use this script."
    exit
  }
}

# Validate Applications List
function Test-AppList {
  param ([string]$AppList)
  $validatedApps = @()
  $apps = $AppList -split ',' | ForEach-Object { $_.Trim() }

  foreach ($app in $apps) {
    $exists = winget search $app -e | Out-String
    if (-not $exists) {
      Write-Warning "Application '$app' not found in WinGet repository."
    }
    else {
      $validatedApps += $app
    }
  }

  return $validatedApps -join ','
}

function Test-TargetOS {
  param ([string]$TargetOS)
  # Implement validation logic
  # ...
  return $TargetOS
}

# Validate and Prepare Save Path
function Test-SavePath {
  param ([string]$SavePath)
    $saveDirectory = Split-Path -Path $SavePath -Parent

    if (-not (Test-Path -Path $saveDirectory)) {
        try {
            New-Item -Path $saveDirectory -ItemType Directory -Force | Out-Null
            Write-Host "Created directory: $saveDirectory"
        } catch {
            Write-Error "Failed to create directory: $saveDirectory. Error: $_"
            exit
        }
    }

    return $SavePath
  return $SavePath
}

function New-WinGetConfig {
  param (
    [string]$AppList,
    [string]$TargetOS,
    [string]$SavePath
  )

  # YAML content for the configuration file
  $yamlContent = @"
# yaml-language-server: $schema=https://aka.ms/configuration-dsc-schema/0.2
properties:
  assertions:
    - resource: Microsoft.Windows.Developer/OsVersion
      directives:
        description: Verify min OS version requirement
        allowPrerelease: true
      settings:
        MinVersion: '$TargetOS'
  resources:
"@

  # Add each app to the YAML content
  foreach ($app in $apps) {
    $yamlContent += @"
    - resource: Microsoft.WinGet.DSC/WinGetPackage
      directives:
        description: Install $app
        allowPrerelease: true
      settings:
        id: $app
        source: winget
"@
  }

  $yamlContent += "  configurationVersion: 0.2.0`n"

  # Save the YAML content to the specified file path
  $yamlContent | Out-File -FilePath $SavePath -Encoding UTF8

  # Verify the file using WinGet
  winget validate --manifest $SavePath
}

Test-WinGetInstalled

# Validate and set default values if necessary
$AppList = Test-AppList -AppList $AppList
$TargetOS = Test-TargetOS -TargetOS $TargetOS
$SavePath = Test-SavePath -SavePath $SavePath


# Call the function with validated parameters
New-WinGetConfig -AppList $AppList -TargetOS $TargetOS -SavePath $SavePath
