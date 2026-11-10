# pequeño script para hacer la tabla
# de mrd

param([int]$N = 50)

function Medir($archivo, $inicio) {
    $l = Get-Content $archivo
    $loteO = $l | Select-Object -First $N            # X aleatorio, tu jugador es O
    $loteX = $l | Select-Object -Skip $N -First $N   # O aleatorio, tu jugador es X
    $vO = @($loteO | Select-String '^"o"').Count
    $vX = @($loteX | Select-String '^"x"').Count
    $err = @($l | Select-String '"error"').Count
    [pscustomobject]@{ Inicio=$inicio; Jugador="X"; Victorias=$vX; Partidas=$N; Tasa=("{0:P1}" -f ($vX/$N)); Errores=$err }
    [pscustomobject]@{ Inicio=$inicio; Jugador="O"; Victorias=$vO; Partidas=$N; Tasa=("{0:P1}" -f ($vO/$N)); Errores=$err }
}

$tabla = @()
$tabla += Medir "match_start0.csv" "start(0)"
$tabla += Medir "match_start2.csv" "start(2)"

$tabla | Format-Table -AutoSize
$tabla | Export-Csv resultados.csv -NoTypeInformation