param(
    [string]$TemplatePath = "C:\Users\hp\Downloads\data_safety_sample.csv",
    [string]$OutputDir = "playstore_data_safety"
)

$ErrorActionPreference = "Stop"

$privacyUrl = "https://www.motobikedeliveryservice.com/privacy-policy.html"

function Set-DirectValue {
    param(
        [object[]]$Rows,
        [string]$QuestionId,
        [string]$Value
    )

    foreach ($row in $Rows) {
        if ($row.'Question ID (machine readable)' -eq $QuestionId) {
            $row.'Response value' = $Value
        }
    }
}

function Set-ChoiceValue {
    param(
        [object[]]$Rows,
        [string]$QuestionId,
        [string]$ResponseId,
        [bool]$Selected
    )

    foreach ($row in $Rows) {
        if (
            $row.'Question ID (machine readable)' -eq $QuestionId -and
            $row.'Response ID (machine readable)' -eq $ResponseId
        ) {
            $row.'Response value' = if ($Selected) { "true" } else { "" }
        }
    }
}

function Set-DataTypeSelected {
    param(
        [object[]]$Rows,
        [string]$DataType
    )

    foreach ($row in $Rows) {
        if (
            $row.'Question ID (machine readable)'.StartsWith("PSL_DATA_TYPES_") -and
            $row.'Response ID (machine readable)' -eq $DataType
        ) {
            $row.'Response value' = "true"
        }
    }
}

function Set-Usage {
    param(
        [object[]]$Rows,
        [string]$DataType,
        [string[]]$CollectionPurposes,
        [string[]]$SharingPurposes = @(),
        [bool]$Required = $true
    )

    $prefix = "PSL_DATA_USAGE_RESPONSES:$DataType"
    Set-ChoiceValue $Rows "$prefix`:PSL_DATA_USAGE_COLLECTION_AND_SHARING" "PSL_DATA_USAGE_ONLY_COLLECTED" $true
    Set-ChoiceValue $Rows "$prefix`:PSL_DATA_USAGE_COLLECTION_AND_SHARING" "PSL_DATA_USAGE_ONLY_SHARED" ($SharingPurposes.Count -gt 0)
    Set-DirectValue $Rows "$prefix`:PSL_DATA_USAGE_EPHEMERAL" "false"

    Set-ChoiceValue $Rows "$prefix`:DATA_USAGE_USER_CONTROL" "PSL_DATA_USAGE_USER_CONTROL_REQUIRED" $Required
    Set-ChoiceValue $Rows "$prefix`:DATA_USAGE_USER_CONTROL" "PSL_DATA_USAGE_USER_CONTROL_OPTIONAL" (-not $Required)

    foreach ($purpose in $CollectionPurposes) {
        Set-ChoiceValue $Rows "$prefix`:DATA_USAGE_COLLECTION_PURPOSE" $purpose $true
    }

    foreach ($purpose in $SharingPurposes) {
        Set-ChoiceValue $Rows "$prefix`:DATA_USAGE_SHARING_PURPOSE" $purpose $true
    }
}

function ConvertTo-CsvField {
    param([object]$Value)

    if ($null -eq $Value) {
        return ""
    }

    $text = [string]$Value
    if ($text.Contains('"')) {
        $text = $text.Replace('"', '""')
    }

    if ($text.Contains(',') -or $text.Contains('"') -or $text.Contains("`r") -or $text.Contains("`n")) {
        return '"' + $text + '"'
    }

    return $text
}

function Export-PlayConsoleCsv {
    param(
        [object[]]$Rows,
        [string]$OutputPath
    )

    $headers = @(
        "Question ID (machine readable)",
        "Response ID (machine readable)",
        "Response value",
        "Answer requirement",
        "Human-friendly question label"
    )

    $lines = [System.Collections.Generic.List[string]]::new()
    $lines.Add(($headers -join ","))

    foreach ($row in $Rows) {
        $fields = foreach ($header in $headers) {
            ConvertTo-CsvField $row.$header
        }
        $lines.Add(($fields -join ","))
    }

    $utf8NoBom = [System.Text.UTF8Encoding]::new($false)
    [System.IO.File]::WriteAllLines($OutputPath, $lines, $utf8NoBom)
}

function New-DataSafetyFile {
    param(
        [string]$AppName,
        [string[]]$DataTypes,
        [hashtable]$Usages,
        [string]$OutputPath
    )

    $rows = Import-Csv -LiteralPath $TemplatePath

    foreach ($row in $rows) {
        $row.'Response value' = ""
    }

    Set-DirectValue $rows "PSL_DATA_COLLECTION_COLLECTS_PERSONAL_DATA" "true"
    Set-DirectValue $rows "PSL_DATA_COLLECTION_ENCRYPTED_IN_TRANSIT" "true"

    Set-ChoiceValue $rows "PSL_SUPPORTED_ACCOUNT_CREATION_METHODS" "PSL_ACM_USER_ID_PASSWORD" $true
    Set-ChoiceValue $rows "PSL_SUPPORTED_ACCOUNT_CREATION_METHODS" "PSL_ACM_USER_ID_OTHER_AUTH" $false
    Set-ChoiceValue $rows "PSL_SUPPORTED_ACCOUNT_CREATION_METHODS" "PSL_ACM_USER_ID_PASSWORD_OTHER_AUTH" $false
    Set-ChoiceValue $rows "PSL_SUPPORTED_ACCOUNT_CREATION_METHODS" "PSL_ACM_OAUTH" $false
    Set-ChoiceValue $rows "PSL_SUPPORTED_ACCOUNT_CREATION_METHODS" "PSL_ACM_OTHER" $false
    Set-ChoiceValue $rows "PSL_SUPPORTED_ACCOUNT_CREATION_METHODS" "PSL_ACM_NONE" $false
    Set-DirectValue $rows "PSL_ACM_SPECIFY" ""
    Set-DirectValue $rows "PSL_ACCOUNT_DELETION_URL" $privacyUrl
    Set-ChoiceValue $rows "PSL_SUPPORT_DATA_DELETION_BY_USER" "DATA_DELETION_YES" $false
    Set-ChoiceValue $rows "PSL_SUPPORT_DATA_DELETION_BY_USER" "DATA_DELETION_NO" $true
    Set-ChoiceValue $rows "PSL_SUPPORT_DATA_DELETION_BY_USER" "DATA_DELETION_NO_AUTO_DELETED" $false
    Set-DirectValue $rows "PSL_DATA_DELETION_URL" ""
    Set-DirectValue $rows "PSL_DATA_COLLECTION_COMPLIES_FAMILY_POLICY" ""
    Set-DirectValue $rows "PSL_INDEPENDENTLY_VALIDATED" ""
    Set-DirectValue $rows "PSL_UPI_BADGE_OPT_IN" ""
    Set-DirectValue $rows "PSL_HAS_OUTSIDE_APP_ACCOUNTS" ""
    Set-ChoiceValue $rows "PSL_OUTSIDE_APP_ACCOUNT_TYPES" "PSL_LOGIN_WITH_OUTSIDE_APP_ID" $false
    Set-ChoiceValue $rows "PSL_OUTSIDE_APP_ACCOUNT_TYPES" "PSL_LOGIN_THROUGH_EMPLOYMENT_OR_ENTERPRISE_ACCOUNT" $false
    Set-ChoiceValue $rows "PSL_OUTSIDE_APP_ACCOUNT_TYPES" "PSL_OUTSIDE_APP_ACCOUNT_TYPE_OTHER" $false
    Set-DirectValue $rows "PSL_OUTSIDE_APP_ACCOUNT_TYPE_SPECIFY" ""

    foreach ($dataType in $DataTypes) {
        Set-DataTypeSelected $rows $dataType
        $usage = $Usages[$dataType]
        if ($null -eq $usage) {
            throw "Missing usage configuration for $AppName data type $dataType"
        }

        Set-Usage `
            -Rows $rows `
            -DataType $dataType `
            -CollectionPurposes $usage.Collection `
            -SharingPurposes $usage.Sharing `
            -Required $usage.Required
    }

    Export-PlayConsoleCsv -Rows $rows -OutputPath $OutputPath
}

if (-not (Test-Path -LiteralPath $TemplatePath)) {
    throw "Template not found: $TemplatePath"
}

if (-not (Test-Path -LiteralPath $OutputDir)) {
    New-Item -ItemType Directory -Path $OutputDir | Out-Null
}

$appFunctionality = "PSL_APP_FUNCTIONALITY"
$analytics = "PSL_ANALYTICS"
$developerComms = "PSL_DEVELOPER_COMMUNICATIONS"
$fraudSecurity = "PSL_FRAUD_PREVENTION_SECURITY"
$accountManagement = "PSL_ACCOUNT_MANAGEMENT"

$clientTypes = @(
    "PSL_NAME",
    "PSL_EMAIL",
    "PSL_USER_ACCOUNT",
    "PSL_ADDRESS",
    "PSL_PHONE",
    "PSL_PURCHASE_HISTORY",
    "PSL_APPROX_LOCATION",
    "PSL_PRECISE_LOCATION",
    "PSL_PHOTOS",
    "PSL_CRASH_LOGS",
    "PSL_PERFORMANCE_DIAGNOSTICS",
    "PSL_USER_INTERACTION",
    "PSL_IN_APP_SEARCH_HISTORY",
    "PSL_USER_GENERATED_CONTENT",
    "PSL_OTHER_APP_ACTIVITY",
    "PSL_DEVICE_ID"
)

$driverTypes = @(
    "PSL_NAME",
    "PSL_EMAIL",
    "PSL_USER_ACCOUNT",
    "PSL_PHONE",
    "PSL_OTHER_PERSONAL",
    "PSL_APPROX_LOCATION",
    "PSL_PRECISE_LOCATION",
    "PSL_PHOTOS",
    "PSL_FILES_AND_DOCS",
    "PSL_CRASH_LOGS",
    "PSL_PERFORMANCE_DIAGNOSTICS",
    "PSL_USER_INTERACTION",
    "PSL_OTHER_APP_ACTIVITY",
    "PSL_DEVICE_ID"
)

$clientUsages = @{
    PSL_NAME = @{
        Collection = @($appFunctionality, $developerComms, $accountManagement)
        Sharing = @($appFunctionality)
        Required = $true
    }
    PSL_EMAIL = @{
        Collection = @($appFunctionality, $developerComms, $accountManagement)
        Sharing = @()
        Required = $true
    }
    PSL_USER_ACCOUNT = @{
        Collection = @($appFunctionality, $fraudSecurity, $accountManagement)
        Sharing = @()
        Required = $true
    }
    PSL_ADDRESS = @{
        Collection = @($appFunctionality)
        Sharing = @($appFunctionality)
        Required = $true
    }
    PSL_PHONE = @{
        Collection = @($appFunctionality, $developerComms, $accountManagement)
        Sharing = @($appFunctionality)
        Required = $true
    }
    PSL_PURCHASE_HISTORY = @{
        Collection = @($appFunctionality, $accountManagement)
        Sharing = @()
        Required = $true
    }
    PSL_APPROX_LOCATION = @{
        Collection = @($appFunctionality)
        Sharing = @($appFunctionality)
        Required = $true
    }
    PSL_PRECISE_LOCATION = @{
        Collection = @($appFunctionality)
        Sharing = @($appFunctionality)
        Required = $true
    }
    PSL_PHOTOS = @{
        Collection = @($appFunctionality)
        Sharing = @($appFunctionality)
        Required = $false
    }
    PSL_CRASH_LOGS = @{
        Collection = @($analytics)
        Sharing = @()
        Required = $true
    }
    PSL_PERFORMANCE_DIAGNOSTICS = @{
        Collection = @($analytics)
        Sharing = @()
        Required = $true
    }
    PSL_USER_INTERACTION = @{
        Collection = @($appFunctionality, $analytics)
        Sharing = @()
        Required = $true
    }
    PSL_IN_APP_SEARCH_HISTORY = @{
        Collection = @($appFunctionality)
        Sharing = @()
        Required = $false
    }
    PSL_USER_GENERATED_CONTENT = @{
        Collection = @($appFunctionality)
        Sharing = @($appFunctionality)
        Required = $false
    }
    PSL_OTHER_APP_ACTIVITY = @{
        Collection = @($appFunctionality, $analytics)
        Sharing = @()
        Required = $true
    }
    PSL_DEVICE_ID = @{
        Collection = @($appFunctionality, $analytics, $fraudSecurity)
        Sharing = @()
        Required = $true
    }
}

$driverUsages = @{
    PSL_NAME = @{
        Collection = @($appFunctionality, $developerComms, $accountManagement)
        Sharing = @($appFunctionality)
        Required = $true
    }
    PSL_EMAIL = @{
        Collection = @($appFunctionality, $developerComms, $accountManagement)
        Sharing = @()
        Required = $true
    }
    PSL_USER_ACCOUNT = @{
        Collection = @($appFunctionality, $fraudSecurity, $accountManagement)
        Sharing = @()
        Required = $true
    }
    PSL_PHONE = @{
        Collection = @($appFunctionality, $developerComms, $accountManagement)
        Sharing = @($appFunctionality)
        Required = $true
    }
    PSL_OTHER_PERSONAL = @{
        Collection = @($appFunctionality, $fraudSecurity, $accountManagement)
        Sharing = @($appFunctionality)
        Required = $true
    }
    PSL_APPROX_LOCATION = @{
        Collection = @($appFunctionality)
        Sharing = @($appFunctionality)
        Required = $true
    }
    PSL_PRECISE_LOCATION = @{
        Collection = @($appFunctionality)
        Sharing = @($appFunctionality)
        Required = $true
    }
    PSL_PHOTOS = @{
        Collection = @($appFunctionality, $fraudSecurity, $accountManagement)
        Sharing = @()
        Required = $true
    }
    PSL_FILES_AND_DOCS = @{
        Collection = @($appFunctionality, $fraudSecurity, $accountManagement)
        Sharing = @()
        Required = $true
    }
    PSL_CRASH_LOGS = @{
        Collection = @($analytics)
        Sharing = @()
        Required = $true
    }
    PSL_PERFORMANCE_DIAGNOSTICS = @{
        Collection = @($analytics)
        Sharing = @()
        Required = $true
    }
    PSL_USER_INTERACTION = @{
        Collection = @($appFunctionality, $analytics)
        Sharing = @()
        Required = $true
    }
    PSL_OTHER_APP_ACTIVITY = @{
        Collection = @($appFunctionality, $analytics)
        Sharing = @()
        Required = $true
    }
    PSL_DEVICE_ID = @{
        Collection = @($appFunctionality, $analytics, $fraudSecurity)
        Sharing = @()
        Required = $true
    }
}

$clientOutput = Join-Path $OutputDir "motobike_client_data_safety.csv"
$driverOutput = Join-Path $OutputDir "motobike_driver_data_safety.csv"

New-DataSafetyFile `
    -AppName "MotoBike client" `
    -DataTypes $clientTypes `
    -Usages $clientUsages `
    -OutputPath $clientOutput

New-DataSafetyFile `
    -AppName "MotoBike Driver" `
    -DataTypes $driverTypes `
    -Usages $driverUsages `
    -OutputPath $driverOutput

Write-Host "Created:"
Write-Host " - $clientOutput"
Write-Host " - $driverOutput"
