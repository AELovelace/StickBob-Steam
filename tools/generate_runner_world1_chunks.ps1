param(
    [string]$ProjectRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path,
    [int]$ChunkWidth = 640
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$culture = [System.Globalization.CultureInfo]::InvariantCulture

function Format-GmlNumber {
    param([double]$Value)

    if ([math]::Abs($Value - [math]::Round($Value)) -lt 0.00001) {
        return [string][int][math]::Round($Value)
    }

    return $Value.ToString('0.###', $culture)
}

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
        ObjectName  = $ObjectName
        Dx          = $Dx
        Dy          = $Dy
        ScaleX      = $ScaleX
        ScaleY      = $ScaleY
        Rotation    = $Rotation
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
                $rangeStart = [double]$element.Dx
                $rangeEnd = [double]($element.Dx + $element.WidthPixels)
                if ($rangeStart -lt 32 -and $rangeEnd -gt 0) { $leftSupport = $true }
                if ($rangeStart -lt $ChunkWidth -and $rangeEnd -gt ($ChunkWidth - 32)) { $rightSupport = $true }
            }
        }

        if ($chunkElements.Count -eq 0) { continue }
        if (-not ($leftSupport -and $rightSupport)) { continue }

        $generatedChunks.Add([pscustomobject]@{
            RoomName   = $roomName
            ChunkStart = $chunkStart
            Width      = $ChunkWidth
            Elements   = $chunkElements.ToArray()
        })
    }
}

$outputDir = Join-Path $ProjectRoot 'scripts\scr_runner_world1_chunks'
$outputFile = Join-Path $outputDir 'scr_runner_world1_chunks.gml'
if (-not (Test-Path $outputDir)) {
    New-Item -ItemType Directory -Force -Path $outputDir | Out-Null
}

$lines = New-Object System.Collections.Generic.List[string]
$lines.Add('// AUTO-GENERATED by tools/generate_runner_world1_chunks.ps1')
$lines.Add('// Source rooms: rm_GameRoom, SP1, SP2, SP3, SP4')
$lines.Add('// Regenerate after changing authored World 1 rooms.')
$lines.Add('')
$lines.Add('function scr_runner_world1_chunks() {')
$lines.Add('    var _chunks = [];')

$chunkIndex = 0
foreach ($chunk in $generatedChunks) {
    $lines.Add('')
    $lines.Add("    // $($chunk.RoomName) chunk $chunkIndex (source x=$($chunk.ChunkStart))")
    $lines.Add('    array_push(_chunks, {')
    $lines.Add("        width     : $($chunk.Width),")
    $lines.Add('        platforms : [],')
    $lines.Add('        hazards   : [],')
    $lines.Add('        elements  : [')

    for ($i = 0; $i -lt $chunk.Elements.Count; $i++) {
        $element = $chunk.Elements[$i]
        $comma = if ($i -lt ($chunk.Elements.Count - 1)) { ',' } else { '' }
        $line = '            runner_prefab_ex(' +
            $element.ObjectName + ', ' +
            (Format-GmlNumber $element.Dx) + ', ' +
            (Format-GmlNumber $element.Dy) + ', ' +
            (Format-GmlNumber $element.ScaleX) + ', ' +
            (Format-GmlNumber $element.ScaleY) + ', ' +
            (Format-GmlNumber $element.Rotation) + ')' + $comma
        $lines.Add($line)
    }

    $lines.Add('        ],')
    $lines.Add('        source_room  : "' + $chunk.RoomName + '",')
    $lines.Add('        source_start : ' + $chunk.ChunkStart + ',')
    $lines.Add('    });')
    $chunkIndex++
}

$lines.Add('')
$lines.Add('    return _chunks;')
$lines.Add('}')

$lines | Set-Content -Path $outputFile -Encoding UTF8
Write-Output ("Generated {0} World 1 runner chunks into {1}" -f $generatedChunks.Count, $outputFile)
