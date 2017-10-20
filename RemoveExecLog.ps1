##########################################################################
#
# ログ削除(For イベントログチェック)
#
##########################################################################
#
#	2014/01/07 Ver 1.0
#	2014/10/30 Ver 2.0 Git 対応
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
$G_LogName = "LogRemove"
$Include = Join-Path $G_CommonPath "f_Log.ps1"
if( -not(Test-Path $Include)){
	$temp = Log "[FAIL] 環境異常 $Include が無い"
	exit
}
. $Include

##########################################################################
# Main
##########################################################################

Log "[INFO] =========== 処理開始 ==========="

$TergetFolder = Join-Path $G_LogPath "*.log"

# 指定フォルダーが存在していなかった
if( -not (Test-Path $TergetFolder) ){
	Log "[Error] $TergetFolder が存在しません"
}
else{
	# 今日の日付
	$Now = Get-Date

	# 削除する日
	$DeleteDate = $Now.AddDays(-$C_KeepLog)

	# ファイル一覧取得
	$Files = Get-ChildItem $TergetFolder | ? {$_.Attributes -ne "Directory"}

	Log "[INFO] -=-=-=-=-=-= $TergetFolder の $DeleteDate 以前のファイル削除 -=-=-=-=-=-="

	foreach( $File in $Files ){
		# PS 2 バグっているぽいので、不可思議な動作迂回
		if( $File.Name -ne $null ){
			# 保管期間よりファイル
			$Date = $File.LastWriteTime
			$FileName = $File.FullName
			if( ($File.GetType().Name -eq "FileINFO") -and ( $Date -le $DeleteDate )){
				Log "[INFO] Remove $FileName ($Date)"
				Remove-Item $FileName -Force
			}
		}
		else{
			Log "[ERROR] PowerShell 2.0 Get-ChildItem Bug Trap !! 処理は正常に実行されています"
		}
	}
}

Log "[INFO] =========== 処理終了 ==========="
