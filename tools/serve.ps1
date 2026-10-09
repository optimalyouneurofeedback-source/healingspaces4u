# Tiny local web server for previewing the site (mimics GitHub Pages: /about -> about.html)
param([int]$Port = 8137, [string]$Root = (Join-Path $PSScriptRoot '..\docs'))
$Root = (Resolve-Path $Root).Path
$types = @{ '.html'='text/html; charset=utf-8'; '.css'='text/css'; '.js'='text/javascript'; '.svg'='image/svg+xml'; '.png'='image/png';
            '.jpg'='image/jpeg'; '.jpeg'='image/jpeg'; '.webp'='image/webp'; '.ico'='image/x-icon'; '.json'='application/json'; '.xml'='application/xml'; '.txt'='text/plain' }
$l = [System.Net.HttpListener]::new(); $l.Prefixes.Add("http://localhost:$Port/"); $l.Start()
Write-Host "Serving $Root at http://localhost:$Port/"
while ($l.IsListening) {
  $c = $l.GetContext(); $p = [Uri]::UnescapeDataString($c.Request.Url.AbsolutePath).TrimStart('/')
  $f = Join-Path $Root $p
  if (Test-Path $f -PathType Container) { $f = Join-Path $f 'index.html' }
  elseif (-not (Test-Path $f) -and (Test-Path "$f.html")) { $f = "$f.html" }
  if (Test-Path $f -PathType Leaf) {
    $b = [IO.File]::ReadAllBytes($f); $ext = [IO.Path]::GetExtension($f).ToLower()
    $c.Response.ContentType = $(if ($types[$ext]) { $types[$ext] } else { 'application/octet-stream' })
  } else {
    $c.Response.StatusCode = 404; $nf = Join-Path $Root '404.html'
    $b = $(if (Test-Path $nf) { [IO.File]::ReadAllBytes($nf) } else { [Text.Encoding]::UTF8.GetBytes('Not found') })
    $c.Response.ContentType = 'text/html; charset=utf-8'
  }
  try { $c.Response.OutputStream.Write($b, 0, $b.Length) } catch {} finally { $c.Response.Close() }
  Write-Host "$($c.Response.StatusCode) /$p"
}
