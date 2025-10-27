<%
'//---------------------------------------------------------------------------
'//ASP 分页引擎 (PageClass v1.2)
'//
'//作者：362220083@qq.com(Xc)
'//时间：2010年12月20日，修改：11:34 2010-12-22 目的：修复Int溢出、调整获取总数方式。
'//声明：本类允许转载、复制和修改，但转载、复制和修改的同时请保留原始的出处和作者声明，这也是对作者劳动成果的一种尊重！
'//如果您对本类进行修改，希望您也可以给我发一份您修改过后的类(362220083@qq.com)
'//---------------------------------------------------------------------------
Class PageClass

'//--- 声明
Private m_StartTime,m_Version
Private m_rs,m_rs_ID,m_rs_Count,m_rs_Count_Flg
Private m_PageSize,m_PageCount,m_PageID
Private m_PageStr,m_PageURL,m_PageURLID
Private m_EOF

'//--- 类初始化
Private Sub Class_Initialize()
  m_StartTime         = Timer()
  m_Version           = "1.0"
  Set m_rs            = Server.CreateObject("ADODB.Recordset")
  m_rs_ID             = 0
  m_rs_Count          = 0
  m_rs_Count_Flg      = False
  m_PageSize          = 1
  m_PageCount         = 1
  m_PageID            = 1
  m_PageStr           = "p"
  m_PageURL           = ""
  m_PageURLID         = "{PageNum}"
  m_EOF               = True
End Sub

'//--- 类销毁
Private Sub Class_Terminate()
  m_StartTime         = 0
  m_Version           = ""
  m_rs.Close()
  Set m_rs            = Nothing
  m_rs_ID             = 0
  m_PageSize          = 0
  m_PageCount         = 0
  m_PageID            = 0
  m_PageStr           = ""
  m_PageURL           = ""
  m_EOF               = False
End Sub


'//************** 内部函数、方法
Private Function iif(a,b,c)
  If a Then iif=b Else iif=c End IF
End Function

Private Sub CheckEOF()
  m_EOF=m_rs.EOF
End Sub

Private Sub CheckQuery()
  Dim str
  m_PageURL="?"
  For Each str In Request.QueryString()
    If Not LCase(str)=LCase(m_PageStr) Then
      m_PageURL=m_PageURL & str & "=" & Request.QueryString(str) & "&"
    End If
  Next
  m_PageURL=m_PageURL & m_PageStr & "=" & m_PageURLID
End Sub

Private Function A(ByRef url,ByRef dec)
  Dim a_Str
  a_Str="<a class=""num"" href=""{@URL}"">{@DEC}</a>"
  A=Replace(Replace(a_Str,"{@URL}",url),"{@DEC}",dec)
End Function


'//************** 公开属性、方法

'//--- 设置数据源，传递的参数必须是Recordset
Public Property Let rs(ByRef val)
  If Not TypeName(val)="Recordset" Then
    Exit Property
  End If
  Set m_rs=val.Clone
  val.Close
  CheckEOF()
End Property

'//--- 设置页面记录数
Public Property Let PageSize(ByRef val)
  If val>0 Then
    m_PageSize=val
  End If
End Property

'//--- 设置总记录数（获取总记录数的方式）
Public Property Let setCount(ByRef val)
  Select Case TypeName(val)
    Case "String"
      m_rs_Count=m_rs.ActiveConnection.Execute(val)(0)
    Case "Integer","Long"
      If val=0 Then
        m_rs_Count=m_rs.RecordCount
      ElseIf val<0 Then
        Dim regEx,sql
        Set regEx = New RegExp
          regEx.Global     = True
          regEx.IgnoreCase = True
          regEx.Pattern = "(Select)([^From]*)([\s\S]*)"
        sql=regEx.Replace(m_rs.Source,"$1 Count(*) $3")
          regEx.Pattern = "([^order]*)(order\s*by\s*[^\s]*\s*[asc|desc]*)(\s*[,]?\s*[^\s]?\s*[asc|desc]?)*([\)]*)$"
        sql=regEx.Replace(sql,"$1$4")
        Set regEx = Nothing
        m_rs_Count=m_rs.ActiveConnection.Execute(sql)(0)
      ElseIf val>0 Then
        m_rs_Count=val
      End If
  End Select
  m_rs_Count_Flg=True
End Property

'//--- 设置分页参数（同时进行分页处理）
Public Property Let PageID(ByRef val)
  Select Case TypeName(val)
    Case "String"
      m_PageStr=val
      m_PageID=CLng("0" & Request.QueryString(val))
      CheckQuery()
    Case Else
      Exit Property
  End Select
  '//总记录数
  If Not m_rs_Count_Flg Then
    setCount=-1
  End If
  '//总页数
  m_PageCount=iif((m_rs_Count Mod m_PageSize), Int(m_rs_Count/m_PageSize)+1, Int(m_rs_Count/m_PageSize))
  '//当前页
  If m_PageID<1 Then
    m_PageID=1
  ElseIf m_PageID>m_PageCount Then
    m_PageID=m_PageCount
  End If
  '//数据集移动指针
  MoveFirst()
End Property

'//--- 返回数据集BOF标志（True：到达数据集开头）
Public Property Get BOF()
  BOF=m_rs.BOF
End Property

'//--- 返回数据集EOF标志（True：到达数据集结尾）
Public Property Get EOF()
  EOF=m_EOF
End Property

'//--- 设置数据集EOF标志（私有）
Private Property Let EOF(ByRef val)
  m_EOF=val
End Property

'//--- 设置数据集移动指针（如果到达该页的结尾，修改EOF标志）
Public Property Get MoveFirst()
  If m_rs.BOF Then
    Exit Property
  End If
  m_rs.Move (m_PageID-1)*m_PageSize,1
  m_rs_ID=0
  CheckEOF()
End Property

Public Property Get MoveNext()
  m_rs.MoveNext
  CheckEOF()
  m_rs_ID=m_rs_ID + 1
  If m_rs_ID>=m_PageSize Then
    EOF=True
  End If
End Property

'//--- 返回当前记录的字段（默认）
Public Default Property Get Fields(ByRef val)
  Fields = m_rs(val)
End Property

'//--- 返回页面的数据(数组形式)
Public Property Get GetRows()
  If m_rs_ID>0 Then
    MoveFirst()
  End If
  If m_rs.BOF Then
    Exit Property
  End If
  GetRows=m_rs.GetRows(m_PageSize)
End Property

'//--- 设置分页导航的基础URL（可选）
Public Property Let PageURL(ByRef val)
  If InStr(val,m_PageURLID)>0 Then
    m_PageURL=val
  End If
End Property

'//--- 返回分页导航（参数：val是导航控制按钮数，style是显示内容【{Ctrl}、{State}、{Select}】）
Public Property Get Control(ByRef val,ByVal style)
  Dim p_id,p_sum,p_url,p_str,p_count,re
  p_id    = m_PageID
  p_sum   = m_PageCount
  p_url   = m_PageURL
  p_str   = m_PageStr
  p_count = m_rs_Count

  Dim i,j
  
  If p_id=1 Then
    re=""
  Else
    re=A(Replace(p_url,m_PageURLID,"")," << ")
    re=re & A(Replace(p_url,m_PageURLID,p_id-1)," < ")
  End If

  If p_id<val Then
    j=0
    For i=1 To val
      If Not ((j+i)<1 or (j+i)>p_sum) Then
        If (j+i)=p_id Then
          re=re & " <span class=""current"">" & j+i & "</span>"
        Else
          re=re & A(Replace(p_url,m_PageURLID,j+i)," " & j+i & " ")
        End If
      End If
    Next
  Else
    j=p_id - val\2 - 1
    For i=1 To val
      If Not ((j+i)<1 or (j+i)>p_sum) Then
        If (j+i)=p_id Then
          re=re & " <span class=""current"">" & j+i & "</span>"
        Else
          re=re & A(Replace(p_url,m_PageURLID,j+i)," " & j+i & " ")
        End If
      End If
    Next
  End If

  If p_id=p_sum Then
    re=re
  Else
    re=re & A(Replace(p_url,m_PageURLID,p_id+1)," > ")
    re=re & A(Replace(p_url,m_PageURLID,p_sum)," >> ")
  End If

  style=Replace(style,"{Ctrl}",re & vbCrlf)

  re=""
  re="共" & p_sum & "页/" & p_count & "条"
  style=Replace(style,"{State}",re & vbCrlf)

 Control=style
End Property

Public Property Get PageID
	PageID=m_PageID
End Property

Public Property Get PageCount
	PageCount=m_PageCount
End Property

Public Property Get PageStr
	PageStr=m_PageStr
End Property

Public Property Get Count
	Count=m_rs_Count
End Property
End Class
%>