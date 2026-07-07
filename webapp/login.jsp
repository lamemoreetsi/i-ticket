<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ taglib uri="jakarta.tags.core" prefix="c" %>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Sign In — HelpDesk IT Portal</title>
    <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/css/bootstrap.min.css">
    <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/@tabler/icons-webfont@3.0.0/tabler-icons.min.css">
    <link rel="stylesheet" href="${pageContext.request.contextPath}/css/signin.css">
</head>
<body>

<main>
    <div class="auth-card">

        <div class="brand">
            <div class="brand-icon">
                <i class="ti ti-ticket"></i>
            </div>
            <div>
                <div class="brand-name">HelpDesk</div>
                <div class="brand-sub">IT Support Portal</div>
            </div>
        </div>

        <h1 class="page-title">Welcome back</h1>
        <p class="page-sub">Sign in to your account to continue</p>

        <form action="${pageContext.request.contextPath}/UserControllerServlet" method="post" novalidate>
            <input type="hidden" name="command" value="LOGIN">
            <input type="hidden" name="csrfToken" value="${sessionScope.CSRF_TOKEN}">

            <c:if test="${not empty LOGIN_ERROR}">
                <div class="alert-box alert-box--error">
                    <i class="ti ti-alert-circle" style="flex-shrink:0; font-size:16px;"></i>
                    <span><c:out value="${LOGIN_ERROR}"/></span>
                </div>
            </c:if>

            <div class="mb-3">
                <label class="form-label-custom" for="username">
                    <i class="ti ti-user" aria-hidden="true"></i> Username
                </label>
                <div class="input-wrapper">
                    <i class="ti ti-user" aria-hidden="true"></i>
                    <input type="text"
                           id="username"
                           name="username"
                           class="input-dark"
                           placeholder="Enter your username"
                           autocomplete="username"
                           required>
                </div>
            </div>

            <div class="mb-3">
                <label class="form-label-custom" for="password">
                    <i class="ti ti-lock" aria-hidden="true"></i> Password
                </label>
                <div class="input-wrapper">
                    <i class="ti ti-lock" aria-hidden="true"></i>
                    <input type="password"
                           id="password"
                           name="password"
                           class="input-dark"
                           placeholder="Enter your password"
                           autocomplete="current-password"
                           required>
                </div>
            </div>

            <button type="submit" class="btn-portal-primary">
                <i class="ti ti-login" aria-hidden="true"></i> Sign in
            </button>
        </form>

        <div class="divider-text"><span>no account?</span></div>

        <a href="${pageContext.request.contextPath}/register.jsp" class="btn-portal-ghost">
            <i class="ti ti-user-plus" aria-hidden="true"></i> Create account
        </a>

    </div>
</main>

<footer>© 2026 I-TICKET System</footer>

<script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/js/bootstrap.bundle.min.js"></script>
</body>
</html>