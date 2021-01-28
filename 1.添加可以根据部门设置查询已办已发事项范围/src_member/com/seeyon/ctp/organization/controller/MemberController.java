/**
 * $Author$
 * $Rev$
 * $Date::                     $:
 * <p>
 * Copyright (C) 2012 Seeyon, Inc. All rights reserved.
 * <p>
 * This software is the proprietary information of Seeyon, Inc.
 * Use is subject to license terms.
 */
package com.seeyon.ctp.organization.controller;

import java.io.PrintWriter;
import java.lang.reflect.Method;
import java.math.BigDecimal;
import java.text.DecimalFormat;
import java.util.ArrayList;
import java.util.Collections;
import java.util.Date;
import java.util.HashMap;
import java.util.HashSet;
import java.util.Iterator;
import java.util.LinkedList;
import java.util.List;
import java.util.Locale;
import java.util.Map;
import java.util.Set;

import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.http.HttpSession;

import org.apache.commons.logging.Log;
import org.apache.commons.logging.LogFactory;
import org.springframework.web.multipart.MultipartHttpServletRequest;
import org.springframework.web.servlet.ModelAndView;

import com.seeyon.apps.addressbook.manager.AddressBookCustomerFieldInfoManager;
import com.seeyon.apps.addressbook.manager.AddressBookManager;
import com.seeyon.apps.addressbook.po.AddressBook;
import com.seeyon.apps.ldap.config.LDAPConfig;
import com.seeyon.apps.ldap.util.LdapUtils;
import com.seeyon.ctp.common.AppContext;
import com.seeyon.ctp.common.SystemEnvironment;
import com.seeyon.ctp.common.appLog.AppLogAction;
import com.seeyon.ctp.common.appLog.manager.AppLogManager;
import com.seeyon.ctp.common.authenticate.domain.User;
import com.seeyon.ctp.common.constants.Plugins;
import com.seeyon.ctp.common.constants.SystemProperties;
import com.seeyon.ctp.common.controller.BaseController;
import com.seeyon.ctp.common.ctpenumnew.manager.EnumManager;
import com.seeyon.ctp.common.datai18n.manager.DataI18nManager;
import com.seeyon.ctp.common.excel.DataRecord;
import com.seeyon.ctp.common.excel.DataRow;
import com.seeyon.ctp.common.excel.FileToExcelManager;
import com.seeyon.ctp.common.exceptions.BusinessException;
import com.seeyon.ctp.common.filemanager.manager.FileManager;
import com.seeyon.ctp.common.i18n.LocaleContext;
import com.seeyon.ctp.common.i18n.ResourceUtil;
import com.seeyon.ctp.common.i18n.expand.ResourceConsts;
import com.seeyon.ctp.common.i18n.util.I18nUtil;
import com.seeyon.ctp.common.metadata.bo.MetadataColumnBO;
import com.seeyon.ctp.common.po.filemanager.V3XFile;
import com.seeyon.ctp.organization.OrgConstants;
import com.seeyon.ctp.organization.OrgConstants.Role_NAME;
import com.seeyon.ctp.organization.bo.CompareSortEntity;
import com.seeyon.ctp.organization.bo.MemberPost;
import com.seeyon.ctp.organization.bo.MemberRole;
import com.seeyon.ctp.organization.bo.V3xOrgAccount;
import com.seeyon.ctp.organization.bo.V3xOrgDepartment;
import com.seeyon.ctp.organization.bo.V3xOrgEntity;
import com.seeyon.ctp.organization.bo.V3xOrgLevel;
import com.seeyon.ctp.organization.bo.V3xOrgMember;
import com.seeyon.ctp.organization.bo.V3xOrgPost;
import com.seeyon.ctp.organization.bo.V3xOrgPrincipal;
import com.seeyon.ctp.organization.bo.V3xOrgRelationship;
import com.seeyon.ctp.organization.bo.V3xOrgRole;
import com.seeyon.ctp.organization.dao.OrgCache;
import com.seeyon.ctp.organization.dao.OrgHelper;
import com.seeyon.ctp.organization.inexportutil.DataUtil;
import com.seeyon.ctp.organization.inexportutil.ResultObject;
import com.seeyon.ctp.organization.manager.MemberManager;
import com.seeyon.ctp.organization.manager.OrgManager;
import com.seeyon.ctp.organization.manager.OrgManagerDirect;
import com.seeyon.ctp.organization.util.OrgTree;
import com.seeyon.ctp.organization.webmodel.WebV3xOrgAccount;
import com.seeyon.ctp.organization.webmodel.WebV3xOrgDepartment;
import com.seeyon.ctp.util.Datetimes;
import com.seeyon.ctp.util.Strings;
import com.seeyon.ctp.util.UniqueList;
import com.seeyon.ctp.util.annotation.CheckRoleAccess;
import com.seeyon.ctp.util.json.JSONUtil;

/**
 * <p>Title: T2组织模型人员维护控制器</p>
 * <p>Description: 主要针对人员进行维护功能</p>
 * <p>Copyright: Copyright (c) 2012</p>
 * <p>Company: seeyon.com</p>
 * @since CTP2.0
 * @author lilong
 */
@CheckRoleAccess(roleTypes = {Role_NAME.SystemAdmin, Role_NAME.AccountAdministrator, Role_NAME.HrAdmin, Role_NAME.GroupAdmin, Role_NAME.DepAdmin})
public class MemberController extends BaseController {

    private static final Log log = LogFactory.getLog(MemberController.class);
    protected OrgManager orgManager;
    protected OrgManagerDirect orgManagerDirect;
    protected OrgCache orgCache;
    protected FileToExcelManager fileToExcelManager;
    protected AppLogManager appLogManager;
    protected MemberManager memberManager;
    protected AddressBookManager addressBookManager;
    protected AddressBookCustomerFieldInfoManager addressBookCustomerFieldInfoManager;
    private DataI18nManager dataI18nManager;

    protected EnumManager enumManagerNew;
    protected FileManager fileManager;

    public void setFileManager(FileManager fileManager) {
        this.fileManager = fileManager;
    }

    public void setEnumManagerNew(EnumManager enumManagerNew) {
        this.enumManagerNew = enumManagerNew;
    }

    public void setMemberManager(MemberManager memberManager) {
        this.memberManager = memberManager;
    }

    public void setAppLogManager(AppLogManager appLogManager) {
        this.appLogManager = appLogManager;
    }

    public OrgManager getOrgManager() {
        return orgManager;
    }

    public void setOrgManager(OrgManager orgManager) {
        this.orgManager = orgManager;
    }

    public OrgManagerDirect getOrgManagerDirect() {
        return orgManagerDirect;
    }

    public void setOrgManagerDirect(OrgManagerDirect orgManagerDirect) {
        this.orgManagerDirect = orgManagerDirect;
    }

    public FileToExcelManager getFileToExcelManager() {
        return fileToExcelManager;
    }

    public void setFileToExcelManager(FileToExcelManager fileToExcelManager) {
        this.fileToExcelManager = fileToExcelManager;
    }

    public OrgCache getOrgCache() {
        return orgCache;
    }

    public void setOrgCache(OrgCache orgCache) {
        this.orgCache = orgCache;
    }

    public void setAddressBookManager(AddressBookManager addressBookManager) {
        this.addressBookManager = addressBookManager;
    }

    public void setAddressBookCustomerFieldInfoManager(
            AddressBookCustomerFieldInfoManager addressBookCustomerFieldInfoManager) {
        this.addressBookCustomerFieldInfoManager = addressBookCustomerFieldInfoManager;
    }

    public void setDataI18nManager(DataI18nManager dataI18nManager) {
        this.dataI18nManager = dataI18nManager;
    }

    /***************************/
    public ModelAndView listByAccount(HttpServletRequest request, HttpServletResponse response) throws Exception {
        //增加部門管理員的功能
        ModelAndView result = new ModelAndView("apps/organization/member/member");
        User user = AppContext.getCurrentUser();
        Long currentAccountId = AppContext.currentAccountId();
        Long accountId = currentAccountId;
        String accountIdStr = request.getParameter("accountId");
        if (Strings.isNotBlank(accountIdStr)) {
            accountId = Long.valueOf(accountIdStr);
        }
        result.addObject("accountId", accountId);

        //自定义通讯录字字段
        List<MetadataColumnBO> metadataColumnBOList = addressBookManager.getCustomerAddressBookList();

        if (user.isGroupAdmin()
                || orgManager.isRole(user.getId(), currentAccountId, OrgConstants.Role_NAME.AccountAdministrator.name())
                || orgManager.isRole(user.getId(), currentAccountId, OrgConstants.Role_NAME.HrAdmin.name())
                || ("0".equals(SystemProperties.getInstance().getProperty("system.ProductId")) && orgManager.isRole(user.getId(), currentAccountId, OrgConstants.Role_NAME.SystemAdmin.name()))) {
            //單位管理員 || HR管理员 管理人員列表
            V3xOrgAccount account = orgManager.getAccountById(accountId);
            List<V3xOrgDepartment> list = orgManager.getAllInternalDepartments(account.getId());
            OrgTree orgTree = OrgHelper.getTree(list, accountId);
            Collections.sort(list, CompareSortEntity.getInstance());
            List<Object> resultlist = new ArrayList<Object>();
            for (V3xOrgDepartment dept : list) {
                if (null == dept.getSuperior() || dept.getSuperior() == -1)
                    continue;//防护
                //OA-11514 NC同步显示申请停用和删除
                StringBuilder deptShowName = new StringBuilder();
                deptShowName.append(dept.getName());
                if (OrgConstants.ORGENT_STATUS.DISABLED.ordinal() == dept.getStatus()) {
                    deptShowName.append("(" + ResourceUtil.getString("org.entity.disabled") + ")");
                } else if (OrgConstants.ORGENT_STATUS.DELETED.ordinal() == dept.getStatus()) {
                    deptShowName.append("(" + ResourceUtil.getString("org.entity.deleted") + ")");
                }
                WebV3xOrgDepartment webdept = new WebV3xOrgDepartment(dept.getId(), deptShowName.toString(), dept.getSuperior());
                webdept.setV3xOrgDepartment(dept);

                //处理zTree上的层级图标
                webdept.setIconSkin("department");
                List<Long> childrenDepts = this.orgCache.getSubDeptList(dept.getId(), orgCache.SUBDEPT_INNER_FIRST);
                if (Strings.isNotEmpty(childrenDepts)) {
                    webdept.setIconSkin("treeDepartment");
                }
/*                OrgTreeNode deptNode= OrgTree.getOrgTreeNodeById(orgTree.getRoot(), dept.getPath());
                if (!deptNode.isLeaf()) {
                    webdept.setIconSkin("treeDepartment");
                }*/

                resultlist.add(webdept);
            }
            WebV3xOrgAccount webrootaccount = new WebV3xOrgAccount(account.getId(), account.getName(), account.getId());
            webrootaccount.setIconSkin("treeAccount");
            resultlist.add(webrootaccount);

            request.setAttribute("ffdeptTree", resultlist);
            if ("true".equals(SystemProperties.getInstance().getProperty("org.isGroupVer"))) {
                result.addObject("isGroupVer", true);
            } else {
                result.addObject("isGroupVer", false);
            }
            /****ldap/ad****/
            String disableModifyLdapPsw = AppContext.getSystemProperty("ldap.disable.modify.password");
            result.addObject("disableModifyLdapPsw", "1".equals(disableModifyLdapPsw));//是否禁用OA修改ldap密码功能,0--不启用,1--启用
            result.addObject("isLdapEnabled", LdapUtils.isLdapEnabled());
            result.addObject("LdapCanOauserLogon", LDAPConfig.getInstance().getLdapCanOauserLogon());
            ;
            /*************/

            result.addObject("bean", metadataColumnBOList);
            return result;
        } else if (orgManager.isRole(user.getId(), accountId, OrgConstants.Role_NAME.DepAdmin.name())) {
            //部门管理员，管理人员界面
            return this.list4DeptAdmin(request, response);
        } else if (AppContext.hasResourceCode("F03_member")) {
            //單位管理員 || HR管理员 管理人員列表
            V3xOrgAccount account = orgManager.getAccountById(accountId);
            List<V3xOrgDepartment> list = orgManager.getAllInternalDepartments(account.getId());
            OrgTree orgTree = OrgHelper.getTree(list, accountId);
            Collections.sort(list, CompareSortEntity.getInstance());
            List<Object> resultlist = new ArrayList<Object>();
            for (V3xOrgDepartment dept : list) {
                if (null == dept.getSuperior() || dept.getSuperior() == -1)
                    continue;//防护
                //OA-11514 NC同步显示申请停用和删除
                StringBuilder deptShowName = new StringBuilder();
                deptShowName.append(dept.getName());
                if (OrgConstants.ORGENT_STATUS.DISABLED.ordinal() == dept.getStatus()) {
                    deptShowName.append("(" + ResourceUtil.getString("org.entity.disabled") + ")");
                } else if (OrgConstants.ORGENT_STATUS.DELETED.ordinal() == dept.getStatus()) {
                    deptShowName.append("(" + ResourceUtil.getString("org.entity.deleted") + ")");
                }
                WebV3xOrgDepartment webdept = new WebV3xOrgDepartment(dept.getId(), deptShowName.toString(), dept.getSuperior());
                webdept.setV3xOrgDepartment(dept);

                //处理zTree上的层级图标
                webdept.setIconSkin("department");
                List<Long> childrenDepts = this.orgCache.getSubDeptList(dept.getId(), orgCache.SUBDEPT_INNER_FIRST);
                if (Strings.isNotEmpty(childrenDepts)) {
                    webdept.setIconSkin("treeDepartment");
                }
/*                OrgTreeNode deptNode= OrgTree.getOrgTreeNodeById(orgTree.getRoot(), dept.getPath());
                if (!deptNode.isLeaf()) {
                    webdept.setIconSkin("treeDepartment");
                }*/

                resultlist.add(webdept);
            }
            WebV3xOrgAccount webrootaccount = new WebV3xOrgAccount(account.getId(), account.getName(), account.getId());
            webrootaccount.setIconSkin("treeAccount");
            resultlist.add(webrootaccount);

            request.setAttribute("ffdeptTree", resultlist);
            if ("true".equals(SystemProperties.getInstance().getProperty("org.isGroupVer"))) {
                result.addObject("isGroupVer", true);
            } else {
                result.addObject("isGroupVer", false);
            }
            /****ldap/ad****/
            String disableModifyLdapPsw = AppContext.getSystemProperty("ldap.disable.modify.password");
            result.addObject("disableModifyLdapPsw", "1".equals(disableModifyLdapPsw));//是否禁用OA修改ldap密码功能,0--不启用,1--启用
            result.addObject("isLdapEnabled", LdapUtils.isLdapEnabled());
            result.addObject("LdapCanOauserLogon", LDAPConfig.getInstance().getLdapCanOauserLogon());
            /*************/
            result.addObject("bean", metadataColumnBOList);
            return result;
        } else {
            return null;
        }

    }

    /**
     * 部门管理员管理
     * @param request
     * @param response
     * @return
     * @throws Exception
     */
    public ModelAndView list4DeptAdmin(HttpServletRequest request, HttpServletResponse response) throws Exception {
        ModelAndView result = new ModelAndView("apps/organization/member/member4DeptAdmin");
        User user = AppContext.getCurrentUser();
        Long accountId = AppContext.currentAccountId();
        String accountIdStr = request.getParameter("accountId");
        if (Strings.isNotBlank(accountIdStr)) {
            accountId = Long.valueOf(accountIdStr);
        }
        result.addObject("accountId", accountId);
        //需要将该人员的管理的所有部门列表送到前台去做简要
        List<V3xOrgDepartment> depts = orgManager.getDeptsByAdmin(user.getId(), accountId);
        List<String> deptIds = new UniqueList<String>();
        for (V3xOrgDepartment bo : depts) {
            deptIds.add(bo.getId().toString());
            //父部门管理员可以管理子部门的人员
            List<V3xOrgDepartment> childs = orgManager.getChildDepartments(bo.getId(), false);
            for (V3xOrgDepartment child : childs) {
                deptIds.add(child.getId().toString());
            }
        }
        result.addObject("deptIds", JSONUtil.toJSONString(deptIds));
        /****ldap/ad****/
        String disableModifyLdapPsw = AppContext.getSystemProperty("ldap.disable.modify.password");
        result.addObject("disableModifyLdapPsw", "1".equals(disableModifyLdapPsw));//是否禁用OA修改ldap密码功能,0--不启用,1--启用
        result.addObject("isLdapEnabled", LdapUtils.isLdapEnabled());
        result.addObject("LdapCanOauserLogon", LDAPConfig.getInstance().getLdapCanOauserLogon());
        /*************/

        //自定义通讯录字字段
        List<MetadataColumnBO> metadataColumnBOList = addressBookManager.getCustomerAddressBookList();
        result.addObject("bean", metadataColumnBOList);
        return result;
    }

    /**
     * 跳转到人员授权角色的小页面，用于给人员授权单位角色
     * @param request
     * @param response
     * @return
     * @throws Exception
     */
    public ModelAndView member2Role(HttpServletRequest request, HttpServletResponse response) throws Exception {
        ModelAndView mav = new ModelAndView("apps/organization/member/member2role");
        Long accountId = AppContext.currentAccountId();
        String accountIdStr = request.getParameter("accountId");
        if (Strings.isNotBlank(accountIdStr)) {
            accountId = Long.valueOf(accountIdStr);
        }
        mav.addObject("accountId", accountId);
        return mav;
    }

    /**
     * 人员管理查看该人员的所有角色
     * @param request
     * @param response
     * @return
     * @throws Exception
     */
    public ModelAndView showMemberAllRoles(HttpServletRequest request, HttpServletResponse response) throws Exception {
        ModelAndView view = new ModelAndView("apps/organization/member/memberAllRoles");
        view.addObject("memberId", request.getParameter("memberId"));
        return view;
    }

    /**
     * 跳转到外部人员授权角色的小页面，用于给外部人员授权单位角色
     * @param request
     * @param response
     * @return
     * @throws Exception
     */
    public ModelAndView member2Role4Ext(HttpServletRequest request, HttpServletResponse response) throws Exception {
        ModelAndView mav = new ModelAndView("apps/organization/member/member2role4ext");
        Long accountId = AppContext.currentAccountId();
        String accountIdStr = request.getParameter("accountId");
        if (Strings.isNotBlank(accountIdStr)) {
            accountId = Long.valueOf(accountIdStr);
        }
        mav.addObject("accountId", accountId);
        return mav;
    }

    /**
     * 跳转到兼职人员授权角色的页面，用于给人员授权单位角色
     * @param request
     * @param response
     * @return
     * @throws Exception
     */
    public ModelAndView cMember2Role(HttpServletRequest request, HttpServletResponse response) throws Exception {
        String orgAccountId = request.getParameter("orgAccountId");
        ModelAndView mv = new ModelAndView("apps/organization/concurrentPost/cMember2role");
        mv.addObject("orgAccountId", orgAccountId);
        return mv;
    }

    /**
     * 外部人員列表
     * @param request
     * @param response
     * @return
     * @throws Exception
     */
    public ModelAndView listExtMember(HttpServletRequest request, HttpServletResponse response) throws Exception {
        ModelAndView result = new ModelAndView("apps/organization/member/member4Ext");
        Long accountId = AppContext.currentAccountId();
        V3xOrgAccount account = orgManager.getAccountById(accountId);
        String accountIdStr = request.getParameter("accountId");
        if (Strings.isNotBlank(accountIdStr)) {
            accountId = Long.valueOf(accountIdStr);
        }
        result.addObject("accountId", accountId);
        /****ldap/ad****/
        String disableModifyLdapPsw = AppContext.getSystemProperty("ldap.disable.modify.password");
        result.addObject("disableModifyLdapPsw", "1".equals(disableModifyLdapPsw));//是否禁用OA修改ldap密码功能,0--不启用,1--启用
        result.addObject("isLdapEnabled", LdapUtils.isLdapEnabled());
        result.addObject("LdapCanOauserLogon", LDAPConfig.getInstance().getLdapCanOauserLogon());
        /*************/
        //自定义通讯录字字段
        List<MetadataColumnBO> metadataColumnBOList = addressBookManager.getCustomerAddressBookList();
        result.addObject("bean", metadataColumnBOList);
        result.addObject("allowManagementSubunit", account.allowManagementSubunit());
        return result;
    }

    /**
     * 批量修改跳转controller
     * 不做逻辑处理
     * @param request
     * @param response
     * @return
     * @throws Exception
     */
    public ModelAndView batchUpdatePre(HttpServletRequest request, HttpServletResponse response) throws Exception {
        ModelAndView result = new ModelAndView("apps/organization/member/member4BatchUpdate");
        Long accountId = AppContext.currentAccountId();
        String accountIdStr = request.getParameter("accountId");
        if (Strings.isNotBlank(accountIdStr)) {
            accountId = Long.valueOf(accountIdStr);
        }
        result.addObject("accountId", accountId);
        Boolean isDeptAdmin = Boolean.valueOf(String.valueOf(request.getParameter("isDeptAdmin")));
        //需要将该人员的管理的所有部门列表送到前台去做校验
        List<V3xOrgDepartment> depts = new ArrayList<V3xOrgDepartment>();
        if (null != isDeptAdmin && isDeptAdmin) {
            depts = orgManager.getDeptsByAdmin(AppContext.currentUserId(), accountId);
        } else {
            depts = Collections.emptyList();//不是部门管理员就不用对已经管理的部门进行校验也不需要将json送到前台
        }
        List<String> deptIds = new UniqueList<String>();
        for (V3xOrgDepartment bo : depts) {
            deptIds.add(bo.getId().toString());
            //父部门管理员可以管理子部门的人员
            List<V3xOrgDepartment> childs = orgManager.getChildDepartments(bo.getId(), false);
            for (V3xOrgDepartment child : childs) {
                deptIds.add(child.getId().toString());
            }
        }
        result.addObject("deptIds", JSONUtil.toJSONString(deptIds));
        result.addObject("isDeptAdmin", isDeptAdmin);

        //自定义通讯录字字段
        List<MetadataColumnBO> metadataColumnBOList = addressBookManager.getCustomerAddressBookList();
        result.addObject("bean", metadataColumnBOList);
        return result;
    }

    /**
     * 批量修改操作controller
     * 进行人员属性批量修改操作
     * @param request
     * @param response
     * @return
     * @throws Exception
     */
    public ModelAndView batchUpdate(HttpServletRequest request, HttpServletResponse response) throws Exception {
        User user = AppContext.getCurrentUser();
        Long accountId = AppContext.currentAccountId();
        String accountIdStr = request.getParameter("accountId");
        if (Strings.isNotBlank(accountIdStr)) {
            accountId = Long.valueOf(accountIdStr);
        }
        response.setCharacterEncoding("UTF-8");
        response.setHeader("Content-Type", "text/html;charset=UTF-8");
        PrintWriter out = response.getWriter();
        // 要更新的人员ID
        String idsStr = request.getParameter("ids");
        List<Long> idList = new LinkedList<Long>();
        if (!Strings.isBlank(idsStr)) {
            String[] idStrArray = idsStr.split(",");
            for (String idStr : idStrArray) {
                try {
                    idList.add(Long.valueOf(idStr.trim()));
                } catch (NumberFormatException e) {
                    log.warn("无效的人员ID：" + idStr, e);
                }
            }
        }
        // 角色
        String orgRoleIdsStr = request.getParameter("roleIds");
        List<Long> roleIdList = new LinkedList<Long>();
        StringBuilder newRoles = new StringBuilder();
        if (null != orgRoleIdsStr
                && Strings.isNotBlank(orgRoleIdsStr)) {
            String roleIds = orgRoleIdsStr;
            String[] roles = roleIds.split(",");
            for (String s : roles) {
                roleIdList.add(Long.valueOf(s.trim()));
                newRoles.append(orgManager.getRoleById(Long.valueOf(s.trim())).getShowName()).append("、");
            }
        }
        // 所属部门
        String orgDepartmentIdStr = request.getParameter("orgDepartmentId");
        Long orgDepartmentId = null;
        if (!Strings.isBlank(orgDepartmentIdStr)) {
            try {
                orgDepartmentId = Long.valueOf(orgDepartmentIdStr.trim());
            } catch (NumberFormatException e) {
                log.warn("无效的部门ID：" + orgDepartmentIdStr);
            }
        }
        // 职务级别
        String orgLevelIdStr = request.getParameter("orgLevelId");
        Long orgLevelId = null;
        if (!Strings.isBlank(orgLevelIdStr)) {
            try {
                orgLevelId = Long.valueOf(orgLevelIdStr.trim());
            } catch (NumberFormatException e) {
                log.warn("无效的职务级别：" + orgLevelIdStr);
            }
        }
        // 主岗
        String orgPostIdStr = request.getParameter("orgPostId");
        Long orgPostId = null;
        if (!Strings.isBlank(orgPostIdStr)) {
            try {
                orgPostId = Long.valueOf(orgPostIdStr.trim());
            } catch (NumberFormatException e) {
                log.warn("无效的岗位ID：" + orgPostIdStr);
            }
        }
        // 性别
        String genderStr = request.getParameter("gender");
        Integer gender = null;
        if (!Strings.isBlank(genderStr)) {
            try {
                gender = Integer.valueOf(genderStr);
            } catch (NumberFormatException e) {
                log.warn("无效的性别：" + genderStr);
            }
        }
        // 人员类型
        String typeStr = request.getParameter("type");
        Integer type = null;
        if (!Strings.isBlank(typeStr)) {
            try {
                type = Integer.valueOf(typeStr);
            } catch (NumberFormatException e) {
                log.warn("无效的人员类型：" + typeStr);
            }
        }
        // 账户状态
        String enabledStr = request.getParameter("enabled");
        Boolean enabled = null;
        if (!Strings.isBlank(enabledStr)) {
            if ("1".equals(enabledStr)) {
                enabled = Boolean.TRUE;
            } else if ("0".equals(enabledStr)) {
                enabled = Boolean.FALSE;
            } else {
                log.warn("无效的账户状态：" + enabledStr);
            }
        }
        //增加工作地，汇报人workLocal1
        String workLocal = request.getParameter("workLocal");
        Long reporter = null;
        String reporterStr = request.getParameter("reporter");
        if (Strings.isNotBlank(reporterStr)) {
            reporter = Long.valueOf(reporterStr);
        }

        //入职时间
        Date hiredate = null;
        if (!Strings.isBlank(request.getParameter("hiredate"))) {
            hiredate = Datetimes.parse(String.valueOf(request.getParameter("hiredate")), "yyyy-MM-dd");
        }

        //密码
        String password = null;
        if (!Strings.isBlank(request.getParameter("password"))) {
            password = request.getParameter("password").toString();
        }

        List<MetadataColumnBO> metadataColumnBOList = addressBookManager.getCustomerAddressBookList();

        List<V3xOrgRelationship> delRels = new UniqueList<V3xOrgRelationship>();
        List<V3xOrgRelationship> addRels = new UniqueList<V3xOrgRelationship>();
        List<V3xOrgMember> members = new LinkedList<V3xOrgMember>();
        for (Long id : idList) {
            boolean skipFlag = false;
            V3xOrgMember member = new V3xOrgMember();
            try {
                member = this.orgManager.getMemberById(id);
            } catch (BusinessException e) {
                log.warn("查询人员信息失败：" + id, e);
                skipFlag = false;
            }
            if (skipFlag || member == null) {
                log.warn("查询人员信息失败：" + id);
                continue;
            }
            //前台不允许授权的角色集合catortyRoles
            //List<Long> categoryRoles = new UniqueList<Long>();
            //更新人员时老角色局部存储设定
            StringBuilder oldRoles = new StringBuilder();
            Set<Long> oldRoleIds = new HashSet<Long>();

            List<MemberRole> memberRoles = orgManager.getMemberRoles(member.getId(), member.getOrgAccountId());
            for (MemberRole m : memberRoles) {
                /*if("0".equals(m.getRole().getCategory().trim())) {
                    categoryRoles.add(m.getRole().getId());//此处将这个人拥有的【不允许前台授权的角色】收集起来
                }*/
                if (OrgConstants.ROLE_BOND.DEPARTMENT.ordinal() == m.getRole().getBond()
                        || OrgConstants.ROLE_BOND.ACCOUNT.ordinal() == m.getRole().getBond()) {
                    oldRoles.append(m.getRole().getShowName()).append("、");
                    oldRoleIds.add(m.getRole().getId());
                }

            }
            //角色变化了.增加日志
            if (!roleIdList.isEmpty() && !roleIdList.equals(oldRoleIds)) {
                String onames = oldRoles.toString();
                String nnames = newRoles.toString();
                appLogManager.insertLog4Account(user, user.isGroupAdmin() ? accountId : AppContext.currentAccountId(), AppLogAction.Organization_UpdateMemberRole, user.getName(), member.getName(),
                        onames.length() == 0 ? "" : onames.substring(0, onames.length() - 1), nnames.length() == 0 ? "" : nnames.substring(0, nnames.length() - 1));

            }
            //角色
            if (roleIdList.size() > 0) {
                orgManagerDirect.cleanMemberAccAndSelfDeptRoles(member, memberManager.canDelRoles(member.getOrgAccountId()));
                for (Long roleId : roleIdList) {
                    V3xOrgRole r = orgManager.getRoleById(roleId);
                    if (null != r) {
                        if (OrgConstants.ROLE_BOND.DEPARTMENT.ordinal() == r.getBond()) {//部门角色
                            orgManagerDirect.addRole2Entity(r.getId(), member.getOrgAccountId(), member, orgManager.getDepartmentById(member.getOrgDepartmentId()), delRels, addRels);
                        } else {
                            orgManagerDirect.addRole2Entity(r.getId(), member.getOrgAccountId(), member, delRels, addRels);
                        }
                    } else {
                        continue;
                    }
                }
            }
            // 所属部门
            if (orgDepartmentId != null) {
                member.setOrgDepartmentId(orgDepartmentId);
            }
            // 职务级别
            if (orgLevelId != null) {
                member.setOrgLevelId(orgLevelId);
            }
            // 主岗
            if (orgPostId != null) {
                member.setOrgPostId(orgPostId);
            }
            // 性别
            if (gender != null) {
                member.setProperty("gender", gender);
            }
            // 人员类型
            if (type != null) {
                member.setType(type);
            }
            // 首选语言
            if (Strings.isNotBlank(request.getParameter("primaryLanguange"))) {
                member.setPrimaryLanguange(request.getParameter("primaryLanguange"));
                orgManagerDirect.setMemberLocale(member, LocaleContext.parseLocale(request.getParameter("primaryLanguange")));
            }
            // 账户状态
            if (enabled != null) {
                if (OrgConstants.MEMBER_STATE.RESIGN.ordinal() == member.getState() && enabled) {
                    out.println("<script>");
                    out.println("alert(\"" + ResourceUtil.getString("org.member.controller.fail.member.delete") + "\")");
                    out.println("window.parent.location.reload();");
                    out.println("window.parent.dialog4Batch.close();");
                    out.println("</script>");
                    return null;
                } else {
                    member.setEnabled(enabled);
                }
            }
            if (member.getEnabled() != null && member.getEnabled()) {//启用，则改成在职状态
                if ("2".equals(member.getState().toString())) {//由离职改成在职,取消所有代理事项
                    member.setState(new Byte("1"));
                }
            }
            if (Strings.isNotBlank(workLocal)) {
                member.setLocation(workLocal);
            }
            if (reporter != null) {
                member.setReporter(reporter);
            }

            if (hiredate != null) {
                member.setProperty("hiredate", hiredate);
            }

            if (password != null) {
                V3xOrgPrincipal p = new V3xOrgPrincipal(member.getId(), member.getLoginName(), password);
                member.setV3xOrgPrincipal(p);
            }

            List<String> list = new ArrayList<String>();
            //自定义的通讯录字段
            AddressBook addressBook = addressBookCustomerFieldInfoManager.getByMemberId(member.getId());
            List<MetadataColumnBO> metadataColumnList = addressBookManager.getCustomerAddressBookList();
            for (MetadataColumnBO metadataColumn : metadataColumnList) {
                String columnName = metadataColumn.getColumnName();
                String key = metadataColumn.getId().toString();
                String newValue = "";
                if (request.getParameter(key) != null && Strings.isNotEmpty(request.getParameter(key))) {
                    newValue = request.getParameter(key);
                }

                try {
                    Method method = addressBookManager.getGetMethod(columnName);
                    if (null == method) {
                        throw new BusinessException("自定义通讯录字段: " + metadataColumn.getLabel() + "不存在！");
                    }
                    if (null != addressBook) {
                        Object value = method.invoke(addressBook, new Object[]{});
                        if (metadataColumn.getType() == 0) {//文本
                            String saveValue = null == value ? "" : String.valueOf(value);
                            list.add(Strings.isNotEmpty(newValue) ? newValue : saveValue);
                        }
                        if (metadataColumn.getType() == 1) {//数字
                            if (null == value) {
                                list.add(Strings.isNotEmpty(newValue) ? newValue : "");
                            } else {
                                BigDecimal bd = new BigDecimal(String.valueOf(value));
                                DecimalFormat df = new DecimalFormat("########.####");
                                list.add(Strings.isNotEmpty(newValue) ? newValue : df.format(bd));
                            }
                        }
                        if (metadataColumn.getType() == 2) {//日期
                            String saveValue = null == value ? "" : Datetimes.formatDate((Date) value);
                            list.add(Strings.isNotEmpty(newValue) ? newValue : saveValue);
                        }
                        if (metadataColumn.getType() == 3) {//枚举
                            String saveValue = null == value ? "" : String.valueOf(value);
                            list.add((Strings.isNotEmpty(newValue) && !"-1".equals(newValue)) ? newValue : saveValue);
                        }
                        if (metadataColumn.getType() == 4) {//选人
                            String saveValue = null == value ? "" : String.valueOf(value);
                            list.add((Strings.isNotEmpty(newValue) && !"-1".equals(newValue)) ? newValue : saveValue);
                        }
                        if (metadataColumn.getType() == 5) {//选部门
                            String saveValue = null == value ? "" : String.valueOf(value);
                            list.add((Strings.isNotEmpty(newValue) && !"-1".equals(newValue)) ? newValue : saveValue);
                        }
                    } else {
                        list.add(Strings.isNotEmpty(newValue) ? newValue : "");
                    }


                } catch (Exception e) {
                    logger.error("", e);
                }
            }
            member.setCustomerAddressBooklist(list);
            members.add(member);
        }

        if (Strings.isNotBlank(workLocal)) {
            //修改枚举引用状态
            refEnum(workLocal);
        }
        //统一添加删除角色关系
        orgManagerDirect.deleteOrgRelationships(delRels);
        orgManagerDirect.addOrgRelationships(addRels);

        orgManagerDirect.updateMembers(members);

        appLogManager.insertLog4Account(user, user.isGroupAdmin() ? accountId : AppContext.currentAccountId(), AppLogAction.Organization_BanchEditMember, user.getName());

        out.println("<title></title>");
        out.println("<script>");
        //out.println("alert(\"操作成功！\")");
        out.println("try{if(getCtpTop()&&getCtpTop().endProc){getCtpTop().endProc()}}catch(e){};");
        out.println("window.parent.location.reload();");
        out.println("window.parent.dialog4Batch.close();");
        out.println("</script>");
        out.println("</head><body></body></html>");
        out.flush();

        return null;
    }

    /**
     * 内部人员导出controller
     * @param request
     * @param response
     * @return
     * @throws Exception
     */
    @CheckRoleAccess(roleTypes = {Role_NAME.GroupAdmin, Role_NAME.AccountAdministrator, Role_NAME.HrAdmin})
    public ModelAndView exportMembers(HttpServletRequest request, HttpServletResponse response) throws Exception {
        log.info("exportMember start");
        orgCache.setOrgExportFlag(true);
        User user = AppContext.getCurrentUser();
        if (user == null) {
            return null;
        }
        if (DataUtil.doingImpExp(user.getId())) {
            return null;
        }
//        Locale locale = LocaleContext.getLocale(request);
//        String resource = "com.seeyon.v3x.organization.resources.i18n.OrganizationResources";

        Map paraMap = new HashMap();
        String listname = "MemberList_";
        listname += user.getLoginName();

        String key = null;
        DataUtil.putImpExpAction(user.getId(), "export");
        DataRecord dataRecord = null;
        paraMap.put("isInternal", Boolean.TRUE);
        try {
            dataRecord = exportMember(request, fileToExcelManager, paraMap);
            key = DataUtil.createTempSaveKey4Sheet(dataRecord);
        } catch (Exception e) {
            DataUtil.removeImpExpAction(user.getId());
            log.error("error occur ->", e);
            orgCache.setOrgExportFlag(false);
            throw new BusinessException("导出失败！");
        }
        DataUtil.removeImpExpAction(user.getId());

        String url = DataUtil.getOrgDownloadExpToExcelUrl(key, listname);
        log.info("url=" + url);
        DataUtil.removeImpExpAction(user.getId());
        try {
            OrgHelper.exportToExcel(request, response, fileToExcelManager, listname, dataRecord);
        } catch (Exception e) {
            log.error(e);
            throw e;
        } finally {
            orgCache.setOrgExportFlag(false);
        }
        return null;

    }

    /**
     * 外部人员全部导出controller
     * @param request
     * @param response
     * @return
     * @throws Exception
     */
    @CheckRoleAccess(roleTypes = {Role_NAME.GroupAdmin, Role_NAME.AccountAdministrator, Role_NAME.HrAdmin})
    public ModelAndView exportExtMembers(HttpServletRequest request, HttpServletResponse response) throws Exception {
        log.info("exportExtMember start");
        User user = AppContext.getCurrentUser();
        if (user == null) {
            return null;
        }
        if (DataUtil.doingImpExp(user.getId())) {
            return null;
        }
        String listname = "ExtMemberList_";
        listname += user.getLoginName();
        String key = null;
        DataUtil.putImpExpAction(user.getId(), "export");
        DataRecord dataRecord = null;
        Map paraMap = new HashMap();
        paraMap.put("isInternal", Boolean.FALSE);
        try {
            dataRecord = exportMember(request, fileToExcelManager, paraMap);
            key = DataUtil.createTempSaveKey4Sheet(dataRecord);
        } catch (Exception e) {
            DataUtil.removeImpExpAction(user.getId());
            throw e;
        }
        DataUtil.removeImpExpAction(user.getId());

        String url = DataUtil.getOrgDownloadExpToExcelUrl(key, listname);
        log.info("url=" + url);
        DataUtil.removeImpExpAction(user.getId());
        OrgHelper.exportToExcel(request, response, fileToExcelManager, listname, dataRecord);
        return null;

    }

    /**
     * 将导出人员数据整理excel的数据对象
     * @param fileToExcelManager
     * @param orgManagerDirect
     * @return
     * @throws Exception
     */
    private DataRecord exportMember(HttpServletRequest request, FileToExcelManager fileToExcelManager, Map paraMap) throws Exception {
        Long accountId = Long.parseLong(request.getParameter("accountId"));
        DataRecord dataRecord = new DataRecord();
        List<V3xOrgMember> memberlist = new UniqueList<V3xOrgMember>();
        Boolean isInternal = (Boolean) paraMap.get("isInternal");
        Boolean enabled = null;
        String condition = null;
        String conditionTemp = null;
        Object value = null;

        Map queryParams = new HashMap<String, Object>();

        String oDepartId = request.getParameter("selectDepartmentId");
        if (Strings.isNotBlank(oDepartId) && !"null".equals(oDepartId)) {
            condition = "selectDepartmentId";
            value = Long.valueOf(oDepartId);

            queryParams.put("selectDepartmentId", Long.valueOf(oDepartId));
        }
        //搜索条件：
        String s = request.getParameter("s");
        if (Strings.isNotBlank(s)) {
            condition = null;
            String type = "";

            String[] param = s.split(";");
            for (String p : param) {
                String[] pp = p.split(":");
                if (pp.length < 2) continue;
                if ("s_type".equals(pp[0])) {
                    if (Strings.isNotBlank(pp[1]) && !"undefined".equals(pp[1])) {
                        type = pp[1];
                    }
                    continue;
                }

                if ("s_condition".equals(pp[0])) {
                    if (Strings.isNotBlank(pp[1]) && !"undefined".equals(pp[1])) {
                        condition = pp[1];
                    }
                    continue;
                }

                if ("s_value".equals(pp[0])) {
                    if ("selectPeople".equals(type)) {
                        String _tempStr = pp[1];
                        try {
                            value = Long.valueOf(_tempStr.substring(_tempStr.indexOf("|") + 1, _tempStr.length()));
                        } catch (Exception e) {
                            value = null;
                        }
                    } else if ("input".equals(type)) {
                        value = pp[1];
                    } else if ("select".equals(type)) {//编外人员的启用状态选择
                        condition = null;
                        enabled = Boolean.valueOf(pp[1]);
                    }
                    continue;
                }
            }

        } else {
            condition = null;
        }
        conditionTemp = condition;
        if ("search_workLocalId".equals(condition)) {
            String str = value.toString();
            if (Strings.isNotBlank(str)) {
                String workLocal = enumManagerNew.parseToIds(str, OrgConstants.WORKLOCAL_ID);
                queryParams.put("workLocal", workLocal + "%");
                conditionTemp = "workLocal";
            }
        } else if (Strings.isNotBlank(condition) && value != null) {
            queryParams.put(condition, value);
        }

        if ("orgDepartmentId".equals(condition) && value != null) {//如果是从搜索部门来的数据，删掉点击左侧部门带过来的参数
            queryParams.remove("selectDepartmentId");
        }

        //人员过滤后带着过滤条件导出、
        boolean subMembers = false;
        if (isInternal) {
            String filter = request.getParameter("filter");
            if (Strings.isBlank(filter)) {
                enabled = null;
            } else {
                String[] param = filter.split(";");
                for (String p : param) {
                    String[] pp = p.split(":");
                    if (pp.length < 2) continue;
                    if ("filter_enabled".equals(pp[0])) {
                        if (Strings.isNotBlank(pp[1]) && !"undefined".equals(pp[1]) && !"null".equals(pp[1])) {
                            enabled = Boolean.valueOf(pp[1]);
                        }
                        continue;
                    }

                    if ("filter_cond".equals(pp[0])) {
                        if (Strings.isNotBlank(pp[1]) && "no".equals(pp[1]) && !"undefined".equals(pp[1])) {
                            if ((Strings.isBlank(oDepartId) || "null".equals(oDepartId))) {
                                queryParams.remove(conditionTemp);
                            }

                        }
                        continue;
                    }

                    if ("filter_value".equals(pp[0])) {
                        if (Strings.isNotBlank(pp[1]) && !"undefined".equals(pp[1])) {
                            value = pp[1];
                        }
                        continue;
                    }

                    if ("filter_condition".equals(pp[0])) {
                        if ("state".equals(condition)) {
                            queryParams.put("state", Integer.valueOf(value.toString()));
                        } else if ("search_workLocalId".equals(condition)) {
                            String str = value.toString();
                            if (Strings.isNotBlank(str)) {
                                String workLocal = enumManagerNew.parseToIds(str, OrgConstants.WORKLOCAL_ID);
                                queryParams.put("workLocal", workLocal + "%");
                            }
                        }
                        continue;
                    }

                    if ("filter_subMembers".equals(pp[0])) {
                        if (Strings.isNotBlank(pp[1]) && !"undefined".equals(pp[1])) {
                            subMembers = Boolean.valueOf(pp[1]);
                        }
                        continue;
                    }

                }

            }
        }

        boolean searchSubMembers = false;
        if (queryParams.containsKey("selectDepartmentId")) {
            if (subMembers) {
                //部门查询，并且包含子部门,这种情况查出全部人员，再循环判断是否在子部门
                queryParams.remove("selectDepartmentId");
                searchSubMembers = true;
            } else {
                queryParams.put("orgDepartmentId", queryParams.get("selectDepartmentId"));
                queryParams.remove("selectDepartmentId");
            }
        }

        memberlist = orgManagerDirect.getAllMemberPOByAccountId(accountId, isInternal, enabled, queryParams, null);
        Set<Long> subDeptIds = new HashSet<Long>();
        if (searchSubMembers) {
            subDeptIds.add(Long.valueOf(oDepartId));
            List<V3xOrgDepartment> deptList = orgManager.getChildDepartments(Long.valueOf(oDepartId), false);
            for (V3xOrgDepartment subDept : deptList) {
                subDeptIds.add(subDept.getId());
            }
        }

        V3xOrgAccount account = null;
        V3xOrgMember member = null;
        V3xOrgDepartment dept = null;
        String deptName = "";
        V3xOrgPost post = null;
        V3xOrgLevel level = null;
        //导出excel文件的国际化
        String member_list = ResourceUtil.getString("org.member_form.list");
        if (!isInternal) {
            member_list = ResourceUtil.getString("org.member_ext_form.list");
        }

        String member_name = ResourceUtil.getString("org.member_form.name.label");
        StringBuilder member_i18n_name = new StringBuilder();
        List<Locale> allLocales = LocaleContext.getAllLocales();
        String[] locales = new String[allLocales.size()];
        for (int i = 0; i < allLocales.size(); i++) {
            locales[i] = I18nUtil.getLocalAsString(allLocales.get(i));
            if (i > 0) {
                member_i18n_name.append(",");
            }

            String strLocale = I18nUtil.getLocalAsString(allLocales.get(i));
            String locale = ResourceConsts.getLanguageName(strLocale);

            member_i18n_name.append(ResourceUtil.getString("org.member_form.name.label") + "(" + locale + "(" + strLocale + ")" + ")");
        }
        if (SystemEnvironment.functionSwitch(Plugins.DATA_I18N)) {
            member_name = member_i18n_name.toString();
        }

        String member_loginName = ResourceUtil.getString("org.member_form.loginName.label");
        String member_code = ResourceUtil.getString("org.member_form.code");
        String member_sortId = ResourceUtil.getString("org.member_form.sort");
        String member_deptName = "";
        if (isInternal) {
            member_deptName = ResourceUtil.getString("org.member_form.deptName.label");
        } else {
            member_deptName = ResourceUtil.getString("org.member_form.ExtDeptName4export.label");
        }
        String member_primaryPost = ResourceUtil.getString("org.member_form.primaryPost.label");
        String member_secondPost = ResourceUtil.getString("org.member_form.secondPost.label");
        String member_levelName = ResourceUtil.getString("org.member_form.levelName.label");
        String member_tel = ResourceUtil.getString("org.member_form.tel");
        String member_account = ResourceUtil.getString("org.member_form.account");
        String member_email = ResourceUtil.getString("org.member.emailaddress");
        String member_gender = ResourceUtil.getString("org.memberext_form.base_fieldset.sexe");
        String member_birthday = ResourceUtil.getString("org.memberext_form.base_fieldset.birthday");
        String member_officeNumber = ResourceUtil.getString("member.office.number");
        String member_primaryLanguange = ResourceUtil.getString("org.member_form.primaryLanguange");
        // String member_communication = ResourceUtil.getString("hr.staffInfo.communication.label");
        String member_location = ResourceUtil.getString("member.location");
        String member_hiredate = ResourceUtil.getString("member.hiredate");
        String member_reporter = ResourceUtil.getString("member.report2");
        String member_workscope = ResourceUtil.getString("org.external.member.form.work");
        String customerAddressBookFields = "";

        //导出记录提前将单位管理员和无效人员过滤出去，这里过滤的原因防止产生的excel的列与记录不同
        List<V3xOrgMember> exportList = new ArrayList<V3xOrgMember>();
        for (V3xOrgMember v : memberlist) {
            if (v.getIsAdmin() || (searchSubMembers && !subDeptIds.contains(v.getOrgDepartmentId()))) {
                continue;
            } else if (null != enabled) {
                if (enabled) {
                    if (!v.isValid()) {
                        continue;
                    } else {
                        exportList.add(v);
                    }
                } else {
                    exportList.add(v);
                }
            } else {
                exportList.add(v);
            }
        }

        if (null != exportList && exportList.size() > 0) {
            DataRow[] datarow = new DataRow[exportList.size()];

            //自定义的通讯录字段
            List<MetadataColumnBO> metadataColumnList = addressBookManager.getCustomerAddressBookList();
            for (MetadataColumnBO metadataColumnBO : metadataColumnList) {
                customerAddressBookFields = customerAddressBookFields + "," + metadataColumnBO.getLabel();
            }

            for (int i = 0; i < exportList.size(); i++) {
                member = exportList.get(i);
                DataRow row = new DataRow();
                if (SystemEnvironment.functionSwitch(Plugins.DATA_I18N)) {
                    Map<String, String> map = null;
                    if (member.getI18nNameId() != null) {
                        map = dataI18nManager.getAllDataI18nValueMap(member.getI18nNameId());
                    }
                    for (String locale : locales) {
                        if (map == null || map.isEmpty()) {
                            row.addDataCell(member.getName(), 1);
                        } else {
                            row.addDataCell(map.get(locale), 1);
                        }

                    }
                } else {
                    row.addDataCell(member.getName(), 1);
                }

                row.addDataCell(member.getLoginName(), 1);
                row.addDataCell(member.getCode(), 1);
                //增加排序号
                row.addDataCell(String.valueOf(member.getSortId()), 1);
                //所属单位
                account = orgManager.getAccountById(member.getOrgAccountId());
                row.addDataCell(account.getName(), 1); //所属单位
                //所属部门
                dept = orgManager.getDepartmentById(member.getOrgDepartmentId());
                if (dept != null) {
                    deptName = OrgHelper.showDepartmentFullPath(dept.getId());
                    //添加部门编码
                    deptName = Strings.isEmpty(dept.getCode()) ? deptName : deptName + "(" + dept.getCode() + ")";
                }
                row.addDataCell(deptName, 1); //所属部门
                if (!isInternal) {//工作范围
                    List<V3xOrgEntity> extWorks = orgManager.getExternalMemberWorkScope(member.getId(), false);
                    StringBuilder extWorkScopeValue = new StringBuilder();
                    for (int j = 0; j < extWorks.size(); j++) {
                        String type = extWorks.get(j).getEntityType();
                        extWorkScopeValue.append(OrgHelper.getEntityTypeByClassSimpleName(extWorks.get(j).getClass().getSimpleName()));
                        extWorkScopeValue.append("|");
                        extWorkScopeValue.append(extWorks.get(j).getName());
                        if (("Department".equals(type) || "Member".equals(type)) && Strings.isNotBlank(extWorks.get(j).getCode())) {
                            extWorkScopeValue.append("(" + extWorks.get(j).getCode() + ")");
                        }
                        if (j != extWorks.size() - 1) {
                            extWorkScopeValue.append("、");
                        }
                    }
                    row.addDataCell(extWorkScopeValue.toString(), 1); //主要岗位
                }
                //主要岗位
                if (null == member.getOrgPostId()
                        || member.getOrgPostId() == -1) {
                    if (!isInternal) {
                        row.addDataCell(OrgHelper.getExtMemberPriPost(member), 1); //主要岗位
                    } else {
                        row.addDataCell(null, 1); //主要岗位
                    }
                } else {
                    post = orgManager.getPostById(member.getOrgPostId());
                    if (null != post) {
                        String ppostName = post.getName(); //
                        String ppostCode = post.getCode();
                        if (Strings.isNotBlank(ppostCode)) {
                            try {
                                ppostName += "(" + ppostCode + ")";
                            } catch (Exception e) {
                                log.error("", e);
                            }
                        }
                        row.addDataCell(ppostName, 1); //主要岗位tanglh
                    } else {
                        row.addDataCell(null, 1); //主要岗位tanglh
                    }
                }
                if (isInternal) {
                    //增加副岗
                    List<MemberPost> secendPosts = member.getSecond_post();
                    if (null == secendPosts || secendPosts.size() < 1) {
                        row.addDataCell(null, 1); //副岗为空
                    } else {
                        StringBuilder sb = new StringBuilder();
                        for (MemberPost secendPost : secendPosts) {
                            V3xOrgPost tempPost = orgManager.getPostById(secendPost.getPostId());
                            if (tempPost != null) {
                                String pName = tempPost.getName();
                                V3xOrgDepartment tempDept = orgManager.getDepartmentById(secendPost.getDepId());
                                String dName = tempDept.getName() + (tempDept.getCode() != null ? "(" + tempDept.getCode() + ")" : "");
                                sb.append(dName + "》" + pName + ",");
                            }
                        }
                        String seconddepts = sb.toString();
                        row.addDataCell(seconddepts.length() > 0 ? seconddepts.substring(0, seconddepts.length() - 1) : null, 1); //增加副岗
                    }
                }
                //职务级别
                if (null == member.getOrgLevelId()
                        || member.getOrgLevelId() == -1) {
                    if (!isInternal) {
                        row.addDataCell(OrgHelper.getExtMemberLevel(member), 1); //职务级别
                    } else {
                        row.addDataCell(null, 1); //职务级别
                    }
                } else {
                    level = orgManager.getLevelById(member.getOrgLevelId());
                    if (null != level) {
                        String levName = level.getName();
                        String levelCode = level.getCode();
                        if (Strings.isNotBlank(levelCode)) {
                            try {
                                levName += "(" + levelCode + ")";
                            } catch (Exception e) {
                                log.error("", e);
                            }
                        }
                        row.addDataCell(levName, 1); //职务级别
                    } else {
                        row.addDataCell(null, 1); //职务级别
                    }
                }
                row.addDataCell(member.getTelNumber(), 1); //移动电话号码
                row.addDataCell(member.getEmailAddress(), 1);//email
                // 性别
                String gender = "";
                if (member.getGender() != null) {
                    if (V3xOrgEntity.MEMBER_GENDER_MALE == member.getGender()) {
                        gender = ResourceUtil.getString("org.memberext_form.base_fieldset.sexe.man");
                    } else if (V3xOrgEntity.MEMBER_GENDER_FEMALE == member.getGender()) {
                        gender = ResourceUtil.getString("org.memberext_form.base_fieldset.sexe.woman");
                    }
                }
                row.addDataCell(gender, 1); // 性别
                // 生日
                String birthday = "";
                if (member.getBirthday() != null)
                    birthday = Datetimes.format(member.getBirthday(), "yyyy-MM-dd");
                row.addDataCell(birthday, 1); // 生日

                V3xOrgMember memMember = orgManager.getMemberById(member.getId());
                // 办公电话
                String officeNum = "";
                if (memMember != null)
                    officeNum = (String) memMember.getOfficeNum();
                row.addDataCell(officeNum, 1); // 办公电话

                // 首选语言
                Locale orgLocale = orgManagerDirect.getMemberLocaleById(member.getId());
                String localStr = "localeselector.locale." + orgLocale;
                row.addDataCell(ResourceUtil.getString(localStr), 1);  
                
/*                // 通信地址
                String communication = "";
                if (memMember != null)
                	communication = (String) memMember.getPostAddress();
                row.addDataCell(communication, 1);  */

                if (isInternal) {
                    // 工作地
                    String location = "";
                    if (memMember != null) {
                        location = (String) memMember.getLocation();
                        if (location == null) {
                            location = "";
                        } else {
                            location = enumManagerNew.parseToName(location);
                        }
                    }
                    row.addDataCell(location, 1);

                    // 入职时间
                    String hiredate = "";
                    if (memMember != null) {
                        if (member.getHiredate() != null) {
                            hiredate = Datetimes.format(memMember.getHiredate(), "yyyy-MM-dd");
                        }
                    }
                    row.addDataCell(hiredate, 1);

                    // 汇报人
                    String report2 = "";
                    if (memMember != null) {
                        V3xOrgMember reportTo = orgManager.getMemberById(memMember.getReporter());
                        if (reportTo != null) {
                            if (Strings.isNotBlank(reportTo.getName())) {
                                report2 = reportTo.getName() + "(" + reportTo.getLoginName() + ")";
                            }
                        }
                    }
                    row.addDataCell(report2, 1);
                }

                //自定义的通讯录字段
                if (Strings.isNotEmpty(metadataColumnList)) {
                    AddressBook addressBook = addressBookCustomerFieldInfoManager.getByMemberId(member.getId());
                    for (MetadataColumnBO metadataColumn : metadataColumnList) {
                        String columnName = metadataColumn.getColumnName();
                        try {
                            Method method = addressBookManager.getGetMethod(columnName);
                            if (null == method) {
                                throw new BusinessException("自定义通讯录字段: " + metadataColumn.getLabel() + "不存在！");
                            }
                            if (null != addressBook) {
                                Object custValue = method.invoke(addressBook, new Object[]{});
                                if (metadataColumn.getType() == 0) {
                                    String showValue = null == custValue ? "" : String.valueOf(custValue);
                                    row.addDataCell(showValue, 1);
                                }
                                if (metadataColumn.getType() == 1) {
                                    String showValue = "";
                                    if (custValue != null) {
                                        DecimalFormat df = new DecimalFormat();
                                        df.setMinimumFractionDigits(0);
                                        df.setMaximumFractionDigits(4);
                                        showValue = df.format(Double.valueOf(String.valueOf(custValue)));
                                        showValue = showValue.replaceAll(",", "");
                                    }
                                    row.addDataCell(showValue, 1);
                                }
                                if (metadataColumn.getType() == 2) {
                                    String showValue = null == custValue ? "" : Datetimes.format((Date) custValue, "yyyy-MM-dd");
                                    row.addDataCell(showValue, 1);
                                }
                                if (metadataColumn.getType() == 3) {
                                    String showValue = null == custValue ? "" : String.valueOf(custValue);
                                    String txt = "";
                                    if (Strings.isNotBlank(showValue)) {
                                        try {
                                            txt = ResourceUtil.getString(enumManagerNew.getEItemNameById(Long.valueOf(showValue)));
                                        } catch (Exception e) {
                                        }
                                    }
                                    row.addDataCell(txt, 1);
                                }
                                if (metadataColumn.getType() == 4) {
                                    String showValue = null == custValue ? "" : String.valueOf(custValue);
                                    String txt = "";
                                    if (Strings.isNotBlank(showValue)) {
                                        try {
                                            V3xOrgMember m = orgManager.getMemberById(Long.valueOf(showValue));
                                            if (Strings.isNotBlank(m.getName())) {
                                                txt = m.getName() + "(" + m.getLoginName() + ")";
                                            }
                                        } catch (Exception e) {
                                        }
                                    }
                                    row.addDataCell(txt, 1);
                                }
                                if (metadataColumn.getType() == 5) {
                                    String showValue = null == custValue ? "" : String.valueOf(custValue);
                                    String txt = "";
                                    if (Strings.isNotBlank(showValue)) {
                                        try {
                                            V3xOrgDepartment d = orgManager.getDepartmentById(Long.valueOf(showValue));
                                            if (Strings.isNotBlank(d.getName())) {
                                                txt = d.getName();
                                                if (Strings.isNotBlank(d.getCode())) {
                                                    txt += "(" + d.getCode() + ")";
                                                }
                                            }
                                        } catch (Exception e) {
                                        }
                                    }
                                    row.addDataCell(txt, 1);
                                }
                            } else {
                                row.addDataCell("", 1);
                            }
                        } catch (Exception e) {
                            logger.error("", e);
                        }
                    }
                }

                datarow[i] = row;
            }
            try {
                dataRecord.addDataRow(datarow);
            } catch (Exception e) {
                log.error("error", e);
            }
        }
        short subHeight = 2000;
        dataRecord.setSubHeight(subHeight);
        if (isInternal) {
            String columnName = member_name + "," + member_loginName + "," + member_code + "," + member_sortId + "," + member_account + "," + member_deptName + ","
                    + member_primaryPost + "," + member_secondPost + "," + member_levelName + "," + member_tel + "," + member_email + "," + member_gender + "," + member_birthday + "," + member_officeNumber + ""
                    + "," + member_primaryLanguange + "," + member_location + "," + member_hiredate + "," + member_reporter;
            String columnNameAllStr = columnName + customerAddressBookFields;
            String[] columnNameAll = columnNameAllStr.split(",");
            dataRecord.setColumnName(columnNameAll);
            if (SystemEnvironment.functionSwitch(Plugins.DATA_I18N)) {//国际化多语言开关
                dataRecord.setSubTitle(ResourceUtil.getString("org.member_form.list.desc.international"));
            } else {
                dataRecord.setSubTitle(ResourceUtil.getString("org.member_form.list.desc"));
            }
        } else {
            String columnName = member_name + "," + member_loginName + "," + member_code + "," + member_sortId + "," + member_account + "," + member_deptName + "," + member_workscope + "," +
                    member_primaryPost + "," + member_levelName + "," + member_tel + "," + member_email + "," + member_gender + "," + member_birthday + "," + member_officeNumber + "," + member_primaryLanguange;
            String columnNameAllStr = columnName + customerAddressBookFields;
            String[] columnNameAll = columnNameAllStr.split(",");
            dataRecord.setColumnName(columnNameAll);
            if (SystemEnvironment.functionSwitch(Plugins.DATA_I18N)) {//国际化多语言开关
                dataRecord.setSubTitle(ResourceUtil.getString("org.member_ext_form.list.desc.international"));
            } else {
                dataRecord.setSubTitle(ResourceUtil.getString("org.member_ext_form.list.desc"));
            }
        }
        dataRecord.setTitle(member_list);
        dataRecord.setSheetName(member_list);
        return dataRecord;
    }

    /**
     * 上传图片界面
     *
     * @param request
     * @param response
     * @return
     * @throws Exception
     */
    public ModelAndView uploadPicture(HttpServletRequest request, HttpServletResponse response) throws Exception {
        ModelAndView modelAndView = new ModelAndView("apps/organization/member/selectFileUpload");
        String fileUpload_maxSize = SystemProperties.getInstance().getProperty("fileUpload.maxSize");
        // 默认值50m,可根据系统配置改变
        Long maxFileSize = 52428800L;
        if (Strings.isNotBlank(fileUpload_maxSize)) {
            maxFileSize = Long.parseLong(fileUpload_maxSize);
        }
        String maxSize = maxFileSize / (1024 * 1024) + "m";
        modelAndView.addObject("maxSize", maxSize);
        String loginAccountId = request.getParameter("loginAccountId");
        modelAndView.addObject("loginAccountId", loginAccountId);
        return modelAndView;
    }

    /**
     * 执行批量压缩图片上传功能
     *
     * @param request
     * @param response
     * @return
     * @throws Exception
     */
    @SuppressWarnings({"unchecked", "rawtypes"})
    @CheckRoleAccess(roleTypes = {Role_NAME.GroupAdmin, Role_NAME.AccountAdministrator, Role_NAME.HrAdmin})
    public ModelAndView doUploadFile(HttpServletRequest request, HttpServletResponse response) throws Exception {
        ModelAndView modelAndView = new ModelAndView("apps/organization/member/importReport");
        HttpSession session = request.getSession();
        List<ResultObject> resultList = new ArrayList<ResultObject>();
        // 如果不是文件上传类型的请求，直接从session取结果列表（针对结果列表翻页）
        if (!(request instanceof MultipartHttpServletRequest)) {
            Object result = session.getAttribute("picUploadReport");
            if (result != null) {
                resultList = (List<ResultObject>) result;
            }
        } else {// 如果是文件上传请求，进行文件上传操作
            Long accountId = null;
            String loginAccountId = request.getParameter("loginAccountId");
            if (Strings.isNotBlank(loginAccountId)) {
                accountId = Long.valueOf(loginAccountId);
            } else {
                accountId = AppContext.currentAccountId();
            }
            // 上传的压缩的文件地址
            String impUrl = request.getParameter("impURL");
            String zipFileName = "";
            if (Strings.isNotBlank(impUrl)) {
                zipFileName = impUrl.substring(impUrl.lastIndexOf("\\") + 1);
            }
            Map<String, V3XFile> v3xFiles = null;
            Long maxFileSize = null;
            try {
                String fileUpload_maxSize = SystemProperties.getInstance().getProperty("fileUpload.maxSize");
                if (Strings.isNotBlank(fileUpload_maxSize)) {
                    maxFileSize = Long.parseLong(fileUpload_maxSize);
                }
                // 50m,zip文件
                v3xFiles = fileManager.uploadFiles(request, "zip", maxFileSize);
                if (v3xFiles != null) {
                    V3XFile v3x = null;
                    Iterator<String> keys = v3xFiles.keySet().iterator();
                    String key = "";
                    while (keys.hasNext()) {
                        key = keys.next();
                        v3x = (V3XFile) v3xFiles.get(key);
                        if (v3x != null) {
                            // 取参数是否进行文件覆盖，1：跳过；0：覆盖
                            String repeat = request.getParameter("repeat");
                            Boolean override = false;
                            if (Strings.isNotBlank(repeat) && "0".equals(repeat)) {
                                override = true;
                            }
                            resultList = memberManager.uploadMemberPicAttachment(zipFileName, v3x, accountId, override);
                            // 放入session主要是报告翻页使用，翻页时请求不是multipartRequest,结果取上次的列表进行翻页
                            session.setAttribute("picUploadReport", resultList);
                        }
                    }
                }
            } catch (BusinessException e) {
                ResultObject ro = new ResultObject();
                if (Strings.isBlank(impUrl)) {// 如果是空，文件超过系统限制大小50m后接收不到属性，命名为“上传文件”
                    zipFileName = ResourceUtil.getString("member.photo.batch.upload.file.name");
                }
                ro.setName(zipFileName);
                ro.setSuccess(ResourceUtil.getString("import.report.fail"));
                ro.setDescription(e.getMessage());
                resultList.add(ro);
                session.setAttribute("picUploadReport", resultList);
                List subl = DataUtil.pageForList(resultList);
                modelAndView.addObject("resultlst", subl);
                return modelAndView;
            } catch (Exception e) {
                logger.error("batch upload image error!", e);
            }
            if (Strings.isEmpty(resultList)) {// 如果结果列表无数据，表示全部上传成功
                super.rendJavaScript(response, "alert('" + ResourceUtil.getString("member.photo.batch.upload.success")
                        + "');if(parent && parent.uploadDialog){parent.uploadDialog.close();};");
                return null;
            }
        }
        List subl = DataUtil.pageForList(resultList);
        modelAndView.addObject("resultlst", subl);
        return modelAndView;
    }

    /**
     * 导出结果报告
     *
     * @param request
     * @param response
     * @return
     * @throws Exception
     */
    @SuppressWarnings("rawtypes")
    public ModelAndView exportReport(HttpServletRequest request, HttpServletResponse response) throws Exception {
        HttpSession session = request.getSession();
        DataRow[] datarow = null;
        if (datarow == null) {
            List resultlst = (List) session.getAttribute("picUploadReport");
            datarow = DataUtil.createDataRowsFromResultObjects(resultlst);
        }
        String import_report = ResourceUtil.getString("member.photo.batch.upload.report");
        String import_data = ResourceUtil.getString("import.data");
        String import_result = ResourceUtil.getString("import.result");
        String import_description = ResourceUtil.getString("import.description");
        String title = "";
        String sheetName = "";
        title = import_report;
        sheetName = import_report;
        // 将导入结果添加到excel中
        DataRecord dataRecord = new DataRecord();
        try {
            dataRecord.addDataRow(datarow);
        } catch (Exception e) {
            log.error(e.getMessage(), e);
        }
        String[] columnName = {import_data, import_result, import_description};
        dataRecord.setColumnName(columnName);
        dataRecord.setTitle(title);
        dataRecord.setSheetName(sheetName);

        try {
            fileToExcelManager.save(response, import_report, dataRecord);
        } catch (Exception e) {
            log.error("error", e);
        }
        return null;
    }

    /**
     * 修改枚举引用状态
     * @param workLocal
     */
    private void refEnum(String workLocal) {
        String[] localIds = workLocal.split(",");
        int index_id = 0;
        for (String id : localIds) {
            try {
                if (index_id == 0) {
                    if (Strings.isBlank(id)) {
                        return;
                    }
                    enumManagerNew.updateEnumItemRef(Long.valueOf(id));
                } else {
                    enumManagerNew.updateEnumItemRef(Long.valueOf(id));
                }
            } catch (Exception e) {
                logger.error("enum error：", e);
            }
            index_id++;
        }
    }

}
