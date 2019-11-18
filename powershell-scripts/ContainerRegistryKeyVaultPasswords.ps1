$RegistryCredentials =  Get-AzContainerRegistry | Get-AzContainerRegistryCredential

$RegistryPw1 = ConvertTo-SecureString -string $RegistryCredentials.Password -AsPlainText -Force
Set-AzKeyVaultSecret -VaultName $ENV:KeyVaultName -Name "RegistryPassword1" -SecretValue $RegistryPw1

$RegistryPw2 = ConvertTo-SecureString -string $RegistryCredentials.Password2 -AsPlainText -Force
Set-AzKeyVaultSecret -VaultName $ENV:KeyVaultName -Name "RegistryPassword2" -SecretValue $RegistryPw2