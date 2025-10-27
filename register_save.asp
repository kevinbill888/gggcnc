<%
' 先获取表单数据
Dkserver = Trim(Request.Form("Dkserver"))
username = Trim(Request.Form("username"))
email = Trim(Request.Form("email"))
password = Trim(Request.Form("password"))
phone = Trim(Request.Form("phone"))

' 设置大区Session - 必须在包含conn.asp之前
If Dkserver <> "" Then
    Session("DkServer") = CInt(Dkserver)
End If
%>

<!--#include file="inc/conn.asp"-->
<!--#include file="inc/md5.asp"-->
<%
On Error Resume Next
Response.ContentType = "text/plain; charset=UTF-8"

' 早期调试日志（包含在 include 之前），以便捕获 include 导致的错误
Dim fso, logFile
Set fso = Server.CreateObject("Scripting.FileSystemObject")
Set logFile = fso.OpenTextFile(Server.MapPath("register_debug.txt"), 8, True)
logFile.WriteLine Now() & " - 注册请求开始 (pre-include)"
logFile.WriteLine "Dkserver: " & Dkserver & "  username: " & username & "  email: " & email & "  phone: " & phone
logFile.WriteLine "Session DkServer (before include): " & Session("DkServer")
logFile.WriteLine "About to include conn.asp and md5.asp"

' 包含后继续
%>
<!--#include file="inc/conn.asp"-->
<!--#include file="inc/md5.asp"-->
<%
logFile.WriteLine Now() & " - includes done. regname: " & regname & " Session DkServer: " & Session("DkServer")
If Err.Number <> 0 Then
    logFile.WriteLine "错误: include 后 Err.Number=" & Err.Number & " Desc=" & Err.Description
    Response.Write "error:server_include_" & Err.Number & " " & Replace(Err.Description, vbCrLf, " ")
    logFile.Close
    Response.End()
End If

' 如果regname还是不对，强制设置
If Dkserver = "2" And regname <> "2026" Then
    regname = "2026"
    logFile.WriteLine "强制设置regname为2026"
ElseIf Dkserver = "1" And regname <> "2025" Then
    regname = "2025"
    logFile.WriteLine "强制设置regname为2025"
End If

logFile.WriteLine "最终使用的regname: " & regname

' 获取客户端IP
Function getClientIP()
    Dim ip
    ip = Request.ServerVariables("HTTP_X_FORWARDED_FOR")
    If ip = "" Then ip = Request.ServerVariables("REMOTE_ADDR")
    getClientIP = ip
End Function

clientIP = getClientIP()

' 验证函数
Function isValidUsername(str)
    Set reg = New RegExp
    reg.Pattern = "^[a-zA-Z0-9_]{5,16}$"
    isValidUsername = reg.Test(str)
End Function

Function isValidEmail(str)
    Set reg = New RegExp
    reg.Pattern = "^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$"
    isValidEmail = reg.Test(str)
End Function

Function isValidPhone(str)
    Set reg = New RegExp
    reg.Pattern = "^1[3-9]\d{9}$"
    isValidPhone = reg.Test(str)
End Function

' 开始验证
If Dkserver = "" Then
    logFile.WriteLine "错误: 未选择大区"
    Response.Write("error:server")
    Response.End()
End If

If Not isValidUsername(username) Then
    logFile.WriteLine "错误: 用户名无效 - " & username
    Response.Write("error:username")
    Response.End()
End If

If Not isValidEmail(email) Then
    logFile.WriteLine "错误: 邮箱无效 - " & email
    Response.Write("error:email")
    Response.End()
End If

If Len(password) < 6 Or Len(password) > 18 Then
    logFile.WriteLine "错误: 密码长度无效 - " & Len(password)
    Response.Write("error:password")
    Response.End()
End If

If Not isValidPhone(phone) Then
    logFile.WriteLine "错误: 手机号无效 - " & phone
    Response.Write("error:phone")
    Response.End()
End If

' 检查账号是否已存在
On Error Resume Next
sql = "SELECT user_id FROM USER_PROFILE WHERE user_id = '" & Replace(username, "'", "''") & "'"
logFile.WriteLine "查询SQL: " & sql

Set rs = conn.Execute(sql)
If Err.Number <> 0 Then
    logFile.WriteLine "数据库错误(查询用户名): " & Err.Description
    logFile.WriteLine "错误号: " & Err.Number
    Response.Write("error:database_" & Err.Number)
    Response.End()
End If

If Not rs.EOF Then
    logFile.WriteLine "错误: 用户名已存在 - " & username
    Response.Write("error:username_exists")
    Response.End()
End If
rs.Close

' 检查邮箱是否已使用
Set rs = conn.Execute("SELECT user_mail FROM USER_PROFILE WHERE user_mail = '" & Replace(email, "'", "''") & "'")
If Not rs.EOF Then
    logFile.WriteLine "错误: 邮箱已存在 - " & email
    Response.Write("error:email_exists")
    Response.End()
End If
rs.Close

' 检查手机号注册次数（最多5个）
Set rs = conn.Execute("SELECT COUNT(*) as count FROM USER_PROFILE WHERE reg_qq = '" & Replace(phone, "'", "''") & "'")
If rs("count") >= 5 Then
    logFile.WriteLine "错误: 手机号注册次数超限 - " & phone
    Response.Write("error:phone_limit")
    Response.End()
End If
rs.Close

' 生成user_no - 确保14位总长度
Set rsCount = conn.Execute("SELECT COUNT(*) as total FROM USER_PROFILE")
userCount = rsCount("total") + 1
rsCount.Close

' 计算后缀需要的位数（14 - 前缀长度）
prefixLength = Len(regname)
suffixLength = 14 - prefixLength

' 生成后缀部分
suffix = Right(String(suffixLength, "0") & userCount, suffixLength)

' 组合成14位的user_no
user_no = regname & suffix

logFile.WriteLine "前缀长度: " & prefixLength
logFile.WriteLine "后缀长度: " & suffixLength
logFile.WriteLine "用户序号: " & userCount
logFile.WriteLine "生成的后缀: " & suffix
logFile.WriteLine "最终user_no: " & user_no
logFile.WriteLine "user_no长度: " & Len(user_no)

' 插入新用户
sql = "INSERT INTO USER_PROFILE (" & _
       "user_no, user_id, user_pwd, resident_no, password, " & _
       "user_mail, reg_qq, regip, reg_time, login_flag, login_tag" & _
       ") VALUES (" & _
       "'" & user_no & "', " & _
       "'" & Replace(username, "'", "''") & "', " & _
       "'" & md5(password) & "', " & _
       "'801011000000', " & _
       "'" & Replace(password, "'", "''") & "', " & _
       "'" & Replace(email, "'", "''") & "', " & _
       "'" & Replace(phone, "'", "''") & "', " & _
       "'" & clientIP & "', " & _
       "GETDATE(), " & _
       "0, " & _
       "'Y'" & _
       ")"

logFile.WriteLine "插入SQL: " & sql

On Error Resume Next
conn.Execute sql

If Err.Number <> 0 Then
    logFile.WriteLine "数据库错误(插入): " & Err.Description
    logFile.WriteLine "错误号: " & Err.Number
    Response.Write("error:database_" & Err.Number)
    Response.End()
End If

On Error GoTo 0

logFile.WriteLine "注册成功: " & username
logFile.WriteLine "----------------------------------------"
logFile.Close

' 注册成功
Response.Write("success:" & username)

' 全局未处理错误检查（如果存在未处理 Err 则记录并返回）
If Err.Number <> 0 Then
    On Error Resume Next
    logFile.WriteLine Now() & " - 未处理错误: " & Err.Number & " - " & Err.Description
    logFile.WriteLine "Stack/Context: 用户=" & username & " email=" & email & " Dkserver=" & Dkserver
    logFile.WriteLine "----------------------------------------"
    logFile.Close
    Response.Clear
    Response.Write("error:exception_" & Err.Number & " " & Replace(Err.Description, vbCrLf, " "))
    If Not conn Is Nothing Then
        On Error Resume Next
        conn.Close
        Set conn = Nothing
    End If
    Response.End()
End If

conn.Close
Set conn = Nothing
%>
