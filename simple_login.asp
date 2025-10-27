<%@ CODEPAGE="65001"%>

' 引入数据库连接
<%
' 设置服务器选择
If dkserver <> "" Then
    session("DkServer") = dkserver
End If
%>
<!--#include file="inc/conn.asp"-->
<%

Dim username, password, checkcode, dkserver, rs, sql

' 获取表单数据
username = Trim(Request.Form("username"))
password = Trim(Request.Form("password"))
checkcode = Trim(Request.Form("checkcode"))
dkserver = Trim(Request.Form("dkserver"))
Dim returnUrl
returnUrl = Request.Form("Url")

' 基本验证
If username = "" Or Len(username) < 4 Then
    Response.Write "用户名不能少于4个字符"
    Response.End
End If

If password = "" Or Len(password) < 2 Then
    Response.Write "密码不能少于2个字符"
    Response.End
End If

If checkcode = "" Or Len(checkcode) <> 4 Then
    Response.Write "验证码必须为4位"
    Response.End
End If

' 验证码检查
If Session("GetCode") <> checkcode Then
    Response.Write "验证码错误"
    Response.End
End If

' 查询用户
sql = "SELECT user_no, user_id, user_pass FROM USER_PROFILE WHERE user_id = '" & username & "'"
Set rs = conn.Execute(sql)

If rs.EOF Then
    Response.Write "用户名不存在"
    rs.Close
    Set rs = Nothing
    Response.End
End If

' 验证密码
If rs("user_pass") <> password Then
    Response.Write "密码错误"
    rs.Close
    Set rs = Nothing
    Response.End
End If

' 登录成功，设置session
Session("username") = rs("user_id")
Session("user_no") = rs("user_no")

rs.Close
Set rs = Nothing

' 设置服务器选择
If dkserver <> "" Then
    Session("DkServer") = dkserver
End If

Response.Write "<script>alert('登录成功'); window.location.href='" & returnUrl & "';</script>"
Response.End
%>