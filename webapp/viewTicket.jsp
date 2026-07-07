<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ taglib uri="jakarta.tags.core" prefix="c" %>

<c:if test="${empty SESSION_USER}">
    <c:redirect url="/login.jsp"/>
</c:if>
<c:if test="${empty ticket}">
    <c:redirect url="/dashboard.jsp"/>
</c:if>

<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Ticket — HelpDesk</title>
    <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/css/bootstrap.min.css">
    <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/@tabler/icons-webfont@3.0.0/tabler-icons.min.css">
    <link rel="stylesheet" href="${pageContext.request.contextPath}/css/dashboard.css">
    <style>
        /* ── Chat bubbles ──────────────────────────────────── */
        .bubble-wrap { display:flex;flex-direction:column;margin-bottom:4px; }
        .bubble-wrap--mine   { align-items:flex-end; }
        .bubble-wrap--theirs { align-items:flex-start; }

        .msg-bubble {
            max-width:75%;border-radius:14px;padding:10px 14px;
            font-size:14px;line-height:1.55;
        }
        .msg-bubble--mine {
            background:#185FA5;color:#fff;border-bottom-right-radius:4px;
        }
        .msg-bubble--theirs {
            background:#1e2d45;color:#cbd5e1;border:1px solid #1e3a5f;
            border-bottom-left-radius:4px;
        }
        .msg-meta-line {
            font-size:11px;color:#475569;margin-top:4px;
            display:flex;align-items:center;gap:6px;
        }
        .bubble-wrap--mine   .msg-meta-line { justify-content:flex-end; }
        .bubble-wrap--theirs .msg-meta-line { justify-content:flex-start; }
        .msg-role-chip {
            font-size:10px;font-weight:700;border-radius:4px;padding:1px 6px;
            background:#185FA5;color:#85B7EB;letter-spacing:.04em;
        }
        .bubble-wrap--mine .msg-role-chip { background:#0c447c;color:#bfdbfe; }

        /* ── Initial report (OP) bubble ────────────────────── */
        .bubble-starter {
            max-width:75%;background:#0d1527;border:1px dashed #2563eb;
            border-radius:14px;border-bottom-left-radius:4px;
            padding:10px 14px;font-size:14px;line-height:1.55;color:#cbd5e1;
        }
        .bubble-starter-meta {
            font-size:11px;color:#475569;margin-bottom:8px;
            display:flex;align-items:center;gap:6px;flex-wrap:wrap;
        }
        .bubble-starter-label {
            font-size:10px;font-weight:700;border-radius:4px;padding:1px 6px;
            background:#1e3a5f;color:#93c5fd;letter-spacing:.04em;
        }
        /* OP image fills the bubble width */
        .op-attachment {
            margin-top:10px;border-radius:8px;overflow:hidden;cursor:zoom-in;
            border:1px solid #1e3a5f;
        }
        .op-attachment img { width:100%;max-height:320px;object-fit:contain;background:#0a0f1e;display:block; }

        /* ── Reply message attachment ───────────────────────── */
        .msg-attachment { margin-top:8px;border-radius:8px;overflow:hidden;max-width:260px;cursor:zoom-in; }
        .msg-attachment img { width:100%;display:block;border-radius:8px; }

        /* ── Image preview in compose ──────────────────────── */
        .img-preview-wrap {
            display:none;align-items:center;gap:8px;background:#0f172a;
            border:1px solid #1e3a5f;border-radius:8px;padding:8px 10px;margin-top:6px;
        }
        .img-preview-wrap.active { display:flex; }
        .img-preview-wrap img { height:48px;width:48px;object-fit:cover;border-radius:6px; }
        .img-preview-name { font-size:12px;color:#94a3b8;flex:1;overflow:hidden;text-overflow:ellipsis;white-space:nowrap; }
        .btn-remove-img {
            background:transparent;border:none;color:#f87171;cursor:pointer;font-size:18px;line-height:1;padding:0;
        }

        /* ── Thread toolbar ────────────────────────────────── */
        .thread-toolbar {
            display:flex;gap:6px;align-items:center;padding:10px 16px 0;
        }
        .btn-toolbar {
            background:transparent;border:1px solid #1e3a5f;border-radius:7px;
            padding:5px 10px;font-size:12px;color:#94a3b8;cursor:pointer;
            display:flex;align-items:center;gap:5px;transition:border-color .12s,color .12s;
        }
        .btn-toolbar:hover { border-color:#378ADD;color:#e2e8f0; }
        .btn-toolbar i { font-size:15px; }

        /* ── Toast ─────────────────────────────────────────── */
        .toast-container {
            position:fixed;bottom:24px;right:24px;z-index:9999;
            display:flex;flex-direction:column;gap:8px;pointer-events:none;
        }
        .toast-msg {
            background:#111827;border:1px solid #1e3a5f;border-radius:10px;
            padding:12px 18px;font-size:13px;color:#e2e8f0;display:flex;
            align-items:center;gap:10px;box-shadow:0 4px 24px #000a;
            animation:slideIn .25s ease;min-width:240px;
        }
        .toast-msg--success { border-color:#14532d;color:#86efac;background:#021f14; }
        .toast-msg--error   { border-color:#7f1d1d;color:#fca5a5;background:#1a0a0a; }
        @keyframes slideIn { from{transform:translateY(20px);opacity:0}to{transform:translateY(0);opacity:1} }

        /* ── Lightbox ───────────────────────────────────────── */
        .lightbox-overlay {
            display:none;position:fixed;inset:0;background:#000c;z-index:10000;
            align-items:center;justify-content:center;cursor:zoom-out;
        }
        .lightbox-overlay.active { display:flex; }
        .lightbox-overlay img { max-width:90vw;max-height:90vh;border-radius:8px;box-shadow:0 8px 40px #000; }
        .lightbox-close {
            position:absolute;top:18px;right:22px;font-size:28px;
            color:#fff;cursor:pointer;line-height:1;background:none;border:none;
        }
    </style>
</head>
<body>

<div class="toast-container" id="toastContainer"></div>

<div class="lightbox-overlay" id="lightbox" onclick="closeLightbox()">
    <button class="lightbox-close" onclick="closeLightbox()">&times;</button>
    <img id="lightboxImg" src="" alt="Full size">
</div>

<header class="topbar">
    <div class="topbar-brand">
        <div class="brand-icon"><i class="ti ti-ticket"></i></div>
        <span class="brand-name">HelpDesk</span>
        <span class="brand-sub">IT Support Portal</span>
    </div>
    <div class="topbar-right">
        <%-- My Tickets button removed per requirements --%>
        <span class="user-pill">
            <i class="ti ti-user-circle"></i>
            <c:out value="${SESSION_USER.firstName} ${SESSION_USER.lastName}"/>
        </span>
        <a href="${pageContext.request.contextPath}/dashboard.jsp" class="btn-logout">
            <i class="ti ti-layout-grid"></i> Dashboard
        </a>
        <a href="${pageContext.request.contextPath}/UserControllerServlet?command=LOGOUT" class="btn-logout">
            <i class="ti ti-logout"></i> Sign out
        </a>
    </div>
</header>

<main class="main-content">

    <%-- Page header --%>
    <div class="page-header">
        <div>
            <h1 class="page-title"><c:out value="${ticket.summary}"/></h1>
            <p class="page-sub">
                Opened by <strong><c:out value="${ticket.creatorName}"/></strong>
                &nbsp;·&nbsp;
                <c:out value="${ticket.createdAt.toString().replace('T',' ').substring(0,16)}"/>
            </p>
        </div>
        <span class="badge-status badge-status--${ticket.status}" style="font-size:13px;padding:6px 16px;">
            <c:out value="${ticket.status}"/>
        </span>
    </div>

    <%-- Meta cards --%>
    <div class="meta-row">
        <div class="meta-card">
            <div class="meta-label"><i class="ti ti-flag"></i> Priority</div>
            <span class="badge-priority badge-priority--${ticket.priority.toLowerCase()}">
                <c:out value="${ticket.priority}"/>
            </span>
        </div>
        <div class="meta-card">
            <div class="meta-label"><i class="ti ti-tag"></i> Category</div>
            <div class="meta-value"><c:out value="${ticket.category}"/></div>
        </div>
        <div class="meta-card">
            <div class="meta-label"><i class="ti ti-user"></i> Status</div>
            <span class="badge-status badge-status--${ticket.status}"><c:out value="${ticket.status}"/></span>
        </div>
        <div class="meta-card">
            <div class="meta-label"><i class="ti ti-refresh"></i> Last Updated</div>
            <div class="meta-value">
                <c:out value="${ticket.updatedAt.toString().replace('T',' ').substring(0,16)}"/>
            </div>
        </div>
    </div>

    <%-- ── Chat thread ─────────────────────────────────────── --%>
    <div class="thread-card">
        <div class="thread-header">
            <i class="ti ti-message-circle"></i> Activity &amp; Messages
        </div>

        <div class="thread-body" id="threadBody">

            <%-- ── OP bubble: description + ticket image ─── --%>
            <%-- Always shown first in the thread so the user sees their original
                 report at the top, including any image they attached on creation. --%>
            <div style="display:flex;flex-direction:column;align-items:flex-start;margin-bottom:4px;">
                <div class="bubble-starter">
                    <div class="bubble-starter-meta">
                        <span class="bubble-starter-label">OP</span>
                        <span><c:out value="${ticket.creatorName}"/></span>
                        <span>·</span>
                        <span><c:out value="${ticket.createdAt.toString().replace('T',' ').substring(0,16)}"/></span>
                        <span>· Initial Report</span>
                    </div>
                    <%-- Description text --%>
                    <c:out value="${empty ticket.description ? 'No detailed description provided.' : ticket.description}"/>
                    <%-- Ticket image — appears directly below description text inside the bubble --%>
                    <c:if test="${not empty ticket.imageLink}">
                        <div class="op-attachment">
                            <img src="${pageContext.request.contextPath}/${ticket.imageLink}"
                                 alt="Ticket attachment"
                                 onclick="openLightbox(this.src)"
                                 title="Click to enlarge">
                        </div>
                    </c:if>
                </div>
                <div class="msg-meta-line" style="justify-content:flex-start;margin-top:4px;">
                    <span class="msg-role-chip" style="background:#1e3a5f;color:#93c5fd;">USER</span>
                    <span><c:out value="${ticket.creatorName}"/></span>
                    <span>·</span>
                    <span><c:out value="${ticket.createdAt.toString().replace('T',' ').substring(0,16)}"/></span>
                </div>
            </div>

            <%-- ── Reply messages ─────────────────────────── --%>
            <c:forEach var="msg" items="${messages}">
                <%--
                    From the USER's perspective:
                    - Their own messages (senderId matches session user) → "mine"  (right, blue)
                    - Admin replies                                       → "theirs" (left, dark)
                --%>
                <c:set var="isMine" value="${msg.senderId == SESSION_USER.id}"/>
                <div class="bubble-wrap ${isMine ? 'bubble-wrap--mine' : 'bubble-wrap--theirs'}">
                    <div class="msg-bubble ${isMine ? 'msg-bubble--mine' : 'msg-bubble--theirs'}">
                        <c:out value="${msg.message}"/>
                        <c:if test="${not empty msg.imageLink}">
                            <div class="msg-attachment">
                                <img src="${pageContext.request.contextPath}/${msg.imageLink}"
                                     alt="Attachment"
                                     onclick="openLightbox(this.src)"
                                     title="Click to enlarge">
                            </div>
                        </c:if>
                    </div>
                    <div class="msg-meta-line">
                        <span class="msg-role-chip"><c:out value="${msg.senderRole}"/></span>
                        <span><c:out value="${msg.senderName}"/></span>
                        <span>·</span>
                        <span><c:out value="${msg.sentAt.toString().replace('T',' ').substring(0,16)}"/></span>
                    </div>
                </div>
            </c:forEach>

            <%-- Empty state — only shown when there are no replies yet (OP bubble always shows above) --%>
            <c:if test="${empty messages}">
                <div class="thread-empty">
                    <i class="ti ti-message-off"></i>
                    <span>No replies yet. Send a message below.</span>
                </div>
            </c:if>

        </div><%-- /thread-body --%>

        <%-- Compose area --%>
        <div class="thread-footer">
            <div class="thread-toolbar">
                <button type="button" class="btn-toolbar" onclick="document.getElementById('msgImageInput').click()">
                    <i class="ti ti-photo"></i> Add Image
                </button>
                <%--
                    View Images count: includes the ticket's own attachment (if any)
                    plus any images attached to reply messages.
                --%>
                <c:set var="imgCount" value="${not empty ticket.imageLink ? 1 : 0}"/>
                <c:forEach var="msg" items="${messages}">
                    <c:if test="${not empty msg.imageLink}">
                        <c:set var="imgCount" value="${imgCount + 1}"/>
                    </c:if>
                </c:forEach>
                <c:if test="${imgCount > 0}">
                    <button type="button" class="btn-toolbar" onclick="scrollToFirstImage()">
                        <i class="ti ti-photo-search"></i> View Images (${imgCount})
                    </button>
                </c:if>
            </div>

            <div class="img-preview-wrap" id="imgPreviewWrap" style="margin:6px 16px 0;">
                <img id="imgPreviewThumb" src="" alt="">
                <span class="img-preview-name" id="imgPreviewName"></span>
                <button type="button" class="btn-remove-img" onclick="clearImageInput()">
                    <i class="ti ti-x"></i>
                </button>
            </div>

            <%--
                enctype="multipart/form-data" is REQUIRED.
                The servlet uses @MultipartConfig — without this Tomcat throws HTTP 500
                InvalidContentTypeException (application/x-www-form-urlencoded received).
            --%>
            <form action="${pageContext.request.contextPath}/TicketControllerServlet"
                  method="post"
                  enctype="multipart/form-data"
                  class="msg-form"
                  style="padding:10px 16px 14px;">
                <input type="hidden" name="command"  value="SEND_MESSAGE">
                <input type="hidden" name="ticketId" value="${ticket.id}">
                <%-- name="image" must match FileHandler.saveImagePart(req, "image") --%>
                <input type="file" name="image" id="msgImageInput"
                       accept="image/*" style="display:none"
                       onchange="previewImage(this)">
                <textarea name="message" class="msg-input"
                          placeholder="Type your message…" rows="3" required></textarea>
                <button type="submit" class="btn-send">
                    <i class="ti ti-send"></i> Send
                </button>
            </form>
        </div><%-- /thread-footer --%>
    </div><%-- /thread-card --%>

</main>

<footer class="site-footer">© 2026 I-TICKET System</footer>
<script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/js/bootstrap.bundle.min.js"></script>
<script>
    // ── Auto-scroll to latest message ─────────────────────────────
    const tb = document.getElementById('threadBody');
    if (tb) tb.scrollTop = tb.scrollHeight;

    // ── Image attach preview ──────────────────────────────────────
    function previewImage(input) {
        const wrap  = document.getElementById('imgPreviewWrap');
        const thumb = document.getElementById('imgPreviewThumb');
        const name  = document.getElementById('imgPreviewName');
        if (input.files && input.files[0]) {
            const reader = new FileReader();
            reader.onload = e => { thumb.src = e.target.result; };
            reader.readAsDataURL(input.files[0]);
            name.textContent = input.files[0].name;
            wrap.classList.add('active');
        }
    }

    function clearImageInput() {
        const input = document.getElementById('msgImageInput');
        input.value = '';
        document.getElementById('imgPreviewWrap').classList.remove('active');
        document.getElementById('imgPreviewThumb').src = '';
        document.getElementById('imgPreviewName').textContent = '';
    }

    // ── Lightbox ──────────────────────────────────────────────────
    function openLightbox(src) {
        document.getElementById('lightboxImg').src = src;
        document.getElementById('lightbox').classList.add('active');
    }
    function closeLightbox() {
        document.getElementById('lightbox').classList.remove('active');
    }
    document.addEventListener('keydown', e => { if (e.key === 'Escape') closeLightbox(); });

    // scrollToFirstImage targets both .op-attachment and .msg-attachment images
    function scrollToFirstImage() {
        const first = document.querySelector('.op-attachment img, .msg-attachment img');
        if (first) first.scrollIntoView({ behavior:'smooth', block:'center' });
    }

    // ── Toast flash ───────────────────────────────────────────────
    function showToast(msg, type) {
        const tc = document.getElementById('toastContainer');
        const el = document.createElement('div');
        el.className = 'toast-msg toast-msg--' + (type || 'success');
        el.innerHTML = `<i class="ti ti-${type == 'error' ? 'alert-circle' : 'circle-check'}"></i> ${msg}`;
        tc.appendChild(el);
        setTimeout(() => { el.style.opacity='0'; el.style.transition='opacity .4s'; }, 3200);
        setTimeout(() => el.remove(), 3700);
    }

    <%
        String ts = (String) session.getAttribute("TOAST_SUCCESS");
        String te = (String) session.getAttribute("TOAST_ERROR");
        if (ts != null) { session.removeAttribute("TOAST_SUCCESS"); %>
    window.addEventListener('DOMContentLoaded', () => showToast('<%= ts.replace("'","\\'") %>', 'success'));
    <%  } %>
    <%  if (te != null) { session.removeAttribute("TOAST_ERROR"); %>
    window.addEventListener('DOMContentLoaded', () => showToast('<%= te.replace("'","\\'") %>', 'error'));
    <%  } %>

    // ── Browser push notifications: poll for new admin replies ────
    (function() {
        const TICKET_ID   = '${ticket.id}';
        const POLL_MS     = 18000;
        const STORAGE_KEY = 'lastMsgCount_ticket_' + TICKET_ID;

        if ('Notification' in window && Notification.permission === 'default') {
            Notification.requestPermission();
        }

        function sendNotif(title, body) {
            if (!('Notification' in window) || Notification.permission !== 'granted') return;
            try {
                const n = new Notification(title, {
                    body,
                    icon: '${pageContext.request.contextPath}/favicon.ico',
                    tag: 'ticket-reply-' + TICKET_ID,
                    renotify: true
                });
                n.onclick = () => { window.focus(); n.close(); };
            } catch(e) {}
        }

        const threadBody = document.getElementById('threadBody');
        let knownCount = parseInt(sessionStorage.getItem(STORAGE_KEY) || '0', 10);
        const currentCount = threadBody ? threadBody.querySelectorAll('.bubble-wrap').length : 0;
        if (currentCount > knownCount) {
            knownCount = currentCount;
            sessionStorage.setItem(STORAGE_KEY, String(knownCount));
        }

        let pollTimer;
        function startPolling() {
            pollTimer = setInterval(async () => {
                if (document.hidden) return;
                try {
                    const resp = await fetch(
                        '${pageContext.request.contextPath}/TicketControllerServlet'
                        + '?command=POLL_MESSAGES&ticketId=' + TICKET_ID + '&t=' + Date.now(),
                        { credentials: 'same-origin' }
                    );
                    if (!resp.ok) return;
                    const data = await resp.json();
                    if (data.count > knownCount) {
                        const diff = data.count - knownCount;
                        knownCount = data.count;
                        sessionStorage.setItem(STORAGE_KEY, String(knownCount));
                        sendNotif('HelpDesk — New Reply',
                            diff + ' new message' + (diff > 1 ? 's' : '') + ' on your ticket.');
                        showToast('IT Support replied — reload the page to see it.', 'success');
                    }
                } catch(e) {}
            }, POLL_MS);
        }

        document.addEventListener('visibilitychange', () => {
            if (document.hidden) { clearInterval(pollTimer); }
            else { startPolling(); }
        });
        startPolling();
    })();
</script>
</body>
</html>
