[CmdletBinding()]
param(
    [Parameter(Mandatory=$true, Position=0)]
    [string]$Path
)

$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.IO.Compression.FileSystem

if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) {
    throw "File not found: $Path"
}

$zip = [System.IO.Compression.ZipFile]::OpenRead((Resolve-Path -LiteralPath $Path))
try {
    $ns = New-Object System.Xml.XmlNamespaceManager((New-Object System.Xml.NameTable))
    $ns.AddNamespace('w', 'http://schemas.openxmlformats.org/wordprocessingml/2006/main')
    $parts = @{}
    foreach ($entry in $zip.Entries) {
        if ($entry.FullName -match '^word/.*\.xml$') {
            $reader = New-Object System.IO.StreamReader($entry.Open())
            try { $parts[$entry.FullName] = $reader.ReadToEnd() } finally { $reader.Dispose() }
        }
    }

    $settings = $null
    if ($parts.ContainsKey('word/settings.xml')) {
        $settings = [xml]$parts['word/settings.xml']
    }
    $tracked = $false
    if ($settings -and $settings.SelectSingleNode('//w:trackRevisions', $ns)) { $tracked = $true }

    $revisionRows = @()
    $allIds = @()
    foreach ($part in $parts.Keys) {
        try { $xml = [xml]$parts[$part] } catch { continue }
        foreach ($node in $xml.SelectNodes('//*[@w:id and (self::w:ins or self::w:del or self::w:moveFrom or self::w:moveTo or self::w:rPrChange or self::w:pPrChange)]', $ns)) {
            $id = $node.GetAttribute('id', $ns.LookupNamespace('w'))
            $author = $node.GetAttribute('author', $ns.LookupNamespace('w'))
            $date = $node.GetAttribute('date', $ns.LookupNamespace('w'))
            $allIds += [int]$id
            $revisionRows += [PSCustomObject]@{ Part=$part; Kind=$node.LocalName; Id=$id; Author=$author; Date=$date }
        }
    }

    $duplicateIds = @($allIds | Group-Object | Where-Object Count -gt 1 | Select-Object -ExpandProperty Name)
    $authors = @($revisionRows | Where-Object Author | Group-Object Author | Sort-Object Name | ForEach-Object { "$($_.Name) ($($_.Count))" })

    [PSCustomObject]@{
        Path = (Resolve-Path -LiteralPath $Path).Path
        TrackRevisions = $tracked
        RevisionCount = $revisionRows.Count
        Authors = if ($authors.Count) { $authors -join '; ' } else { '' }
        DuplicateRevisionIds = if ($duplicateIds.Count) { $duplicateIds -join ', ' } else { '' }
        PartsWithRevisions = (($revisionRows | Select-Object -ExpandProperty Part -Unique) -join '; ')
        Status = if ($duplicateIds.Count -eq 0) { 'OK' } else { 'CHECK_DUPLICATE_IDS' }
    }

    if ($revisionRows.Count) {
        Write-Output "`nRevision details:"
        $revisionRows | Sort-Object Part,Id | Format-Table -AutoSize
    }
}
finally {
    $zip.Dispose()
}
