<!--#include file="inc/conn.asp" -->
<%
If Request.ServerVariables("REQUEST_METHOD") = "POST" Then
    Dim newCount
    newCount = Request.Form("new_count")
    
    If IsNumeric(newCount) Then
        ' 更新JSON文件
        Dim jsonContent, fs, file
        jsonContent = "{" & vbCrLf & _
                      "    ""base_count"": " & newCount & "," & vbCrLf & _
                      "    ""last_updated"": """ & Now() & """," & vbCrLf & _
                      "    ""description"": ""在线人数基准值，系统会根据时间段自动调整""" & vbCrLf & _
                      "}"
        
        Set fs = Server.CreateObject("Scripting.FileSystemObject")
        Set file = fs.CreateTextFile(Server.MapPath("online_count.json"), True)
        file.Write jsonContent
        file.Close
        Set file = Nothing
        Set fs = Nothing
        
        Response.Write "<script>alert('在线人数基准值已更新为 " & newCount & "');</script>"
    End If
End If

' 读取当前值
Dim currentCount, fs, file, jsonText
currentCount = 158

On Error Resume Next
Set fs = Server.CreateObject("Scripting.FileSystemObject")
If fs.FileExists(Server.MapPath("online_count.json")) Then
    Set file = fs.OpenTextFile(Server.MapPath("online_count.json"), 1)
    jsonText = file.ReadAll
    file.Close
    
    ' 简单解析JSON获取base_count
    Dim baseCountMatch
    Set baseCountMatch = New RegExp
    baseCountMatch.Pattern = """base_count"":\s*(\d+)"
    baseCountMatch.Global = False
    Dim matches
    Set matches = baseCountMatch.Execute(jsonText)
    If matches.Count > 0 Then
        currentCount = matches(0).SubMatches(0)
    End If
End If
Set file = Nothing
Set fs = Nothing
On Error Goto 0
%>
<!DOCTYPE html>
<html>
<head>
    <title>在线人数管理</title>
    <meta http-equiv="Content-Type" content="text/html; charset=UTF-8" />
    <style>
        body { font-family: Arial; padding: 20px; background: #f5f5f5; }
        .container { max-width: 500px; margin: 0 auto; background: white; padding: 20px; border-radius: 8px; }
        h1 { color: #333; text-align: center; }
        .form-group { margin: 15px 0; }
        label { display: block; margin-bottom: 5px; font-weight: bold; }
        input { width: 100%; padding: 8px; border: 1px solid #ddd; border-radius: 4px; }
        button { background: #007bff; color: white; border: none; padding: 10px 20px; border-radius: 4px; cursor: pointer; }
        .info { background: #e7f3ff; padding: 10px; border-radius: 4px; margin: 10px 0; }
    </style>
</head>
<body>
    <div class="container">
        <h1>📊 在线人数管理</h1>
        
        <div class="info">
            <strong>当前基准值:</strong> <%=currentCount%><br>
            <strong>说明:</strong> 系统会根据时间段自动调整实际显示人数
        </div>
        
        <form method="post">
            <div class="form-group">
                <label for="new_count">新的基准值:</label>
                <input type="number" id="new_count" name="new_count" value="<%=currentCount%>" min="1" max="9999" required>
            </div>
            <button type="submit">更新基准值</button>
        </form>
        
        <div style="margin-top: 20px; font-size: 0.9em; color: #666;">
            <strong>时间段调整规则:</strong><br>
            - 凌晨 (0-6点): -10%<br>
            - 上午 (8-11点): +5%<br>
            - 中午 (11-14点): +10%<br>
            - 下午 (14-18点): +15%<br>
            - 晚上 (19-23点): +20%<br>
            - 其他时间: 基准值
        </div>
    </div>
</body>
</html>