#region Import Classes
If (Test-Path "$PSScriptRoot\functions\classes") {
  $ClassesList = Get-ChildItem -Path "$PSScriptRoot\functions\classes"

  ForEach ($File in $ClassesList) {
    . $File.FullName
    Write-Verbose -Message ('Importing class file: {0}' -f $File.FullName)
  }
}
#region Import Private Functions
if (Test-Path "$PSScriptRoot\functions\private") {
  $FunctionList = Get-ChildItem -Path "$PSScriptRoot\functions\private";

  foreach ($File in $FunctionList) {
      . $File.FullName;
      Write-Verbose -Message ('Importing private function file: {0}' -f $File.FullName);
  }
}
#endregion

#region Import Public Functions
if (Test-Path "$PSScriptRoot\functions\public") {
  $FunctionList = Get-ChildItem -Path "$PSScriptRoot\functions\public";

  foreach ($File in $FunctionList) {
      . $File.FullName;
      Write-Verbose -Message ('Importing public function file: {0}' -f $File.FullName);
  }
}
#endregion


### Export all functions
Export-ModuleMember -Function *;
