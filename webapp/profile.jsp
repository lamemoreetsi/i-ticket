<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ taglib uri="jakarta.tags.core" prefix="c" %>
<%@ taglib uri="jakarta.tags.functions" prefix="fn" %>

<c:if test="${empty SESSION_USER}">
    <c:redirect url="/login.jsp"/>
</c:if>

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
    <title>My Profile — HelpDesk</title>
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
    </div>
    <div class="topbar-right">
        <a href="${pageContext.request.contextPath}/ProfileControllerServlet"
           class="user-pill" style="text-decoration:none;cursor:pointer;">
            <i class="ti ti-user-circle"></i>
            <c:out value="${SESSION_USER.firstName} ${SESSION_USER.lastName}"/>
        </a>
        <a href="${pageContext.request.contextPath}/dashboard.jsp" class="btn-logout">
            <i class="ti ti-layout-grid"></i> Dashboard
        </a>
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
                <i class="ti ti-user-circle pf-title-icon"></i> My profile
            </h1>
            <p class="pf-page-sub">Manage your personal information and contact details</p>
        </div>
    </div>

    <%-- ── Notification banner ─────────────────────────────── --%>
    <div class="pf-notif-banner" id="notifBanner">
        <i class="ti ti-bell-ringing pf-notif-icon"></i>
        <div>
            <strong class="pf-notif-strong">Enable notifications</strong><br>
            Get instant browser alerts when IT Support replies to your tickets.
        </div>
        <button class="pf-btn-notif-allow" id="btnAllowNotif">Allow</button>
        <button class="pf-btn-notif-dismiss" id="btnDismissNotif" title="Dismiss">×</button>
    </div>

    <%-- ── Two-column grid ─────────────────────────────────── --%>
    <div class="pf-grid">

        <%-- LEFT: Edit form --%>
        <div class="pf-card">
            <div class="pf-card-header">
                <i class="ti ti-user-edit"></i> Edit my details
            </div>
            <div class="pf-card-body">

                <div class="pf-avatar pf-avatar--user">
                    ${fn:substring(profileUser.firstName,0,1)}${fn:substring(profileUser.lastName,0,1)}
                </div>

                <form action="${pageContext.request.contextPath}/ProfileControllerServlet" method="post">
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
                        <div class="pf-field-label"><i class="ti ti-phone"></i> Office line / extension</div>
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
                    <div class="pf-info-icon"><i class="ti ti-shield"></i></div>
                    <div>
                        <div class="pf-info-label">Role</div>
                        <div class="pf-info-value">
                            <span class="role-chip role-chip--user">
                                <c:out value="${profileUser.role}"/>
                            </span>
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

        <%-- RIGHT: IT Support contact --%>
        <div class="pf-card">
            <div class="pf-card-header">
                <i class="ti ti-headset"></i> IT Support contact
            </div>
            <div class="pf-card-body">

                <c:choose>
                    <c:when test="${not empty adminContact}">

                        <div class="pf-avatar pf-avatar--admin">
                                ${fn:substring(adminContact.firstName,0,1)}${fn:substring(adminContact.lastName,0,1)}
                        </div>

                        <div class="pf-support-banner">
                            <i class="ti ti-shield-check"></i>
                            Your dedicated IT Support administrator
                        </div>

                        <div class="pf-info-row">
                            <div class="pf-info-icon"><i class="ti ti-user"></i></div>
                            <div>
                                <div class="pf-info-label">Full name</div>
                                <div class="pf-info-value">
                                    <c:out value="${adminContact.firstName} ${adminContact.lastName}"/>
                                </div>
                            </div>
                        </div>
                        <div class="pf-info-row">
                            <div class="pf-info-icon"><i class="ti ti-mail"></i></div>
                            <div>
                                <div class="pf-info-label">Email</div>
                                <div class="pf-info-value">
                                    <c:out value="${adminContact.email}"/>
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
                            <div class="pf-info-icon"><i class="ti ti-phone"></i></div>
                            <div>
                                <div class="pf-info-label">Office line</div>
                                <div class="pf-info-value">
                                    <c:choose>
                                        <c:when test="${not empty adminContact.officeLine}">
                                            <c:out value="${adminContact.officeLine}"/>
                                        </c:when>
                                        <c:otherwise>
                                            <span class="pf-muted-italic">Not provided</span>
                                        </c:otherwise>
                                    </c:choose>
                                </div>
                            </div>
                        </div>

                        <a href="mailto:<c:out value='${adminContact.email}'/>" class="pf-contact-btn">
                            <i class="ti ti-mail-forward"></i> Send email to IT Support
                        </a>

                    </c:when>
                    <c:otherwise>
                        <div class="pf-no-admin">
                            <i class="ti ti-user-off pf-no-admin-icon"></i>
                            No IT admin contact found.
                        </div>
                    </c:otherwise>
                </c:choose>

            </div>
        </div>

    </div><%-- /pf-grid --%>

</main>

<footer class="site-footer">© 2026 I-TICKET System</footer>

<script>
    /* ── Toast ──────────────────────────────────────────────── */
    function showToast(msg, type) {
        var tc = document.getElementById('toastContainer');
        var el = document.createElement('div');
        el.className = 'toast-msg toast-msg--' + (type || 'success');
        el.innerHTML = '<i class="ti ti-' + (type === 'error' ? 'alert-circle' : 'circle-check') + '"></i> ' + msg;
        tc.appendChild(el);
        setTimeout(function () { el.style.opacity = '0'; el.style.transition = 'opacity .4s'; }, 3200);
        setTimeout(function () { el.remove(); }, 3700);
    }

    /* ── Flash messages ─────────────────────────────────────── */
    <% if (flashOk != null) {
           String s = flashOk.replace("\\","\\\\").replace("'","\\'"); %>
    window.addEventListener('DOMContentLoaded', function () { showToast('<%= s %>', 'success'); });
    <% } %>
    <% if (flashErr != null) {
           String s = flashErr.replace("\\","\\\\").replace("'","\\'"); %>
    window.addEventListener('DOMContentLoaded', function () { showToast('<%= s %>', 'error'); });
    <% } %>

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
