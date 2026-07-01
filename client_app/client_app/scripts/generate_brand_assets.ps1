Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$appRoot = Split-Path -Parent $PSScriptRoot
Set-Location $appRoot

$logoPath = Join-Path $appRoot "assets\images\logo2048.png"
if (-not (Test-Path -LiteralPath $logoPath)) {
    throw "Logo image not found at $logoPath"
}

$brandDir = Join-Path $appRoot "assets\images\brand"
New-Item -ItemType Directory -Path $brandDir -Force | Out-Null

Add-Type -AssemblyName System.Drawing
if (-not ("BrandPngSharpen" -as [type])) {
    Add-Type -ReferencedAssemblies "System.Drawing" -TypeDefinition @"
using System;
using System.Drawing;
using System.Drawing.Imaging;
using System.IO;
using System.Runtime.InteropServices;

public static class BrandPngSharpen
{
    public static void Sharpen(string path, double amount)
    {
        byte[] fileBytes = File.ReadAllBytes(path);
        Bitmap source;
        using (var memory = new MemoryStream(fileBytes))
        {
            source = new Bitmap(memory);
        }

        var rect = new Rectangle(0, 0, source.Width, source.Height);
        var srcData = source.LockBits(rect, ImageLockMode.ReadOnly, PixelFormat.Format32bppArgb);
        int stride = srcData.Stride;
        int bytes = Math.Abs(stride) * source.Height;
        var src = new byte[bytes];
        Marshal.Copy(srcData.Scan0, src, 0, bytes);
        source.UnlockBits(srcData);

        var dst = new byte[bytes];
        int width = source.Width;
        int height = source.Height;
        source.Dispose();

        for (int y = 0; y < height; y++)
        {
            for (int x = 0; x < width; x++)
            {
                int i = Index(x, y, stride, height);
                byte alpha = src[i + 3];
                if (alpha == 0)
                {
                    dst[i] = 0;
                    dst[i + 1] = 0;
                    dst[i + 2] = 0;
                    dst[i + 3] = 0;
                    continue;
                }

                dst[i] = SharpenChannel(src, x, y, 0, width, height, stride, amount);
                dst[i + 1] = SharpenChannel(src, x, y, 1, width, height, stride, amount);
                dst[i + 2] = SharpenChannel(src, x, y, 2, width, height, stride, amount);
                dst[i + 3] = alpha;
            }
        }

        using (var output = new Bitmap(width, height, PixelFormat.Format32bppArgb))
        {
            var outData = output.LockBits(rect, ImageLockMode.WriteOnly, PixelFormat.Format32bppArgb);
            Marshal.Copy(dst, 0, outData.Scan0, bytes);
            output.UnlockBits(outData);
            output.Save(path, ImageFormat.Png);
        }
    }

    private static byte SharpenChannel(byte[] src, int x, int y, int channel, int width, int height, int stride, double amount)
    {
        int centerIndex = Index(x, y, stride, height);
        double center = src[centerIndex + channel];
        double value = center * (1 + (4 * amount))
            - Sample(src, x - 1, y, channel, width, height, stride, center) * amount
            - Sample(src, x + 1, y, channel, width, height, stride, center) * amount
            - Sample(src, x, y - 1, channel, width, height, stride, center) * amount
            - Sample(src, x, y + 1, channel, width, height, stride, center) * amount;

        if (value < 0) return 0;
        if (value > 255) return 255;
        return (byte)Math.Round(value);
    }

    private static double Sample(byte[] src, int x, int y, int channel, int width, int height, int stride, double fallback)
    {
        if (x < 0 || y < 0 || x >= width || y >= height) return fallback;
        int i = Index(x, y, stride, height);
        if (src[i + 3] < 16) return fallback;
        return src[i + channel];
    }

    private static int Index(int x, int y, int stride, int height)
    {
        int row = stride > 0 ? y * stride : (height - 1 - y) * -stride;
        return row + (x * 4);
    }
}
"@
}

function New-BrandPng {
    param(
        [Parameter(Mandatory = $true)]
        [string] $OutputPath,
        [Parameter(Mandatory = $true)]
        [int] $CanvasSize,
        [Parameter(Mandatory = $true)]
        [int] $MaxLogoSize,
        [Parameter(Mandatory = $true)]
        [System.Drawing.Color] $BackgroundColor,
        [bool] $Sharpen = $false
    )

    $source = [System.Drawing.Image]::FromFile($logoPath)
    $canvas = New-Object System.Drawing.Bitmap $CanvasSize, $CanvasSize, ([System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
    $graphics = [System.Drawing.Graphics]::FromImage($canvas)

    try {
        $graphics.CompositingQuality = [System.Drawing.Drawing2D.CompositingQuality]::HighQuality
        $graphics.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
        $graphics.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality
        $graphics.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::HighQuality

        if ($BackgroundColor.A -eq 0) {
            $graphics.Clear([System.Drawing.Color]::Transparent)
        } else {
            $graphics.Clear($BackgroundColor)
        }

        $scale = [Math]::Min($MaxLogoSize / $source.Width, $MaxLogoSize / $source.Height)
        $drawWidth = [int][Math]::Round($source.Width * $scale)
        $drawHeight = [int][Math]::Round($source.Height * $scale)
        $drawX = [int][Math]::Round(($CanvasSize - $drawWidth) / 2)
        $drawY = [int][Math]::Round(($CanvasSize - $drawHeight) / 2)

        $graphics.DrawImage($source, $drawX, $drawY, $drawWidth, $drawHeight)
        $canvas.Save($OutputPath, [System.Drawing.Imaging.ImageFormat]::Png)
    } finally {
        $graphics.Dispose()
        $canvas.Dispose()
        $source.Dispose()
    }

    if ($Sharpen) {
        [BrandPngSharpen]::Sharpen($OutputPath, 0.18)
    }
}

New-BrandPng -OutputPath (Join-Path $brandDir "launcher_icon.png") -CanvasSize 1024 -MaxLogoSize 720 -BackgroundColor ([System.Drawing.Color]::White) -Sharpen $true
New-BrandPng -OutputPath (Join-Path $brandDir "adaptive_icon_foreground.png") -CanvasSize 1024 -MaxLogoSize 660 -BackgroundColor ([System.Drawing.Color]::Transparent) -Sharpen $true
New-BrandPng -OutputPath (Join-Path $brandDir "splash_logo.png") -CanvasSize 1024 -MaxLogoSize 448 -BackgroundColor ([System.Drawing.Color]::Transparent) -Sharpen $true

$dart = "dart"
$flutterCommand = Get-Command flutter -ErrorAction SilentlyContinue
if ($flutterCommand) {
    $flutterBin = Split-Path -Parent $flutterCommand.Source
    $flutterRoot = Split-Path -Parent $flutterBin
    $flutterDart = Join-Path $flutterRoot "bin\cache\dart-sdk\bin\dart.exe"
    if (Test-Path -LiteralPath $flutterDart) {
        $dart = $flutterDart
    }
}

function Invoke-DartCommand {
    param(
        [Parameter(Mandatory = $true)]
        [string[]] $Arguments
    )

    & $dart @Arguments
    if ($LASTEXITCODE -ne 0) {
        throw "dart $($Arguments -join ' ') failed with exit code $LASTEXITCODE"
    }
}

Invoke-DartCommand -Arguments @("run", "flutter_launcher_icons")
Invoke-DartCommand -Arguments @("run", "flutter_native_splash:create")
