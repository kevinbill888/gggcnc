<!--#include file="inc/conn.asp" -->
<!--#include file="inc/char.asp" -->
<%
Dim ID,NID
ID=CheckStr(Request.QueryString("ID"))

	If not isnumeric(ID) Then 
		Response.write "error"
		Response.end
	End If 

	Sql="Select * FROM News Where ID="&ID
	Set Rs=conn.Execute(Sql)
	ID=Rs("ID")
	title=Rs("title")
	NewsContent=Rs("NewsContent")
	hits=Rs("hits")
	noticle=Rs("noticle")
	news=Rs("news")
	topid=Rs("topid")
	NewsDate=Rs("NewsDate")
	rs.close

%>
<html>
<head>
<meta http-equiv="Content-Type" content="text/html; charset=utf-8" />
<link href="images/news.css" rel="stylesheet" type="text/css" />
<style>
TD {
	FONT-SIZE: 16px; COLOR: #343434; LINE-HEIGHT: 150%
}

</style>

<title><%=title%></title>
</head>
<body>
<table width="98%" border="0" align="center" cellpadding="0" cellspacing="0" class="maintable">
  <tr>
    <td height="38" align="center" style="line-height: 40px;" ><font size="3"><strong><%=title%></strong></font></td>
  </tr>
  <tr>
    <td height="38" align="right">发布日期:<%=NewsDate%> &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;阅读次数:<%=hits*7%>&nbsp;&nbsp;</td>
  </tr>
  <tr>
    <td style="line-height: 30px;">
	<%
	Response.write NewsContent
	set rs=conn.execute("update news set hits=hits+1 where ID="&ID&"") 

Set Rs=Nothing
conn.close
Set conn=Nothing

	%>
</td>
  </tr>
</table>
</body>
</html>