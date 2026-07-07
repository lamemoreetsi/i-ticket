<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ taglib uri="jakarta.tags.core" prefix="c" %>
<%@ taglib uri="jakarta.tags.functions" prefix="fn" %>

<c:if test="${empty SESSION_USER or SESSION_USER.role != 'ADMIN'}">
    <c:redirect url="/login.jsp"/>
</c:if>

<%-- Read and clear flash messages before any output --%>
<%
    String flashOk  = (String) session.getAttribute("PROFILE_SUCCESS");
    String flashErr = (String) session.getAttribute("PROFILE_ERROR");
    if (flashOk  != null) session.removeAttribute("PROFILE_SUCCESS");
    if (flashErr != null) session.removeAttribute("PROFILE_ERROR");
%>

<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Admin Profile — HelpDesk</title>
    <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/@tabler/icons-webfont@3.0.0/tabler-icons.min.css">
    <link rel="stylesheet" href="${pageContext.request.contextPath}/css/dashboard.css">
    <link rel="stylesheet" href="${pageContext.request.contextPath}/css/profile.css">
</head>
<body>

<div class="toast-container" id="toastContainer"></div>

<%-- ── Topbar ─────────────────────────────────────────────── --%>
<header class="topbar">
    <div class="topbar-brand">
        <div class="brand-icon"><i class="ti ti-ticket"></i></div>
        <span class="brand-name">HelpDesk</span>
        <span class="brand-sub">IT Support Portal</span>
        <span class="role-chip role-chip--admin" style="margin-left:4px;">ADMIN</span>
    </div>
    <div class="topbar-right">
        <span class="user-pill">
            <i class="ti ti-shield-check"></i>
            <c:out value="${SESSION_USER.firstName} ${SESSION_USER.lastName}"/>
        </span>
        <a href="${pageContext.request.contextPath}/admin-dashboard.jsp" class="btn-logout">
            <i class="ti ti-layout-grid"></i> Dashboard
        </a>
        <button type="button" class="btn-logout" id="btnRegisterAdmin">
            <i class="ti ti-user-plus"></i> Register Admin
        </button>
        <a href="${pageContext.request.contextPath}/UserControllerServlet?command=LOGOUT" class="btn-logout">
            <i class="ti ti-logout"></i> Sign out
        </a>
    </div>
</header>

<main class="main-content">

    <%-- ── Page header ──────────────────────────────────────── --%>
    <div class="pf-page-header">
        <div>
            <h1 class="pf-page-title">
                <i class="ti ti-shield-check pf-title-icon"></i> Admin profile
            </h1>
            <p class="pf-page-sub">Manage your account details and registered system users</p>
        </div>
    </div>

    <%-- ── Notification banner ─────────────────────────────── --%>
    <div class="pf-notif-banner" id="notifBanner">
        <i class="ti ti-bell-ringing pf-notif-icon"></i>
        <div>
            <strong class="pf-notif-strong">Enable notifications</strong><br>
            Get browser alerts when users reply to tickets.
        </div>
        <button class="pf-btn-notif-allow" id="btnAllowNotif">Allow</button>
        <button class="pf-btn-notif-dismiss" id="btnDismissNotif" title="Dismiss">×</button>
    </div>

    <%-- ── Two-column: edit form + contact card ────────────── --%>
    <div class="pf-grid">

        <%-- LEFT: Edit form --%>
        <div class="pf-card">
            <div class="pf-card-header">
                <i class="ti ti-user-edit"></i> Edit my details
            </div>
            <div class="pf-card-body">

                <div class="pf-avatar pf-avatar--admin">
                    ${fn:substring(profileUser.firstName,0,1)}${fn:substring(profileUser.lastName,0,1)}
                </div>

                <form action="${pageContext.request.contextPath}/ProfileControllerServlet" method="post">
                    <input type="hidden" name="csrfToken" value="${sessionScope.CSRF_TOKEN}">
                    <div class="pf-field-group">
                        <div class="pf-field-label"><i class="ti ti-user"></i> First name</div>
                        <input type="text" name="firstName" class="pf-field-input" required
                               value="<c:out value='${profileUser.firstName}'/>">
                    </div>
                    <div class="pf-field-group">
                        <div class="pf-field-label"><i class="ti ti-user"></i> Last name</div>
                        <input type="text" name="lastName" class="pf-field-input" required
                               value="<c:out value='${profileUser.lastName}'/>">
                    </div>
                    <div class="pf-field-group">
                        <div class="pf-field-label"><i class="ti ti-mail"></i> Email address</div>
                        <input type="email" name="email" class="pf-field-input" required
                               value="<c:out value='${profileUser.email}'/>">
                    </div>
                    <div class="pf-field-group">
                        <div class="pf-field-label"><i class="ti ti-phone"></i> Office line</div>
                        <input type="text" name="officeLine" class="pf-field-input"
                               placeholder="e.g. Ext. 2045"
                               value="<c:out value='${profileUser.officeLine}'/>">
                    </div>
                    <button type="submit" class="pf-btn-save">
                        <i class="ti ti-check"></i> Save changes
                    </button>
                </form>

                <hr class="pf-divider">

                <div class="pf-info-row">
                    <div class="pf-info-icon"><i class="ti ti-id-badge"></i></div>
                    <div>
                        <div class="pf-info-label">Username</div>
                        <div class="pf-info-value"><c:out value="${profileUser.username}"/></div>
                    </div>
                </div>
                <div class="pf-info-row">
                    <div class="pf-info-icon"><i class="ti ti-shield-check"></i></div>
                    <div>
                        <div class="pf-info-label">Role</div>
                        <div class="pf-info-value">
                            <span class="role-chip role-chip--admin">ADMIN</span>
                        </div>
                    </div>
                </div>
                <div class="pf-info-row">
                    <div class="pf-info-icon"><i class="ti ti-calendar"></i></div>
                    <div>
                        <div class="pf-info-label">Member since</div>
                        <div class="pf-info-value">
                            <c:out value="${profileUser.createdAt.toString().replace('T',' ').substring(0,16)}"/>
                        </div>
                    </div>
                </div>

            </div>
        </div>

        <%-- RIGHT: Contact card --%>
        <div class="pf-card">
            <div class="pf-card-header">
                <i class="ti ti-id-badge-2"></i> My contact card
            </div>
            <div class="pf-card-body">

                <div class="pf-avatar pf-avatar--admin">
                    ${fn:substring(profileUser.firstName,0,1)}${fn:substring(profileUser.lastName,0,1)}
                </div>

                <div class="pf-info-row">
                    <div class="pf-info-icon"><i class="ti ti-user"></i></div>
                    <div>
                        <div class="pf-info-label">Full name</div>
                        <div class="pf-info-value">
                            <c:out value="${profileUser.firstName} ${profileUser.lastName}"/>
                        </div>
                    </div>
                </div>
                <div class="pf-info-row">
                    <div class="pf-info-icon"><i class="ti ti-at"></i></div>
                    <div>
                        <div class="pf-info-label">Username</div>
                        <div class="pf-info-value"><c:out value="${profileUser.username}"/></div>
                    </div>
                </div>
                <div class="pf-info-row">
                    <div class="pf-info-icon"><i class="ti ti-mail"></i></div>
                    <div>
                        <div class="pf-info-label">Email</div>
                        <div class="pf-info-value">
                            <a href="mailto:<c:out value='${profileUser.email}'/>" class="pf-link">
                                <c:out value="${profileUser.email}"/>
                            </a>
                        </div>
                    </div>
                </div>
                <div class="pf-info-row">
                    <div class="pf-info-icon"><i class="ti ti-phone"></i></div>
                    <div>
                        <div class="pf-info-label">Office line</div>
                        <div class="pf-info-value">
                            <c:choose>
                                <c:when test="${not empty profileUser.officeLine}">
                                    <c:out value="${profileUser.officeLine}"/>
                                </c:when>
                                <c:otherwise>
                                    <span class="pf-muted-italic">Not set</span>
                                </c:otherwise>
                            </c:choose>
                        </div>
                    </div>
                </div>
                <div class="pf-info-row">
                    <div class="pf-info-icon"><i class="ti ti-shield-check"></i></div>
                    <div>
                        <div class="pf-info-label">Role</div>
                        <div class="pf-info-value">
                            <span class="role-chip role-chip--admin">ADMIN</span>
                        </div>
                    </div>
                </div>
                <div class="pf-info-row">
                    <div class="pf-info-icon"><i class="ti ti-calendar"></i></div>
                    <div>
                        <div class="pf-info-label">Account created</div>
                        <div class="pf-info-value">
                            <c:out value="${profileUser.createdAt.toString().replace('T',' ').substring(0,10)}"/>
                        </div>
                    </div>
                </div>

            </div>
        </div>

    </div><%-- /pf-grid --%>

    <%-- ── Registered users table ───────────────────────────── --%>
    <div class="pf-section-heading">
        <i class="ti ti-users"></i> Registered users
    </div>

    <div class="pf-table-wrap">
        <table class="pf-table">
            <thead>
            <tr>
                <th>Name</th>
                <th>Username</th>
                <th>Email</th>
                <th>Office line</th>
                <th>Role</th>
                <th>Joined</th>
                <th>Actions</th>
            </tr>
            </thead>
            <tbody>
            <c:choose>
                <c:when test="${empty allUsers}">
                    <tr>
                        <td colspan="7" class="pf-empty-row">
                            <i class="ti ti-users-off"></i>
                            <span>No users registered yet.</span>
                        </td>
                    </tr>
                </c:when>
                <c:otherwise>
                    <c:forEach var="u" items="${allUsers}">
                        <tr>
                            <td>
                                <div class="pf-user-name-cell">
                                    <div class="pf-user-initials">
                                            ${fn:substring(u.firstName,0,1)}${fn:substring(u.lastName,0,1)}
                                    </div>
                                    <c:out value="${u.firstName} ${u.lastName}"/>
                                </div>
                            </td>
                            <td><c:out value="${u.username}"/></td>
                            <td>
                                <a href="mailto:<c:out value='${u.email}'/>" class="pf-link">
                                    <c:out value="${u.email}"/>
                                </a>
                            </td>
                            <td>
                                <c:choose>
                                    <c:when test="${not empty u.officeLine}">
                                        <c:out value="${u.officeLine}"/>
                                    </c:when>
                                    <c:otherwise>
                                        <span class="pf-muted">—</span>
                                    </c:otherwise>
                                </c:choose>
                            </td>
                            <td>
                                <span class="role-chip ${u.role == 'ADMIN' ? 'role-chip--admin' : 'role-chip--user'}">
                                    <c:out value="${u.role}"/>
                                </span>
                            </td>
                            <td class="pf-date-cell">
                                <c:out value="${u.createdAt.toString().replace('T',' ').substring(0,10)}"/>
                            </td>
                            <td>
                                <c:choose>
                                    <c:when test="${u.id == SESSION_USER.id}">
                                        <span class="pf-you-tag">You</span>
                                    </c:when>
                                    <c:otherwise>
                                        <button class="pf-btn-delete-user"
                                                data-id="${u.id}"
                                                data-name="<c:out value='${u.firstName} ${u.lastName}'/>">
                                            <i class="ti ti-trash"></i> Delete
                                        </button>
                                    </c:otherwise>
                                </c:choose>
                            </td>
                        </tr>
                    </c:forEach>
                </c:otherwise>
            </c:choose>
            </tbody>
        </table>
    </div>

</main>

<%-- ── Delete user modal ────────────────────────────────────── --%>
<div class="pf-modal-overlay" id="deleteModal">
    <div class="pf-modal-box">
        <div class="pf-modal-header">
            <i class="ti ti-alert-triangle"></i> Delete user account
        </div>
        <div class="pf-modal-body" id="modalBody">
            This action cannot be undone.
        </div>
        <div class="pf-modal-actions">
            <button class="pf-btn-modal-cancel" onclick="closeModal()">Cancel</button>
            <button class="pf-btn-modal-confirm" onclick="submitDelete()">
                <i class="ti ti-trash"></i> Yes, delete
            </button>
        </div>
    </div>
</div>

<form id="deleteForm"
      action="${pageContext.request.contextPath}/ProfileControllerServlet"
      method="post" style="display:none;">
    <input type="hidden" name="action" value="DELETE_USER">
    <input type="hidden" name="targetUserId" id="deleteTargetId">
    <input type="hidden" name="csrfToken" value="${sessionScope.CSRF_TOKEN}">
</form>

<%-- ── Register new admin modal ─────────────────────────────── --%>
<div class="pf-modal-overlay" id="registerAdminModal">
    <div class="pf-modal-box">
        <div class="pf-modal-header">
            <i class="ti ti-user-plus"></i> Register a new admin
        </div>
        <div class="pf-modal-body">
            <form id="registerAdminForm"
                  action="${pageContext.request.contextPath}/UserControllerServlet"
                  method="post">
                <input type="hidden" name="command" value="REGISTER_ADMIN">
                <input type="hidden" name="csrfToken" value="${sessionScope.CSRF_TOKEN}">

                <div class="pf-field-group">
                    <div class="pf-field-label"><i class="ti ti-user"></i> First name</div>
                    <input type="text" name="firstName" class="pf-field-input" required>
                </div>
                <div class="pf-field-group">
                    <div class="pf-field-label"><i class="ti ti-user"></i> Last name</div>
                    <input type="text" name="lastName" class="pf-field-input" required>
                </div>
                <div class="pf-field-group">
                    <div class="pf-field-label"><i class="ti ti-id-badge"></i> Username</div>
                    <input type="text" name="username" class="pf-field-input" required>
                </div>
                <div class="pf-field-group">
                    <div class="pf-field-label"><i class="ti ti-mail"></i> Email address</div>
                    <input type="email" name="email" class="pf-field-input" required>
                </div>
                <div class="pf-field-group">
                    <div class="pf-field-label"><i class="ti ti-lock"></i> Password</div>
                    <input type="password" name="password" class="pf-field-input" required
                           minlength="8">
                </div>
                <div class="pf-field-group">
                    <div class="pf-field-label"><i class="ti ti-lock"></i> Confirm password</div>
                    <input type="password" name="confirmPassword" class="pf-field-input" required
                           minlength="8">
                </div>
                <p style="font-size:12px;color:#64748b;margin:4px 0 0;">
                    Min 8 characters, at least 1 number and 1 special character.
                </p>
            </form>
        </div>
        <div class="pf-modal-actions">
            <button class="pf-btn-modal-cancel" type="button" onclick="closeRegisterAdminModal()">Cancel</button>
            <button class="pf-btn-modal-confirm" type="button" onclick="document.getElementById('registerAdminForm').submit()">
                <i class="ti ti-user-plus"></i> Create admin
            </button>
        </div>
    </div>
</div>

<footer class="site-footer">© 2026 I-TICKET System</footer>

<script>
    /* ── Toast ──────────────────────────────────────────────── */
    function showToast(msg, type) {
        var tc = document.getElementById('toastContainer');
        var el = document.createElement('div');
        el.className = 'toast-msg toast-msg--' + (type || 'success');
        el.innerHTML = '<i class="ti ti-' + (type === 'error' ? 'alert-circle' : 'circle-check') + '"></i> ' + msg;
        tc.appendChild(el);
        setTimeout(function () { el.style.opacity = '0'; el.style.transition = 'opacity .4s'; }, 3400);
        setTimeout(function () { el.remove(); }, 3900);
    }

    /* ── Flash messages ─────────────────────────────────────── */
    <% if (flashOk != null) {
           String s = flashOk.replace("\\","\\\\").replace("'","\\'"); %>
    document.addEventListener('DOMContentLoaded', function () { showToast('<%= s %>', 'success'); });
    <% } %>
    <% if (flashErr != null) {
           String s = flashErr.replace("\\","\\\\").replace("'","\\'"); %>
    document.addEventListener('DOMContentLoaded', function () { showToast('<%= s %>', 'error'); });
    <% } %>

    /* ── Delete modal ───────────────────────────────────────── */
    document.querySelectorAll('.pf-btn-delete-user').forEach(function (btn) {
        btn.addEventListener('click', function () {
            document.getElementById('deleteTargetId').value = btn.getAttribute('data-id');
            document.getElementById('modalBody').innerHTML =
                'Permanently delete <strong>' + btn.getAttribute('data-name') + '</strong>?<br>' +
                'All their tickets and messages will also be erased.<br>' +
                '<span class="pf-modal-warning">This cannot be undone.</span>';
            document.getElementById('deleteModal').classList.add('active');
        });
    });

    function closeModal() { document.getElementById('deleteModal').classList.remove('active'); }
    function submitDelete() { closeModal(); document.getElementById('deleteForm').submit(); }

    document.getElementById('deleteModal').addEventListener('click', function (e) {
        if (e.target === this) closeModal();
    });

    /* ── Register admin modal ───────────────────────────────── */
    var registerAdminModal = document.getElementById('registerAdminModal');
    document.getElementById('btnRegisterAdmin').addEventListener('click', function () {
        registerAdminModal.classList.add('active');
    });
    function closeRegisterAdminModal() { registerAdminModal.classList.remove('active'); }
    registerAdminModal.addEventListener('click', function (e) {
        if (e.target === this) closeRegisterAdminModal();
    });

    /* ── Notification permission ────────────────────────────── */
    (function () {
        var banner  = document.getElementById('notifBanner');
        var allow   = document.getElementById('btnAllowNotif');
        var dismiss = document.getElementById('btnDismissNotif');
        if ('Notification' in window && Notification.permission === 'default'
            && !sessionStorage.getItem('notifDismissed')) {
            banner.classList.add('visible');
        }
        allow.addEventListener('click', function () {
            Notification.requestPermission().then(function (p) {
                banner.classList.remove('visible');
                if (p === 'granted') showToast('Notifications enabled!', 'success');
            });
        });
        dismiss.addEventListener('click', function () {
            banner.classList.remove('visible');
            sessionStorage.setItem('notifDismissed', '1');
        });
    })();
</script>

</body>
</html>
