#######################################################
# 証明書復号
#######################################################
function Encrypt(
				$ThumbprintFile,
				$PasswordFile
				){

	if( -not (test-path $PasswordFile )){
		$ErrorMessage = "[FAIL] Encrypt FAIL. Password file " + $PasswordFile + " not found !!"
		Log $ErrorMessage
		return $null
	}

	if( -not (test-path $ThumbprintFile )){
		$ErrorMessage = "[FAIL] Encrypt FAIL. Thumbprint file " + $ThumbprintFile + " not found !!"
		Log $ErrorMessage
		return $null
	}

	### 証明書復号のメイン処理
	# 暗号化や復号化に必要な System.Security アセンブリを読み込む
	Add-type –AssemblyName System.Security

	# 証明書の拇印(Thumbprint)の読み込み
	$Thumbprint = Get-Content $ThumbprintFile

	$CertPath = "cert:\LocalMachine\MY\" + $Thumbprint
	if(-not(test-path $CertPath)){
		$ErrorMessage = "[FAIL] Encrypt FAIL. Certificate not found !!"
		Log $ErrorMessage
		return $null
	}

	# 証明書を取得
	$Cert = get-item $CertPath

	# 暗号化したパスワードの読み込み
	$Password = Get-Content $PasswordFile

	# Base64でエンコードされたパスワードをデコードし、証明書を使って復号化(encrypt)
	$env = new-object Security.Cryptography.Pkcs.EnvelopedCms
	$env.Decode([Convert]::FromBase64String( $Password ))
	$env.Decrypt( $Cert )

	# バイト型からストリング型に変換
	$PlainPassword = [Text.Encoding]::UTF8.GetString($env.ContentInfo.Content)

	# 平文に復号されたパスワード
	return $PlainPassword
}

