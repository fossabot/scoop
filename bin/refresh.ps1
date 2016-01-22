# for development, update the installed scripts to match local source
. "$($MyInvocation.MyCommand.Path | Split-Path)\..\lib\core.ps1"

$src = $(rootrelpath ".")
$dest = ensure (versiondir 'scoop' 'current')

# make sure not running from the installed directory
if("$src" -eq "$dest") { abort "$(strip_ext $myinvocation.mycommand.name) is for development only" }

'copying files...'
$output = robocopy $src $dest /mir /njh /njs /nfl /ndl /xd .git tmp /xf .DS_Store last_updated

$output | where-object { $_ -ne "" }

write-output 'creating shim...'
shim "$dest\bin\scoop.ps1" $false

ensure_scoop_in_path
success 'scoop was refreshed!'
