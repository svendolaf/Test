param (
    [Parameter(Mandatory=$true)][string]$FileName
 )

foreach($l in get-content $FileName){

    if ($l -match "^0[0-9a-fA-F]+:"){
        $c = ([int]("0x"+$l.substring(10,2)))
        Write-Host -NoNewline $l.substring(0, 9) " "
        if ($c -ge 32 -and $c -le 128){
            Write-Host -NoNewline ([char] $c)
        }
        else {
            Write-Host -NoNewline $c
        }
        Write-Host -NoNewline " "
        $c = ([int]("0x"+$l.substring(13,2)))
        if ($c -ge 32 -and $c -le 128){
            [char] $c
        }
        else {
            $c
        }
    }
}