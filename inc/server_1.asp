<%

' 防止该文件被浏览器直接查看
Response.AddHeader "Content-Type", "text/html"
Response.AddHeader "Cache-Control", "no-store"

'###########数据库设置
SQL_Server="127.0.0.1,65101"
SQL_UserName="sa"
SQL_PassWord="zzgm99w4$1"
DBName		= "account"
DBName_b	= "cash"
DBName_c     = "character"


'###########基础设置
ServerName="乱世挑战"								'服务器名称"
openlevel=200												'网页显示开放等级	
ReName_Money=50000000		                '改名所需金币
PK_Money=200000									 '每洗一点所需金币
ChangeJob_Money=2000000000				'转职需要多少钱


'###########系统开关设置 ，0为关闭，1为开放
enableReg=1												'是否开放 注册系统 ，0为关闭，1为开放，2为注册后手动激活"
enableRename=1										'是否开放改名系统 ，0为关闭，1为开放"
Rename_Time=7										'改名间隔天数
regname=2025											' 注册帐号ID编号前缀,100和200之间,方便合区
IsGift	=1													'是否开放 领取礼包
IsExchange=1											'是否开放 兑换商城币
IsChangeJob	=1										'是否开放 转职
IsShop=1													'是否开放 寄售道具
IsPay=1														'是否开放 在线充值
IsExchangeItem=1										'是否开放 道具兑换

'###########转生设置
Upgrade_Money=1000000000				'转生需要多少钱
Upgrade_Level=200			'转生需要多少级
Upgrade_AddSkil=10			'转生后赠送多少技能点
Max_Upgrade=50			'最高转生次数


'###########交易大厅设置
admin_character="E24080630000000032"'仓库管理员角色ID
max_sell=10												'个人卖家最多发布商品数量


Give_Money=200000000
Give_Money2=200000000
Mypagesize=10				'每页显示商品数量	
Lucky_cdate1="2016-7-1"				'创建时间1
Lucky_cdate1_exp=1.5				'倍率1加成
Lucky_cdate2="2016-7-1"				'创建时间2
Lucky_cdate1_exp=2					'倍率2加成
Lucky_cdate3="2016-7-1"				'创建时间3
Lucky_cdate1_exp=3					'倍率3加成

need_maya=5				'兑换5点商城币需要金币数量
need_Money=50000000		'兑换10点商城币需要金币数量
need_PPoint=5000000		'兑换10点商城币需要p点数量
%>