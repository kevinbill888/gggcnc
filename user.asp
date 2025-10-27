<!--#include file="inc/conn.asp" -->
<!--#include file="head.asp" -->
<!--#include file="inc/char.asp" -->
<!--#include file="inc/md5.asp" -->
<%
pageLink=lcase(Request.ServerVariables("QUERY_STRING"))
HTTP_url=Request.ServerVariables("HTTP_url")

Action = Request("Action")
Action2 = Request("Action2")
Action3 = Request("Action3")



Select Case Action2
	Case"ChangeJob"
		strtitle2="变更职业"
	 Case "PK"
		strtitle2="清洗红名"
     Case "Move"
		strtitle2="卡号自救"
     Case "Upgrade"
		strtitle2="角色转生"
	Case Else 
		strtitle2="角色详情"
End Select

Select Case Action
     Case "Reg" 
		strtitle="注册账号"
     Case "RegMobile" 
		strtitle="手机激活"
	Case "Modify" 
		strtitle="修改资料"
	Case "Down" 
		strtitle="客户端下载"
	Case"ChangeJob"
		strtitle="改变职业"
	Case"GetPwd"
		strtitle="取回密码"
	Case"NewsList"
		strtitle="新闻公告"
	 Case "PK"
		strtitle="清洗红名"
     Case "Move"
		strtitle="卡号自救"
	Case "Agree"
		strtitle="注册账号"
	Case "Upgrade"
		strtitle="角色转生"
    Case Else '注册
		strtitle="登录"
End Select

%>
        <!-- END: Navbar Mobile -->
        <div class="nk-main">
            <!-- START: Breadcrumbs -->
            <div class="nk-gap-1"></div>
            <div class="container">
                <ul class="nk-breadcrumbs">
                    <li><span style="letter-spacing: 6px;">首页-用户中心-<%If strtitle2<>"" Then Response.write strtitle2 Else Response.write strtitle End If %></span></li>
                </ul>
            </div>
            <div class="nk-gap-1"></div>
            <!-- END: Breadcrumbs -->
            <div class="container">
              
                <div class="nk-gap-2"></div>
                <div class="row vertical-gap">
                    <div class="col-lg-8 main-content-container">
		                 <!-- START: Products -->
                        <div class="row vertical-gap" style="padding-top:30px; padding-left:20px;padding-bottom:20px;">
					<%
Select Case Action
    Case "UserLogin"
        UserLogin()
     Case "Reg" 
        Reg()
		strtitle="注册账号"
     Case "RegMobile" 
        RegMobile()
		strtitle="手机激活"
	Case "Modify" 
        Modify()
		strtitle="修改资料"
	Case "Down" 
        Down()
		strtitle="客户端下载"
	Case"ChangeJob"
        ChangeJob()
		strtitle="改变职业"
	Case"GetPwd"
        GetPwd()
		strtitle="取回密码"
	Case"NewsList"
        NewsList()
		strtitle="新闻公告"
	 Case "PK"
		PK()
		strtitle="清洗红名"
     Case "Move"
		Move()
		strtitle="卡号自救"
	Case "Agree"
		Agree()
		strtitle="注册账号"
	Case "Upgrade"
		Upgrade()
		strtitle="角色转生"
		
		
    Case Else '注册
        Main()
		strtitle="用户中心"
End Select


Sub Down()
%>
</p>   <!-- 客户端下载中心 -->

                   <div class="main-bd">
					<div class="ui-column fn-cf">
						 <span class="on">客户端下载</span>
					</div>


                          <div class="client-down fl"  style="margin-left:20px;margin-top:20px">
                            <h2><i>	<img  style="margin-bottom:0px;" src="static/image/down1.png"></i>最新完整客户端下载</h2>
                            <p class="con-p">
                              更新时间：<span class="color" id="update_date">2016-06-02</span>     当前版本：<span class="color" id="version">V3.5</span>  <br> 文件大小：<span class="color" id="size">1.90GB</span>  <br>md5码：<span id="md5"> 2560a4b1020b1b3be5011c99163686c8</span>
                          </p>
                          <h3 class="con-title-2">下载说明：</h3>
                          <p class="con-p">
                              1、由于文件较大，我们建议玩家使用迅雷等下载工具下载。<br>
                              2、完整客户端包含登录器，下载完整客户端的玩家无需下载登录器。<br>
                              3、如遇安装文件无法运行或无法正常游戏等问题，请联系客服。
                          </p>
                      </div>


                      <div class="download_btn fn-cf"  style="margin-left:20px;margin-top:20px">
					  

                        <a  class="nk-product-image" href="http://218.93.207.159:9001/wztz3.5.exe" target="_blank" class="fn-fl" style="margin-bottom:20px;margin-top:30px;"><img id="dkimg"  width="285" height="70" alt="3.5版完整客户端下载" src="static/image/download_btn2.jpg"></a>
                        <a href="http://pan.baidu.com/s/1kVAjku7" target="_blank" class="fn-fl" style="margin-bottom:20px;"><img id="dkimg2"  width="285" height="70" alt="3.5版完整客户端下载" src="static/image/download_btn3.jpg"></a>
                        <a href="https://yunpan.cn/cSVkzCfDUjux9" target="_blank" class="fn-fl" style="margin-bottom:20px;"><img id="dkimg3" width="285" height="70" alt="3.5版完整客户端下载" src="static/image/download_btn4.jpg"></a>
						<span id="md5">360云盘提取密码： (  <font color="#cc0000"><strong>4e7a</strong></font> )
                    </div>


					<div class="ui-column fn-cf" style="margin-top:50px;">
						<span class="on">游戏补丁下载</span>
					</div>


                          <div class="client-down fl"  style="margin-left:20px;margin-top:20px">
                            <h2><i>	<img  style="margin-bottom:0px;" src="static/image/down2.png"></i>暂未开放补丁包下载</h2>
                            <p class="con-p">
                              更新时间：<span class="color" id="update_date">2016-06-02</span>     当前版本：<span class="color" id="version">V1.0.228</span>  <br> 文件大小：<span class="color" id="size">76mn</span>  <br>MD5码：<span id="md5">2560a4b1020b1b3be5011c99163686c8</span>
                          </p>
                          <h3 class="con-title-2">下载说明：</h3>
                          <p class="con-p">
                              1、如遇更新缓慢等问题请尝试使用本补丁包。<br>
                              2、如遇游戏异常请尝试使用本补丁包。<br>
                              3、本补丁包含登录器。
                          </p>
                      </div>


                      <div class="download_btn fn-cf"  style="margin-left:20px;margin-top:20px">
                        <span class="fn-fl" style="margin-bottom:30px;margin-top:30px;"><img  src="static/image/download_btn1.jpg"></span>
                    </div>
                    <div class="clb"></div>
                </div>
<%
End Sub
Sub Agree()
%>


<div class="notibar announcement">
<h3>请仔细阅读下面的协议。</h3>
 <p>1、乱世大区之后将采用通行证的方式,一号通全服,以后无需再注册。</p>
 <p>2、乱世大区账号采用手机验证的方式注册,请务必填写真实有效的手机号,否则无法注册。</p>
</div>

		
		
			<div class="column" style="display: inline-block;box-sizing: border-box;">                <a href="User.asp?Action=Reg&DKServer=1"><img id="dkimg" width="350" height="270" src="static/image/s_01.jpg" alt="" border="0"></a>
              <div class="game-name">《乱世大区》即将开放</div></div>
					<div class="column" style="display: inline-block;box-sizing: border-box;">			<a href="User.asp?Action=Reg&DKServer=2"><img id="dkimg2" width="350" height="270" src="static/image/s_02.jpg" alt="" border="0"></a>
              <div class="game-name">《赤焰老区》公益区</div></div>


  <%
End Sub


Sub Reg()
If enableReg<>1 Then 
	Response.Write "<script>swal({title: ""错误!"",text: ""系统暂时不开放注册，请联系管理员!"",type: ""error"",}, function() {history.go(-1);});</script>"
	response.End
End If 
%>  
	


  	<div class="notibar announcement">
    <h4>您将要注册<%=ServerName%>通行证。</h4>
    <p>1、网通挑战通行证适用于<%=ServerName%>之后的所有大区,全区通用无需重复注册。</p>
    <p>2、请务必填写真实有效的手机号,每个手机号码最多可注册10个账号。</p>
	  </div>
	  <form  class="" id="register" method="post" action="UserCore.asp?Action=RegSave">
            <table width="680" class="basic" style="table-layout:fixed; background-color: #fff;margin-left:15px;">
                <tr>
                    <td style="width:100px;"><strong>用户名：</strong></td>
                    <td style="width:300px;"><input type="text" class="form-control un" placeholder="例如：wztz888" name="user" ajaxurl="inc/check.asp" datatype="s5-16" nullmsg="请输入您的用户名！" errormsg="用户名至少5个字符,最多16个字符！">
                   </td>
                    <td>
                    	<div class="Validform_checktip"></div>
                        <div class="info">用户名至少5个字符,最多16个字符<span class="dec"><s class="dec1">&#9670;</s><s class="dec2">&#9670;</s></span></div>
                    </td>
                </tr>
                <tr>
                    <td style="width:70px;"><strong>密码：</strong></td>
                    <td style="width:210px;">
                        <input type="password" value="" name="pwd" class="form-control pw" placeholder="请填写6位数以上的密码" plugin="passwordStrength"  datatype="*6-18" nullmsg="请输入密码！" errormsg="密码至少6个字符,最多18个字符！" />
                    </td>
                    <td>
                        <div class="Validform_checktip"></div>
                        <div class="passwordStrength" style="display:none;"><span>弱</span><span>中</span><span class="last">强</span></div>
                        <div class="info">密码至少6个字符,最多18个字符<span class="dec"><s class="dec1">&#9670;</s><s class="dec2">&#9670;</s></span></div>
                    </td>
                </tr>
                <tr>
                    <td><strong>确认密码：</strong></td>
                    <td><input type="password" value="" name="re_pwd" class="form-control pw"  recheck="pwd" placeholder="请确认密码"  datatype="*6-18" nullmsg="请确认密码！" errormsg="两次输入的密码不一致！" /></td>
                    <td>
                    	<div class="Validform_checktip"></div>
                    	<div class="info">请确认您的密码<span class="dec"><s class="dec1">&#9670;</s><s class="dec2">&#9670;</s></span></div>
                    </td>
                </tr>
				<!--
				<tr>
                    <td><strong>QQ号：</strong></td>
                    <td><input type="text" value="" name="qq" class="form-control qq"  datatype="n5-11" placeholder="您的QQ号码" nullmsg="请输入您的QQ号码！" errormsg="QQ号码错误！"  /></td>
                    <td>
                    	<div class="Validform_checktip"></div>
                        <div class="info">请输入您的QQ号码！<span class="dec"><s class="dec1">&#9670;</s><s class="dec2">&#9670;</s></span></div>
                    </td>
                </tr>
				  <tr>
                    <td><strong>电子邮件：</strong></td>
                    <td>
					<input type="text" value="" name="email" class="form-control wx" placeholder="您常用的电子邮件地址" datatype="e" nullmsg="请输入您的电子邮件地址！" errormsg="电子邮件地址错误！"  /></td>
                    <td>
                    	<div class="Validform_checktip"></div>
                        <div class="info">请输入您的电子邮件地址！<span class="dec"><s class="dec1">&#9670;</s><s class="dec2">&#9670;</s></span></div>
                    </td>
                </tr>-->
				<tr>
                    <td><strong>手机号码：</strong></td>
                    <td>  <input type="text" class="form-control ph" name="tel" id="tel" datatype="m" nullmsg="请输入手机号码" placeholder="请输入手机号码"></td>
                    <td>
                    	<div class="Validform_checktip"></div>
                        <div class="info">请输入您手机号码！<span class="dec"><s class="dec1">&#9670;</s><s class="dec2">&#9670;</s></span></div>
                    </td>
                </tr>
				<tr>
                    <td><strong>图形验证码：</strong></td>
                    <td>
					<div class="column" style="display: inline-block;box-sizing: border-box;"><input type="text" value="" name="checkcode" class="form-control wx" ajaxurl="inc/check.asp"  datatype="n4-4" nullmsg="请输入验证码！" errormsg="验证码错误！"   style="width:120px"/></div>
					<div class="column" style="display: inline-block;box-sizing: border-box;"><img src="inc/getcode.asp"  style=" margin-left:10px;cursor:Pointer;width:110px;height:32px"	 alt="看不清楚?请点击刷新" name="src" id="src" onClick="this.src=this.src+'?'+Math.random();"/></div>
                    <td>
                    	<div class="Validform_checktip"></div>
                        <div class="info">请输入验证码<span class="dec"><s class="dec1">&#9670;</s><s class="dec2">&#9670;</s></span></div>
                    </td>
                </tr>
				<!--
				<tr>
                    <td><strong>短信验证码：</strong></td>
                    <td> <input type="text" class="form-control" name="telcode" id="telcode" datatype="n4" nullmsg="请输入手机收到的短信验证码" placeholder=" " style="width:110px">  <div style="display:inline-block;vertical-align: middle;margin-top: -4px;margin-left: 20px;height:36px;" id="gca"><a class="telcode" href="#">获取短信验证码</a></div></td>
                    <td>
                    	<div class="Validform_checktip"></div>
                        <div class="info">请输入验证码<span class="dec"><s class="dec1">&#9670;</s><s class="dec2">&#9670;</s></span></div>
                    </td>
                </tr>-->
               <tr>
                    <td colspan="3"><button style="border:0;width:220px;" class="large button blue" />注 册 账 号</button> </td>
                </tr>
			</table> 
        </form>
			

<%
End Sub
Sub Modify()
%>
<div class="notibar announcement">
  <h3>请仔细阅读下面的协议。</h3>
  <p>1: 为了保证安全性,您必须输入您的旧密码才允许从新设定密码! <br>
    2: 如果您忘记了密码请联系客服,提 交注册时填写的QQ号即可找回!  </p>
</div>
<form method="post" action="UserCore.asp?Action=ModifySave">

           <table width="680" class="basic" style="table-layout:fixed; background-color: #fff;margin-left:15px;">
                <tr>
                    <td style="width:110px;"><strong>用户名：</strong></td>
                    <td style="width:280px;"><input type="text"  name="username" class="form-control un" placeholder="请输入您的用户名" datatype="s5-16" nullmsg="请输入您的用户名！" errormsg="用户名至少5个字符,最多16个字符！">
                   </td>
                    <td>
                    	
                        <div class="info">用户名至少5个字符,最多16个字符<span class="dec"><s class="dec1">&#9670;</s><s class="dec2">&#9670;</s></span></div>
                    </td>
                </tr>
                <tr>
                    <td style="width:70px;"><strong>旧密码：</strong></td>
                    <td style="width:210px;">
                        <input type="text" value="" name="old_password" class="form-control pw" placeholder="请填写6位数以上的密码" plugin="passwordStrength"  datatype="*6-18" nullmsg="请输入密码！" errormsg="密码至少6个字符,最多18个字符！" />
                    </td>
                    <td>
                        <div class="Validform_checktip"></div>
                        <div class="passwordStrength" style="display:none;"><b>密码强度：</b> <span>弱</span><span>中</span><span class="last">强</span></div>
                        <div class="info">密码至少6个字符,最多18个字符<span class="dec"><s class="dec1">&#9670;</s><s class="dec2">&#9670;</s></span></div>
                    </td>
                </tr>
				 <tr>
                    <td style="width:70px;"><strong>新密码：</strong></td>
                    <td style="width:210px;">
                        <input type="password" value="" name="password" class="form-control pw" placeholder="请输入新密码！" plugin="passwordStrength"  datatype="*6-18" nullmsg="请填写6位数以上的密码" errormsg="密码至少6个字符,最多18个字符！" />
                    </td>
                    <td>
                    </td>
                </tr>
				 <tr>
                    <td style="width:70px;"><strong>重复密码：</strong></td>
                    <td style="width:210px;">
                        <input type="password" value="" name="password2" class="form-control pw" placeholder="请确认新密码！" plugin="passwordStrength"  datatype="*6-18" nullmsg="请填写6位数以上的密码" errormsg="密码至少6个字符,最多18个字符！" />
                    </td>
                    <td>
                    </td>
                </tr>


				  <tr>
                    <td><strong>选择服务器：</strong></td>
                    <td><% Call ServerList()%></td>
                    <td>
                    </td>
                </tr>
				                <tr>
                    <td><strong>验证码：</strong></td>
                    <td><input type="text" value="" name="code" class="form-control wx" ajaxurl="inc/check.asp"  datatype="n4-4" nullmsg="请输入验证码！" errormsg="验证码错误！"   style="width:110px"/><img src="inc/getcode.asp" style=" margin-left:30px;cursor:Pointer;width:100px;height:28px" alt="看不清楚?请点击刷新" name="src" align="absmiddle" id="src" onClick="this.src=this.src+'?'+Math.random();"/></td>
                    <td>
                    	<div class="Validform_checktip"></div>
                        <div class="info">请输入验证码<span class="dec"><s class="dec1">&#9670;</s><s class="dec2">&#9670;</s></span></div>
                    </td>
                </tr>

                <tr>
                    <td colspan="3"><button style="border:0" class="large button blue" />修 改 密 码</button> </td>
                </tr>
</table>








</form>

<%
End Sub

Sub ChangeJob()

    If Not ChkLogin Then
        ' 【修改开始】如果未登录，不再跳转，直接在当前页面显示登录按钮
%>
        <div class="main-content-container">
            <h3>请先登录</h3>
            <p>您需要登录后才能进行职业变更操作。请点击下方按钮登录您的账号。</p>
            <button class="btn btn-login" id="loginBtn">立即登录</button>
        </div>
<%
        ' 停止执行后续代码，防止未登录用户看到职业选择表单
        Response.End
    End If

    ' 【修改结束】以下是已登录用户才能看到的内容，保持不变

    Id = checkstr(Request("Id"))
    If IsNull(Id) Then
        Response.Write "error!!"
        Response.End
    End If
set rs=conn_c.execute("select Character_name,Character_no,bypcClass from User_Character where user_no='"&session("user_no")&"' and Character_no='"&Id&"'")
%>
<form id="form1" method="post" action="UserCore.asp?Action=ChangeJobSave">
  <table width="650" border="0" align="center" cellpadding="5" cellspacing="0" class="maintable">
    <tbody>
      <tr>
        <td height="30" colspan="2">请仔细阅读以下注意事项<font color="#AADD47">：</font></td>
      </tr>
      <tr>
        <td height="30" colspan="2" >1: 转职前请将身上的所有装备(<span class="STYLE13">包括快捷栏的药水,时装等等</span>)放到背包中,否则无法转职! </td>
      </tr>
      <tr>
        <td height="30" colspan="2" >2: 充值200元以上转职一次收取5000万金币,其他取3E金币! </td>
      </tr>
      
      <tr>
        <td width="123" height="30" align="center" >角色名称:</td>
        <td width="423" ><%=rs("Character_name")%> [<%=GetClass(rs("bypcClass"))%>]</td>
      </tr>
      <tr>
        <td align="center" >改变的职业:</td>
        <td height="155" style="line-height:26px;">
          <table width="330" border="0" cellpadding="1" cellspacing="0">
            <tr>
              <td width="110" height="34"><input type="radio" name="New_Class" value="0" />
骑士 </td>
              <td width="110"><input type="radio" name="New_Class" value="1" />
弓箭手</td>
              <td width="110"><input type="radio" name="New_Class" value="2" />
法师</td>
            </tr>
            <tr>
              <td height="34"><input type="radio" name="New_Class" value="3" />
驱魔师 </td>
              <td><input type="radio" name="New_Class" value="4" />
巫师 </td>
              <td><input type="radio" name="New_Class" value="5" />
狂战 </td>
            </tr>
            <tr>
              <td height="34"><input type="radio" name="New_Class" value="6" />
魔枪手</td>
              <td><input type="radio" name="New_Class" value="7" />
女武神 </td>
              <td><input type="radio" name="New_Class" value="8" />
死神 </td>
            </tr>
            <tr>
              <td height="34"><input type="radio" name="New_Class" value="9" />
黑法师 </td>
              <td><input type="radio" name="New_Class" value="10" />
女战神 </td>
              <td>&nbsp;</td>
            </tr>
          </table></td>
      </tr>
      
      <tr>
        <td height="40" align="center" >&nbsp;</td>
        <td ><input name="Id" type="hidden" id="Id2" value="<%=rs("Character_no")%>" />
          <input type="submit" name="button4" class="btn" value="提 交" /></td>
      </tr>
    </tbody>
  </table>
</form>
<%
End Sub

Sub GetPwd()
%>
<form action="UserCore.asp?Action=GetPwdMail" method="post" name="form" id="form2">


<div class="notibar announcement">
    <h3>取回密码说明:</h3>
    <p>1: 请输入您的帐号和注册时填写的QQ号.</p>
    <p>2: 确认后系统将把您的密码发送至注册时填写的邮箱中.</p>
  </div>


           <table width="680" class="basic" style="table-layout:fixed; background-color: #fff;margin-left:15px">
                <tr>
                    <td style="width:110px;"><strong>用户名：</strong></td>
                    <td style="width:280px;"><input type="text"  name="username" class="form-control un" placeholder="您的用户名" datatype="s5-16" nullmsg="请输入您的用户名！" errormsg="用户名至少5个字符,最多16个字符！">
                   </td>
                    <td>
                    	
                        <div class="info">用户名至少5个字符,最多16个字符<span class="dec"><s class="dec1">&#9670;</s><s class="dec2">&#9670;</s></span></div>
                    </td>
                </tr>
                <tr>
                    <td style="width:70px;"><strong>注册QQ:</strong></td>
                    <td style="width:210px;">
                        <input type="text" value="" name="user_qq" class="form-control qq"  datatype="n5-11" placeholder="您的QQ号码" nullmsg="请输入您的QQ号码！" errormsg="QQ号码错误！"  />
                    </td>
                    <td>
                    </td>
                </tr>
				  <tr>
                    <td><strong>选择服务器：</strong></td>
                    <td>
					<% Call ServerList()%>
				   </td>
                    <td>
                    </td>
                </tr>
				                <tr>
                    <td><strong>验证码：</strong></td>
                    <td><input type="text" value="" name="code" class="form-control wx" ajaxurl="inc/check.asp"  datatype="n4-4" nullmsg="请输入验证码！" errormsg="验证码错误！"   style="width:110px"/><img src="inc/getcode.asp" style=" margin-left:30px;cursor:Pointer;width:100px;height:28px" alt="看不清楚?请点击刷新" name="src" align="absmiddle" id="src" onClick="this.src=this.src+'?'+Math.random();"/></td>
                    <td>
                    	<div class="Validform_checktip"></div>
                        <div class="info">请输入验证码<span class="dec"><s class="dec1">&#9670;</s><s class="dec2">&#9670;</s></span></div>
                    </td>
                </tr>

                <tr>
                    <td colspan="3"><button style="border:0" class="large button blue" />确 定</button> </td>
                </tr>
</table>
</form>
<%
End Sub

Sub NewsList()
%>		
					  
					  <ul class="list1 list1-a mt25">
					  <%

set rs=conn.execute("SELECT top 20 id,title,NewsDate FROM News order by istop desc")
  if rs.eof or rs.bof then
  response.write "没有公告.."
  else
  Do While not rs.eof
	newsdate=year(RS(2))&"-"&month(RS(2))&"-"&day(RS(2))



Response.write "<li><span>["&newsdate&"]</span><a class=""fl hover fancybox fancybox.iframe badge badge-gary""   href=""News.asp?Id="&RS(0)&""">"&RS(1)&"</a></li>"

rs.movenext
Loop
rs.close
End If 
%>
					</ul>
					<%End Sub
					Set conn = Nothing%>
					
					

                           
							<div>          &nbsp;              </div>
                        </div>                        
                        <!-- END: Products -->
                      
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
									<li><a href="User.asp" <%If pageLink="" Then response.write "class='on'"%>>用户中心</a></li>
									<li><a href="User.asp?Action=Agree" <%If Action="Reg" Then response.write "class='on'"%>>注册账号</a></li>
									<li><a href="User.asp?Action=Down" <%If Action="Down" Then response.write "class='on'"%>>游戏下载</a></li>
									<li><a href="User.asp?Action=Modify" <%If Action="Modify" Then response.write "class='on'"%>>修改资料</a></li>
									<li><a href="User.asp?Action=GetPwd" <%If Action="GetPwd" Then response.write "class='on'"%>>取回密码</a></li>
									<li><a href="User.asp?Action2=ChangeJob" <%If Right(pageLink,2)="ob" Then response.write "class='on'"%>>变更职业</a></li>
									<li><a href="User.asp?Action2=Upgrade" <%If Right(pageLink,2)="de" Then response.write "class='on'"%>>角色转生</a></li>
									<li><a href="User.asp?Action2=Move" <%If Right(pageLink,2)="ve" Then response.write "class='on'"%>>卡号自救</a></li>
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
        
    
  <style>
.action-btn {
    display: inline-block;
    padding: 5px 22px 9px 18px;
    background-color: #007bff;
    color: white;
    text-decoration: none;
    border: none;
    border-radius: 9px;
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
</style>

    </body>
</html>