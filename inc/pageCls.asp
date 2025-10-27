<%
Const Btn_First = "<font face=webdings>9</font>" '定义首页显示样式
Const Btn_Prev = "<font face=webdings>7</font>" '定义前*页显示样式
Const Btn_Next = "<font face=webdings>8</font>" '定义下*页显示样式
Const Btn_Last = "<font face=webdings>:</font>" '定义未页显示样式
Const TD_Align = "right" '定义分页信息对齐方式
Const TD_Width = "100%" '定义分页信息框大小

Class pageShow
    Private HY_Conn, HY_Rs, HY_SQL, HY_PageSize, HY_ListNum, str_Error, Int_curpage, Int_totalPage, Int_totalRecord

    '============================================
    'PageSize 属性
    '设置每一页的分页大小
    '============================================

    Public Property Let PageSize(int_PageSize)
        If IsNumeric(Int_Pagesize) Then
            HY_PageSize = CLng(int_PageSize)
        Else
            HY_PageSize = 10 '参数有错，则默认为10
        End If
    End Property

    '得到PageSize 属性

    Public Property Get PageSize
        PageSize = HY_PageSize
    End Property

    '============================================
    'ListNum 属性
    '设置分页数字导航条字数
    '============================================

    Public Property Let ListNum(int_ListNum)
        If IsNumeric(Int_ListNum) Then
            HY_ListNum = CLng(Int_ListNum)
        Else
            HY_ListNum = 10 '参数有错，则默认为10
        End If
    End Property

    '得到ListNum 属性

    Public Property Get ListNum
        ListNum = HY_ListNum
    End Property

    '============================================
    'IsReady 属性
    '得到记录集数组是否可用
    '============================================

    Public Property Get IsReady
        If Int_totalRecord>0 Then
            IsReady = True
        Else
            IsReady = False
        End If
    End Property

    '============================================
    'GetRsArray 属性
    '返回分页后的记录集数组
    '============================================

    Public Property Get GetRs()
        Set HY_Rs = Server.CreateObject("adodb.recordset")
        HY_Rs.PageSize = HY_PageSize
        HY_Rs.Open HY_SQL, HY_Conn, 1, 1
        int_totalRecord = HY_Rs.recordcount
        If Not HY_Rs.EOF Then
            If Int_curpage > HY_Rs.PageCount Then Int_cutpage = HY_Rs.PageCount
            HY_Rs.AbsolutePage = int_curpage
        End If
        Set GetRs = HY_Rs '返回记录
    End Property

    '=====================================
    'GetConn  得到数据库连接'
    '=====================================

    Public Property Let GetConn(obj_Conn)
        Set HY_Conn = obj_Conn
    End Property

    '====================================
    'GetProcName   得到存储过程名'
    '====================================

    Public Property Let GetSQL(str_sql)
        HY_SQL = str_sql
    End Property

    '=====================================
    'Class_Initialize 类的初始化
    '初始化当前页的值'
    '=====================================

    Private Sub Class_Initialize
        '============================
        '设定一些参数的黙认值
        '============================
        HY_PageSize = 10 'pagesize属性，默认为10
        HY_ListNum = 10 '数字导航条默认显示10个数字
        '如:1 2 3 4 5 ...... 10
        '============================
        '获取当前页的值
        '============================
        Int_curpage = Trim(request("page"))
        If Int_curpage = "" Then
            Int_curpage = 1
        ElseIf Not(IsNumeric(Int_curpage)) Then
            int_curpage = 1
        ElseIf CLng(Int_curpage)<1 Then
            int_curpage = 1
        Else
            Int_curpage = CLng(Int_curpage)
        End If

    End Sub

    '==============================
    '得到当前页数
    '==============================

    Public Property Get curPage
        curPage = Int_curpage
    End Property

    '==============================
    '得到总页数
    '==============================

    Public Property Get Get_TotalPage
        Get_TotalPage = int_TotalPage
    End Property

    '==============================
    '得到总记录数
    '==============================

    Public Property Get Get_TotalRecord
        Get_TotalRecord = Int_totalRecord
    End Property


    '===========================================
    'pageNav  创建分页导航条
    '有首页、前一页、下一页、末页、还有数字导航'
    '===========================================

    Public Sub pageNav()
        Dim str_tmp, p, Url
        Url = GetUrl

        If int_totalRecord Mod HY_PageSize = 0 Then
            int_TotalPage = int_totalRecord \ HY_PageSize
        Else
            int_TotalPage = int_totalRecord \ HY_PageSize+1
        End If

        If Int_curpage>int_Totalpage Then
            int_curpage = int_TotalPage
        End If
        If Int_curPage -1 Mod HY_ListNum = 0 Then
            p = (Int_curPage -1) \ HY_ListNum
        Else
            p = (Int_curPage -1) \ HY_ListNum
        End If

        '===========================================
        '显示分页信息，各个模块根据自己要求更改显求位置
        '===========================================
        response.Write "<table border=0  width="&TD_Width&"><tr><td align="&TD_Align&">"
        str_tmp = pageNavInfo(Url, p)
        response.Write str_tmp
        response.Write "</td></tr></table>"

    End Sub

    '==========================================
    'pageNavInfo  分页信息
    '更据要求自行修改'
    '==========================================

    Private Function pageNavInfo(Url, p)
        Dim str_tmp, i
        'str_tmp="页次:"&int_curpage&"/"&int_totalpage&"页 共"&int_totalrecord&"记录 "&HY_PageSize&"条/页 "
        'str_tmp="页次:"&int_curpage&"/"&int_totalpage&"页 "&HY_PageSize&"条/页 "
        ' 显示首页、前**页
        '===============
        If Int_curPage = 1 Then
            str_tmp = str_tmp&Btn_First&" "
        Else
            str_tmp = str_tmp & "<a href='"&Url&"1' title=首页>"&Btn_First&"</a> "
        End If
        If p * HY_ListNum>0 Then str_tmp = str_tmp & "<a href='"&Url&(p * HY_ListNum)&"' title=上"&HY_ListNum&"页>"&Btn_Prev&"</a> "

        ' 数字导航
        '=========
        For i = p * HY_ListNum + 1 To (P + 1) * HY_ListNum
            If i = Int_curPage Then
                str_tmp = str_tmp&"<font color=red>"&i&"</font> "
            Else
                str_tmp = str_tmp&"<a href='"&Url&i&"'>"&i&"</a> "
            End If
            If i = int_TotalPage Then Exit For
        Next
        'ShowNextLast  下**页、末页
        '=========================
        If i<int_TotalPage Then str_tmp = str_tmp&"<a href='"&Url&i&"' title=下"&HY_ListNum&"页>"&Btn_Next&"</a> "
        If Int_curPage = int_TotalPage Then
            str_tmp = str_tmp&Btn_Last
        Else
            str_tmp = str_tmp&"<a href='"&Url&int_TotalPage&"' title=尾页>"&Btn_Last&"</a>"
        End If
        str_tmp = str_tmp & " 页次:"&Int_curPage&"/"&int_TotalPage&" 共"&int_TotalRecord&"个记录 "&HY_PageSize&"个/页"
        pageNavInfo = str_tmp
    End Function

    '=========================================
    'GetURL  得到当前的URL参数
    '更据URL参数不同，获取不同的结果'
    '=========================================

    Private Function GetURL()
        Dim j, result_url, str_params
        Const search_str = "page="

        str_params = Request.ServerVariables("QUERY_STRING")
        If str_params = "" Then
            result_url = "?page="
        Else
            If InstrRev(str_params, search_str) = 0 Then
                result_url = "?" & str_params &"&page="
            Else
                j = InstrRev(str_params, search_str) -2
                If j = -1 Then
                    result_url = "?page="
                Else
                    str_params = Left(str_params, j)
                    result_url = "?" & str_params &"&page="
                End If
            End If
        End If

        GetURL = result_url

    End Function

    '=======================================
    ' 设置 Terminate 事件。'
    '=======================================

    Private Sub Class_Terminate
        HY_Rs.Close
        Set HY_Rs = Nothing
    End Sub

    '=======================================
    'ShowError  错误提示'
    '=======================================

    Private Sub ShowError()
        If str_Error <> "" Then
            Response.Write("<font color=""#FF0000""><br><b>" & SW_Error & "</font>")
            Response.End
        End If
    End Sub

End Class
%>
