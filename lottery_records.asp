<!--#include file="inc/conn.asp"-->
<%
user = Request.QueryString("user")
sql = "SELECT TOP 10 * FROM Lottery_Log WHERE user_id = '" & user & "' ORDER BY lottery_time DESC"
Set rs = conn.Execute(sql)

If rs.EOF Then
    Response.Write "<div class='no-records'>暂无中奖记录</div>"
Else
    Do While Not rs.EOF
%>
        <div class="record-item">
            <div class="record-prize">
                <i class="fas fa-trophy"></i>
                <%=rs("prize_name")%>
            </div>
            <div class="record-time">
                <%=FormatDateTime(rs("lottery_time"), 2)%> <%=FormatDateTime(rs("lottery_time"), 4)%>
            </div>
        </div>
<%
        rs.MoveNext
    Loop
End If

rs.Close
conn.Close
%>
