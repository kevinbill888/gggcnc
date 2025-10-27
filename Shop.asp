<!--#include file="inc/conn.asp" -->
<!--#include file="head.asp" -->
<!--#include file="inc/char.asp" -->
<!--#include file="inc/pageClass.asp"-->
<%
Response.AddHeader "X-Content-Type-Options", "nosniff"
%>

<%
' ====== 公告板真实数据缓存（5分钟刷新一次）======

' 最近购买（来自 account..web_market，status=1），缓存到 Application("BoardBuys")
If IsEmpty(Application("BoardBuysTS")) Or DateDiff("n", Application("BoardBuysTS"), Now()) >= 5 Then
On Error Resume Next
Dim rsB, sB, listB, nmB, itB
sB = "[]": listB = ""
Set rsB = conn.Execute("SELECT TOP 50 m.buy_name, m.Windex, wi.item_name " & _
"FROM web_market m WITH (NOLOCK) " & _
"LEFT JOIN web_items wi ON wi.windex=m.Windex " & _
"WHERE ISNULL(m.[status],1)=1 " & _
"ORDER BY m.[time] DESC")
If Err.Number=0 And Not rsB Is Nothing Then
Do While Not rsB.EOF
nmB = Replace(Trim("" & rsB("buy_name")), """", """""")
itB = Replace(Trim("" & rsB("item_name")), """", """""")
If listB <> "" Then listB = listB & ","
listB = listB & "{""name"":""" & nmB & """,""item"":""" & itB & """}"
rsB.MoveNext
Loop
sB = "[" & listB & "]"
rsB.Close : Set rsB = Nothing
Else
Err.Clear
End If
Application.Lock
Application("BoardBuys") = sB
Application("BoardBuysTS")= Now()
Application.UnLock
On Error GoTo 0
End If

' 最近发布（来自 character..USER_POSTBOX，市场归属 admin_character），缓存到 Application("BoardPosts")
If IsEmpty(Application("BoardPostsTS")) Or DateDiff("n", Application("BoardPostsTS"), Now()) >= 5 Then
On Error Resume Next
Dim rsP, sP, listP, nmP, itP, rsNm, sellerNo
sP = "[]": listP = ""
Set rsP = conn_c.Execute("SELECT TOP 50 p.sell_character_no, p.Windex, p.ipt_time " & _
"FROM USER_POSTBOX p WITH (NOLOCK) " & _
"WHERE p.character_no='" & Replace(admin_character,"'","''") & "' " & _
"ORDER BY p.ipt_time DESC")
If Err.Number=0 And Not rsP Is Nothing Then
Do While Not rsP.EOF
sellerNo = Trim("" & rsP("sell_character_no"))
' 角色名
nmP = ""
Set rsNm = conn_c.Execute("SELECT TOP 1 character_name FROM user_character WHERE character_no='" & Replace(sellerNo,"'","''") & "'")
If Not rsNm.EOF Then nmP = rsNm(0)
rsNm.Close : Set rsNm = Nothing
' 物品名（到 account..web_items 取）
itP = ""
Dim rsWI: Set rsWI = conn.Execute("SELECT TOP 1 item_name FROM web_items WHERE windex=" & CLng(0 & rsP("Windex")))
If Not rsWI.EOF Then itP = rsWI(0)
rsWI.Close : Set rsWI = Nothing


  If listP <> "" Then listP = listP & ","
  listP = listP & "{""name"":""" & Replace(nmP, """", """""") & """,""item"":""" & Replace(itP, """", """""") & """}"
  rsP.MoveNext
Loop
sP = "[" & listP & "]"
rsP.Close : Set rsP = Nothing
Else
Err.Clear
End If
Application.Lock
Application("BoardPosts") = sP
Application("BoardPostsTS") = Now()
Application.UnLock
On Error GoTo 0
End If
%>

<script>
 // 注入给前端 
 window.__BOARD_BUYS = <%=Application("BoardBuys")%> || []; 
 window.__BOARD_POSTS = <%=Application("BoardPosts")%> || []; 
 </script>


<%
' ====== 公告板玩家名缓存（每小时刷新一次）======
If IsEmpty(Application("BoardPlayersTS")) Then Application("BoardPlayersTS") = CDate("1900-01-01")
If DateDiff("n", Application("BoardPlayersTS"), Now()) >= 60 Then
On Error Resume Next
Dim rsBP, sJSON, nm
sJSON = ""
Set rsBP = conn_c.Execute("SELECT TOP 500 character_name FROM user_character WITH (NOLOCK) WHERE LEN(LTRIM(RTRIM(character_name)))>0 ORDER BY NEWID()")
If Err.Number = 0 And Not rsBP Is Nothing Then
Do While Not rsBP.EOF
nm = Replace(Trim("" & rsBP("character_name")), """", """""")
If sJSON <> "" Then sJSON = sJSON & ","
sJSON = sJSON & """" & nm & """"
rsBP.MoveNext
Loop
rsBP.Close : Set rsBP = Nothing
Else
Err.Clear
End If
Application.Lock
Application("BoardPlayers") = "[" & sJSON & "]"
Application("BoardPlayersTS") = Now()
Application.UnLock
On Error GoTo 0
End If
%>

<script> // 供前端使用的玩家名数组（来自服务器缓存） 
window.__BOARD_PLAYERS = <%=Application("BoardPlayers")%> || []; 
</script>


<%
Action = Request("Action")
Action2 = Request("Action2")
pageLink=lcase(Request.ServerVariables("QUERY_STRING"))

Function MaskRoleName(s)
    Dim t, n, mask
    t = Trim("" & s)
    If t = "" Then
        MaskRoleName = "未知"
        Exit Function
    End If

    n = Len(t)
    If n = 1 Then
        MaskRoleName = t
    ElseIf n = 2 Then
        MaskRoleName = Left(t, 1) & "*"  ' 两个字符时，显示第一个字符+星号
    Else
        mask = String(n - 2, "*")  ' 用星号填充中间部分
        MaskRoleName = Left(t, 1) & mask & Right(t, 1)
    End If
End Function


Function GetItemNameByWindex(widx)
Dim rsN, nm
nm = "未知"
On Error Resume Next
If IsNumeric(widx) Then
Set rsN = conn.Execute("SELECT TOP 1 item_name FROM web_items WHERE windex=" & CLng(widx))
If Err.Number = 0 And Not rsN Is Nothing Then
If Not rsN.EOF Then nm = rsN(0)
Else
Err.Clear
End If
If Not rsN Is Nothing Then rsN.Close : Set rsN = Nothing
End If
On Error GoTo 0
GetItemNameByWindex = nm
End Function

Select Case Action2
	Case"Gift"
		strtitle2="领取礼包"
     Case "Exchange"
		strtitle2="商城币兑换"
	Case "Add"
		strtitle2="寄售道具"
	Case "ExchangeItem"
		strtitle2="道具兑换"
	Case Else 
		strtitle2="角色详情"
End Select

Select Case Action
    Case "UserLogin"
	Case "ShopList" 
		strtitle="选择装备"
		Case "View_Item" 
		strtitle="查看道具属性"
     Case "Gift"
		strtitle="领取礼包"
     Case "Exchange"
		strtitle="兑换商城币"
     Case "ExchangeItem"
		strtitle="道具兑换"
    Case "Shop" 
		strtitle="出售道具"
 Case "AddItem" 
		strtitle="寄售道具"
 Case "SaveItem" 
		strtitle="寄售道具"
 Case "Pay" 
		strtitle="用户充值"
 Case "OrderList" 
		strtitle="充值订单管理"
    Case Else '注册
		If Action2="" Then 
			strtitle="查看道具"
		Else
			strtitle="选择职业"
		End  If 
End Select

%>
        <!-- END: Navbar Mobile -->
        <div class="nk-main">
            <!-- START: Breadcrumbs -->
            <div class="nk-gap-1"></div>
            <div class="container">
                <ul class="nk-breadcrumbs">
                    <li><span style="letter-spacing: 6px;">首页-在线商城-<%=strtitle%></span></li>
                </ul>
            </div>
            <div class="nk-gap-1"></div>
            <!-- END: Breadcrumbs -->
            <div class="container">
              
                <div class="nk-gap-2"></div>
                <div class="row vertical-gap">
                    <div class="col-lg-8 main-content-container">
		                 <!-- START: Products -->
                        <div class="row vertical-gap">
					<%
Select Case Action2
	Case"Gift"
		strtitle2="领取礼包"
     Case "Exchange"
		strtitle2="商城币兑换"
	Case "Add"
		strtitle2="寄售道具"
	Case "ExchangeItem"
		strtitle2="道具兑换"
	Case Else 
		strtitle2="角色详情"
End Select

Select Case Action
    Case "UserLogin"
        ' 【修改】当访问旧的登录链接时，不再跳转，直接在当前页面显示登录按钮
        strtitle = "用户登录"
%>
        <div class="user-level login-modal-header login-btn">
            <h3>请先登录</h3>
            <p>您需要登录后才能进行此操作,请点击下方按钮登录您的账号。</p>
            <button class="btn btn-login" id="loginBtn">立即登录</button>
        </div>
<%
        Response.End ' 停止执行后续代码
	Case "ShopList" '选择属性
        ShopList()
		strtitle="选择装备"
		Case "View_Item" '查看寄售道具
        View_Item()
		strtitle="查看道具属性"
     Case "Gift"
		Gift()
		strtitle="领取礼包"
     Case "Exchange"
		Exchange()
		strtitle="兑换商城币"
     Case "ExchangeItem"
		ExchangeItem()
		strtitle="道具兑换"
    Case "Shop" 
        Shop()
		strtitle="出售道具"
 Case "AddItem" 
        AddItem()
		strtitle="寄售道具"
 Case "SaveItem" 
        SaveItem()
		strtitle="1,寄售道具"
 Case "Pay" 
		Pay()
		strtitle="用户充值"
Case "UserCenter" ' 新增的个人中心
        UserCenter()
        strtitle="个人中心"
 Case "OrderList" 
		OrderList()
		strtitle="充值订单管理"		
    Case Else '注册
		If Action2="" Then 
			Shop()
			strtitle="1,查看道具"
		Else
			Main()
			strtitle="选择职业"
		End  If 
End Select



'-----------------------------------寄售市场-----------------------------------
Sub Shop()
Dim Action3, isMy
Action3 = Request("Action3")
isMy = (LCase(Trim(Action3 & "")) = "my")

Dim topstr, topstr2, sql, sqlstr, i
topstr = "" : topstr2 = "" : sql = "" : sqlstr = "" : i = 0

If Action3 <> "" Then
topstr = "查看我的道具"
topstr2 = "点击修改道具"



    If Not ChkLogin Then
        ' 【修改开始】如果未登录，不再跳转，直接在当前页面显示登录按钮
%>
        <div class="user-level login-modal-header login-btn">
            <h3>请先登录</h3>
            <p>您需要登录后才能进行操作,请点击下方按钮登录您的账号。</p>
            <button class="btn btn-login" id="loginBtn">立即登录</button>
        </div>
<%
        ' 停止执行后续代码，防止未登录用户看到职业选择表单
        Response.End
    End If

    ' 【修改结束】以下是已登录用户才能看到的内容，保持不变


If Not ChkOnLine Then
  Response.Write "<script>swal({title:'错误!',text:'系统检测到您当前的游戏状态为在线,请退出游戏后重新进行此操作!',type:'error'}, function(){history.go(-1);});</script>"
  Response.End
End If

Dim rsChar
Set rsChar = conn_c.Execute("select top 1 Character_no from User_Character where user_no='" & session("user_no") & "'")
If rsChar.EOF Then
  Response.Write "您还没有创建角色.."
  Response.End
Else
  Do While Not rsChar.EOF
    i = i + 1
    If i = 1 Then
      sqlstr = " sell_character_no='" & rsChar(0) & "'"
    Else
      sqlstr = sqlstr & " and sell_character_no='" & rsChar(0) & "'"
    End If
    rsChar.MoveNext
  Loop
End If
rsChar.Close : Set rsChar = Nothing

sql = "select p.*, c.character_name from USER_POSTBOX p left join USER_CHARACTER c on p.sell_character_no=c.character_no where " & sqlstr & " order by p.post_no"
Else
topstr = "查看全部道具"
topstr2 = "点击查看详情"
sql = "select p.*, c.character_name from USER_POSTBOX p left join USER_CHARACTER c on p.sell_character_no=c.character_no where p.character_no='" & admin_character & "' order by p.post_no"
End If

' 列表
Dim rsList
Set rsList = Server.CreateObject("ADODB.Recordset")
rsList.Open sql, conn_c, 1, 1

' 分页
Dim currentPage, pageSize, totalRecords, totalPages, startRecord
pageSize = 9
currentPage = CLng("0" & Request.QueryString("p"))
If currentPage < 1 Then currentPage = 1

If Not rsList.EOF Then
rsList.MoveLast
totalRecords = rsList.RecordCount
rsList.MoveFirst
Else
totalRecords = 0
End If

totalPages = Int((totalRecords + pageSize - 1) / pageSize)
If totalPages > 0 And currentPage > totalPages Then currentPage = totalPages
startRecord = (currentPage - 1) * pageSize

Dim userHello
userHello = session("username")
If IsNull(userHello) Then userHello = ""
Response.Write "<div class='table-container'><b>" & Server.HTMLEncode(userHello) & " 您好,欢迎您回来.</b></div>"

If rsList.EOF Then
Response.Write "<div class='no-records'>没有找到任何记录...</div>"
Else
If startRecord > 0 Then rsList.Move startRecord
Response.Write "<div class='equipment-grid'>"


Dim recordCount : recordCount = 0
Do While Not rsList.EOF And recordCount < pageSize
  Dim itemname, byHeaderVal, hexInfo, sHex
  Dim qtyText, sellerName, postTimeText, priceText
  Dim tooltipRaw, iconName

  ' 物品名
  On Error Resume Next
  itemname = GetItemNameByWindex(rsList("Windex"))

  ' byHeader / info
  byHeaderVal = 0
  If Not IsNull(rsList("byHeader")) And rsList("byHeader") <> "" Then
    On Error Resume Next
    byHeaderVal = CLng(rsList("byHeader"))
    If Err.Number <> 0 Then byHeaderVal = 0 : Err.Clear
    On Error GoTo 0
  End If
  hexInfo  = ShowHex(rsList("info"))
  sHex = UCase(Trim("" & hexInfo)) : If Left(sHex,2)="0X" Then sHex = Mid(sHex,3)

  ' 数量
  qtyText = "1"
  If byHeaderVal = 1 Then
    If isChkInteger(Hexnumber(sHex)) Then
      qtyText = Left(Hexnumber(sHex), 5)
    Else
      qtyText = "1"
    End If
  End If

  ' 解析属性/镶嵌
  Dim attrCount, socketCount, isStack, b
  attrCount = 0 : socketCount=0
  b = byHeaderVal
  If IsNumeric(b) Then
    If b>15 Then
      socketCount = Int(b/16)
      Dim r: r = b Mod 16
      If r>=5 And r<=8 Then attrCount = r-4
    Else
      If b>=5 And b<=8 Then attrCount=b-4
    End If
    If attrCount<0 Then attrCount=0
    If attrCount>4 Then attrCount=4
    If socketCount<0 Then socketCount=0
    If socketCount>4 Then socketCount=4
  End If

  ' 组装 raw 文本
  tooltipRaw = "数量: " & qtyText & vbCrLf & "属性" & vbCrLf

  ' 属性（右边起，每条6位）
  If attrCount>0 Then
    Dim length, startPos, optIdxHex, optValHex, optIdx, optVal, rsOpt, desc, minData, maxData, delta, value
    length = Len(sHex)
    startPos = length - (attrCount*6) + 1
    For i=0 To attrCount-1
      optIdxHex = Mid(sHex, startPos + i*6, 4)
      optValHex = Mid(sHex, startPos + i*6 + 4, 2)
      optIdx = Hexnumber(optIdxHex)
      optVal = Hexnumber(optValHex)
      If IsNumeric(optIdx) Then
        On Error Resume Next
        Set rsOpt = conn.Execute("SELECT TOP 1 Description,minData,MaxData FROM web_itemoption WHERE OptionIndex=" & CLng(optIdx))
        If Err.Number=0 And Not rsOpt Is Nothing Then
          If Not rsOpt.EOF Then
            desc = Trim("" & rsOpt("Description"))
            minData = CLng(rsOpt("minData"))
            maxData = CLng(rsOpt("MaxData"))
            delta = (maxData - minData) / 100
            value = CLng(minData + Fix(delta * CLng(optVal)))
            tooltipRaw = tooltipRaw & desc & " " & value & vbCrLf
          End If
          rsOpt.Close : Set rsOpt = Nothing
        Else
          Err.Clear
        End If
        On Error GoTo 0
      End If
    Next
  Else
    tooltipRaw = tooltipRaw & "属性: 无" & vbCrLf
  End If

  tooltipRaw = tooltipRaw & "----" & vbCrLf & "镶嵌" & vbCrLf

  ' 镶嵌（左边起，每孔4位）
  If socketCount>0 Then
    Dim j, holeHex, holeId, rsSock, sName, sVal
    For j=0 To socketCount-1
      holeHex = Mid(sHex, 1 + j*4, 4)
      holeId = Hexnumber(holeHex)
      If IsNumeric(holeId) And CLng(holeId)<>0 Then
        On Error Resume Next
        Set rsSock = conn.Execute("SELECT TOP 1 name,value FROM web_itemetc_socket WHERE id=" & CLng(holeId))
        If Err.Number=0 And Not rsSock Is Nothing Then
          If Not rsSock.EOF Then
            sName = Trim("" & rsSock("name"))
            sVal  = Trim("" & rsSock("value"))
            tooltipRaw = tooltipRaw & sName & " " & sVal & vbCrLf
          End If
          rsSock.Close : Set rsSock = Nothing
        Else
          Err.Clear
        End If
        On Error GoTo 0
      End If
    Next
  Else
    tooltipRaw = tooltipRaw & "镶嵌: 无镶嵌" & vbCrLf
  End If

  Dim tooltipAttr : tooltipAttr = Server.HTMLEncode(tooltipRaw)

  ' 卖家/时间/价格
  If IsNull(rsList("character_name")) Or rsList("character_name")="" Then sellerName="未知" Else sellerName=Server.HTMLEncode(rsList("character_name"))
  If IsNull(rsList("ipt_time")) Then postTimeText="未知时间" Else If IsDate(rsList("ipt_time")) Then postTimeText=FormatDateTime(rsList("ipt_time"),2) Else postTimeText="未知时间"
  If IsNull(rsList("include_dil")) Or rsList("include_dil")="" Then priceText="0" Else priceText=FormatNumber(rsList("include_dil"),0)

  Dim wFirst : wFirst=Left(CStr(rsList("Windex")),1)
  iconName = "其他类.png"
	' 修改后（正确写法）
If wFirst = "0" Or wFirst = "1" Or wFirst = "2" Or wFirst = "3" Or wFirst = "4" Or wFirst = "5" Then
    iconName = "武器类.png"
ElseIf wFirst = "6" Or wFirst = "7" Or wFirst = "8" Or wFirst = "9" Then
    iconName = "防具类.png"
End If
  Response.Write "<div class=""item-card"" data-itemname=""" & Server.HTMLEncode(itemname) & """ data-rawattrs=""" & tooltipAttr & """ onclick=""window.location.href='Shop.asp?Action=View_Item&post_no=" & rsList("post_no") & "&Action4=Edit'"">"
  Response.Write "  <div class=""item-header"">"
  Response.Write "    <img src=""static/image/分类图片/" & iconName & """ alt=""装备图标"" class=""item-icon"" />"
  Response.Write "    <h3 class=""equip-title"">" & Server.HTMLEncode(itemname) & "</h3>"
  Response.Write "  </div>"
  Response.Write "  <div class=""item-details"">"
  Response.Write "    <div class=""item-detail""><strong>数量:</strong> " & Server.HTMLEncode(qtyText) & "</div>"
  Response.Write "    <div class=""item-detail""><strong>卖家:</strong> " & sellerName & "</div>"
  Response.Write "    <div class=""item-detail""><strong>发布:</strong> " & postTimeText & "</div>"
  Response.Write "  </div>"
  Response.Write "  <div class=""item-price"">价格: " & priceText & " 金币</div>"
  Response.Write "  <div class=""item-action""><a href=""Shop.asp?Action=View_Item&post_no=" & rsList("post_no") & "&Action4=Edit"" class=""item-btn"">" & topstr2 & "</a></div>"
  Response.Write "</div>"

  rsList.MoveNext
  recordCount = recordCount + 1
Loop

Response.Write "</div>"
End If

rsList.Close : Set rsList = Nothing

' 分页（保留你的原逻辑）
Response.Write "<div class=""nk-pagination nk-pagination-center""><nav>"
If totalPages > 1 Then
Response.Write "<div class='pagination-nav'>"
If currentPage > 1 Then
Response.Write "<a href='?" & Replace(Request.QueryString(), "p=" & currentPage, "p=" & (currentPage - 1)) & "' class='page-btn'>上一页</a> "
End If


Dim i2, startPage2, endPage2, newQuery
startPage2 = currentPage - 2
endPage2   = currentPage + 2
If startPage2 < 1 Then startPage2 = 1
If endPage2 > totalPages Then endPage2 = totalPages

For i2 = startPage2 To endPage2
  If i2 = currentPage Then
    Response.Write "<span class='page-current'>" & i2 & "</span> "
  Else
    newQuery = Request.QueryString()
    If InStr(newQuery, "p=") > 0 Then
      newQuery = Replace(newQuery, "p=" & currentPage, "p=" & i2)
    Else
      If newQuery <> "" Then newQuery = newQuery & "&"
      newQuery = newQuery & "p=" & i2
    End If
    Response.Write "<a href='?" & newQuery & "' class='page-btn'>" & i2 & "</a> "
  End If
Next

If currentPage < totalPages Then
  Response.Write "<a href='?" & Replace(Request.QueryString(), "p=" & currentPage, "p=" & (currentPage + 1)) & "' class='page-btn'>下一页</a>"
End If

Response.Write "<span class='pagination-info'>第 " & currentPage & " 页，共 " & totalPages & " 页，共 " & totalRecords & " 条记录</span>"
Response.Write "</div>"
End If
Response.Write "</nav></div>"

' 交易记录（合并一张表、物品名来自 web_item）
If isMy Then
Dim rsTrade, sqlTrade, u
u = Replace(session("user_no"),"'", "''")


sqlTrade  = "SELECT TOP 100 t.rec_type, t.other_name, t.[time], t.Money, t.Windex, ISNULL(wi.item_name,'') AS item_name "
sqlTrade  = sqlTrade & "FROM ( "
sqlTrade  = sqlTrade & "  SELECT '出售' AS rec_type, ISNULL(buy_name,'') AS other_name, [time], Money, Windex "
sqlTrade  = sqlTrade & "  FROM web_market WITH (NOLOCK) "
sqlTrade  = sqlTrade & "  WHERE sell_user_no='" & u & "' AND ISNULL([status],1)=1 "
sqlTrade  = sqlTrade & "  UNION ALL "
sqlTrade  = sqlTrade & "  SELECT '购买' AS rec_type, ISNULL(sell_name,'') AS other_name, [time], Money, Windex "
sqlTrade  = sqlTrade & "  FROM web_market WITH (NOLOCK) "
sqlTrade  = sqlTrade & "  WHERE buy_user_no='" & u & "' AND ISNULL([status],1)=1 "
sqlTrade  = sqlTrade & ") t "
sqlTrade  = sqlTrade & "LEFT JOIN web_items wi ON wi.windex=t.Windex "
sqlTrade  = sqlTrade & "ORDER BY t.[time] DESC"

Set rsTrade = conn.Execute(sqlTrade)

Response.Write "<div class='item-detail-container'>"
Response.Write "<div class='item-detail-header small'>我的交易记录</div>"
Response.Write "<table class='item-detail-table compact'>"
Response.Write "<thead><tr>"
Response.Write "<th style='width:10%;'>类型</th>"
Response.Write "<th style='width:20%;'>交易对象</th>"
Response.Write "<th style='width:30%;'>交易时间</th>"
Response.Write "<th style='width:10%;'>交易金额</th>"
Response.Write "<th style='width:30%;'>物品名称</th>"
Response.Write "</tr></thead><tbody>"

If rsTrade.EOF Then
  Response.Write "<tr><td colspan='5' style='text-align:center;padding:10px;'>暂无交易记录</td></tr>"
Else
  Do While Not rsTrade.EOF
    Dim tType, typeClass, rawOther, maskedOther, tTimeText, tMoney, tItemName

    tType = Trim(rsTrade("rec_type") & "")
    If tType = "出售" Then
      typeClass = "trade-type-sale"
    Else
      typeClass = "trade-type-buy"
    End If

    rawOther = Trim(rsTrade("other_name") & "")
    maskedOther = Server.HTMLEncode(MaskRoleName(rawOther))

    tTimeText = "-"
    If Not IsNull(rsTrade("time")) Then
      If IsDate(rsTrade("time")) Then
        tTimeText = Replace(FormatDateTime(rsTrade("time"), 0), " ", "&nbsp;")
      End If
    End If

    If IsNull(rsTrade("Money")) Or rsTrade("Money") = "" Then
      tMoney = 0
    Else
      tMoney = CLng(rsTrade("Money"))
    End If

    tItemName = Trim(rsTrade("item_name") & "")
    If tItemName = "" Then tItemName = "未知"
    tItemName = Server.HTMLEncode(tItemName)

    Response.Write "<tr>"
    Response.Write "<td><span class='" & typeClass & "'>" & tType & "</span></td>"
    Response.Write "<td>" & maskedOther & "</td>"
    Response.Write "<td>" & tTimeText & "</td>"
    Response.Write "<td>" & FormatNumber(tMoney,0) & "</td>"
    Response.Write "<td>" & tItemName & "</td>"
    Response.Write "</tr>"

    rsTrade.MoveNext
  Loop
End If

rsTrade.Close : Set rsTrade = Nothing
Response.Write "</tbody></table></div>"
End If
End Sub
'------------------------------------------------------------------'
Sub Add()


        If Not ChkLogin Then
        ' 【修改开始】如果未登录，不再跳转，直接在当前页面显示登录按钮
%>
        <div class="user-level login-modal-header login-btn">
            <h3>请先登录</h3>
            <p>您需要登录后才能进行操作,请点击下方按钮登录您的账号。</p>
            <button class="btn btn-login" id="loginBtn">立即登录</button>
        </div>
<%
        ' 停止执行后续代码，防止未登录用户看到职业选择表单
        Response.End
    End If

    ' 【修改结束】以下是已登录用户才能看到的内容，保持不变



			  SET RS2 = Conn_c.Execute("select *  from USER_POSTBOX where post_no='"&post_no&"'")
				If RS2.eof Or RS2.bof Then 
				        Response.Write "<script>alert(""非法参数!"");history.go(-1);</script>"
						response.End
				End If 
				
itemname = GetItemNameByWindex(rs("Windex"))

byHeader=rs2("byHeader")
Hexinfo=ShowHex(rs2("info"))	  
 %>

 <div class="ui-column fn-cf"  style="margin-top:-35px;"><span class="on">我要寄售装备</span></div>

 <form method="post" action="ShopCore.asp?Action=BuySave">
  <table width="97%" height="80" border="0" align="center" cellpadding="2" cellspacing="1" class="maintable">
    <tr >
      <td width="150"><p align="center">装备</p></td>
	  <td height="40" ><p align="center"><%=itemname%></p></td>
    </tr>
	<tr >
      <td width="150"><p align="center">标题</p></td>
	  <td height="40" ><p align="center"><%=rs2("post_title")%></p></td>
    </tr>
    <tr >
      <td><p align="center">属性/数量</p></td>
	  <td height="40" ><p align="center"><%if isChkInteger(Hexnumber(Hexinfo)) then response.write left(Hexnumber(Hexinfo),5) else response.write "1"%></p></td>
    </tr>
	<tr >
      <td><p align="center">售价</p></td>
	  <td height="40" ><p align="center"><%=rs2("include_dil")%></p></td>
    </tr>
	
	<tr >
      <td><p align="center">介绍</p></td>
	  <td height="40" ><p align="center"><%=rs2("body_text")%></p></td>
    </tr>
	
    <tr >
      <td><p align="center">属性1</p></td>
	  <td height="40" ><p align="center"><%
Dim detailHtml
detailHtml = BuildItemDetailHtml(itemname, Hexinfo, byHeader)
Response.Write detailHtml
%></p></td>
    </tr>
	<tr >
      <td><p align="center">选择角色</p></td>
	  <td height="40" ><input type="hidden" name="post_no" value="<%=rs2("post_no")%>"><%=ChkChar%>&nbsp;&nbsp;<input type="submit" class="btn" value="购买装备随手">&nbsp;&nbsp;   <input type="reset" name="button" class="btn" value="返回重新挑选装备" onClick="history.go(-1);"/> </td>
    </tr>
	
  </table>
   </form>
   
<%
end Sub
'-----------------------------提交寄售物品-------------------------------------'
Sub AddItem()
Dim Id, rs, sql, html
Dim rs3, itemname
Dim byHeaderVal, Hexinfo, sHex
Dim qtyText
Dim attrCount, socketCount, b, r
Dim attrLen, attrStart, ai
Dim optIdxHex, optValHex, optIdx, optVal
Dim rsOpt, desc, minD, maxD, delta, v
Dim si, holeHex, holeId, rsSock, sName, sVal
Dim rawLines, rawEncoded
Dim rowId

    If Not ChkLogin Then
        ' 【修改开始】如果未登录，不再跳转，直接在当前页面显示登录按钮
%>
        <div class="user-level login-modal-header login-btn">
            <h3>请先登录</h3>
            <p>您需要登录后才能进行操作,请点击下方按钮登录您的账号。</p>
            <button class="btn btn-login" id="loginBtn">立即登录</button>
        </div>
<%
        ' 停止执行后续代码，防止未登录用户看到职业选择表单
        Response.End
    End If

    ' 【修改结束】以下是已登录用户才能看到的内容，保持不变


If Not ChkOnLine Then
Response.Write "<script>swal({title:'错误!',text:'系统检测到您当前的游戏状态为在线,请退出游戏后重新进行此操作!',type:'error'}, function(){history.go(-1);});</script>"
Response.End
End If

Id = checkstr(Request("Id"))
If IsNull(Id) Or Len(Trim(Id))=0 Then
Response.Write "<script>alert('非法参数!');history.go(-1);</script>"
Response.End
End If

sql = "select * from user_storage where character_no='" & Replace(Id,"'","''") & "' order by line_no"
Set rs = conn_c.Execute(sql)

html = ""
html = html & "<div class=""item-detail-container"">"
html = html & " <div class=""item-detail-header"">选择即将寄售的装备</div>"
html = html & " <table class=""item-detail-table"">"
html = html & " <thead><tr><th>名称</th><th>数量</th><th>出售</th></tr></thead>"
html = html & " <tbody>"

If rs.EOF Then
html = html & " <tr><td class='table-container' colspan='3'>对不起,您的仓库中没有装备,请将需要出售的装备放至仓库中01.</td></tr>"
Else
Do While Not rs.EOF
' 物品名
itemname = GetItemNameByWindex(rs("Windex"))


  ' 基本字段
  byHeaderVal = 0
  If Not IsNull(rs("byHeader")) And rs("byHeader")<>"" Then byHeaderVal = CLng(rs("byHeader"))
  Hexinfo = ShowHex(rs("info"))
  sHex    = UCase(Trim("" & Hexinfo))
  If Left(sHex,2)="0X" Then sHex = Mid(sHex,3)

  ' 数量（byHeader=1 才是堆叠数量）
  qtyText = "1"
  If byHeaderVal = 1 Then
    If isChkInteger(Hexnumber(sHex)) Then
      qtyText = Left(Hexnumber(sHex), 5)
    Else
      qtyText = "1"
    End If
  End If

  ' 条数
  attrCount = 0 : socketCount = 0
  If IsNumeric(byHeaderVal) Then
    b = CLng(byHeaderVal)
    If b > 15 Then
      socketCount = Int(b / 16)
      r = b Mod 16
      If r >= 5 And r <= 8 Then attrCount = r - 4
    Else
      If b >= 5 And b <= 8 Then attrCount = b - 4
    End If
  End If
  If attrCount < 0 Then attrCount = 0
  If attrCount > 4 Then attrCount = 4
  If socketCount < 0 Then socketCount = 0
  If socketCount > 4 Then socketCount = 4

  ' 组装“多行文本”：数量 / 属性 / 分隔 / 镶嵌
  rawLines = "数量: " & qtyText & vbCrLf & "属性" & vbCrLf

  ' 属性：右起，每条6位HEX（4位ID + 2位值）
  If attrCount > 0 Then
    attrLen   = Len(sHex)
    attrStart = attrLen - (attrCount * 6) + 1
    For ai = 0 To attrCount - 1
      optIdxHex = Mid(sHex, attrStart + ai*6,     4)
      optValHex = Mid(sHex, attrStart + ai*6 + 4, 2)
      optIdx    = Hexnumber(optIdxHex)
      optVal    = Hexnumber(optValHex)
      If IsNumeric(optIdx) Then
        Set rsOpt = conn.Execute("SELECT TOP 1 Description,minData,MaxData FROM web_itemoption WHERE OptionIndex=" & CLng(optIdx))
        If Not rsOpt.EOF Then
          desc  = Trim("" & rsOpt("Description"))
          minD  = CLng(rsOpt("minData"))
          maxD  = CLng(rsOpt("MaxData"))
          delta = (maxD - minD) / 100
          v     = CLng(minD + Fix(delta * CLng(optVal)))
          rawLines = rawLines & desc & " " & v & vbCrLf
        End If
        rsOpt.Close : Set rsOpt = Nothing
      End If
    Next
  Else
    rawLines = rawLines & "属性: 无" & vbCrLf
  End If

  rawLines = rawLines & "----" & vbCrLf & "镶嵌" & vbCrLf

  ' 镶嵌：左起，每孔4位HEX
  If socketCount > 0 Then
    For si = 0 To socketCount - 1
      holeHex = Mid(sHex, 1 + si*4, 4)
      holeId  = Hexnumber(holeHex)
      If IsNumeric(holeId) And CLng(holeId)<>0 Then
        Set rsSock = conn.Execute("SELECT TOP 1 name,value FROM web_itemetc_socket WHERE id=" & CLng(holeId))
        If Not rsSock.EOF Then
          sName = Trim("" & rsSock("name"))
          sVal  = Trim("" & rsSock("value"))
          rawLines = rawLines & sName & " " & sVal & vbCrLf
        End If
        rsSock.Close : Set rsSock = Nothing
      End If
    Next
  Else
    rawLines = rawLines & "镶嵌: 无镶嵌" & vbCrLf
  End If

  rawEncoded = Server.HTMLEncode(rawLines)
  rowId = "attr_row_" & rs("line_no")

  html = html & "      <tr>"
  ' 名称：做成按钮样式 + tooltip（class=item-card + data-rawattrs）
  html = html & "        <td>"
  html = html & "          <span class=""action-btn sell-btn item-card"" data-itemname=""" & Server.HTMLEncode(itemname) & """ data-rawattrs=""" & rawEncoded & """>" & Server.HTMLEncode(itemname) & "</span>"
  html = html & "        </td>"

  html = html & "        <td>" & Server.HTMLEncode(qtyText) & "</td>"
  html = html & "        <td><button class=""detail-btn buy-btn"" onclick=""window.location.href='Shop.asp?Action=SaveItem&id=" & Server.URLEncode(Id) & "&line_no=" & rs("line_no") & "';return false;"">出售该道具</button></td>"
  html = html & "      </tr>"

  rs.MoveNext
Loop
End If

html = html & " </tbody></table></div>"
Response.Write html

If Not rs Is Nothing Then rs.Close : Set rs = Nothing
End Sub

'----------------------------寄售物品详情页面----------------------------'
Sub View_Item()
Dim post_no, rs2, rs3, itemname
Dim byHeader, Hexinfo, sHex
Dim qtyText
Dim attrCount, socketCount, b, r
Dim lines, tooltipRaw, tooltipAttr
Dim attrLen, attrStart, ai
Dim optIdxHex, optValHex, optIdx, optVal
Dim rsOpt, desc, minD, maxD, delta, v
Dim si, holeHex, holeId, rsSock, sName, sVal
Dim html

' 访问保护
    If Not ChkLogin Then
        ' 【修改开始】如果未登录，不再跳转，直接在当前页面显示登录按钮
%>
        <div class="user-level login-modal-header login-btn">
            <h3>请先登录</h3>
            <p>您需要登录后才能进行操作,请点击下方按钮登录您的账号。</p>
            <button class="btn btn-login" id="loginBtn">立即登录</button>
        </div>
<%
        ' 停止执行后续代码，防止未登录用户看到职业选择表单
        Response.End
    End If

    ' 【修改结束】以下是已登录用户才能看到的内容，保持不变


If Not ChkOnLine Then
Response.Write "<script>swal({title:'错误!',text:'系统检测到您当前的游戏状态为在线,请退出游戏后重新进行此操作!',type:'error'}, function(){history.go(-1);});</script>"
Response.End
End If

post_no = checkstr(Request("post_no"))
If Len(post_no) = 0 Then
Response.Write "<script>alert('参数错误!');history.go(-1);</script>"
Response.End
End If

' 寄售记录
Set rs2 = conn_c.Execute("select * from USER_POSTBOX where post_no='" & Replace(post_no,"'","''") & "'")
If rs2.EOF Then
Response.Write "<script>alert('非法参数!');history.go(-1);</script>"
Response.End
End If

' 物品名
itemname = GetItemNameByWindex(rs2("Windex"))

' 解析 info/byHeader
byHeader = 0
If Not IsNull(rs2("byHeader")) And rs2("byHeader")<>"" Then byHeader = CLng(rs2("byHeader"))
Hexinfo = ShowHex(rs2("info"))
sHex = UCase(Trim("" & Hexinfo))
If Left(sHex,2)="0X" Then sHex = Mid(sHex,3)

' 数量（byHeader=1 才是堆叠数量）
qtyText = "1"
If IsNumeric(byHeader) Then
If CLng(byHeader) = 1 Then
If isChkInteger(Hexnumber(sHex)) Then qtyText = Left(Hexnumber(sHex), 5)
End If
End If

' 计算属性条数/孔位数
attrCount = 0 : socketCount = 0
If IsNumeric(byHeader) Then
b = CLng(byHeader)
If b > 15 Then
socketCount = Int(b / 16)
r = b Mod 16
If r >= 5 And r <= 8 Then attrCount = r - 4
Else
If b >= 5 And b <= 8 Then attrCount = b - 4
End If
End If
If attrCount < 0 Then attrCount = 0
If attrCount > 4 Then attrCount = 4
If socketCount < 0 Then socketCount = 0
If socketCount > 4 Then socketCount = 4

' 组装“多行文本”：数量/属性/镶嵌（每条一行，前端按行显示）
lines = "数量 " & qtyText

' 属性（右起，每条6位：4位ID + 2位值）
If attrCount > 0 Then
attrLen = Len(sHex)
attrStart = attrLen - (attrCount * 6) + 1
For ai = 0 To attrCount - 1
optIdxHex = Mid(sHex, attrStart + ai6, 4)
optValHex = Mid(sHex, attrStart + ai6 + 4, 2)
optIdx = Hexnumber(optIdxHex)
optVal = Hexnumber(optValHex)


  If IsNumeric(optIdx) Then
    Set rsOpt = conn.Execute("SELECT TOP 1 Description,minData,MaxData FROM web_itemoption WHERE OptionIndex=" & CLng(optIdx))
    If Not rsOpt.EOF Then
      desc  = Trim("" & rsOpt("Description"))
      minD  = CLng(rsOpt("minData"))
      maxD  = CLng(rsOpt("MaxData"))
      delta = (maxD - minD) / 100
      v     = CLng(minD + Fix(delta * CLng(optVal)))
      lines = lines & vbCrLf & desc & " " & v
    End If
    rsOpt.Close : Set rsOpt = Nothing
  End If
Next
Else
lines = lines & vbCrLf & "无属性"
End If

' 镶嵌（左起，每孔4位）
If socketCount > 0 Then
For si = 0 To socketCount - 1
holeHex = Mid(sHex, 1 + si*4, 4)
holeId = Hexnumber(holeHex)
If IsNumeric(holeId) And CLng(holeId)<>0 Then
Set rsSock = conn.Execute("SELECT TOP 1 name, value FROM web_itemetc_socket WHERE id=" & CLng(holeId))
If Not rsSock.EOF Then
sName = Trim("" & rsSock("name"))
sVal = Trim("" & rsSock("value"))
lines = lines & vbCrLf & sName & " " & sVal
End If
rsSock.Close : Set rsSock = Nothing
End If
Next
Else
lines = lines & vbCrLf & "无镶嵌"
End If

tooltipRaw = lines
tooltipAttr = Server.HTMLEncode(tooltipRaw)

' 游戏化样式（标题icon/价格徽章/动感按钮等）
html = ""
html = html & "<style>"
html = html & ".game-title{display:flex;align-items:center;gap:8px;font-weight:800;font-size:18px;color:#f1f5f9;}"
html = html & ".game-title .ico{font-size:20px;filter:drop-shadow(0 0 6px rgba(255,255,255,.15));}"
html = html & ".price-pill{display:inline-block;padding:6px 12px;border-radius:999px;background:linear-gradient(135deg,#eab308,#f59e0b);"
html = html & " color:#1f2937;font-weight:800;border:2px solid #78350f;box-shadow:0 2px 0 #78350f, inset 0 0 8px rgba(255,255,255,.3);}"
html = html & ".btn-action{display:inline-block;padding:10px 16px;border:0;border-radius:10px;background:linear-gradient(135deg,#22c55e,#16a34a);color:#0b1020;"
html = html & " font-weight:800;letter-spacing:.5px;cursor:pointer;box-shadow:0 6px 18px rgba(34,197,94,.4);transition:.18s transform;}"
html = html & ".btn-action:hover{transform:translateY(-2px) scale(1.02);box-shadow:0 10px 28px rgba(34,197,94,.55)}"
html = html & ".btn-action:active{transform:translateY(1px) scale(.98)}"
html = html & ".equip-btn{display:inline-block;padding:6px 10px;border:2px solid rgba(255,255,255,.1);border-radius:8px;background:rgba(255,255,255,.06);"
html = html & " color:#e5e7eb;font-weight:700;cursor:pointer;transition:.18s;}"
html = html & ".equip-btn:hover{background:rgba(255,255,255,.12)}"
html = html & "</style>"

' 页面内容
html = html & "<div class='item-detail-container'>"
html = html & " <div class='game-title'><span class='ico'>🗡️</span><span>寄售装备详情</span></div>"
html = html & " <form method='post' action='ShopCore.asp?Action=RecallSave' id='recallForm'>"
html = html & " <input type='hidden' name='post_no' value='" & rs2("post_no") & "'>"
html = html & " <input type='hidden' id='item_price' value='" & FormatNumber(rs2("include_dil"), 0) & "'>"
html = html & " <input type='hidden' id='sell_character_no' value='" & Server.HTMLEncode(Trim("" & rs2("sell_character_no"))) & "'>"
html = html & " <table class='item-detail-table'>"

' 装备（名称按钮 + 悬浮属性）
html = html & " <tr><td>装备</td><td>"
html = html & " <span class='equip-btn item-card' data-itemname='" & Server.HTMLEncode(itemname) & "' data-rawattrs=""" & tooltipAttr & """>" & Server.HTMLEncode(itemname) & "</span>"
html = html & " </td></tr>"

' 标题
html = html & " <tr><td>标题</td><td>" & Server.HTMLEncode(Trim("" & rs2("post_title"))) & "</td></tr>"

' 数量
html = html & " <tr><td>数量</td><td>" & Server.HTMLEncode(qtyText) & "</td></tr>"

' 售价（价格徽章）
html = html & " <tr><td>售价</td><td><span class='price-pill'>" & FormatNumber(rs2("include_dil"), 0) & " 金币</span></td></tr>"

' 介绍
html = html & " <tr><td>介绍</td><td>" & rs2("body_text") & "</td></tr>"

' 选择角色 + 动感按钮
html = html & " <tr class='item-action-row'>"
html = html & " <td>选择角色</td><td>"
html = html & " <select name='Character' id='characterSelect' class='character-select equipment-price'>"

' 角色下拉
Dim rschr
Set rschr = conn_c.Execute("select character_no,character_name from user_character where user_no='" & Replace(session("user_no"),"'", "''") & "'")
If rschr.EOF Then
html = html & "<option value=''>您还没有创建任何角色</option>"
Else
html = html & "<option value=''>请选择您的角色</option>"
Do While Not rschr.EOF
html = html & "<option value='" & Server.HTMLEncode(Trim("" & rschr(0))) & "'>" & Server.HTMLEncode(Trim("" & rschr(1))) & "</option>"
rschr.MoveNext
Loop
End If
If Not rschr Is Nothing Then rschr.Close : Set rschr = Nothing

html = html & " </select> "
html = html & " <button type='button' class='buy-btn detail-btn' onclick='confirmRecall()'>购买 / 取回装备</button>"
html = html & " </td>"
html = html & " </tr>"

html = html & " </table>"
html = html & " </form>"
html = html & "</div>"

Response.Write html

rs2.Close : Set rs2 = Nothing
End Sub

'----------------------------寄售道具最后一步---------------------------- '
Sub SaveItem()
Dim Id, line_no, rs, rs3, itemname
Dim byHeaderVal, Hexinfo, sHex
Dim qtyText
Dim attrCount, socketCount, b, r
Dim attrLen, attrStart, ai
Dim optIdxHex, optValHex, optIdx, optVal
Dim rsOpt, desc, minD, maxD, delta, v
Dim si, holeHex, holeId, rsSock, sName, sVal
Dim rawLines, rawEncoded
Dim html

    If Not ChkLogin Then
        ' 【修改开始】如果未登录，不再跳转，直接在当前页面显示登录按钮
%>
        <div class="user-level login-modal-header login-btn">
            <h3>请先登录</h3>
            <p>您需要登录后才能进行操作,请点击下方按钮登录您的账号。</p>
            <button class="btn btn-login" id="loginBtn">立即登录</button>
        </div>
<%
        ' 停止执行后续代码，防止未登录用户看到职业选择表单
        Response.End
    End If

    ' 【修改结束】以下是已登录用户才能看到的内容，保持不变


If Not ChkOnLine Then
Response.Write "<script>swal({title:'错误!',text:'系统检测到您当前的游戏状态为在线,请退出游戏后重新进行此操作!',type:'error'}, function(){history.go(-1);});</script>"
Response.End
End If

Id = checkstr(Request("Id"))
line_no = Request("line_no")

If IsNull(Id) Or Len(Trim(Id))=0 Then
Response.Write "<script>alert('非法参数01!');history.go(-1);</script>"
Response.End
End If
If Not IsNumeric(line_no) Then
Response.Write "<script>swal({title:'错误!',text:'非法参数02',type:'error'}, function(){history.go(-1);});</script>"
Response.End
End If

' 校验角色归属
Set rs = conn_c.Execute("select Character_no from User_Character where user_no='" & Replace(session("user_no"),"'", "''") & "' and Character_no='" & Replace(Id,"'","''") & "'")
If rs.EOF Then
Response.Write "<script>swal({title:'错误!',text:'角色信息错误!',type:'error'}, function(){history.go(-1);});</script>"
Response.End
End If
rs.Close : Set rs = Nothing

Set rs = conn_c.Execute("select * from user_storage where character_no='" & Replace(Id,"'","''") & "' and line_no=" & CLng(line_no))

html = "<div class=""item-detail-table2 item-title""><span class=""on"">发布寄售装备（确认步骤）</span></div>"

If rs.EOF Then
html = html & "<div class='table-container'>对不起,您的仓库中没有装备,请将需要出售的装备放至仓库中02.</div>"
Response.Write html
Exit Sub
End If

' 物品名
itemname = GetItemNameByWindex(rs("Windex"))

' 解析 info/byHeader
byHeaderVal = 0
If Not IsNull(rs("byHeader")) And rs("byHeader")<>"" Then byHeaderVal = CLng(rs("byHeader"))
Hexinfo = ShowHex(rs("info"))
sHex = UCase(Trim("" & Hexinfo))
If Left(sHex,2)="0X" Then sHex = Mid(sHex,3)

' 数量
qtyText = "1"
If byHeaderVal = 1 Then
If isChkInteger(Hexnumber(sHex)) Then
qtyText = Left(Hexnumber(sHex), 5)
Else
qtyText = "1"
End If
End If

' 条数
attrCount = 0 : socketCount = 0
If IsNumeric(byHeaderVal) Then
b = CLng(byHeaderVal)
If b > 15 Then
socketCount = Int(b / 16)
r = b Mod 16
If r >= 5 And r <= 8 Then attrCount = r - 4
Else
If b >= 5 And b <= 8 Then attrCount = b - 4
End If
End If
If attrCount < 0 Then attrCount = 0
If attrCount > 4 Then attrCount = 4
If socketCount < 0 Then socketCount = 0
If socketCount > 4 Then socketCount = 4

' 组装“多行文本”：数量 / 属性 / 分隔 / 镶嵌
rawLines = "数量: " & qtyText & vbCrLf & "属性" & vbCrLf

' 属性（右起）
If attrCount > 0 Then
attrLen = Len(sHex)
attrStart = attrLen - (attrCount * 6) + 1
For ai = 0 To attrCount - 1
optIdxHex = Mid(sHex, attrStart + ai6, 4)
optValHex = Mid(sHex, attrStart + ai6 + 4, 2)
optIdx = Hexnumber(optIdxHex)
optVal = Hexnumber(optValHex)
If IsNumeric(optIdx) Then
Set rsOpt = conn.Execute("SELECT TOP 1 Description,minData,MaxData FROM web_itemoption WHERE OptionIndex=" & CLng(optIdx))
If Not rsOpt.EOF Then
desc = Trim("" & rsOpt("Description"))
minD = CLng(rsOpt("minData"))
maxD = CLng(rsOpt("MaxData"))
delta = (maxD - minD) / 100
v = CLng(minD + Fix(delta * CLng(optVal)))
rawLines = rawLines & desc & " " & v & vbCrLf
End If
rsOpt.Close : Set rsOpt = Nothing
End If
Next
Else
rawLines = rawLines & "属性: 无" & vbCrLf
End If

' 镶嵌（左起）
rawLines = rawLines & "----" & vbCrLf & "镶嵌" & vbCrLf
If socketCount > 0 Then
For si = 0 To socketCount - 1
holeHex = Mid(sHex, 1 + si*4, 4)
holeId = Hexnumber(holeHex)
If IsNumeric(holeId) And CLng(holeId)<>0 Then
Set rsSock = conn.Execute("SELECT TOP 1 name,value FROM web_itemetc_socket WHERE id=" & CLng(holeId))
If Not rsSock.EOF Then
sName = Trim("" & rsSock("name"))
sVal = Trim("" & rsSock("value"))
rawLines = rawLines & sName & " " & sVal & vbCrLf
End If
rsSock.Close : Set rsSock = Nothing
End If
Next
Else
rawLines = rawLines & "镶嵌: 无镶嵌" & vbCrLf
End If

rawEncoded = Server.HTMLEncode(rawLines)

' 输出详情与提交表单
html = html & "<div id=""list_mffm"" style=""margin-bottom:15px;"">"
html = html & " <div class=""container"">"
html = html & " <div class=""item-card game-style-container""><li>出售成功的道具将收取每笔20%的交易费</li><li>如中途不想出售可撤回</li></div>"
html = html & " <form method=""post"" action=""ShopCore.asp?Action=SellSave"">"
html = html & " <table class=""item-detail-table"">"
html = html & " <tr class=""data-row""><td class=""table-cell"">道具名称</td><td class=""table-cell""><span class=""action-btn sell-btn item-card"" data-itemname=""" & Server.HTMLEncode(itemname) & """ data-rawattrs=""" & rawEncoded & """>" & Server.HTMLEncode(itemname) & "</span></td></tr>"
html = html & " <tr class=""data-row""><td class=""table-cell"">数量</td><td class=""table-cell"">" & Server.HTMLEncode(qtyText) & "</td></tr>"
html = html & " <tr class=""data-row""><td class=""table-cell"">售价</td><td class=""table-cell""><input type=""text"" name=""price"" style=""width:80%;padding:6px;""></td></tr>"
html = html & " <tr class=""data-row""><td class=""table-cell""></td><td class=""table-cell""><input type=""hidden"" name=""line_no"" value=""" & CLng(line_no) & """><input type=""hidden"" name=""id"" value=""" & Server.HTMLEncode(Id) & """><input type=""submit"" class=""detail-btn"" value=""提交寄售""></td></tr>"
html = html & " </table>"
html = html & " </form>"
html = html & " </div>"
html = html & "</div>"

Response.Write html

If Not rs Is Nothing Then rs.Close : Set rs = Nothing
End Sub

'----------------------------领取新手礼包----------------------------'
Sub Gift()
    Id = checkstr(Request("Id"))

If Not ChkLogin Then
    ' 【修改开始】如果未登录，不再跳转，直接在当前页面显示登录按钮
%>
    <div class="user-level login-modal-header login-btn">
        <h3>请先登录</h3>
        <p>您需要登录后才能领取礼包,请点击下方按钮登录您的账号。</p>
        <button class="btn btn-login" id="loginBtn">立即登录</button>
    </div>
<%
    ' 停止执行后续代码，防止未登录用户看到礼包内容
    Response.End
End If


' 自动获取当前角色ID
    Id = checkstr(Request("Id"))
    If Id = "" Then Id = Session("current_char_id")
    If Id = "" Then
        ' 如果还是没有，获取第一个角色
        Set rsFirst = conn_c.Execute("select top 1 Character_no from User_Character where user_no='" & session("user_no") & "'")
        If Not rsFirst.EOF Then
            Id = rsFirst("Character_no")
            Session("current_char_id") = Id
        End If
        rsFirst.Close
    End If

    
    If Not ChkOnLine Then
        Response.Write "<script>swal({title: ""错误!"",text: ""系统检测到您当前的游戏状态为在线,请退出游戏后重新进行此操作!"",type: ""error"",}, function() {history.go(-1);});</script>"
        response.End
    End If

    Set rs = conn_c.Execute("select Character_name,ipt_time,Gift,dwmoney,wlevel,wMasterLevel from User_Character where user_no='"&session("user_no")&"' and Character_no='"&Id&"'")
    If rs.EOF Or rs.bof Then '检测登陆信息是否正确
        Response.Write "<script>swal({title: ""错误!"",text: ""角色信息错误,请返联系管理员!"",type: ""error"",}, function() {history.go(-1);});</script>"
        response.End
    Else
        Character_name = rs("Character_name")
        ' 使用位运算方式处理礼包状态，与ShopCore.asp保持一致
        currentGift = CLng(rs("Gift")) ' 将Gift字段作为Long整数处理
        wlevel=rs("wlevel")
        wMasterLevel=rs("wMasterLevel")
        ipt_time=rs("ipt_time")
    End If
    rs.close


' 【关键修复】确保USER_PROFILE表有记录并获取礼包状态
    Dim accountGift
    accountGift = 0
    
' ===== 关键修改开始：确保正确读取USER_PROFILE =====
    
    ' 1. 先检查USER_PROFILE表是否有记录
    Set rsCheck = conn.Execute("select count(*) as cnt from USER_PROFILE where user_no='"&session("user_no")&"'")
    If rsCheck("cnt") = 0 Then
        ' 没有记录，创建一个
        conn.Execute "insert into USER_PROFILE (user_no, isGift) values ('"&session("user_no")&"', 0)"
        accountGift = 0
        'Response.Write "<script>alert('已创建USER_PROFILE记录，初始值=0');</script>"
    Else
        ' 有记录，获取当前值
        Set rsAccount = conn.Execute("select isGift from USER_PROFILE where user_no='"&session("user_no")&"'")
        If Not rsAccount.EOF Then
            accountGift = CLng(0 & rsAccount("isGift"))
            'Response.Write "<script>alert('读取USER_PROFILE值=" & accountGift & "');</script>"
        End If
        rsAccount.Close
    End If
    rsCheck.Close
    
    ' ===== 关键修改结束 =====
    


%>
<div class="table-container">
  <h3>注意事项: </h3>
  <p>
    1 : 每个账号只允许一个角色领取礼包,角色创建时间越晚奖励越多!.<br>
    2 : 对于创建时间过早的角色可能无法领取,此举是为了保护新人的利益.<br>
    3 : 角色创建时间必须晚于或等于"礼包要求时间"才能领取.<br>
    4 : 礼包要求时间是指您的角色创建时间必须晚于该日期才能领取礼包.<br>
  </p>
</div>










<div class="gift-table-container">
  <div class="gift-table-wrapper">
    <table class="gift-table">
      <thead>
        <tr>
          <th>礼包</th>
          <th>要求</th>
          <th>礼包内容</th>
          <th>领取状态</th>
        </tr>
      </thead>
      <tbody>
<%
	Set rs = conn.Execute("select * from web_gift")
	If rs.EOF Or rs.bof Then
        Response.Write "<tr><td colspan='4' class='gift-error'>暂无礼包信息</td></tr>"
	else
	Dim gift_index
	gift_index = 0
	Do While not rs.eof
		gift_index = gift_index + 1
		
		' 检查是否可领取
		Dim hasClaimedGift, giftBit, meetsTimeRequirement
		hasClaimedGift = False
		meetsTimeRequirement = False
		
		' 【关键修复】正确的位运算 - 礼包ID从1开始，所以用(礼包ID-1)作为位数
		giftBit = 2 ^ (CInt(RS(0)) - 1)
		
		' 检查是否已领取
		If (accountGift AND giftBit) > 0 Then hasClaimedGift = True
		
		' 调试输出（生产环境可删除）
		Response.Write "<script>console.log('礼包ID:" & RS(0) & ", 位值:" & giftBit & ", 已领取:" & hasClaimedGift & ", 当前总值:" & accountGift & "');</script>"
		
		If Not IsNull(ipt_time) And Not IsNull(rs("chr_date")) And _
		   Len(Trim(ipt_time)) > 0 And Len(Trim(rs("chr_date"))) > 0 And _
		   IsDate(ipt_time) And IsDate(Left(rs("chr_date"), 19)) And _
		   cdate(ipt_time) >= cdate(Left(rs("chr_date"), 19)) Then 
			meetsTimeRequirement = True
		End If
		
		' 确定礼包状态
		Dim statusClass, statusText, canClaim
		If hasClaimedGift Then 
			statusClass = "claimed"
			statusText = "已领取"
			canClaim = False
		ElseIf wlevel <= rs("min_level") Then 
			statusClass = "level-locked"
			statusText = "等级不符"
			canClaim = False
		ElseIf wMasterLevel < rs("min_upgrade") Then 
			statusClass = "upgrade-locked"
			statusText = "转生不符"
			canClaim = False
		ElseIf Not meetsTimeRequirement Then 
			statusClass = "time-locked"
			statusText = "时间不符"
			canClaim = False
		Else
			statusClass = "available"
			statusText = "可领取"
			canClaim = True
		End If
		
		' 替代IIF函数的逻辑
		Dim levelMetClass, levelIcon
		If wlevel > rs("min_level") Then
			levelMetClass = "met"
			levelIcon = "fa-check-circle"
		Else
			levelMetClass = "unmet"
			levelIcon = "fa-times-circle"
		End If
		
		Dim upgradeMetClass, upgradeIcon
		If wMasterLevel >= rs("min_upgrade") Then
			upgradeMetClass = "met"
			upgradeIcon = "fa-check-circle"
		Else
			upgradeMetClass = "unmet"
			upgradeIcon = "fa-times-circle"
		End If
		
		Dim timeMetClass, timeIcon
		If meetsTimeRequirement Then
			timeMetClass = "met"
			timeIcon = "fa-check-circle"
		Else
			timeMetClass = "unmet"
			timeIcon = "fa-times-circle"
		End If
%>
        <tr class="gift-row <%=statusClass%>">
          <td class="gift-name">
            <div class="gift-title">礼包<%=gift_index%></div>
            <div class="character-name">
              <i class="fas fa-user"></i> <%=Character_name%>
            </div>
          </td>
          
          <td class="requirement-cell">
            <div class="requirement-group">
              <div class="requirement-item">
                <div class="requirement-value">
                  <span class="req-label">等级:</span> 
                  <span class="req-target">Lv.<%=rs("min_level")%></span>
                </div>
                <div class="player-value <%=levelMetClass%>">
                  <span class="player-stat">Lv.<%=wlevel%></span>
                  <i class="fas <%=levelIcon%>"></i>
                </div>
              </div>
              
              <div class="requirement-item">
                <div class="requirement-value">
                  <span class="req-label">转生:</span> 
                  <span class="req-target"><%=rs("min_upgrade")%>转</span>
                </div>
                <div class="player-value <%=upgradeMetClass%>">
                  <span class="player-stat"><%=wMasterLevel%>转</span>
                  <i class="fas <%=upgradeIcon%>"></i>
                </div>
              </div>
              
              <div class="requirement-item">
                <div class="requirement-value">
                  <span class="req-label">时间:</span> 
                  <span class="req-target">
                    <% If Not IsNull(rs("chr_date")) And Len(Trim(rs("chr_date"))) > 0 Then %>
                      <%=FormatDateTime(Left(rs("chr_date"), 19), 2)%>
                    <% Else %>
                      无限制
                    <% End If %>
                  </span>
                </div>
                <div class="player-value <%=timeMetClass%>">
                  <span class="player-stat"><%=FormatDateTime(ipt_time, 2)%></span>
                  <i class="fas <%=timeIcon%>"></i>
                </div>
              </div>
            </div>
          </td>
          
          <td class="gift-content-cell">
    <div class="gift-items">
        <%If rs("Cash")>0 Then%>
        <div class="cash-item"> <!-- 原gift-item -->
            <div class="item-left">
                <span class="item-icon">💰</span>
                <span class="item-name">商城币</span>
            </div>
            <span class="item-amount">x<%=rs("Cash")%></span>
        </div>
        <%End If%>
        
        <%If rs("Money")>0 Then%>
        <div class="gold-item"> <!-- 原money-item -->
            <div class="item-left">
                <span class="item-icon">🪙</span>
                <span class="item-name">金币</span>
            </div>
            <span class="item-amount">x<%=FormatNumber(rs("Money")/10000,0)%>万</span>
        </div>
        <%End If%>
        
        <%If rs("item_id")>0 Then%>
        <div class="gift-package-item"> <!-- 原equip-item -->
            <div class="item-left">
                <span class="item-icon">🎁</span>
                <span class="item-name"><%=rs("item_name")%></span>
            </div>
            <span class="item-amount">x<%=rs("item_count")%></span>
        </div>
        <%End If%>
    </div>
</td>
          
          <td class="action-cell">
            <% If canClaim Then %>
              <a href="ShopCore.asp?Action=GiftSave&Id=<%=Id%>&GiftId=<%=RS(0)%>&Url=<%=Server.URLEncode("Shop.asp?Id="&Id&"&Action=Gift")%>" 
                 class="claim-btn available-btn">
                <i class="fas fa-gift"></i> 领取礼包
              </a>
            <% Else %>
              <button class="claim-btn disabled-btn" disabled>
                <i class="fas fa-lock"></i> <%=statusText%>
              </button>
            <% End If %>
          </td>
        </tr>
<%		
		rs.movenext
		Loop
		rs.close
	End If 
%>
      </tbody>
    </table>
  </div>
</div>

<style>
/* 礼包表格容器 - 暗色系透明风格 */
.gift-table-container {
  max-width: 900px;
  width: 100%;
  margin: 0 auto;
  padding: 20px;
  font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
}

.gift-header {
  text-align: center;
  color: #e0e0e0;
  margin-bottom: 20px;
  font-size: 28px;
  text-shadow: 0 0 10px rgba(100, 200, 255, 0.5);
}

/* 更新公告区域样式 */
.gift-notice {
  background: linear-gradient(135deg, rgba(30, 30, 40, 0.9), rgba(40, 40, 50, 0.8));
  border-left: 4px solid #4a9eff;
  padding: 15px 20px;
  margin-bottom: 25px;
  border-radius: 8px;
  box-shadow: 0 4px 15px rgba(0, 0, 0, 0.4);
  backdrop-filter: blur(10px);
  border: 1px solid rgba(74, 158, 255, 0.3);
  position: relative;
  overflow: hidden;
}

.gift-notice::before {
  content: '';
  position: absolute;
  top: 0;
  left: 0;
  right: 0;
  height: 2px;
  background: linear-gradient(90deg, transparent, #4a9eff, transparent);
  animation: scan 3s linear infinite;
}

@keyframes scan {
  0% { transform: translateX(-100%); }
  100% { transform: translateX(100%); }
}

.notice-header {
  display: flex;
  align-items: center;
  gap: 10px;
  margin-bottom: 12px;
  color: #4a9eff;
  font-size: 16px;
  font-weight: bold;
  text-shadow: 0 0 5px rgba(74, 158, 255, 0.5);
}

.notice-header i {
  font-size: 18px;
  animation: pulse-icon 2s ease-in-out infinite;
}

@keyframes pulse-icon {
  0%, 100% { transform: scale(1); }
  50% { transform: scale(1.1); }
}

.gift-notice ul {
  margin: 0;
  padding-left: 0;
  list-style: none;
}

.gift-notice li {
  margin-bottom: 8px;
  color: #b0b0b0;
  display: flex;
  align-items: center;
  gap: 10px;
  padding: 5px 0;
  transition: all 0.3s ease;
}

.gift-notice li:hover {
  color: #e0e0e0;
  transform: translateX(5px);
}

.gift-notice li i {
  color: #4a9eff;
  font-size: 14px;
  width: 16px;
  text-align: center;
}

/* 表格包装器 */
.gift-table-wrapper {
  overflow-x: auto;
  border-radius: 10px;
  box-shadow: 0 4px 20px rgba(0, 0, 0, 0.4);
  background: rgba(20, 20, 30, 0.7);
  backdrop-filter: blur(10px);
  border: 1px solid rgba(74, 158, 255, 0.2);
}

/* 表格样式 - 暗色系透明 */
.gift-table {
  width: 100%;
  border-collapse: separate;
  border-spacing: 0;
  background: rgba(25, 25, 35, 0.6);
  border-radius: 10px;
  overflow: hidden;
}

.gift-table th {
  background: linear-gradient(135deg, rgba(40, 50, 70, 0.9), rgba(30, 40, 60, 0.9));
  color: #e0e0e0;
  padding: 12px 10px;
  text-align: center;
  font-weight: 600;
  font-size: 14px;
  position: relative;
  border-bottom: 1px solid rgba(74, 158, 255, 0.3);
  white-space: nowrap;
}

.gift-table th:not(:last-child):after {
  content: '';
  position: absolute;
  right: 0;
  top: 20%;
  height: 60%;
  width: 1px;
  background: rgba(74, 158, 255, 0.3);
}

.gift-table td {
  padding: 10px 8px;
  vertical-align: middle;
  border-bottom: 1px solid rgba(74, 158, 255, 0.1);
  position: relative;
  color: #b0b0b0;
}

.gift-table tr:last-child td {
  border-bottom: none;
}

.gift-row:hover {
  background-color: rgba(74, 158, 255, 0.1);
}


.gift-title {
  font-size: 16px;
  font-weight: bold;
  color: #4a9eff;
  margin-bottom: 6px;
  text-shadow: 0 0 5px rgba(74, 158, 255, 0.5);
}

.character-name {
  font-size: 12px;
  color: #888;
  display: flex;
  align-items: center;
  justify-content: center;
  gap: 4px;
  white-space: nowrap;
}

.character-name i {
  color: #4a9eff;
  font-size: 12px;
}


.requirement-group {
  display: flex;
  flex-direction: column;
  gap: 6px;
}

.requirement-item {
  background: rgba(30, 30, 40, 0.5);
  border-radius: 4px;
  padding: 4px 6px;
  border: 1px solid rgba(74, 158, 255, 0.1);
  display: flex;
  justify-content: space-between;
  align-items: center;
  white-space: nowrap;
}

.requirement-value {
  display: flex;
  align-items: center;
  gap: 4px;
  flex-shrink: 0;
  
}

.req-label {
  font-size: 11px;
  color: #888;
}

.req-target {
  font-weight: bold;
  color: #e0e0e0;
  font-size: 12px;
}

.player-value {
  display: flex;
  align-items: center;
  gap: 4px;
  padding: 2px 6px;
  border-radius: 3px;
  font-size: 11px;
  flex-shrink: 0;
}

.player-value.met {
  background: linear-gradient(135deg, rgba(46, 204, 113, 0.2), rgba(39, 174, 96, 0.2));
  border: 1px solid rgba(46, 204, 113, 0.3);
  color: #2ecc71;
}

.player-value.unmet {
  background: linear-gradient(135deg, rgba(231, 76, 60, 0.2), rgba(192, 57, 43, 0.2));
  border: 1px solid rgba(231, 76, 60, 0.3);
  color: #e74c3c;
}

.player-stat {
  font-weight: bold;
  font-size: 11px;
}

.player-value i {
  font-size: 12px;
}

.player-value.met i {
  color: #2ecc71;
  text-shadow: 0 0 3px rgba(46, 204, 113, 0.5);
}

.player-value.unmet i {
  color: #e74c3c;
  text-shadow: 0 0 3px rgba(231, 76, 60, 0.5);
}




.item-icon {
  font-size: 14px;
  margin-right: 4px;
}


.item-amount {
  font-weight: bold;
  padding: 1px 4px;
  border-radius: 8px;
  font-size: 10px;
}



.claim-btn {
  display: inline-flex;
  align-items: center;
  justify-content: center;
  gap: 6px;
  padding: 8px 12px;
  border-radius: 20px;
  font-weight: bold;
  font-size: 12px;
  cursor: pointer;
  transition: all 0.3s ease;
  text-decoration: none;
  border: none;
  width: 100%;
  white-space: nowrap;
}

.available-btn {
  background: linear-gradient(135deg, rgba(46, 204, 113, 0.8), rgba(39, 174, 96, 0.8));
  color: white;
  box-shadow: 0 2px 0 rgba(39, 174, 96, 0.6), 0 3px 6px rgba(0, 0, 0, 0.3);
  border: 1px solid rgba(46, 204, 113, 0.3);
}

.available-btn:hover {
  background: linear-gradient(135deg, rgba(39, 174, 96, 0.9), rgba(34, 153, 84, 0.9));
  transform: translateY(-1px);
  box-shadow: 0 3px 0 rgba(34, 153, 84, 0.6), 0 4px 8px rgba(0, 0, 0, 0.4);
}

.disabled-btn {
  background: linear-gradient(135deg, rgba(149, 165, 166, 0.6), rgba(127, 140, 141, 0.6));
  color: #888;
  cursor: not-allowed;
  box-shadow: 0 2px 0 rgba(127, 140, 141, 0.4), 0 3px 6px rgba(0, 0, 0, 0.2);
  border: 1px solid rgba(149, 165, 166, 0.3);
}

/* 状态行样式 */
.gift-row.available {
  background-color: rgba(46, 204, 113, 0.05);
}

.gift-row.claimed {
  background-color: rgba(149, 165, 166, 0.05);
}

.gift-row.level-locked, 
.gift-row.upgrade-locked, 
.gift-row.time-locked {
  background-color: rgba(231, 76, 60, 0.05);
}

/* 错误信息样式 */
.gift-error {
  text-align: center;
  color: #e74c3c;
  padding: 20px;
  font-size: 16px;
  background: rgba(231, 76, 60, 0.1);
  border-radius: 8px;
  border: 1px solid rgba(231, 76, 60, 0.2);
}



</style>

<%
End Sub

'-------------------------兑换商城币--------------------------'
Sub Exchange()

	Id = checkstr(Request("Id"))

If Not ChkLogin Then
    ' 【修改开始】如果未登录，不再跳转，直接在当前页面显示登录按钮
%>
    <div class="user-level login-modal-header login-btn">
        <h3>请先登录</h3>
        <p>您需要登录后才能进行操作,请点击下方按钮登录您的账号。</p>
        <button class="btn btn-login" id="loginBtn">立即登录</button>
    </div>
<%
    ' 停止执行后续代码，防止未登录用户看到礼包内容
    Response.End
End If

	If Not ChkOnLine Then
		Response.Write "<script>swal({title: ""错误!"",text: ""系统检测到您当前的游戏状态为在线,请退出游戏后重新进行此操作!"",type: ""error"",}, function() {history.go(-1);});</script>"
        response.End
    End If


   	Set rs = conn_c.Execute("select Character_name,dwLowPPoint,dwmoney,wlevel from User_Character where user_no='"&session("user_no")&"' and Character_no='"&Id&"'")
    If rs.EOF Or rs.bof Then '检测登陆信息是否正确
		Response.Write "<script>swal({title: ""错误!"",text: ""角色信息错误,请返联系管理员!"",type: ""error"",}, function() {history.go(-1);});</script>"
        response.End
	Else

		Character_name = rs("Character_name")
		dwmoney = CLng(rs("dwmoney"))
		dwLowPPoint= CLng(rs("dwLowPPoint"))
    End If
	rs.close
	%><div class="game-style-container">
<h3>注意事项</h3>
<ul class="game-style-list">
<li><span class="highlight">金币兑换</span>：<%=(need_Money/10000)/10%>万金币可兑换1点商城币，每次可兑换10点商城币，可无限制多次兑换</li>
<li><span class="highlight">红包兑换</span>：<%=need_maya%>个红包可兑换10点商城币，每次可兑换10点商城币，可无限制多次兑换</li>
<li><span class="highlight">P点兑换</span>：<%=(need_PPoint/10000)/10%>万P点可兑换1点商城币，每次可兑换10点商城币，可无限制多次兑换</li>
<li><span class="highlight">重要提示</span>：兑换之前请将红包转移至角色背包</li>
</ul>
</div>
<div class="item-detail-container">
  <div class="item-detail-header"><%=Character_name%> - 兑换商城币</div>
  
  <table class="item-detail-table">
    <thead>
      <tr>
        <th>道具名称</th>
        <th>当前数量</th>
        <th>点击兑换</th>
      </tr>
    </thead>
    <tbody>



      <tr>
        <td>游戏币</td>
        <td><%=dwmoney%></td>
        <td><%
          If dwmoney<need_money Then 
            Response.write "<button class=""detail-btn disabled-btn"" disabled>金币不足,无法兑换</button>"
          else
            Response.write "<button class=""detail-btn buy-btn"" onclick=""window.location.href='ShopCore.asp?Action=ExchangeSave&Id="&Id&"&Action3=1&Url="&Server.URLEncode("Shop.asp?Id="&Id&"&Action=Exchange")&"'"">金币兑换商城币</button>" 
          End If%></td>
      </tr>
				<tr>
                    <td>P点</td>
                    <td><%=dwLowPPoint%></td>
                    <td><%
						If dwLowPPoint<need_PPoint Then 
            Response.write "<button class=""detail-btn disabled-btn"" disabled>P点不足,无法兑换</button>"
						else
						Response.write "<button class=""detail-btn buy-btn"" onclick=""window.location.href='ShopCore.asp?Action=ExchangeSave&Id="&Id&"&Action3=2&Url="&Server.URLEncode("Shop.asp?Id="&Id&"&Action=Exchange")&"'"" >P点兑换商城币</button>" 
					End If%></td>
                </tr>
	<%
	Set rs = conn_c.Execute("select * from user_bag where Character_no='"&Id&"' and windex=9930")
	If rs.EOF Or rs.bof Then
%>
      <tr>
        <td>红包</td>
        <td>0个</td>
        <td><button class="detail-btn disabled-btn" disabled>数量不足,无法兑换</button></td>
      </tr>
<%
	else
	Do While not rs.eof
	If Hexnumber(ShowHex(rs("info")))>=need_maya Then
	Line_no=rs("Line_no")
%>



				<tr>
                    <td>红包</td>
                    <td><%
				if isChkInteger(Hexnumber(ShowHex(rs("info")))) Then
				  If Hexnumber(ShowHex(rs("info")))>5000 Then 
					 response.write "1"
				  else
					response.write Hexnumber(ShowHex(rs("info")))
				  End If 
			  else 
			  response.write "1"
			  End If %>
			  </td>
                    <td><%
					
					Response.write "<button class=""detail-btn buy-btn"" onclick=""window.location.href='ShopCore.asp?Action=ExchangeSave&Id="&Id&"&Line_no="&Line_no&"&Action3=3&Url="&Server.URLEncode("Shop.asp?Id="&Id&"&Action=Exchange")&"'"" >红包兑换商城币</button>"
					
					%></td>
                </tr>

<%		
		End If 
		rs.movenext
		Loop
		rs.close
		End If 
		%>

    </tbody>
  </table>
</div>
<%
End Sub	
Set conn = Nothing	
'------------------------道具兑换------------------------
	Sub ExchangeItem()

  If Not ChkLogin Then
    ' 【修改开始】如果未登录，不再跳转，直接在当前页面显示登录按钮
%>
    <div class="user-level login-modal-header login-btn">
        <h3>请先登录</h3>
        <p>您需要登录后才能进行道具升级,请点击下方按钮登录您的账号。</p>
        <button class="btn btn-login" id="loginBtn">立即登录</button>
    </div>
<%
    ' 停止执行后续代码，防止未登录用户看到礼包内容
    Response.End
End If
    Id = checkstr(Request("Id"))

    If Id="" Then
        Response.Write "<script>alert('请选择角色!');history.go(-1);</script>"
        response.End
    End If

    set rs=conn_c.execute("select Character_name,Character_no,bypcClass from User_Character where user_no='"&session("user_no")&"' and Character_no='"&Id&"'")
%>

<div class="table-container">
  <h3> 第二步：选择需要兑换的道具:</h3>
  <p>
    <font color="#CC0000">1: 请将需要兑换的道具放到角色背包中，否则系统无法识别.</font><br>
  </p>
</div>

<div class="item-detail-container">
  <div class="item-detail-header">装备升级列表（前10项）</div>
  
  <table class="exchange-list-table">
    <thead>
      <tr>
        <th>当前装备</th>
        <th>升级后装备</th>
        <th>所需商城币</th>
      </tr>
    </thead>
    <tbody>
      <%
      ' 从SQL数据库读取装备升级列表
      On Error Resume Next
      Set rsExchange = conn.Execute("SELECT TOP 10 oldname, newname, needcash FROM WEB_ExchangeItem ORDER BY ID")
      
      If Err.Number <> 0 Then
          Response.Write "<tr><td colspan='3' style='text-align: center; color: red;'>数据库错误: " & Err.Description & "</td></tr>"
          Err.Clear
      ElseIf rsExchange.EOF Or rsExchange.bof Then
          Response.Write "<tr><td colspan='3' style='text-align: center; padding: 15px;'>暂无装备升级信息</td></tr>"
      Else
          Dim rowCount
          rowCount = 0
          Do While Not rsExchange.EOF
              rowCount = rowCount + 1
              Dim rowClass
              If rowCount Mod 2 = 0 Then
                  rowClass = "even"
              Else
                  rowClass = "odd"
              End If
      %>
      <tr class="<%=rowClass%>">
        <td><%=Server.HTMLEncode(rsExchange("oldname"))%></td>
        <td><%=Server.HTMLEncode(rsExchange("newname"))%></td>
        <td><strong style="color: #e74c3c;"><%=rsExchange("needcash")%></strong> 点</td>
      </tr>
      <%
              rsExchange.movenext
          Loop
          
          ' 检查是否有更多数据
          Set rsCount = conn.Execute("SELECT COUNT(*) as total FROM WEB_ExchangeItem")
          If Not rsCount.EOF Then
              If rsCount("total") > 10 Then
      %>
      <tr>
        <td colspan="3" style="text-align: center; padding: 8px;">
          <button class="detail-btn view-all-btn" onclick="viewAllExchangeItems()">查看全部装备升级信息 (<%=rsCount("total")%> 项)</button>
        </td>
      </tr>
      <%
              End If
          End If
          rsCount.Close
          Set rsCount = Nothing
      End If
      
      If Not rsExchange Is Nothing Then
          rsExchange.Close
          Set rsExchange = Nothing
      End If
      On Error Goto 0
      %>
    </tbody>
  </table>
</div>

<div class="item-detail-container">
  <div class="item-detail-header">我的背包 - 可升级装备</div>
  
  <table class="exchange-list-table">
    <thead>
      <tr>
        <th>装备名称</th>
        <th>所需商城币</th>
        <th>操作</th>
      </tr>
    </thead>
    <tbody>
      <%
      set rsitem=conn_c.execute("select * from user_bag where character_no='"&Id&"'")
      If rsitem.EOF Or rsitem.bof Then
          Response.Write "<tr><td colspan='3' style='text-align: center; padding: 15px;'>对不起,没有查询到道具，请将需要兑换的道具放到角色背包中</td></tr>"
      Else
          Dim itemRowCount, hasUpgradeableItems
          itemRowCount = 0
          hasUpgradeableItems = false
          
          Do While Not rsitem.EOF
            ' 检查这个物品是否在升级列表中
            SET RS3 = conn.Execute("SELECT * FROM WEB_ExchangeItem WHERE oldid="&rsitem("Windex")&"")
            If Not (RS3.eof Or RS3.bof) Then 
                itemname=RS3("oldname")
                itemcash=RS3("needcash")
                newid=RS3("newid")
                itemRowCount = itemRowCount + 1
                hasUpgradeableItems = true
                Dim itemRowClass
                If itemRowCount Mod 2 = 0 Then
                    itemRowClass = "even"
                Else
                    itemRowClass = "odd"
                End If
      %>
      <tr class="<%=itemRowClass%>">
        <td><%=itemname%></td>
        <td><%=itemcash%> 点</td>
        <td>
<button class="detail-btn exchange-btn" 
        onclick="confirmExchange('<%=Id%>', <%=rsitem("Windex")%>, <%=newid%>, <%=itemcash%>, <%=rsitem("line_no")%>, '<%=Replace(Server.HTMLEncode(itemname), "'", "\'")%>')"
        data-character-id="<%=Id%>"
        data-old-id="<%=rsitem("Windex")%>"
        data-new-id="<%=newid%>"
        data-need-cash="<%=itemcash%>"
        data-line-no="<%=rsitem("line_no")%>"
        data-item-name="<%=Server.HTMLEncode(itemname)%>">
    升级装备
</button>
        </td>
      </tr>
      <%
            End If 
            RS3.Close
            rsitem.movenext
          Loop
          
          If Not hasUpgradeableItems Then
              Response.Write "<tr class='item-detail-table compact nk-pagination'><td >您的背包中没有可升级的装备</td></tr>"
          End If
      End If
      rsitem.Close
      Set rsitem = Nothing
      %>
    </tbody>
  </table>
</div>


<script>
// 查看全部装备升级信息
function viewAllExchangeItems() {
    // 获取当前分区信息
    var currentDkServer = '<%=session("DkServer")%>';
    
    swal({
        title: "加载中...",
        text: "正在获取完整的装备升级信息",
        type: "info",
        showConfirmButton: false
    });
    
    // 打开新窗口显示全部信息，并传递分区参数
    setTimeout(function() {
        var newWindow = window.open('ExchangeItemList.asp?DkServer=' + currentDkServer, 'exchangeItems', 'width=1000,height=700,scrollbars=yes,resizable=yes');
        if (newWindow) {
            swal.close();
        } else {
            swal({
                title: "错误!",
                text: "无法打开新窗口，请检查浏览器弹窗设置!",
                type: "error",
                confirmButtonText: "确定"
            });
        }
    }, 500);
}

// 确认装备升级
function confirmExchange(characterId, oldId, newId, needCash, lineNo, itemName) {
    console.log('升级装备参数:', {
        characterId: characterId,
        oldId: oldId,
        newId: newId,
        needCash: needCash,
        lineNo: lineNo,
        itemName: itemName
    });
    
    // 先获取用户余额
    getUserCashBalance(function(userCash) {
        var canAfford = parseInt(userCash) >= parseInt(needCash);
        var statusHtml = canAfford ? 
            '<span style="color: #27ae60; font-weight: bold;">✓ 余额充足</span>' : 
            '<span style="color: #e74c3c; font-weight: bold;">✗ 余额不足</span>';
        
        var confirmHtml = '<div style="text-align: left; padding: 15px; background: #f8f9fa; border-radius: 8px; margin: 15px 0;">' +
            '<p><strong>🛡️ 装备名称:</strong> ' + itemName + '</p>' +
            '<p><strong>💰 所需商城币:</strong> ' + needCash + ' 点</p>' +
            '<p><strong>👤 您的余额:</strong> ' + userCash + ' 点</p>' +
            '<p><strong>📊 状态:</strong> ' + statusHtml + '</p>' +
            '</div>';
        
        if (!canAfford) {
            swal({
                title: "余额不足",
                html: confirmHtml,
                type: "error",
                confirmButtonText: "确定",
                confirmButtonColor: "#e74c3c"
            });
            return;
        }
        
        swal({
            title: "确认装备升级",
            html: confirmHtml + '<p style="color: #e67e22; margin-top: 10px;">确认要升级这件装备吗？</p>',
            type: "warning",
            showCancelButton: true,
            confirmButtonColor: "#27ae60",
            cancelButtonColor: "#95a5a6",
            confirmButtonText: "确认升级",
            cancelButtonText: "取消",
            closeOnConfirm: false,
            showLoaderOnConfirm: true,
            allowOutsideClick: false
        }, function(isConfirm) {
            if (isConfirm) {
                // 显示处理中提示
                swal({
                    title: "升级进行中",
                    text: "正在处理装备升级，请稍候...",
                    type: "info",
                    showConfirmButton: false,
                    allowOutsideClick: false
                });
                
                // 构建URL参数 - 确保所有参数正确传递
                var urlParams = [
                    'Action=ExchangeItem_Save',
                    'Windex=' + encodeURIComponent(oldId),
                    'Id=' + encodeURIComponent(characterId),
                    'line_no=' + encodeURIComponent(lineNo),
                    'newid=' + encodeURIComponent(newId)
                ].join('&');
                
                var targetUrl = 'ShopCore.asp?' + urlParams;
                console.log('跳转URL:', targetUrl);
                
                // 跳转到处理页面
                setTimeout(function() {
                    window.location.href = targetUrl;
                }, 1000);
            }
        });
    });
}

// 修复后的getUserCashBalance函数
function getUserCashBalance(callback) {
    console.log('开始获取用户余额...');
    
    // 直接使用AJAX获取余额，不依赖任何DOM元素
    $.ajax({
        url: 'GetUserCash.asp',
        type: 'GET',
        dataType: 'text',
        timeout: 10000,
        success: function(data) {
            console.log('获取余额成功:', data);
            var balance = data.trim();
            
            // 验证返回的数据是否为数字
            if (balance === '' || isNaN(parseInt(balance))) {
                console.warn('余额数据无效，使用默认值0');
                callback('0');
            } else {
                callback(balance);
            }
        },
        error: function(xhr, status, error) {
            console.error('获取余额失败:', status, error);
            // 使用默认值
            callback('0');
        }
    });
}

// 简化的页面初始化
$(document).ready(function() {
    console.log('装备升级页面加载完成');
    
    // 为升级按钮添加调试信息
    $('.exchange-btn').each(function() {
        var $btn = $(this);
        console.log('找到升级按钮:', $btn.attr('onclick'));
    });
});
</script>
<%
End Sub

'----------------------
		
		Sub Pay()
%>
					

      <FORM name=alipayment onSubmit="return CheckForm();" action=alipayto.asp method=post target="_blank">
	  

<div class="table-container">
    <h3>充值说明:</h3>
       <p> 2,0-9所有的神兵道具可一次安全强化位+10,如果您没有神兵道具可以购买或查询价格.</p>
       <p> 3,如需购买首饰翅膀请尽可能通过网站直接够买,遇到装备被盗可自行通过网站找回.</p>
	   <p>4,8.9日前开放185级装备，8.9日我们将免费统一将185升级为最新195级装备(不扣点不累计)。</p>
       <p>5,以下价格仅供价格计算参考使用.请按照您的实际需求选择充值金额.</p>
		  
  </div>


<div class="item-detail-container">
  <div class="item-detail-header">用户充值</div>
  
  <table class="item-detail-table11" style="margin-top: 0;">
    <tr>
      <td style="width:120px;"><strong>充值金额:</strong></td>
      <td>
        <div style="display: inline-block; margin-right: 15px;">
          <INPUT name="alimoney" id="product-subtotal" size=13 maxLength=10 class="form-control" style="display: inline-block; width: 150px;">
        </div>
        <div style="display: inline-block; color: #666; font-size: 14px;">
          充值100元以上赠5%,500元以上赠10%,1000元以上赠20%的商城币.
        </div>
      </td>
    </tr>
    <tr>
      <td><strong>验证码：</strong></td>
      <td>
        <div style="display: inline-block; margin-right: 15px;">
          <input type="text" value="" name="checkcode" class="form-control" ajaxurl="inc/check.asp" datatype="n4-4" nullmsg="请输入验证码！" errormsg="验证码错误！" style="width:120px; display: inline-block;"/>
        </div>
        <div style="display: inline-block;">
          <img src="inc/getcode.asp" style="cursor:Pointer;width:110px;height:32px" alt="看不清楚?请点击刷新" name="src" id="src" onClick="this.src=this.src+'?'+Math.random();"/>
        </div>
        <div class="Validform_checktip"></div>
        <div class="info" style="margin-top: 5px; color: #999; font-size: 12px;">请输入验证码<span class="dec"><s class="dec1">&#9670;</s><s class="dec2">&#9670;</s></span></div>
      </td>
    </tr>
    <tr>
      <td colspan="2" style="text-align: center; padding: 20px;">
        <button style="border:0; padding: 10px 30px; background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); color: white; border-radius: 6px; font-size: 16px; cursor: pointer;" class="submit-btn">确 定</button>
      </td>
    </tr>
  </table>
</div>
</form>
<%
End Sub


	  Sub OrderList()
	  %>
<div class="item-detail-container">
  <div class="item-detail-header">充值订单管理</div>
  
  <table class="item-detail-table">
    <thead>
      <tr>
        <th>订单日期</th>
        <th>金额/商城币</th>
        <th>订单状态</th>
        <th>领取商城币</th>
        <th>获取等级</th>
        <th>领取金币</th>
      </tr>
    </thead>
    <tbody>
        <%
If session("user_no")="" Or session("UserName")="" Then
  response.write "<script language=javascript>alert('请登录网站后在进行操作!');history.back()</script>"
response.End
End If 
set rs=conn.execute("select * from PayLog where  userid='"&session("user_no")&"' and trade_status>0")
If rs.EOF Or rs.bof Then
    response.Write "<tr><td colspan='6' style='text-align: center; padding: 20px;'>对不起,没有查询到任何订单信息.</td></tr>"
Else
    Do While Not rs.EOF
%>
        <tr>
          <td title="订单编号:<%=rs("PayNo")%>"><%=rs("Paytime")%></td>
          <td><%=rs("Amount")%>/<%=rs("gamecash")%></td>
          <td><%
		  select case rs("trade_status")
			case 1
		  response.write"已付款"  
		   case 2
		  response.write"交易成功" 
		   case 3
		  response.write"人工订单" 
		   case 4
		  response.write"转区订单" 
		   case else
		  response.write"未知信息"
		  end select 
		  %></td>
          <td><%
		  if rs("trade_status")=1 Then
		  response.write "<button class=""action-btn gift-btn"" data-url=""?Action=GiveCash&PayNo="&rs("PayNo")&""" data-action=""领取"">领取商城币</button>"
		  else
		  response.write"已领取"
		  end if 
		  %></td>
          <td><%
		  if rs("uplevel")=0 Then
			  	if rs("Amount")>299 then 
		  			response.write "<a href=uplevel.asp?PayNo="&rs("PayNo")&">提升等级</a>"
		 		end if 
		  end if 
		  %></td>
          <td><%
		  if rs("givemoney")=0 and (rs("trade_status")=2 or rs("trade_status")=3) then 
		  			response.write "<a href=uplevel.asp?GiveMoney=1&PayNo="&rs("PayNo")&" title=""点击这里可领取"""&rs("Amount")*200000&"金币"">领取金币</a>"
		  end if 
		  %></td>
        </tr>
        <%
rs.movenext
Loop
End If
rs.Close
Set rs = Nothing
' 【重要】已删除 conn.Close 和 Set conn = Nothing，移到页面底部统一关闭
    
%>
      <tr>
        <td colspan="6">
          <div style="color: #d32f2f; background-color: #ffebee; padding: 15px; border-radius: 6px; margin: 10px 0;">
            <strong>注意:</strong><br>
            充值成功后请点击点击领取商城币,否则您将无法获取商城币.<br><br>
            单笔订单满<span style="color: #e65100; font-weight: bold;">300</span>元可将账号中的任意角色提升至<span style="color: #e65100; font-weight: bold;">185</span>级,请点击订单后面的链接进行操作.<br><br>
            每充值1元送20万金币,以此类推.金币将发送至账号中等级最高的角色里.
          </div>
        </td>
      </tr>
    </tbody>
  </table>
</div>
    <%End Sub

    '--------------------个人中心页面-------------------
    Sub UserCenter()
        If Not ChkLogin Then
    %>
            <div class="user-level login-modal-header login-btn">
                <h3>请先登录</h3>
                <p>您需要登录后才能查看个人中心,请点击下方按钮登录您的账号。</p>
                <button class="btn btn-login" id="loginBtn">立即登录</button>
            </div>
    <%
            Response.End
        End If

        ' 调用函数获取数据，避免在页面内写复杂SQL
        Dim onlineTime, currencyInfo, totalCCoin, totalBCoin
        onlineTime = GetUserTotalOnlineTime(session("user_no"))
        currencyInfo = GetUserTotalCurrency(session("user_no"))
        totalCCoin = currencyInfo(0)
        totalBCoin = currencyInfo(1)

        ' 获取角色列表
        Dim rs
        Set rs = conn_c.Execute("SELECT character_name, wlevel, bypcClass FROM user_character WHERE user_no='" & session("user_no") & "' ORDER BY wlevel DESC")
    %>
    <!-- 账户概览 -->
    <div class="table-container">
        <h4 style="color: #fff; margin-bottom: 20px;">
            <i class="fas fa-user-circle"></i> 账户概览 - <%=Session("username")%>
        </h4>
        <div class="row">
            <div class="col-md-3 col-sm-6">
                <div class="info-box">
                    <span class="info-box-icon bg-blue"><i class="fas fa-clock"></i></span>
                    <div class="info-box-content">
                        <span class="info-box-text">总在线时间</span>
                        <span class="info-box-number"><%=onlineTime%></span>
                    </div>
                </div>
            </div>
            <div class="col-md-3 col-sm-6">
                <div class="info-box">
                    <span class="info-box-icon bg-green"><i class="fas fa-coins"></i></span>
                    <div class="info-box-content">
                        <span class="info-box-text">总C币</span>
                        <span class="info-box-number"><%=FormatNumber(totalCCoin, 0)%></span>
                    </div>
                </div>
            </div>
            <div class="col-md-3 col-sm-6">
                <div class="info-box">
                    <span class="info-box-icon bg-orange"><i class="fas fa-gem"></i></span>
                    <div class="info-box-content">
                        <span class="info-box-text">总B币</span>
                        <span class="info-box-number"><%=FormatNumber(totalBCoin, 0)%></span>
                    </div>
                </div>
            </div>
            <div class="col-md-3 col-sm-6">
                <div class="info-box" style="text-align: center; padding: 10px;">
                    <a href="Shop.asp?Action=Pay" class="action-btn buy-btn" style="font-size: 16px; padding: 10px 20px;">
                        <i class="fas fa-credit-card"></i> 立即充值
                    </a>
                </div>
            </div>
        </div>
    </div>

    <!-- 角色列表 -->
    <div class="item-detail-container" style="margin-top: 20px;">
        <div class="item-detail-header"><i class="fas fa-users"></i> 我的角色</div>
        <table class="item-detail-table">
            <thead>
                <tr>
                    <th>角色名称</th>
                    <th>职业</th>
                    <th>等级</th>
                    <th>操作</th>
                </tr>
            </thead>
            <tbody>
                <%
                If rs.EOF Or rs.bof Then
                    response.Write "<tr><td colspan='4' style='text-align: center; padding: 20px;'>您还没有创建任何角色....</td></tr>"
                Else
                    Do While Not rs.EOF
                %>
                    <tr>
                        <td><%=rs("character_name")%></td>
                        <td><%=GetClass(rs("bypcClass"))%></td>
                        <td><%=rs("wlevel")%></td>
                        <td>
                            <a href="User.asp?Action2=Upgrade&Id=<%=rs("character_name")%>" class="action-btn exchange-btn">角色转生</a>
                            <a href="User.asp?Action2=ChangeJob&Id=<%=rs("character_name")%>" class="action-btn exchange-btn">变更职业</a>
                        </td>
                    </tr>
                <%
                    rs.movenext
                    Loop
                End If
                rs.Close
                Set rs = Nothing
                %>
            </tbody>
        </table>
    </div>
    <%
    End Sub

    ' 在页面所有ASP逻辑都处理完毕后，统一关闭数据库连接
    Set conn = Nothing
    Set conn_c = Nothing
    %>
                     
                        <!-- END: Products -->
                      
                     </div>
                    </div>
                    <div class="col-lg-4">
                        <!--
                START: Sidebar

                Additional Classes:
                    .nk-sidebar-left
                    .nk-sidebar-right
                    .nk-sidebar-sticky
            -->
                        <aside class="nk-sidebar nk-sidebar-right nk-sidebar-sticky">

                            <div class="nk-widget nk-widget-highlighted" style="margin-top: -30px">
                                <h4 class="nk-widget-title" style="color: #fff; "><span><span class="text-main-1">控制</span> 面板</span></h4>
                                <div class="nk-widget-content">
                                    <ul class="nk-widget-categories">
									<li><a href="Shop.asp?Action2=Add" <%If Right(pageLink,2)="dd"  Then response.write "class='on'"%>>寄售道具</a></li>
									<li><a href="Shop.asp?Action3=My" <%If Right(pageLink,2)="my"  Then response.write "class='on'"%>>我的寄售</a></li>
									<li><a href="Shop.asp" <%If Right(pageLink,2)=""  Then response.write "class='on'"%>>交易市场</a></li>
									<li><a href="Shop.asp?Action2=Gift" <%If Right(pageLink,2)="ft"  Then response.write "class='on'"%>>领取礼包</a></li>
									<li><a href="Shop.asp?Action2=Exchange" <%If Right(pageLink,2)="ge" Then response.write "class='on'"%>>兑换商城币</a></li>
									<li><a href="Shop.asp?Action2=ExchangeItem" <%If Right(pageLink,2)="em" Then response.write "class='on'"%>>装备熔炼</a></li>
                  <li><a href="javascript:void(0);" class="dropdown-item right-menu" onclick="openLotteryModal()">🎲 幸运大抽奖</a></li>
									<li><a href="javascript:swal('该功能暂未开放', '王者5区为免费服务器,该功能暂不开放.', 'error');" <%If Right(pageLink,2)="ap" Then response.write "class='on'"%>>在线充值</a></li>
									<li><a href="javascript:swal('该功能暂未开放', '王者5区为免费服务器,该功能暂不开放.', 'error');" <%If Right(pageLink,2)="st"  Then response.write "class='on'"%>>订单管理</a></li>
                                    </ul>
                                </div>
                            </div>

                            <div class="nk-widget nk-widget-highlighted">
								<h4 class="nk-widget-title" style="color: #fff; "><span><span class="text-main-1">客服</span> 帮助</span></h4>
                                <div class="nk-widget-content">
						<p style="height: 40px;">客服Q Q：9891328</p>
						<p style="height: 40px;">服务时间：9:00-24:00</p>
						<p style="height: 40px;">微信号：<img  style="CURSOR: pointer" onclick="javascript:window.open('http://b.qq.com/webc.htm?new=0&sid=9891328&o=王者挑战客服&q=7', '_blank', 'height=502, width=644,toolbar=no,scrollbars=no,menubar=no,status=no');"  border="0" SRC=http://wpa.qq.com/pa?p=1:9891328:1 alt="点击这里给我发消息"></p>
                                </div>
                            </div>
                        </aside>
                        <!-- END: Sidebar -->
                    </div>
                </div>
            </div>
            <div class="nk-gap-2"></div>
		<!--#include file="Copyright.asp" -->
        </div>
        <!-- START: Page Background -->
        <img class="nk-page-background-top" src="static/image/bg-top-4.png" alt="">
        <img class="nk-page-background-bottom" src="static/image/bg-bottom.png" alt="">
        <!-- END: Page Background -->
       
        <!-- START: Login Modal -->
        <div class="nk-modal modal fade" id="modalLogin" tabindex="-1" role="dialog" aria-hidden="true">
            <div class="modal-dialog modal-sm" role="document">
                <div class="modal-content">
                    <div class="modal-body">
                        <button type="button" class="close" data-dismiss="modal" aria-label="Close">
                            <span class="ion-android-close"></span>
                        </button>
                        <h4 class="mb-0"><span class="text-main-1">Sign</span> In</h4>
                        <div class="nk-gap-1"></div>
                        <form action="#" class="nk-form text-white">
                            <div class="row vertical-gap">
                                <div class="col-md-6"> Use email and password: <div class="nk-gap"></div>
                                    <input type="email" value="" name="email" class=" form-control" placeholder="Email">
                                    <div class="nk-gap"></div>
                                    <input type="password" value="" name="password" class="required form-control" placeholder="Password">
                                </div>
                                <div class="col-md-6"> Or social account: <div class="nk-gap"></div>
                                    <ul class="nk-social-links-2">
                                        <li><a class="nk-social-facebook" href="#"><span class="fab fa-facebook"></span></a></li>
                                        <li><a class="nk-social-google-plus" href="#"><span class="fab fa-google-plus"></span></a></li>
                                        <li><a class="nk-social-twitter" href="#"><span class="fab fa-twitter"></span></a></li>
                                    </ul>
                                </div>
                            </div>
                            <div class="nk-gap-1"></div>
                            <div class="row vertical-gap">
                                <div class="col-md-6">
                                    <a href="#" class="nk-btn nk-btn-rounded nk-btn-color-white nk-btn-block">Sign In</a>
                                </div>
                                <div class="col-md-6">
                                    <div class="mnt-5">
                                        <small><a href="#">Forgot your password?</a></small>
                                    </div>
                                    <div class="mnt-5">
                                        <small><a href="#">Not a member? Sign up</a></small>
                                    </div>
                                </div>
                            </div>
                        </form>
                    </div>
                </div>
            </div>
        </div>


<script>
(function () {
  var debug = false;
 
  // 1) 注入样式（包含火爆图标样式）
  (function injectCSS() {
    var css = 
      '#mouseTooltip{position:fixed;display:none;z-index:9999999;max-width:520px;background:rgba(18,18,18,0.96);color:#fff;padding:0;border-radius:8px;box-shadow:0 8px 30px rgba(0,0,0,0.6);font-size:13px;pointer-events:none;line-height:1.35;}' +
      '#mouseTooltip .tt-header{padding:10px 12px;background:rgba(255,255,255,0.03);border-radius:8px 8px 0 0;font-weight:700;border-bottom:1px solid rgba(255,255,255,0.04);color:#fff;}' +
      '#mouseTooltip .tt-body{padding:10px 12px;}' +
      '#mouseTooltip .tt-line{margin:6px 0;word-break:break-word;white-space:normal;display:flex;align-items:baseline;}' +
      '#mouseTooltip .tt-name{color:#f5f5f5;margin-right:8px;font-weight:600;}' +
      '#mouseTooltip .tt-plus{color:#fff;margin-right:6px;font-weight:700;}' +
      '#mouseTooltip .tt-val{font-weight:700;}' +
      '.gt-group-title{margin-top:8px;color:#9ca3af;font-weight:700;}' +
      '.gt-gap{height:8px;}' +
      // 属性配色
      '.attr-color-1{color:#60a5fa !important}' +  // 浅蓝
      '.attr-color-2{color:#1d4ed8 !important}' +  // 深蓝
      '.attr-color-3{color:#8b5cf6 !important}' +  // 紫色
      '.attr-color-4{color:#f59e0b !important}' +  // 金色
      // 其余颜色全部当作镶嵌红色
      '.attr-color-5,.attr-color-6,.attr-color-7,.attr-color-8,.attr-color-9,.attr-color-10,.attr-color-11,.attr-color-12,.attr-color-13,.attr-color-14,.attr-color-15,.attr-color-16{color:#ef4444 !important}' +
      '.attr-socket{color:#ef4444 !important;font-weight:700;}' +
      '.muted{color:#94a3b8 !important;}' +
      
      // 火爆图标样式
      '.hot-badge { background: linear-gradient(45deg, #ff6b6b, #ff8e53); color: white; padding: 2px 6px; border-radius: 10px; font-size: 10px; margin-left: 8px; animation: glow 1.5s ease-in-out infinite alternate; }' +
      '@keyframes glow { from { box-shadow: 0 0 5px #ff6b6b; } to { box-shadow: 0 0 10px #ff8e53, 0 0 15px #ff6b6b; } }';
 
    var st = document.createElement('style');
    st.type = 'text/css';
    st.appendChild(document.createTextNode(css));
    document.head.appendChild(st);
  })();
 
  // 2) 创建 tooltip 容器
  var tooltip = document.getElementById('mouseTooltip');
  if (!tooltip) {
    tooltip = document.createElement('div');
    tooltip.id = 'mouseTooltip';
    tooltip.style.display = 'none';
    document.body.appendChild(tooltip);
  }
 
  // 3) 工具函数
  function decodeHTML(encoded) {
    var d = document.createElement('div');
    d.innerHTML = encoded || '';
    var s = d.textContent || d.innerText || '';
    return s.replace(/\u00a0|\u3000/g, ' ').trim();
  }
 
  function splitLines(s) {
    return (s || '')
      .split(/\r\n|\r|\n/)
      .map(function (t) { return (t || '').trim(); })
      .filter(Boolean);
  }
 
  // 从 data-rawattrs 解析为结构化数据
  function parseRaw(raw) {
    var tokens = splitLines(decodeHTML(raw));
    var out = { qty: '1', attrs: [], sockets: [] };
    var mode = 'none';

    for (var i = 0; i < tokens.length; i++) {
      var t = tokens[i];

      if (/^数量\s*[:：]/.test(t)) {
        out.qty = t.replace(/^数量\s*[:：]\s*/, '');
        continue;
      }

      if (/^属性$/.test(t)) {
        mode = 'attr';
        continue;
      }

      if (/^镶嵌$/.test(t)) {
        mode = 'socket';
        continue;
      }

      if (/^[-]{2,}$/.test(t)) {
        continue;
      }

      if (/^属性\s*[:：]\s*无$/.test(t)) {
        continue;
      }

      if (/^镶嵌\s*[:：]\s*无镶嵌$/.test(t)) {
        continue;
      }

      // 普通行：用末尾的数字或数字%识别值，其余当名字
      var m = t.match(/([-+]?\d+(?:\.\d+)?%?)$/);
      var name = t, val = '';

      if (m) {
        val = m[1];
        name = t.slice(0, t.length - val.length).replace(/[：:]+$/, '').trim();
      }

      if (mode === 'socket') {
        out.sockets.push({ name: name, value: val });
      } else if (mode === 'attr') {
        out.attrs.push({ name: name, value: val });
      }
    }
    return out;
  }
 
  // 4) 根据 raw 渲染 tooltip
  function buildTooltipFromRaw(title, raw) {
    tooltip.innerHTML = '';

    var header = document.createElement('div');
    header.className = 'tt-header';
    header.textContent = title || '';
    tooltip.appendChild(header);

    var body = document.createElement('div');
    body.className = 'tt-body';
    tooltip.appendChild(body);

    var data = parseRaw(raw || '');

    // 数量
    var q = document.createElement('div');
    q.className = 'tt-line';
    q.innerHTML = 
      '<span class="tt-name">数量</span>' + 
      '<span class="tt-plus"></span>' + 
      '<span class="tt-val">' + (data.qty || '1') + '</span>';
    body.appendChild(q);

    // 属性
    var tA = document.createElement('div');
    tA.className = 'tt-line gt-group-title';
    tA.textContent = '属性';
    body.appendChild(tA);

    if (data.attrs.length) {
      for (var i = 0; i < data.attrs.length; i++) {
        var a = data.attrs[i];
        var line = document.createElement('div');
        line.className = 'tt-line';
        var col = 'attr-color-' + (i + 1);
        if (i + 1 > 4) col = 'attr-color-4';
        line.innerHTML = 
          '<span class="tt-name">' + (a.name || '') + '</span>' + 
          '<span class="tt-plus">+</span>' + 
          '<span class="tt-val ' + col + '">' + (a.value || '') + '</span>';
        body.appendChild(line);
      }
    } else {
      var lineN = document.createElement('div');
      lineN.className = 'tt-line';
      lineN.innerHTML = 
        '<span class="tt-name"></span>' + 
        '<span class="tt-plus"></span>' + 
        '<span class="tt-val muted">无</span>';
      body.appendChild(lineN);
    }

    // 间隔
    var sp = document.createElement('div');
    sp.className = 'gt-gap';
    body.appendChild(sp);

    // 镶嵌
    var tS = document.createElement('div');
    tS.className = 'tt-line gt-group-title';
    tS.textContent = '镶嵌';
    body.appendChild(tS);

    if (data.sockets.length) {
      for (var j = 0; j < data.sockets.length; j++) {
        var s = data.sockets[j];
        var line2 = document.createElement('div');
        line2.className = 'tt-line';
        line2.innerHTML = 
          '<span class="tt-name">' + (s.name || '') + '</span>' + 
          '<span class="tt-plus">+</span>' + 
          '<span class="tt-val attr-socket">' + (s.value || '') + '</span>';
        body.appendChild(line2);
      }
    } else {
      var line2N = document.createElement('div');
      line2N.className = 'tt-line';
      line2N.innerHTML = 
        '<span class="tt-name"></span>' + 
        '<span class="tt-plus"></span>' + 
        '<span class="tt-val attr-socket">无镶嵌</span>';
      body.appendChild(line2N);
    }
  }
 
  // 5) 绑定卡片和火爆图标
  function bindCards() {
    var cards = document.querySelectorAll('.item-card');
    var HOT_RATIO = 0.15; // 15% 火爆概率
    
    for (var i = 0; i < cards.length; i++) {
      var el = cards[i];
      if (el._ttBound) continue;
      el._ttBound = true;

      // 绑定 tooltip
      el.addEventListener('mouseenter', function (e) {
        var title = this.getAttribute('data-itemname') || '';
        var raw = this.getAttribute('data-rawattrs') || '';
        buildTooltipFromRaw(title, raw);
        tooltip.style.display = 'block';
        moveWith(e);
      });

      el.addEventListener('mousemove', moveWith);

      el.addEventListener('mouseleave', function () {
        tooltip.style.display = 'none';
      });

      // 添加火爆图标
      if (!el.querySelector('.hot-badge') && Math.random() < HOT_RATIO) {
        markHot(el);
      }
    }
  }

  function markHot(card) {
    if (card.querySelector('.hot-badge')) return;
    
    var title = card.querySelector('.equip-title') || card.querySelector('.item-header h3');
    if (!title) return;
    
    var badge = document.createElement('span');
    badge.className = 'hot-badge';
    badge.textContent = '🔥 火爆';
    title.insertAdjacentElement('afterend', badge);
  }

  function moveWith(e) {
    var rect = tooltip.getBoundingClientRect();
    var x = e.clientX + 12;
    var y = e.clientY + 12;
    var W = window.innerWidth || document.documentElement.clientWidth;
    var H = window.innerHeight || document.documentElement.clientHeight;

    if (x + rect.width > W) x = e.clientX - rect.width - 12;
    if (y + rect.height > H) y = e.clientY - rect.height - 12;
    if (x < 2) x = 2;
    if (y < 2) y = 2;

    tooltip.style.left = x + 'px';
    tooltip.style.top = y + 'px';
  }
 
  // 6) 详情页渲染
  window.renderDetailFromRaw = function (boxId, title) {
    var el = document.getElementById(boxId);
    if (!el) return;
    var raw = el.getAttribute('data-rawattrs') || '';
    buildTooltipFromRaw(title || '物品详情', raw);
    var body = tooltip.querySelector('.tt-body');
    if (body) {
      el.innerHTML = body.innerHTML;
    }
    tooltip.style.display = 'none';
  };
 
  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', bindCards);
  } else {
    bindCards();
  }
})();




// 取回装备确认函数
function confirmRecall() {
    var characterSelect = document.getElementById('characterSelect');
    var selectedCharacter = characterSelect.value;
    var sellCharacterNo = document.getElementById('sell_character_no').value;
    var itemPrice = document.getElementById('item_price').value;
    
    if (!selectedCharacter) {
        swal({
            title: "错误!",
            text: "请先选择要接收装备的角色!",
            type: "error"
        });
        return;
    }
    
    var characterName = characterSelect.options[characterSelect.selectedIndex].text;
    
    // 第一个对话框：确认是否继续
    swal({
        title: "确认操作",
        text: "您确定要操作这件装备吗？",
        type: "warning",
        showCancelButton: true,
        confirmButtonColor: "#DD6B55",
        confirmButtonText: "确定继续",
        cancelButtonText: "取消",
        closeOnConfirm: false,
        showLoaderOnConfirm: false
    }, function(isConfirm) {
        if (isConfirm) {
            // 第二个对话框：显示详细信息
            showRecallDetails(selectedCharacter, characterName, sellCharacterNo, itemPrice);
        }
    });
}

// 显示详细信息的第二个对话框
function showRecallDetails(characterId, characterName, sellCharacterNo, itemPrice) {
    var isSelfRecall = (characterId === sellCharacterNo);
    
    if (isSelfRecall) {
        swal({
            title: "确认取回装备",
            html: "这是您自己寄售的装备，取回不扣除任何费用<br><br>" +
                  "<strong>接收角色:</strong> " + characterName + "<br>" +
                  "<strong>操作类型:</strong> 免费取回",
            type: "info",
            showCancelButton: true,
            confirmButtonColor: "#28a745",
            confirmButtonText: "确认取回",
            cancelButtonText: "取消",
            closeOnConfirm: false,
            showLoaderOnConfirm: true
        }, function(isConfirm) {
            if (isConfirm) {
                document.getElementById('recallForm').submit();
            }
        });
    } else {
        getUserCashBalance(function(userCash) {
            var canAfford = parseInt(userCash) >= parseInt(itemPrice);
            var statusHtml = canAfford ? 
                '<span style="color: #28a745; font-weight: bold;">余额充足</span>' : 
                '<span style="color: #dc3545; font-weight: bold;">余额不足</span>';
            
            var confirmButtonColor = canAfford ? "#28a745" : "#6c757d";
            var confirmButtonText = canAfford ? "确认购买" : "余额不足";
            
            swal({
                title: "确认购买装备",
                html: "<strong>装备价格:</strong> " + itemPrice + " 金币<br>" +
                      "<strong>您的余额:</strong> " + userCash + " 金币<br>" +
                      "<strong>接收角色:</strong> " + characterName + "<br>" +
                      "<strong>状态:</strong> " + statusHtml + "<br><br>" +
                      (canAfford ? 
                       "购买后将扣除 " + itemPrice + " 金币" : 
                       "<span style='color: #dc3545;'>您的余额不足，无法购买此装备</span>"),
                type: canAfford ? "warning" : "error",
                showCancelButton: canAfford,
                confirmButtonColor: confirmButtonColor,
                confirmButtonText: confirmButtonText,
                cancelButtonText: "取消",
                closeOnConfirm: false,
                showLoaderOnConfirm: canAfford
            }, function(isConfirm) {
                if (isConfirm && canAfford) {
                    document.getElementById('recallForm').submit();
                }
            });
        });
    }
}

// 获取用户金币余额
function getUserCashBalance(callback) {
    $.ajax({
        url: 'GetUserCash.asp',
        type: 'GET',
        success: function(data) {
            callback(data);
        },
        error: function() {
            callback('0');
        }
    });
}

// 公告板功能
(function() {
    // 配置
    var MB_ROWS = 5;
    var MB_COLS = 2;
    var MB_CELLS = MB_ROWS * MB_COLS;
    var BOARD_INTERVAL = 3000;
    var ONLINE_PULSE_MS = 7000;
    var ONLINE_REFETCH_MS = 60000;

    // 安装公告板
    function installMiniBoard() {
        var anchor = document.querySelector('.equipment-grid') || document.querySelector('.table-container');
        if (!anchor) return;
        if (document.getElementById('marketMiniBoard')) return;

        var wrap = document.createElement('div');
        wrap.id = 'marketMiniBoard';
        wrap.innerHTML = 
            '<div class="mb-head">' +
                '<div class="title">📣 动态公告</div>' +
                '<div class="online">' +
                    '<span class="online-label">在线勇士</span>' +
                    '<span class="online-chip">' +
                        '<span class="online-dot"></span>' +
                        '<span id="marketOnline" class="online-num">--</span>' +
                    '</span>' +
                '</div>' +
            '</div>' +
            '<div class="mb-grid" id="mbGrid"></div>';

        anchor.parentNode.insertBefore(wrap, anchor);

        // 生成格子
        var g = document.getElementById('mbGrid');
        for (var i = 0; i < MB_CELLS; i++) {
            var cell = document.createElement('div');
            cell.className = 'mb-item';
            cell.textContent = '加载中...';
            g.appendChild(cell);
        }
    }

    // 名字掩码
    function maskName(n) {
        n = (n || '').trim();
        if (!n) return '***';
        if (n.length <= 2) return n[0] + '*';
        return n[0] + Array(n.length - 1).join('*') + n[n.length - 1];
    }

    // 从卡片收集物品名
    function collectItems() {
        var arr = [];
        document.querySelectorAll('.item-card').forEach(function(card) {
            var nm = card.getAttribute('data-itemname');
            if (nm) arr.push(nm);
        });
        
        if (!arr.length) {
            arr = ['铁匠+9', '远古戒指', '黑曜石铠甲', '时光之靴', '大地之剑+9'];
        }
        return arr;
    }

    // 拿一位玩家名
    function pickPlayer() {
        var pool = window.__BOARD_PLAYERS || [];
        if (!pool.length) return '勇者***';
        var raw = pool[Math.floor(Math.random() * pool.length)];
        return maskName(raw);
    }

    // 生成一条公告文本
    function makeNotice() {
        var WEIGHTS = { enter: 40, view: 35, buy: 5, post: 5, leave: 25 };
        var sum = WEIGHTS.enter + WEIGHTS.view + WEIGHTS.buy + WEIGHTS.post + WEIGHTS.leave;
        var rnd = Math.random() * sum;
        var type = 'enter';
        
        if (rnd < WEIGHTS.enter) type = 'enter';
        else if (rnd < WEIGHTS.enter + WEIGHTS.view) type = 'view';
        else if (rnd < WEIGHTS.enter + WEIGHTS.view + WEIGHTS.buy) type = 'buy';
        else if (rnd < WEIGHTS.enter + WEIGHTS.view + WEIGHTS.buy + WEIGHTS.post) type = 'post';
        else type = 'leave';
        
        var players = window.__BOARD_PLAYERS || [];
        var name = players.length ? players[Math.floor(Math.random() * players.length)] : '勇者**';
        name = maskName(name);

        var items = collectItems();
        var item = items[Math.floor(Math.random() * items.length)];

        // 真实购买
        if (type === 'buy') {
            var buys = window.__BOARD_BUYS || [];
            if (buys.length) {
                var b = buys[Math.floor(Math.random() * buys.length)];
                name = maskName((b.name || '').trim());
                item = (b.item || item || '神秘装备');
            }
            return '玩家 <span class="mb-em">' + name + '</span> <span class="mb-act">购买了</span> <span class="mb-em">' + item + '</span> 真是可喜可贺啊!';
        }

        // 真实发布
        if (type === 'post') {
            var posts = window.__BOARD_POSTS || [];
            if (posts.length) {
                var p = posts[Math.floor(Math.random() * posts.length)];
                name = maskName((p.name || '').trim());
                item = (p.item || item || '神秘装备');
            }
            return '玩家 <span class="mb-em">' + name + '</span> <span class="mb-act">发布了</span> <span class="mb-em">' + item + '</span> 快来抢购吧!';
        }

        // 进入/浏览/离开
        if (type === 'enter') {
            return '玩家 <span class="mb-em">' + name + '</span> 进入了页面';
        } else if (type === 'view') {
            return '玩家 <span class="mb-em">' + name + '</span> 浏览了装备 <span class="mb-em">' + item + '</span>';
        } else {
            return '玩家 <span class="mb-em">' + name + '</span> 离开了页面';
        }
    }

    // 初始化格子内容
    function fillInitial() {
        var grid = document.getElementById('mbGrid');
        if (!grid) return;
        
        var cells = grid.children;
        for (var i = 0; i < cells.length; i++) {
            cells[i].innerHTML = makeNotice();
        }
    }

    // 每次更新一个随机格子
    function rotateOne() {
        var grid = document.getElementById('mbGrid');
        if (!grid) return;
        
        var cells = grid.children;
        if (!cells.length) return;
        
        var idx = Math.floor(Math.random() * cells.length);
        cells[idx].innerHTML = makeNotice();
    }

    // 在线人数逻辑
    var baseCount = 0,
        currentCount = 0,
        onlineTimer = null,
        refetchTimer = null;

    function timeFactor() {
        var h = new Date().getHours();
        if (h >= 19 && h < 23) return 1.15 + Math.random() * 0.05;
        if (h >= 14 && h < 18) return 1.10 + Math.random() * 0.05;
        if (h >= 11 && h < 14) return 1.05 + Math.random() * 0.05;
        if (h >= 8 && h < 11) return 1.00 + Math.random() * 0.05;
        if (h >= 0 && h < 6) return 0.90 + Math.random() * 0.05;
        return 0.98 + Math.random() * 0.04;
    }

    function jitter(count) {
        var d = Math.random() * 0.02;
        if (Math.random() < 0.5) d = -d;
        return Math.max(1, Math.round(count * (1 + d)));
    }

    function updateOnlineDisplay(val) {
        var el = document.getElementById('marketOnline');
        if (el) el.textContent = val;
    }

    function refetchOnline() {
        fetch('online_count.json?_=' + Date.now())
            .then(function(r) {
                return r.json();
            })
            .then(function(data) {
                if (!data || !data.market_count) return;
                baseCount = parseInt(data.market_count, 10) || 258;
                currentCount = Math.round(baseCount * timeFactor());
                updateOnlineDisplay(currentCount);
            })
            .catch(function() {
                if (!baseCount) baseCount = 258;
                currentCount = Math.round(baseCount * timeFactor());
                updateOnlineDisplay(currentCount);
            });
    }

    function startOnline() {
        refetchOnline();
        
        if (onlineTimer) clearInterval(onlineTimer);
        onlineTimer = setInterval(function() {
            currentCount = jitter(currentCount);
            updateOnlineDisplay(currentCount);
        }, ONLINE_PULSE_MS);
        
        if (refetchTimer) clearInterval(refetchTimer);
        refetchTimer = setInterval(refetchOnline, ONLINE_REFETCH_MS);
    }

    // 启动
    function initBoard() {
        installMiniBoard();
        fillInitial();
        startOnline();
        setInterval(rotateOne, BOARD_INTERVAL);
    }

    if (document.readyState === 'loading') {
        document.addEventListener('DOMContentLoaded', initBoard);
    } else {
        initBoard();
    }
})();







</script>

<style>
.action-btn {
    display: inline-block;
    padding: 6px 12px;
    background-color: #007bff;
    color: white;
    text-decoration: none;
    border: none;
    border-radius: 4px;
    font-size: 12px;
    cursor: pointer;
    transition: all 0.3s ease;
    text-align: center;
}

.action-btn:hover {
    background-color: #0056b3;
    color: white;
    text-decoration: none;
}

.action-btn.disabled, .action-btn:disabled {
    background-color: #6c757d;
    cursor: not-allowed;
    opacity: 0.6;
}

.action-btn.buy-btn {
    background-color: #28a745;
}

.action-btn.buy-btn:hover {
    background-color: #1e7e34;
}

.action-btn.sell-btn {
    background-color: #fd7e14;
}

.action-btn.sell-btn:hover {
    background-color: #e55a00;
}

.action-btn.exchange-btn {
    background-color: #6f42c1;
}

.action-btn.exchange-btn:hover {
    background-color: #533093;
}

.action-btn.gift-btn {
    background-color: #e83e8c;
}

.action-btn.gift-btn:hover {
    background-color: #d91a72;
}

/* 组标题与间隔 */ 
.gt-group-title { margin-top:8px; color:#9ca3af; font-weight:700; } .gt-gap { height:8px; } /* 数量 */ .gt-qty { color:#f1f5f9; } /* 属性颜色：1浅蓝、2深蓝、3紫、4金 */ .gt-attr-1 { color:#60a5fa; font-weight:700; } /* 浅蓝 */ .gt-attr-2 { color:#1d4ed8; font-weight:700; } /* 深蓝 */ .gt-attr-3 { color:#8b5cf6; font-weight:700; } /* 紫色 */ .gt-attr-4 { color:#f59e0b; font-weight:700; } /* 金色 */ .gt-attr-none { color:#94a3b8; } /* 镶嵌统一红色 */ .gt-socket, .gt-socket-none { color:#ef4444; font-weight:700; }


.market-topbar {
  display: flex;
  gap: 12px;
  align-items: stretch;
  margin: 12px 0 16px;
  padding: 10px 12px;
  background: linear-gradient(135deg, rgba(17,24,39,.85), rgba(31,41,55,.85));
  border: 1px solid rgba(255,255,255,.08);
  border-radius: 10px;
  box-shadow: 0 8px 20px rgba(0,0,0,.35);
}

/* 在线栏 */
.online-box {
  min-width: 240px;
  padding: 8px 12px;
  background: linear-gradient(135deg, rgba(34,197,94,.15), rgba(34,197,94,.06));
  border: 1px solid rgba(34,197,94,.35);
  border-radius: 8px;
  color: #d1fae5;
  font-weight: 700;
  display: flex;
  align-items: center;
  gap: 10px;
}
.online-dot {
  width: 10px; height: 10px; border-radius: 50%;
  background: #22c55e;
  box-shadow: 0 0 12px rgba(34,197,94,.7);
  animation: odPulse 1.8s infinite ease-in-out;
}
@keyframes odPulse { 0%,100%{transform:scale(1);opacity:1} 50%{transform:scale(1.25);opacity:.8} }
.online-num { font-size: 18px; font-weight: 900; color: #ecfccb; text-shadow: 0 1px 0 rgba(0,0,0,.4); }

/* 公告板区域变“表格” */
.board {
  flex: 1;
  display: flex;
  flex-direction: column;
  gap: 6px;
  padding-left: 12px;
  border-left: 1px dashed rgba(255,255,255,.08);
}

/* 表头 */
.board-head {
  display: grid;
  grid-template-columns: 100px 1fr;
  gap: 8px;
  padding: 8px 12px;
  background: linear-gradient(135deg, rgba(59,130,246,.12), rgba(99,102,241,.08));
  border: 1px solid rgba(255,255,255,.1);
  border-radius: 8px;
  color: #c7d2fe;
  font-weight: 800;
  letter-spacing: .3px;
}
.board-head .col-time { text-align: left; }
.board-head .col-msg  { text-align: left; }

/* 表体 */
.board-table {
  display: block;
  border: 1px solid rgba(255,255,255,.08);
  border-radius: 8px;
  overflow: hidden;
  background: rgba(0,0,0,.15);
}
.board-list {
  list-style: none;
  margin: 0;
  padding: 0;
}
.board-item {
  display: grid;
  grid-template-columns: 100px 1fr;
  gap: 8px;
  padding: 8px 12px;
  align-items: center;
  border-bottom: 1px solid rgba(255,255,255,.06);
  background: rgba(255,255,255,.02);
  transition: background .2s ease, transform .2s ease, opacity .2s ease;
}
.board-item:nth-child(odd)  { background: rgba(255,255,255,.015); }
.board-item:nth-child(even) { background: rgba(255,255,255,.03); }
.board-item:hover { background: rgba(59,130,246,.08); }

.board-time {
  font-size: 12px;
  color: #9ca3af;
  background: rgba(255,255,255,.06);
  border: 1px solid rgba(255,255,255,.1);
  padding: 2px 8px;
  border-radius: 9999px;
  justify-self: start;
}
.board-msg {
  color: #e5e7eb;
  display: flex;
  align-items: center;
  gap: 6px;
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
}

/* 高亮关键字 */
.board-em  { font-weight: 800; color: #93c5fd; }
.board-act { font-weight: 800; color: #fcd34d; }

/* 出场动画（可选） */
.board-item.hide   { transform: translateY(-6px); opacity: 0; }
.board-item.ready  { transform: translateY(0);    opacity: 1; }



    .lottery-wrap {
            margin: 20px 0;
            padding: 16px;
            border: 1px solid #eee;
            border-radius: 8px;
            background: #fff7ed;
        }

        .lottery-header {
            font-weight: 700;
            margin-bottom: 8px;
        }

        .lottery-meta {
            font-size: 13px;
            color: #7a3e00;
            margin-bottom: 10px;
        }

        .lottery-stage {
            display: flex;
            align-items: center;
            gap: 16px;
        }

        .wheel-wrap {
            position: relative;
            width: 380px;
            height: 380px;
        }

        #wheel {
            border-radius: 50%;
            border: 6px solid #ffcf76;
            background: #ffe9c2;
            box-shadow: 0 2px 10px rgba(0, 0, 0, .06);
        }

        .pointer {
            position: absolute;
            left: 50%;
            transform: translateX(-50%);
            top: -6px;
            width: 0;
            height: 0;
            border-left: 12px solid transparent;
            border-right: 12px solid transparent;
            border-bottom: 20px solid #ff5a00;
        }

        .lottery-btn {
            padding: 10px 14px;
            background: #ff8c31;
            color: #fff;
            border: 0;
            border-radius: 6px;
            cursor: pointer;
        }

        .lottery-btn:disabled {
            opacity: .7;
            cursor: not-allowed;
        }

        .lottery-tip {
            font-size: 12px;
            color: #a66a00;
            margin-top: 8px;
        }



/* 礼包容器样式 */
.gift-container {
  max-width: 900px;
  margin: 0 auto;
  padding: 20px;
  font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
}

.gift-header {
  text-align: center;
  color: #2c3e50;
  margin-bottom: 20px;
  font-size: 28px;
  text-shadow: 1px 1px 2px rgba(0,0,0,0.1);
}

.gift-notice {
  background: #f8f9fa;
  border-left: 4px solid #3498db;
  padding: 15px;
  margin-bottom: 25px;
  border-radius: 0 5px 5px 0;
}

.gift-notice ul {
  margin: 10px 0 0 20px;
}

.gift-notice li {
  margin-bottom: 8px;
  color: #555;
}

/* 礼包卡片样式 */
.gift-card {
  background: white;
  border-radius: 12px;
  box-shadow: 0 4px 15px rgba(0,0,0,0.08);
  margin-bottom: 20px;
  overflow: hidden;
  transition: transform 0.3s ease, box-shadow 0.3s ease;
  border: 1px solid #e0e0e0;
}

.gift-card:hover {
  transform: translateY(-5px);
  box-shadow: 0 8px 25px rgba(0,0,0,0.12);
}

.gift-card-header {
  background: linear-gradient(135deg, #3498db, #2980b9);
  color: white;
  padding: 15px 20px;
}

.gift-title {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 10px;
}

.gift-number {
  font-size: 20px;
  font-weight: bold;
}

.gift-status {
  padding: 5px 12px;
  border-radius: 20px;
  font-size: 14px;
  font-weight: bold;
}

.gift-status.available {
  background: #2ecc71;
  color: white;
}

.gift-status.claimed {
  background: #95a5a6;
  color: white;
}

.gift-status.level-locked, 
.gift-status.upgrade-locked, 
.gift-status.time-locked {
  background: #e74c3c;
  color: white;
}

.gift-requirements {
  display: flex;
  flex-wrap: wrap;
  gap: 15px;
  font-size: 14px;
}

.req-item {
  display: flex;
  align-items: center;
  gap: 5px;
  opacity: 0.9;
}

.gift-content {
  padding: 20px;
}

.gift-content h4 {
  margin-top: 0;
  color: #2c3e50;
  border-bottom: 1px dashed #ddd;
  padding-bottom: 10px;
  margin-bottom: 15px;
}



.item-icon {
  font-size: 16px;
  margin-right: 10px;
}


.item-amount {
  font-weight: bold;
  color: #09f363;
  background: rgba(52, 152, 219, 0.1);
  padding: 2px 8px;
  border-radius: 12px;
  font-size: 14px;
}

.gift-footer {
  padding: 15px 20px;
  background: #f8f9fa;
  text-align: center;
  border-top: 1px solid #eee;
}

.gift-claim-btn {
  display: inline-block;
  background: linear-gradient(135deg, #2ecc71, #27ae60);
  color: white;
  border: none;
  padding: 12px 30px;
  border-radius: 30px;
  font-weight: bold;
  font-size: 16px;
  cursor: pointer;
  transition: all 0.3s ease;
  text-decoration: none;
}

.gift-claim-btn:hover:not(.disabled) {
  background: linear-gradient(135deg, #27ae60, #229954);
  transform: scale(1.05);
}

.gift-claim-btn.disabled {
  background: #bdc3c7;
  cursor: not-allowed;
  transform: none;
}

/* 响应式设计 */
@media (max-width: 768px) {
  .gift-requirements {
    flex-direction: column;
    gap: 8px;
  }
  
  .gift-items {
    flex-direction: column;
  }
  

  
  .gift-title {
    flex-direction: column;
    align-items: flex-start;
    gap: 10px;
  }
}
</style>

