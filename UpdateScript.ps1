##########################################################################
#
# イベントログチェック
#  スクリプトの自動更新
#
# 2014/11/19 1.00 Git 対応のため新規作成
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

# 変数 Include

$G_RootPath = Join-Path $ScriptDir ".."
$G_CommonPath = Join-Path $G_RootPath "\Core"
$G_ProjectPath = Join-Path $G_RootPath "\Project"
$G_LogPath = Join-Path $G_RootPath "\Log"

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
$G_LogName = "Update"
$Include = Join-Path $G_CommonPath "f_Log.ps1"
if( -not(Test-Path $Include)){
	$temp = Log "[FAIL] 環境異常 $Include が無い"
	exit
}
. $Include

##########################################################################
#
# Main
#
##########################################################################

Log "[INFO] ======= 処理開始 ======="

$TaskPath = $C_ScheduleDir
$TaskName = $C_CheckEventLogTaskName
$FullTaskName = $TaskPath + "\" + $TaskName

# 実行終了しているかの確認
$ScheduleStatus = schtasks /Query /TN $FullTaskName
if($LastExitCode -ne 0){
	Log "[FAIL] スケジュール : $FullTaskName は存在しない"
	exit
}

if( -not(($ScheduleStatus[4] -match "準備完了") -or ($ScheduleStatus[4] -match "無効")) ){
	# 実行終了していなかったら 15 秒待つ
	Log "[INFO] スケジュール : $FullTaskName が終了していないので15秒待つ"
	sleep 15
	$ScheduleStatus = schtasks /Query /TN $FullTaskName
	if($LastExitCode -ne 0){
		Log "[FAIL] スケジュール : $FullTaskName 状態確認失敗"
		Log "[FAIL] ●○●○ 処理異常終了 ●○●○"
		exit
	}
	if( -not(($ScheduleStatus[4] -match "準備完了") -or ($ScheduleStatus[4] -match "無効")) ){
		Log "[FAIL] スケジュール : $FullTaskName 終了せず"
		Log "[FAIL] ●○●○ 処理異常終了 ●○●○"
		exit
	}
}


## プロジェクト 情報更新
$env:path += ";C:\Program Files (x86)\Git\bin"
$env:home = $G_RootPath

cd $G_RootPath

$Output = git pull $C_ProjectRepository | Out-String
if( $LastExitCode -eq 0 ){
	Log "[INFO] プロジェクト 情報更新処理完了 : $G_ProjectPath"
	Log "[INFO] $Output"
}
else{
	Log "[ERROR] プロジェクト 情報更新処理失敗 : $G_ProjectPath"
}

## スクリプト更新
cd $G_CommonPath
$Output = git pull $C_CommonRepository | Out-String
if( $LastExitCode -eq 0 ){
	Log "[INFO] スクリプト更新処理完了 : $G_CommonPath"
	Log "[INFO] $Output"
}
else{
	Log "[ERROR] スクリプト更新処理失敗 : $G_CommonPath"
}

Log "[INFO] ======= 処理終了 ======="
