<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ taglib uri="jakarta.tags.core" prefix="c" %>

<%-- Guard: redirect to login if no session --%>
<c:if test="${empty SESSION_USER}">
    <c:redirect url="/login.jsp"/>
</c:if>

<%-- Fallback Data loader if page is refreshed or directly accessed safely --%>
<%@ page import="DAO.TicketDAO, DAO.AnnouncementDAO, Model.Ticket, Model.Announcement, java.util.List" %>
<%@ page import="java.sql.SQLException" %>
<%
    Model.User su = (Model.User) session.getAttribute("SESSION_USER");
    if (su != null) {
        if (request.getAttribute("tickets") == null) {
            TicketDAO dao = new TicketDAO();
            try {
                List<Ticket> tickets = dao.getTicketsByUser(su.getId());
                request.setAttribute("tickets", tickets);
                request.setAttribute("sessionUser", su);
            } catch (SQLException e) {
                e.printStackTrace();
            }
        }
        if (request.getAttribute("announcements") == null) {
            try {
                request.setAttribute("announcements", new AnnouncementDAO().getAll());
            } catch (SQLException e) {
                e.printStackTrace();
            }
        }
    }
%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>My Dashboard — HelpDesk</title>
    <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/css/bootstrap.min.css">
    <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/@tabler/icons-webfont@3.0.0/tabler-icons.min.css">
    <link rel="stylesheet" href="${pageContext.request.contextPath}/css/dashboard.css">
    <style>
        .toast-container { position:fixed;bottom:24px;right:24px;z-index:9999;display:flex;flex-direction:column;gap:8px;pointer-events:none; }
        .toast-msg { background:#111827;border:1px solid #1e3a5f;border-radius:10px;padding:12px 18px;font-size:13px;color:#e2e8f0;display:flex;align-items:center;gap:10px;box-shadow:0 4px 24px #000a;animation:slideIn .25s ease;min-width:260px; }
        .toast-msg--success { border-color:#14532d;color:#86efac;background:#021f14; }
        .toast-msg--error   { border-color:#7f1d1d;color:#fca5a5;background:#1a0a0a; }
        @keyframes slideIn { from{transform:translateY(20px);opacity:0} to{transform:translateY(0);opacity:1} }
        .live-dot { width:8px;height:8px;background:#22c55e;border-radius:50%;display:inline-block;animation:pulse 1.5s infinite; }
        @keyframes pulse { 0%,100%{opacity:1}50%{opacity:.3} }

        .actions-cell { display: flex; gap: 6px; align-items: center; }

        /* Integrated Announcements Style Blocks */
        .announce-panel { background:#111827;border:1px solid #1e3a5f;border-radius:12px;overflow:hidden;margin-top:2rem; }
        .announce-header { display:flex;align-items:center;justify-content:space-between;padding:14px 18px;background:#0d1424;border-bottom:1px solid #1e3a5f; }
        .announce-header-left { display:flex;align-items:center;gap:8px;font-size:13px;font-weight:600;color:#94a3b8; }
        .announce-body { padding:16px;display:flex;flex-direction:column;gap:12px;max-height:360px;overflow-y:auto; }
        .announce-empty { text-align:center;padding:2rem;color:#475569;font-size:13px; }
        .announce-item { background:#0f172a;border:1px solid #1e3a5f;border-radius:10px;padding:14px 16px; }
        .announce-item-title { font-size:14px;font-weight:600;color:#e2e8f0;margin-bottom:6px;display:flex;align-items:flex-start;gap:8px; }
        .announce-item-title i { color:#378ADD;font-size:16px;flex-shrink:0;margin-top:1px; }
        .announce-item-body { font-size:13px;color:#94a3b8;line-height:1.55;white-space:pre-wrap;margin-bottom:8px; }
        .announce-meta { font-size:11px;color:#475569;display:flex;gap:10px;align-items:center;flex-wrap:wrap; }
    </style>
</head>
<body>

<div class="toast-container" id="toastContainer"></div>

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
        <a href="${pageContext.request.contextPath}/UserControllerServlet?command=LOGOUT" class="btn-logout">
            <i class="ti ti-logout"></i> Sign out
        </a>
    </div>
</header>

<main class="main-content">

    <div class="page-header">
        <div>
            <h1 class="page-title">My Support Activity</h1>
            <p class="page-sub">Track and manage your requests &nbsp;<span class="live-dot"></span></p>
        </div>
        <button class="btn-new" data-bs-toggle="modal" data-bs-target="#newTicketModal">
            <i class="ti ti-plus"></i> Open Ticket
        </button>
    </div>

    <div class="notif-banner" id="notifBanner">
        <i class="ti ti-bell-ringing"></i>
        <span>Get notified the moment IT support replies to one of your tickets, even when this tab isn't focused.</span>
        <button class="btn-notif-allow" id="notifAllowBtn" onclick="requestNotifPermission()">Enable</button>
        <button class="btn-notif-dismiss" onclick="dismissNotifBanner()" title="Dismiss">&times;</button>
    </div>

    <div class="table-card">
        <div class="table-responsive">
            <table class="ticket-table">
                <thead>
                <tr>
                    <th>Ticket Description / Summary</th>
                    <th>Category</th>
                    <th>Priority</th>
                    <th>Current Status</th>
                    <th>Action</th>
                </tr>
                </thead>
                <tbody id="ticketBody">
                <c:choose>
                    <c:when test="${empty tickets}">
                        <tr>
                            <td colspan="5" class="empty-row">
                                <i class="ti ti-inbox"></i>
                                <span>No active support interactions opened.</span>
                            </td>
                        </tr>
                    </c:when>
                    <c:otherwise>
                        <c:forEach var="t" items="${tickets}">
                            <tr class="ticket-row" data-ticket-row-id="${t.id}" data-updated="<c:out value="${t.updatedAt}"/>" onclick="window.location='${pageContext.request.contextPath}/TicketControllerServlet?command=VIEW_TICKET&ticketId=${t.id}'" style="cursor:pointer;">
                                <td class="summary-cell"><strong><c:out value="${t.summary}"/></strong></td>
                                <td><c:out value="${t.category}"/></td>
                                <td>
                                    <span class="badge-priority badge-priority--${t.priority.toLowerCase()}">
                                        <i class="ti ti-arrow-up"></i><c:out value="${t.priority}"/>
                                    </span>
                                </td>
                                <td>
                                    <span class="badge-status badge-status--${t.status}">
                                        <c:out value="${t.status.replace('_', ' ')}"/>
                                    </span>
                                </td>
                                <td onclick="event.stopPropagation()">
                                    <div class="actions-cell">
                                            <%-- Read summary/priority/category/description off data-* attrs so any
                                                 quotes, apostrophes, or newlines in free text can't break the handler. --%>
                                        <button class="btn-action btn-edit" title="Edit Support Ticket"
                                                data-ticket-id="${t.id}"
                                                data-ticket-summary="<c:out value="${t.summary}"/>"
                                                data-ticket-priority="<c:out value="${t.priority}"/>"
                                                data-ticket-category="<c:out value="${t.category}"/>"
                                                data-ticket-description="<c:out value="${t.description}"/>"
                                                onclick="openEditModalFromBtn(this)">
                                            <i class="ti ti-pencil"></i>
                                        </button>
                                        <form action="${pageContext.request.contextPath}/TicketControllerServlet" method="post" onsubmit="return confirm('Permanently close and delete this ticket?')" style="display:inline;">
                                            <input type="hidden" name="command" value="DELETE_TICKET">
                                            <input type="hidden" name="ticketId" value="${t.id}">
                                            <input type="hidden" name="redirectTo" value="dashboard">
                                            <input type="hidden" name="csrfToken" value="${sessionScope.CSRF_TOKEN}">
                                            <button type="submit" class="btn-action btn-del" title="Delete ticket">
                                                <i class="ti ti-trash"></i>
                                            </button>
                                        </form>
                                    </div>
                                </td>
                            </tr>
                        </c:forEach>
                    </c:otherwise>
                </c:choose>
                </tbody>
            </table>
        </div>
    </div>

    <%-- Shared Global Announcements View --%>
    <div class="announce-panel">
        <div class="announce-header">
            <div class="announce-header-left">
                <i class="ti ti-speakerphone"></i> Global Announcements & Alerts
                &nbsp;<span class="live-dot"></span>
            </div>
        </div>
        <div class="announce-body" id="announceBody">
            <c:choose>
                <c:when test="${empty announcements}">
                    <div class="announce-empty" id="announceEmpty">
                        <i class="ti ti-speakerphone" style="font-size:24px;display:block;margin-bottom:8px;"></i>
                        No active bulletins broadcasting at this time.
                    </div>
                </c:when>
                <c:otherwise>
                    <c:forEach var="a" items="${announcements}">
                        <div class="announce-item" id="ann-${a.id}">
                            <div class="announce-item-title"><i class="ti ti-speakerphone"></i><c:out value="${a.title}"/></div>
                            <div class="announce-item-body"><c:out value="${a.body}"/></div>
                            <div class="announce-meta">
                                <span><i class="ti ti-user" style="font-size:11px;"></i> <c:out value="${a.authorName}"/></span>
                                <span><i class="ti ti-clock" style="font-size:11px;"></i> <c:out value="${a.createdAt.toString().replace('T',' ').substring(0,16)}"/></span>
                            </div>
                        </div>
                    </c:forEach>
                </c:otherwise>
            </c:choose>
        </div>
    </div>
</main>

<%-- Modal: Request System Support (Creation) --%>
<div class="modal fade" id="newTicketModal" tabindex="-1" aria-hidden="true">
    <div class="modal-dialog modal-dialog-centered">
        <div class="modal-content modal-dark">
            <div class="modal-header">
                <h5 class="modal-title"><i class="ti ti-edit"></i> Request System Support</h5>
                <button type="button" class="btn-close btn-close-white" data-bs-dismiss="modal"></button>
            </div>
            <form action="${pageContext.request.contextPath}/TicketControllerServlet" method="post" enctype="multipart/form-data">
                <input type="hidden" name="command" value="CREATE_TICKET">
                <input type="hidden" name="csrfToken" value="${sessionScope.CSRF_TOKEN}">
                <div class="modal-body">

                    <div class="mb-3">
                        <label class="form-label-custom">Summary of Issue</label>
                        <input type="text" name="summary" class="input-dark" required placeholder="Brief description of what's broken...">
                    </div>

                    <div class="mb-3">
                        <label class="form-label-custom">Detailed Description</label>
                        <textarea name="description" class="input-dark" rows="4" placeholder="Provide precise context details about your problem..." style="resize: none; width: 100%; font-size: 13px; color: #e2e8f0; padding: 10px 12px;"></textarea>
                    </div>

                    <div class="row g-3 mb-3">
                        <div class="col-6">
                            <label class="form-label-custom">Priority</label>
                            <select name="priority" class="input-dark">
                                <option value="Low">Low</option>
                                <option value="Medium" selected>Medium</option>
                                <option value="High">High</option>
                            </select>
                        </div>
                        <div class="col-6">
                            <label class="form-label-custom">Category</label>
                            <select name="category" class="input-dark">
                                <option value="Network">Network</option>
                                <option value="Hardware">Hardware</option>
                                <option value="Software">Software</option>
                                <option value="Other">Other</option>
                            </select>
                        </div>
                    </div>

                    <div class="mb-1">
                        <label class="form-label-custom">Upload Screenshot from PC</label>
                        <input type="file" name="image" class="input-dark" accept="image/*">
                    </div>

                </div>
                <div class="modal-footer">
                    <button type="button" class="btn-portal-ghost" data-bs-dismiss="modal">Cancel</button>
                    <button type="submit" class="btn-portal-primary">File Ticket</button>
                </div>
            </form>
        </div>
    </div>
</div>

<%-- Modal: Edit System Support Details --%>
<div class="modal fade" id="editTicketModal" tabindex="-1" aria-hidden="true">
    <div class="modal-dialog modal-dialog-centered">
        <div class="modal-content modal-dark">
            <div class="modal-header">
                <h5 class="modal-title"><i class="ti ti-pencil"></i> Edit Support Ticket Details</h5>
                <button type="button" class="btn-close btn-close-white" data-bs-dismiss="modal"></button>
            </div>
            <%-- Added enctype attributes here to cleanly support updating binary file buffers --%>
            <form action="${pageContext.request.contextPath}/TicketControllerServlet" method="post" enctype="multipart/form-data">
                <input type="hidden" name="command" value="UPDATE_TICKET">
                <input type="hidden" name="ticketId" id="editTicketId">
                <input type="hidden" name="csrfToken" value="${sessionScope.CSRF_TOKEN}">
                <div class="modal-body">

                    <div class="mb-3">
                        <label class="form-label-custom">Summary of Issue</label>
                        <input type="text" id="editSummary" name="summary" class="input-dark" required>
                    </div>

                    <div class="mb-3">
                        <label class="form-label-custom">Detailed Description</label>
                        <textarea id="editDescription" name="description" class="input-dark" rows="4" placeholder="Update information context..." style="resize: none; width: 100%; font-size: 13px; color: #e2e8f0; padding: 10px 12px;"></textarea>
                    </div>

                    <div class="row g-3 mb-3">
                        <div class="col-6">
                            <label class="form-label-custom">Priority</label>
                            <select id="editPriority" name="priority" class="input-dark">
                                <option value="Low">Low</option>
                                <option value="Medium">Medium</option>
                                <option value="High">High</option>
                            </select>
                        </div>
                        <div class="col-6">
                            <label class="form-label-custom">Category</label>
                            <select id="editCategory" name="category" class="input-dark">
                                <option value="Network">Network</option>
                                <option value="Hardware">Hardware</option>
                                <option value="Software">Software</option>
                                <option value="Other">Other</option>
                            </select>
                        </div>
                    </div>

                    <div class="mb-1">
                        <label class="form-label-custom">Replace Screenshot Document (Optional)</label>
                        <input type="file" name="image" class="input-dark" accept="image/*">
                        <span style="font-size:11px; color:#475569; display:block; margin-top:4px;">Leave blank to preserve current attachment image.</span>
                    </div>

                </div>
                <div class="modal-footer">
                    <button type="button" class="btn-portal-ghost" data-bs-dismiss="modal">Cancel</button>
                    <button type="submit" class="btn-portal-primary">Save Changes</button>
                </div>
            </form>
        </div>
    </div>
</div>

<footer class="site-footer">© 2026 I-TICKET System</footer>

<script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/js/bootstrap.bundle.min.js"></script>
<script>
    const CTX = '${pageContext.request.contextPath}';
    let lastAnnounceTime = Date.now();

    function showToast(msg, type = 'success') {
        const container = document.getElementById('toastContainer');
        if(!container) return;
        const div = document.createElement('div');
        div.className = `toast-msg toast-msg--\${type}`;
        div.innerHTML = `<i class="ti ti-\${type==='success'?'circle-check':'alert-circle'}"></i> <span>\${msg}</span>`;
        container.appendChild(div);
        setTimeout(() => div.remove(), 4000);
    }

    // ── Flash toast from session after a redirect (create/update/delete ticket) ──
    // This page previously had showToast() defined but nothing called it on load,
    // so TOAST_SUCCESS/TOAST_ERROR set by the servlet were silently dropped.
    <%
        String dashTs = (String) session.getAttribute("TOAST_SUCCESS");
        String dashTe = (String) session.getAttribute("TOAST_ERROR");
        if (dashTs != null) { session.removeAttribute("TOAST_SUCCESS"); %>
    window.addEventListener('DOMContentLoaded', () => showToast('<%= dashTs.replace("'","\\'") %>', 'success'));
    <%  } %>
    <%  if (dashTe != null) { session.removeAttribute("TOAST_ERROR"); %>
    window.addEventListener('DOMContentLoaded', () => showToast('<%= dashTe.replace("'","\\'") %>', 'error'));
    <%  } %>

    // Updated JavaScript wrapper mapping parameters directly down to DOM selectors safely
    function openEditModal(id, summary, priority, category, description) {
        document.getElementById('editTicketId').value = id;
        document.getElementById('editSummary').value = summary;
        document.getElementById('editPriority').value = priority;
        document.getElementById('editCategory').value = category;
        document.getElementById('editDescription').value = description || '';
        const modal = new bootstrap.Modal(document.getElementById('editTicketModal'));
        modal.show();
    }

    // Reads the ticket's fields off the button's data-* attributes instead of inline JS
    // string interpolation — a summary/description with a quote, apostrophe, or newline
    // used to break the old onclick="..." string and silently no-op the whole button.
    function openEditModalFromBtn(btn) {
        openEditModal(
            btn.dataset.ticketId,
            btn.dataset.ticketSummary || '',
            btn.dataset.ticketPriority || '',
            btn.dataset.ticketCategory || '',
            btn.dataset.ticketDescription || ''
        );
    }

    function esc(str) {
        if (!str) return '';
        return str.replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;').replace(/"/g, '&quot;');
    }

    function buildAnn(a) {
        let dt = a.createdAt ? a.createdAt.replace('T',' ').substring(0,16) : '';
        return `<div class="announce-item" id="ann-\${a.id}">
            <div class="announce-item-title"><i class="ti ti-speakerphone"></i> \${esc(a.title)}</div>
            <div class="announce-item-body">\${esc(a.body)}</div>
            <div class="announce-meta">
                <span><i class="ti ti-user" style="font-size:11px;"></i> \${esc(a.authorName)}</span>
                <span><i class="ti ti-clock" style="font-size:11px;"></i> \${dt}</span>
            </div>
        </div>`;
    }

    // ── Browser notifications: permission banner ───────────────────
    const NOTIF_DISMISS_KEY = 'notifBannerDismissed';

    function refreshNotifBanner() {
        const banner = document.getElementById('notifBanner');
        if (!banner) return;
        const supported = 'Notification' in window;
        const dismissed = sessionStorage.getItem(NOTIF_DISMISS_KEY) === '1';
        const show = supported && Notification.permission === 'default' && !dismissed;
        banner.classList.toggle('visible', show);
    }

    function requestNotifPermission() {
        if (!('Notification' in window)) return;
        Notification.requestPermission().then(() => refreshNotifBanner());
    }

    function dismissNotifBanner() {
        sessionStorage.setItem(NOTIF_DISMISS_KEY, '1');
        refreshNotifBanner();
    }

    function sendNotif(title, body, tag) {
        if (!('Notification' in window) || Notification.permission !== 'granted') return;
        try {
            const n = new Notification(title, {
                body, icon: `\${CTX}/favicon.ico`, tag, renotify: true
            });
            n.onclick = () => { window.focus(); n.close(); };
        } catch (e) {}
    }

    refreshNotifBanner();

    // ── Track each ticket's last-known updatedAt so we can tell when IT support
    //    (or anything else) has changed one of the user's tickets since they last
    //    looked at the dashboard. Seeded from the server-rendered rows on page load
    //    so refreshing the page never fires a false "updated" notification. ──
    const TICKET_UPDATE_KEY = 'lastTicketUpdates';
    function loadKnownUpdates() {
        try { return JSON.parse(sessionStorage.getItem(TICKET_UPDATE_KEY) || '{}'); }
        catch (e) { return {}; }
    }
    function saveKnownUpdates(map) {
        sessionStorage.setItem(TICKET_UPDATE_KEY, JSON.stringify(map));
    }
    (function seedKnownUpdates() {
        const known = loadKnownUpdates();
        document.querySelectorAll('#ticketBody tr[data-ticket-row-id]').forEach(row => {
            const id = row.dataset.ticketRowId;
            if (!(id in known)) known[id] = row.dataset.updated || '';
        });
        saveKnownUpdates(known);
    })();

    function checkTicketUpdates(tickets) {
        const known = loadKnownUpdates();
        let changed = false;
        tickets.forEach(t => {
            const id = String(t.id);
            const prev = known[id];
            if (prev !== undefined && prev !== t.updatedAt) {
                sendNotif('HelpDesk — Ticket Updated',
                    `"\${t.summary}" was just updated (status: \${(t.status||'').replace('_',' ')}).`,
                    'ticket-update-' + id);
                showToast(`📩 Your ticket "\${esc(t.summary)}" was updated.`, 'success');
                changed = true;
            }
            known[id] = t.updatedAt;
        });
        saveKnownUpdates(known);
        return changed;
    }

    function poll() {
        fetch(`\${CTX}/AnnouncementControllerServlet?command=POLL&since=\${lastAnnounceTime}`)
            .then(r => r.ok ? r.json() : null)
            .then(data => {
                if (!data) return;
                if (Array.isArray(data.announcements) && data.announcements.length) {
                    const ab = document.getElementById('announceBody');
                    const empty = document.getElementById('announceEmpty');
                    if (empty) empty.remove();
                    data.announcements.forEach(a => {
                        if (!document.getElementById('ann-'+a.id)) {
                            ab.insertAdjacentHTML('afterbegin', buildAnn(a));
                            showToast('📢 Urgent Announcement: ' + a.title, 'success');
                            sendNotif('HelpDesk — New Announcement', a.title, 'announcement-' + a.id);
                        }
                    });
                    lastAnnounceTime = Date.now();
                }
                if (Array.isArray(data.tickets)) {
                    checkTicketUpdates(data.tickets);
                }
            })
            .catch(() => {});
    }
    setInterval(poll, 8000);
</script>
</body>
</html>