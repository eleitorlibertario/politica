param(
    [switch]$Force
)

$ErrorActionPreference = "Stop"

$repoRoot  = Resolve-Path (Join-Path $PSScriptRoot "..")
$sourceDir = Join-Path $repoRoot "inputs\tse"
$destDir   = Join-Path $repoRoot "inputs\tse_extracted"

if (-not (Test-Path -LiteralPath $destDir)) {
    New-Item -ItemType Directory -Path $destDir | Out-Null
}

$zips = Get-ChildItem -Path $sourceDir -Filter "*.zip"

if ($zips.Count -eq 0) {
    Write-Host "Nenhum ZIP encontrado em: $sourceDir"
    exit 1
}

foreach ($zip in $zips) {
    $zipName   = $zip.BaseName
    $targetDir = Join-Path $destDir $zipName

    if ((Test-Path -LiteralPath $targetDir) -and -not $Force) {
        Write-Host "[SKIP] $($zip.Name) ja extraido. Use -Force para re-extrair."
        continue
    }

    Write-Host "[EXTR] $($zip.Name) -> $targetDir"

    if (Test-Path -LiteralPath $targetDir) {
        Remove-Item -Recurse -Force -LiteralPath $targetDir
    }

    Expand-Archive -LiteralPath $zip.FullName -DestinationPath $targetDir

    $count = (Get-ChildItem -Recurse -File -Path $targetDir).Count
    Write-Host "[ OK ] $($zip.Name) ($count arquivo(s))"
}

Write-Host ""
Write-Host "Extracao concluida. Arquivos em: $destDir"
Write-Host "Proximo passo: node scripts/008_inspect_headers.js"
