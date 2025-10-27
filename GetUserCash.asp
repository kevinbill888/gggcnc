<!--#include file="inc/conn.asp" -->
<!--#include file="inc/char.asp" -->
<%
Response.ContentType = "text/plain"
Response.AddHeader "Cache-Control", "no-cache"


' 清除任何可能的HTML输出
Response.Clear

' 检查用户登录状态
If Not ChkLogin Then
    Response.Write "0"
    Response.End
End If

' 获取用户商城币余额
On Error Resume Next

Dim userAmount
userAmount = 0

' 使用conn_b连接cash数据库
SET RScash = conn_b.Execute("SELECT amount FROM user_cash WHERE user_no='" & session("user_no") & "'")

If Err.Number <> 0 Then
    ' 数据库错误
    userAmount = 0
ElseIf RScash.eof Or RScash.bof Then
    ' 没有找到记录
    userAmount = 0
Else
    ' 获取余额
    userAmount = RScash("amount")
    If IsNull(userAmount) Then
        userAmount = 0
    End If
End If

' 清理资源
If Not RScash Is Nothing Then
    RScash.Close
    Set RScash = Nothing
End If

On Error Goto 0

' 输出纯数字
Response.Write userAmount
Response.End
%>