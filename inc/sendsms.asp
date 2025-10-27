<%@ CODEPAGE="65001"%>
<%

function PostHTTPPage(url,data) 
dim Http 
set Http=server.createobject("MSXML2.XMLHTTP")
Http.open "POST",url,false 
Http.setRequestHeader "CONTENT-TYPE", "application/x-www-form-urlencoded" 
Http.send(data) 
if Http.readystate<>4 then 
exit function 
End if
PostHTTPPage=bytesToBSTR(Http.responseBody,"UTF-8") 
set http=nothing 
if err.number<>0 then err.Clear 
End function


function BytesToBstr(body,Cset) 
dim objstream 
set objstream = Server.CreateObject("adodb.stream")
objstream.Type = 1 
objstream.Mode =3 
objstream.Open 
objstream.Write body 
objstream.Position = 0 
objstream.Type = 2 
objstream.Charset = Cset 
BytesToBstr = objstream.ReadText 
objstream.Close 
set objstream = nothing 
End function

If Request.ServerVariables("HTTP_X_FORWARDED_FOR")<>""  then 
	Response.Write "{""code"":2,""msg"":""对不起，本站禁止代理IP访问!!"",""result"":null}"
	Response.end
end if

if Session("FYCC_Session_1")>8 and minute(now())=Session("FYCC_Session_2") then

	Response.Write "{""code"":2,""msg"":""对不起,您的操作过于频繁,请稍后再试.."",""result"":null}"
		Session("FYCC_Session_1")=Session("FYCC_Session_1")+1
	response.end
else
	if Session("FYCC_Session_1")="" then
		Session("FYCC_Session_1")=1
		Session("FYCC_Session_2")=minute(now())
	else
		if minute(now())<>Session("FYCC_Session_2") then
			Session("FYCC_Session_1")=1
			Session("FYCC_Session_2")=minute(now())
		else
			Session("FYCC_Session_1")=Session("FYCC_Session_1")+1
		end if
	end if
End If

mobile=request("mobile")
imgcode=request("imgcode")
id="1672302200" '请输入你的KEY
apikey="bRR6VuYHW1SwkAsqJZXxAVDyPDP9b94l" '请输入你的KEY
signid="4888285400"'已通过审核的签名ID
templateid="MEN3GZZULQT2VJVUCCNE"'已通过审核的模板ID

	
'Response.Write "{""code"":2,""msg"":"""&imgcode&"&"&mobile&""",""result"":null}"

If imgcode=Empty Or Trim(Session("getCode"))<>imgcode Then
	'Response.Write "{""code"":2,""msg"":""非法提交!"",""result"":null}"
	'Response.end
end If

if not isnumeric(mobile) or len(mobile)<>11 Then
	Response.Write "{""code"":2,""msg"":""手机号码错误!"",""result"":null}"
	Response.end
end If

if left(mobile,2)<13 Or left(mobile,2)>19  Then
	Response.Write "{""code"":2,""msg"":""手机号码错误!!"",""result"":null}"
	Response.end
end If

if right(mobile,6)="111111" Or  right(mobile,6)="222222" Or  right(mobile,6)="333333" Or  right(mobile,6)="444444" Or  right(mobile,6)="555555" Or  right(mobile,6)="666666" Or  right(mobile,6)="777777" Or  right(mobile,6)="888888"  Or  right(mobile,6)="999999" Or  right(mobile,6)="000000" Or  right(mobile,6)="123456" Or  right(mobile,6)="234567" Or  right(mobile,6)="345678" Or  right(mobile,6)="456789" Or  right(mobile,6)="567890" Then
	Response.Write "{""code"":2,""msg"":""手机号码错误!!!"",""result"":null}"
	Response.end
end If

RANDOMIZE
smscode = left(INT(now()*(20000000000 * RND)),4)
session("smscode")=smscode




data="id="&id&"&key="&apikey&"&mobile="&mobile&"&signid="&signid&"&templateid="&templateid&"&templateparamset="&smscode&""
	'Response.Write data
	'Response.end


json=trim(PostHTTPPage("https://www.weisms.com/api/send",data))


	Response.Write json
	Response.end
%>