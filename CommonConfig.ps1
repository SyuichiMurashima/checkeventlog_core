##########################################################################
#
# イベントログチェック
#  環境設定(共通部分)
#
# 2013/12/27 1.00 新規作成 システム基盤部 村嶋
# 2014/01/03 1.10 Submission & アプリケーションログ対応
# 2014/01/14 1.11 特定イベントのみ監視するオプション追加
# 2014/01/21 1.30 XML 出力対応
# 2014/10/23 2.00 Git 対応構成変更
#
##########################################################################

# スケジュールフォルダー
$C_ScheduleDir = "gloops\CheckEventLog"

# イベントチェックタスク名と実行スクリプト
$C_CheckEventLogTaskName = "Check EventLog Schedule"
$C_CheckEventLogTaskScriptName = "CheckEventLog.ps1"

# 実行ログ削除登録タスク名と実行スクリプト
$C_RemoveExecLogTaskName = "Remove ExecLog Schedule"
$C_RemoveExecLogTaskScriptName = "RemoveExecLog.ps1"

# スクリプト更新登録タスク名と実行スクリプト
$C_UpdateTaskName = "Check Update"
$C_UpdateTaskScriptName = "UpdateScript.ps1"


# 実行ログ保存期間(日)
$C_KeepLog = 5

# 一部のイベントログのみをチェックするか否か
$C_CheckSelectEventLog = $True

# チェックするイベントログ名(一部のイベントログのみチェックする時用)
$C_CheckEventLogNames = @(
							"Application",
							"System"
						)

# イベントを最後に取った日時を保管しているファイル
$GetTimeFile = "GetDate.dat"
$C_GetTimeFile = Join-Path $G_RootPath $GetTimeFile

# 前回処理時間がなかった時の遡及時間(分)
$C_StartDelay = 30

# スキップするログ
$C_SkipLogs = @(
					"Security",
					"Microsoft-Windows-TaskScheduler/Operational"
				)

# スルーするエラーイベント(ソース イベントID)
$C_SkipError = @(
					"OpsMgr Connector 21006",
					"VDS Basic Provider 1",
					"VSS 8193",
					"VSS 7001",
					"volsnap 27",
					"Iphlpsvc 4202",
					"Schannel 36882",
					"Schannel 36888",
					"Schannel 36887",
					"Schannel 36874",
					"Defrag 257",
					"Microsoft-Windows-Defrag 257",
					"Perflib 1008",
					"UmrdpService 1111",
					"TermDD 56",
					"TermDD 50",
					"TermService 1061",
					"DCOM 10016",
					"ESENT 489",
					"MSSQLSERVER 14420",
					"MSSQLSERVER 14421",
					"MSSQLSERVER 17806",
					"MSSQLSERVER 18204",
					"SNMP 1500",
					"DCOM 10006",
					"DCOM 10009",
					"DCOM 10010",
					"Microsoft-Windows-CAPI2 4107",
					"Microsoft-Windows-FilterManager 3",
					"PerfNet 2004",
					"ASP.NET 4.0.30319.0 1325"
				)

# トラップする警告イベント(ソース イベントID)
$C_TrapWarning = @(
					"ixgbn 27",
					"e1rexpress 27",
					"Server Administrator 2094",
					"Server Administrator 2405"
				)

# トラップする情報イベント(ソース イベントID)
$C_TrapInformation = @(
					"Server Administrator 2095"
				)

# イベントの XML 出力をするか
$C_OutputEventXML = $True

### メール
# メール宛先
$C_RcpTo = @(
				"system+eventlog@gloops.com",
				"y.yoda@gloops.com"
			)

# メール送信元
$C_MailFrom = "EventLog@win.monitor.clayapp.jp"

### 認証
# 認証データー ディレクトリー
$C_AuthenticationDir = "C:\Authentication"

# 拇印ファイル
$C_ThumbprintFile = Join-Path $C_AuthenticationDir "InfraBatch.txt"

### サーバー情報
$C_ServerInformation = Join-Path $G_ProjectPath "HostRole.csv"


### リポジトリー
# 共通リポジトリ
$C_CommonRepository = "git@github.com:gloops-sgp/CheckEventLog_Core.git"


### インストール先
$C_InstallRoot = "\CheckEventlog2"

