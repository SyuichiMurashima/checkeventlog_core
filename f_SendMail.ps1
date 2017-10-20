##########################################################################
#
# メール送信
#
# f_encrypt.ps1
# メインで include する
#
##########################################################################
function MailSend(
		$MSA,				# メールサーバー
		$MailFrom,			# 送信元
		$RcpTos,			# 宛先
		$ProjectName,		# プロジェクト名
		$Mode,				# モード(エラーとか)
		$Manufacturer,		# メーカー
		$Model,				# モデル
		$ServiceTag,		# サービスタグ
		$Controller,		# RAID コントローラー
		$Raid,				# RAID 構成
		$OS,				# OSバージョン
		$HostName,			# ホスト名
		$CNAME,				# CNAME
		$ServerType,		# サーバータイプ
		$HostIPAddress,		# IP アドレス
		$LogName,			# イベントログ名
		$EventTime,			# イベント発生日時
		$EventSource,		# イベントソース
		$EventID,			# イベント ID
		$EventMessage,		# メッセージ
		$EventCount,		# 発生件数
		$EventXMLData = ""	# XML データー
	){

	switch( $Mode ){
		"Error" { # エラー
			$SubjectSting = "エラーを検出しました"
			$Status = "Error"
		}

		"Warning" { # 警告
			$SubjectSting = "指定の警告を検出しました"
			$Status = "Warning"
		}

		"Information" { # 情報
			$SubjectSting = "指定の情報を検出しました"
			$Status = "Information"
		}
	}

	# メールデーター作成
	$Mail = New-Object Net.Mail.MailMessage
	$Mail.From = $MailFrom

	# 宛先
	foreach( $RcpTo in $RcpTos ){
		$Mail.To.Add($RcpTo)
		if( $C_Debug ){ Log "[DEBUG] RcpTo:$RcpTo" }
	}

	$Mail.Subject = "【$ProjectName】イベントログに$SubjectSting $HostName($ServerType) / $EventSource / $EventID"
	$Mail.Body =
		"$Status イベントログ情報( $EventCount 件)`n" +
		"-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-`n" +
		"Status         : $Status`n" +
		"Project Name   : $ProjectName`n" +
		"Host Name      : $HostName`n" +
		"CNAME          : $CNAME`n" +
		"Server Type    : $ServerType`n" +
		"IP Address     : $HostIPAddress`n" +
		"Manufacturer   : $Manufacturer`n" +
		"Model          : $Model`n" +
		"Service Tag    : $ServiceTag`n" +
		"RAID Controller: $Controller`n" +
		"RAID Layout    : $Raid`n" +
		"OS             : $OS`n" +
		"Log Name       : $LogName`n" +
		"Generated Time : $EventTime`n" +
		"Event Source   : $EventSource`n" +
		"Event ID       : $EventID`n" +
		"Message :`n" +
		"$EventMessage`n"

	if($C_OutputEventXML){
		$Mail.Body += "XML :`n" +
		"$EventXMLData`n"
	}
	$Mail.Body +=
		"-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-"

	Log "[INFO] $Status イベントログ情報( $EventCount 件)"
	Log "[INFO] -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-"
	Log "[INFO] Status         : $Status"
	Log "[INFO] ProjectName    : $ProjectName"
	Log "[INFO] Host Name      : $HostName"
	Log "[INFO] CNAME          : $CNAME"
	Log "[INFO] Server Type    : $ServerType"
	Log "[INFO] IP Address     : $HostIPAddress"
	Log "[INFO] Manufacturer   : $Manufacturer"
	Log "[INFO] Model          : $Model"
	Log "[INFO] Service Tag    : $ServiceTag"
	Log "[INFO] RAID Controller: $Controller"
	Log "[INFO] RAID Layout    : $Raid"
	Log "[INFO] OS             : $OS"
	Log "[INFO] Log Name       : $LogName"
	Log "[INFO] Generated Time : $EventTime"
	Log "[INFO] Event Source   : $EventSource"
	Log "[INFO] Event ID       : $EventID"
	Log "[INFO] Message :"
	Log "[INFO] $EventMessage"
	if($C_OutputEventXML){
		Log "[INFO] XML :"
		Log "[INFO] $EventXMLData"
	}
	Log "[INFO] -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-"

	# メール送信
	if( -not $C_Debug ){
		# SubMission
		if( $C_Submission ){
			$Password = $null
			$Password = Encrypt $C_ThumbprintFile $C_SMTPPasswordFile
			if( $Password -ne $null ){
				$SmtpClient = New-Object Net.Mail.SmtpClient($MSA, 587)
				$SmtpClient.Credentials = New-Object System.Net.NetworkCredential($MailFrom, $Password)
			}
		}
		# TCP/25
		else{
			$SmtpClient = New-Object Net.Mail.SmtpClient($MSA)
		}

		try{
			$SmtpClient.Send($Mail)
		}
		catch [Exception]{
			Log "[ERROR] $Status メール送信に失敗しました MSA : $MSA"
		}

		Log "[INFO] $Status $LogName $EventTime $EventSource $EventID mail sended"
		$Mail.Dispose()
	}
	else{
		Log "[DEBUG] メール送信抑制"
	}
}

