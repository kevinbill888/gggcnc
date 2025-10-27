<!--#include file="inc/conn.asp" -->
<!--#include file="inc/char.asp" -->
<!--#include file="inc/md5.asp" -->
<!--#include file="inc/jmail.asp" -->
<!DOCTYPE html>
<html>
  <head>
    <title>网通挑战</title>
    <meta http-equiv="Content-Type" content="text/html; charset=UTF-8" />
    <meta name="keywords" content="挑战" />
    <meta name="description" content="本站是专门为广大挑战玩家第一时间提供最好、最新的挑战挑战及挑战相关资料的专业网站!" />
        <link rel="icon" type="image/png" href="static/image/favicon.png">
    <link rel="stylesheet" type="text/css" href="static/css/sweetalert.css" />
    <script type="text/javascript" src="http://apps.bdimg.com/libs/jquery/1.8.3/jquery.min.js"></script>
    <script type="text/javascript" src="static/js/sweetalert.min.js"></script>
	</head>
  <body>
<%
Response.Buffer = True 
Response.ExpiresAbsolute = Now() - 1 
Response.Expires = 0 
Response.CacheControl = "no-cache" 
Response.AddHeader "Pragma", "No-Cache"

Action = Request("Action")
Action2 = Request("Action2")
Select Case Action
    Case "ModifySave"
        ModifySave()
	Case "RegSave"
        RegSave()
    Case "Login"
        Login()
    Case "Quit"
        Quit()
    Case"ChangeJobSave"
        ChangeJobSave()
    Case"UpgradeSave"
        UpgradeSave()
	Case "Move"			'卡号自救
         Move()
	Case "GetPwdMail"	'取回密码发信
        GetPwdMail()
    Case "ClaimVIPGift"
    ClaimVIPGift()
End Select


'-------------------------------vip--------------------------'
Sub ClaimVIPGift()
    If Not ChkLogin Then
        Response.Write "<script>swal({title: ""错误!"",text: ""请先登录!"",type: ""error""});</script>"
        response.End
    End If
    
    If Not ChkPost Then
        Response.Write "<script>swal({title: ""安全错误!"",text: ""检测到非法访问!"",type: ""error""});</script>"
        response.End
    End If
    
    giftID = checkstr(Request("gift_id"))
    characterNo = checkstr(Request("character_no"))
    vipLevel = checkstr(Request("vip_level"))
    
    ' 验证参数
    If Not IsNumeric(giftID) Or Not IsNumeric(vipLevel) Then
        Response.Write "<script>swal({title: ""错误!"",text: ""参数错误!"",type: ""error""});</script>"
        response.End
    End If
    
    ' 获取用户VIP等级
    Set rsVIP = conn.Execute("SELECT vip_level FROM User_VIP WHERE user_no='"&session("user_no")&"'")
    If rsVIP.EOF Then
        currentVIP = 0
    Else
        currentVIP = rsVIP("vip_level")
    End If
    rsVIP.Close
    
    ' 检查VIP等级是否足够
    If currentVIP < CInt(vipLevel) Then
        Response.Write "<script>swal({title: ""错误!"",text: ""您的VIP等级不足!"",type: ""error""});</script>"
        response.End
    End If
    
    ' 检查是否已领取
    Set rsClaimed = conn.Execute("SELECT COUNT(*) as cnt FROM VIP_Claim_Logs WHERE user_no='"&session("user_no")&"' AND gift_id="&giftID)
    If rsClaimed("cnt") > 0 Then
        Response.Write "<script>swal({title: ""错误!"",text: ""您已经领取过这个礼包了!"",type: ""error""});</script>"
        response.End
    End If
    rsClaimed.Close
    
    ' 获取礼包信息
    Set rsGift = conn.Execute("SELECT * FROM VIP_Gifts WHERE gift_id="&giftID)
    If rsGift.EOF Then
        Response.Write "<script>swal({title: ""错误!"",text: ""礼包不存在!"",type: ""error""});</script>"
        response.End
    End If
    
    giftType = rsGift("gift_type")
    itemCode = rsGift("item_code")
    itemName = rsGift("item_name")
    itemCount = rsGift("item_count")
    rsGift.Close
    
    ' 根据礼包类型发放奖励
    Select Case giftType
        Case "cash"
            ' 发放金币
            Set rsChar = conn_c.Execute("SELECT dwmoney FROM User_Character WHERE user_no='"&session("user_no")&"' AND Character_no='"&characterNo&"'")
            If Not rsChar.EOF Then
                newMoney = CLng(rsChar("dwmoney")) + CLng(itemCount)
                conn_c.Execute("UPDATE User_Character SET dwmoney="&newMoney&" WHERE user_no='"&session("user_no")&"' AND Character_no='"&characterNo&"'")
            End If
            rsChar.Close
            
        Case "money"
            ' 发放商城币
            ' 这里需要根据你的商城系统来实现
            ' 假设有一个 User_Money 表
            Set rsMoney = conn.Execute("SELECT money FROM User_Money WHERE user_no='"&session("user_no")&"'")
            If rsMoney.EOF Then
                conn.Execute("INSERT INTO User_Money (user_no, money) VALUES ('"&session("user_no")&"', "&itemCount&")")
            Else
                newMoney = CLng(rsMoney("money")) + CLng(itemCount)
                conn.Execute("UPDATE User_Money SET money="&newMoney&" WHERE user_no='"&session("user_no")&"'")
            End If
            rsMoney.Close
            
        Case "item"
            ' 发放物品到游戏背包
            ' 这里需要根据你的物品系统来实现
            ' 假设有一个 User_Item 表
            conn.Execute("INSERT INTO User_Item (user_no, character_no, item_code, item_count) VALUES ('"&session("user_no")&"', '"&characterNo&"', '"&itemCode&"', "&itemCount&")")
    End Select
    
    ' 记录领取日志
    conn.Execute("INSERT INTO VIP_Claim_Logs (user_no, vip_level, gift_id, character_no) VALUES ('"&session("user_no")&"', "&vipLevel&", "&giftID&", '"&characterNo&"')")
    
    Response.Write "<script>swal({title: ""成功!"",text: ""VIP礼包领取成功!"",type: ""success""});</script>"
End Sub
'----------------------------------------注册-----------------------------'
Sub RegSave()

If enableReg<>1 Then 
	Response.Write "<script>swal({title: ""错误!"",text: ""系统暂时不开放注册，请联系管理员!"",type: ""error"",}, function() {location = 'user.asp';});</script>"
	response.End
 End If 
UserName=checkstr(trim(Request.form("user")))
'Email=trim(Request.form("email"))
Password=trim(request.form("pwd"))
RE_Password=trim(request.form("re_pwd"))
qq=trim(request.form("qq"))
tel=trim(request.form("tel"))
code=Trim(Request.Form("imgcode"))
telcode=Trim(Request.Form("telcode"))


	If code=""  Then
		Response.Write "<script>swal({title: ""错误!"",text: ""验证码错误,请返回重新输入!"",type: ""error"",}, function() {history.go(-1);});</script>"
		response.end
	end If

	If  Not isnumeric(code) Or Int(Session("getCode"))<>int(code) Then
		Response.Write "<script>swal({title: ""错误!"",text: ""图形验证码错误,请返回重新输入!"",type: ""error"",}, function() {history.go(-1);});</script>"
		response.end
	end If

	If session("DkServer")=1 then
		If  Not isnumeric(telcode) Or Int(Session("smscode"))<>int(telcode) Then
			Response.Write "<script>swal({title: ""错误!"",text: ""短信码错误,请返回重新输入!"",type: ""error"",}, function() {history.go(-1);});</script>"
			response.end
		end If
	end If

	if UserName="" or len(UserName)<5 or len(UserName)>12 Then
		 Response.Write "<script>swal({title: ""错误!"",text: ""用户名错误,请重新输入!"",type: ""error"",}, function() {history.go(-1);});</script>"
		 response.end
	elseif CheckIfEnglish(UserName) Then
		Response.Write "<script>swal({title: ""错误!"",text: ""用户名含有特殊字符,请重新输入!"",type: ""error"",}, function() {history.go(-1);});</script>"
		response.end
	end if

	set rs1=conn.execute("select user_id from user_profile where user_id = '"&UserName&"'")
	if not (rs1.EOF and rs1.bof) Then
		Response.Write "<script>swal({title: ""错误!"",text: ""用户名已经被注册,请重新输入!"",type: ""error"",}, function() {history.go(-1);});</script>"
		response.end
	end If


	if len(Password) < 6 or len(Password)>16 or Password=""  then 
		Response.Write "<script>swal({title: ""错误!"",text: ""密码长度在6到16位之间,请重新输入!"",type: ""error"",}, function() {history.go(-1);});</script>"
		response.end
	end If

	if Password <> Re_Password then 
		Response.Write "<script>swal({title: ""错误!"",text: ""两次密码不相同,请重新输入!"",type: ""error"",}, function() {history.go(-1);});</script>"
		response.end
	end if 

	'if len(qq) < 5 or len(qq)>11  Or IsNumeric(qq)=0  then 
	'	Response.Write "<script>swal({title: ""错误!"",text: ""QQ号码不正确,请重新输入!"",type: ""error"",}, function() {history.go(-1);});</script>"
	'	response.end
	'end If

	if len(tel)<>11  Or IsNumeric(tel)=0  then 
		Response.Write "<script>swal({title: ""错误!"",text: ""手机号码不正确,请重新输入!"",type: ""error"",}, function() {history.go(-1);});</script>"
		response.end
	end If


	if Password=UserName then 
		Response.Write "<script>swal({title: ""错误!"",text: ""密码不能和用户名相同!"",type: ""error"",}, function() {history.go(-1);});</script>"
		response.end
	end if

	'if IsValidEmail(Email)=false Then
	'	Response.Write "<script>swal({title: ""错误!"",text: ""电子邮件错误，请返回重新输入!"",type: ""error"",}, function() {history.go(-1);});</script>"
	'	response.end
	'end If


	SET RS = Conn.Execute("select count(user_no) from user_profile")
		num=rs(0)+1
	rs.close
	num=regname&Right("00000000000"&num,11)
	regip=Request.serverVariables("REMOTE_ADDR")

	sql="INSERT INTO user_profile (user_no,user_id,user_pwd,resident_no,password,reg_qq,tel,regip) VALUES ('"&num&"','"&UserName&"','"&md5(Password)&"','801011000000','"&Password&"',"&qq&","&tel&",'"&regip&"')"
	set rs=conn.execute(sql)
	set rs=nothing
	conn.close
	set conn=Nothing
	Session("smscode")=""

	if err then 
		Response.Write "<script>swal({title: ""错误!"",text: ""出现未知错误,请联系管理员解决!"",type: ""error"",}, function() {history.go(-1);});</script>"
	else		
		Response.Write "<script>swal({title: ""账号注册成功"",text: ""恭喜,您的帐号已注册成功,您的账号为: "&UserName&" ,请牢记宁的账号及密码,祝您游戏愉快!"",type: ""success"",}, function() {location = 'index.asp';});</script>"
	End  If 
	
End Sub




Sub PK()
    If Not ChkLogin Then
			response.redirect "?Action=UserLogin&Url="&Server.URLEncode("User.asp?Action2=PK")
			response.end
    End If

    If Not ChkPost Then
        Response.Write "<script>swal({title: ""安全错误!"",text: ""检测到非法访问，请通过正常页面进行操作!"",type: ""error"",}, function() {history.go(-1);});</script>"
        response.End
    End If

    Id = checkstr(Request("Id"))

    If IsNull(Id) Then
        Response.Write "<script>swal({title: ""参数错误!"",text: ""角色ID参数丢失，请重新选择角色!"",type: ""error"",}, function() {history.go(-1);});</script>"
        Response.End
    End If

    If Not ChkOnLine Then
		Response.Write "<script>swal({title: ""错误!"",text: ""系统检测到您当前的游戏状态为在线,请退出游戏后重新进行此操作!"",type: ""error"",}, function() {history.go(-1);});</script>"
        response.End
    End If

    Set rs = Server.CreateObject("ADODB.Recordset")
    sql = "select wCHaoticlevel,dwmoney from User_Character where user_no='"&session("user_no")&"' and Character_no='"&Id&"'"
    rs.Open sql, conn_c, 1, 3
    If rs.EOF Or rs.bof Then '检测登陆信息是否正确
        rs.Close
        Set sql = Nothing
		Response.Write "<script>swal({title: ""错误!"",text: ""找不到角色!请联系客服!"",type: ""error"",}, function() {history.go(-1);});</script>"
        response.End
    End If
    wCHaoticlevel = Int(rs("wCHaoticlevel"))
    dwmoney = CLng(rs("dwmoney"))

    If wCHaoticlevel<1 Then
		Response.Write "<script>swal({title: ""错误!"",text: ""您不是红名!"",type: ""error"",}, function() {history.go(-1);});</script>"
        response.End
    End If

    If wCHaoticlevel * PK_Money>999999000 Then
		Response.Write "<script>swal({title: ""错误!"",text: ""趋向值过高,请到游戏中泡点吧!"",type: ""error"",}, function() {history.go(-1);});</script>"
        response.End
    End If

    If wCHaoticlevel * PK_Money>dwmoney Then
		Response.Write "<script>swal({title: ""错误!"",text: ""没有足够的金币洗名!"",type: ""error"",}, function() {history.go(-1);});</script>"
        response.End
    End If
    rs("dwmoney") = dwmoney - (wCHaoticlevel * PK_Money)
    rs("wCHaoticlevel") = 0
    rs.update
    rs.Close
    Set rs = Nothing
    conn.Close
    Set conn = Nothing
		Response.Write "<script>swal({title: ""操作成功!"",text: ""恭喜:洗名成功!!!"",type: ""success"",}, function() {location = 'user.asp';});</script>"
End Sub


Sub Login()

	'If Not ChkPost Then
    '    response.Write"System Error!"
     '   response.End
    'End If

    username = Checkstr(Request("username"))
    password = request("password")
    code = Trim(Request("code"))
	GetUrl = Request("Url")
    If username = "" Or password = "" Then
		Response.Write "<script>swal({title: ""错误!"",text: ""账号不存在或用户密码错误，请返回重新输入!"",type: ""error"",}, function() {history.go(-1);});</script>"
        response.End
    End If


    Set rs = Server.CreateObject("ADODB.Recordset")
    sql = "select user_id,user_pwd,user_no,login_flag from USER_PROFILE where user_id = '"&username&"'"
    rs.Open sql, conn, 1, 1
    If rs.EOF Or rs.bof Then
		Response.Write "<script>swal({title: ""错误!"",text: ""账号不存在或用户密码错误，请返回重新输入!"",type: ""error"",}, function() {history.go(-1);});</script>"
        response.End
    ElseIf rs("user_pwd") <> md5(password) Then
		Response.Write "<script>swal({title: ""错误!"",text: ""用户密码错误，请返回重新输入!"",type: ""error"",}, function() {history.go(-1);});</script>"
        Response.End
    Else
		 If rs("login_flag") <>0 Then
			Response.Write "<script>swal({title: ""错误!"",text: ""系统检测到您当前的游戏状态为在线,请退出游戏后重新进行此操作!"",type: ""error"",}, function() {history.go(-1);});</script>"
            Response.End
        End If

			session("username") = username
			session("password") = password
			session("user_no") = rs("user_no")
			If isnull(GetUrl) Then 
				response.redirect "index.asp"
							
			Else
				'response.write URLDecode(GetUrl) 
				'response.end
				response.redirect URLDecode(GetUrl) 

			End If 

    End If
    rs.Close
    conn.Close
End Sub

Sub Move()

    If Not ChkLogin Then
			response.redirect "?Action=UserLogin&Url="&Server.URLEncode("User.asp?Action2=Move")
			response.end
    End If

    If Not ChkPost Then
        Response.Write "<script>swal({title: ""安全错误!"",text: ""检测到非法访问，请通过正常页面进行操作!"",type: ""error"",}, function() {history.go(-1);});</script>"
        response.End
    End If

    Id = checkstr(request("Id"))

    If IsNull(Id) Then
        Response.Write "<script>swal({title: ""参数错误!"",text: ""角色ID参数丢失，请重新选择角色!"",type: ""error"",}, function() {history.go(-1);});</script>"
        Response.End
    End If

    If Not ChkOnLine Then
		Response.Write "<script>swal({title: ""错误!"",text: ""系统检测到您当前的游戏状态为在线,请退出游戏后重新进行此操作!"",type: ""error"",}, function() {history.go(-1);});</script>"
        response.End
    End If

    Set rs = Server.CreateObject("ADODB.Recordset")
    sql = "select * from user_character where character_no = '"&Id&"'"
    rs.Open sql, conn_c, 1, 3
    rs("wRetMapIndex") = "150"
    rs("wMapIndex") = "150"
    rs("wRetPosY") = "271"
    rs("wRetPosX") = "269"
    rs("wPosY") = "271"
    rs("wPosX") = "269"
    rs.Update
    rs.Close
	Response.Write "<script>swal({title: ""操作成功!"",text: ""恭喜,角色自救成功,重新登录游戏后生效!!"",type: ""success"",}, function() {location = 'user.asp';});</script>"
	Response.end
End Sub

Sub ModifySave()
    username = checkstr(request("username"))
    old_password = request("old_password")
    password = request("password")
    password2 = request("password2")
	code=request("code")

    If Not ChkPost Then
        Response.Write "<script>swal({title: ""安全错误!"",text: ""检测到非法访问，请通过正常页面进行操作!"",type: ""error"",}, function() {history.go(-1);});</script>"
        response.End
    End If

If code=""  Then
	Response.Write "<script>swal({title: ""错误!"",text: ""验证码错误,请返回重新输入!"",type: ""error"",}, function() {history.go(-1);});</script>"
    response.end
end If

If  Not isnumeric(code) Or Int(Session("getCode"))<>int(code) Then
	Response.Write "<script>swal({title: ""错误!"",text: ""验证码错误,请返回重新输入!"",type: ""error"",}, function() {history.go(-1);});</script>"
    response.end
end If

    If old_password = "" Or password = "" Or username=""  Then
		Response.Write "<script>swal({title: ""错误!"",text: ""密码不能为空,请返回重新输入!"",type: ""error"",}, function() {history.go(-1);});</script>"
        response.End
    End If

    If password2<>password Then
		Response.Write "<script>swal({title: ""错误!"",text: ""两次密码不一致,请返回重新输入!"",type: ""error"",}, function() {history.go(-1);});</script>"
        response.End
    End If

    If Len(password)<6 Or  Len(password)>12 Then
		Response.Write "<script>swal({title: ""错误!"",text: ""密码长度为6到12个字符,请返回重新输入!"",type: ""error"",}, function() {history.go(-1);});</script>"
        response.End
    End If


    Set rs = Server.CreateObject("ADODB.Recordset")
    sql = "select user_pwd,password from USER_PROFILE where user_id = '"&username&"'"
    rs.Open sql, conn, 1, 3
    If old_password<>rs("password") Then
		Response.Write "<script>swal({title: ""错误!"",text: ""旧密码错误,请返回重新输入!"",type: ""error"",}, function() {history.go(-1);});</script>"

        response.End
	Else
		rs("user_pwd") = md5(password)
		rs("password") = password
    End If
    rs.update
    rs.Close


    conn.Close
    Set conn = Nothing
	Response.Write "<script>swal({title: ""操作成功!"",text: ""恭喜,用户密码修改成功!"",type: ""success"",}, function() {location = 'user.asp';});</script>"
	Response.end

End Sub

Sub ChangeJobSave()

    If Not ChkLogin Then
			response.redirect "?Action=UserLogin&Url="&Server.URLEncode("User.asp?Action2=ChangeJob")
			response.end
    End If

    If Not ChkPost Then
        Response.Write "<script>swal({title: ""安全错误!"",text: ""检测到非法访问，请通过正常页面进行操作!"",type: ""error"",}, function() {history.go(-1);});</script>"
        response.End
    End If

    Id = checkstr(Request("Id"))
    New_Class = int(checkstr(Request("New_Class")))

    If IsNull(Id) Then
        Response.Write "<script>swal({title: ""参数错误!"",text: ""角色ID参数丢失，请重新选择角色!"",type: ""error"",}, function() {history.go(-1);});</script>"
        Response.End
    End If

    If New_Class>10 And   New_Class<0 Then
		Response.Write "<script>swal({title: ""错误!"",text: ""请选择需要变更的职业，请返回重新输入!"",type: ""error"",}, function() {history.go(-1);});</script>"
        Response.End
    End If

    If Not ChkOnLine Then
		Response.Write "<script>swal({title: ""错误!"",text: ""系统检测到您当前的游戏状态为在线,请退出游戏后重新进行此操作!"",type: ""error"",}, function() {history.go(-1);});</script>"
        response.End
    End If

		  SET RS_count = conn.Execute("select sum(amount) from PayLog where trade_status>0 and userid='"&session("user_no")&"'")
		  If RS_count(0)>199  Then 
			 ChangeJob_Money2=50000000
		 else
			ChangeJob_Money2=ChangeJob_Money
		  End If
		  RS_count.close

    Set rs = Server.CreateObject("ADODB.Recordset")
    sql = "select bypcClass,dwmoney,wskillpoint,wlevel from User_Character where user_no='"&session("user_no")&"' and Character_no='"&Id&"'"
    rs.Open sql, conn_c, 1, 3
    If rs.EOF Or rs.bof Then '检测登陆信息是否正确
        rs.Close
        Set sql = Nothing
		Response.Write "<script>swal({title: ""错误!"",text: ""角色信息错误,请返联系管理员!"",type: ""error"",}, function() {history.go(-1);});</script>"
        response.End
    End If
    bypcClass = Int(rs("bypcClass"))
    dwmoney = CLng(rs("dwmoney"))

    If bypcClass=New_Class Then
		Response.Write "<script>swal({title: ""错误!"",text: ""您需要变更的职业和当前职业相同,请重新选择!"",type: ""error"",}, function() {history.go(-1);});</script>"
        response.End
    End If

    If  ChangeJob_Money2>dwmoney Then
		Response.Write "<script>swal({title: ""错误!"",text: ""您没有足够的金币转职!"",type: ""error"",}, function() {history.go(-1);});</script>"
        response.End
    End If

	SET RSzb = conn_c.Execute("select Character_no from user_suit where Character_no='"&Id&"' and (line_no<>15 or line_no<>16 or line_no<>17)")
	If Not RSzb.eof Then 
			Response.Write "<script>swal({title: ""错误!"",text: ""检测到您的角色身上有装备或者服装,请脱下装备(包括快捷栏的药水)!"",type: ""error"",}, function() {history.go(-1);});</script>"
			response.End
	 End If

    rs("dwmoney") = dwmoney - ChangeJob_Money2
    rs("bypcClass") = New_Class
    rs("wskillpoint") = rs("wlevel") 
    rs.update
    rs.Close
    Set rs = Nothing
    conn.Close
    Set conn = Nothing

	set rsdelskill=conn_c.execute("Delete  from user_skill where Character_no='"&Id&"'")
	set rsdelslot=conn_c.execute("Delete  from user_slot where Character_no='"&Id&"'")
	Response.Write "<script>swal({title: ""操作成功!"",text: ""恭喜,转职成功!上线后请脱掉前职业的所有装备,否则无法移动!"",type: ""success"",}, function() {location = 'user.asp';});</script>"

End Sub

Sub UpgradeSave()

    If Not ChkLogin Then
			response.redirect "?Action=UserLogin&Url="&Server.URLEncode("User.asp?Action2=Upgrade")
			response.end
    End If

    ' 转生功能禁用CSRF检查，因为它是通过内部GET链接调用的
    ' If Not ChkPost Then
    '     Response.Write "<script>swal({title: ""安全错误!"",text: ""检测到非法访问，请通过正常页面进行操作!"",type: ""error"",}, function() {history.go(-1);});</script>"
    '     response.End
    ' End If

    Id = checkstr(Request("Id"))

    If IsNull(Id) Then
        Response.Write "<script>swal({title: ""参数错误!"",text: ""角色ID参数丢失，请重新选择角色!"",type: ""error"",}, function() {history.go(-1);});</script>"
        Response.End
    End If

    If Not ChkOnLine Then
		Response.Write "<script>swal({title: ""错误!"",text: ""系统检测到您当前的游戏状态为在线,请退出游戏后重新进行此操作!"",type: ""error"",}, function() {history.go(-1);});</script>"
        response.End
    End If

		  SET RS_count = conn.Execute("select sum(amount) from PayLog where trade_status>0 and userid='"&session("user_no")&"'")
		  If RS_count(0)>199  Then 
			 Upgrade_Money2=50000000
		 else
			Upgrade_Money2=Upgrade_Money
		  End If
		  RS_count.close

    Set rs = Server.CreateObject("ADODB.Recordset")
    sql = "select bypcClass,dwmoney,wskillpoint,wlevel,wMasterLevel from User_Character where user_no='"&session("user_no")&"' and Character_no='"&Id&"'"
    rs.Open sql, conn_c, 1, 3
    If rs.EOF Or rs.bof Then '检测登陆信息是否正确
        rs.Close
        Set sql = Nothing
		Response.Write "<script>swal({title: ""错误!"",text: ""角色信息错误,请返联系管理员!"",type: ""error"",}, function() {history.go(-1);});</script>"
        response.End
    End If
    dwmoney = CLng(rs("dwmoney"))
    wlevel = CLng(rs("wlevel"))
    Upgrade = int(rs("wMasterLevel"))
	
	If Upgrade>Max_Upgrade Then 
			Response.Write "<script>swal({title: ""错误!"",text: ""您已经达到最大转生次数!"",type: ""error"",}, function() {history.go(-1);});</script>"
        response.End
    End If
	
    If Upgrade_Level>wlevel Then
		Response.Write "<script>swal({title: ""错误!"",text: ""您的等级不够无法转生!"",type: ""error"",}, function() {history.go(-1);});</script>"
        response.End
    End If

    If  Upgrade_Money2>dwmoney Then
		Response.Write "<script>swal({title: ""错误!"",text: ""您没有足够的金币转生!"",type: ""error"",}, function() {history.go(-1);});</script>"
        response.End
    End If

	SET RSzb = conn_c.Execute("select Character_no from user_suit where Character_no='"&Id&"' and (line_no<>15 or line_no<>16 or line_no<>17)")
	If Not RSzb.eof Then 
			Response.Write "<script>swal({title: ""错误!"",text: ""检测到您的角色身上有装备或者服装,请脱下装备(包括快捷栏的药水)!"",type: ""error"",}, function() {history.go(-1);});</script>"
			response.End
	 End If

    rs("dwmoney") = dwmoney - Upgrade_Money2
    rs("wlevel") = 1
    rs("wskillpoint") = (Upgrade_AddSkil+1)
    rs("wstr") = 6
    rs("wdex") = 3
    rs("wCon") = 5
    rs("wSpr") = 1
    rs("wStatpoint") = 0
    rs("wMasterLevel") = rs("wMasterLevel")+1
	
	rs("wRetMapIndex") = "150"
    rs("wMapIndex") = "150"
    rs("wRetPosY") = "271"
    rs("wRetPosX") = "269"
    rs("wPosY") = "271"
    rs("wPosX") = "269"
	
    rs.update
    rs.Close
    Set rs = Nothing
    conn.Close
    Set conn = Nothing

	set rsdelskill=conn_c.execute("Delete  from user_skill where Character_no='"&Id&"'")
	set rsdelslot=conn_c.execute("Delete  from user_slot where Character_no='"&Id&"'")
	Response.Write "<script>swal({title: ""操作成功!"",text: ""恭喜,转职成功!上线后请脱掉前职业的所有装备,否则无法移动!"",type: ""success"",}, function() {location = 'user.asp';});</script>"

End Sub

Sub GetPwdMail()

    If Not ChkPost Then
        Response.Write "<script>swal({title: ""安全错误!"",text: ""检测到非法访问，请通过正常页面进行操作!"",type: ""error"",}, function() {history.go(-1);});</script>"
        response.End
    End If

    username = checkstr(Request.Form("username"))
	user_qq = Request("user_qq")
	code=Request("code")


	If code=""  Then
		Response.Write "<script>swal({title: ""错误!"",text: ""验证码错误,请返回重新输入!"",type: ""error"",}, function() {history.go(-1);});</script>"
		response.end
	end If

	If  Not isnumeric(code) Or Int(Session("getCode"))<>int(code) Then
		Response.Write "<script>swal({title: ""错误!"",text: ""验证码错误,请返回重新输入!"",type: ""error"",}, function() {history.go(-1);});</script>"
		response.end
	end If

    If IsNull(username) Or IsNull(user_qq) Then
		Response.Write "<script>swal({title: ""错误!"",text: ""请填写您的用户名和注册Q Q号码!"",type: ""error"",}, function() {history.go(-1);});</script>"
        Response.End
    End If

    Set rs = Server.CreateObject("ADODB.Recordset")
    sql = "select user_id,user_mail,password,reg_qq,login_tag from USER_PROFILE where user_id = '"&username&"'"
    rs.Open sql, conn, 1, 1
    If rs.EOF Or rs.bof Then
		Response.Write "<script>swal({title: ""错误!"",text: ""账号或QQ号码错误，请返回重新输入!"",type: ""error"",}, function() {history.go(-1);});</script>"
        response.End
    ElseIf rs("reg_qq") <> user_qq Then
		Response.Write "<script>swal({title: ""错误!"",text: ""账号或QQ号码错误，请返回重新输入!"",type: ""error"",}, function() {history.go(-1);});</script>"
        Response.End
    Else
		 If rs("login_tag") ="N" Then
			Response.Write "<script>swal({title: ""错误!"",text: ""该账号已被封停，无法取回密码!"",type: ""error"",}, function() {history.go(-1);});</script>"
            Response.End
        End If

		On Error Resume Next 
		Set jmail = Server.CreateObject("JMAIL.Message") '建立发送邮件的对象
		jmail.silent = true '屏蔽例外错误，返回FALSE跟TRUE两值j
		jmail.logging = true '启用邮件日志
		jmail.Charset = "GB2312" '邮件的文字编码为国标
		jmail.ContentType = "text/html" '邮件的格式为HTML格式
		jmail.AddRecipient rs("user_mail") '邮件收件人的地址
		jmail.From = MailFrom '发件人的E-MAIL地址
		jmail.MailServerUserName = MailServerUserName '登录邮件服务器所需的用户名
		jmail.MailServerPassword = MailServerPassword '登录邮件服务器所需的密码
		jmail.Subject = ServerName&"密码取回邮件" '邮件的标题 
		'jmail.Body = "尊敬的"&username&"你好,您在"&ServerName&"的密码是"&rs("password")&" 请登录我们的网站修改密码.我们的网址是http://www.3366cc.com"'邮件的内容
		jmail.Priority = 3 '邮件的紧急程序，1 为最快，5 为最慢， 3 为默认值
		jmail.Send(MailSend) '执行邮件发送（通过邮件服务器地址）
		jmail.Close() '关闭对象

		If Err.number <> 0 Then
			Response.Write "<script>swal({title: ""错误!"",text: ""邮件发送失败!请联系客服.错误信息:"&rs("Err.Description")&""",type: ""error"",}, function() {history.go(-1);});</script>"
		Else
			Response.Write "<script>swal({title: ""操作成功!"",text: ""密码取回成功!已成功将密码发送至您的邮箱:"&rs("user_mail")&""",type: ""success"",}, function() {location = 'user.asp';});</script>"
		End If

    End If
    rs.Close
    conn.Close
End Sub








Sub Quit()
    Session.Abandon
    response.redirect "index.asp"
End Sub


%>
<script type="text/javascript" src="static/js/main.js"></script>
