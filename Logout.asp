<%
Session.Contents.RemoveAll()
Session.Abandon()
Response.Redirect("user.asp")
%>