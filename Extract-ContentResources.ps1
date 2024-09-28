# Load necessary assembly for working with zip files
Add-Type -AssemblyName System.IO.Compression.FileSystem

try {
    # Execute the Detect-StarfieldFolder.ps1 script and capture the output
    $starfieldFolder = & ".\Detect-StarfieldFolder.ps1"
    $starfieldFolder = $starfieldFolder.Trim()

    # Remove any leading and trailing quotes
    $starfieldFolder = $starfieldFolder.Trim('"')

    if ([string]::IsNullOrEmpty($starfieldFolder)) {
        throw "Failed to retrieve the Starfield folder path."
    }
} catch {
    Write-Error "Error detecting Starfield folder: $_"
    exit 1
}

# Define the paths for the zip file and the destination folder
$zipFilePath = Join-Path $starfieldFolder "Tools\ContentResources.zip"
$destinationFolder = Join-Path $starfieldFolder "Data\Scripts\Source"

# Check if the zip file exists
if (!(Test-Path $zipFilePath)) {
    Write-Error "Zip file not found at path: $zipFilePath"
    exit 1
}

# Ensure the destination folder exists
if (!(Test-Path $destinationFolder)) {
    New-Item -ItemType Directory -Path $destinationFolder -Force | Out-Null
}

# Open the zip file
$zip = [System.IO.Compression.ZipFile]::OpenRead($zipFilePath)

# Iterate over each entry in the zip file
foreach ($entry in $zip.Entries) {
    # Check if the entry is a .psc file
    if ($entry.FullName -like "*.psc") {
        # Flatten the path by using only the file name
        $outputPath = Join-Path $destinationFolder $entry.Name

        # Extract the .psc file to the destination folder
        try {
            $entryStream = $entry.Open()
            $destinationFileStream = [System.IO.File]::Create($outputPath)
            $entryStream.CopyTo($destinationFileStream)
        }
        finally {
            if ($entryStream) { $entryStream.Dispose() }
            if ($destinationFileStream) { $destinationFileStream.Dispose() }
        }
    }
}

# Dispose of the zip file object
$zip.Dispose()

Write-Host "Extraction of .psc files completed successfully."
