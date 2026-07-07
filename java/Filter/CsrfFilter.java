package Filter;

import jakarta.servlet.*;
import jakarta.servlet.annotation.WebFilter;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.servlet.http.HttpSession;

import java.io.IOException;
import java.security.SecureRandom;
import java.util.Base64;

/**
 * Mitigates Cross-Site Request Forgery (OWASP A01:2021 – Broken Access Control).
 *
 * Every session is issued a random, unguessable token the moment it's created.
 * Any request that can change state (POST / PUT / PATCH / DELETE) must echo
 * that token back as a request parameter named "csrfToken", or the request
 * is rejected with 403 before it ever reaches a servlet.
 *
 * GET requests are left alone — they must never mutate state in the first
 * place — and the token itself is exposed to every JSP via session scope,
 * so pages just do:
 *
 *   <input type="hidden" name="csrfToken" value="${sessionScope.CSRF_TOKEN}">
 *
 * No servlet or JSP code has to generate or manage the token; this filter
 * owns that entirely.
 */
@WebFilter("/*")
public class CsrfFilter implements Filter {

    public static final String SESSION_KEY = "CSRF_TOKEN";
    private static final SecureRandom RNG = new SecureRandom();

    @Override
    public void doFilter(ServletRequest sReq, ServletResponse sRes, FilterChain chain)
            throws IOException, ServletException {

        HttpServletRequest  req = (HttpServletRequest) sReq;
        HttpServletResponse res = (HttpServletResponse) sRes;

        // Every visitor (even pre-login, on the login/register pages) gets a token.
        HttpSession session = req.getSession(true);
        String token = (String) session.getAttribute(SESSION_KEY);
        if (token == null) {
            token = generateToken();
            session.setAttribute(SESSION_KEY, token);
        }

        String method = req.getMethod();
        boolean mutating = "POST".equalsIgnoreCase(method)  || "PUT".equalsIgnoreCase(method)
                         || "PATCH".equalsIgnoreCase(method) || "DELETE".equalsIgnoreCase(method);

        if (mutating) {
            String submitted = req.getParameter("csrfToken");
            if (submitted == null || !constantTimeEquals(submitted, token)) {
                res.setStatus(HttpServletResponse.SC_FORBIDDEN);
                res.setContentType("text/plain;charset=UTF-8");
                res.getWriter().write("Request blocked: missing or invalid CSRF token.");
                return;
            }
        }

        chain.doFilter(req, res);
    }

    private static String generateToken() {
        byte[] bytes = new byte[32];
        RNG.nextBytes(bytes);
        return Base64.getUrlEncoder().withoutPadding().encodeToString(bytes);
    }

    // Avoids leaking timing information about how much of the token matched.
    private static boolean constantTimeEquals(String a, String b) {
        if (a.length() != b.length()) return false;
        int result = 0;
        for (int i = 0; i < a.length(); i++) result |= a.charAt(i) ^ b.charAt(i);
        return result == 0;
    }
}
