<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ taglib uri="jakarta.tags.core" prefix="c" %>

<c:if test="${empty SESSION_USER or SESSION_USER.role != 'ADMIN'}">
    <c:redirect url="/login.jsp"/>
</c:if>

<%@ page import="DAO.TicketDAO, DAO.AnnouncementDAO, Model.Ticket, Model.Announcement, java.util.List" %>
<%@ page import="java.sql.SQLException" %>
<%
    TicketDAO       tDao = new TicketDAO();
    AnnouncementDAO aDao = new AnnouncementDAO();
    try {
        List<Ticket> tickets = tDao.getAllTickets();
        request.setAttribute("tickets", tickets);
        request.setAttribute("openCount",       tickets.stream().filter(t -> "open".equals(t.getStatus())).count());
        request.setAttribute("inProgressCount", tickets.stream().filter(t -> "in_progress".equals(t.getStatus())).count());
        request.setAttribute("closedCount",     tickets.stream().filter(t -> "closed".equals(t.getStatus())).count());
        request.setAttribute("highCount",       tickets.stream().filter(t -> "High".equals(t.getPriority())).count());
        request.setAttribute("announcements",   aDao.getAll());
    } catch (SQLException e) { e.printStackTrace(); }
%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Admin — HelpDesk</title>
    <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/css/bootstrap.min.css">
    <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/@tabler/icons-webfont@3.0.0/tabler-icons.min.css">
    <link rel="stylesheet" href="${pageContext.request.contextPath}/css/dashboard.css">
    <style>
        .admin-badge { font-size:10px;font-weight:700;background:#185FA5;color:#85B7EB;border-radius:5px;padding:2px 8px;letter-spacing:.06em; }
        .stats-row { display:grid;grid-template-columns:repeat(4,1fr);gap:14px;margin-bottom:1.5rem; }
        .stat-card { background:#111827;border:1px solid #1e3a5f;border-radius:12px;padding:16px 20px;display:flex;align-items:center;gap:14px; }
        .stat-icon { width:40px;height:40px;border-radius:10px;display:flex;align-items:center;justify-content:center;font-size:20px;flex-shrink:0; }
        .stat-icon--open     { background:#0c1f35;color:#85B7EB; }
        .stat-icon--progress { background:#1a1200;color:#fcd34d; }
        .stat-icon--closed   { background:#111827;border:1px solid #334155;color:#64748b; }
        .stat-icon--high     { background:#1f0d0d;color:#fca5a5; }
        .stat-value { font-size:26px;font-weight:700;color:#f1f5f9;line-height:1; }
        .stat-label { font-size:12px;color:#64748b;margin-top:3px;font-weight:500; }
        /* Clickable stat cards stay visually identical to the static ones — */
        /* just a cursor + faint lift on hover so admins discover the report without any added chrome. */
        .stat-card--clickable { cursor:pointer;transition:transform .12s,border-color .12s; }
        .stat-card--clickable:hover { border-color:#334155;transform:translateY(-1px); }
        .stat-card--clickable:active { transform:translateY(0); }
        /* Report modal */
        .report-modal-body { padding:0 !important; }
        .report-tabs { display:flex;gap:6px;padding:14px 18px 0; }
        .report-tab {
            background:transparent;border:1px solid #1e3a5f;border-radius:7px;
            padding:6px 14px;font-size:12px;font-weight:600;color:#64748b;
            cursor:pointer;transition:border-color .12s,color .12s;
        }
        .report-tab.active { border-color:#378ADD;color:#85B7EB;background:#0c1f35; }
        .report-summary {
            display:flex;gap:10px;padding:16px 18px 4px;
        }
        .report-summary-card {
            flex:1;background:#0d1424;border:1px solid #1e3a5f;border-radius:9px;
            padding:11px 14px;
        }
        .report-summary-num { font-size:20px;font-weight:700;color:#f1f5f9;line-height:1; }
        .report-summary-cap { font-size:11px;color:#64748b;margin-top:3px; }
        .report-list { padding:8px 18px 18px;max-height:340px;overflow-y:auto; }
        .report-period {
            display:flex;align-items:center;justify-content:space-between;
            padding:10px 12px;border-radius:8px;margin-bottom:6px;background:#0d1424;
            border:1px solid #16233d;
        }
        .report-period-label { font-size:13px;color:#cbd5e1;font-weight:500; }
        .report-period-sub { font-size:11px;color:#475569;margin-top:1px; }
        .report-period-count { font-size:15px;font-weight:700;color:#85B7EB; }
        .report-empty { text-align:center;padding:2.5rem 1rem;color:#475569;font-size:13px; }
        .report-empty i { font-size:24px;display:block;margin-bottom:8px; }
        .filter-bar { display:flex;gap:10px;align-items:center;flex-wrap:wrap;margin-bottom:1rem; }
        .filter-select { background:#111827;border:1px solid #1e3a5f;border-radius:8px;padding:7px 12px;font-size:13px;color:#94a3b8;outline:none;cursor:pointer; }
        .filter-select:focus { border-color:#378ADD; }
        .filter-search-wrap { position:relative;flex:1;min-width:180px; }
        .filter-search-wrap i { position:absolute;left:10px;top:50%;transform:translateY(-50%);color:#475569;font-size:16px;pointer-events:none; }
        .filter-search { width:100%;background:#111827;border:1px solid #1e3a5f;border-radius:8px;padding:7px 12px 7px 34px;font-size:13px;color:#e2e8f0;outline:none; }
        .filter-search::placeholder { color:#334155; }
        .filter-search:focus { border-color:#378ADD; }
        /* Announcements */
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
        .btn-del-announce { background:transparent;border:1px solid #7f1d1d;border-radius:6px;color:#fca5a5;font-size:12px;padding:3px 10px;cursor:pointer;display:flex;align-items:center;gap:4px;margin-left:auto;transition:background .12s; }
        .btn-del-announce:hover { background:#1f0d0d; }
        .announce-footer { padding:14px 16px;border-top:1px solid #1e3a5f;background:#0d1424;display:flex;flex-direction:column;gap:8px; }
        .announce-input { width:100%;background:#0f172a;border:1px solid #1e3a5f;border-radius:8px;padding:9px 12px;font-size:13px;color:#e2e8f0;outline:none;font-family:inherit;transition:border-color .15s;margin-bottom:8px; }
        .announce-input::placeholder { color:#334155; }
        .announce-input:focus { border-color:#378ADD; }
        .announce-form-row { display:flex;gap:8px; }
        .announce-textarea { flex:1;background:#0f172a;border:1px solid #1e3a5f;border-radius:8px;padding:9px 12px;font-size:13px;color:#e2e8f0;outline:none;font-family:inherit;resize:none;transition:border-color .15s; }
        .announce-textarea::placeholder { color:#334155; }
        .announce-textarea:focus { border-color:#378ADD; }
        .btn-broadcast { display:flex;align-items:center;gap:6px;background:#185FA5;border:none;border-radius:8px;padding:9px 18px;font-size:13px;font-weight:600;color:#fff;cursor:pointer;white-space:nowrap;transition:background .15s; }
        .btn-broadcast:hover { background:#0c447c; }
        /* Toast */
        .toast-container { position:fixed;bottom:24px;right:24px;z-index:9999;display:flex;flex-direction:column;gap:8px;pointer-events:none; }
        .toast-msg { background:#111827;border:1px solid #1e3a5f;border-radius:10px;padding:12px 18px;font-size:13px;color:#e2e8f0;display:flex;align-items:center;gap:10px;box-shadow:0 4px 24px #000a;animation:slideIn .25s ease;min-width:260px; }
        .toast-msg--success { border-color:#14532d;color:#86efac;background:#021f14; }
        .toast-msg--error   { border-color:#7f1d1d;color:#fca5a5;background:#1a0a0a; }
        @keyframes slideIn { from{transform:translateY(20px);opacity:0} to{transform:translateY(0);opacity:1} }
        .live-dot { width:8px;height:8px;background:#22c55e;border-radius:50%;display:inline-block;animation:pulse 1.5s infinite; }
        @keyframes pulse { 0%,100%{opacity:1}50%{opacity:.3} }
        @media(max-width:768px){ .stats-row{grid-template-columns:1fr 1fr;} }
        @media(max-width:480px){ .stats-row{grid-template-columns:1fr;} }
    </style>
</head>
<body>

<div class="toast-container" id="toastContainer"></div>

<header class="topbar">
    <div class="topbar-brand">
        <div class="brand-icon"><i class="ti ti-ticket"></i></div>
        <span class="brand-name">HelpDesk</span>
        <span class="brand-sub">IT Support Portal</span>
        <span class="admin-badge">ADMIN</span>
    </div>
    <div class="topbar-right">
        <a href="${pageContext.request.contextPath}/ProfileControllerServlet"
           class="user-pill" style="text-decoration:none;cursor:pointer;">
            <i class="ti ti-shield-check"></i>
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
            <h1 class="page-title">All Tickets</h1>
            <p class="page-sub">Manage and respond to every support request &nbsp;<span class="live-dot"></span></p>
        </div>
    </div>

    <div class="notif-banner" id="notifBanner">
        <div class="notif-icon-wrap">
            <i class="ti ti-bell-ringing"></i>
        </div>
        <div class="notif-text">
            <strong>Enable Notifications</strong>
            Stay updated on new tickets and replies in real-time.
        </div>
        <div class="notif-actions">
            <button class="btn-notif-action btn-allow" onclick="requestNotifPermission()">Allow</button>
            <button class="btn-notif-action btn-dismiss" onclick="dismissNotifBanner()">Later</button>
        </div>
    </div>

    <div class="stats-row">
        <div class="stat-card stat-card--clickable" data-report-status="open" title="View open tickets report">
            <div class="stat-icon stat-icon--open"><i class="ti ti-folder-open"></i></div>
            <div><div class="stat-value" id="statOpen">${openCount}</div><div class="stat-label">Open</div></div></div>
        <div class="stat-card stat-card--clickable" data-report-status="in_progress" title="View in-progress tickets report">
            <div class="stat-icon stat-icon--progress"><i class="ti ti-loader"></i></div>
            <div><div class="stat-value" id="statProgress">${inProgressCount}</div><div class="stat-label">In Progress</div></div></div>
        <div class="stat-card stat-card--clickable" data-report-status="closed" title="View closed tickets report">
            <div class="stat-icon stat-icon--closed"><i class="ti ti-circle-check"></i></div>
            <div><div class="stat-value" id="statClosed">${closedCount}</div><div class="stat-label">Closed</div></div></div>
        <div class="stat-card stat-card--clickable" data-report-status="high" title="View high priority tickets report">
            <div class="stat-icon stat-icon--high"><i class="ti ti-flame"></i></div>
            <div><div class="stat-value" id="statHigh">${highCount}</div><div class="stat-label">High Priority</div></div></div>
    </div>

    <div class="filter-bar">
        <div class="filter-search-wrap">
            <i class="ti ti-search"></i>
            <input type="text" id="searchInput" class="filter-search" placeholder="Search tickets…">
        </div>
        <select id="statusFilter"   class="filter-select"><option value="">All Statuses</option><option value="open">Open</option><option value="in_progress">In Progress</option><option value="closed">Closed</option></select>
        <select id="priorityFilter" class="filter-select"><option value="">All Priorities</option><option value="High">High</option><option value="Medium">Medium</option><option value="Low">Low</option></select>
        <select id="categoryFilter" class="filter-select"><option value="">All Categories</option><option value="Network">Network</option><option value="Hardware">Hardware</option><option value="Software">Software</option><option value="Access">Access</option><option value="Other">Other</option></select>
    </div>

    <div class="table-card">
        <div class="table-responsive">
            <table class="ticket-table">
                <thead><tr>
                    <th>Summary</th><th>Raised By</th><th>Priority</th><th>Category</th><th>Status</th><th>Created</th><th>Action</th>
                </tr></thead>
                <tbody id="ticketBody">
                <c:choose>
                    <c:when test="${empty tickets}">
                        <tr><td colspan="7" class="empty-row"><i class="ti ti-inbox"></i><span>No tickets yet.</span></td></tr>
                    </c:when>
                    <c:otherwise>
                        <c:forEach var="t" items="${tickets}">
                            <tr class="ticket-row"
                                data-id="${t.id}"
                                data-summary="<c:out value="${t.summary}"/>"
                                data-status="${t.status}"
                                data-priority="${t.priority}"
                                data-category="${t.category}"
                                data-updated="<c:out value="${t.updatedAt}"/>"
                                onclick="window.location='${pageContext.request.contextPath}/TicketControllerServlet?command=ADMIN_VIEW_TICKET&ticketId=${t.id}'"
                                style="cursor:pointer;">
                                <td class="summary-cell"><c:out value="${t.summary}"/></td>
                                <td><c:out value="${t.creatorName}"/></td>
                                <td><span class="badge-priority badge-priority--${t.priority.toLowerCase()}"><i class="ti ti-arrow-up"></i><c:out value="${t.priority}"/></span></td>
                                <td><c:out value="${t.category}"/></td>
                                <td><span class="badge-status badge-status--${t.status}"><c:out value="${t.status}"/></span></td>
                                <td class="date-cell"><c:out value="${t.createdAt.toString().replace('T',' ').substring(0,16)}"/></td>
                                <td onclick="event.stopPropagation()">
                                    <button class="btn-action btn-del" title="Delete ticket"
                                            data-ticket-id="${t.id}" data-ticket-summary="<c:out value="${t.summary}"/>"
                                            onclick="confirmDeleteFromBtn(this)">
                                        <i class="ti ti-trash"></i>
                                    </button>
                                </td>
                            </tr>
                        </c:forEach>
                    </c:otherwise>
                </c:choose>
                </tbody>
            </table>
        </div>
    </div>

    <%-- Announcements panel --%>
    <div class="announce-panel">
        <div class="announce-header">
            <div class="announce-header-left">
                <i class="ti ti-speakerphone"></i> Announcements
                &nbsp;<span class="live-dot"></span>
            </div>
        </div>
        <div class="announce-body" id="announceBody">
            <c:choose>
                <c:when test="${empty announcements}">
                    <div class="announce-empty" id="announceEmpty">
                        <i class="ti ti-speakerphone" style="font-size:24px;display:block;margin-bottom:8px;"></i>
                        No announcements yet. Broadcast one below.
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
                                <form action="${pageContext.request.contextPath}/AnnouncementControllerServlet" method="post"
                                      style="margin:0;" onsubmit="return confirm('Delete this announcement?')">
                                    <input type="hidden" name="command" value="DELETE_ANNOUNCEMENT">
                                    <input type="hidden" name="announcementId" value="${a.id}">
                                    <input type="hidden" name="csrfToken" value="${sessionScope.CSRF_TOKEN}">
                                    <button type="submit" class="btn-del-announce"><i class="ti ti-trash"></i> Delete</button>
                                </form>
                            </div>
                        </div>
                    </c:forEach>
                </c:otherwise>
            </c:choose>
        </div>
        <div class="announce-footer">
            <form action="${pageContext.request.contextPath}/AnnouncementControllerServlet" method="post">
                <input type="hidden" name="command" value="ADD_ANNOUNCEMENT">
                <input type="hidden" name="csrfToken" value="${sessionScope.CSRF_TOKEN}">
                <input type="text" name="title" class="announce-input" placeholder="Announcement title…" required maxlength="120">
                <div class="announce-form-row">
                    <textarea name="body" class="announce-textarea" rows="2" placeholder="Write your message to all users…" required></textarea>
                    <button type="submit" class="btn-broadcast"><i class="ti ti-speakerphone"></i> Broadcast</button>
                </div>
            </form>
        </div>
    </div>

</main>

<%-- Delete modal --%>
<div class="modal fade" id="deleteModal" tabindex="-1" aria-hidden="true">
    <div class="modal-dialog modal-dialog-centered">
        <div class="modal-content modal-dark">
            <div class="modal-header">
                <h5 class="modal-title"><i class="ti ti-alert-triangle"></i> Delete Ticket</h5>
                <button type="button" class="btn-close btn-close-white" data-bs-dismiss="modal"></button>
            </div>
            <div class="modal-body">
                <p style="color:#cbd5e1;font-size:14px;">Permanently delete <strong id="delSummary" style="color:#f1f5f9;"></strong>? This cannot be undone.</p>
            </div>
            <div class="modal-footer">
                <button class="btn-portal-ghost" data-bs-dismiss="modal">Cancel</button>
                <form id="deleteForm" action="${pageContext.request.contextPath}/TicketControllerServlet" method="post">
                    <input type="hidden" name="command" value="DELETE_TICKET">
                    <input type="hidden" name="redirectTo" value="admin">
                    <input type="hidden" name="ticketId" id="delTicketId">
                    <input type="hidden" name="csrfToken" value="${sessionScope.CSRF_TOKEN}">
                    <button type="submit" class="btn-danger-solid"><i class="ti ti-trash"></i> Delete</button>
                </form>
            </div>
        </div>
    </div>
</div>

<%-- Status report modal (opened from the Open / In Progress / Closed stat cards) --%>
<div class="modal fade" id="reportModal" tabindex="-1" aria-hidden="true">
    <div class="modal-dialog modal-dialog-centered modal-lg">
        <div class="modal-content modal-dark">
            <div class="modal-header">
                <h5 class="modal-title"><i class="ti ti-chart-bar" id="reportIcon"></i> <span id="reportTitle">Ticket Report</span></h5>
                <button type="button" class="btn-close btn-close-white" data-bs-dismiss="modal"></button>
            </div>
            <div class="modal-body report-modal-body">
                <div class="report-tabs">
                    <button class="report-tab active" data-range="week" onclick="setReportRange('week')">This Week</button>
                    <button class="report-tab" data-range="month" onclick="setReportRange('month')">This Month</button>
                    <button class="report-tab" data-range="all" onclick="setReportRange('all')">All Time</button>
                </div>
                <div class="report-summary">
                    <div class="report-summary-card">
                        <div class="report-summary-num" id="reportTotal">0</div>
                        <div class="report-summary-cap">Tickets in range</div>
                    </div>
                    <div class="report-summary-card">
                        <div class="report-summary-num" id="reportHighPct">0%</div>
                        <div class="report-summary-cap">High priority share</div>
                    </div>
                </div>
                <div class="report-list" id="reportList"></div>
            </div>
        </div>
    </div>
</div>

<footer class="site-footer">© 2026 I-TICKET System</footer>
<script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/js/bootstrap.bundle.min.js"></script>
<script>
    const CTX = '${pageContext.request.contextPath}';
    const CSRF_TOKEN = '${sessionScope.CSRF_TOKEN}';
    let lastAnnounceTime = Date.now();

    // ── Ticket data for client-side status reports (Open/In Progress/Closed cards) ──
    // Built server-side from the same `tickets` list already used to render the table,
    // so the report always matches what's on screen without an extra round trip.
    const REPORT_TICKETS = [
        <%
            List<Ticket> rTickets = (List<Ticket>) request.getAttribute("tickets");
            if (rTickets != null) {
                boolean first = true;
                for (Ticket rt : rTickets) {
                    if (!first) { %>,<% }
                    first = false;
                    String rSummary = rt.getSummary() == null ? "" : rt.getSummary()
                            .replace("\\", "\\\\").replace("\"", "\\\"").replace("\n", " ").replace("\r", "")
                            .replace("</", "<\\/");
                    String rStatus  = rt.getStatus()   == null ? "" : rt.getStatus();
                    String rPrio    = rt.getPriority() == null ? "" : rt.getPriority();
                    String rCreated = rt.getCreatedAt() == null ? "" : rt.getCreatedAt().toString();
        %>{"id":<%= rt.getId() %>,"summary":"<%= rSummary %>","status":"<%= rStatus %>","priority":"<%= rPrio %>","createdAt":"<%= rCreated %>"}<%
                }
            }
        %>
    ];

    // ── Toast ─────────────────────────────────────────────────────
    function showToast(msg, type) {
        const tc = document.getElementById('toastContainer');
        const el = document.createElement('div');
        el.className = 'toast-msg toast-msg--' + (type || 'success');
        // FIXED: Changed '===' to '==' inside the Java EL tag string
        el.innerHTML = `<i class="ti ti-\${type == 'error' ? 'alert-circle' : 'circle-check'}"></i> \${msg}`;
        tc.appendChild(el);
        setTimeout(() => { el.style.opacity='0'; el.style.transition='opacity .4s'; }, 3200);
        setTimeout(() => el.remove(), 3700);
    }

    // Flash from session after redirect
    <% String flash = (String) session.getAttribute("TOAST_SUCCESS");
       if (flash != null) { session.removeAttribute("TOAST_SUCCESS"); %>
    window.addEventListener('DOMContentLoaded', () => showToast('<%= flash.replace("'","\\'") %>', 'success'));
    <% } %>
    <% String flashErr = (String) session.getAttribute("TOAST_ERROR");
       if (flashErr != null) { session.removeAttribute("TOAST_ERROR"); %>
    window.addEventListener('DOMContentLoaded', () => showToast('<%= flashErr.replace("'","\\'") %>', 'error'));
    <% } %>

    // ── Delete modal ──────────────────────────────────────────────
    function confirmDelete(id, summary) {
        document.getElementById('delTicketId').value = id;
        document.getElementById('delSummary').textContent = '#' + id + ' — ' + summary;
        new bootstrap.Modal(document.getElementById('deleteModal')).show();
    }
    // Reads id/summary off data-* attributes so special characters (quotes, apostrophes)
    // in a ticket summary can never break the click handler the way inline JS string
    // interpolation did before.
    function confirmDeleteFromBtn(btn) {
        confirmDelete(btn.dataset.ticketId, btn.dataset.ticketSummary || '');
    }

    // ── Filtering ─────────────────────────────────────────────────
    const searchInput    = document.getElementById('searchInput');
    const statusFilter   = document.getElementById('statusFilter');
    const priorityFilter = document.getElementById('priorityFilter');
    const categoryFilter = document.getElementById('categoryFilter');

    function applyFilters() {
        const q = searchInput.value.toLowerCase();
        const s = statusFilter.value, p = priorityFilter.value, c = categoryFilter.value;
        document.querySelectorAll('#ticketBody tr.ticket-row').forEach(r => {
            r.style.display = (
                (!q || r.dataset.summary.toLowerCase().includes(q)) &&
                (!s || r.dataset.status   === s) &&
                (!p || r.dataset.priority === p) &&
                (!c || r.dataset.category === c)
            ) ? '' : 'none';
        });
    }
    [searchInput,statusFilter,priorityFilter,categoryFilter].forEach(el =>
        el.addEventListener(el.tagName==='SELECT'?'change':'input', applyFilters));

    // ── Helpers for building HTML ─────────────────────────────────
    function esc(s) {
        return (s||'').replace(/&/g,'&amp;').replace(/</g,'&lt;').replace(/>/g,'&gt;')
            .replace(/"/g,'&quot;').replace(/'/g,'&#39;');
    }

    function buildRow(t) {
        const dt = (t.createdAt||'').substring(0,16).replace('T',' ');
        const pc = (t.priority||'medium').toLowerCase();
        return `<tr class="ticket-row" data-id="\${t.id}"
               data-summary="\${esc(t.summary)}" data-status="\${esc(t.status)}"
               data-priority="\${esc(t.priority)}" data-category="\${esc(t.category)}"
               data-updated="\${esc(t.updatedAt)}"
               onclick="window.location='\${CTX}/TicketControllerServlet?command=ADMIN_VIEW_TICKET&ticketId=\${t.id}'"
               style="cursor:pointer;">
        <td class="summary-cell">\${esc(t.summary)}</td>
        <td>\${esc(t.creatorName)}</td>
        <td><span class="badge-priority badge-priority--\${pc}"><i class="ti ti-arrow-up"></i>\${esc(t.priority)}</span></td>
        <td>\${esc(t.category)}</td>
        <td><span class="badge-status badge-status--\${esc(t.status)}">\${esc(t.status)}</span></td>
        <td class="date-cell">\${dt}</td>
        <td onclick="event.stopPropagation()">
            <button class="btn-action btn-del" title="Delete ticket"
                    data-ticket-id="\${t.id}" data-ticket-summary="\${esc(t.summary)}"
                    onclick="confirmDeleteFromBtn(this)">
                <i class="ti ti-trash"></i>
            </button>
        </td>
    </tr>`;
    }

    function buildAnn(a) {
        const dt = (a.createdAt||'').substring(0,16).replace('T',' ');
        return `<div class="announce-item" id="ann-\${a.id}">
        <div class="announce-item-title"><i class="ti ti-speakerphone"></i>\${esc(a.title)}</div>
        <div class="announce-item-body">\${esc(a.body)}</div>
        <div class="announce-meta">
            <span><i class="ti ti-user" style="font-size:11px;"></i> \${esc(a.authorName)}</span>
            <span><i class="ti ti-clock" style="font-size:11px;"></i> \${dt}</span>
            <form action="\${CTX}/AnnouncementControllerServlet" method="post"
                  style="margin:0;" onsubmit="return confirm('Delete this announcement?')">
                <input type="hidden" name="command" value="DELETE_ANNOUNCEMENT">
                <input type="hidden" name="announcementId" value="\${a.id}">
                <input type="hidden" name="csrfToken" value="\${CSRF_TOKEN}">
                <button type="submit" class="btn-del-announce"><i class="ti ti-trash"></i> Delete</button>
            </form>
        </div>
    </div>`;
    }

    // ── Live poll (every 8 s) ─────────────────────────────────────

    // ── Browser notifications: permission banner ───────────────────
    const NOTIF_DISMISS_KEY = 'adminNotifBannerDismissed';

    function refreshNotifBanner() {
        const banner = document.getElementById('notifBanner');
        if (!banner) return;
        const supported = 'Notification' in window;
        const dismissed = localStorage.getItem(NOTIF_DISMISS_KEY) === '1';
        const show = supported && Notification.permission === 'default' && !dismissed;
        banner.classList.toggle('visible', show);
    }

    function requestNotifPermission() {
        if (!('Notification' in window)) return;
        Notification.requestPermission().then(() => {
            // Whatever the user chose, don't ask again from this banner.
            localStorage.setItem(NOTIF_DISMISS_KEY, '1');
            refreshNotifBanner();
        });
    }

    function dismissNotifBanner() {
        localStorage.setItem(NOTIF_DISMISS_KEY, '1');
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

    // ── Track known ticket IDs + updatedAt so admins get notified the moment a
    //    NEW ticket comes in, or an EXISTING ticket changes (i.e. a user replied,
    //    since every reply bumps updatedAt). Seeded from the server-rendered table
    //    on page load so a normal refresh never fires a false notification. ──
    const knownTicketState = new Map(); // id -> updatedAt
    document.querySelectorAll('#ticketBody tr.ticket-row[data-id]').forEach(row => {
        knownTicketState.set(row.dataset.id, row.dataset.updated || '');
    });

    function diffAndNotifyTickets(tickets) {
        const seenIds = new Set();
        tickets.forEach(t => {
            const id = String(t.id);
            seenIds.add(id);
            if (!knownTicketState.has(id)) {
                // Brand-new ticket the admin hasn't seen yet
                sendNotif('HelpDesk — New Ticket',
                    `\${t.creatorName || 'A user'} opened: "\${t.summary}"`,
                    'new-ticket-' + id);
                showToast(`🆕 New ticket from \${esc(t.creatorName)}: "\${esc(t.summary)}"`, 'success');
            } else if (knownTicketState.get(id) !== t.updatedAt) {
                // Existing ticket changed — most commonly a new user reply
                sendNotif('HelpDesk — Ticket Activity',
                    `New activity on "\${t.summary}" (\${(t.status||'').replace('_',' ')}).`,
                    'ticket-activity-' + id);
                showToast(`📩 Activity on "\${esc(t.summary)}"`, 'success');
            }
            knownTicketState.set(id, t.updatedAt);
        });
        // Drop tickets that no longer exist (deleted) so memory doesn't grow stale
        Array.from(knownTicketState.keys()).forEach(id => {
            if (!seenIds.has(id)) knownTicketState.delete(id);
        });
    }

    function poll() {
        refreshNotifBanner();
        fetch(`\${CTX}/AnnouncementControllerServlet?command=POLL&since=\${lastAnnounceTime}`)
            .then(r => r.ok ? r.json() : null)
            .then(data => {
                if (!data) return;
                // Rebuild ticket table with fresh data
                if (Array.isArray(data.tickets)) {
                    const ts = data.tickets;
                    // Notify BEFORE re-rendering so the diff is against last-known state, not the DOM about to be replaced
                    diffAndNotifyTickets(ts);
                    document.getElementById('ticketBody').innerHTML =
                        ts.length ? ts.map(buildRow).join('') :
                            '<tr><td colspan="7" class="empty-row"><i class="ti ti-inbox"></i><span>No tickets yet.</span></td></tr>';
                    document.getElementById('statOpen').textContent     = ts.filter(t=>t.status==='open').length;
                    document.getElementById('statProgress').textContent = ts.filter(t=>t.status==='in_progress').length;
                    document.getElementById('statClosed').textContent   = ts.filter(t=>t.status==='closed').length;
                    document.getElementById('statHigh').textContent     = ts.filter(t=>t.priority==='High').length;
                    applyFilters();
                    // Keep the report data set fresh so the modal reflects live counts too
                    REPORT_TICKETS.length = 0;
                    ts.forEach(t => REPORT_TICKETS.push(t));
                }
                // Prepend new announcements
                if (Array.isArray(data.announcements) && data.announcements.length) {
                    const ab = document.getElementById('announceBody');
                    const empty = document.getElementById('announceEmpty');
                    if (empty) empty.remove();
                    data.announcements.forEach(a => {
                        if (!document.getElementById('ann-'+a.id)) {
                            ab.insertAdjacentHTML('afterbegin', buildAnn(a));
                            showToast('📢 New announcement: ' + a.title, 'success');
                            sendNotif('HelpDesk — New Announcement', a.title, 'announcement-' + a.id);
                        }
                    });
                    lastAnnounceTime = Date.now();
                }
            })
            .catch(() => {});
    }

    // ── Status report (Open / In Progress / Closed cards) ─────────
    const REPORT_META = {
        open:        { label: 'Open Tickets',        icon: 'ti-folder-open'  },
        in_progress: { label: 'In Progress Tickets',  icon: 'ti-loader'      },
        closed:      { label: 'Closed Tickets',       icon: 'ti-circle-check'},
        high:        { label: 'High Priority Tickets', icon: 'ti-flame'      }
    };
    let currentReportStatus = null;
    let currentReportRange  = 'week';

    document.querySelectorAll('.stat-card--clickable').forEach(card => {
        card.addEventListener('click', () => openReport(card.dataset.reportStatus));
    });

    function openReport(status) {
        currentReportStatus = status;
        currentReportRange  = 'week';
        const meta = REPORT_META[status] || { label: 'Tickets', icon: 'ti-chart-bar' };
        document.getElementById('reportTitle').textContent = meta.label + ' — Report';
        document.getElementById('reportIcon').className = 'ti ' + meta.icon;
        document.querySelectorAll('.report-tab').forEach(t => t.classList.toggle('active', t.dataset.range === 'week'));
        renderReport();
        new bootstrap.Modal(document.getElementById('reportModal')).show();
    }

    function setReportRange(range) {
        currentReportRange = range;
        document.querySelectorAll('.report-tab').forEach(t => t.classList.toggle('active', t.dataset.range === range));
        renderReport();
    }

    function startOfWeek(d) {
        const dt = new Date(d);
        const day = dt.getDay(); // 0 = Sunday
        dt.setHours(0,0,0,0);
        dt.setDate(dt.getDate() - day);
        return dt;
    }

    function renderReport() {
        if (!currentReportStatus) return;
        const now = new Date();
        // "high" isn't a ticket status — it's a priority that can appear alongside
        // any status — so it needs its own filter instead of matching t.status.
        const all = currentReportStatus === 'high'
            ? REPORT_TICKETS.filter(t => t.priority === 'High')
            : REPORT_TICKETS.filter(t => t.status === currentReportStatus);

        let cutoff = null;
        if (currentReportRange === 'week')  { cutoff = new Date(now); cutoff.setDate(cutoff.getDate() - 7); }
        if (currentReportRange === 'month') { cutoff = new Date(now); cutoff.setMonth(cutoff.getMonth() - 1); }

        const inRange = all.filter(t => {
            if (!cutoff) return true;
            const created = new Date(t.createdAt);
            return !isNaN(created) && created >= cutoff;
        });

        document.getElementById('reportTotal').textContent = inRange.length;
        const highCount = inRange.filter(t => t.priority === 'High').length;
        document.getElementById('reportHighPct').textContent =
            inRange.length ? Math.round((highCount / inRange.length) * 100) + '%' : '0%';

        const list = document.getElementById('reportList');
        if (!inRange.length) {
            list.innerHTML = '<div class="report-empty"><i class="ti ti-inbox"></i>No tickets in this range.</div>';
            return;
        }

        // Group by week (for "month"/"all") or by day (for "week") so admins get a
        // skimmable breakdown rather than one flat count.
        const groups = new Map(); // key -> { label, sub, count }

        inRange.forEach(t => {
            const created = new Date(t.createdAt);
            if (isNaN(created)) return;
            let key, label, sub;

            if (currentReportRange === 'week') {
                key = created.toISOString().slice(0, 10);
                label = created.toLocaleDateString(undefined, { weekday: 'long' });
                sub   = created.toLocaleDateString(undefined, { month: 'short', day: 'numeric' });
            } else {
                const weekStart = startOfWeek(created);
                key = weekStart.toISOString().slice(0, 10);
                const weekEnd = new Date(weekStart);
                weekEnd.setDate(weekEnd.getDate() + 6);
                label = 'Week of ' + weekStart.toLocaleDateString(undefined, { month: 'short', day: 'numeric' });
                sub   = weekStart.toLocaleDateString(undefined, { year: 'numeric' });
            }

            if (!groups.has(key)) groups.set(key, { label, sub, count: 0 });
            groups.get(key).count++;
        });

        const sortedKeys = Array.from(groups.keys()).sort().reverse();
        list.innerHTML = sortedKeys.map(k => {
            const g = groups.get(k);
            return `<div class="report-period">
                <div><div class="report-period-label">\${g.label}</div><div class="report-period-sub">\${g.sub}</div></div>
                <div class="report-period-count">\${g.count}</div>
            </div>`;
        }).join('');
    }
    setInterval(poll, 8000);
</script>
</body>
</html>