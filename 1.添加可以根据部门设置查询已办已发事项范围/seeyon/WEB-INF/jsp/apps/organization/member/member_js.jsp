<%--
 $Author: lilong $
 $Rev: 4423 $
 $Date:: 2012-09-24 18:13:06#$:
  
 Copyright (C) 2012 Seeyon, Inc. All rights reserved.
 This software is the proprietary information of Seeyon, Inc.
 Use is subject to license terms.
--%>
<%@ page contentType="text/html; charset=UTF-8" isELIgnored="false" %>
<%@ include file="/WEB-INF/jsp/common/common.jsp" %>
<%@ include file="/WEB-INF/jsp/apps/ldap/ldap_tools_js.jsp" %>
<script type="text/javascript" language="javascript">
    var dialog4Role;
    var dialog4Batch;
    var dialog;
    var grid;
    var uploadDialog;
    $().ready(function () {
        var s;//查询条件
        var isSearch = false;//保存前是进行的查询
        //为点击某部门自动将人员部门信息关联增加的变量
        var preDeptId = '';
        var preDeptName = '';
        var msg = '${ctp:i18n("info.totally")}';
        var filter = null;//列表过滤查询条件
        var loginAccountId = "${accountId}";
        var isNewMember = false;
        var disableModifyLdapPsw = "${disableModifyLdapPsw}";//ctpConfig配置是否OA可以修改ldap密码
        var mManager = new memberManager();
        var oManager = new orgManager();
        var imanager = new iOManager();
        var rManager = new roleManager();
        var eManager = new enumManagerNew();
        var enumId = "8264671846789452738";
        var eDeep = null;
        var loadDistpicker = false;
        $("tr[class='forInter']").show();
        $("tr[class='forOuter']").hide();
        $("#button_area").hide();
        //列表
        grid = $("#memberTable").ajaxgrid({
            gridType: 'autoGrid',
            colModel: [{
                display: 'id',
                name: 'id',
                width: 'smallest',
                sortable: false,
                align: 'center',
                type: 'checkbox'
            },
                {
                    display: "${ctp:i18n('org.member_form.name.label')}",
                    name: 'name',
                    sortable: true,
                    width: 'small'
                },
                {
                    display: "${ctp:i18n('org.member_form.loginName.label')}",
                    name: 'loginName',
                    sortable: true,
                    width: 'small'
                },
                {
                    display: "${ctp:i18n('org.member_form.code')}",
                    name: 'code',
                    sortable: true,
                    width: 'small'
                },
                {
                    display: "${ctp:i18n('org.member_form.sort')}",
                    name: 'sortId',
                    sortType: 'number',
                    sortable: true,
                    width: 'small'
                },
                {
                    display: "${ctp:i18n('org.member_form.deptName.label')}",
                    name: 'departmentName',
                    sortable: true,
                    width: 'small'
                },
                {
                    display: "${ctp:i18n('org.member_form.primaryPost.label')}",
                    name: 'postName',
                    sortable: true,
                    width: 'small'
                },
                {
                    display: "${ctp:i18n('org.member_form.levelName.label')}",
                    name: 'levelName',
                    sortable: true,
                    width: 'medium'
                },
                {
                    display: "${ctp:i18n('org.metadata.member_type.label')}",
                    sortable: true,
                    codecfg: "codeId:'org_property_member_type'",
                    name: 'typeName',
                    width: 'small'
                },
                {
                    display: "${ctp:i18n('org.metadata.member_state.label')}",
                    sortable: true,
                    codecfg: "codeId:'org_property_member_state'",
                    name: 'stateName',
                    width: 'small'
                }],
            managerName: "memberManager",
            managerMethod: "showByAccount",
            parentId: 'center',
            vChange: true,
            render: rend,
            vChangeParam: {
                overflow: "hidden",
                position: 'relative'
            },
            slideToggleBtn: true,
            showTableToggleBtn: true,
            customize: false,
            click: clickGrid,
            dblclick: dblclkGrid,
            callBackTotle: getCount
        });

        function getCount() {
            cnt = grid.p.total;
            $("#count").get(0).innerHTML = msg.format(cnt);
        }

        $("#welcome").show();
        $("#form_area").hide();

        function rend(txt, data, r, c) {
            if (c == 5 || c == 6 || c == 7) {
                if (txt == '待定') {
                    return '<font color="red">' + txt + '</font>';
                } else {
                    return txt;
                }
            } else if (c == 2) {
                if (null == data.ldapLoginName || "" == data.ldapLoginName) {
                    return txt;
                } else {
                    var loginTemp = "${ctp:i18n('ldap.user.prompt.new')}";
                    return txt + "<img src=<c:url value='/common/images/ldapbinding.gif' /> title='" + loginTemp + data.ldapLoginName + "'/>";
                }
            } else return txt;
        }

        //第一次加载表格，只加载单位内启用的人员
        filter = new Object();
        filter.enabled = true;
        filter.accountId = loginAccountId;
        $("#memberTable").ajaxgridLoad(filter);
        //部门树
        $("#deptTree").tree({
            idKey: "id",
            pIdKey: "parentId",
            nameKey: "name",
            onClick: showMembersByDept,
            nodeHandler: function (n) {
                if (n.data.parentId == n.data.id) {
                    n.open = true;
                } else {
                    n.open = false;
                }
            }
        });

        //手动去除部门树上的节点选择状态
        function cancelSelectTree() {
            $("#deptTree").treeObj().cancelSelectedNode();
            preDeptId = '';
            searchobj.g.clearCondition();
            s = searchobj.g.getReturnValue();
        }

        var westHide = false;
        //页面按钮
        var toolBarVar = $("#toolbar").toolbar({
            toolbar: [{
                id: "add",
                name: "${ctp:i18n('common.toolbar.new.label')}",
                className: "ico16",
                click: newMember
            },
                {
                    id: "edit",
                    name: "${ctp:i18n('common.button.modify.label')}",
                    className: "ico16 editor_16",
                    click: editMember
                },
                {
                    id: "delete",
                    name: "${ctp:i18n('common.toolbar.delete.label')}",
                    className: "ico16 delete del_16",
                    click: delMembers
                },
                {
                    id: "import_export",
                    name: "${ctp:i18n('export.or.import')}",
                    className: "ico16 import_16",
                    subMenu: [{
                        name: "${ctp:i18n('import.excel')}",
                        click: function () {
                            dialog = $.dialog({
                                width: 600,
                                height: 400,
                                isDrag: false,
                                //targetWindow:window.parent,
                                //BUG请不要打开这个属性，否则弹出窗口取得对象无法关闭这个框
                                id: 'importdialog',
                                url: '${path}/organization/organizationControll.do?method=importExcel&importType=member&accountId=' + loginAccountId + "${ctp:csrfSuffix()}",
                                title: "${ctp:i18n('import.excel')}",
                                closeParam: {
                                    'show': true,
                                    handler: function () {
                                        filter = new Object();
                                        filter.enabled = true;
                                        filter.accountId = loginAccountId;
                                        isSearch = false;
                                        $("#memberTable").ajaxgridLoad(filter);
                                    }
                                }
                            });
                        }
                    },
                        {
                            name: "${ctp:i18n('org.template.excel.download')}",
                            click: function () {
                                var downloadUrl = "${path}/organization/organizationControll.do?method=downloadTemplate&type=Member&accountId=" + loginAccountId + "${ctp:csrfSuffix()}";
                                var eurl = "<c:url value='" + downloadUrl + "' />";
                                exportIFrame.location.href = eurl;
                            }
                        },
                        {
                            name: "${ctp:i18n('org.post_form.export.exel')}",
                            click: function () {
                                var exportFlag = oManager.getOrgExportFlag();
                                if (exportFlag || exportFlag == 'true') {
                                    $.alert("${ctp:i18n('org.alert.info')}");
                                    return;
                                } else {
                                    $.alert({
                                        'title': "${ctp:i18n('common.prompt')}",
                                        'msg': "${ctp:i18n('member.export.prompt.wait')}",
                                        ok_fn: function () {
                                            imanager.canIO({
                                                success: function (rel) {
                                                    if ('ok' == rel) {
                                                        var downloadUrl_e = "${path}/organization/member.do?method=exportMembers&orgDepartmentId=" + preDeptId + "&accountId=" + loginAccountId + "${ctp:csrfSuffix()}";
                                                        if (s != undefined && s != null) {
                                                            var s_condition = s.condition;
                                                            var s_value = encodeURIComponent(s.value);
                                                            var s_enable = s.enable;
                                                            var s_accountId = s.accountId;
                                                            var s_state = s.state;
                                                            var s_type = s.type;
                                                            var url_s = "s_type:" + s_type + ";s_condition:" + s_condition + ";s_value:" + s_value + ";s_enable:" + s_enable + ";s_accountId:" + s_accountId + ";s_state:" + s_state;
                                                            downloadUrl_e = downloadUrl_e + "&s=" + url_s;
                                                        }

                                                        if (filter != undefined && filter != null) {
                                                            var filter_condition = filter.condition;
                                                            var filter_value = encodeURIComponent(filter.value);
                                                            var filter_enabled = filter.enabled;
                                                            var filter_accountId = filter.accountId;
                                                            var filter_showByType = filter.showByType;
                                                            var filter_cond = filter.cond;
                                                            var filter_deptId = filter.deptId;
                                                            var filter_subMembers = $("#subMembers").prop("checked");
                                                            var url_filter = "filter_value:" + filter_value + ";filter_condition:" + filter_condition + ";" +
                                                                "filter_enabled:" + filter_enabled + ";filter_accountId:" + filter_accountId + ";" +
                                                                "filter_showByType:" + filter_showByType + ";filter_cond:" + filter_cond + ";filter_subMembers:" + filter_subMembers + ";" +
                                                                "filter_deptId:" + filter_deptId;
                                                            downloadUrl_e = downloadUrl_e + "&filter=" + url_filter;
                                                        }

                                                        var eurl_e = "<c:url value='" + downloadUrl_e + "' />";
                                                        exportIFrame.location.href = eurl_e + "${ctp:csrfSuffix()}";
                                                    }
                                                }
                                            });
                                        }
                                    });
                                }
                            }
                        },
                        {
                            id: 'importLDIF',
                            name: "${ctp:i18n('ldap.impPost.ldif')}",
                            click: impPost
                        }]
                },
                {
                    id: "filter",
                    name: "${ctp:i18n('member.filter')}",
                    className: "ico16 personnel_filter_16",
                    subMenu: [{
                        name: "${ctp:i18n('member.all')}",
                        click: function () {
                            filter = new Object();
                            filter.enabled = null;
                            filter.accountId = loginAccountId;
                            isSearch = false;
                            $("#memberTable").ajaxgridLoad(filter);
                            grid.grid.resizeGridUpDown('down');
                            cancelSelectTree();
                        }
                    },
                        {
                            name: "-------------",
                            click: function () {
                                return;
                            }
                        },
                        {
                            name: "${ctp:i18n('member.in.service')}",
                            click: function () {
                                filter = new Object();
                                filter.condition = 'state';
                                filter.value = 1;
                                filter.enabled = true;
                                filter.accountId = loginAccountId;
                                isSearch = false;
                                $("#memberTable").ajaxgridLoad(filter);
                                grid.grid.resizeGridUpDown('down');
                                cancelSelectTree();
                            }
                        },
                        {
                            name: "${ctp:i18n('member.out.service')}",
                            click: function () {
                                filter = new Object();
                                filter.condition = 'state';
                                filter.value = 2;
                                filter.enabled = false;
                                filter.accountId = loginAccountId;
                                isSearch = false;
                                $("#memberTable").ajaxgridLoad(filter);
                                grid.grid.resizeGridUpDown('down');
                                cancelSelectTree();
                            }
                        },
                        {
                            name: "-------------",
                            click: function () {
                                return;
                            }
                        },
                        {
                            name: "${ctp:i18n('account.start')}",
                            click: function () {
                                filter = new Object();
                                filter.enabled = true;
                                filter.accountId = loginAccountId;
                                isSearch = false;
                                $("#memberTable").ajaxgridLoad(filter);
                                grid.grid.resizeGridUpDown('down');
                                cancelSelectTree();
                            }
                        },
                        {
                            name: "${ctp:i18n('account.stop')}",
                            click: function () {
                                filter = new Object();
                                filter.enabled = false;
                                filter.accountId = loginAccountId;
                                isSearch = false;
                                $("#memberTable").ajaxgridLoad(filter);
                                grid.grid.resizeGridUpDown('down');
                                cancelSelectTree();
                            }
                        }]
                },
                {
                    id: "more",
                    name: "${ctp:i18n('member.advanced')}",
                    className: "ico16 setting_16",
                    subMenu: [
                        {
                            name: "${ctp:i18n('member.batch.list.modify')}",
                            click: function () {
                                var boxs = $("#memberTable input:checked");
                                if (boxs.length === 0) {
                                    $.alert(" ${ctp:i18n('org.member_form.choose.personnel.edit')}");
                                    return;
                                } else {
                                    var membersIds = "";
                                    var isDeptOrManager = "";
                                    boxs.each(function () {
                                        membersIds += $(this).val() + ",";
                                    });
                                    isDeptOrManager = mManager.checkMember4DeptRole(membersIds);
                                    if (isDeptOrManager.deptName.trim() != '') {
                                        $.alert(isDeptOrManager.deptName + " ${ctp:i18n('member.deptmaster.or.admin.not.batupate')}");
                                        var temRoles = isDeptOrManager.deptIds.split(",");
                                        for (i = 0; i < temRoles.length; i++) {
                                            $("input[value='" + temRoles[i] + "']").prop("checked", false);
                                        }
                                        return false;
                                    } else {
                                        var max_height = 500;
                                        var h = getWindowHeight() - 130;
                                        h = h > max_height ? max_height : h;
                                        dialog4Batch = $.dialog({
                                            id: "batchDia",
                                            url: "<c:url value='/organization/member.do' />?method=batchUpdatePre&isDeptAdmin=false&accountId=" + loginAccountId + "${ctp:csrfSuffix()}",
                                            title: "${ctp:i18n('member.batch.list.modify')}",
                                            width: 580,
                                            height: h,
                                            transParams: membersIds,
                                            targetWindow: window
                                        });
                                    }
                                }
                            }
                        },
                        {
                            name: "${ctp:i18n('member.tree.structure')}",
                            click: function () {
                                var layout = $("#layout").layout();
                                if (!westHide) {
                                    layout.setWest(0);
                                    westHide = true;
                                } else {
                                    layout.setWest(200);
                                    westHide = false;
                                }
                            }
                        },
                        {
                            id: "batchImgUpload",
                            name: "${ctp:i18n('member.photo.batch.upload')}",
                            className: "ico16 import_16",
                            click: batchUploadImg
                        }]
                },
                {
                    id: "workchange",
                    name: "${ctp:i18n('member.job.change')}",
                    className: "ico16 redistribution_16",
                    subMenu: [
                        {
                            id: "leaveMember2",
                            name: "${ctp:i18n('member.leave.label')}",
                            className: "ico16 staff_transferred_out_16",
                            click: memberLeave2
                        },
                        {
                            id: "leaveMember",
                            name: "${ctp:i18n('member.out.service.procedure')}",
                            className: "ico16 staff_transferred_out_16",
                            click: memberLeave
                        },
                        {
                            id: "cancelMemberBtn",
                            name: "${ctp:i18n('member.callout')}",
                            click: cancelMember
                        },
                        {
                            id: "toOuter",
                            name: "${ctp:i18n('turn.member.query.outerior')}",
                            className: "ico16 switch_internal_staff_16",
                            click: toOuter
                        }
                    ]
                },
                {
                    id: "showMemberAllRoles",
                    name: "${ctp:i18n('org.member_form.showMemberAllrole')}",
                    className: "ico16 roster_16",
                    click: showMemberAllRoles
                },
                {
                    id: "subMembers",
                    type: "checkbox",
                    checked: false,
                    text: "${ctp:i18n('org.member.subdept.include')}",
                    value: "1",
                    click: subMembers
                }]
        });

        //转内部人员
        function toOuter() {
            var boxs = $("#memberTable input:checked");
            if (boxs.length === 0) {
                $.alert("${ctp:i18n('org.member_form.choose.personnel.toOuter')}");
                return;
            } else if (boxs.length > 1) {
                $.alert("${ctp:i18n('org.member_form.chosen.personnel.one.toOuter')}");
                return;
            } else {

                var memberId = boxs[0].value;
                var checkResult = oManager.checkCanLeave(memberId, true);
                if (checkResult != null && checkResult != "") {
                    $.alert(checkResult);
                    return;
                }

                $.confirm({
                    title: "",
                    msg: $.i18n("turn.member.query.outerior.confirm"),
                    ok_fn: function () {
                        var memberId = boxs[0].value;
                        var member = mManager.viewOne(memberId);
                        var dialog = $.dialog({
                            id: "showLeavePageDialog",
                            url: "<c:url value='/organization/memberLeave.do' />?method=dealLeavePage&memberId=" + memberId + "${ctp:csrfSuffix()}",
                            title: "${ctp:i18n('turn.member.query.outerior')}" + ": " + member.name_text,
                            width: 890,
                            height: 500,
                            targetWindow: window.top,
                            isClear: false,//OA-49174
                            buttons: [{
                                isEmphasize: true,
                                id: "okButton",
                                text: $.i18n('common.button.ok.label'),
                                handler: function () {
                                    $.confirm({
                                        title: "",
                                        msg: $.i18n("turn.member.query.outerior.confirm.ok"),
                                        ok_fn: function () {
                                            dialog.close();
                                            var mDetail = new Object();
                                            grid.grid.resizeGridUpDown('middle');
                                            $("#form_area").clearform();
                                            $('#name').dataI18n({
                                                type: 'dataI18n',
                                                mode: 1,
                                                category: 'organization.member.name',
                                                i18nSwitch: 'on',
                                                categoryName: "${ctp:i18n('org.member_form.name.label')}"
                                            });
                                            clearCustomSelectField();
                                            mDetail = mManager.viewOne(boxs[0].value);
                                            $("tr[class='forInter']").hide();
                                            $("tr[class='forOuter']").show();
                                            $("#sortIdtype1").prop("checked", "checked");
                                            $("#memberForm").enable();
                                            $("#name").prop("disabled", false);
                                            $("#memberForm").fillform(mDetail);
                                            $("#name").setI18nVal(mDetail.name);

                                            $("#extbirthday").val(mDetail.birthday);
                                            $("#extgender").val(mDetail.gender);
                                            $("#extdescription").val(mDetail.description);

                                            $("#loginName").attr("readonly", "readonly");
                                            $("#isChangePWD").val("false");
                                            fillSelectPeople(mDetail);
                                            $("#button_area").show();
                                            $("#form_area").show();
                                            isNewMember = false;
                                            $("#state").disable();
                                            $("#lconti").hide();
                                            $("#welcome").hide();
                                            $(".calendar_icon_area").show();
                                            toOuter = true;
                                            ldapSet4Edit("edit", mDetail.ldapUserCodes);
                                            $("#isLoginNameModifyed").val(false);
                                            //设置给编外人员编外人员角色
                                            var role = oManager.getRoleByName('ExternalStaff', loginAccountId);
                                            if (null != role) {
                                                $("#extRoles").val(role.showName);
                                                $("#extRoleIds").val(role.id);
                                            }

                                            $("#conPostsTr").hide();
                                            $('#sssssssss').height($('#grid_detail').height() - 50).css('overflow', 'auto');
                                        }
                                    });
                                }
                            }]
                        });
                    }
                });
            }
        }

        $("#subMembers").prop("checked", true);
        $("#subMembers").disable();

        function subMembers() {
            if (preDeptId == '') {
                return;//在选择单位的情况下，checkbox不起作用
            }
            s = searchobj.g.getReturnValue();
            s.enabled = filter.enabled;
            s.accountId = loginAccountId;
            filter.cond = 'yes';
            if ('state' == filter.condition) {
                s.state = filter.value;
            }
            if (null != filter.state) {
                s.state = filter.state;
            }
            if (null != preDeptId && '' != preDeptId) {
                s.deptId = preDeptId;
                s.subMembers = $("#subMembers").prop("checked");
            }
            isSearch = true;
            $("#memberTable").ajaxgridLoad(s);
        }

        //批量上传头像
        function batchUploadImg() {
            uploadDialog = $.dialog({
                width: 600,
                height: 400,
                isDrag: false,
                id: 'uploadZipDialog',
                url: '${path}/organization/member.do?method=uploadPicture&loginAccountId=' + loginAccountId + "${ctp:csrfSuffix()}",
                targetWindow: window,
                title: "${ctp:i18n('member.photo.batch.upload')}",
                closeParam: {
                    'show': true,
                    handler: function () {
                        filter = new Object();
                        filter.enabled = true;
                        filter.accountId = loginAccountId;
                        isSearch = false;
                        $("#memberTable").ajaxgridLoad(filter);
                    }
                }
            });
        }

        /**
         * 查看该人员的所有角色
         */
        function showMemberAllRoles() {
            var boxs = $("#memberTable input:checked");
            if (boxs.length === 0) {
                $.alert("${ctp:i18n('org.member_form.choose.personnel.view.no')}");
                return;
            } else if (boxs.length > 1) {
                $.alert("${ctp:i18n('org.member_form.choose.personnel.view.more')}");
                return;
            } else {
                dialog4Role = null;
                dialog4Role = $.dialog({
                    url: "<c:url value='/organization/member.do' />?method=showMemberAllRoles&memberId=" + boxs[0].value + "${ctp:csrfSuffix()}",
                    title: "${ctp:i18n('org.member_form.roleList')}",
                    width: 400,
                    height: 300,
                    buttons: [{
                        id: "roleConcel",
                        text: "${ctp:i18n('label.close')}",
                        handler: function () {
                            dialog4Role.close();
                        }
                    }]
                });
            }
        }

        //区分集团版企业版隐藏人员调出按钮
        if ("${isGroupVer}" == "false" || "${isGroupVer}" == false) {
            toolBarVar.hideBtn("cancelMemberBtn");
        }

        //查看人员信息
        function viewDetail(id) {
            grid.grid.resizeGridUpDown('middle');
            $("#form_area").clearform();
            $('#name').dataI18n({
                type: 'dataI18n',
                mode: 1,
                category: 'organization.member.name',
                i18nSwitch: 'on',
                categoryName: "${ctp:i18n('org.member_form.name.label')}"
            });
            clearCustomSelectField();
            toOuter = false;
            $("tr[class='forInter']").show();
            $("tr[class='forOuter']").hide();
            $("#secondPostIds").val("");//OA-41812
            var mDetail = mManager.viewOne(id);
            getlocation();
            $("#form_area").show();
            $("#welcome").hide();
            $("#memberForm").fillform(mDetail);
            $("#name").setI18nVal(mDetail.name);
            $("#loginName").attr("readonly", "readonly");
            //头像回写
            showImage();
            $("#sortIdtype1").prop("checked", "checked");
            $("#form_area").resetValidate();
            $("#password").val("~`@%^*#?");
            $("#password2").val("~`@%^*#?");
            $("#isChangePWD").val("false");
            fillSelectPeople(mDetail);
            $("#button_area").hide();
            $('#sssssssss').height($('#grid_detail').height()).css('overflow', 'auto');
            $("#memberForm").disable();
            $("#name").prop("disabled", true);
            ldapSet4Edit("view", mDetail.ldapUserCodes);
            showConPostInfo(mDetail.conPostsInfo);
            $("#isLoginNameModifyed").val(false);
            $("#officenumber").attr("placeholder", "");
            $(".calendar_icon_area").hide();
        }

        /*人员头像回填*/
        function showImage() {
            //回显人物头像
            var path = _ctxServer;
            var imageid = $("#imageid").val();
            var defaultImageid = "${ctp:avatarImageUrl(1)}";
            var url = "";
            if ("" == imageid || "" == imageid.trim()) {
                url = defaultImageid;
            } else {
                url = path + imageid;
            }
            var imgStr = "<img src='" + url + "' width='100px' height='120px'>";
            $("#viewImageIframe").get(0).innerHTML = imgStr;
        }

        //选人界面的回写方法
        function fillSelectPeople(memberData) {
            if (null != memberData["orgDepartmentId"] || '-1' != memberData["orgDepartmentId"]) {
                //部门
                var deptInfo = oManager.getDepartmentById(memberData["orgDepartmentId"]);
                if (null != deptInfo) {
                    $("#deptName").val(oManager.showDepartmentFullPath(memberData["orgDepartmentId"]));
                    $("#deptName").attr("title", oManager.showDepartmentFullPath(memberData["orgDepartmentId"]));
                    $("#orgDepartmentId").val(memberData["orgDepartmentId"]);
                }
            }
            if (null != memberData["orgPostId"] || '-1' != memberData["orgPostId"]) {
                //主岗
                var primaryPostInfo = oManager.getPostById(memberData["orgPostId"]);
                if (null != primaryPostInfo) {
                    if (primaryPostInfo.enabled == false) {
                        $("#primaryPost").val("待定");
                        $("#orgPostId").val(-1);
                    } else {
                        $("#primaryPost").val(primaryPostInfo.name);
                        $("#orgPostId").val(memberData["orgPostId"]);
                    }
                }
            }
            if (null != memberData["orgLevelId"] || '-1' != memberData["orgLevelId"]) {
                //职务级别
                var levelInfo = oManager.getLevelById(memberData["orgLevelId"]);
                if (null != levelInfo) {
                    $("#levelName").val(levelInfo.name);
                    $("#orgLevelId").val(memberData["orgLevelId"]);
                }
            }
            //汇报人部门全路径
            $("#reporterName").attr("title", memberData["reporterDeptTitle"]);
        }

        //表格单击事件
        function clickGrid(data, r, c) {
            viewDetail(data.id);
        }

        //表格双击事件
        function dblclkGrid(data, r, c) {
            var mDetail = new Object();
            $("#imageid").val("");
            $("#form_area").clearform();
            $('#name').dataI18n({
                type: 'dataI18n',
                mode: 1,
                category: 'organization.member.name',
                i18nSwitch: 'on',
                categoryName: "${ctp:i18n('org.member_form.name.label')}"
            });
            clearCustomSelectField();
            toOuter = false;
            $("tr[class='forInter']").show();
            $("tr[class='forOuter']").hide();
            $("#secondPostIds").val("");//OA-41812
            mDetail = mManager.viewOne(data.id);
            getlocation();
            $("#password").val("~`@%^*#?");
            $("#password2").val("~`@%^*#?");
            $("#sortIdtype1").prop("checked", "checked");
            $("#memberForm").enable();
            $("#name").prop("disabled", false);
            $("#memberForm").fillform(mDetail);
            $("#name").setI18nVal(mDetail.name);
            showImage();
            $("#loginName").attr("readonly", "readonly");
            $("#isChangePWD").val("false");
            fillSelectPeople(mDetail);
            $(".calendar_icon_area").show();
            $("#button_area").show();
            $("#form_area").show();
            $("#welcome").hide();
            $("#state").disable();
            isNewMember = false;
            $("#lconti").hide();
            ldapSet4Edit("edit", mDetail.ldapUserCodes);
            showConPostInfo(mDetail.conPostsInfo);
            $("#isLoginNameModifyed").val(false);
            $("#officenumber").attr("placeholder", "${ctp:i18n('personal.info.telephone.placeholder')}");
            if (!supportPlaceholder) {
                var value = $("#officenumber").val();
                if (!value) {
                    $("#officenumber").val("${ctp:i18n('personal.info.telephone.placeholder')}").addClass("phcolor");
                } else {
                    $("#officenumber").removeClass("phcolor");
                }
            }
            $("#memberForm").resetValidate();
            $('#sssssssss').height($('#grid_detail').height() - 50).css('overflow', 'auto');
            $("#name_text").blur();
        }

        var toOuter = false;

        function newMember() {
            $("#reporter").val("");
            $('#workspace').val("");
            $('#workLocal').val("")
            var initpwd = oManager.getInitPWDForPage();
            if (null != initpwd && initpwd != "" && initpwd != false) {
                initpwd = initpwd.substring(8);
            } else {
                initpwd = "";
            }
            $("#password").val(initpwd);
            $("#password2").val(initpwd);
            isNewMember = true;
            $("#isNewMember").val("true");
            $("#imageid").val("");
            var imgStr = "<img src='${ctp:avatarImageUrl(1)}' width='100px' height='120px'>";
            $("#viewImageIframe").get(0).innerHTML = imgStr;
            grid.grid.resizeGridUpDown('middle');
            $("#memberForm").clearform();
            $('#name').dataI18n({
                type: 'dataI18n',
                mode: 1,
                category: 'organization.member.name',
                i18nSwitch: 'on',
                categoryName: "${ctp:i18n('org.member_form.name.label')}"
            });
            clearCustomSelectField();
            $("tr[class='forInter']").show();
            $("tr[class='forOuter']").hide();
            $("#secondPostIds").val("");//OA-41812
            $("#loginName").removeAttr("readonly");
            $("#roles").val("");
            $("#roleIds").val("");
            $("#id").val("-1");
            $("#orgAccountId").val(loginAccountId);//新建人员时追加当前登录单位id，以备判断人员角色
            $("#form_area").show();
            $("#welcome").hide();
            $("#memberForm").enable();
            $("#name").prop("disabled", false);
            $("#button_area").show();
            $("#button_area").enable();
            $("#btnArea").show();
            $("#btnArea").enable();
            $(".calendar_icon_area").show();
            $("input[type='radio'][name='enabled'][value='true']").prop("checked", "checked");
            //zhou:是否待离职
            $("input[type='radio'][name='departure'][value='false']").prop("checked", "checked");
            $("#sortIdtype1").prop("checked", "checked");
            if ("" !== preDeptId) {
                $("#orgDepartmentId").val(preDeptId);
                $("#deptName").val(preDeptName);
            }

            var sort = 1;
            var preSortId = oManager.getMaxMemberSortByAccountId(loginAccountId);
            if (preSortId >= 999999999) {
                sort = 999999999;
            } else {
                sort = parseInt(preSortId) + 1;
            }
            $("#sortId").val(sort);
            $("#lconti").show();
            $("#primaryLanguange").val("zh_CN");
            $("#type").val("1");
            $("#state").val("1");
            $("#state").disable();
            //对新建的人员默认给一个最低级别的职务
            var lowestLevel = oManager.getLowestLevel(loginAccountId);
            if (null != lowestLevel) {
                $("#levelName").val(lowestLevel.name);
                $("#orgLevelId").val(lowestLevel.id);
            }
            //默认给人员一个普通角色
            var role = rManager.getDefultRoleByAccount(loginAccountId);
            if (null != role) {
                $("#roles").val(role.showName);
                $("#roleIds").val(role.id);
            }
            //ldap/ad
            if ('true' == "${isLdapEnabled}") {
                $("input[type='radio'][name='ldapSetType'][value='select']").prop("checked", "checked");
                $("#ldapSet_tr0").show();
                $("#ldapSet_tr1").show();
                $("#ldapSet_tr2").hide();
                //ctpConfig配置禁用OA修改ldap密码则置灰
                if ('false' == "${LdapCanOauserLogon}") {
                    if ('true' == disableModifyLdapPsw || true == disableModifyLdapPsw) {
                        $("#password").disable();
                        $("#password2").disable();
                    }
                }
            } else {
                $("#ldapSet_tr0").hide();
                $("#ldapSet_tr1").hide();
                $("#ldapSet_tr2").hide();
            }
            $("#officenumber").attr("placeholder", "${ctp:i18n('personal.info.telephone.placeholder')}");
            if (!supportPlaceholder) {
                var value = $("#officenumber").val();
                if (!value) {
                    $("#officenumber").val("${ctp:i18n('personal.info.telephone.placeholder')}").addClass("phcolor");
                } else {
                    $("#officenumber").removeClass("phcolor");
                }
            }
            //新建时屏蔽显示兼职的信息框
            $("#conPostsTr").hide();
            $('#sssssssss').height($('#grid_detail').height() - 50).css('overflow', 'auto');
        }

        //绑定ldap新建radio的选项
        $("input[type='radio'][name='ldapSetType']").click(function () {
            if ($("input[type='radio'][name='ldapSetType'][value='new']").prop("checked")) {
                $("#ldapSet_tr0").show();
                $("#ldapSet_tr1").hide();
                $("#ldapSet_tr2").show();
            }
            if ($("input[type='radio'][name='ldapSetType'][value='select']").prop("checked")) {
                $("#ldapSet_tr0").show();
                $("#ldapSet_tr1").show();
                $("#ldapSet_tr2").hide();
            }
        });

        //点击部门树某一部门展现某部门的人员
        function showMembersByDept(e, treeId, node) {
            isSearch = false;
            searchobj.g.clearCondition();
            s = searchobj.g.getReturnValue();
            grid.grid.resizeGridUpDown('down');
            $("#welcome").show();
            $("#form_area").hide();
            $("#button_area").hide();
            if (node.parentId === 0) {
                $("#subMembers").prop("checked", true);
                $("#subMembers").disable();
                filter.deptId = node.id;
                preDeptId = '';
                preDeptName = '';
                filter.showByType = null;
                filter.cond = 'no';
                filter.accountId = loginAccountId;
                $("#memberTable").ajaxgridLoad(filter);
            } else {
                $("#subMembers").enable();
                //var o2 = new Object();
                filter.deptId = node.id;
                filter.accountId = loginAccountId;
                filter.subMembers = $("#subMembers").prop("checked");
                $("#memberTable").ajaxgridLoad(filter);
                preDeptId = node.id;
                preDeptName = node.name;
            }
        }

        /** 离职办理 */
        function memberLeave(fromDisable) {
            var memberId;
            if (fromDisable) {
                memberId = $("#id").val();
            } else {
                var boxs = $("#memberTable input:checked");
                if (boxs.length === 0 || boxs.length > 1) {
                    $.alert('${ctp:i18n("member.leave")}');
                    return;
                }
                memberId = boxs[0].value;
            }

            var checkResult = oManager.checkCanLeave(memberId, false);
            if (checkResult != null && checkResult != "") {
                $.alert(checkResult);
                return;
            }

            var member = mManager.viewOne(memberId);
            if (navigator.userAgent.toLowerCase().indexOf("nt 10.0") != -1 && navigator.userAgent.toLowerCase().indexOf("trident") != -1) {
                var leaveConfirm = confirm($.i18n("member.leave.confirm", member.name_text));
                if (leaveConfirm == true) {
                    var dialog = $.dialog({
                        id: "showLeavePageDialog",
                        url: "<c:url value='/organization/memberLeave.do' />?method=dealLeavePage&from=leave1&memberId=" + memberId + "${ctp:csrfSuffix()}",
                        title: $.i18n("member.out.service.procedure") + " : " + member.name_text,
                        width: 890,
                        height: 500,
                        targetWindow: window.top,
                        isClear: false,//OA-49174
                        buttons: [{
                            isEmphasize: true,
                            id: "okButton",
                            text: '完成',
                            handler: function () {
                                var rv = dialog.getReturnValue();
                                var lm = new memberLeaveManager();
                                lm.updateMemberToLeave(memberId, {
                                    success: function () {
                                        dialog.close();

                                        grid.grid.resizeGridUpDown('down');
                                        $("#welcome").show();
                                        $("#form_area").hide();
                                        //filter.enabled = false;
                                        filter.accountId = loginAccountId;
                                        $("#memberTable").ajaxgridLoad(filter);
                                    }
                                });

                            }
                        }]
                    });
                } else {
                    return false;
                }
            } else {
                $.confirm({
                    title: "${ctp:i18n('common.prompt')}",
                    msg: $.i18n("member.leave.confirm", member.name_text),
                    ok_fn: function () {
                        var dialog = $.dialog({
                            id: "showLeavePageDialog",
                            url: "<c:url value='/organization/memberLeave.do' />?method=dealLeavePage&from=leave1&memberId=" + memberId + "${ctp:csrfSuffix()}",
                            title: $.i18n("member.out.service.procedure") + " : " + member.name_text,
                            width: 890,
                            height: 500,
                            targetWindow: window.top,
                            isClear: false,//OA-49174
                            buttons: [{
                                isEmphasize: true,
                                id: "okButton",
                                text: '完成',
                                handler: function () {
                                    var rv = dialog.getReturnValue();
                                    var lm = new memberLeaveManager();
                                    lm.updateMemberToLeave(memberId, {
                                        success: function () {
                                            dialog.close();

                                            grid.grid.resizeGridUpDown('down');
                                            $("#welcome").show();
                                            $("#form_area").hide();
                                            //filter.enabled = false;
                                            filter.accountId = loginAccountId;
                                            $("#memberTable").ajaxgridLoad(filter);
                                        }
                                    });
                                }
                            }]
                        });
                    }
                });
            }
        }


        /** 工作交接 */
        function memberLeave2() {
            var boxs = $("#memberTable input:checked");
            if (boxs.length === 0 || boxs.length > 1) {
                $.alert('${ctp:i18n("member.leave1")}');
                return;
            }
            var memberId = boxs[0].value;
            var checkResult = oManager.checkCanLeave(memberId, false);
            if (checkResult != null && checkResult != "") {
                $.alert(checkResult);
                return;
            }

            var member = mManager.viewOne(memberId);
            if (navigator.userAgent.toLowerCase().indexOf("nt 10.0") != -1 && navigator.userAgent.toLowerCase().indexOf("trident") != -1) {
                var leaveConfirm = confirm("${ctp:i18n('member.disableandleaveconfirm.title')}");
                if (leaveConfirm == true) {
                    var dialog = $.dialog({
                        id: "showLeavePageDialog",
                        url: "<c:url value='/organization/memberLeave.do' />?method=dealLeavePage&memberId=" + memberId + "&noupdateState=1" + "${ctp:csrfSuffix()}",
                        title: $.i18n("member.leave.label") + " : " + member.name_text,
                        width: 890,
                        height: 500,
                        targetWindow: window.top,
                        isClear: false,//OA-49174
                        buttons: [{
                            isEmphasize: true,
                            id: "okButton",
                            text: $.i18n('common.button.ok.label'),
                            handler: function () {
                                var rv = dialog.getReturnValue();
                                dialog.close();
                                grid.grid.resizeGridUpDown('down');
                                $("#welcome").show();
                                $("#form_area").hide();
                                filter.enabled = true;
                                filter.accountId = loginAccountId;
                                $("#memberTable").ajaxgridLoad(filter);
                            }
                        }]
                    });
                }
            } else {
                $.confirm({
                    title: "${ctp:i18n('common.prompt')}",
                    msg: "${ctp:i18n('member.disableandleaveconfirm.title')}",
                    ok_fn: function () {
                        var dialog = $.dialog({
                            id: "showLeavePageDialog",
                            url: "<c:url value='/organization/memberLeave.do' />?method=dealLeavePage&memberId=" + memberId + "&noupdateState=1" + "${ctp:csrfSuffix()}",
                            title: $.i18n("member.leave.label") + " : " + member.name_text,
                            width: 890,
                            height: 500,
                            targetWindow: window.top,
                            isClear: false,//OA-49174
                            buttons: [{
                                isEmphasize: true,
                                id: "okButton",
                                text: $.i18n('common.button.ok.label'),
                                handler: function () {
                                    var rv = dialog.getReturnValue();
                                    dialog.close();
                                    grid.grid.resizeGridUpDown('down');
                                    $("#welcome").show();
                                    $("#form_area").hide();
                                    filter.enabled = true;
                                    filter.accountId = loginAccountId;
                                    $("#memberTable").ajaxgridLoad(filter);
                                }
                            }]
                        });
                    }
                });
            }
        }

        /** 人员调出 */
        function cancelMember() {
            var boxs = $("#memberTable input:checked");
            if (boxs.length === 0) {
                $.alert("${ctp:i18n('org.member_form.choose.personnel.canel')}");
                return;
            } else {
                $.confirm({
                    'title': "${ctp:i18n('common.prompt')}",
                    'msg': "${ctp:i18n('organization_post_cancel_ysno')}",
                    ok_fn: function () {
                        if (boxs.length === 0) {
                            $.alert("${ctp:i18n('org.member_form.choose.personnel.canel')}");
                            return;
                        } else if (boxs.length >= 1) {
                            var membersIds = "";
                            var members = new Array();
                            var isDeptOrManager = "";
                            boxs.each(function () {
                                membersIds += $(this).val() + ",";
                                members.push($(this).val());
                            });
                            isDeptOrManager = mManager.checkMember4DeptRole(membersIds);
                            if (isDeptOrManager.deptName.trim() != '') {
                                $.alert(isDeptOrManager.deptName + " ${ctp:i18n('member.deptmaster.or.admin.not.operation')}");
                                var temRoles = isDeptOrManager.deptIds.split(",");
                                for (i = 0; i < temRoles.length; i++) {
                                    $("input[value='" + temRoles[i] + "']").prop("checked", false);
                                }
                                return false;
                            } else {
                                if (boxs.length == 1) {
                                    var memberId = boxs[0].value;
                                    var member = mManager.viewOne(memberId);
                                    var dialog = $.dialog({
                                        id: "showLeavePageDialog",
                                        url: "<c:url value='/organization/memberLeave.do' />?method=dealLeavePage&memberId=" + memberId + "${ctp:csrfSuffix()}",
                                        title: "${ctp:i18n('member.callout')}: " + member.name_text,
                                        width: 890,
                                        height: 500,
                                        targetWindow: window.top,
                                        isClear: false,//OA-49174
                                        buttons: [{
                                            isEmphasize: true,
                                            id: "okButton",
                                            text: $.i18n('common.button.ok.label'),
                                            handler: function () {
                                                var rv = dialog.getReturnValue();
                                                mManager.cancelMember(members, {
                                                    success: function (memberBean) {
                                                        if (memberBean.SUCCESS && memberBean.SUCCESS == 'false') {
                                                            $.alert(memberBean.msg);
                                                            return;
                                                        }
                                                        $.messageBox({
                                                            'title': "${ctp:i18n('common.prompt')}",
                                                            'type': 0,
                                                            'imgType': 0,
                                                            'msg': "${ctp:i18n('organization.ok')}",
                                                            ok_fn: function () {
                                                                dialog.close();
                                                                isSearch = false;
                                                                $("#memberTable").ajaxgridLoad(filter);
                                                            }
                                                        });
                                                    }
                                                });
                                            }
                                        }]
                                    });

                                } else {
                                    mManager.cancelMember(members, {
                                        success: function (memberBean) {
                                            if (memberBean.SUCCESS && memberBean.SUCCESS == 'false') {
                                                $.alert(memberBean.msg);
                                                return;
                                            }
                                            $.messageBox({
                                                'title': "${ctp:i18n('common.prompt')}",
                                                'type': 0,
                                                'imgType': 0,
                                                'msg': "${ctp:i18n('organization.ok')}",
                                                ok_fn: function () {
                                                    isSearch = false;
                                                    $("#memberTable").ajaxgridLoad(filter);
                                                }
                                            });
                                        }
                                    });
                                }

                            }
                        }
                    },
                    cancel_fn: function () {
                        isSearch = false;
                        $("#memberTable").ajaxgridLoad(filter);
                    }
                });
            }
        }

        function delMembers() {
            var boxs = $("#memberTable input:checked");
            if (boxs.length === 0) {
                $.alert("${ctp:i18n('org.member_form.choose.personnel')}");
                return;
            } else {
                var confirm = $.confirm({
                    'title': "${ctp:i18n('common.prompt')}",
                    'msg': "${ctp:i18n('org.member_form.choose.member.delete')}",
                    ok_fn: function () {
                        var boxs = $("#memberTable input:checked");
                        if (boxs.length === 0) {
                            $.alert("${ctp:i18n('org.member_form.choose.personnel')}");
                            return;
                        } else if (boxs.length >= 1) {
                            var members = new Array();
                            boxs.each(function () {
                                members.push($(this).val());
                            });
                            if (getCtpTop() && getCtpTop().startProc) getCtpTop().startProc();
                            mManager.deleteMembers(members, {
                                success: function (memberBean) {
                                    try {
                                        if (getCtpTop() && getCtpTop().endProc) {
                                            getCtpTop().endProc()
                                        }
                                    } catch (e) {
                                    }
                                    ;
                                    if (memberBean.SUCCESS && memberBean.SUCCESS == 'false') {
                                        $.alert(memberBean.msg);
                                        return;
                                    }
                                    $.messageBox({
                                        'title': "${ctp:i18n('common.prompt')}",
                                        'type': 0,
                                        'imgType': 0,
                                        'msg': "${ctp:i18n('organization.ok')}",
                                        ok_fn: function () {
                                            if ("" !== preDeptId) {
                                                filter = new Object();
                                                filter.deptId = preDeptId;
                                                filter.enabled = true;
                                                filter.accountId = loginAccountId;
                                                filter.showByType = "showByDepartment";
                                                filter.deptId = preDeptId;
                                                filter.subMembers = $("#subMembers").prop("checked");

                                                $("#memberTable").ajaxgridLoad(filter);
                                                grid.grid.resizeGridUpDown('down');
                                                getCount();
                                                $("#form_area").hide();
                                                $("#button_area").hide();
                                                $("#welcome").show();
                                            } else {
                                                filter = new Object();
                                                filter.deptId = preDeptId;
                                                filter.enabled = true;
                                                filter.accountId = loginAccountId;

                                                $("#memberTable").ajaxgridLoad(filter);
                                                grid.grid.resizeGridUpDown('down');
                                                getCount();
                                                $("#form_area").hide();
                                                $("#button_area").hide();
                                                $("#welcome").show();
                                                //location.reload();
                                            }
                                        }
                                    });
                                }
                            });
                        }
                    },
                    cancel_fn: function () {
                    }
                });
            }
        }

        //人员修改
        function editMember() {
            toOuter = false;
            var boxs = $("#memberTable input:checked");
            if (boxs.length === 0) {
                $.alert("${ctp:i18n('org.member_form.choose.personnel.edit')}");
                return;
            } else if (boxs.length > 1) {
                $.alert("${ctp:i18n('org.member_form.choose.personnel.one.edit')}");
                return;
            } else {
                document.getElementById("isNewMember").value = false;
                grid.grid.resizeGridUpDown('middle');
                $("#form_area").clearform();
                $('#name').dataI18n({
                    type: 'dataI18n',
                    mode: 1,
                    category: 'organization.member.name',
                    i18nSwitch: 'on',
                    categoryName: "${ctp:i18n('org.member_form.name.label')}"
                });
                clearCustomSelectField();
                $("tr[class='forInter']").show();
                $("tr[class='forOuter']").hide();
                $("#imageid").val("");
                $("#secondPostIds").val("");//OA-41812
                var mDetail = mManager.viewOne(boxs[0].value);
                getlocation();
                $("#password").val("~`@%^*#?");
                $("#password2").val("~`@%^*#?");
                $("#sortIdtype1").prop("checked", "checked");
                $("#memberForm").fillform(mDetail);
                $("#name").setI18nVal(mDetail.name);
                showImage();
                $("#loginName").attr("readonly", "readonly");
                $("#isChangePWD").val("false");
                $(".calendar_icon_area").show();
                fillSelectPeople(mDetail);
                $("#loginName").attr('readonly', 'readonly');
                $("#button_area").show();
                $("#form_area").show();
                $("#welcome").hide();
                isNewMember = false;
                $("#lconti").hide();
                $("#memberForm").enable();
                $("#name").prop("disabled", false);
                $("#state").disable();
                ldapSet4Edit("edit", mDetail.ldapUserCodes);
                showConPostInfo(mDetail.conPostsInfo);
                $("#isLoginNameModifyed").val(false);
                //办公电话提示
                $("#officenumber").attr("placeholder", "${ctp:i18n('personal.info.telephone.placeholder')}");
                if (!supportPlaceholder) {
                    var value = $("#officenumber").val();
                    if (!value) {
                        $("#officenumber").val("${ctp:i18n('personal.info.telephone.placeholder')}").addClass("phcolor");
                    } else {
                        $("#officenumber").removeClass("phcolor");
                    }
                }
                $('#sssssssss').height($('#grid_detail').height() - 50).css('overflow', 'auto');
            }
            $("#name_text").blur();
        }

        //搜索框
        var searchobj = $.searchCondition({
            top: 7,
            right: 10,
            searchHandler: function () {
                s = searchobj.g.getReturnValue();
                s.enabled = filter.enabled;
                s.accountId = loginAccountId;
                filter.cond = 'yes';
                if ('state' == filter.condition) {
                    s.state = filter.value;
                }
                if (null != filter.state) {
                    s.state = filter.state;
                }
                if (null != preDeptId && '' != preDeptId) {
                    s.deptId = preDeptId;
                    s.subMembers = $("#subMembers").prop("checked");
                }
                isSearch = true;
                $("#memberTable").ajaxgridLoad(s);
            },
            conditions: [{
                id: 'search_name',
                name: 'search_name',
                type: 'input',
                text: "${ctp:i18n('member.list.find.name')}",
                value: 'name',
                maxLength: 40
            },
                {
                    id: 'search_loginName',
                    name: 'search_loginName',
                    type: 'input',
                    text: "${ctp:i18n('member.list.find.loginname')}",
                    value: 'loginName',
                    maxLength: 100
                },
                {
                    id: 'search_department',
                    name: 'search_department',
                    type: 'selectPeople',
                    text: "${ctp:i18n('import.type.dept')}",
                    value: 'orgDepartmentId',
                    comp: "type:'selectPeople',panels:'Department',selectType:'Department',maxSize:'1',onlyLoginAccount: true,accountId:'${accountId}'"
                },
                {
                    id: 'search_post',
                    name: 'search_post',
                    type: 'selectPeople',
                    text: "${ctp:i18n('org.member_form.primaryPost.label')}",
                    value: 'orgPostId',
                    comp: "type:'selectPeople',panels:'Post',selectType:'Post',maxSize:'1',onlyLoginAccount: true,accountId:'${accountId}'"
                },
                {//副岗查询
                    id: 'search_secpost',
                    name: 'search_secpost',
                    type: 'selectPeople',
                    text: "${ctp:i18n('org.member_form.secondPost.label')}",
                    value: 'secPostId',
                    comp: "type:'selectPeople',panels:'Post',selectType:'Post',maxSize:'1',onlyLoginAccount: true,accountId:'${accountId}'"
                },
                {
                    id: 'search_level',
                    name: 'search_level',
                    type: 'selectPeople',
                    text: "${ctp:i18n('org.member_form.levelName.label')}",
                    value: 'orgLevelId',
                    comp: "type:'selectPeople',panels:'Level',selectType:'Level',maxSize:'1',onlyLoginAccount: true,accountId:'${accountId}'"
                }, {
                    id: 'search_workLocal',
                    name: 'search_workLocal',
                    type: 'input',
                    text: "${ctp:i18n('member.location')}",
                    value: 'search_workLocalId',
                    maxLength: 40
                }, {
                    id: 'search_code',
                    name: 'search_code',
                    type: 'input',
                    text: "${ctp:i18n('org.member_form.code')}",
                    value: 'code',
                    maxLength: 20
                }
            ]
        });


        //连续添加人员，保留部门排序号岗位职务
        function clear4addconti() {
            //清除头像
            clearAddImage();
            //连续添加被选中时，按钮显示正常
            $("#button_area").enable();
            $("#id").val("-1");
            $('#name').dataI18n({
                type: 'dataI18n',
                mode: 1,
                category: 'organization.member.name',
                i18nSwitch: 'on',
                categoryName: "${ctp:i18n('org.member_form.name.label')}"
            });
            $("#loginName").val("");
            var initpwd = oManager.getInitPWDForPage();
            if (null != initpwd && initpwd != "" && initpwd != false) {
                initpwd = initpwd.substring(8);
            } else {
                initpwd = "";
            }
            $("#password").val(initpwd);
            $("#password2").val(initpwd);
            $("#birthday").val("");
            $("#officenumber").val("");
            $("#telnumber").val("");
            $("#emailaddress").val("");
            $("#description").val("");
            $("#secondPost").val("");
            $("#secondPostIds").val("");
            $("#ldapUserCodes").val("");
            $("#workspace").val("");
            $("#workLocal").val("");
            var sort = 1;
            if (parseInt($("#sortId").val()) >= 999999999) {
                sort = 999999999;
            } else {
                sort = parseInt($("#sortId").val()) + 1;
            }
            $("#sortId").val(sort);
            $("#roles").val('');
            $("#roleIds").val('');
            clearCustomSelectField();

            var role = rManager.getDefultRoleByAccount(loginAccountId);
            if (null != role) {
                $("#roles").val(role.showName);
                $("#roleIds").val(role.id);
            }
            //勾选连续添加后列表根据之前的条件自动刷新列表
            filter = new Object();
            if ("" !== preDeptId) {
                filter.deptId = preDeptId;
                filter.enabled = true;
                filter.showByType = "showByDepartment";
                filter.deptId = preDeptId;
                filter.subMembers = $("#subMembers").prop("checked");
            } else {
                filter.enabled = true;
            }
            filter.accountId = loginAccountId;
            isSearch = false;
            $("#memberTable").ajaxgridLoad(filter);
            $("#form_area").show();
            $("#welcome").hide();
            $("#memberForm").resetValidate();
            $("#name_text").focus();
        }

        //清除已有的头像信息,回归默认头像
        function clearAddImage() {
            $("#imageid").val("");
            //回归到默认头像
            var imgStr = "<img src='${ctp:avatarImageUrl(1)}' width='100px' height='120px'>";
            $("#viewImageIframe").get(0).innerHTML = imgStr;
        }

        //登录名修改提示与清空密码
        $("#loginName").click(function () {
            var ln = $("#loginName").val();
            if (ln === "") {
                var initpwd = oManager.getInitPWDForPage();
                if (null != initpwd && initpwd != "" && initpwd != false) {
                    initpwd = initpwd.substring(8);
                } else {
                    initpwd = "";
                }
                $("#password").val(initpwd);
                $("#password2").val(initpwd);
            }
            $("#loginName").removeAttr("readonly");
            if (isNewMember || 'true' == isNewMember || undefined == isNewMember || 'undefined' == isNewMember || $("#isLoginNameModifyed").val() == 'true') {
                $("#loginName").focus();
            } else {
                var confirm = $.confirm({
                    'title': "${ctp:i18n('common.prompt')}",
                    'msg': "${ctp:i18n('account.system.loginstaff.info')}",
                    ok_fn: function () {
                        $("#loginName").focus();
                        $("#isLoginNameModifyed").val(true);
                        //如果ctpConfig开启了禁止OA修改LDAP密码则只修改登录名不清空密码
                        var disableModifyLdapPsw = "${disableModifyLdapPsw}";
                        if (('true' == "${isLdapEnabled}") && (true == disableModifyLdapPsw || 'true' == disableModifyLdapPsw) && $("#ldapUserCodes").val() != '') {
                        } else if ($("#ldapUserCodes").val() == '') {
                            $("#password").val("");
                            $("#password2").val("");
                            $("#isChangePWD").val("true");
                        }
                        $("input[type='radio'][name='enabled'][value='true']").prop("checked", "checked");
                        $("#state").val("1");
                    },
                    cancel_fn: function () {
                        $("#name_text").focus();
                        $("#loginName").attr("readonly", "readonly");
                    }
                });
            }
        });
        $("#password").click(function () {
            $("#isChangePWD").val("true");
        });
        //绑定选人界面区域
        //部门
        $("#deptName").click(function () {
            $("#memberForm").resetValidate();
            $.selectPeople({
                type: 'selectPeople',
                panels: 'Department',
                selectType: 'Department',
                minSize: 1,
                maxSize: 1,
                onlyLoginAccount: true,
                accountId: '${accountId}',
                returnValueNeedType: false,
                callback: function (ret) {
                    $("#deptName").val(oManager.showDepartmentFullPath(ret.value));
                    $("#deptName").attr("title", oManager.showDepartmentFullPath(ret.value));
                    $("#memberForm #orgDepartmentId").val(ret.value);
                    // 如果换了部门就把原来的部门角色清除
                    if ($("#id").val() != -1) {
                        var tempOne = mManager.viewOne($("#id").val());
                        $("#roles").val("");
                        $("#roleIds").val("");
                        $("#roles").val(tempOne.roles);
                        $("#roleIds").val(tempOne.roleIds);
                    }
                }
            });
        });
        //主岗
        $("#primaryPost").click(function () {
            $("#memberForm").resetValidate();
            $.selectPeople({
                type: 'selectPeople',
                panels: 'Post',
                selectType: 'Post',
                minSize: 1,
                maxSize: 1,
                onlyLoginAccount: true,
                accountId: '${accountId}',
                returnValueNeedType: false,
                callback: function (ret) {
                    $("#primaryPost").val(ret.text);
                    $("#orgPostId").val(ret.value);
                }
            });
        });
        //副岗
        $("#secondPost").click(function () {
            var sP4People = $("#secondPostIds").val();
            $.selectPeople({
                type: 'selectPeople',
                panels: 'Department',
                selectType: 'Post',
                onlyLoginAccount: true,
                accountId: '${accountId}',
                returnValueNeedType: true,
                params: {value: sP4People},
                minSize: 0,
                callback: function (ret) {
                    $("#memberForm").validate();
                    $("#secondPost").val(ret.text);
                    $("#secondPostIds").val(ret.value);

                    var secondPostIdsStr = $("#secondPostIds").val();
                    var mainPostIdsStr = "Department_Post|" + $("#orgDepartmentId").val() + "_" + $("#orgPostId").val();
                    if (secondPostIdsStr != null && secondPostIdsStr != "") {
                        var temSecondPostIds = secondPostIdsStr.split(",");
                        for (i = 0; i < temSecondPostIds.length; i++) {
                            var temSecondPostIds0 = temSecondPostIds[i];
                            if (mainPostIdsStr == temSecondPostIds0) {
                                $.alert("${ctp:i18n('member.mainpost.vicepost.not.same')}");
                                $("#secondPost").val("");
                                $("#secondPostIds").val("");
                                return true;
                            }
                        }
                    }
                }
            });
        });
        //职务
        $("#levelName").click(function () {
            $("#memberForm").resetValidate();
            $.selectPeople({
                type: 'selectPeople',
                panels: 'Level',
                selectType: 'Level',
                minSize: 1,
                maxSize: 1,
                onlyLoginAccount: true,
                accountId: '${accountId}',
                returnValueNeedType: false,
                callback: function (ret) {
                    $("#levelName").val(ret.text);
                    $("#orgLevelId").val(ret.value);
                }
            });
        });


        $("#extAccountName").click(function () {
            $.selectPeople({
                type: 'selectPeople',
                panels: 'Outworker',
                alwaysShowPanels: 'Outworker',
                selectType: 'Department',
                minSize: 1,
                maxSize: 1,
                onlyLoginAccount: true,
                accountId: '${accountId}',
                showAllOuterDepartment: true,
                returnValueNeedType: false,
                callback: function (ret) {
                    $("#extAccountName").val(ret.text);
                    $("#orgDepartmentId").val(ret.value);
                    var workScope = oManager.getParentUnitById(ret.value);
                    if (null != workScope && undefined != workScope) {
                        $("#extWorkScope").val(workScope.name);
                        //自动填充工作范围
                        if (workScope.type == 'Department') {
                            $("#extWorkScopeValue").val("Department|" + workScope.id);
                        } else {
                            $("#extWorkScopeValue").val("Account|" + workScope.id);
                        }
                    }
                }
            });
        });
        //外单位人员工作范围
        $("#extWorkScope").click(function () {
            $("#memberForm").resetValidate();
            tempVal = $("#extWorkScopeValue").val();
            $.selectPeople({
                type: 'selectPeople',
                panels: 'Department',
                selectType: 'Account,Department,Member',
                minSize: 1,
                params: {value: tempVal},
                onlyLoginAccount: true,
                accountId: '${accountId}',
                hiddenSaveAsTeam: true,
                callback: function (ret) {
                    $("#extWorkScope").val(ret.text);
                    $("#extWorkScopeValue").val(ret.value);
                }
            });
        });
        //角色-用于内部人员转编外人员
        $("#extRoles").click(function () {
            $("#memberForm").resetValidate();
            var tRoles = $("#extRoleIds").val();
            dialog4Role = $.dialog({
                url: "<c:url value='/organization/member.do' />?method=member2Role4Ext&accountId=" + loginAccountId,
                title: "${ctp:i18n('member.authorize.role')}",
                width: 400,
                height: 300,
                isClear: false,
                transParams: tRoles,
                buttons: [{
                    id: "roleOK",
                    text: "${ctp:i18n('guestbook.leaveword.ok')}",
                    handler: function () {
                        var roleIds = dialog4Role.getReturnValue();
                        if (roleIds == "") {//编外人员后台会清空所有内部角色，如果没有选择角色，这里必须默认设置一个默认角色
                            $.alert("${ctp:i18n('member.role.checkroles')}");
                            var role = oManager.getRoleByName('ExternalStaff', loginAccountId);
                            if (null != role) {
                                $("#extRoles").val(role.showName);
                                $("#extRoleIds").val(role.id);
                            }
                        } else {
                            var roleStr = "";
                            for (var i = 0; i < roleIds.length; i++) {
                                var rObject = oManager.getRoleById(roleIds[i]);
                                roleStr = roleStr + rObject.showName;
                                if (i !== roleIds.length - 1) {
                                    roleStr = roleStr + ",";
                                }
                            }
                            ;
                            $("#extRoles").val(roleStr);
                            $("#extRoleIds").val(roleIds);
                        }
                        dialog4Role.close();
                    }
                },
                    {
                        id: "roleConcel",
                        text: "${ctp:i18n('systemswitch.cancel.lable')}",
                        handler: function () {
                            dialog4Role.close();
                        }
                    }]
            });
        });

        //角色
        $("#roles").click(function () {
            dialog4Role = null;
            var tRoles = $("#roleIds").val();
            dialog4Role = $.dialog({
                url: "<c:url value='/organization/member.do' />?method=member2Role&accountId=" + loginAccountId + "${ctp:csrfSuffix()}",
                title: "${ctp:i18n('member.authorize.role')}",
                width: 420,
                height: 300,
                isClear: false,
                transParams: tRoles,
                buttons: [{
                    isEmphasize: true,
                    id: "roleOK",
                    text: "${ctp:i18n('guestbook.leaveword.ok')}",
                    handler: function () {
                        if (getCtpTop() && getCtpTop().startProc) getCtpTop().startProc();
                        var roleIds = dialog4Role.getReturnValue();
                        if (roleIds == "") {
                            var entityIds = "";
                            entityIds = entityIds + $("#orgAccountId").val() + ",";
                            entityIds = entityIds + $("#orgDepartmentId").val() + ",";
                            entityIds = entityIds + $("#orgPostId").val() + ",";
                            entityIds = entityIds + $("#orgLevelId").val() + ",";
                            entityIds = entityIds + $("#secondPostIds").val() + ",";
                            var mManager2 = new memberManager();
                            var cMemberNoRoles = mManager2.checkNoRoles(entityIds);
                            try {
                                if (getCtpTop() && getCtpTop().endProc) {
                                    getCtpTop().endProc()
                                }
                            } catch (e) {
                            }
                            ;
                            if (cMemberNoRoles) {
                                $.alert("${ctp:i18n('member.role.checkroles')}");
                                var defultRole = rManager.getDefultRoleByAccount(loginAccountId);
                                if (null != defultRole) {
                                    $("#roles").val(defultRole.showName);
                                    $("#roleIds").val(defultRole.id);
                                }
                            } else {
                                $("#roles").val("");
                                $("#roleIds").val("");
                            }
                        } else {
                            var result = rManager.checkRoles(roleIds.toString(), $("#id").val(), $("#orgDepartmentId").val());
                            try {
                                if (getCtpTop() && getCtpTop().endProc) {
                                    getCtpTop().endProc()
                                }
                            } catch (e) {
                            }
                            ;
                            if (result) {
                                var success = result.success;
                                if ("false" == success) {
                                    $.alert(result.info);
                                    return;
                                } else {
                                    var roleStr = result.roleStr;
                                    $("#roles").val(roleStr);
                                    $("#roleIds").val(roleIds);
                                }
                            }
                        }
                        dialog4Role.close();
                    }
                },
                    {
                        id: "roleConcel",
                        text: "${ctp:i18n('systemswitch.cancel.lable')}",
                        handler: function () {
                            dialog4Role.close();
                        }
                    }]
            });
            $("#memberForm").resetValidate();
        });

        // 表单JSON无分区无分组提交事件
        $("#btnok").click(function () {
            //人员无角色的校验2013-8-1由于需求变更修改代码
            if ($("#roleIds").val() == "") {
                var entityIds = "";
                var memberId = $("#id").val();
                if (memberId != "-1") {
                    entityIds = entityIds + memberId + ",";
                }
                entityIds = entityIds + $("#orgAccountId").val() + ",";
                entityIds = entityIds + $("#orgDepartmentId").val() + ",";
                entityIds = entityIds + $("#orgPostId").val() + ",";
                entityIds = entityIds + $("#orgLevelId").val() + ",";
                entityIds = entityIds + $("#secondPostIds").val() + ",";
                var mManager2 = new memberManager();
                var cMemberNoRoles = mManager2.checkNoRoles(entityIds);
                if (cMemberNoRoles) {
                    $.alert("${ctp:i18n('member.role.checkroles')}");
                    var defultRole = rManager.getDefultRoleByAccount(loginAccountId);
                    if (null != defultRole) {
                        $("#roles").val(defultRole.showName);
                        $("#roleIds").val(defultRole.id);
                    }
                    return;
                }
            }
            //密码一致校验
            if ($("#password").val() !== $("#password2").val()) {
                $.alert("${ctp:i18n('account.system.newpassword.again.not.consistent')}");
                $("#password").val("");
                $("#password2").val("");
                $("#password").focus();
                return;
            }
            //输入正确性校验
            if (!($("#memberForm").validate())) {
                $("#button_area").enable();
                return;
            }
            if ($("#orgPostId").val() == '-1') {
                $.alert("请选择主岗！");//OA-54001
                return;
            }
            if ('true' == "${isLdapEnabled}" && 'false' == "${LdapCanOauserLogon}") {
                if ($("input[type='radio'][name='ldapSetType'][value='select']").prop("checked")) {
                    if ($("#ldapUserCodes").val() == '') {
                        $.alert("${ctp:i18n('org.alert.ldapUserCodeNotNull')}");
                        return;
                    }
                }
                if (isNewMember == false) {
                    if ($("#ldapUserCodes").val() == '') {
                        $.alert("${ctp:i18n('org.alert.ldapUserCodeNotNull')}");
                        return;
                    }
                }
            }
            //设置办公电话的默认值
            if ($("#officenumber").val() == "${ctp:i18n('personal.info.telephone.placeholder')}") {
                $("#officenumber").val("");
            }
            $("#memberForm").resetValidate();
            if ($("#id").val() === '-1') {
                if (getCtpTop() && getCtpTop().startProc) getCtpTop().startProc();
                if ($("#name_text").prop("readonly") == true) {
                    $("#i18nEnable").val(true);
                } else {
                    $("#i18nEnable").val(false);
                }
                mManager.createMember(loginAccountId, $("#memberForm").formobj(), {
                    success: function (memberBean) {
                        try {
                            if (getCtpTop() && getCtpTop().endProc) {
                                getCtpTop().endProc()
                            }
                        } catch (e) {
                        }
                        ;
                        if (memberBean.SUCCESS && memberBean.SUCCESS == 'false') {
                            $.alert(memberBean.msg);
                            return;
                        }
                        if ($("#conti").prop("checked")) {
                            clear4addconti();
                        } else {
                            $.messageBox({
                                'title': "${ctp:i18n('common.prompt')}",
                                'type': 0,
                                'imgType': 0,
                                'msg': "${ctp:i18n('organization.ok')}",
                                ok_fn: function () {
                                    filter = new Object();
                                    if ("" !== preDeptId) {
                                        filter.deptId = preDeptId;
                                        filter.showByType = "showByDepartment";
                                        filter.deptId = preDeptId;
                                        filter.subMembers = $("#subMembers").prop("checked");
                                    } else {
                                        filter.enabled = true;
                                    }

                                    filter.accountId = loginAccountId;
                                    $("#memberTable").ajaxgridLoad(filter);
                                    grid.grid.resizeGridUpDown('down');
                                    getCount();
                                    $("#form_area").hide();
                                    $("#button_area").hide();
                                    $("#welcome").show();

                                }
                            });
                        }
                    }
                });
            } else {
                if (toOuter) {
                    $("#isInternal").val("false");
                } else {
                    //xxx的部门发生变化，其原部门角色：XX、YY、ZZ，将带到新部门，是否继续
                    //点“确定”：带入到新部门
                    //点“取消”：保留在当前页面
                    var tempOne = mManager.viewOne($("#id").val());
                    var oldDeptId = tempOne["orgDepartmentId"];
                    if (null != oldDeptId || '-1' != oldDeptId) {
                        var newDeptId = $("#orgDepartmentId").val();
                        if (oldDeptId != newDeptId) {
                            //所有部门角色
                            var allDeptRoles = tempOne["allDeptRoles"];
                            var allDeptRolesArray = allDeptRoles.split(",");
                            //已选角色
                            var selectDeptRoles = $("#roles").val();
                            var selectDeptRolesArray = selectDeptRoles.split(",");

                            var repeatDeptRoleName = "";
                            for (i = 0; i < allDeptRolesArray.length; i++) {
                                for (j = 0; j < selectDeptRolesArray.length; j++) {
                                    if (allDeptRolesArray[i] == selectDeptRolesArray[j]) {
                                        if (repeatDeptRoleName == "") {
                                            repeatDeptRoleName = allDeptRolesArray[i];
                                        } else {
                                            repeatDeptRoleName = repeatDeptRoleName + "," + allDeptRolesArray[i];
                                        }
                                    }
                                }
                            }
                            if (repeatDeptRoleName != "") {
                                var memberName = $("#name").val();
                                var showConfirmMessage = memberName + "的部门发生变化,其部门角色: " + repeatDeptRoleName + " 将带到新部门，是否继续?";
                                var deptRoleConfirm = confirm(showConfirmMessage);
                                if (deptRoleConfirm != true) {
                                    return;
                                }
                            }
                        }
                    }
                }

                if (getCtpTop() && getCtpTop().startProc) getCtpTop().startProc();
                if ($("#name_text").prop("readonly") == true) {
                    $("#i18nEnable").val(true);
                } else {
                    $("#i18nEnable").val(false);
                }
                mManager.updateMember($("#memberForm").formobj(), {
                    success: function (memberBean) {
                        if (memberBean.SUCCESS && memberBean.SUCCESS == 'false') {
                            try {
                                if (getCtpTop() && getCtpTop().endProc) {
                                    getCtpTop().endProc()
                                }
                            } catch (e) {
                            }
                            ;
                            $.alert(memberBean.msg);
                            return;
                        }
                        $.messageBox({
                            'title': "${ctp:i18n('common.prompt')}",
                            'type': 0,
                            'imgType': 0,
                            'msg': "${ctp:i18n('organization.ok')}",
                            ok_fn: function () {
                                //filter = new Object();
                                if ("" !== preDeptId) {
                                    filter.deptId = preDeptId;
                                    filter.showByType = "showByDepartment";
                                } else {
                                    filter.enabled = true;
                                }
                                if (isSearch) {
                                    $("#memberTable").ajaxgridLoad(s);
                                } else {
                                    $("#memberTable").ajaxgridLoad(filter);
                                }

                                grid.grid.resizeGridUpDown('down');
                                getCount();
                                $("#form_area").hide();
                                $("#button_area").hide();
                                $("#welcome").show();
                            }
                        });
                        try {
                            if (getCtpTop() && getCtpTop().endProc) {
                                getCtpTop().endProc()
                            }
                        } catch (e) {
                        }
                        ;
                    }
                });

            }
        });

        $("#btncancel").click(function () {
            location.reload();
        });

        /******ldap/ad******/
        //屏蔽和现实ldap的按钮
        if ('true' == "${isLdapEnabled}") {
            $("tr[class='ldapClass']").show();
            $("#ldapSet_tr1").show();
            $("#ldapSet_tr2").hide();
        } else {
            $("tr[class='ldapClass']").hide();
            toolBarVar.hideBtn("importLDIF");
        }

        /**
         前台修改密码的校验：
         1.没有打开oa不能修改ad密码的开关，总是能修改。
         2.打开了oa不能修改ad密码的开关
         a.修改人员信息，账号已经绑定，就不能修改密码
         b.修改人员信息，账号没有绑定，但是不允许开启ad的情况下oa账号登录，也不能修改密码
         c.修改人员信息，账号没有绑定，并且允许开启ad的情况下oa账号登录，则可以修改。
         d.新建人员时，不允许开启ad的情况下oa账号登录，不能修改密码。
         e.新建人员时，允许开启ad的情况下oa账号登录，不确定此人到底需不需要进行绑定，默认可以修改密码。
         ps: 有一个问题：
         在允许开启ad的情况下oa账号登录时，并且打开了oa不能修改ad密码的开关。
         已经绑定的人员要修改oa的密码，要先删除绑定的条目保存一次，才能再次修改密码。
         （其实也没多大问题） */
        function ldapSet4Edit(type, ldapUserCodes) {
            if ('true' == "${isLdapEnabled}") {
                $("#ldapSet_tr0").hide();
                $("#ldapSet_tr1").show();
                $("#ldapSet_tr2").hide();
                if (type == "edit") {
                    //打开了了oa不能修改ad密码的开关
                    if ('true' == disableModifyLdapPsw || true == disableModifyLdapPsw) {
                        //如果已经绑定了，就不能修改密码
                        if (ldapUserCodes != "" && ldapUserCodes != null && ldapUserCodes != undefined) {
                            $("#password").disable();
                            $("#password2").disable();
                        } else if ('false' == "${LdapCanOauserLogon}") {//如果没有绑定，但是不允许在开启ad的情况下，oa账号登录时，也不能修改密码
                            $("#password").disable();
                            $("#password2").disable();
                        }
                        //其他情况：允许在开启ad的情况下，oa账号登录。并且账号没有进行绑定，则可以修改。
                    }
                }
            }
        }

        //LDAP导入文件
        function impPost() {
            /*     var sendResult = v3x.openWindow({
      url: "/seeyon/ldap/ldap.do?method=importLDIF",
      width: "390",
      height: "155",
      resizable: "false",
      scrollbars: "yes"
    });
    if (!sendResult) {
      return;
    } else {
      filter = new Object();
      filter.enabled = null;
      filter.accountId = loginAccountId;
      isSearch = false;
      $("#memberTable").ajaxgridLoad(filter);
      grid.grid.resizeGridUpDown('middle');
      getCount();
      $("#welcome").show();
    } */

            dialog = $.dialog({
                width: 390,
                height: 175,
                isDrag: false,
                id: 'ldapImportdialog',
                url: '/seeyon/ldap/ldap.do?method=importLDIF' + "${ctp:csrfSuffix()}",
                title: "${ctp:i18n('ldap.impPost.ldif')}",
                closeParam: {
                    'show': true,
                    handler: function () {
                        filter = new Object();
                        filter.enabled = null;
                        filter.accountId = loginAccountId;
                        isSearch = false;
                        $("#memberTable").ajaxgridLoad(filter);
                        grid.grid.resizeGridUpDown('middle');
                        getCount();
                        $("#welcome").show();
                    }
                }
            });
        }

        /******ldap/ad end ******/
        /***conPostInfoTr兼职信息的显示与隐藏**/
        function showConPostInfo(conPosts) {
            if ("" === conPosts || null === conPosts || undefined === conPosts) {
                $("#conPostsTr").hide();
            } else {
                $("#conPostsTr").show();
            }
        }

        //离职人员点启用自动置为在职
        $(".m_enable").bind('click', function () {
            var is_checkEnable = $('input[name="enabled"]:checked').val();
            if ('true' == is_checkEnable) {
                $("#state").val("1");
            }

            if ($("#id").val() == '-1') {
                return;
            }
            if ('false' == is_checkEnable) {
                memberLeave("fromDisable");
            }
        });

        $('#grid_detail').resize(function () {
            if ($("#button_area").is(":hidden")) {
                $('#sssssssss').height($(this).height() - 0).css('overflow', 'auto');
            } else {
                $('#sssssssss').height($(this).height() - 50).css('overflow', 'auto');
            }
        });

        //工作地
        $("#workspace").click(function () {
            var dialog = $.dialog({
                width: 460,
                height: 300,
                id: 'workspaceDialog',
                title: "${ctp:i18n('system.enum.administrativeDivision')}",
                url: '${path}/enum.do?method=showAdministrativeDivision${ctp:csrfSuffix()}',
                targetWindow: window,
                transParams: $('#workLocal').val(),
                buttons: [{
                    text: "${ctp:i18n('common.button.ok')}",
                    id: 'ok',
                    handler: function () {
                        var localArray = dialog.getReturnValue();
                        if (localArray) {
                            $('#workspace').val(localArray.localStr);
                            $('#workLocal').val(localArray.localId);
                            dialog.close();
                        }
                    }
                }, {
                    text: "${ctp:i18n('common.button.cancel.label')}",
                    id: 'cancel',
                    handler: function () {
                        dialog.close();
                    }
                }]
            });
        });

        // 汇报人
        $("#reporterName").click(function () {
            $("#memberForm").resetValidate();
            var reporterName = $("#reporterName").val();
            var reporterId = $("#reporter").val();
            var reporterValue = "";
            if (reporterId != "-1" && reporterId != "") {
                reporterValue = 'Member|' + reporterId;
            }
            $.selectPeople({
                params: {
                    text: reporterName,
                    value: reporterValue
                },
                type: 'selectPeople',
                panels: 'Department',
                selectType: 'Member',
                minSize: 0,
                maxSize: 1,
                onlyLoginAccount: false,
                isNeedCheckLevelScope: false,
                accountId: '${accountId}',
                returnValueNeedType: false,
                callback: function (ret) {
                    $("#reporterName").val(ret.text);
                    $("#reporter").val(ret.value);
                    //刚修改完汇报人后清空title
                    $("#reporterName").attr("title", "");
                }
            });
        });

        $("#search_workLocal").click(function () {
            $('#search_workLocal').val("");
            $("#search_distpicker").enable();
            var dialog = $.dialog({
                width: 460,
                height: 300,
                id: 'workspaceDialog',
                title: "${ctp:i18n('system.enum.administrativeDivision')}",
                url: '${path}/enum.do?method=showAdministrativeDivision${ctp:csrfSuffix()}',
                targetWindow: window,
                transParams: $('#search_workLocal').val(),
                buttons: [{
                    text: "${ctp:i18n('common.button.ok')}",
                    id: 'ok',
                    handler: function () {
                        var localArray = dialog.getReturnValue();
                        if (localArray) {
                            $('#search_workLocal').val(localArray.localStr);
                            dialog.close();
                        }
                    }
                }, {
                    text: "${ctp:i18n('common.button.cancel.label')}",
                    id: 'cancel',
                    handler: function () {
                        dialog.close();
                    }
                }]
            });
        });

        function getlocation() {
            //清空工作地信息
            $("#workspace").val("");
            $("#workLocal").val("");
        }

        function getWindowHeight() {
            if (window.innerHeight != undefined) {
                return window.innerHeight;
            } else {
                var B = document.body, D = document.documentElement;
                return Math.min(D.clientHeight, B.clientHeight);
            }
        }


        var currentSelectPeopleCustomId = "";//当前操作的自定义选人/选部门字段的id
        $("[name='customer_field_selectMember']").click(function () {
            // 选人自定义字段
            var fieldTxt = this.value;
            var fieldTxt_id = this.id;//-38947843635897489_txt
            var fieldValue_id = fieldTxt_id.substring(0, fieldTxt_id.length - 4);
            var id = $("#" + fieldValue_id).val();
            var value = "";
            if (id != "-1" && id != "") {
                value = 'Member|' + id;
            }

            currentSelectPeopleCustomId = fieldValue_id;
            $.selectPeople({
                params: {
                    text: fieldTxt,
                    value: value
                },
                type: 'selectPeople',
                panels: 'Department',
                selectType: 'Member',
                minSize: 0,
                maxSize: 1,
                onlyLoginAccount: true,
                isNeedCheckLevelScope: false,
                accountId: '${accountId}',
                returnValueNeedType: false,
                callback: function (ret) {
                    setCustomSelectPeopleField(currentSelectPeopleCustomId, ret.text, ret.value);
                }
            });
        });

        $("[name='customer_field_selectDepartment']").click(function () {
            // 选人自定义字段
            var fieldTxt = this.value;
            var fieldTxt_id = this.id;//-38947843635897489_txt
            var fieldValue_id = fieldTxt_id.substring(0, fieldTxt_id.length - 4);
            var id = $("#" + fieldValue_id).val();
            var value = "";
            if (id != "-1" && id != "") {
                value = 'Department|' + id;
            }

            currentSelectPeopleCustomId = fieldValue_id;
            $.selectPeople({
                params: {
                    text: fieldTxt,
                    value: value
                },
                type: 'selectPeople',
                panels: 'Department',
                selectType: 'Department',
                minSize: 0,
                maxSize: 1,
                onlyLoginAccount: true,
                isNeedCheckLevelScope: false,
                accountId: '${accountId}',
                returnValueNeedType: false,
                callback: function (ret) {
                    setCustomSelectPeopleField(currentSelectPeopleCustomId, ret.text, ret.value);
                }
            });
        });

        function setCustomSelectPeopleField(id, text, value) {
            if (id === "") {
                return;
            }
            $("#" + id).val(value);
            $("#" + id + "_txt").val(text);
            currentSelectPeopleCustomId = "";
        }

        function clearCustomSelectField() {
            var customer_fields = document.getElementsByName("customer_field");
            for (var i = 0; i < customer_fields.length; i++) {
                customer_fields[i].value = "";
            }

            var customer_field_selectMembers = document.getElementsByName("customer_field_selectMember");
            for (var i = 0; i < customer_field_selectMembers.length; i++) {
                customer_field_selectMembers[i].value = "";
            }

            var customer_field_selectDepartments = document.getElementsByName("customer_field_selectDepartment");
            for (var i = 0; i < customer_field_selectDepartments.length; i++) {
                customer_field_selectDepartments[i].value = "";
            }
        }

        var supportPlaceholder = 'placeholder' in document.createElement('input');

    });
</script>