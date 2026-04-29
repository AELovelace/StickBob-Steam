param(
    [string]$ProjectRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path,
    [int]$ChunkWidth = 640
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$culture = [System.Globalization.CultureInfo]::InvariantCulture

function New-ChunkElement {
    param(
        [string]$ObjectName,
        [double]$Dx,
        [double]$Dy,
        [double]$ScaleX,
        [double]$ScaleY,
        [double]$Rotation,
        [double]$WidthPixels,
        [bool]$IsSupport
    )

    [pscustomobject]@{
        object_name = $ObjectName
        dx          = $Dx
        dy          = $Dy
        scale_x     = $ScaleX
        scale_y     = $ScaleY
        rotation    = $Rotation
        WidthPixels = $WidthPixels
        IsSupport   = $IsSupport
    }
}

$roomPaths = @(
    'rooms\rm_GameRoom\rm_GameRoom.yy',
    'rooms\SP1\SP1.yy',
    'rooms\SP2\SP2.yy',
    'rooms\SP3\SP3.yy',
    'rooms\SP4\SP4.yy'
) | ForEach-Object { Join-Path $ProjectRoot $_ }

$clippableObjects = @(
    'objSolid',
    'objSolid1',
    'objSolid6',
    'objSolidInvisible',
    'obj_Wall'
)

$supportObjects = @(
    'objSolid',
    'objSolid1',
    'objSolid6',
    'objSolidInvisible',
    'obj_Wall',
    'objSloped',
    'objSloped45',
    'objSloped45Left',
    'objSloped_1',
    'objSloped_2',
    'objSloped_3',
    'objSloped_4',
    'objBouncyBottom'
)

$allowedObjects = @(
    $clippableObjects +
    @(
        'objSloped',
        'objSloped45',
        'objSloped45Left',
        'objSloped_1',
        'objSloped_2',
        'objSloped_3',
        'objSloped_4',
        'objBouncyBottom',
        'objBouncyTop',
        'objBouncyLeft',
        'objBouncyRight',
        'objSlopBot',
        'objSlopBotGunner',
        'objSlopBotSlacker'
    )
) | Select-Object -Unique

$instancePattern = '"objectId":\{"name":"(?<object>[^"]+)".*?"rotation":(?<rotation>-?\d+(?:\.\d+)?),"scaleX":(?<scaleX>-?\d+(?:\.\d+)?),"scaleY":(?<scaleY>-?\d+(?:\.\d+)?),"x":(?<x>-?\d+(?:\.\d+)?),"y":(?<y>-?\d+(?:\.\d+)?),'
$roomWidthPattern = '"Width":(?<width>\d+)'

$generatedChunks = New-Object System.Collections.Generic.List[object]

foreach ($roomPath in $roomPaths) {
    $roomText = Get-Content -Raw -Path $roomPath
    $roomWidthMatch = [regex]::Match($roomText, $roomWidthPattern)
    if (-not $roomWidthMatch.Success) {
        throw "Could not find room width in $roomPath"
    }

    $roomWidth = [int]$roomWidthMatch.Groups['width'].Value
    $roomName = Split-Path (Split-Path $roomPath -Parent) -Leaf

    $instances = @()
    foreach ($line in Get-Content -Path $roomPath) {
        $match = [regex]::Match($line, $instancePattern)
        if (-not $match.Success) { continue }

        $objectName = $match.Groups['object'].Value
        if ($allowedObjects -notcontains $objectName) { continue }

        $instances += [pscustomobject]@{
            ObjectName = $objectName
            Rotation   = [double]::Parse($match.Groups['rotation'].Value, $culture)
            ScaleX     = [double]::Parse($match.Groups['scaleX'].Value, $culture)
            ScaleY     = [double]::Parse($match.Groups['scaleY'].Value, $culture)
            X          = [double]::Parse($match.Groups['x'].Value, $culture)
            Y          = [double]::Parse($match.Groups['y'].Value, $culture)
        }
    }

    for ($chunkStart = 0; ($chunkStart + $ChunkWidth) -le $roomWidth; $chunkStart += $ChunkWidth) {
        $chunkElements = New-Object System.Collections.Generic.List[object]
        $leftSupport = $false
        $rightSupport = $false
        $leftEdge = [double]$chunkStart
        $rightEdge = [double]($chunkStart + $ChunkWidth)

        foreach ($inst in $instances) {
            if ($inst.ObjectName -eq 'obj_Wall' -and ($inst.X -le 16 -or $inst.X -ge ($roomWidth - 32))) {
                continue
            }

            $isSupport = $supportObjects -contains $inst.ObjectName

            if ($clippableObjects -contains $inst.ObjectName) {
                $instStart = $inst.X
                $instEnd = $inst.X + (16.0 * $inst.ScaleX)
                $clipStart = [math]::Max($instStart, $leftEdge)
                $clipEnd = [math]::Min($instEnd, $rightEdge)
                if ($clipEnd -le $clipStart) { continue }

                $localDx = $clipStart - $leftEdge
                $widthPixels = $clipEnd - $clipStart
                $scaleX = $widthPixels / 16.0
                $element = New-ChunkElement $inst.ObjectName $localDx $inst.Y $scaleX $inst.ScaleY $inst.Rotation $widthPixels $isSupport
                $chunkElements.Add($element)
            }
            else {
                if ($inst.X -lt ($leftEdge - 16) -or $inst.X -ge $rightEdge) { continue }

                $localDx = $inst.X - $leftEdge
                $widthPixels = 16.0 * [math]::Max(1.0, $inst.ScaleX)
                $element = New-ChunkElement $inst.ObjectName $localDx $inst.Y $inst.ScaleX $inst.ScaleY $inst.Rotation $widthPixels $isSupport
                $chunkElements.Add($element)
            }

            if ($isSupport) {
                $rangeStart = [double]$element.dx
                $rangeEnd = [double]($element.dx + $element.WidthPixels)
                if ($rangeStart -lt 32 -and $rangeEnd -gt 0) { $leftSupport = $true }
                if ($rangeStart -lt $ChunkWidth -and $rangeEnd -gt ($ChunkWidth - 32)) { $rightSupport = $true }
            }
        }

        if ($chunkElements.Count -eq 0) { continue }
        if (-not ($leftSupport -and $rightSupport)) { continue }

        $generatedChunks.Add([pscustomobject]@{
            width        = $ChunkWidth
            platforms    = [object[]]@()
            hazards      = [object[]]@()
            elements     = [object[]]($chunkElements.ToArray() | ForEach-Object {
                [pscustomobject]@{
                    object_name = $_.object_name
                    dx          = $_.dx
                    dy          = $_.dy
                    scale_x     = $_.scale_x
                    scale_y     = $_.scale_y
                    rotation    = $_.rotation
                }
            })
            source_room  = $roomName
            source_start = $chunkStart
        })
    }
}

$outputDir = Join-Path $ProjectRoot 'datafiles\infiniteRunner'
if (-not (Test-Path $outputDir)) {
    New-Item -ItemType Directory -Force -Path $outputDir | Out-Null
}

$manifestPath = Join-Path $outputDir 'chunks_manifest.json'
$chunkFilePath = Join-Path $outputDir 'world1_chunks.json'

$manifest = [pscustomobject]@{
    files = @('world1_chunks.json')
}

$chunkDoc = [pscustomobject]@{
    chunk_set = 'world1'
    chunk_width = $ChunkWidth
    source_rooms = @('rm_GameRoom', 'SP1', 'SP2', 'SP3', 'SP4')
    chunks = $generatedChunks
}

$utf8NoBom = New-Object System.Text.UTF8Encoding($false)
[System.IO.File]::WriteAllText($manifestPath, ($manifest | ConvertTo-Json -Depth 4), $utf8NoBom)
[System.IO.File]::WriteAllText($chunkFilePath, ($chunkDoc | ConvertTo-Json -Depth 8), $utf8NoBom)

Write-Output ("Generated {0} World 1 runner chunks into {1}" -f $generatedChunks.Count, $chunkFilePath)
