<!--#include file="inc/conn.asp" -->
<!--#include file="inc/char.asp" -->
<!DOCTYPE html>
<html>
  <head>
    <title>挑战</title>
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

' ========== 新增安全验证函数 ==========
Function SafeSQLString(str)
    If IsNull(str) Then SafeSQLString = "": Exit Function
    SafeSQLString = Replace(Trim(str), "'", "''")
End Function

Function SafeRoleID(roleID)
    If IsNull(roleID) Or roleID = "" Then
        SafeRoleID = ""
        Exit Function
    End If
    
    ' 角色ID格式验证
    If Len(roleID) > 32 Then
        SafeRoleID = ""
        Exit Function
    End If
    
    ' 只允许字母、数字、下划线
    Dim cleanID, i, c
    cleanID = ""
    For i = 1 To Len(roleID)
        c = Mid(roleID, i, 1)
        If (c >= "A" And c <= "Z") Or (c >= "a" And c <= "z") Or _
           (c >= "0" And c <= "9") Or c = "_" Then
            cleanID = cleanID & c
        End If
    Next
    
    SafeRoleID = cleanID
End Function

Function ValidatePrice(price)
    If Not IsNumeric(price) Then
        ValidatePrice = False
        Exit Function
    End If
    
    Dim priceNum
    priceNum = CLng(price)
    If priceNum < 1 Or priceNum > 99999999 Then
        ValidatePrice = False
        Exit Function
    End If
    
    ValidatePrice = True
End Function

' ========== 统一错误处理 ==========
Sub LogError(moduleName, errorMsg)
    On Error Resume Next
    Dim ip, sql
    ip = Request.ServerVariables("REMOTE_ADDR")
    
    sql = "INSERT INTO System_Error_Log (error_time, ip, username, module, error_message) VALUES (" & _
          "GETDATE(), '" & SafeSQLString(ip) & "', " & _
          "'" & SafeSQLString(Session("username")) & "', " & _
          "'" & SafeSQLString(moduleName) & "', " & _
          "'" & SafeSQLString(errorMsg) & "')"
    
    conn.Execute sql
    Err.Clear
End Sub

Sub OutputJSONError(message)
    Response.ContentType = "application/json;charset=utf-8"
    Response.Write "{""ok"":false,""msg"":""" & Replace(message, """", "\""") & """}"
    Response.End
End Sub

' ========== 核心功能函数（新增在文件开头） ==========
Function GenerateUniqueSN()
    Dim timestamp, randomStr
    timestamp = Year(Now()) & Right("0" & Month(Now()), 2) & Right("0" & Day(Now()), 2)
    randomStr = ""
    Dim i, charSet
    charSet = "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ"
    For i = 1 To 6
        Randomize
        randomStr = randomStr & Mid(charSet, Int(Rnd() * Len(charSet)) + 1, 1)
    Next
    GenerateUniqueSN = timestamp & randomStr
End Function
 
Sub ShowError(msg)
    Response.Write "<script>swal({title: '操作失败', text: '" & Replace(msg, "'", "\'") & "', type: 'error'}, function() {history.go(-1);});</script>"
    Response.End
End Sub
 
' ========== 主处理逻辑（新增在文件开头） ==========
Sub HandleAction()
    Dim Action
    Action = Request("Action")
    
    Select Case Action
        Case "ExchangeSave": ExchangeSave()
        Case "GiftSave": GiftSave()
        Case "BuySave": BuySave()
        Case "UpdateSave": UpdateSave()
        Case "UPgradeSave": UPgradeSave()
        Case "SellSave": SellSave()
        Case "ExchangeItem_Save": ExchangeItem_Save()
        Case "RecallSave": RecallSave()  ' 确保包含这个case
        Case "GetLotteryAnnouncements": GetLotteryAnnouncements() ' <-- 新增这一行
        Case "GetPrizePool": GetPrizePool() ' <-- 新增这一行
        Case Else: ShowError("无效操作")
    End Select
End Sub

' 生成唯一编号（适配varchar(18)字段）
Function GenerateUniqueSN()
    Dim timestamp, randomStr, sn
    ' 时间戳（年月日时分秒，14位）
    timestamp = Year(Now()) & _
                Right("0" & Month(Now()), 2) & _
                Right("0" & Day(Now()), 2) & _
                Right("0" & Hour(Now()), 2) & _
                Right("0" & Minute(Now()), 2) & _
                Right("0" & Second(Now()), 2)
    ' 4位随机字母数字（确保总长度18位内）
    Randomize
    randomStr = ""
    Dim i, charSet
    charSet = "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ"
    For i = 1 To 4
        randomStr = randomStr & Mid(charSet, Int(Rnd() * Len(charSet)) + 1, 1)
    Next
    ' 组合为18位以内的字符串（14+4=18）
    sn = timestamp & randomStr
    GenerateUniqueSN = sn
End Function

' MD5辅助函数
Function SimpleMD5(str)
    Dim x, i, c, h
    h = Array(12345678, 87654321, 13579246, 64297531)
    For i = 1 To Len(str)
        c = Asc(Mid(str, i, 1))
        x = (c * i) Mod 4
        h(x) = (h(x) + c) * i Mod 2147483647
    Next
    SimpleMD5 = Right("00000000" & Hex(h(0)), 8) & _
                Right("00000000" & Hex(h(1)), 8) & _
                Right("00000000" & Hex(h(2)), 8) & _
                Right("00000000" & Hex(h(3)), 8)
End Function

' 辅助函数：条件判断
Function IIf(condition, trueVal, falseVal)
    If condition Then
        IIf = trueVal
    Else
        IIf = falseVal
    End If
End Function

Action = Request("Action")
Action2 = Request("Action2")


Select Case Action
	Case "ExchangeSave"	'兑换商城币
        ExchangeSave()
	Case "GiftSave"	'领取礼包
		GiftSave()
	Case "BuySave"		'购买装备
        BuySave()
	Case "UpdateSave"	'更换装备
        UpdateSave()
	Case "UPgradeSave"	'强化装备
        UPgradeSave()
	Case "SellSave"	'出售装备
        SellSave()
	Case "ExchangeItem_Save"	'兑换装备
        ExchangeItem_Save()
	Case "RecallSave"	'取回装备
		RecallSave()
    Case "LotterySpin"
        LotterySpin()
    Case "GetLotteryAnnouncements"
        GetLotteryAnnouncements()
    Case "GetPrizePool"
        GetPrizePool()
    Case "SetCurrentCharacter"
     Call SetCurrentCharacter()
End Select


'------------------------------设置当前角色------------------------------'
Sub SetCurrentCharacter()
    Dim Id
    Id = SafeRoleID(Trim(request("Id")))
    
    If Id <> "" And ChkLogin Then
        ' 验证角色是否属于当前用户
        Set rs = conn_c.Execute("select count(*) as cnt from User_Character where user_no='" & session("user_no") & "' and Character_no='" & Id & "'")
        If rs("cnt") > 0 Then
            Session("current_char_id") = Id
            Response.Write "OK"
        Else
            Response.Write "ERROR"
        End If
        rs.Close
    Else
        Response.Write "ERROR"
    End If
    
    Response.End
End Sub

'------------------------------兑换商城币（安全优化版）------------------------------'
Sub ExchangeSave()
    ' 前置验证
    If Not ChkLogin Then
        response.redirect "?Action=UserLogin&Url=" & Server.URLEncode("Shop.asp?Action2=Exchange")
        response.end
    End If

    If Not ChkOnLine Then
        Response.Write "<script>swal({title: ""错误!"",text: ""系统检测到您当前的游戏状态为在线,请退出游戏后重新进行此操作!"",type: ""error"",}, function() {history.go(-1);});</script>"
        response.End
    End If

    Dim Id, Line_no, Url, Action3
    Id = SafeRoleID(Trim(request("Id")))
    Line_no = Request("Line_no")
    Url = Request("Url")
    Action3 = Request("Action3")

    ' 验证Id
    If Id = "" Then
        Response.Write "<script>swal({title: '错误!',text: '角色ID格式错误!',type: 'error'}, function() {history.go(-1);});</script>"
        Response.End
    End If

    ' 红包兑换的特殊验证
    If Action3 = 3 Then
        If IsNull(Line_no) Or Not IsNumeric(Line_no) Then
            Response.Write "Line_no参数错误!"
            Response.End
        End If
        Line_no = CLng(Line_no)

        Set rs = conn_c.Execute("select Windex,info,Line_no from user_bag where Line_no=" & Line_no & " and Character_no='" & Id & "'")
        If rs.EOF Or rs.bof Then
            Response.Write "error!"
            Response.end
        Else
            If rs("Windex") <> 9930 Then
                Response.Write "error!!"
                Response.end
            End If

            item_count = Hexnumber(ShowHex(rs("info")))
            If item_count < need_maya Then
                Response.Write "error!!!"
                Response.end
            End If
        End If
        rs.close
    End If 

    ' 检查商城账户
    SET RScash = conn_b.Execute("select * from user_cash where user_no='" & session("user_no") & "'")
    If RScash.eof Or RScash.bof Then
        Response.Write "<script>swal({title: ""商城系统错误!"",text: ""领取礼包之前请确保您在游戏商城中购买过任意一样物品!"",type: ""error"",}, function() {history.go(-1);});</script>"
        response.End
    End If 

    ' 检查角色信息
    set rs = conn_c.execute("select dwmoney,wlevel,dwLowPPoint from User_Character where user_no='" & session("user_no") & "' and Character_no='" & Id & "'")
    If rs.EOF Or rs.bof Then
        rs.Close
        Response.Write "<script>swal({title: ""错误!"",text: ""角色信息错误,请返联系管理员!"",type: ""error"",}, function() {history.go(-1);});</script>"
        response.End
    End If

    ' 金币兑换
    If Action3 = 1 then
        Dim dwmoney, needMoney
        dwmoney = CLng(Trim(rs("dwmoney") & ""))
        needMoney = CLng(Trim(need_Money & ""))
        
        If dwmoney < needMoney Then
            Response.Write "error!!!!"
            Response.end
        Else
            set rs1 = conn_c.execute("update User_Character set dwmoney=dwmoney-" & needMoney & " where user_no='" & session("user_no") & "' and Character_no='" & Id & "'")
        End If
    End If 

    ' P点兑换
    If Action3 = 2 then
        Dim dwLowPPoint, needPPoint
        dwLowPPoint = CLng(Trim(rs("dwLowPPoint") & ""))
        needPPoint = CLng(Trim(need_PPoint & ""))
        
        If dwLowPPoint < needPPoint Then
            Response.Write "error!!!!"
            Response.End
        Else
            set rs1 = conn_c.execute("update User_Character set dwLowPPoint=dwLowPPoint-" & needPPoint & " where user_no='" & session("user_no") & "' and Character_no=" & Id & "")
        End If
    End If 

    ' 红包兑换
    If Action3 = 3 Then
        If item_count = 10 Then
            set updateitem = conn_c.execute("delete user_bag where Character_no=" & Id & " and line_no=" & line_no & " and Windex=9930")
        Else
            item_count = item_count - need_maya
            item_count = Hex(item_count)
            item_count = "0x" & Right("000" & item_count, 4)
            set updateitem = conn_c.execute("update user_bag set info=" & item_count & " where Character_no=" & Id & " and line_no=" & line_no & " and Windex=9930")
        End If 
    End If 
    
    ' 增加商城币
    set rs3 = conn_b.execute("update user_cash set amount=amount+10 where user_no='" & session("user_no") & "'")
    
    Set rs = Nothing
    Response.Write "<script>swal({title: ""操作成功!"",text: ""恭喜:您已经成功兑换10点商城币,请前往游戏查看!"",type: ""success"",}, function() {location = '" & URLDecode(Url) & "';});</script>"
    Response.end
End Sub
'--------------------------------------领取礼包（安全优化版）----------
Sub GiftSave()
    Dim Id, GiftId, Url
    Id = SafeRoleID(Trim(request("Id")))
    GiftId = Request("GiftId")
    Url = Request("Url")

    ' 验证参数
    If Id = "" Then
        Response.Write "<script>swal({title: '错误!',text: '角色ID格式错误!',type: 'error'}, function() {history.go(-1);});</script>"
        Response.End
    End If

    If IsNull(GiftId) Or Not IsNumeric(GiftId) Then
        Response.Write "error!!"
        Response.End
    End If
    
    GiftId = CLng(GiftId)
    If GiftId < 1 Or GiftId > 63 Then
        Response.Write "<script>swal({title: 'Error!',text: 'Invalid Gift ID range!',type: 'error'}, function() {history.go(-1);});</script>"
        response.End
    End If

    If Not ChkLogin Then
        response.redirect "?Action=UserLogin&Url=" & Server.URLEncode("User.asp?Action2=Gift")
        response.end
    End If

    If Not ChkOnLine Then
        Response.Write "<script>swal({title: '错误!',text: '系统检测到您当前的游戏状态为在线,请退出游戏后重新进行此操作!',type: 'error'}, function() {history.go(-1);});</script>"
        Response.End
    End If

    ' 获取礼包信息
    Set rs = conn.Execute("select * from web_gift where id=" & GiftId & "")
    If rs.EOF Or rs.bof Then
        Response.Write "error!!!"
    Else
        min_level = rs("min_level")
        min_upgrade = rs("min_upgrade")
        chr_date = rs("chr_date")
        item_id = rs("item_id")
        item_name = rs("item_name")
        item_count = rs("item_count")
        Cash = rs("Cash")
        Money = CLng(Trim(rs("Money") & ""))
    End If
    rs.close

    ' 检查角色信息
    Set rs = Server.CreateObject("ADODB.Recordset")
    sql = "select ipt_time,Gift,dwmoney,wlevel,wMasterLevel from User_Character where user_no='" & session("user_no") & "' and Character_no='" & Id & "'"
    rs.Open sql, conn_c, 1, 3

    If rs.EOF Or rs.bof Then
        rs.Close
        Response.Write "<script>swal({title: '错误!',text: '角色信息错误,请返联系管理员!',type: 'error'}, function() {history.go(-1);});</script>"
        response.End
    End If

    ' 【关键修复】确保USER_PROFILE表有记录并获取礼包状态
    Dim accountGift
    accountGift = 0
    
    ' 先检查USER_PROFILE表是否有记录
    Set rsCheck = conn.Execute("select count(*) as cnt from USER_PROFILE where user_no='"&session("user_no")&"'")
    If rsCheck("cnt") = 0 Then
        ' 没有记录，创建一个
        On Error Resume Next
        conn.Execute "insert into USER_PROFILE (user_no, isGift) values ('"&session("user_no")&"', 0)"
        If Err.Number <> 0 Then
            Response.Write "<script>alert('创建USER_PROFILE记录失败: " & Err.Description & "');history.go(-1);</script>"
            Response.End
        End If
        On Error GoTo 0
        accountGift = 0
    Else
        ' 有记录，获取当前值
        Set rsAccount = conn.Execute("select isGift from USER_PROFILE where user_no='"&session("user_no")&"'")
        If Not rsAccount.EOF Then
            accountGift = CLng(0 & rsAccount("isGift"))
        End If
        rsAccount.Close
    End If
    rsCheck.Close

    ' 【关键修复】正确的位运算 - 礼包ID从1开始，所以用(礼包ID-1)作为位数
    Dim giftBit
    giftBit = 2 ^ (GiftId - 1)
    
    ' 使用位操作检查是否已领取礼包
    If (accountGift AND giftBit) > 0 Then 
        Response.Write "<script>swal({title: '错误!',text: '您已经领取了该礼包!',type: 'error'}, function() {history.go(-1);});</script>"
        Response.End
    End If

    ' 等级验证
    Dim userLevel, reqLevel
    userLevel = CInt(Trim(rs("wlevel") & ""))
    reqLevel = CInt(Trim(min_level & "")) - 1
    If userLevel < reqLevel Then 
        Response.Write "<script>swal({title: '错误!',text: '您的等级达不到领取礼包的要求!',type: 'error'}, function() {history.go(-1);});</script>"
        Response.End
    End If

    ' 转生验证
    Dim masterLevel, reqUpgrade
    masterLevel = CInt(Trim(rs("wMasterLevel") & ""))
    reqUpgrade = CInt(Trim(min_upgrade & ""))
    If masterLevel < reqUpgrade Then 
        Response.Write "<script>swal({title: '错误!',text: '您的转生次数达不到领取礼包的要求!',type: 'error'}, function() {history.go(-1);});</script>"
        Response.End
    End If

    ' 日期验证
    If Not IsNull(rs("ipt_time")) And Not IsNull(chr_date) And _
       Len(Trim(rs("ipt_time"))) > 0 And Len(Trim(chr_date)) > 0 And _
       IsDate(rs("ipt_time")) And IsDate(Left(chr_date, 19)) And _
       cdate(rs("ipt_time")) < cdate(Left(chr_date, 19)) Then 
        Response.Write "<script>swal({title: '错误!',text: '您的角色创建时间达不到领取礼包的要求!',type: 'error'}, function() {history.go(-1);});</script>"
        Response.End
    End If

    ' 检查商城账户
    SET RScash = conn_b.Execute("select * from user_cash where user_no='" & session("user_no") & "'")
    If RScash.eof Or RScash.bof Then
        Response.Write "<script>swal({title: '商城系统错误!',text: '领取礼包之前请确保您在游戏商城中购买过任意一样物品!',type: 'error'}, function() {history.go(-1);});</script>"
        Response.End
    End If 
    RScash.Close

    ' 【关键修复】使用位操作标记礼包为已领取
    Dim newGiftValue
    newGiftValue = accountGift OR giftBit
    
    ' ===== 关键修改：更新USER_PROFILE表 =====
    On Error Resume Next
    conn.Execute "update USER_PROFILE set isGift=" & newGiftValue & " where user_no='" & session("user_no") & "'"
    If Err.Number <> 0 Then
        Response.Write "<script>alert('更新USER_PROFILE失败: " & Err.Description & "');history.go(-1);</script>"
        Response.End
    End If
    On Error GoTo 0
    
    ' 验证更新是否成功
    Set rsVerify = conn.Execute("select isGift from USER_PROFILE where user_no='"&session("user_no")&"'")
    If CLng(0 & rsVerify("isGift")) <> newGiftValue Then
        Response.Write "<script>alert('USER_PROFILE更新失败！期望值:" & newGiftValue & ", 实际值:" & rsVerify("isGift") & "');history.go(-1);</script>"
        Response.End
    End If
    rsVerify.Close
    ' ===== 关键修改结束 =====
    
    item_count = Hex(item_count)
    item_count = Right("000" & item_count, 4)

    ' 更新角色表的礼包状态（保持兼容性）
    set rs1 = conn_c.execute("update user_character set Gift=" & newGiftValue & " where character_no='" & id & "'")

    ' 发送物品
    If Not isnull(item_id) then
        Call PostMail(id, min_level & "级礼包", item_id, item_count, CLng(Money))
    End If 

    ' 发送商城币
    If cash > 0 then
        Dim addCash
        addCash = CInt(Trim(cash & ""))
        set rs3 = conn_b.execute("update user_cash set amount=amount+" & addCash & " where user_no='" & session("user_no") & "'")
    End If 

    Set rs = Nothing
    Response.Write "<script>swal({title: '操作成功!',text: '恭喜:您的礼包已经成功发送至游戏的邮箱中,请前往游戏取出礼包!',type: 'success'}, function() {location = '" & URLDecode(Url) & "';});</script>"
    Response.end
End Sub


'--------------------九宫格抽奖 (日志库修正版)-------------------'
Sub LotterySpin()
    On Error Resume Next
    Response.Buffer = True
    Response.Clear
    Response.CharSet = "utf-8"
    Response.ContentType = "application/json;charset=utf-8"

    Dim Id, cleanId, i, c
    Id = Trim(Request("Id"))
    If IsNull(Id) Or Id = "" Then OutputError("角色ID不能为空"): Response.End
    
    cleanId = ""
    For i = 1 To Len(Id)
        c = Mid(Id, i, 1)
        If (c>="A" And c<="Z") Or (c>="a" And c<="z") Or (c>="0" And c<="9") Or c="_" Then cleanId = cleanId & c
    Next
    Id = cleanId
    If Len(Id) <> 18 Then OutputError("角色ID格式不正确"): Response.End
    
    If Not ChkLogin Then OutputError("请先登录"): Response.End
    If Not ChkOnLine Then OutputError("检测到您在线，请先下线"): Response.End

    Dim currentUserNoForLottery, characterName
    Set rsRole = conn_c.Execute("select user_no, character_name from User_Character where character_no='" & Id & "'")
    If rsRole.EOF Then 
        rsRole.Close
        OutputError("角色信息无效"): Response.End
    Else
        currentUserNoForLottery = Trim(rsRole("user_no") & "")
        characterName = Trim(rsRole("character_name") & "")
    End If
    rsRole.Close

    ' 修改：从TOP 9改为TOP 8
    Dim sqlPool
    sqlPool = "SELECT TOP 8 id, item_name, ISNULL(item_id,0) AS item_id, ISNULL(item_count,1) AS item_count, ISNULL(Cash,0) AS Cash, ISNULL(Money,0) AS Money, ISNULL(weight,1) AS weight FROM WEB_Gift WHERE (ISNULL(item_id,0)>0 OR ISNULL(Cash,0)>0 OR ISNULL(Money,0)>0) ORDER BY id ASC"

    Dim rsPool
    Set rsPool = conn.Execute(sqlPool)
    If rsPool.EOF Then rsPool.Close: OutputError("奖池为空"): Response.End

    ' 修改：从9改为8
    Dim pIds(7), pNames(7), pItemId(7), pItemCnt(7), pCash(7), pMoney(7), pWeights(7)
    Dim n, actualCount
    n = 0
    actualCount = 0
    
    Do Until rsPool.EOF Or n >= 8
        pIds(n) = CLng(0 & rsPool("id"))
        pNames(n) = rsPool("item_name") & ""
        pItemId(n) = CLng(0 & rsPool("item_id"))
        pItemCnt(n) = CLng(0 & rsPool("item_count")): If pItemCnt(n) <= 0 Then pItemCnt(n) = 1
        pCash(n) = CLng(0 & rsPool("Cash"))
        pMoney(n) = CLng(0 & rsPool("Money"))
        pWeights(n) = CLng(0 & rsPool("weight")): If pWeights(n) <= 0 Then pWeights(n) = 1
        
        n = n + 1
        actualCount = actualCount + 1
        rsPool.MoveNext
    Loop
    rsPool.Close

    ' 修改：从9改为8
    If actualCount < 8 Then OutputError("奖池奖项不足8个"): Response.End

    ' Fisher-Yates 洗牌算法
    Dim j, temp
    Randomize Timer
    ' 修改：从7循环到1
    For i = 7 To 1 Step -1
        j = Int(Rnd() * (i + 1))
        temp = pIds(i): pIds(i) = pIds(j): pIds(j) = temp
        temp = pNames(i): pNames(i) = pNames(j): pNames(j) = temp
        temp = pItemId(i): pItemId(i) = pItemId(j): pItemId(j) = temp
        temp = pItemCnt(i): pItemCnt(i) = pItemCnt(j): pItemCnt(j) = temp
        temp = pCash(i): pCash(i) = pCash(j): pCash(j) = temp
        temp = pMoney(i): pMoney(i) = pMoney(j): pMoney(j) = temp
        temp = pWeights(i): pWeights(i) = pWeights(j): pWeights(j) = temp
    Next

    Dim LotteryCostBB: LotteryCostBB = 10
    Dim rowsAffected: rowsAffected = 0
    conn_b.Execute "update user_cash set b_amount = b_amount - " & LotteryCostBB & " where user_no='" & currentUserNoForLottery & "' and b_amount >= " & LotteryCostBB, rowsAffected
    If Err.Number <> 0 Then Err.Clear: OutputError("扣除B币时出错"): Response.End
    If rowsAffected = 0 Then OutputError("B币不足"): Response.End

    Dim totalW: totalW = 0
    ' 修改：从0到7循环
    For i = 0 To 7
        totalW = totalW + pWeights(i)
    Next
    Randomize Timer
    Dim r, acc, winIdx
    r = Int(Rnd() * totalW) + 1
    acc = 0: winIdx = 0
    ' 修改：从0到7循环
    For i = 0 To 7
        acc = acc + pWeights(i)
        If r <= acc Then winIdx = i: Exit For
    Next

    Dim prizeLabel, sendErr
    prizeLabel = pNames(winIdx)
    sendErr = ""
    
    If (pItemId(winIdx) > 0) Or (pMoney(winIdx) > 0) Then
        Dim cntHex: cntHex = Right("000" & Hex(pItemCnt(winIdx)), 4)
        Call PostMail(Id, "抽奖奖励", pItemId(winIdx), cntHex, CLng(pMoney(winIdx)))
        If Err.Number <> 0 Then sendErr = "发送邮件失败"
    End If
    If sendErr = "" And pCash(winIdx) > 0 Then
        conn_b.Execute "update user_cash set amount = amount + " & pCash(winIdx) & " where user_no='" & currentUserNoForLottery & "'"
        If Err.Number <> 0 Then sendErr = "发放C币失败"
    End If

    If sendErr <> "" Then
        Err.Clear
        conn_b.Execute "update user_cash set b_amount = b_amount + " & LotteryCostBB & " where user_no='" & currentUserNoForLottery & "'"
        OutputError(sendErr): Response.End
    End If

    ' 写入抽奖日志
    Dim isBigPrize, prizeDetailsForLog
    isBigPrize = 0
    prizeDetailsForLog = prizeLabel
    If pCash(winIdx) > 1000 Or pMoney(winIdx) > 1000000 Then isBigPrize = 1
    If pItemCnt(winIdx) > 1 Then prizeDetailsForLog = prizeLabel & " x" & pItemCnt(winIdx)
    
    conn.Execute "INSERT INTO WEB_Lottery_Log (user_no, character_no, character_name, prize_name, prize_details, is_big_prize) VALUES ('" & currentUserNoForLottery & "', '" & Id & "', '" & characterName & "', '" & prizeLabel & "', '" & prizeDetailsForLog & "', " & isBigPrize & ")"
    If Err.Number <> 0 Then Err.Clear

    Dim rsLeft, leftBB: leftBB = 0
    Set rsLeft = conn_b.Execute("select isnull(b_amount,0) as b_amount from user_cash where user_no='" & currentUserNoForLottery & "'")
    If Not rsLeft.EOF Then leftBB = CLng(0 & rsLeft("b_amount"))
    rsLeft.Close

    Dim jsonPrizes
    jsonPrizes = "["
    ' 修改：从0到7循环
    For i = 0 To 7
        If i > 0 Then jsonPrizes = jsonPrizes & ","
        Dim safeName
        safeName = Replace(pNames(i), "\", "\\")
        safeName = Replace(safeName, """", "\""")
        safeName = Replace(safeName, vbCr, "\r")
        safeName = Replace(safeName, vbLf, "\n")
        jsonPrizes = jsonPrizes & "{""id"":" & pIds(i) & ",""name"":""" & safeName & """,""count"":" & pItemCnt(i) & ",""cash"":" & pCash(i) & ",""money"":" & pMoney(i) & "}"
    Next
    jsonPrizes = jsonPrizes & "]"
    
    prizeLabel = Replace(prizeLabel, "\", "\\")
    prizeLabel = Replace(prizeLabel, """", "\""")
    prizeLabel = Replace(prizeLabel, vbCr, "\r")
    prizeLabel = Replace(prizeLabel, vbLf, "\n")

    Response.Write "{""ok"":true,""prizes"":" & jsonPrizes & ",""index"":" & winIdx & ",""remainBB"":" & leftBB & ",""prizeLabel"":""" & prizeLabel & """}"
    Response.End
End Sub

'--------------------获取打乱顺序的奖池 (最终纯净版)-------------------'
Sub GetPrizePool()
    On Error Resume Next
    Response.Buffer = True
    Response.Clear
    Response.CharSet = "utf-8"
    Response.ContentType = "application/json;charset=utf-8"

    Dim sqlPool, rsPool
    ' 修改：从TOP 9改为TOP 8
    sqlPool = "SELECT TOP 8 id, item_name, ISNULL(item_id,0) AS item_id, ISNULL(item_count,1) AS item_count, ISNULL(Cash,0) AS Cash, ISNULL(Money,0) AS Money, ISNULL(weight,1) AS weight FROM WEB_Gift WHERE (ISNULL(item_id,0)>0 OR ISNULL(Cash,0)>0 OR ISNULL(Money,0)>0) ORDER BY id ASC"
    Set rsPool = conn.Execute(sqlPool)

    If Err.Number <> 0 Then
        Response.Write "{""ok"":false,""msg"":""数据库查询出错: " & Replace(Err.Description, """", "\""") & """}"
        Response.End
    End If

    If rsPool.EOF Then
        rsPool.Close
        Response.Write "{""ok"":false,""msg"":""奖池为空""}"
        Response.End
    End If

    ' 修改：从9改为8
    Dim pIds(7), pNames(7), pItemId(7), pItemCnt(7), pCash(7), pMoney(7), pWeights(7)
    Dim i, n, actualCount
    n = 0
    actualCount = 0
    
    Do Until rsPool.EOF Or n >= 8
        pIds(n) = CLng(0 & rsPool("id"))
        pNames(n) = rsPool("item_name") & ""
        pItemId(n) = CLng(0 & rsPool("item_id"))
        pItemCnt(n) = CLng(0 & rsPool("item_count")): If pItemCnt(n) <= 0 Then pItemCnt(n) = 1
        pCash(n) = CLng(0 & rsPool("Cash"))
        pMoney(n) = CLng(0 & rsPool("Money"))
        pWeights(n) = CLng(0 & rsPool("weight")): If pWeights(n) <= 0 Then pWeights(n) = 1
        
        n = n + 1
        actualCount = actualCount + 1
        rsPool.MoveNext
    Loop
    rsPool.Close

    ' 修改：从9改为8
    If actualCount < 8 Then
        Response.Write "{""ok"":false,""msg"":""奖池奖项不足8个""}"
        Response.End
    End If

    Dim j, temp
    Randomize Timer
    ' 修改：从8循环到1
    For i = 7 To 1 Step -1
        j = Int(Rnd() * (i + 1))
        temp = pIds(i): pIds(i) = pIds(j): pIds(j) = temp
        temp = pNames(i): pNames(i) = pNames(j): pNames(j) = temp
        temp = pItemId(i): pItemId(i) = pItemId(j): pItemId(j) = temp
        temp = pItemCnt(i): pItemCnt(i) = pItemCnt(j): pItemCnt(j) = temp
        temp = pCash(i): pCash(i) = pCash(j): pCash(j) = temp
        temp = pMoney(i): pMoney(i) = pMoney(j): pMoney(j) = temp
        temp = pWeights(i): pWeights(i) = pWeights(j): pWeights(j) = temp
    Next

    Dim jsonPrizes, sep
    jsonPrizes = "[": sep = ""
    ' 修改：从0到7循环
    For i = 0 To 7
        If i > 0 Then jsonPrizes = jsonPrizes & ","
        Dim safeName
        safeName = Replace(pNames(i), "\", "\\")
        safeName = Replace(safeName, """", "\""")
        jsonPrizes = jsonPrizes & "{""id"":" & pIds(i) & ",""name"":""" & safeName & """,""count"":" & pItemCnt(i) & ",""cash"":" & pCash(i) & ",""money"":" & pMoney(i) & "}"
    Next
    jsonPrizes = jsonPrizes & "]"
    
    Response.Write "{""ok"":true,""prizes"":" & jsonPrizes & "}"
    Response.End
End Sub

'--------------------获取抽奖公告 (最终纯净版)-------------------'
Sub GetLotteryAnnouncements()
    On Error Resume Next
    Response.Buffer = True
    Response.Clear
    Response.CharSet = "utf-8"
    Response.ContentType = "application/json;charset=utf-8"

    If conn Is Nothing Then
        Response.Write "{""ok"":false,""msg"":""数据库连接对象未初始化""}"
        Response.End
    End If

    Dim sqlAnn
    sqlAnn = "SELECT TOP 10 L.character_name, L.prize_details, G.id AS prize_id, CONVERT(varchar, L.draw_time, 120) as draw_time FROM WEB_Lottery_Log L LEFT JOIN WEB_Gift G ON L.prize_name = G.item_name ORDER BY L.draw_time DESC"
    
    Dim rsAnn
    Set rsAnn = conn.Execute(sqlAnn)
    
    If Err.Number <> 0 Then
        Response.Write "{""ok"":false,""msg"":""数据库查询出错: " & Replace(Err.Description, """", "\""") & """}"
        Response.End
    End If

    Dim jsonAnn, sep
    jsonAnn = "[": sep = ""
    Do While Not rsAnn.EOF
        Dim cName, pDetails, isBig, dTime
        cName = Trim(rsAnn("character_name") & "")
        pDetails = Trim(rsAnn("prize_details") & "")
        dTime = Trim(rsAnn("draw_time") & "")
        
        isBig = 0
        Dim prize_id_val
        prize_id_val = rsAnn("prize_id")
        If Not IsNull(prize_id_val) Then
            If CLng(prize_id_val) < 5 Then 
                isBig = 1 
            End If
        End If
        
        jsonAnn = jsonAnn & sep & "{""name"":""" & Replace(cName, """", "\""") & """,""prize"":""" & Replace(pDetails, """", "\""") & """,""isBig"":" & isBig & ",""time"":""" & dTime & """}"
        sep = ","
        rsAnn.MoveNext
    Loop
    rsAnn.Close
    jsonAnn = jsonAnn & "]"
    
    Response.Write "{""ok"":true,""announcements"":" & jsonAnn & "}"
    Response.End
End Sub







'--------------------------------寄售装备（安全优化版）---------------------------------------
Sub SellSave()
    ' 登录/在线校验
    If Not ChkLogin Then
        Response.Redirect "../user.asp?Action=UserLogin&furl=1"
        Response.End
    End If

    If Not ChkOnLine Then
        Response.Write "<script>alert('系统检测到您当前的游戏状态为在线,请退出游戏后重新进行此操作!');history.go(-1);</script>"
        Response.End
    End If

    Dim id, line_no, itemprice, itemPriceNum
    id = SafeRoleID(Trim(checkstr(Request("id"))))
    line_no = Trim(Request("line_no"))
    itemprice = Trim(Request("price"))

    ' 参数验证
    If id = "" Then
        Response.Write "<script>alert('角色ID为空或格式错误!');history.go(-1);</script>"
        Response.End
    End If

    If Not IsNumeric(line_no) Then
        Response.Write "<script>alert('参数错误：line_no!');history.go(-1);</script>"
        Response.End
    End If
    line_no = CLng(line_no)

    If Not ValidatePrice(itemprice) Then
        Response.Write "<script>alert('请填写有效的售价!');history.go(-1);</script>"
        Response.End
    End If
    itemPriceNum = CLng(itemprice)

    ' 校验角色归属
    Dim rsCheck
    Set rsCheck = conn_c.Execute( _
        "select Character_no from User_Character " & _
        "where user_no='" & Replace(session("user_no"), "'", "''") & "' " & _
        "and Character_no='" & Replace(id, "'", "''") & "'" _
    )
    If rsCheck.EOF Then
        rsCheck.Close : Set rsCheck = Nothing
        Response.Write "<script>alert('角色不属于您，无法寄售!');history.go(-1);</script>"
        Response.End
    End If
    rsCheck.Close : Set rsCheck = Nothing

    ' 读取仓库中的物品
    Dim rs2, wIndex, dwSerialNumber, byHeader, iteminfo
    Set rs2 = conn_c.Execute( _
        "select * from user_storage " & _
        "where character_no='" & Replace(id, "'", "''") & "' and line_no=" & line_no _
    )
    If rs2.EOF Then
        Response.Write "<script>alert('非法参数!');history.go(-1);</script>"
        Response.End
    Else
        wIndex = rs2("wIndex")
        dwSerialNumber = rs2("dwSerialNumber")
        byHeader = rs2("byHeader")
        iteminfo = rs2("info")
    End If
    rs2.Close : Set rs2 = Nothing

    ' 新增市场记录
    Dim rs, sqlstr
    Set rs = Server.CreateObject("ADODB.Recordset")
    sqlstr = "select * from user_postbox"
    rs.Open sqlstr, conn_c, 1, 3

    rs.AddNew
    rs("character_no") = admin_character
    rs("sell_character_no") = id
    rs("post_no") = GenerateUniqueSN()
    rs("wIndex") = wIndex
    rs("dwSerialNumber") = dwSerialNumber
    rs("byHeader") = byHeader
    rs("info") = iteminfo
    rs("include_dil") = itemPriceNum
    rs("from_char_nm") = "出售道具"
    rs("post_sort") = 0
    rs("post_title") = "自助寄售道具"
    rs("body_text") = "90天内未出售请自行取回,否则自动删除"
    rs("state_tag") = 0
    rs("item_tag") = 1
    rs("dil_tag") = 0
    rs("ipt_time") = Now()
    rs("expire_time") = Now() + 90
    rs.Update
    rs.Close : Set rs = Nothing

    ' 从仓库删除
    conn_c.Execute "delete from user_storage where Character_no='" & Replace(id, "'", "''") & "' and line_no=" & line_no

    Response.Write "<script>alert('装备寄售成功,90天内有效期,未出售请自行取回,否则自动删除.');history.go(-2);</script>"
End Sub
'-----------------------------------------BUYSAVE-------------------------
Sub BuySave()
    On Error Resume Next
    Dim errorMsg, post_no, Character, itemcash, freeAmount, isSelfRecall, user_no
    Dim wIndex, dwSerialNumber, byHeader, info, sellCharacterNo
    
    errorMsg = ""
    isSelfRecall = False ' 标记是否为取回自己的装备

    ' 校验登录状态
    If Not ChkLogin Then
        errorMsg = "请先登录"
        Response.redirect "../user.asp?Action=UserLogin&furl=1"
        Response.End
    End If

    ' 校验游戏离线状态
    If Not ChkOnLine Then
        errorMsg = "请退出游戏后操作"
        Response.Write "<script>swal({title: '错误', text: '" & errorMsg & "', type: 'error'}, function() {history.go(-1);});</script>"
        Response.End
    End If

    ' 获取并校验参数
    Character = checkstr(Request("Character"))
    post_no = Trim(request("post_no"))
    
    ' 正确的验证：检查是否为空和长度是否符合varchar(18)
If Character = "" Then
    errorMsg = "请选择角色ID"
    Response.Write "<script>swal({title: '错误', text: '" & errorMsg & "', type: 'error'}, function() {history.go(-1);});</script>"
    Response.End
End If

' 检查长度是否超过数据库字段限制（varchar(18)）
If Len(Character) > 18 Then
    errorMsg = "角色ID过长（超过18位）"
    Response.Write "<script>swal({title: '错误', text: '" & errorMsg & "', type: 'error'}, function() {history.go(-1);});</script>"
    Response.End
End If

' 移除可能的特殊字符（保留字母和数字）
Dim cleanChar, i
cleanChar = ""
For i = 1 To Len(Character)
    Dim c
    c = Mid(Character, i, 1)
    ' 只保留字母、数字和下划线（根据实际角色ID格式调整）
    If (c >= "A" And c <= "Z") Or (c >= "a" And c <= "z") Or (c >= "0" And c <= "9") Or c = "_" Then
        cleanChar = cleanChar & c
    End If
Next
Character = cleanChar ' 最终使用清洗后的角色ID
    
    If Not IsNumeric(post_no) Then
        errorMsg = "参数错误：post_no必须为数字"
        Response.Write "<script>swal({title: '错误', text: '" & errorMsg & "', type: 'error'}, function() {history.go(-1);});</script>"
        Response.End
    End If
    post_no = CLng(post_no)

    ' 读取寄售记录（包含卖家信息）
    Dim RS2
    SET RS2 = Conn_c.Execute("select * from USER_POSTBOX where post_no="&post_no&" and character_no='"&admin_character&"'")
    If RS2.eof Or RS2.bof Then 
        errorMsg = "该装备已被购买或不存在"
        RS2.Close
        Response.Write "<script>swal({title: '错误', text: '" & errorMsg & "', type: 'error'}, function() {history.go(-1);});</script>"
        Response.End
    End If
    
   ' 提取必要字段（修复类型问题）
Dim rawDilValue
rawDilValue = Trim(RS2("include_dil") & "")
If IsNumeric(rawDilValue) Then
    itemcash = CInt(rawDilValue)
Else
    itemcash = 0
    Response.Write "<script>console.error('商城币无效: ' + '" & rawDilValue & "');</script>"
End If

' 角色ID直接作为字符串处理
sellCharacterNo = Trim(RS2("sell_character_no") & "")
Response.Write "<script>console.log('角色ID: ' + '" & sellCharacterNo & "');</script>"

wIndex = RS2("wIndex")
dwSerialNumber = RS2("dwSerialNumber")
byHeader = RS2("byHeader")
info = RS2("info")
RS2.Close


    ' 调试：输出当前用户和角色信息
    Response.Write "<script>console.log('调试1：当前用户=' + '" & session("user_no") & "' + ', 输入角色=' + '" & Character & "');</script>"
    
    ' 判断是否为取回自己的装备
    Dim RSCharacter
    SET RSCharacter = conn_c.Execute("select character_no from user_character where user_no='" & session("user_no") & "' and character_no='" & Character & "'")
    
    ' 调试：输出查询结果
    If RSCharacter.EOF Then
        Response.Write "<script>console.log('调试2：未查询到角色记录');</script>"
    Else
        Response.Write "<script>console.log('调试2：查询到角色=' + '" & RSCharacter("character_no") & "' + ', 卖家角色=' + '" & sellCharacterNo & "');</script>"
        If sellCharacterNo = RSCharacter("character_no") Then
            isSelfRecall = True
            Response.Write "<script>console.log('调试3：标记为本人取回');</script>"
        End If
    End If
    RSCharacter.Close
    
    ' 调试：最终判断结果
    Response.Write "<script>console.log('调试4：isSelfRecall=' + '" & isSelfRecall & "');</script>"

    ' 调试：强制输出当前状态
    Response.Write "<script>console.log('强制调试点：isSelfRecall=' + '" & isSelfRecall & "');</script>"
    
    ' 调试：绕过框架直接输出
    Response.Write "<script>if(!window.alerted){window.alerted=true;alert('强制调试1：isSelfRecall=' + '" & isSelfRecall & "');}</script>"
    
    ' 严格验证条件（临时日志）
    Response.Write "<script>console.log('最终验证：isSelfRecall=' + '" & isSelfRecall & "');</script>"
    
    ' 商城币校验（仅非取回自己装备时需要）
    If Not isSelfRecall Then
        Response.Write "<script>alert('强制调试2：进入商城币检查');</script>"
    Else
        Response.Write "<script>alert('调试3：已跳过商城币检查');</script>"
        Response.Write "<script>console.log('进入商城币检查');</script>"
        Dim RScash
        SET RScash = conn_b.Execute("select b_amount from user_cash where user_no='"&session("user_no")&"'")
        If RScash.eof Or RScash.bof Then
            errorMsg = "商城信息错误，请联系管理员"
            RScash.Close
            Response.Write "<script>console.log('商城信息查询失败');</script>"
            Response.Write "<script>swal({title: '错误', text: '" & errorMsg & "', type: 'error'}, function() {history.go(-1);});</script>"
            Response.End
        End If
        
        freeAmount = CInt(Trim(RScash("b_amount") & ""))
        RScash.Close
        
        ' 调试信息：输出关键变量
        Response.Write "<script>console.log('调试信息：当前角色ID=' + '" & Character & "' + ', 卖家角色ID=' + '" & sellCharacterNo & "' + ', 商城币余额=' + '" & freeAmount & "' + ', 商品价格=' + '" & itemcash & "');</script>"
        
        If Not IsNumeric(itemcash) Or itemcash <= 0 Then
            errorMsg = "商品价格无效"
        ElseIf freeAmount < itemcash Then
            errorMsg = "商城币不足（需要：" & itemcash & "，当前：" & freeAmount & "）"
            Response.Write "<script>swal({title: '错误', text: '" & errorMsg & "', type: 'error'}, function() {history.go(-1);});</script>"
            Response.End
        End If
        
   
    End If

    ' 开始事务处理
    conn_c.BeginTrans
    conn_b.BeginTrans
    
    ' 扣除商城币（仅非取回自己装备时执行）
    If Not isSelfRecall Then
        conn_b.execute("update user_cash set b_amount=b_amount-"&itemcash&" where user_no='"&session("user_no")&"'")
        If Err.Number <> 0 Then
            errorMsg = "扣减商城币失败："&Err.Description
            Err.Clear
            conn_c.RollbackTrans
            conn_b.RollbackTrans
            Response.Write "<script>swal({title: '错误', text: '" & errorMsg & "', type: 'error'}, function() {history.go(-1);});</script>"
            Response.End
        End If
    End If

    ' 添加装备到目标角色邮箱
    Dim rsNew, newPostNo
    newPostNo = GenerateUniqueSN()
    set rsNew = server.CreateObject("adodb.recordset")
    rsNew.open "select * from user_postbox", conn_c, 1, 3
    rsNew.AddNew
    rsNew("character_no") = Character ' 写入数字类型（匹配数据库字段）
    rsNew("post_no") = newPostNo ' 写入字符串类型（varchar(18)）
    rsNew("wIndex") = wIndex
    rsNew("dwSerialNumber") = dwSerialNumber
    rsNew("byHeader") = byHeader
    rsNew("info") = info
    rsNew("from_char_nm") = IIf(isSelfRecall, "取回自己的装备", "自助购买道具")
    rsNew("post_sort") = 0
    rsNew("post_title") = IIf(isSelfRecall, "取回成功", "购买成功")
    rsNew("body_text") = IIf(isSelfRecall, "您取回了自己寄售的装备", "自助购买道具，有效时间90天")
    rsNew("state_tag") = 0
    rsNew("item_tag") = 1
    rsNew("dil_tag") = 0
    rsNew("include_dil") = 0
    rsNew("ipt_time") = Now()
    rsNew("expire_time") = Now() + 90
    rsNew.update
    rsNew.close
    If Err.Number <> 0 Then
        errorMsg = "添加装备到邮箱失败："&Err.Description
        Err.Clear
        conn_c.RollbackTrans
        conn_b.RollbackTrans
        Response.Write "<script>swal({title: '错误', text: '" & errorMsg & "', type: 'error'}, function() {history.go(-1);});</script>"
        Response.End
    End If

    ' 删除原市场记录
    conn_c.Execute("delete from USER_POSTBOX where post_no="&post_no&" and character_no='"&admin_character&"'")
    If Err.Number <> 0 Then
        errorMsg = "删除原记录失败："&Err.Description
        Err.Clear
        conn_c.RollbackTrans
        conn_b.RollbackTrans
        Response.Write "<script>swal({title: '错误', text: '" & errorMsg & "', type: 'error'}, function() {history.go(-1);});</script>"
        Response.End
    End If

    ' 提交事务
    conn_c.CommitTrans
    conn_b.CommitTrans

    ' 记录日志
    Dim ip, logtxt, rsLog
    ip = Request.serverVariables("REMOTE_ADDR")
    logtxt = IIf(isSelfRecall, "取回自己的装备ID:"&wIndex, "购买物品ID:"&wIndex&" 花费商城币:"&itemcash)
    set rsLog = conn.execute("INSERT INTO [adminlog](admin,datetime,ip,username,adminlog,logtype) VALUES('"&session("username")&"',getdate(),'"&ip&"','"&Character&"','"&logtxt&"',3)")
    rsLog.Close

    ' 操作成功提示（区分取回和购买）
    Dim successMsg
    successMsg = IIf(isSelfRecall, "装备取回成功，请去邮箱中领取!", "装备购买成功，请去邮箱中领取!")
    Response.Write "<script>alert('"&successMsg&"');history.go(-2);</script>"

    ' 清理资源
    set rsNew = Nothing
    set rsLog = Nothing
    conn.close
    conn_c.close
    conn_b.close
    set conn = Nothing
    set conn_c = Nothing
    set conn_b = Nothing
    Response.End

    ' 捕获未处理的错误
    If Err.Number <> 0 Then
        errorMsg = "操作过程发生错误："&Err.Description
        conn_c.RollbackTrans
        conn_b.RollbackTrans
        Response.Write "<script>swal({title: '错误', text: '" & errorMsg & "', type: 'error'}, function() {history.go(-1);});</script>"
        Response.End
    End If
    On Error Goto 0
End Sub


'----------------------------------------------------取回装备--------------------------------------------------------------------
	Sub RecallSave()
    On Error Resume Next
    Dim post_no, Character, errorMsg
    Dim isSelfRecall, itemcash, freeAmount, userNo, sellerUserNo
    Dim rsPost, rsCash, rsChar, rsSeller, windex
    
    ' 调试输出开始
    Response.Write "<script>console.log('RecallSave开始执行');</script>"
    
    ' 1. 获取并验证参数
    post_no = Trim(Request("post_no") & "")
    Character = Trim(Request("Character") & "")
    
    Response.Write "<script>console.log('参数: post_no=" & post_no & ", Character=" & Character & "');</script>"
    
    If post_no = "" Or Len(post_no) > 18 Then
        errorMsg = "无效的寄售记录ID：" & post_no
        ShowError(errorMsg)
    End If
    If Character = "" Or Len(Character) > 18 Then
        errorMsg = "无效的角色ID：" & Character
        ShowError(errorMsg)
    End If
    
    ' 2. 验证角色及所属用户
    Set rsChar = conn_c.Execute("SELECT user_no FROM user_character WHERE character_no = '" & Character & "'")
    If rsChar.EOF Then
        errorMsg = "角色不存在：" & Character
        ShowError(errorMsg)
    End If
    userNo = Trim(rsChar("user_no") & "")
    rsChar.Close
    
    Response.Write "<script>console.log('用户验证通过: user_no=" & userNo & "');</script>"
    
    ' 3. 查询寄售记录（获取价格、寄售者ID和物品ID）
    Set rsPost = conn_c.Execute("SELECT sell_character_no, include_dil, windex FROM USER_POSTBOX WHERE post_no = '" & post_no & "'")
    If rsPost.EOF Then
        errorMsg = "未找到寄售记录：" & post_no
        ShowError(errorMsg)
    End If
    
    ' 4. 解析寄售信息
    Dim sellCharacterNo, rawPrice
    sellCharacterNo = Trim(rsPost("sell_character_no") & "")
    rawPrice = Trim(rsPost("include_dil") & "")
    windex = rsPost("windex")
    itemcash = CInt(rawPrice)
    rsPost.Close
    
    Response.Write "<script>console.log('寄售信息: sellCharacterNo=" & sellCharacterNo & ", windex=" & windex & ", itemcash=" & itemcash & "');</script>"
    
    ' 5. 判断是否本人
    isSelfRecall = (StrComp(sellCharacterNo, Character, vbBinaryCompare) = 0)
    
    Response.Write "<script>console.log('是否本人取回: " & isSelfRecall & "');</script>"
    
    ' 6. 非本人购买逻辑（需要支付商城币）
    If Not isSelfRecall Then
        ' 6.1 价格验证
        If itemcash <= 0 Then
            errorMsg = "商品价格异常，无法购买！寄售记录ID：" & post_no & "，检测到价格为：" & rawPrice & "（需大于0）"
            ShowError(errorMsg)
        End If
        
        ' 6.2 检查购买者余额
        Set rsCash = conn_b.Execute("SELECT b_amount FROM user_cash WHERE user_no = '" & userNo & "'")
        If rsCash.EOF Then
            errorMsg = "用户账户不存在：" & userNo
            ShowError(errorMsg)
        End If
        freeAmount = CLng(Trim(rsCash("b_amount") & ""))
        rsCash.Close
        
        ' 6.3 余额不足验证
        If freeAmount < itemcash Then
            errorMsg = "商城币不足！需要：" & itemcash & "，余额：" & freeAmount
            ShowError(errorMsg)
        End If
        
        ' 6.4 获取出售者信息
        Set rsSeller = conn_c.Execute("SELECT user_no, character_name FROM user_character WHERE character_no = '" & sellCharacterNo & "'")
        If rsSeller.EOF Then
            errorMsg = "无法找到出售者信息"
            ShowError(errorMsg)
        End If
        sellerUserNo = Trim(rsSeller("user_no") & "")
        sellerCharName = Trim(rsSeller("character_name") & "")
        rsSeller.Close
        
        Response.Write "<script>console.log('出售者信息: sellerUserNo=" & sellerUserNo & ", sellerCharName=" & sellerCharName & "');</script>"
        
        ' 6.5 开始事务处理
        conn_b.BeginTrans
        
        ' 6.6 扣除购买者商城币
        conn_b.execute("UPDATE user_cash SET b_amount = b_amount - " & itemcash & " WHERE user_no = '" & userNo & "'")
        If Err.Number <> 0 Then
            errorMsg = "扣币失败：" & Err.Description
            conn_b.RollbackTrans
            ShowError(errorMsg)
        End If
        
        ' 6.7 计算扣除20%手续费后的金额并转账给出售者
        Dim sellerAmount
        sellerAmount = CInt(itemcash * 0.8) ' 80%给卖家，20%手续费
        
        conn_b.execute("UPDATE user_cash SET b_amount = b_amount + " & sellerAmount & " WHERE user_no = '" & sellerUserNo & "'")
        If Err.Number <> 0 Then
            errorMsg = "转账给出售者失败：" & Err.Description
            conn_b.RollbackTrans
            ShowError(errorMsg)
        End If
        
        ' 6.8 提交事务
        conn_b.CommitTrans
        
        Response.Write "<script>console.log('商城币转账完成: 扣除" & itemcash & "，转账给卖家" & sellerAmount & "');</script>"
        
        ' 6.9 记录交易日志到web_market表
        Dim buyerIP, buyerCharName
        buyerIP = Request.serverVariables("REMOTE_ADDR")
        
        ' 获取购买者角色名称
        Set rsBuyer = conn_c.Execute("SELECT character_name FROM user_character WHERE character_no = '" & Character & "'")
        If Not rsBuyer.EOF Then
            buyerCharName = Trim(rsBuyer("character_name") & "")
        Else
            buyerCharName = "未知购买者"
        End If
        rsBuyer.Close
        
        ' 记录到web_market表
        Dim sqlMarketLog
        sqlMarketLog = "INSERT INTO web_market (buy_name, sell_name, IP, time, Money, Windex, buy_user_no, sell_user_no, actual_amount, status) VALUES (" & _
                      "N'" & Replace(buyerCharName, "'", "''") & "', " & _
                      "N'" & Replace(sellerCharName, "'", "''") & "', " & _
                      "N'" & Replace(buyerIP, "'", "''") & "', " & _
                      "GETDATE(), " & _
                      itemcash & ", " & _
                      windex & ", " & _
                      "'" & Replace(userNo, "'", "''") & "', " & _
                      "'" & Replace(sellerUserNo, "'", "''") & "', " & _
                      sellerAmount & ", " & _
                      "1)"
        
        Response.Write "<script>console.log('准备执行SQL: " & Replace(sqlMarketLog, "'", "\'") & "');</script>"
        
        conn.Execute(sqlMarketLog)
        If Err.Number <> 0 Then
            Response.Write "<script>console.error('记录web_market表失败: " & Replace(Err.Description, "'", "\'") & "');</script>"
            Response.Write "<script>console.error('SQL语句: " & Replace(sqlMarketLog, "'", "\'") & "');</script>"
            Err.Clear
        Else
            Response.Write "<script>console.log('web_market表记录成功');</script>"
        End If
        
        ' 6.10 记录到adminlog表
        Dim logIP, logtxt, rsLog
        logIP = Request.serverVariables("REMOTE_ADDR")
        logtxt = "购买物品ID:" & windex & " 花费商城币:" & itemcash & " 卖家收到:" & sellerAmount
        
        Response.Write "<script>console.log('准备记录adminlog: " & logtxt & "');</script>"
        
        set rsLog = conn.Execute("INSERT INTO [adminlog](admin,datetime,ip,username,adminlog,logtype) VALUES('"&session("username")&"',getdate(),'"&logIP&"','"&Character&"','"&logtxt&"',3)")
        If Err.Number <> 0 Then
            Response.Write "<script>console.error('记录adminlog表失败: " & Replace(Err.Description, "'", "\'") & "');</script>"
            Err.Clear
        Else
            rsLog.Close
            Set rsLog = Nothing
            Response.Write "<script>console.log('adminlog表记录成功');</script>"
        End If
    Else
        ' 如果是取回自己的装备，也记录日志
        Dim recallIP, recallLog, rsRecallLog
        recallIP = Request.serverVariables("REMOTE_ADDR")
        recallLog = "取回自己的装备ID:" & windex
        
        Response.Write "<script>console.log('准备记录取回日志到adminlog: " & recallLog & "');</script>"
        
        set rsRecallLog = conn.Execute("INSERT INTO [adminlog](admin,datetime,ip,username,adminlog,logtype) VALUES('"&session("username")&"',getdate(),'"&recallIP&"','"&Character&"','"&recallLog&"',3)")
        If Err.Number <> 0 Then
            Response.Write "<script>console.error('记录adminlog表失败: " & Replace(Err.Description, "'", "\'") & "');</script>"
            Err.Clear
        Else
            rsRecallLog.Close
            Set rsRecallLog = Nothing
            Response.Write "<script>console.log('取回日志记录成功');</script>"
        End If
    End If
    
    ' 7. 更新邮件信息（标题、内容和所有权）
    Dim targetCharNo, updateSql
    targetCharNo = IIf(isSelfRecall, sellCharacterNo, Character)
    
    If isSelfRecall Then
        ' 取回自己的装备
        updateSql = "UPDATE USER_POSTBOX SET " & _
                   "character_no = '" & targetCharNo & "', " & _
                   "from_char_nm = '系统管理员', " & _
                   "post_title = '装备取回成功', " & _
                   "body_text = '您已成功取回自己寄售的装备，请在90天内取出，否则自动删除物品无法恢复', " & _
                   "state_tag = 0, " & _
                   "ipt_time = GETDATE(), " & _
                   "expire_time = DATEADD(day, 90, GETDATE()) " & _
                   "WHERE post_no = '" & post_no & "'"
    Else
        ' 购买他人装备
        updateSql = "UPDATE USER_POSTBOX SET " & _
                   "character_no = '" & targetCharNo & "', " & _
                   "from_char_nm = '交易市场', " & _
                   "post_title = '恭喜:寄售购买成功', " & _
                   "body_text = '您已成功购买此装备，请在90天内取出，否则自动删除物品无法恢复', " & _
                   "state_tag = 0, " & _
                   "ipt_time = GETDATE(), " & _
                   "expire_time = DATEADD(day, 90, GETDATE()) " & _
                   "WHERE post_no = '" & post_no & "'"
    End If
    
    Response.Write "<script>console.log('准备更新邮件信息');</script>"
    
    conn_c.Execute(updateSql)
    If Err.Number <> 0 Then
        errorMsg = "更新记录失败：" & Err.Description & "（post_no：" & post_no & "）"
        ShowError(errorMsg)
    End If
    
    Response.Write "<script>console.log('邮件信息更新成功');</script>"
    
    ' 8. 成功提示
    Dim successMsg, alertType
    If isSelfRecall Then
        successMsg = "装备取回成功！装备已发送到您的邮箱，请前往游戏邮箱查收。"
        alertType = "success"
    Else
        successMsg = "装备购买成功！已扣除" & itemcash & "商城币（含20%手续费），卖家实际收到" & CInt(itemcash * 0.8) & "商城币，装备已发送到您的邮箱，请前往游戏邮箱查收。"
        alertType = "success"
    End If

    Response.Write "<script>console.log('操作完成，显示成功提示');</script>"
    Response.Write "<script>swal({title: ""操作成功!"",text: """ & successMsg & """,type: """ & alertType & """}, function() {location.href='Shop.asp';});</script>"
    Response.End
    
    ' 错误处理
    If Err.Number <> 0 Then
        errorMsg = "操作异常：" & Err.Description
        ShowError(errorMsg)
    End If
    On Error Goto 0
End Sub

'----------------------------------------------------更新装备属性--------------------------------------------------------------------
Sub UpdateSave()  

    If Not ChkLogin Then
			Response.write "请先前往主页登录您的帐号,然后刷新本页面."
			response.end
    End If


    If Not ChkPost Then
        response.Write"System Error!"
        response.End
    End If

	' 替换md5函数调用，解决可能的Automation对象问题
	If session("safekey")<>Left(SimpleMD5(SimpleMD5(session("user_no"))),6) Then
			Response.Write "<script>alert(""验证码错误,请重新获取验证码!"");history.go(-1);</script>"
			response.End
	End If

	  If Not ChkOnLine Then
		 Response.Write "<script>alert(""系统检测到您当前的游戏状态为在线,请退出游戏后重新进行此操作!"");history.go(-1);</script>"
        response.End
    End If

    Dim Id, wIndex, line_no, hole
    Id = checkstr(Request("Id"))
	wIndex=Trim(request("wIndex"))
	line_no=Trim(request("line_no"))
	hole=Trim(request("hole"))

    ' 验证Id为数字
    If Not IsNumeric(Id) Then
        Response.Write "<script>alert('角色ID格式错误!');history.go(-1);</script>"
        Response.End
    End If
    Id = CLng(Id)

    If Not IsNumeric(wIndex) Then 
        Response.Write "非法参数1"
        Response.End
    End If
    wIndex = CLng(wIndex)

    If Not IsNumeric(line_no) Then 
        Response.Write "非法参数2"
        Response.End
    End If
    line_no = CLng(line_no)


	set rschr=conn_c.execute("select Character_name,Character_no,bypcClass from User_Character where user_no='"&session("user_no")&"' and Character_no="&Id&"")
	   If  rschr.eof Or rschr.bof Then 
        Response.Write "系统忙.请重新登录."
        Response.End
    End If



'统计订单金额
		  SET RS_count = conn.Execute("select sum(amount),sum(gamecash) from PayLog where trade_status>0 and amount>0 and userid='"&session("user_no")&"'")
		  If RS_count(0)>0  Then 
			gamecash=CLng(Trim(RS_count(1) & "")) ' 安全转换
		  Else
		  Response.Write "<script>alert(""没有订单信息,无法更换道具"");history.go(-1);</script>"
		  response.End
		  End If 
		  RS_count.close


				set sqlitem=conn_c.execute("select *  from user_bag where Character_no="&Id&" and line_no="&line_no&" and Windex="&Windex)'查询装备是否唯一,防止构造特殊参数.

				If sqlitem.eof Or sqlitem.bof Then 
				        Response.Write "<script>alert(""参数错误.."");history.go(-1);</script>"
						response.End
				End If 
				info=showhex(sqlitem("info")) '装备属性代码
				vipitem_no=ShowHex(sqlitem("dwserialnumber")) '格式化dwserialnumber
				vipitem_no= left(vipitem_no,12)
				vipitem_no=chn10(vipitem_no)
				'response.write vipitem_no&"<br>"
				'response.write session("user_no")



				SET RSitem = conn_i.Execute("select * from Item2 where itemid="&wIndex&"")
					   If (RSitem.eof Or RSitem.bof) Then  
							Response.Write "<script>alert(""装备参数错误,请联系管理员!"");history.go(-1);</script>"
							Response.End
					  Else
						itemcash= CLng(Trim(RSitem("itemcash") & "")) ' 安全转换
						hole=CLng(Trim(RSitem("hole") & "")) ' 安全转换
						sellprice=CLng(Trim(RSitem("sellprice") & "")) ' 安全转换
						ismaya=CLng(Trim(RSitem("maya") & "")) ' 安全转换
					  End If 	

					If ismaya<>1 Then '判断是否为青蛙草莓
						If int(vipitem_no)<>int(session("user_no")) Then 
								Response.Write "<script>alert(""该装备为非会员装备或该装备不属于您本人,所以无法更换!"");history.go(-1);</script>"
								 Response.End
						 End If 
					End If 


						If hole>0 Then '洞数量大于0 则同时返还玛雅
						  '1洞判断
						  if MID(info,1,4)="192C" or MID(info,1,4)="1972" or MID(info,1,4)="199A" or MID(info,1,4)="19A4"  or MID(info,1,4)="197C"  or MID(info,1,4)="1986"  or MID(info,1,4)="1968"   or MID(info,1,4)="196D"   or MID(info,1,4)="198B"   or MID(info,1,4)="1995"  Then
						  set rsstone=conn_i.execute("select *  from item2 where isstone=true and itemid="&chn10(MID(info,1,4))&"")
								If rsstone.eof Or rsstone.bof Then 
										maya1=0
								Else
										maya1=CLng(Trim(rsstone("itemcash") & "")) ' 安全转换
								End If 
						rsstone.close
						end If

						 '2洞判断
						if MID(info,5,4)="192C" or MID(info,5,4)="1972" or MID(info,5,4)="199A" or MID(info,5,4)="19A4"  or MID(info,5,4)="197C"  or MID(info,5,4)="1986"  or MID(info,5,4)="1968"   or MID(info,5,4)="196D"   or MID(info,5,4)="198B"   or MID(info,5,4)="1995" Then
						  set rsstone=conn_i.execute("select *  from item2 where isstone=true and itemid="&chn10(MID(info,5,4))&"")
								If rsstone.eof Or rsstone.bof Then 
										maya2=0
								Else
										maya2=CLng(Trim(rsstone("itemcash") & "")) ' 安全转换
								End If 
						rsstone.close
						end If

				if hole>2 Then '如果3洞以上则检测3洞代码
						if  MID(info,9,4)="192C" or MID(info,9,4)="1972" or MID(info,9,4)="199A" or MID(info,9,4)="19A4"  or MID(info,9,4)="197C"  or MID(info,9,4)="1986"  or MID(info,9,4)="1968"   or MID(info,9,4)="196D"   or MID(info,9,4)="198B"   or MID(info,9,4)="1995"  Then
						  set rsstone=conn_i.execute("select *  from item2 where isstone=true and itemid="&chn10(MID(info,9,4))&"")
								If rsstone.eof Or rsstone.bof Then 
										maya3=0
								Else
										maya3=CLng(Trim(rsstone("itemcash") & "")) ' 安全转换
								End If 
						rsstone.close
						end If
				End If

				if hole=4 Then '4洞
						if MID(info,13,4)="192C" or MID(info,13,4)="1972" or MID(info,13,4)="199A" or MID(info,13,4)="19A4"  or MID(info,13,4)="197C"  or MID(info,13,4)="1986"  or MID(info,13,4)="1968"   or MID(info,13,4)="196D"   or MID(info,13,4)="198B"   or MID(info,13,4)="1995"  Then
						  set rsstone=conn_i.execute("select *  from item2 where isstone=true and itemid="&chn10(MID(info,13,4))&"")
								If rsstone.eof Or rsstone.bof Then 
										maya4=0
								Else
										maya4=CLng(Trim(rsstone("itemcash") & "")) ' 安全转换
								End If 
						rsstone.close
						end If
				End If
			maya=int(maya1)+int(maya2)+int(maya3)+int(maya4)
			maya16="00"&chn16(int(maya))
		End If 
'返还玛雅结束

'统计兑换金额
		SET RS_log_count = conn.Execute("select sum(itemcash) from ItemToCash where logtype=1 and username='"&session("username")&"'")
		Dim logCount, givecash
		logCount = 0
		If Not RS_log_count.EOF And Not IsNull(RS_log_count(0)) Then
			logCount = CLng(Trim(RS_log_count(0) & "")) ' 安全转换
		End If
			 If logCount > gamecash Then '如果大于订单金额则使用扣费的方式
				givecash=itemcash-sellprice
			else
				givecash=itemcash
			End If 

				set delitem=conn_c.execute("Delete  from user_bag where Character_no="&Id&" and line_no="&line_no&" and Windex="&Windex) '删除首饰翅膀等
				If ismaya=1 Then 
					maya16="00"&chn16(int(itemcash-sellprice))
					maya=int(itemcash-sellprice)
				Else
					set rs_cash=conn_b.execute("update user_cash set amount=amount+"&givecash&" where user_no='"&session("user_no")&"'")'发送商城币
				End If 
				'response.write"maya="&maya
				'response.write"<br>maya16="&maya16
				'response.end

			If maya>0 Then '如果玛雅数量大于0则发送玛雅
				post_no=GenerateUniqueSN() ' 使用自定义函数生成唯一编号
				set rs=server.CreateObject("adodb.recordset")
				sqlstr="select * from user_postbox "
				rs.open sqlstr,conn_c,1,3
				Rs.AddNew
				rs("character_no")=ID
				rs("post_no")=post_no
				rs("from_char_nm")="道具管理系统" 
				rs("post_sort")=0 'gm发送为0
				rs("post_title")="兑换玛雅之石"&maya&"颗"
				rs("body_text")="兑换玛雅之石"&maya&"颗"
				rs("state_tag")=0 '0未查看1以查看
				rs("item_tag")=1  '1未取出 2已取出
				rs("wIndex")=9906 '装备代码
				rs("dwSerialNumber")="00000000000000000000000000000000" '未知
				rs("byHeader")=1
				rs("info")=maya16 '玛雅数量
				rs("dil_tag")=0	'未知
				rs("include_dil")=0	'未知
				rs("ipt_time")=Now() '发送时间
				rs("expire_time")=Now()+90 '过期日期
				rs.update
				rs.close
			End If 

				If ismaya=1  Then '如果兑换青蛙,则兑换订单中不计费
				itemcash2=itemcash
				itemcash=0
				End If 

				set rslog=conn.execute("INSERT INTO ItemToCash (username,character_no,windex,itemcash,exctime,logtype) VALUES('"&session("username")&"','"&ID&"',"&windex&","&itemcash&",getdate(),1)") '写日志



				If ismaya=1  Then
					Response.Write "<script>alert(""已经成功兑换玛雅之石"&(itemcash2-sellprice)&"颗,请前往邮箱领取玛雅之石"");history.go(-2);</script>"
				Elseif maya>0 then
					Response.Write "<script>alert(""已经成功兑换商城币"&givecash&"个!玛雅之石"&maya&",请前往邮箱领取玛雅之石"");history.go(-2);</script>"
				Else
					Response.Write "<script>alert(""已经成功兑换商城币"&givecash&"个!"");history.go(-2);</script>"
				End If 
rsitem.close
End Sub
'---------------------------------------------------兑换道具--------------------------------------------------------------------
Sub ExchangeItem_Save()  
    If Not ChkLogin Then
        Response.redirect "../user.asp?Action=UserLogin&furl=1"
        response.end
    End If

    If Not ChkPost Then
        response.Write"System Error!"
        response.End
    End If

    If Not ChkOnLine Then
        Response.Write "<script>alert('系统检测到您当前的游戏状态为在线,请退出游戏后重新进行此操作!');history.go(-1);</script>"
        response.End
    End If

    Dim Id, wIndex, line_no, newid
    Id = checkstr(Request("Id"))
    wIndex = Trim(request("Windex"))
    line_no = Trim(request("line_no"))
    newid = Trim(request("newid"))

    ' 验证Id不为空
    If Id = "" Then
        Response.Write "<script>alert('角色ID不能为空!');history.go(-1);</script>"
        Response.End
    End If

    If Not IsNumeric(wIndex) Then 
        Response.Write "非法参数001"
        Response.End
    End If
    wIndex = CLng(wIndex)

    If Not IsNumeric(line_no) Then 
        Response.Write "非法参数002"
        Response.End
    End If
    line_no = CLng(line_no)

    If Not IsNumeric(newid) Then 
        Response.Write "非法参数003"
        Response.End
    End If
    newid = CLng(newid)

    ' 从SQL数据库读取升级信息
    set rsitem = conn.Execute("select * from WEB_ExchangeItem where oldid=" & wIndex & " and newid=" & newid)
    If rsitem.eof Or rsitem.bof Then 
        response.write "非法参数004!!"
        response.End
    Else
        itemcash = CLng(Trim(rsitem("needcash") & ""))
        oldname = rsitem("oldname")
        newname = rsitem("newname")
    End If 
    rsitem.close

    ' 检查背包中是否有该装备
    set sqlitem = conn_c.execute("select * from user_bag where Character_no='" & Id & "' and line_no=" & line_no & " and Windex=" & wIndex)
    If sqlitem.eof Or sqlitem.bof Then 
        Response.Write "<script>alert('参数错误或装备不存在!');history.go(-1);</script>"
        response.End
    End If 
    sqlitem.close

    ' 检查商城币余额
    SET RScash = conn_b.Execute("select * from user_cash where user_no='" & session("user_no") & "'")
    If RScash.eof Or RScash.bof Then
        Response.Write "<script>alert('商城信息有错误,请联系管理员!');history.go(-1);</script>"
        response.End
    Else
        Dim cashAmount
        cashAmount = CLng(Trim(RScash("amount") & ""))
        If cashAmount < itemcash Then
            Response.Write "<script>alert('商城币不足! 需要" & itemcash & "点，当前有" & cashAmount & "点');history.go(-1);</script>"
            response.End
        End If 
    End If 
    RScash.close

    ' 扣除商城币
    set rs3 = conn_b.execute("update user_cash set amount=amount-" & itemcash & " where user_no='" & session("user_no") & "'")

    ' 升级装备
    set rsupdate = conn_c.execute("update user_bag set windex=" & newid & " where Character_no='" & Id & "' and line_no=" & line_no & " and Windex=" & wIndex)

' 记录日志 - 根据新的表结构
On Error Resume Next
ip = Request.serverVariables("REMOTE_ADDR")

' 获取角色名称 - 确保从正确的数据库连接查询
Dim charName
charName = "未知角色"
Set rsChar = conn_c.Execute("SELECT character_name FROM user_character WHERE character_no='" & Id & "'")
If Not rsChar.EOF Then
    charName = Trim(rsChar("character_name") & "")
    If charName = "" Then charName = "未知角色"
Else
    charName = "角色不存在"
End If
rsChar.Close
    
 ' 构建日志内容
Dim logText
logText = "装备升级:" & oldname & " -> " & newname & " - 消耗:" & itemcash & "商城币"

' 根据表结构构建插入语句
' 表字段: [id], [admin], [datetime], [ip], [user_id], [adminlog], [note], [logtype], [user_no], [character_no], [char_name]
Dim sqlLog
sqlLog = "INSERT INTO [adminlog] (" & _
         "[admin], [datetime], [ip], [user_id], [adminlog], [logtype], [user_no], [character_no], [char_name]" & _
         ") VALUES (" & _
         "N'" & Replace(session("username"), "'", "''") & "', " & _
         "GETDATE(), " & _
         "N'" & Replace(ip, "'", "''") & "', " & _
         "N'" & Replace(Id, "'", "''") & "', " & _
         "N'" & Replace(logText, "'", "''") & "', " & _
         "3, " & _
         session("user_no") & ", " & _
         "N'" & Replace(Id, "'", "''") & "', " & _
         "N'" & Replace(charName, "'", "''") & "'" & _
         ")"

' 执行日志记录
conn.Execute(sqlLog)

If Err.Number <> 0 Then
    ' 如果日志记录失败，尝试简化版本
    Dim sqlLogSimple
    sqlLogSimple = "INSERT INTO [adminlog] ([admin], [datetime], [ip], [user_id], [adminlog], [logtype], [char_name]) " & _
                  "VALUES (N'" & Replace(session("username"), "'", "''") & "', GETDATE(), N'" & Replace(ip, "'", "''") & "', N'" & Replace(Id, "'", "''") & "', N'" & Replace(logText, "'", "''") & "', 3, N'" & Replace(charName, "'", "''") & "')"
    
    conn.Execute(sqlLogSimple)
    
    If Err.Number <> 0 Then
        ' 如果还是失败，记录到文本文件
        Dim fs, ts, logFile
        Set fs = Server.CreateObject("Scripting.FileSystemObject")
        logFile = Server.MapPath("exchange_log.txt")
        Set ts = fs.OpenTextFile(logFile, 8, True)
        ts.WriteLine(Now() & " - " & session("username") & " - " & Id & " - " & charName & " - " & logText)
        ts.Close
        Set ts = Nothing
        Set fs = Nothing
        Err.Clear
    End If
End If
On Error Goto 0

    ' 使用漂亮的sweetalert提示
    Response.Write "<script>swal({title: '升级成功!', text: '装备升级成功! " & oldname & " → " & newname & "', type: 'success', confirmButtonText: '确定'}, function() {window.location.href='Shop.asp?Action=ExchangeItem&Id=" & Id & "';});</script>"
    Response.End
End Sub
'------------------------------------------------------------------------------'
' 空过程定义（避免未定义错误）
Sub UPgradeSave()
    Response.Write "<script>alert('该功能暂未实现');history.go(-1);</script>"
    Response.End
End Sub
' ========== 主入口点（新增在文件末尾） ==========
Call HandleAction()
%>
</body>
</html>
