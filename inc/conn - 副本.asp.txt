<%@ CODEPAGE="65001"%>
<!--#include file="blacklist.asp" -->

<%
TimerStart=Timer()

admin_character="E24080630000000032"'仓库管理员角色ID
function log_result(sWord)
	set fs= createobject("scripting.filesystemobject")
	set ts=fs.Opentextfile(server.MapPath("sqllog.txt"),8,true,-1)
	ts.writeline(sWord)
	ts.close
	set ts=Nothing
	set fs=Nothing
end Function

function GetDateTime()
	sTime=now()
	sResult	= year(sTime)&right("0" & month(sTime),2)&right("0" & day(sTime),2)&right("0" & hour(sTime),2)&right("0" & minute(sTime),2)&right("0" & second(sTime),2)
	GetDateTime = sResult
end Function


Function StopInjection(values)
	For Each A_Get In values
	   'response.write "A_Get="&A_Get
		For A_Xh=0 To Ubound(A_Str)
			If Instr(LCase(values(A_Get)),A_Str(A_Xh))<>0 Then
		        log_result(Now()&"-"&Request.ServerVariables("REMOTE_ADDR")&"-"&Request.ServerVariables("URL")&"-"&values)
				'Response.write values(A_Get)
				Response.write"系统错误,请联系管理员"
				Response.End
			End If
	   Next
	Next
End Function 

Dim A_Get,Bad_Str,A_Str,A_Xh
Bad_Str = "'|;|and|(|)|exec|insert|select|delete|count|*|chr|mid|master|truncate|char|declare"
A_Str = split(Bad_Str,"|")
If Request.Form<>"" Then StopInjection(Request.Form)
If Request.QueryString<>"" Then StopInjection(Request.QueryString)
If Request.Cookies<>"" Then StopInjection(Request.Cookies)


dim connstr,conn,connstrs,DBName,DBName1,DBName2,DBName3,SQL_Server,SQL_UserName,SQL_PassWord,startime,endtime,DkServer
'On Error Resume next
itemdb="I:\web\new\inc\item.mdb"

startime=timer()
Select Case request("Dkserver")
Case 2 
session("DkServer")=2
Case 1
session("DkServer")=1
End Select 

Select Case session("DkServer")
Case 2 
%>
<!--#include file="server_2.asp" -->
<%
Case Else
%>
<!--#include file="server_1.asp" -->
<%
End Select  'account
connstr="driver={SQL Server};Server="&SQL_Server&";UID="&SQL_UserName&";PWD="&SQL_PassWord&";database="&DBName
Set conn = Server.CreateObject("ADODB.Connection")
conn.Open connstr

if not isobject(conn_b) Then 'cash
connstr_b="driver={SQL Server};Server="&SQL_Server&";UID="&SQL_UserName&";PWD="&SQL_PassWord&";database="&DBName_b
Set conn_b = Server.CreateObject("ADODB.Connection")
conn_b.Open connstr_b
end If

if not isobject(conn_c) Then 'character
connstr_c="driver={SQL Server};Server="&SQL_Server&";UID="&SQL_UserName&";PWD="&SQL_PassWord&";database="&DBName_c
Set conn_c = Server.CreateObject("ADODB.Connection")
conn_c.Open connstr_c
end If

if not isobject(conn_i) then
connstr_i="Provider=Microsoft.Jet.OLEDB.4.0;Data Source=" & (""&itemdb&"")
Set conn_i= Server.CreateObject("ADODB.Connection")
conn_i.Open connstr_i
end If

If Err Then
	err.Clear
	Set conn = Nothing
	Response.Write "数据库连接出错，请联系管理员。"
	Response.End
End If

%>