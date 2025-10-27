<%
Response.ContentType = "text/plain"
Response.CacheControl = "no-cache"

Dim session_key, captcha_value
session_key = Trim(Request.Form("session_key"))
captcha_value = Trim(Request.Form("captcha_value"))

If session_key <> "" And captcha_value <> "" Then
    Session(session_key) = captcha_value
    Response.Write "success"
Else
    Response.Write "error"
End If
%>
