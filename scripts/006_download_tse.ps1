param(
    [switch]$Force
)

$ErrorActionPreference = "Stop"

$repoRoot = Resolve-Path (Join-Path $PSScriptRoot "..")
$downloadDir = Join-Path $repoRoot "inputs\tse"

if (-not (Test-Path -LiteralPath $downloadDir)) {
    New-Item -ItemType Directory -Path $downloadDir | Out-Null
}

$files = @(
    @{
        Name = "consulta_cand_2022.zip"
        Url  = "https://cdn.tse.jus.br/estatistica/sead/odsele/consulta_cand/consulta_cand_2022.zip"
    },
    @{
        Name = "votacao_candidato_munzona_2022.zip"
        Url  = "https://cdn.tse.jus.br/estatistica/sead/odsele/votacao_candidato_munzona/votacao_candidato_munzona_2022.zip"
    },
    @{
        Name = "votacao_secao_2022_SC.zip"
        Url  = "https://cdn.tse.jus.br/estatistica/sead/odsele/votacao_secao/votacao_secao_2022_SC.zip"
    },
    @{
        Name = "prestacao_de_contas_eleitorais_candidatos_2022.zip"
        Url  = "https://cdn.tse.jus.br/estatistica/sead/odsele/prestacao_contas/prestacao_de_contas_eleitorais_candidatos_2022.zip"
    }
)

Write-Host "Diretorio de destino: $downloadDir"

foreach ($file in $files) {
    $target = Join-Path $downloadDir $file.Name

    if ((Test-Path -LiteralPath $target) -and -not $Force) {
        Write-Host "[SKIP] $($file.Name) ja existe. Use -Force para baixar novamente."
        continue
    }

    Write-Host "[DOWN] $($file.Name)"
    Write-Host "       $($file.Url)"

    Invoke-WebRequest -Uri $file.Url -OutFile $target

    if (-not (Test-Path -LiteralPath $target)) {
        throw "Falha ao salvar arquivo: $target"
    }

    $sizeMb = [math]::Round(((Get-Item -LiteralPath $target).Length / 1MB), 2)
    Write-Host "[ OK ] $($file.Name) ($sizeMb MB)"
}

Write-Host ""
Write-Host "Download concluido."
Write-Host "Arquivos em: $downloadDir"
Write-Host "Proximo passo: extrair ZIPs e mapear arquivos para staging."
