<%
'----------------------属性判断-------------------------------
Const TBL_ITEMOPTION = "web_itemoption"
Const TBL_SOCKET = "web_itemetc_socket"
' 设置Session超时时间为1440分钟（24小时）
Session.Timeout = 1440

' 设置Cookie过期时间
If Session("user_no") <> "" Then
    Response.Cookies("user")("user_no") = Session("user_no")
    Response.Cookies("user")("username") = Session("username")
    Response.Cookies("user")("expires") = DateAdd("d", 7, Now())
End If


' 检查用户是否已登录
Function IsLoggedIn()
    If Session("user_no") <> "" Then
        ' 检查Session是否即将过期（还有5分钟）
        If Session.Timeout > 5 Then
            ' 续期Session
            Session.Timeout = 1440
            ' 更新Cookie过期时间
            Response.Cookies("user")("expires") = DateAdd("d", 7, Now())
        End If
        IsLoggedIn = True
    Else
        IsLoggedIn = False
    End If
End Function



' 自动登录检查（基于Cookie）
Function AutoLogin()
    If Request.Cookies("user")("user_no") <> "" And Session("user_no") = "" Then
        ' 从Cookie读取用户信息
        Dim user_no, username
        user_no = Request.Cookies("user")("user_no")
        username = Request.Cookies("user")("username")
        
        ' 验证用户有效性
        Set rs = conn_c.Execute("SELECT user_no, username FROM user_info WHERE user_no='" & user_no & "' AND username='" & username & "'")
        If Not rs.EOF Then
            Session("user_no") = rs("user_no")
            Session("username") = rs("username")
            Session.Timeout = 1440
            AutoLogin = True
        Else
            ' Cookie无效，清除
            Response.Cookies("user").Expires = Date() - 1
            AutoLogin = False
        End If
        rs.Close
    Else
        AutoLogin = False
    End If
End Function
'--------------------角色下拉框函数-------------------
' 角色下拉框函数
Function GetCharacterDropdown()
    If Not ChkLogin Then
        GetCharacterDropdown = ""
        Exit Function
    End If
    
    Dim html, currentCharId
    currentCharId = Request("Id")
    If currentCharId = "" Then currentCharId = Session("current_char_id")
    
    html = "<div style='position: relative; display: inline-block;'>"
    html = html & "<select id='charSelect' style='"
    html = html & "background: rgba(20, 30, 40, 0.9) !important;"
    html = html & "border: 1px solid rgba(74, 158, 255, 0.3) !important;"
    html = html & "color: #e0e0e0 !important;"
    html = html & "font-size: 10px !important;"
    html = html & "padding: 2px 20px 2px 5px !important;"
    html = html & "cursor: pointer !important;"
    html = html & "outline: none !important;"
    html = html & "width: 100px !important;"
    html = html & "appearance: none !important;"
    html = html & "-webkit-appearance: none !important;"
    html = html & "-moz-appearance: none !important;"
    html = html & "border-radius: 4px !important;"
    html = html & "' onchange='switchCharacter(this.value)'>"
    
    ' 获取该账号的所有角色
    Set rsChars = conn_c.Execute("select Character_no, Character_name, wlevel from User_Character where user_no='" & session("user_no") & "' order by wlevel desc")
    
    If Not rsChars.EOF Then
        Do While Not rsChars.EOF
            Dim selected, charId, charName, charLevel
            charId = rsChars("Character_no")
            charName = rsChars("Character_name")
            charLevel = rsChars("wlevel")
            
            selected = ""
            If CStr(charId) = CStr(currentCharId) Then selected = "selected"
            
            html = html & "<option value='" & charId & "' " & selected & " style='"
            html = html & "background: #1a2530 !important;"
            html = html & "color: #e0e0e0 !important;"
            html = html & "padding: 2px 5px !important;"
            html = html & "font-size: 10px !important;"
            html = html & "'>"
            html = html & Left(charName, 5) & "." & charLevel
            html = html & "</option>"
            
            rsChars.MoveNext
        Loop
    End If
    rsChars.Close
    
    html = html & "</select>"
    ' 添加箭头到select后面
    html = html & "<i class='fas fa-chevron-down' style='"
    html = html & "position: absolute !important;"
    html = html & "right: 6px !important;"
    html = html & "top: 50% !important;"
    html = html & "transform: translateY(-50%) !important;"
    html = html & "color: #4a9eff !important;"
    html = html & "font-size: 8px !important;"
    html = html & "pointer-events: none !important;"
    html = html & "z-index: 1 !important;"
    html = html & "'></i>"
    html = html & "</div>"
    
    GetCharacterDropdown = html
End Function

'--------------------获取用户总在线时间-------------------
' 功能：根据 user_no 计算用户在 USER_CONNLOG_KEY 表中的总在线时长
' 返回：格式化后的字符串，如 "123 小时 45 分钟"
Function GetUserTotalOnlineTime(user_no)
    On Error Resume Next
    Dim rs, totalMinutes
    totalMinutes = 0
    ' 使用 DATEDIFF 高效计算分钟差，并求和
    Set rs = conn.Execute("SELECT SUM(DATEDIFF(minute, login_time, logout_time)) AS TotalMins FROM USER_CONNLOG_KEY WHERE user_no = '" & user_no & "' AND logout_time IS NOT NULL")
    If Not rs.EOF Then
        totalMinutes = CLng(0 & rs("TotalMins"))
    End If
    rs.Close
    Set rs = Nothing

    ' 将总分钟数转换为小时和分钟
    Dim hours, minutes
    hours = totalMinutes \ 60
    minutes = totalMinutes Mod 60
    
    GetUserTotalOnlineTime = hours & " 小时 " & minutes & " 分钟"

    If Err.Number <> 0 Then
        GetUserTotalOnlineTime = "计算中..."
        Err.Clear
    End If
End Function

'--------------------获取用户总货币-------------------
' 功能：根据 user_no 查询其所有角色的C币和B币总和
' 返回：一个数组，Array(总C币, 总B币)
Function GetUserTotalCurrency(user_no)
    On Error Resume Next
    Dim rs, totalCCoin, totalBCoin
    totalCCoin = 0 : totalBCoin = 0

    ' 【重要】请根据您的实际字段名修改 C_Coin 和 B_Coin
    ' 假设C币和B币字段在 user_character 表中
    Set rs = conn_c.Execute("SELECT SUM(ISNULL(C_Coin, 0)) AS TotalC, SUM(ISNULL(B_Coin, 0)) AS TotalB FROM user_character WHERE user_no = '" & user_no & "'")
    If Not rs.EOF Then
        totalCCoin = CLng(0 & rs("TotalC"))
        totalBCoin = CLng(0 & rs("TotalB"))
    End If
    rs.Close
    Set rs = Nothing

    GetUserTotalCurrency = Array(totalCCoin, totalBCoin)

    If Err.Number <> 0 Then
        GetUserTotalCurrency = Array(0, 0)
        Err.Clear
    End If
End Function


Function ToUtf8(str)
    On Error Resume Next
    If str = "" Or IsNull(str) Then
        ToUtf8 = ""
        Exit Function
    End If
    Dim adoStream
    Set adoStream = Server.CreateObject("ADODB.Stream")
    adoStream.Type = 2
    adoStream.Mode = 3
    adoStream.Open()
    adoStream.CharSet = "gbk" ' 数据库是GBK
    adoStream.WriteText str
    adoStream.Position = 0
    adoStream.CharSet = "utf-8" ' 网页是UTF-8
    ToUtf8 = adoStream.ReadText()
    adoStream.Close()
    Set adoStream = Nothing
End Function


Function SafeHex(s)
s = Trim("" & s)
If Len(s) >= 2 Then
If LCase(Left(s, 2)) = "0x" Then s = Mid(s, 3)
End If
SafeHex = UCase(s)
End Function

Sub CalcCounts(byHeader, ByRef attrCount, ByRef socketCount, ByRef isStack)
Dim b, r
attrCount = 0 : socketCount = 0 : isStack = False
If Not IsNumeric(byHeader) Then Exit Sub
b = CLng(byHeader)
If b = 0 Then Exit Sub
If b = 1 Then isStack = True : Exit Sub
If b > 15 Then
socketCount = Int(b / 16)
r = b Mod 16
If r >= 5 And r <= 8 Then attrCount = r - 4
Else
If b >= 5 And b <= 8 Then attrCount = b - 4
End If
If attrCount < 0 Then attrCount = 0
If attrCount > 4 Then attrCount = 4
If socketCount < 0 Then socketCount = 0
If socketCount > 4 Then socketCount = 4
End Sub

Function GetItemQuantity(hexStr)
Dim v
On Error Resume Next
v = Hexnumber(SafeHex(hexStr))
On Error GoTo 0
If IsNumeric(v) Then
GetItemQuantity = CStr(v)
Else
GetItemQuantity = "1"
End If
End Function

Function JsonEscape(s)
s = Trim("" & s)
s = Replace(s, "", "\")
s = Replace(s, """", """")
s = Replace(s, vbCrLf, "\n")
s = Replace(s, vbCr, "\n")
s = Replace(s, vbLf, "\n")
JsonEscape = s
End Function

' 输出 JSON，前端增强 tooltip 用
Function BuildItemDetailsJson(itemName, hexStr, byHeader)
Dim hexInfo, attrCount, socketCount, isStack
Dim i, length, startPos, optIdx, optVal, rs, desc, minData, maxData, delta, value
Dim attrJson, sockJson, code, rs2, qty

hexInfo = SafeHex(hexStr)
Call CalcCounts(byHeader, attrCount, socketCount, isStack)

qty = "1"
If isStack Then qty = GetItemQuantity(hexInfo)

attrJson = ""
If attrCount > 0 Then
length = Len(hexInfo)
startPos = length - (attrCount * 6) + 1
For i = 0 To attrCount - 1
optIdx = Hexnumber(Mid(hexInfo, startPos + i * 6, 4))
optVal = Hexnumber(Mid(hexInfo, startPos + i * 6 + 4, 2))
If IsNumeric(optIdx) Then
On Error Resume Next
Set rs = conn.Execute("SELECT TOP 1 Description, minData, MaxData FROM " & TBL_ITEMOPTION & " WHERE OptionIndex=" & CLng(optIdx))
If Err.Number = 0 And Not rs Is Nothing Then
If Not rs.EOF Then
desc = Trim("" & rs("Description"))
minData = CLng(rs("minData"))
maxData = CLng(rs("MaxData"))
delta = (maxData - minData) / 100
value = CLng(minData + Fix(delta * CLng(optVal)))
If attrJson <> "" Then attrJson = attrJson & ","
attrJson = attrJson & "{""desc"":""" & JsonEscape(desc) & """,""value"":" & value & "}"
End If
rs.Close : Set rs = Nothing
Else
Err.Clear
End If
On Error GoTo 0
End If
Next
End If

sockJson = ""
If socketCount > 0 Then
For i = 0 To socketCount - 1
code = Hexnumber(Mid(hexInfo, 1 + i * 4, 4))
If IsNumeric(code) And CLng(code) <> 0 Then
On Error Resume Next
Set rs2 = conn.Execute("SELECT TOP 1 name, value FROM " & TBL_SOCKET & " WHERE id=" & CLng(code))
If Err.Number = 0 And Not rs2 Is Nothing Then
If Not rs2.EOF Then
If sockJson <> "" Then sockJson = sockJson & ","
sockJson = sockJson & "{""name"":""" & JsonEscape(rs2("name")) & """,""value"":""" & JsonEscape(rs2("value")) & """}"
End If
rs2.Close : Set rs2 = Nothing
Else
Err.Clear
End If
On Error GoTo 0
End If
Next
End If

BuildItemDetailsJson = "{""name"":""" & JsonEscape(itemName) & """,""qty"":" & qty & ",""attrs"":[" & attrJson & "],""sockets"":[" & sockJson & "]}"
End Function

' 字符串版（兼容 View_Item，回退用）
Function BuildItemOptionHtml(hexStr, byHeader)
Dim hexInfo, attrCount, socketCount, isStack
Dim html, sockHtml, i, length, startPos, optIdx, optVal, rs, desc, minData, maxData, delta, value, code, rs2
hexInfo = SafeHex(hexStr)
Call CalcCounts(byHeader, attrCount, socketCount, isStack)
html = "" : sockHtml = ""

If attrCount > 0 Then
length = Len(hexInfo)
startPos = length - (attrCount * 6) + 1
For i = 0 To attrCount - 1
optIdx = Hexnumber(Mid(hexInfo, startPos + i * 6, 4))
optVal = Hexnumber(Mid(hexInfo, startPos + i * 6 + 4, 2))
If IsNumeric(optIdx) Then
On Error Resume Next
Set rs = conn.Execute("SELECT TOP 1 Description, minData, MaxData FROM " & TBL_ITEMOPTION & " WHERE OptionIndex=" & CLng(optIdx))
If Err.Number = 0 And Not rs Is Nothing Then
If Not rs.EOF Then
desc = rs("Description")
minData = CLng(rs("minData"))
maxData = CLng(rs("MaxData"))
delta = (maxData - minData) / 100
value = CLng(minData + Fix(delta * CLng(optVal)))
If html <> "" Then html = html & "; "
html = html & Server.HTMLEncode("" & desc) & value
End If
rs.Close : Set rs = Nothing
Else
Err.Clear
End If
On Error GoTo 0
End If
Next
End If

If socketCount > 0 Then
For i = 0 To socketCount - 1
code = Hexnumber(Mid(hexInfo, 1 + i * 4, 4))
If IsNumeric(code) And CLng(code) <> 0 Then
On Error Resume Next
Set rs2 = conn.Execute("SELECT TOP 1 name, value FROM " & TBL_SOCKET & " WHERE id=" & CLng(code))
If Err.Number = 0 And Not rs2 Is Nothing Then
If Not rs2.EOF Then
If sockHtml <> "" Then sockHtml = sockHtml & "; "
sockHtml = sockHtml & Server.HTMLEncode("" & rs2("name") & rs2("value"))
End If
rs2.Close : Set rs2 = Nothing
Else
Err.Clear
End If
On Error GoTo 0
End If
Next
End If

If html = "" Then html = "属性无"
If sockHtml = "" Then sockHtml = "无镶嵌"
BuildItemOptionHtml = html & "; " & sockHtml
End Function

' 兼容旧名字：直接返回字符串（View_Item 用）
Function itemoption(infostr, byheader)
Dim hexInfo : hexInfo = SafeHex(infostr)
Dim attrCount, socketCount, isStack
Call CalcCounts(byheader, attrCount, socketCount, isStack)
If isStack Then
itemoption = "数量：" & GetItemQuantity(hexInfo)
Else
itemoption = BuildItemOptionHtml(hexInfo, byheader)
End If
End Function
'-------------------------语言过滤--------------------------------------'


Sub DataClose()
    Set Rs=Nothing
	Conn.Close
	Set Conn=Nothing
End Sub 

Function cacuIp(ip)
Dim srIp, aIp
If ip="" Then Exit Function
srIp=0
aIp = Split(ip,".")
If UBound(aIP)<>3 Then
cacuIP=0
Exit Function
End If
For ii=0 To 3
srIp=srIp+(CInt(aIP(ii))*(256^(3-ii)))
Next
cacuIp=srIp-1
End Function 


Function IsValidStr(str)
   IsValidStr = False
   On Error Resume Next
   If IsNull(str) Then Exit Function
   If Trim(str) = Empty Then Exit Function
	str=lcase(str)
   Dim ForbidStr, i
	 ForbidStr = "ping|操|日|妈|叼|mac|草|垃圾|fuck|sb|‰|bitch|性爱|三级|sex|腚|妓|娼|阴蒂|奸|尻|贱|婊|靠|叉|龟头|屄|赑|妣|肏|尻|屌|cnctz|管理|%|&|$|#|[|]|+|-|*|/|\|<|>|;|,|.| |gm|" & Chr(32) & "|" & Chr(0) & "|" & Chr(1) & "|" & Chr(2) & "|" & Chr(3) & "|" & Chr(4) & "|" & Chr(5) & "|" & Chr(6) & "|" & Chr(7) & "|" & Chr(8) & "|" & Chr(9) & "|" & Chr(10) & "|" & Chr(11) & "|" & Chr(12) & "|" & Chr(13) & "|" & Chr(14) & "|" & Chr(15) & "|" & Chr(16) & "|" & Chr(17) & "|" & Chr(18) & "|" & Chr(19) & "|" & Chr(20) & "|" & Chr(21) & "|" & Chr(22) & "|" & Chr(23) & "|" & Chr(24) & "|" & Chr(25) & "|" & Chr(26) & "|" & Chr(27) & "|" & Chr(28) & "|" & Chr(29) & "|" & Chr(64) & "|" & Chr(34) & "|" & Chr(61) & "|" & Chr(95) & "|" & Chr(96) & "|" & Chr(10) & "|" & Chr(71) & "|" & Chr(39) & "|" & Chr(9) 
   ForbidStr = Split(ForbidStr, "|")
   For i = 0 To UBound(ForbidStr)
    If InStr(1,str, ForbidStr(i),1) > 0 Then
     IsValidStr = False
     Exit Function
    End If
   Next
   IsValidStr = True
End Function

Function CheckIfEnglish(Str)
	str=LCase(str)
    Temp_Str=Len(Str)
    Letters = "abcdefghijklmnopqrstuvwxyz1234567890_-"
    CheckIfEnglish=false
    For I005=1 To Temp_Str
        Test_Str=(Mid(Str,I005,1))
        if not InStr(Letters,Test_Str) > 0 then
           CheckIfEnglish=true
           exit function
        End If
    Next
End Function

function IsValidEmail(email)
dim names, name, i, c
IsValidEmail = true
names = Split(email, "@")
if UBound(names) <> 1 then
   IsValidEmail = false
   exit function
end if
for each name in names
   if Len(name) <= 0 then
     IsValidEmail = false
     exit function
   end if
   for i = 1 to Len(name)
     c = Lcase(Mid(name, i, 1))
     if InStr("abcdefghijklmnopqrstuvwxyz_-.", c) <= 0 and not IsNumeric(c) then
       IsValidEmail = false
   exit function
     end if
   next
   if Left(name, 1) = "." or Right(name, 1) = "." then
      IsValidEmail = false
      exit function
   end if
next
if InStr(names(1), ".") <= 0 then
   IsValidEmail = false
   exit function
end if
i = Len(names(1)) - InStrRev(names(1), ".")
if i <> 2 and i <> 3 then
   IsValidEmail = false
   exit function
end if
if InStr(email, "..") > 0 then
   IsValidEmail = false
end if
end function


function ChkPost()	'检查外部提交数据
	chkpost=false
	server_v1=Cstr(Request.ServerVariables("HTTP_REFERER"))
	server_v2=Cstr(Request.ServerVariables("SERVER_NAME"))
	if mid(server_v1,8,len(server_v2))<>server_v2 then
		chkpost=false
	else
		chkpost=true
	end if
end function

 Function GetCode()
	Randomize
	GetCode=cstr(Int((9999 - 1000 + 1) * Rnd() + 1000))
	session("GetCode")=GetCode
End Function


 Function ChkLogin() '检查用户登录状态
 ChkLogin=false
	 If session("username")="" or   session("user_no")="" Then 
			ChkLogin=false
	 else
			ChkLogin=true
	 end if
End Function 



 Function ChkOnLine() '检查用户是否在线
 ChkOnLine=false
 If IsNull(session("username")) Then 
		ChkLogin=False
		Exit Function 
Else
			set rsol=conn.execute("select user_id,login_flag from USER_PROFILE where user_no='"&session("user_no")&"' and login_flag='0'")
			If rsol.EOF Or rsol.bof Then
				ChkOnLine=False
			Else
				ChkOnLine=true
		end If
end if
End Function 

Function GetClass(Str)
		Str=Int(Str)
		Select case Str
		case 0
			GetClass="战士"
		case 1
			GetClass="弓箭手"
		case 2
			GetClass="法师"
   		case 3 
   			GetClass="驱魔师"
   		case 4 
   			GetClass="巫师"
   		case 5 
   			GetClass="狂战士"
   		case 6 
   			GetClass="魔枪手"
   		case 7 
   			GetClass="龙骑士"
   		case 9 
   			GetClass="暗咒师"
		case 10 
   			GetClass="女武神"
   		case 11 
   			GetClass="死神"
   		case 12 
   			GetClass="女战圣"
		End select	
End Function


	Public Function Checkstr(Str)
		If Isnull(Str) Then
			CheckStr = ""
			Exit Function 
		End If
		Str = Replace(Str,Chr(0),"")
		CheckStr = Replace(Str,"'","''")
	End Function


'取得含有中文字符串的长度
Function chLen(Str)
    Dim i
    chLen = 0
    If Len(Str) < 1 Then Exit Function
    For i = 1 To Len(Str)
        If Asc(Mid(Str, i, 1)) > 0 Then
            chLen = chLen + 1
        Else
            chLen = chLen + 2
        End If
    Next
End Function

'16进制转10进制
Function chn10(nums)
Dim tmp,tmpstr,i
nums_len=Len(nums)
For i=1 To nums_len
tmp=Mid(nums,i,1)
If IsNumeric(tmp) Then
tmp=tmp * 16 * (16^(nums_len-i-1))
Else
tmp=(ASC(UCase(tmp))-55) * (16^(nums_len-i))
End If
tmpstr=tmpstr+tmp
Next
chn10=tmpstr
End Function

'10进制转16进制
function chn16(Ints)
dim IntPam, Rmder, RmderStr, a
IntPam = Ints	 '赋被除数
Rmder = IntPam - Fix(IntPam / 16) * 16	 '取余数
RmderStr = CStr(hex(Rmder)) & RmderStr	 '将余数连合
Do While IntPam > 16
IntPam = Fix(IntPam / 16)	 '取次级被除数
Rmder = (IntPam - Fix(IntPam / 16) * 16) '取余数
RmderStr = CStr(hex(Rmder)) & RmderStr	 '将余数连合
loop
chn16 = RmderStr
end Function

'替换指定位置的字符串
function replace_info(str,str_start) 
k=mid(str,1,str_start-1) 
kk=mid(str,str_start+4,len(str)) 
replace_info=k&"0000"&kk 
end function 


'创建随机数
function createssn()
	RANDOMIZE
	createssn = left(INT(now()*(20000000000 * RND)),15)
end Function

'格式化字符串
function ShowHex(data)
    dim l
    dim i 
    dim ch

	If IsNull(data) Then 
	Exit Function 
	End If 
    l=lenB(data)
    for i = 1 to l 
        ch=midB(data,i,1)
        h=trim(hex(ascB(ch)))
        if len(h)=1 then
           h="0"+h
        end if
        ShowHex=ShowHex+h+""
        'if i mod 15 =0 then 
           'response.write "<br>"
        'end if
    Next
  ShowHex=ShowHex
end Function

' 增强版16进制转换
Function Hexnumber(nums)
    On Error Resume Next
    Dim tmp, tmpstr, i, power
    nums = UCase(Trim(nums))
    power = Len(nums) - 1
    tmpstr = 0
    
    For i = 1 To Len(nums)
        tmp = Mid(nums, i, 1)
        If IsNumeric(tmp) Then
            tmpstr = tmpstr + (tmp * (16 ^ power))
        Else
            tmpstr = tmpstr + ((Asc(tmp) - 55) * (16 ^ power))
        End If
        power = power - 1
    Next
    
    Hexnumber = CLng(tmpstr)
    If Err.Number <> 0 Then Hexnumber = 0
End Function

'判断整形
function isChkInteger(para)
       on error resume next
       dim str
       dim l,i
       if isNUll(para) then 
          isChkInteger=false
          exit function
       end if
       str=cstr(para)
       if trim(str)="" then
          isChkInteger=false
          exit function
       end if
       l=len(str)
       for i=1 to l
           if mid(str,i,1)>"9" or mid(str,i,1)<"0" then
              isChkInteger=false 
              exit function
           end if
       next
       isChkInteger=true
       if err.number<>0 then err.clear
end Function

'10进制转16进制
function chn16(Ints)
dim IntPam, Rmder, RmderStr, a
IntPam = Ints	 '赋被除数
Rmder = IntPam - Fix(IntPam / 16) * 16	 '取余数
RmderStr = CStr(hex(Rmder)) & RmderStr	 '将余数连合
Do While IntPam > 16
IntPam = Fix(IntPam / 16)	 '取次级被除数
Rmder = (IntPam - Fix(IntPam / 16) * 16) '取余数
RmderStr = CStr(hex(Rmder)) & RmderStr	 '将余数连合
loop
chn16 = RmderStr
end Function

'URL解密
Function URLDecode(enStr) 
 dim deStr,strSpecial 
 dim c,i,v 
  deStr=""
  strSpecial="!""#$%&'()*+,.-_/:;<=>?@[/]^`{|}~%"
  for i=1 to len(enStr) 
   c=Mid(enStr,i,1) 
   if c="%" then 
    v=eval("&h"+Mid(enStr,i+1,2)) 
    if inStr(strSpecial,chr(v))>0 then 
     deStr=deStr&chr(v) 
     i=i+2 
    else
     v=eval("&h"+ Mid(enStr,i+1,2) + Mid(enStr,i+4,2)) 
     deStr=deStr & chr(v) 
     i=i+5 
    end if
   else
    if c="+" then 
     deStr=deStr&" "
    else
     deStr=deStr&c 
    end if
   end if
  next 
  URLDecode=deStr 
End Function

'角色选择
Function ChkChar()
set rschr=conn_c.execute("select character_no,character_name from user_character where user_no='"&session("user_no")&"'")
response.write "<select name=""Character"">"
if rschr.eof or rschr.bof then
	response.write "<option value="""">您还没有创建任何角色</option>"
  else
	response.write "<option value="""">请选择您的角色</option>"
  Do While not rschr.eof
	  response.write "<option value="""&rschr(0)&""">"&rschr(1)&"</option>"
  rschr.movenext
  loop
end if
response.write "</select>"
End Function

Function PostMail(chr_id,post_title,wIndex,info,include_dil)

	set rsitem=server.CreateObject("adodb.recordset")
	sqlstr="select * from user_postbox "
	rsitem.open sqlstr,conn_c,1,3
	rsitem.AddNew
	rsitem("character_no")=chr_id
	rsitem("post_no")=createssn
	rsitem("from_char_nm")="CNCTZ-DK" 
	rsitem("post_sort")=0 'gm发送为0
	rsitem("post_title")=post_title
	rsitem("body_text")=post_title&"有效时间90天"
	rsitem("state_tag")=0 '0未查看1以查看
	rsitem("item_tag")=1  '1未取出 2已取出
	If include_dil>0 Then '如果发钱
		rsitem("dil_tag")=1
		rsitem("include_dil")=include_dil	'未知
	Else
		rsitem("dil_tag")=0	'未知
		rsitem("include_dil")=0	'未知
	End If
		rsitem("byHeader")=1
		rsitem("wIndex")=wIndex '装备代码
		rsitem("info")=info '亮金属性
	rsitem("dwSerialNumber")="00000000000000000000000000000000" '未知
	rsitem("ipt_time")=Now() '发送时间
	rsitem("expire_time")=Now()+90 '过期日期
	rsitem.update
	rsitem.close
End Function

Function ServerList()
   Response.write "<select id=""server-select"" name=""DKserver"" class=""server-dropdown"">"
   Response.write "<option value=""1"" selected>乱世挑战</option>"
   Response.write "<option value=""2"">赤焰挑战</option>"
   Response.write "<option value=""3"">王者征途</option>"
   Response.write "<option value=""4"">英雄传说</option>"
   Response.write "<option value=""5"">梦幻仙境</option>"
   Response.write "<option value=""6"">龙腾虎跃</option>"
   Response.write "</select>"
End Function


Sub Main()
    ' 检查用户是否已登录
    If Not ChkLogin Then
        ' 如果未登录，则不跳转，直接在当前页面显示提示和登录按钮
%>
        <div class="main-content-container">
            <h3>请先登录</h3>
            <p>您需要登录后才能进行此操作。请点击下方按钮登录您的账号。</p>
            <button class="btn btn-login" id="loginBtn">立即登录</button>
        </div>
<%
        ' 停止执行后续代码，防止未登录用户看到受保护的内容
        Response.End
    End If

    ' --- 以下是已登录用户才能看到的内容，保持不变 ---

    Set rs = conn.Execute("select * from User_Profile where user_id = '"&session("username")&"'")

    If Action2="Gift" then%>
<div class="game-style-container game-style-list">
<h3>请仔细阅读下面的协议。</h3>
  <p>1: 每个账号只允许一个角色领取礼包,角色创建时间越晚奖励越多!<br>
     2 : 对于创建时间过早的角色可能无法领取,此举是为了保护新人的利益.<br>
     3 : 角色创建时间越晚领取的礼包数额越多,具体请参考下表. <br></p>
</div>
<%ElseIf  Action2="Exchange" then%>
<div class="game-style-container game-style-list">
<h3>商城币兑换说明:</h3>
  <p>
    <font color="#ff0000">1 : 本服独家开放免费兑换商城币的功能,无需花一分钱,您就可以购买任何VIP服务.</font><br>
    2 : 本功能旨在保护大部分免费玩家的利益,让游戏更加公平有趣.<br>
    3 : 目前暂时开放玛雅之石,P点,金币的兑换,后期会增加其他道具的兑换.<br>
    4 : 兑换的商城币可以无限制无条件的使用,同时商城币也可无限制多次兑换.<br>
    5 : 兑换之前请将玛雅之石或者金币转移至角色背包,玛雅石至少10颗一组.<br>
  </p>
</div>
<%ElseIf  Action2="Add" then%>
<div class="game-style-container game-style-list">
<h3>我要寄售装备</h3>
<ul class="game-style-list">
    <li><span class="highlight">1 : 本服独家开放免费兑换商城币的功能,无需花一分钱,您就可以购买任何VIP服务.</span></li>
    <li><span class="highlight">2 : 本功能旨在保护大部分免费玩家的利益,让游戏更加公平有趣.</span></li>
    <li><span class="highlight">3 : 目前暂时开放玛雅之石,P点,金币的兑换,后期会增加其他道具的兑换.</span></li>
    <li><span class="highlight">4 : 兑换的商城币可以无限制无条件的使用,同时商城币也可无限制多次兑换.</span></li>
    <li><span class="highlight">5 : 兑换之前请将玛雅之石或者金币转移至角色背包,玛雅石至少10颗一组.</span></li>
</ul>
</div>
<%ElseIf  Action2="Upgrade" then%>
<div class="game-style-container game-style-list">
<h3>我要转生</h3>
  <p>
    <font color="#ff0000">1 : 转生等级需要大于等于<%=Upgrade_Level%>级.</font><br>
    2 : 每次转生需要消费<%=Upgrade_Money%>金币.<br>
    3 : 每次转生赠送<%=Upgrade_AddSkil%>技能点.<br>
    4 : 目前最高开放转生次数为:<%=Max_Upgrade%>转.<br>
    5 : 转生前请将身上的装备全部卸下<br>
  </p>
</div>
<%else%>
<div class="table-container">
<b><%=session("username")%> 您好,欢迎您回来.</b>
</div>
<%End If%>

                <div class="item-detail-container">
                  <div class="item-detail-header"><%=strtitle2%></div>
                  
                  <table class="item-detail-table">
                    <thead>
                      <tr>
                        <th>角色名称</th>
                        <th>职业</th>
                        <th>等级</th>
                        <th>金币</th>
                        <th>转生</th>
                        <th>操作</th>
                      </tr>
                    </thead>
                    <tbody>
<%
Set rs = conn_c.Execute("select * from user_character where user_no='"&session("user_no")&"'")
If rs.EOF Or rs.bof Then
    response.Write "<tr><td colspan='6' style='text-align: center; padding: 20px;'>对不起,您没有创建角色....</td></tr>"
Else
    Do While Not rs.EOF

    character_no=rs("character_no")

    Select Case Action2
    Case"ChangeJob"
        strurl2="<button class=""action-btn exchange-btn"" onclick=""handleActionButton(this, 'User.asp?Action=ChangeJob&Id="&character_no&"', '职业变更')"">改变职业</button>"
Case"Gift"
    strurl2="<button class=""action-btn gift-btn"" onclick=""handleActionButton(this, 'Shop.asp?Id="&character_no&"&Action=Gift', '查看礼包详情')"">查看礼包详情</button>"
     Case "Add"
        strurl2="<button class=""action-btn sell-btn"" onclick=""handleActionButton(this, 'Shop.asp?Id="&character_no&"&Action=AddItem', '进入寄售')"">寄售该角色的道具</button>"
     Case "Exchange"
        strurl2="<button class=""action-btn exchange-btn"" onclick=""handleActionButton(this, 'Shop.asp?Id="&character_no&"&Action=Exchange', '进入兑换')"">兑换商城币</button>"
     Case "Move"
        strurl2="<button class=""action-btn exchange-btn"" onclick=""handleActionButton(this, 'UserCore.asp?Action=Move&Id="&character_no&"', '卡号自救')"">卡号自救</button>"
     Case "Upgrade"
        strurl2="<button class=""action-btn exchange-btn"" onclick=""handleActionButton(this, 'UserCore.asp?Action=UpgradeSave&Id="&character_no&"', '角色转生')"">角色转生</button>"
     Case "ExchangeItem"
        strurl2="<button class=""action-btn exchange-btn"" onclick=""handleActionButton(this, 'Shop.asp?Action=ExchangeItem&Id="&character_no&"', '进入熔炉')"">装备熔炼</button>"
        
        
    Case Else 
        strurl2="<button class=""action-btn exchange-btn"" onclick=""handleActionButton(this, 'UserCore.asp?Action=Move&Id="&character_no&"', '卡号自救')"">卡号自救</button> <button class=""action-btn exchange-btn"" onclick=""handleActionButton(this, 'User.asp?Action=ChangeJob&Id="&character_no&"', '职业变更')"">改变职业</button>"
    End Select

%>
      <tr>
        <td><%=rs("character_name")%></td>
        <td><%=GetClass(rs("bypcClass"))%></td>
        <td><%=rs("wlevel")%></td>
        <td><%=FormatNumber(rs("dwmoney"), 0)%></td>
        <td><%=rs("wMasterLevel")%></td>
        <td><%=strurl2%></td>
      </tr>

           <%
rs.movenext
Loop
End If
rs.Close
Set rs = Nothing
conn.Close
Set conn = Nothing

%>
    </tbody>
  </table>
</div>
<%
End Sub 

%>