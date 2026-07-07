package Filter;

import jakarta.servlet.ServletContextEvent;
import jakarta.servlet.ServletContextListener;
import jakarta.servlet.SessionCookieConfig;
import jakarta.servlet.annotation.WebListener;

/**
 * Hardens the JSESSIONID cookie at startup (OWASP A05 / A07).
 */
@WebListener
public class AppContextListener implements ServletContextListener {


    private static final boolean FORCE_SECURE_COOKIE = true;

    @Override
    public void contextInitialized(ServletContextEvent sce) {
        SessionCookieConfig cfg = sce.getServletContext().getSessionCookieConfig();
        cfg.setHttpOnly(true);                 // JS can never read the session cookie
        cfg.setSecure(FORCE_SECURE_COOKIE);     // cookie only sent over HTTPS in prod
    }

    @Override
    public void contextDestroyed(ServletContextEvent sce) { /* no-op */ }
}
