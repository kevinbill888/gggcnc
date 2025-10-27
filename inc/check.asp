<!--#include file="conn.asp" -->
<!--#include file="char.asp" -->
<%
param=checkstr(trim(Request("param"))) '值
name=checkstr(trim(Request("name")))'表单名称
'Response.write param
'response.End
If name="user" Then '判断用户名
		If IsNull(param) Then
			response.write "{""info"":""错误:用户名不能为空."",""status"":""n""}"
			response.End
		End If 
		set rs=conn.execute("select user_id from user_profile where user_id = '"&param&"'")
		if not (rs.EOF and rs.bof) then
			response.write "{""info"":""错误:该用户名已经被注册."",""status"":""n""}"
		Else
			response.write "{""info"":""该用户名可以注册."",""status"":""y""}"
		End If
			rs.close
		set rs=Nothing
ElseIf name="telcode" Then '判断手机验证码
		If param=Empty Or Trim(Session("smscode"))<>param Then
			response.write "{""info"":""短信验证码不正确."",""status"":""n""}"

		else
			response.write "{""info"":""短信验证码正确."",""status"":""y""}"
		end If

Else
		If param=Empty Or Trim(Session("getCode"))<>param Then
			response.write "{""info"":""验证码不正确."",""status"":""n""}"

		else
			response.write "{""info"":""验证码正确."",""status"":""y""}"
		end If
End If 

%>