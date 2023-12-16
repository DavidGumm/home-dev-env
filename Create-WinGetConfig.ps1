# PowerShell script to create a basic WinGet configuration file with optional interactive mode

param (
    [string]$AppList = $(Read-Host -Prompt 'Enter a comma-separated list of applications (Leave blank for interactive input)'),
    [string]$TargetOS = $(Read-Host -Prompt 'Enter the target OS version (e.g., 10.0.22000, leave blank for interactive input)'),
    [string]$SavePath = $(Read-Host -Prompt 'Enter the full path to save the configuration file (Leave blank for interactive input)')
)

# Function to create a WinGet configuration file
function Create-WinGetConfig {
    param (
        [string]$AppList,
        [string]$TargetOS,
        [string]$SavePath
    )

    # Check if interactive input is needed
    if (-not $AppList) {
        $AppList = Read-Host -Prompt 'Enter a comma-separated list of applications'
    }
    if (-not $TargetOS) {
        $TargetOS = Read-Host -Prompt 'Enter the target OS version (e.g., 10.0.22000)'
    }
    if (-not $SavePath) {
        $SavePath = Read-Host -Prompt 'Enter the full path to save the configuration file'
    }

    # Split the comma-separated list of applications
    $apps = $AppList -split ',' | ForEach-Object { $_.Trim() }

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

# Create the configuration file
Create-WinGetConfig -AppList $AppList -TargetOS $TargetOS -SavePath $SavePath
