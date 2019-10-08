#Central Server
Import-Module dbatools -Force

Set-DbaToolsConfig -Name 'psremoting.pssession.usessl' -Value $true
Set-DbaToolsConfig -Name 'psremoting.pssessionoption.includeportinspn' -Value $true

$centralServer = "CentralServer"
$centralDatabase = "dbatools"
$throttle = 10

#Every one
$invokeQuerySplatting = @{
    SqlInstance = $centralServer
    Database = $centralDatabase
    Query = "SELECT FQDN FROM vGetInstances WHERE DOMAIN LIKE '$env:UserDomain%' ORDER BY 1"
}
$ServerList = Invoke-DbaQuery @invokeQuerySplatting | Select-Object -ExpandProperty FQDN


$sb = {
    param (
        $pcentralServer
        ,$pcentralDatabase
    )

    $dt = Get-DbaDiskSpace -ComputerName $_
    $dt | Add-Member -MemberType NoteProperty -Name CollectionTime -Value $(Get-Date)
    $dt | Write-DbaDataTable -SqlInstance $pcentralServer -Database $pcentralDatabase -Table "[DiskSpace]" -Schema "dbo" -AutoCreateTable
}

#region multi-thread
$ServerList | Start-RSJob -ScriptBlock $sb -Throttle $throttle -ArgumentList $centralServer, $centralDatabase | Wait-RsJob | Receive-RsJob

#Clean up
Get-RsJob | Remove-RsJob
