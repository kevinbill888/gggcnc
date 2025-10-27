<!--#include file="inc/conn.asp" -->
<%
'防CC设置
If Request.ServerVariables("HTTP_X_FORWARDED_FOR")<>""  then 
response.write "对不起，本站禁止代理IP访问!"
Response.End
end if

if Session("FYCC_Session_1")>8 and minute(now())=Session("FYCC_Session_2") then
response.write "对不起,您的操作过于频繁,请稍后再刷新本页面..."
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
End if

%>

<!--#include file="inc/char.asp" -->
<html>
<head>
<meta http-equiv="Content-Type" content="text/html; charset=gb2312" />
<link href="images/news.css" rel="stylesheet" type="text/css" />
<title>挑战私服之英雄排行榜</title>
</head>
<body>
<table width="558" border="0" align="center" cellpadding="0" cellspacing="0" class="maintable">
  <tr>
    <td height="38" align="center" ><a href="Hero.asp?Action=hero"><b><FONT SIZE="3" >英雄排行榜</FONT></b></a> &nbsp;&nbsp;&nbsp;<b><a href="Hero.asp?Action=hero&amp;Type=pk"><FONT SIZE="3" >PK排行榜</FONT></a></b> &nbsp;&nbsp;&nbsp;<b><a href="Hero.asp?Action=hero&amp;Type=pvp"><FONT SIZE="3" >PVP排行榜</FONT></a></b> &nbsp;&nbsp;<a href="Hero.asp?Action=union"><b><FONT SIZE="3" >战盟排行榜</FONT></b></a> &nbsp;&nbsp;&nbsp;</td>
  </tr>
</table>
<%
set rs=server.createobject("adodb.recordset")
Action = Request("Action")
Select case request("Action")
		case "union"
		call union()
		case "hero"
		call hero()
		case "list"
		call list()
   		case else
		call hero()
End select	
sub Hero()%>
<br />
  <table width="558" height="80" border="0" align="center" cellpadding="4" cellspacing="1" class="maintable">
    <tr >
      <td width="68" height="30" ><p align="center">名次</p></td>
      <td width="300"><p align="center">角色名</p></td>
      <td width="133" ><p align="center">角色类型</p></td>
      <td width="88" ><div align="center"><a href="Hero.asp?Action=hero"><FONT COLOR="#CC0000">等级</FONT></a></div></td>
      <td width="88" ><p align="center"><a href="Hero.asp?Action=hero&amp;Type=pk"><FONT COLOR="#CC0000">PK值</FONT></a></p></td>
      <td width="110" ><p align="center"><a href="Hero.asp?Action=hero&amp;Type=pvp"><FONT COLOR="#CC0000">PVP值</FONT></a></p></td>
    </tr>
    <%
			If request("type")="pk" then 
				sqlstr="  order by wpkcount desc"
			ElseIf request("type")="pvp" then 
				sqlstr="  order by dwpvppoint desc"
			Else 
				sqlstr="  order by wlevel desc"
			End If 
		sql="select top 30 character_name,bypcclass,wlevel,wpkcount,dwpvppoint from user_character where character_name not like '%GM%' "&sqlstr
		rs.open sql,conn_c,1
		i=0
do while not rs.eof       
	i=i+1 
%>
    <tr>
      <td width="68" height="20" align="center"><%=i%></td>
      <td align="center" valign="middle"><b><%=rs("character_name")%></b></td>
      <td align="center"><%=GetClass(rs("bypcClass"))%></td>
      <td align="center"><%=rs("wlevel")%></td>
      <td align="center"><%=rs("wpkcount")%></td>
      <td align="center"><%=rs("dwpvppoint")%></td>
    </tr>
    <%
rs.movenext
loop
%>
  </table>
  <%
				end sub
				sub union()
				%>
  <br />
  <table width="558" height="40" border="0" align="center" cellpadding="4" cellspacing="1"class="maintable">
    <tr >
      <td width="51" height="30" ><div align="center">名次</div></td>
      <td width="200"><div align="center">战盟名称</div></td>
      <td width="200" ><div align="center">盟主</div></td>
      <td width="90" ><div align="center">人数</div></td>
      <td ><div align="center" style="width: 90; height: 19">等级</div></td>
    </tr>
    <%
sql="select top 20 guild_name,guild_code,guild_level,(select count(guild_code) from guild_char_info where guild_code = guild_info.guild_code) As gCount from guild_info order by gCount desc"
rs.open sql,conn_c,1,1

    i = 0
    do while not rs.eof       
         i=i+1 

%>
    <tr>
      <td width="51" height="25" align="center"><%=i%></td>
      <td align="center"><a href="hero.asp?Action=list&amp;guild_code=<%=rs("guild_code")%>"><b><%=rs("guild_name")%></b></a></td>
      <td align="center"><%SET RS2 = Conn_c.Execute("select guild_code,character_name from guild_char_info where guild_code = '"&rs("guild_code")&"' and peerage_code=0")
		  If Not rs2.eof Then   response.write rs2("character_name")
%></td>
      <td align="center"><%=rs("gCount")%></td>
      <td  align="center" width="93"><%=rs("guild_level")%></td>
    </tr>
    <%      
rs.movenext
loop
%>
  </table>
  <br />
  <%
				end sub
				sub list()
				guild_code=checkstr(Request("guild_code"))
				%>
  <br />
  <table width="558" height="40" border="0" align="center" cellpadding="4" cellspacing="1" class="maintable">
    <tr >
      <td width="94" height="30" ><div align="center">名次</div></td>
      <td width="407"><div align="center">队员名称</div></td>
      <td width="407"><div align="center">职位</div></td>
    </tr>
    <%
sql="select * from guild_char_info where guild_code = '"&guild_code&"' order by peerage_code"
rs.open sql,conn_c,1,1

    i = 0
    do while not rs.eof       
         i=i+1 
%>
    <tr>
      <td width="94" height="20" align="center"><%=i%></td>
      <td width="407" align="center"><%=rs("character_name")%></td>
      <td width="407" align="center"><%
SET RS2 = Conn_c.Execute("select guild_code,peerage_code,peerage_name from GUILD_PEERAGE where guild_code = '"&guild_code&"' and peerage_code="&rs("peerage_code")&" order by peerage_code")
 response.write rs2("peerage_name")
If rs2("peerage_code")=0 Then response.write "&nbsp;(盟主)"

rs2.close
			  %></td>
    </tr>
    <%      
rs.movenext
loop
%>
  </table>
<%
                end sub
				rs.close
				set rs=nothing
				conn.close
				set conn=nothing
				%>
</body>
</html>