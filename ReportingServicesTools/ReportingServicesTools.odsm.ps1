# Octopus deploy module export
$mainScript = "$PSScriptRoot\ReportingServicesTools.Designer.ps1"
@('# AUTO GENERATED SCRIPT', '# SOURCE https://github.com/microsoft/ReportingServicesTools') | sc -path $mainScript 
gc "$PSScriptRoot\Libraries\library.ps1" | ac -path $mainScript -Encoding UTF8

$mainScript

$scripts =  Get-ChildItem "$PSScriptRoot\Functions" -Recurse -Include *.ps1
foreach ($script in $scripts) { gc $script | ac -path $mainScript -Encoding UTF8 }