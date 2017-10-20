##########################################################################
#
# イベントログチェック
#  エラーを見つけたらメールを送る
#
# 2013/12/27 1.00 新規作成 システム基盤部 村嶋
# 2014/01/09 1.10 Submission & アプリケーションログ対応
# 2014/01/14 1.11 指定イベントログのみチェックするオプション追加
# 2014/01/16 1.20 メールをサマる様に変更
# 2014/01/21 1.30 XML 出力するようにした
# 2014/10/27 2.00 Git 対応のため構造から再設計
#
##########################################################################
##### スクリプトが格納されているディレクトリー
# for PS v3
if( $PSVersionTable.PSVersion.Major -ge 3 ){
	$ScriptDir = $PSScriptRoot
}
# for PS v2
else{
	$ScriptDir = Split-Path $MyInvocation.MyCommand.Path -Parent
}

$G_RootPath = Join-Path $ScriptDir ".."
$G_CommonPath = Join-Path $G_RootPath "\Core"
$G_ProjectPath = Join-Path $G_RootPath "\Project"
$G_LogPath = Join-Path $G_RootPath "\Log"

# 変数 Include
$Include = Join-Path $G_CommonPath "CommonConfig.ps1"
if( -not(Test-Path $Include)){
	$temp = Log "[FAIL] 環境異常 $Include が無い"
	exit
}
. $Include

$Include = Join-Path $G_ProjectPath "ProjectConfig.ps1"
if( -not(Test-Path $Include)){
	$temp = Log "[FAIL] 環境異常 $Include が無い"
	exit
}
. $Include

$Include = Join-Path $G_ProjectPath "NodeConfig.ps1"
if( -not(Test-Path $Include)){
	$temp = Log "[FAIL] 環境異常 $Include が無い"
	exit
}
. $Include


# 処理ルーチン
$G_LogName = "EventLogCheck"
$Include = Join-Path $G_CommonPath "f_Log.ps1"
if( -not(Test-Path $Include)){
	$temp = Log "[FAIL] 環境異常 $Include が無い"
	exit
}
. $Include

$Include = Join-Path $G_CommonPath "f_SendMail.ps1"
if( -not(Test-Path $Include)){
	$temp = Log "[FAIL] 環境異常 $Include が無い"
	exit
}
. $Include

$Include = Join-Path $G_CommonPath "f_FomatXML.ps1"
if( -not(Test-Path $Include)){
	$temp = Log "[FAIL] 環境異常 $Include が無い"
	exit
}
. $Include

$Include = Join-Path $G_CommonPath "f_encrypt.ps1"
if( -not(Test-Path $Include)){
	$temp = Log "[FAIL] 環境異常 $Include が無い"
	exit
}
. $Include

##############################################################
# RAID 構成確認
##############################################################
function GatRaidConstitution(){

	$DellServerAdministrator = "C:\Program Files\Dell\SysMgt\oma\bin\omreport.exe"
	if( -not (Test-Path $DellServerAdministrator)){
		return $null
	}

	$Status = cmd /c $DellServerAdministrator storage vdisk

	$RaidControllers = @()

	foreach($Line in $Status){
		if( $Line -match "^Controller (?<Controller>.*?)$"){
			$Controller = $Matches.Controller

			if( $RaidController -ne $null ){
				$RaidController.vDisks = $vDisks
				$RaidControllers += $RaidController
				$RaidController = $null
			}

			$RaidController = New-Object PSObject | Select-Object ControllerName, vDisks
			$RaidController.ControllerName = $Matches.Controller
			$vDisks = @()
		}

		if( $Line -match "^ID +: (?<ID>.*?)$"){
			$ID = $Matches.ID

			$vDisk = New-Object PSObject | Select-Object ID, Layout
			$vDisk.ID = $Matches.ID
		}

		if( $Line -match "^Layout +: (?<Layout>.*?)$"){
			$Layout = $Matches.Layout

			$vDisk.Layout = $Matches.Layout
			$vDisks += $vDisk
		}
	}

	if( $RaidController -ne $null ){
		$RaidController.vDisks = $vDisks
		$RaidControllers += $RaidController
	}

	return $RaidControllers
}


##########################################################################
#
# Main
#
##########################################################################

Log "[INFO] ======= 処理開始 ======="

# ホスト名
$HostName = [Net.Dns]::GetHostName()

# IPv4 アドレス
$IPv4Address = ipconfig | ?{$_ -like "*IPv4*"} | % {($_).split(":")[1].trim()}

# 複数 IPv4 アドレスを持っている場合は最初の有効な IP アドレスをセット
if( $IPv4Address.GetType().Name -ne "String" ){
	foreach( $IPv4 in $IPv4Address){
		if( $IPv4 -match "169.254" ){
			continue
		}
		else{
			$HostIPAddress = $IPv4
			break
		}
	}
}
# IPv4 アドレスが1つの場合はそのままセット
else{
	$HostIPAddress = $IPv4Address
}

# マシン情報
$Manufacturer = (Get-WmiObject Win32_BIOS).Manufacturer
$Model = (Get-WmiObject Win32_ComputerSystem).Model
$ServiceTag = (Get-WmiObject Win32_BIOS).SerialNumber
$OS = (Get-WmiObject Win32_OperatingSystem).Caption
$SP = (Get-WmiObject Win32_OperatingSystem).ServicePackMajorVersion
if( $SP -ne 0 ){
	$OS += " SP" + $SP
}

# RAID 構成
[array]$RaidConstitutions = GatRaidConstitution
if( $RaidConstitutions.Count -eq 0 ){
	$Controller = "Unknown"
	$Raid = "None RAID"
}
else{
	$Controller = $RaidConstitutions[0].ControllerName
	$Raid = $RaidConstitutions[0].vDisks[0].Layout
}


# 前回の処理開始時刻を取得
if( Test-Path $C_GetTimeFile ){
	$StartTime = (Get-Content $C_GetTimeFile) -as [DateTime]
	if($StartTime -eq $null){
		# 正しく取れなかった時は所定時間前
		$StartTime = (Get-Date).AddMinutes(-$C_StartDelay)
	}
}
else{
	# 初めての時は所定時間前
	$StartTime = (Get-Date).AddMinutes(-$C_StartDelay)
}

# 従来のイベントログを処理

# ログ一覧取得
$Logs = Get-EventLog -list

# イベントログ名一覧にする
$LogNames = @()
foreach( $Log in $Logs ){
	# 処理対象ログ名
	$LogNames += $Log.Log
}

# 処理対象のログ名セット
# 指定ログのみチェックの時
$TergetLogNames = @()
if( $C_CheckSelectEventLog ){
	# 正しいイベントログ名かのチェック
	foreach( $CheckEventLogName in $C_CheckEventLogNames ){
		if( $LogNames -contains $CheckEventLogName ){
			$TergetLogNames += $CheckEventLogName
		}
		else{
			Log "[ERROR] $CheckEventLogName はイベントログではない"
		}
	}
}
# 全てのイベントログをチェックする
else{
	$TergetLogNames = $LogNames
}

$ProcessedLog = @() # WinEvent での処理スキップ用配列

# 実行時刻の記録
(Get-Date) -as [String] | Set-Content $C_GetTimeFile
Log "[INFO] イベントログ 収集開始時刻 : $StartTime"


# スキップするエラー
$SkipError = $C_SkipError

# トラップする警告
$TrapWarning  = $C_TrapWarning + $C_ProjectTrapWarning

# トラップする情報
$TrapInformation = $C_TrapInformation + $C_ProjectTrapInformation

foreach( $TergetLogName in $TergetLogNames ){
	# WinEvent での処理スキップ用配列作成
	$ProcessedLog += $TergetLogName

	Log "[INFO] $TergetLogName のエラーイベントログ収集開始"

	# スキップ対象外のログ
	if( -not ($C_SkipLogs -contains $TergetLogName) ){
		$EventLogs = ""
		# イベントログ取得
		$EventLogs = Get-EventLog -LogName $TergetLogName -After $StartTime

		# ログがあった場合
		if( $EventLogs.Length -gt 0 ){
			# ソースとIDでグループ化
			$EventLogSams = $EventLogs | Group -Property Source,EventID

			# サマリ単位でチェック
			foreach( $EventLogSam in $EventLogSams ){
				#イベントタイプの取得
				$EventType = $EventLogSam.Group[0].EntryType

				# ソース、IDの取得
				$Source = $EventLogSam.Name.split(",")[0].trim()
				$ID = $EventLogSam.Name.split(",")[1].trim()

				# サマリー数の取得
				$Count = $EventLogSam.Count

				# チェック用にイベントID加工
				$ChkEvent = $Source + " " + $ID

				Switch($EventType){
					"Error"{	# エラーの時
						if( $SkipError -contains $ChkEvent){
							# スキップ対象なのでスキップする
							$TrapEvent = $False
						}
						else{
							# トラップする
							$TrapEvent = $True
							$RcpTos = $C_RcpTo + $C_ProjectErrorRcpTo
						}
					}

					"Warning"{ # 警告の時
						if( $TrapWarning -contains $ChkEvent){
							# トラップ対象なのでトラップする
							$TrapEvent = $True
							$RcpTos = $C_RcpTo + $C_ProjectWarningRcpTo
						}
						else{
							# スキップする
							$TrapEvent = $False
						}
					}

					"Information"{ # 情報の時
						if( $TrapInformation -contains $ChkEvent){
							# トラップ対象なのでトラップする
							$TrapEvent = $True
							$RcpTos = $C_RcpTo + $C_ProjectInformationRcpTo
						}
						else{
							# スキップする
							$TrapEvent = $False
						}
					}

					default { # 誤動作対策
							$ErrorMessage = "[Warning] " + $TergetLogName + " / " + $EventType + " / " + $ChkEvent
							Log $ErrorMessage
							$TrapEvent = $False
					}
				}

				if( $TrapEvent ){
					# トラップするイベントの時
					# イベント取得
					$HitEventLogs = $EventLogs | ? {($_.Source -eq $Source) -and ($_.EventID -eq $ID) }

					# 1件だけの時
					if( $Count -eq 1 ){
						$EventTime = $HitEventLogs.TimeGenerated
						$EventSource = $HitEventLogs.Source
						$EventID = $HitEventLogs.EventID
						$EventMessage = $HitEventLogs.Message
						$EventIndex = $HitEventLogs.Index
					}
					# 複数記録されていたときは先頭
					else{
						$EventTime = $HitEventLogs[0].TimeGenerated
						$EventSource = $HitEventLogs[0].Source
						$EventID = $HitEventLogs[0].EventID
						$EventMessage = $HitEventLogs[0].Message
						$EventIndex = $HitEventLogs[0].Index
					}
					$EventCount = $Count
					if($C_OutputEventXML){
						$WinEvent = Get-WinEvent -LogName $TergetLogName | ? { (($_.ProviderName -eq $EventSource) -and ($_.RecordId -eq $EventIndex))}
						$EventXML = $WinEvent.ToXML()
						$EventXMLData = Format-XML $EventXML 2
					}
					else{
						$EventXMLData = ""
					}
					MailSend `
							$C_MSA `
							$C_MailFrom `
							$RcpTos `
							$C_ProjectName `
							$EventType `
							$Manufacturer `
							$Model `
							$ServiceTag `
							$Controller `
							$Raid `
							$OS `
							$HostName `
							$C_CNAME `
							$C_ServerType `
							$HostIPAddress `
							$TergetLogName `
							$EventTime `
							$EventSource `
							$EventID `
							$EventMessage `
							$EventCount `
							$EventXMLData
				}
				else{
					if($C_Debug){
						Log "[INFO] $TergetLogName / $EventType / $ChkEvent は検出対象外のためスルー"
					}
				}
			}
		}
		else{
			Log "[INFO] $TergetLogName にログが存在しない"
		}
	}
	else{
		Log "[INFO] $TergetLogName は処理対象外なのでスキップ"
	}
}

# アプリケーションとサービスログ指定があればチェックする
if( ($C_CheckAppLogNames.Length -ne 0) -and ($C_CheckAppLogNames -ne $null ) ){
	# 処理対象のログ一覧取得
	$Logs = @()
	foreach( $CheckAppLogName in $C_CheckAppLogNames ){
		$Logs += Get-WinEvent -ListLog $CheckAppLogName
	}

	foreach( $Log in $Logs ){
		# 処理対象ログ名
		$TergetLogName = $Log.LogName

		Log "[INFO] $TergetLogName のエラーイベントログ収集開始"

		# スキップログ
		if( -not ($C_SkipLogs -contains $TergetLogName) ){
			# 処理済みのログ
			if( -not ($ProcessedLog -contains $TergetLogName) ){
				$EventLogs = ""
				# イベントログ取得
				$EventLogs = Get-WinEvent -LogName $TergetLogName | ? {$_.TimeCreated -ge $StartTime}

				# ログがあった場合
				if( $EventLogs.Length -gt 0 ){
					# ソースとIDでグループ化
					$EventLogSams = $EventLogs | Group -Property ProviderName,Id

					# サマリ単位でチェック
					foreach( $EventLogSam in $EventLogSams ){
						#イベントタイプの取得
						$EventLevel = $EventLogSam.Group[0].Level

						# ソース、IDの取得
						$Source = $EventLogSam.Name.split(",")[0].trim()
						$ID = $EventLogSam.Name.split(",")[1].trim()

						# サマリー数の取得
						$Count = $EventLogSam.Count

						# チェック用にイベントID加工
						$ChkEvent = $Source + " " + $ID

						Switch($EventLevel){
							2 {	# エラーの時
								$EventType = "Error"
								if( $SkipError -contains $ChkEvent){
									# スキップするエラー
									$TrapEvent = $False
								}
								else{
									# トラップするエラー
									$TrapEvent = $True
									$RcpTos = $C_RcpTo + $C_ProjectErrorRcpTo
								}
							}

							3 { # 警告の時
								$EventType = "Warning"
								if( $TrapWarning -contains $ChkEvent){
									# トラップする警告
									$TrapEvent = $True
									$RcpTos = $C_RcpTo + $C_ProjectWarningRcpTo
								}
								else{
									# スキップする警告
									$TrapEvent = $False
								}
							}

							4 { # 情報の時
								$EventType = "Information"
								if( $TrapInformation -contains $ChkEvent){
									# トラップする情報
									$TrapEvent = $True
									$RcpTos = $C_RcpTo + $C_ProjectInformationRcpTo
								}
								else{
									# スキップする情報
									$TrapEvent = $False
								}
							}

							default { # 誤動作対策
									$ErrorMessage = "[Warning] " + $TergetLogName + " / " + $EventLevel + " / " + $ChkEvent
									Log $ErrorMessage
									$TrapEvent = $False
							}
						}

						if( $TrapEvent -eq $True ){
							# イベント取得
							$HitEventLogs = $EventLogs | ? {($_.ProviderName -eq $Source) -and ($_.Id -eq $ID) }

							# 1件だけの時
							if( $Count -eq 1 ){
								$EventTime = $HitEventLogs.TimeCreated
								$EventSource = $HitEventLogs.ProviderName
								$EventID = $HitEventLogs.Id
								$EventMessage = $HitEventLogs.Message
								$EventXML = $HitEventLogs.ToXML()
							}
							# 複数記録されていたときは先頭
							else{
								$EventTime = $HitEventLogs[0].TimeCreated
								$EventSource = $HitEventLogs[0].ProviderName
								$EventID = $HitEventLogs[0].Id
								$EventMessage = $HitEventLogs[0].Message
								$EventXML = $HitEventLogs[0].ToXML()
							}
							$EventCount = $Count
							$EventXMLData = Format-XML $EventXML 2
							MailSend `
									$C_MSA `
									$C_MailFrom `
									$RcpTos `
									$C_ProjectName `
									$EventType `
									$Manufacturer `
									$Model `
									$ServiceTag `
									$Controller `
									$Raid `
									$OS `
									$HostName `
									$C_CNAME `
									$C_ServerType `
									$HostIPAddress `
									$TergetLogName `
									$EventTime `
									$EventSource `
									$EventID `
									$EventMessage `
									$EventCount `
									$EventXMLData
						}
						else{
							if($C_Debug){Log "[INFO] $TergetLogName / $EventType / $ChkEvent は検出対象外のためスルー"}
						}
					}
				}
				else{
					Log "[INFO] $TergetLogName にログは存在しない"
				}
			}
			else{
				Log "[INFO] $TergetLogName は処理済なのでスキップ"
			}
		}
		else{
			Log "[INFO] $TergetLogName は処理対象外なのでスキップ"
		}
	}
}

Log "[INFO] ======= 処理終了 ======="
