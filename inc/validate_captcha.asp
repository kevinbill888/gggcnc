<%
Response.ContentType = "text/plain"
Response.CacheControl = "no-cache"

Dim session_key, captcha_value
session_key = Trim(Request.Form("session_key"))
captcha_value = Trim(Request.Form("captcha_value"))

If session_key <> "" And captcha_value <> "" Then
    If CStr(Session(session_key)) = CStr(captcha_value) Then
        Session(session_key) = "" ' 验证成功后清除
        Response.Write "true"
    Else
        Response.Write "false"
    End If
Else
    Response.Write "false"
End If
%>
