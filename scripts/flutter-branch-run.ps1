param(
    [Parameter(Mandatory = $true)]
    [string] $FlutterExecutable,
    [string[]] $FlutterArguments = @(),
    [ValidateSet('test', 'master', '')]
    [string] $Branch = '',
    [switch] $Preview
)

$ErrorActionPreference = 'Stop'

if ($FlutterArguments.Count -eq 0 -or $FlutterArguments[0] -ne 'run') {
    if ($Preview) { Write-Output ('flutter ' + ($FlutterArguments -join ' ')); exit 0 }
    & $FlutterExecutable @FlutterArguments
    exit $LASTEXITCODE
}

$appRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\driver_app\driver_app')).Path
if ((Get-Location).ProviderPath -ne $appRoot) {
    throw 'Run flutter from driver_app/driver_app.'
}

if (-not $Branch) {
    $Branch = (& git branch --show-current).Trim()
    if ($LASTEXITCODE -ne 0) { throw 'Could not determine the Git branch.' }
}

$runArguments = @($FlutterArguments)
$gradleFile = Join-Path $appRoot 'android\app\build.gradle.kts'
$hasFlavors = (Get-Content -LiteralPath $gradleFile -Raw) -match 'create\("staging"\)'

if ($Branch -eq 'test' -or ($Branch -eq 'master' -and $hasFlavors)) {
    if ($FlutterArguments | Where-Object { $_ -match '^--(flavor|dart-define|dart-define-from-file)(=|$)' }) {
        throw 'This branch selects its flavor and environment file automatically. Remove the manual flavor or Dart define option.'
    }

    if ($Branch -eq 'test') {
        $flavor = 'staging'
        $envFile = '.env.staging'
        $expectedEnvironment = 'test'
        $expectedApi = 'moto-bike-test.vercel.app'
        $expectedSupabase = 'mtbqqharhxijulpaqdrm.supabase.co'
    } else {
        $flavor = 'production'
        $envFile = '.env.production'
        $expectedEnvironment = 'production'
        $expectedApi = 'motobikedeliveryservice.com'
        $expectedSupabase = 'smkfvvblyudecimcfman.supabase.co'
    }

    $envPath = Join-Path $appRoot $envFile
    if (-not (Test-Path -LiteralPath $envPath)) {
        throw "Missing $envFile in driver_app/driver_app."
    }

    $values = @{}
    foreach ($line in Get-Content -LiteralPath $envPath) {
        if ($line -match '^([A-Za-z_][A-Za-z0-9_]*)=(.*)$') {
            $values[$Matches[1]] = $Matches[2].Trim()
        }
    }
    $apiUri = $null
    $supabaseUri = $null
    if (-not [Uri]::TryCreate($values['API_BASE_URL'], [UriKind]::Absolute, [ref] $apiUri) -or
        -not [Uri]::TryCreate($values['SUPABASE_URL'], [UriKind]::Absolute, [ref] $supabaseUri) -or
        $values['ENVIRONMENT'] -ne $expectedEnvironment -or
        $apiUri.Scheme -ne 'https' -or $apiUri.Host -ne $expectedApi -or
        $supabaseUri.Scheme -ne 'https' -or $supabaseUri.Host -ne $expectedSupabase -or
        [string]::IsNullOrWhiteSpace($values['SUPABASE_ANON_KEY'])) {
        throw "$envFile does not contain the expected $Branch app endpoints and public key."
    }

    $runArguments += @('--flavor', $flavor, "--dart-define-from-file=$envFile")
}

if ($Preview) {
    Write-Output ('flutter ' + ($runArguments -join ' '))
    exit 0
}

& $FlutterExecutable @runArguments
exit $LASTEXITCODE
