
<!--#include file="inc/conn.asp" -->
<!--#include file="inc/char.asp" -->
<%


Dim post_no, Character, rsPost, rsItem, itemname, sell_char, price, isSelf

post_no = Trim(Request("post_no"))
Character = Trim(Request("Character"))

' 验证参数
If Character = "" Then Response.Write "<script>alert('请选择角色');history.go(-1);</script>": Response.End
If post_no = "" Then Response.Write "<script>alert('寄售ID无效');history.go(-1);</script>": Response.End

' ========== 关键修复：post_no 作为字符串查询！ ==========
Set rsPost = conn_c.Execute("SELECT * FROM USER_POSTBOX WHERE post_no = '" & Replace(post_no, "'", "''") & "'")
If rsPost.EOF Then Response.Write "<script>alert('寄售记录不存在');history.go(-1);</script>": Response.End

sell_char = Trim(rsPost("sell_character_no") & "")
price = CLng(Trim(rsPost("include_dil") & ""))  ' ← include_dil 是数字，可安全转换

' 查询物品名
Set rsItem = conn_i.Execute("SELECT itemname FROM Item WHERE itemid=" & rsPost("Windex"))
itemname = "未知道具"
If Not rsItem.EOF Then itemname = rsItem("itemname")
rsItem.Close

isSelf = (sell_char = Character)

rsPost.Close
%>
<!DOCTYPE html>
<html>
<head>
<meta charset="GB2312">
<title>确认取回</title>
<link rel="stylesheet" href="static/css/sweetalert.css">
<script src="static/js/sweetalert.min.js"></script>
<style>
body { background:#f5f5f5; padding:50px; }
.container { max-width:600px; margin:0 auto; background:white; padding:30px; border-radius:10px; box-shadow:0 2px 10px rgba(0,0,0,0.1); }
.btn { padding:10px 30px; border:none; border-radius:5px; cursor:pointer; }
.confirm { background:#28a745; color:white; }
.cancel { background:#6c757d; color:white; text-decoration:none; display:inline-block; }
</style>
</head>
<body>
<div class="container">
  <h2 style="text-align:center;">确认操作</h2>
  <table style="width:100%; margin:20px 0;">
    <tr><td>角色：</td><td><%=Server.HTMLEncode(Character)%></td></tr>
    <tr><td>装备：</td><td><%=Server.HTMLEncode(itemname)%></td></tr>
    <% If Not isSelf Then %>
    <tr><td>价格：</td><td style="color:red;"><%=price%> 商城币</td></tr>
    <% End If %>
  </table>
  <form method="post" action="ShopCore.asp?Action=RecallSave">
    <input type="hidden" name="post_no" value="<%=Server.HTMLEncode(post_no)%>">
    <input type="hidden" name="Character" value="<%=Server.HTMLEncode(Character)%>">
    <% If isSelf Then %>
    <p style="color:green;">此操作不会扣除商城币。</p>
    <% Else %>
    <p style="color:red;">将从您的账户扣除 <%=price%> 商城币！</p>
    <% End If %>
    <button type="submit" class="btn confirm">确认取回</button>
    <a href="javascript:history.go(-1);" class="btn cancel">取消</a>
  </form>
</div>
</body>
</html>