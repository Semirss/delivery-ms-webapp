$ErrorActionPreference = "Stop"

# Create Client App
Write-Host "Creating client app..."
New-Item -ItemType Directory -Force -Path "client_app\client_app"
Copy-Item -Path "starter_temp\app_starter\*" -Destination "client_app\client_app" -Recurse -Force
New-Item -ItemType Directory -Force -Path "client_app\client_ui"
Copy-Item -Path "starter_temp\flutter_ui\*" -Destination "client_app\client_ui" -Recurse -Force

# Create Driver App
Write-Host "Creating driver app..."
New-Item -ItemType Directory -Force -Path "driver_app\driver_app"
Copy-Item -Path "starter_temp\app_starter\*" -Destination "driver_app\driver_app" -Recurse -Force
New-Item -ItemType Directory -Force -Path "driver_app\driver_ui"
Copy-Item -Path "starter_temp\flutter_ui\*" -Destination "driver_app\driver_ui" -Recurse -Force

function Replace-In-Files {
    param (
        [string]$Path,
        [string]$Search,
        [string]$Replace
    )
    Get-ChildItem -Path $Path -Recurse -File -Include *.dart, *.yaml, *.xml, *.kt, *.kts, *.md, *.plist | ForEach-Object {
        $content = Get-Content -Path $_.FullName -Raw
        if ($content -match $Search) {
            $newContent = $content -replace $Search, $Replace
            Set-Content -Path $_.FullName -Value $newContent -NoNewline
        }
    }
}

# Client Replacements
Write-Host "Replacing client app names..."
Replace-In-Files -Path "client_app" -Search "app_starter" -Replace "client_app"
Replace-In-Files -Path "client_app" -Search "flutter_ui" -Replace "client_ui"
Replace-In-Files -Path "client_app" -Search "com.example.flutter_boilerplate" -Replace "com.delivery.client"
Replace-In-Files -Path "client_app" -Search "com.example.app_starter" -Replace "com.delivery.client"
Replace-In-Files -Path "client_app" -Search "MyApp" -Replace "ClientApp"

# Driver Replacements
Write-Host "Replacing driver app names..."
Replace-In-Files -Path "driver_app" -Search "app_starter" -Replace "driver_app"
Replace-In-Files -Path "driver_app" -Search "flutter_ui" -Replace "driver_ui"
Replace-In-Files -Path "driver_app" -Search "com.example.flutter_boilerplate" -Replace "com.delivery.driver"
Replace-In-Files -Path "driver_app" -Search "com.example.app_starter" -Replace "com.delivery.driver"
Replace-In-Files -Path "driver_app" -Search "MyApp" -Replace "DriverApp"

Write-Host "Done!"
