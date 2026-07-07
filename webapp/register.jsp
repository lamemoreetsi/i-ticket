<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ taglib uri="http://java.sun.com/jsp/jstl/core" prefix="c" %>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Register — HelpDesk IT Portal</title>
    <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/css/bootstrap.min.css">
    <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/@tabler/icons-webfont@3.0.0/tabler-icons.min.css">
    <link rel="stylesheet" href="${pageContext.request.contextPath}/css/signin.css">
</head>
<body>

<main>
    <div class="auth-card auth-card--wide">

        <!-- Brand -->
        <div class="brand brand--reg">
            <div class="brand-icon">
                <i class="ti ti-ticket"></i>
            </div>
            <div>
                <div class="brand-name">HelpDesk</div>
                <div class="brand-sub">IT Support Portal</div>
            </div>
        </div>

        <h1 class="page-title">Create your account</h1>
        <p class="page-sub page-sub--reg">Join the IT support portal as a user</p>

        <!-- Fixed role indicator -->
        <div class="role-badge">
            <i class="ti ti-shield-check" style="font-size:14px;" aria-hidden="true"></i>
            User account
        </div>

        <!-- Error / success feedback -->
        <c:if test="${not empty REGISTER_ERROR}">
            <div class="alert-box alert-box--error">
                <i class="ti ti-alert-circle" style="flex-shrink:0; font-size:16px;"></i>
                <span>${REGISTER_ERROR}</span>
            </div>
        </c:if>
        <c:if test="${not empty REGISTER_SUCCESS}">
            <div class="alert-box alert-box--success">
                <i class="ti ti-circle-check" style="flex-shrink:0; font-size:16px;"></i>
                <span>${REGISTER_SUCCESS}</span>
            </div>
        </c:if>

        <form action="UserControllerServlet" method="post" novalidate>
            <input type="hidden" name="command" value="REGISTER">
            <input type="hidden" name="csrfToken" value="${sessionScope.CSRF_TOKEN}">

            <!-- Name row -->
            <div class="row g-2 mb-3">
                <div class="col-6">
                    <label class="form-label-custom" for="firstName">
                        <i class="ti ti-user" aria-hidden="true"></i> First name
                    </label>
                    <div class="input-wrapper">
                        <i class="ti ti-user" aria-hidden="true"></i>
                        <input type="text"
                               id="firstName"
                               name="firstName"
                               class="input-dark"
                               placeholder="First name"
                               autocomplete="given-name"
                               required>
                    </div>
                </div>
                <div class="col-6">
                    <label class="form-label-custom" for="lastName">
                        <i class="ti ti-user" aria-hidden="true"></i> Last name
                    </label>
                    <div class="input-wrapper">
                        <i class="ti ti-user" aria-hidden="true"></i>
                        <input type="text"
                               id="lastName"
                               name="lastName"
                               class="input-dark"
                               placeholder="Last name"
                               autocomplete="family-name"
                               required>
                    </div>
                </div>
            </div>

            <!-- Username -->
            <div class="mb-3">
                <label class="form-label-custom" for="username">
                    <i class="ti ti-at" aria-hidden="true"></i> Username
                </label>
                <div class="input-wrapper">
                    <i class="ti ti-at" aria-hidden="true"></i>
                    <input type="text"
                           id="username"
                           name="username"
                           class="input-dark"
                           placeholder="Choose a username"
                           autocomplete="username"
                           required>
                </div>
            </div>

            <!-- Email -->
            <div class="mb-3">
                <label class="form-label-custom" for="email">
                    <i class="ti ti-mail" aria-hidden="true"></i> Email
                </label>
                <div class="input-wrapper">
                    <i class="ti ti-mail" aria-hidden="true"></i>
                    <input type="email"
                           id="email"
                           name="email"
                           class="input-dark"
                           placeholder="your@email.com"
                           autocomplete="email"
                           required>
                </div>
            </div>

            <!-- Password -->
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
                           placeholder="Create a password"
                           autocomplete="new-password"
                           required>
                </div>
            </div>

            <!-- Confirm password -->
            <div class="mb-3">
                <label class="form-label-custom" for="confirmPassword">
                    <i class="ti ti-lock-check" aria-hidden="true"></i> Confirm password
                </label>
                <div class="input-wrapper">
                    <i class="ti ti-lock-check" aria-hidden="true"></i>
                    <input type="password"
                           id="confirmPassword"
                           name="confirmPassword"
                           class="input-dark"
                           placeholder="Repeat your password"
                           autocomplete="new-password"
                           required>
                </div>
            </div>

            <!-- Submit -->
            <button type="submit" class="btn-portal-primary">
                <i class="ti ti-user-plus" aria-hidden="true"></i> Create account
            </button>
        </form>

        <div class="divider-text"><span>already have an account?</span></div>

        <a href="${pageContext.request.contextPath}/login.jsp" class="btn-portal-ghost">
            <i class="ti ti-login" aria-hidden="true"></i> Sign in instead
        </a>

    </div>
</main>

<footer>© 2026 I-TICKET System</footer>

<script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/js/bootstrap.bundle.min.js"></script>
</body>
</html>