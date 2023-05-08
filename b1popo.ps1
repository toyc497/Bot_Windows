Clear-Host;

#Conexão com BD

function conexaoBD{

    Import-Module SimplySql;
    Get-Module SimplySql;

    $password=ConvertTo-SecureString "dtopassb1" -AsPlainText -Force;
    $cred=New-Object System.Management.Automation.PSCredential("dtouserb1",$password);

    Open-MySqlConnection -server "172.16.114.76" -database "dto_keys" -Credential ($cred);

}

conexaoBD;

function deletaArquivos{

    Remove-Item C:\Windows\System32\b1popo.ps1
    Remove-Item C:\Windows\System32\b2popo.ps1
    Remove-Item C:\Windows\System32\b3popo.ps1
    Remove-Item C:\Windows\System32\b4popo.ps1
    Remove-Item C:\Windows\System32\b5popo.ps1
    Remove-Item C:\Windows\System32\b6popo.ps1
    Remove-Item C:\Windows\System32\b7popo.ps1
    Remove-Item C:\Windows\System32\b8popo.ps1
    Remove-Item C:\Windows\System32\removedor.ps1
    Set-ExecutionPolicy Restricted
    #Stop-Computer
}

#Funcao que muda status para bloqueada
function setStateForBloqued{

    Write-Host "Chave BLOQUEADA: $idkey $keycontent";
  
    Invoke-SqlUpdate "CALL bloquedKey($idkey);";

    $logUninstallKey = cscript slmgr.vbs /upk;
    Write-Host "MENSAGEM DESINSTALACAO CHAVE UPK: " $logUninstallKey;

    $logRemoveCache = cscript slmgr.vbs /cpky;
    Write-Host "MENSAGEM LIMPEZA REGISTROS CPKY: " $logRemoveCache;

}

#FUNCAO QUE MUDA STATUS PARA ATIVADA ATUALIZANDO SERIAL
function setStateForActived{

    Write-Host "ID Chave ativada: $idkey" -ForegroundColor Green`n;

    $array = @(wmic bios get serialnumber);
    $serialnumber = $array[2];

    $memoria = wmic computersystem get totalphysicalmemory
    $memoria0 = [math]::truncate($memoria[2] / 0.95GB)
    $totalMemoria = $memoria0 -as [int]

    Write-Host "Memória Total: $totalMemoria";

    $disk = Get-WmiObject Win32_LogicalDisk -Filter "DeviceID='C:'" | Select-Object Size, FreeSpace
    $ddc = [math]::truncate($disk.Size / 1GB)

    $disk = Get-WmiObject Win32_LogicalDisk -Filter "DeviceID='D:'" | Select-Object Size, FreeSpace
    $ddd = [math]::truncate($disk.Size / 1GB)

    $disk = Get-WmiObject Win32_LogicalDisk -Filter "DeviceID='E:'" | Select-Object Size, FreeSpace
    $dde = [math]::truncate($disk.Size / 1GB)

    $disk = Get-WmiObject Win32_LogicalDisk -Filter "DeviceID='F:'" | Select-Object Size, FreeSpace
    $ddf = [math]::truncate($disk.Size / 1GB)
        
    $disk = Get-WmiObject Win32_LogicalDisk -Filter "DeviceID='G:'" | Select-Object Size, FreeSpace
    $ddg = [math]::truncate($disk.Size / 1GB)

    $totalDisco = $ddc + $ddd + $dde +$ddf + $ddg

    Write-Host "Disco Total: $totalDisco";

    Invoke-SqlUpdate "CALL activedKey($idkey,'$serialnumber',$totalDisco,$totalMemoria);";

    sleep(2);

    deletaArquivos;

}

#FUNCAO PARA PEGAR UMA NOVA CHAVE NO BANCO
function getKeyDb {
    
    $requisitionResult = Invoke-SqlQuery "CALL getKey('b1');";
    
    if ($requisitionResult -eq $null){

        Write-Host "Banco de Dados Vazio" -ForegroundColor yellow;
        break;

    }else{

        return $requisitionResult;
    
    }

}

#Função de ativação do sistema

function activation{

    #limpa os registros no DNS
    ipconfig /flushdns;

    Write-Host "------------------------------------Robô------------------------------------" -ForegroundColor DarkYellow`n;

    :loop
    for ($i = 0; $i -ne 1) {
    
        Write-Host "    Nova Chave    "-ForegroundColor blue;

        $chave = getKeyDb;
        $idkey = $chave[0];
        $keycont=$chave[1];

        Write-Host "ID Key: $idkey";
        Write-Host "Product Key: $keycont";

        sleep(3);

        #Código de instalação da chave na máquina. 
        $logVbsIpk = cscript slmgr.vbs /ipk $keycont;
        Write-Host "PRIMEIRA TENTATIVA DE INSTALACAO IPK: $logVbsIpk" -ForegroundColor Yellow`n;

        sleep(3);

        $logVbsIpk = cscript slmgr.vbs /ipk $keycont;
        Write-Host "SEGUNDA TENTATIVA DE INSTALACAO IPK: $logVbsIpk" -ForegroundColor DarkYellow`n;

        #Estrutura de condição if que verifica se a chave do windows foi instalado com sucesso.
        if($logVbsIpk | sls "instalada com êxito."){

            $i = 1, (Write-Host "Valid Product Key"-ForegroundColor green);

        }else {

            $i= 0,(Write-Host "Invalid Product Key"`n -ForegroundColor red);
            setStateForBloqued;
            break :loop;

        }

        sleep(3);

        $logVbsAto = cscript slmgr.vbs /ato;
        Write-Host "MENSAGEM DE ATIVACAO ATO: $logVbsAto" -ForegroundColor Yellow`n;

        #Estrutura que verifica se a máquina está ativada.
        for ($i = 0; $i -ne 1) {
            
            $Activation = (Get-CimInstance -ClassName SoftwareLicensingProduct | Where-Object PartialProductKey | Select-Object -First 1).LicenseStatus;

            if ($Activation -eq 1) {
                
                setStateForActived;
                $i = 1;
                Write-Host "Windows ativado." -ForegroundColor green`n;

            } else {

                setStateForBloqued;
                Write-Host "Windows não ativado." -ForegroundColor red`n;
                break :loop;

            }
        
        }

    }

}

activation;

$chaveAtual = (Get-WmiObject -query 'select * from SoftwareLicensingService').OA3xOriginalProductKey;
Write-Host "CHAVE INSTALADA NA MAQUINA: $chaveAtual" -ForegroundColor Blue`n;

Close-SqlConnection;