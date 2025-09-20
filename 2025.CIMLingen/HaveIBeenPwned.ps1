####################################################################
## Troy Hunts: Have I been pwned? 
## https://haveibeenpwned.com/API/v3#SearchingPwnedPasswordsByRange
## RegEx: Split after 5 characters from the beginning, e.g.
##        'ABCDE123' -split '(?<=^.{5})'
####################################################################

$password = 'Pa$$w0rd'

$hash = (Get-FileHash -A 'SHA1' -InputStream (
  [IO.MemoryStream]::new([Text.Encoding]::UTF8.GetBytes($password)))
).Hash

$splitA,$splitB = $hash -split '(?<=^.{5})'

$Uri = "https://api.pwnedpasswords.com/range/$splitA"
(((Invoke-RestMethod -UseBasicParsing -Uri $Uri) -split 
  '\r\n' -like "$splitB*") -split ':')[-1]