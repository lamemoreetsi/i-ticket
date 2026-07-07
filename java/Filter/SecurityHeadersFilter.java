package Filter;

import jakarta.servlet.*;
import jakarta.servlet.annotation.WebFilter;
import jakarta.servlet.http.HttpServletResponse;

import java.io.IOException;

/**
 * Adds standard defensive response headers to every request.
 * Addresses OWASP A05:2021 – Security Misconfiguration.
 */
@WebFilter("/*")
public class SecurityHeadersFilter implements Filter {

    @Override
    public void doFilter(ServletRequest req, ServletResponse res, FilterChain chain)
            throws IOException, ServletException {

        HttpServletResponse httpRes = (HttpServletResponse) res;

        // Stop the browser guessing content types (protects against MIME sniffing XSS)
        httpRes.setHeader("X-Content-Type-Options", "nosniff");
        // Stop the site being framed by another origin (clickjacking)
        httpRes.setHeader("X-Frame-Options", "DENY");
        // Legacy header — modern browsers use CSP instead, explicitly disable the old,
        // sometimes-exploitable auto "XSS filter" rather than leaving it on default.
        httpRes.setHeader("X-XSS-Protection", "0");
        httpRes.setHeader("Referrer-Policy", "same-origin");
        // Only allow scripts/styles/fonts from this origin and the CDN the app already
        // depends on (Bootstrap + Tabler icons). Adjust the list if you add new CDNs.
        httpRes.setHeader("Content-Security-Policy",
                "default-src 'self'; " +
                "script-src 'self' https://cdn.jsdelivr.net 'unsafe-inline'; " +
                "style-src 'self' https://cdn.jsdelivr.net 'unsafe-inline'; " +
                "font-src 'self' https://cdn.jsdelivr.net; " +
                "img-src 'self' data: blob:;");

        chain.doFilter(req, res);
    }
}
