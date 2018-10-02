################
# The wild west
################

# Routing table as objects
$rt = netstat -r  
($rt | Select-Object -Last ($rt.count - 1 )) -replace '\s{1,}',',' | ConvertFrom-Csv  | 
    Where-Object { $_.Destination -eq 'default' }

# List open files 
$of = (lsof) -replace '\s{1,}',';' | ConvertFrom-Csv -Delimiter ';'
$of | Group-Object -Property user | Sort-Object -Property Count -Descending | Select-Object -First 10 -Property Count,Name  

# Mime types (from /etc/mime.types) 
[regex]$pattern = '\s{1,}' 
(Get-Content /etc/mime.types) -notmatch '^$|^#' | ForEach-Object { $pattern.Replace($_,';', 1)  } |
     Convertfrom-Csv -Delimiter ';' -Header 'Application','Suffices' 

$mimetypes = (Get-Content /etc/mime.types) -notmatch '^$|^#' | ForEach-Object { $pattern.Replace($_,';', 1)  } | 
    Convertfrom-Csv -Delimiter ';' -Header 'Application','Suffices'
$mimetypes  | Select-Object -First 10 | Format-Table -AutoSize

# Mind the gap: Aliases
Get-Alias -Name ls, ps, wget, curl

# cd ? 
Get-Alias -Name cd

# Where am I? 
Get-Variable -Name is*
