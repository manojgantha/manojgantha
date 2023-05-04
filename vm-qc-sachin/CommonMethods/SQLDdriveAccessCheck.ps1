$D_Drive = "D:\"
$SQLUser = "MSSQLSERVER"
$permission = (Get-Acl $D_Drive).Access | Where-Object { $_.IdentityReference -match $SQLUser } | Select-Object IdentityReference, FileSystemRights
If ($permission) {
    $permission.FileSystemRights    
}
Else {
    $null
}