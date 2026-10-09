# Builds the site: wraps every page in src/pages with src/_layout.html and writes it to docs/ (the folder GitHub Pages publishes).
# Each page starts with a front-matter comment:
#   <!--
#   title: Page title
#   description: One-sentence summary for Google
#   path: /about            (the page's address)
#   nav: about              (which menu item to highlight; optional)
#   image: /images/x.jpg    (social preview image; optional)
#   ogtype: article         (optional, default website)
#   -->
# Anything between <!--head--> and <!--/head--> goes into <head> (e.g. structured data).
$ErrorActionPreference = 'Stop'
$root = Split-Path $PSScriptRoot -Parent
$src = Join-Path $root 'src\pages'; $out = Join-Path $root 'docs'
$layout = [IO.File]::ReadAllText((Join-Path $root 'src\_layout.html'))
$utf8 = New-Object Text.UTF8Encoding($false)
$navs = 'about','neurofeedback','writings','insurance','blog','contact'

Get-ChildItem $src -Recurse -Filter *.html | ForEach-Object {
  $raw = [IO.File]::ReadAllText($_.FullName)
  $m = [regex]::Match($raw, '^\s*<!--(.*?)-->', 'Singleline')
  if (-not $m.Success) { throw "No front matter in $($_.FullName)" }
  $meta = @{ ogtype = 'website'; image = '/images/river-hero.jpg'; nav = '' }
  foreach ($line in $m.Groups[1].Value -split "`n") { if ($line -match '^\s*(\w+):\s*(.+?)\s*$') { $meta[$Matches[1]] = $Matches[2] } }
  $body = $raw.Substring($m.Length)
  $head = ''
  $h = [regex]::Match($body, '<!--head-->(.*?)<!--/head-->', 'Singleline')
  if ($h.Success) { $head = $h.Groups[1].Value.Trim(); $body = $body.Remove($h.Index, $h.Length) }

  $html = $layout.Replace('{{content}}', $body.Trim()).Replace('{{head}}', $head)
  foreach ($k in 'title','description','path','image','ogtype') {
    $html = $html.Replace("{{$k}}", [Net.WebUtility]::HtmlEncode($meta[$k]).Replace('&#39;', "'"))
  }
  foreach ($n in $navs) { $html = $html.Replace("{{nav:$n}}", $(if ($meta.nav -eq $n) { ' aria-current="page"' } else { '' })) }

  $rel = $_.FullName.Substring($src.Length + 1)
  $dest = Join-Path $out $rel
  New-Item -ItemType Directory -Force (Split-Path $dest) | Out-Null
  [IO.File]::WriteAllText($dest, $html, $utf8)
  "built $rel"
}
