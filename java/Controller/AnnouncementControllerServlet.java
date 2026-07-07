package Controller;

import DAO.AnnouncementDAO;
import DAO.TicketDAO;
import Model.Announcement;
import Model.Ticket;
import Model.User;
import com.google.gson.Gson;
import com.google.gson.GsonBuilder;
import com.google.gson.JsonSerializer;
import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.*;
import java.io.IOException;
import java.io.PrintWriter;
import java.sql.SQLException;
import java.time.LocalDateTime;
import java.time.ZoneOffset;
import java.time.format.DateTimeFormatter;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

@WebServlet("/AnnouncementControllerServlet")
public class AnnouncementControllerServlet extends HttpServlet {

    private final AnnouncementDAO announcementDAO = new AnnouncementDAO();
    private final TicketDAO       ticketDAO       = new TicketDAO();
    private static final DateTimeFormatter FMT = DateTimeFormatter.ofPattern("yyyy-MM-dd HH:mm");

    // Gson that serialises LocalDateTime as a formatted string
    private static final Gson GSON = new GsonBuilder()
            .registerTypeAdapter(LocalDateTime.class,
                    (JsonSerializer<LocalDateTime>) (src, type, ctx) ->
                            ctx.serialize(src == null ? null : src.format(FMT)))
            .create();

    // ── POST: add or delete announcement ─────────────────────
    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse res)
            throws ServletException, IOException {

        User user = sessionUser(req);
        if (user == null || !"ADMIN".equals(user.getRole())) {
            res.sendRedirect(req.getContextPath() + "/login.jsp");
            return;
        }

        String command = req.getParameter("command");
        if (command == null) command = "";

        switch (command) {
            case "ADD_ANNOUNCEMENT"    -> handleAdd(req, res, user);
            case "DELETE_ANNOUNCEMENT" -> handleDelete(req, res);
            default -> res.sendRedirect(req.getContextPath() + "/admin-dashboard.jsp");
        }
    }

    // ── GET: JSON polling endpoint used by both dashboards ───
    // ?command=POLL&since=<epochMillis>
    // Returns: { announcements: [...], tickets: [...], ticketCount: N }
    // tickets is only populated for admins (all tickets); for users pass userId
    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse res)
            throws IOException {

        User user = sessionUser(req);
        if (user == null) {
            res.setStatus(HttpServletResponse.SC_UNAUTHORIZED);
            return;
        }

        String command = req.getParameter("command");
        if (!"POLL".equals(command)) {
            res.sendRedirect(req.getContextPath() + "/login.jsp");
            return;
        }

        long since = 0;
        try { since = Long.parseLong(req.getParameter("since")); }
        catch (NumberFormatException ignored) {}

        Map<String, Object> payload = new HashMap<>();

        try {
            // New announcements since last poll
            List<Announcement> newAnnouncements = announcementDAO.getNewerThan(since);
            payload.put("announcements", newAnnouncements);

            // Ticket list — admin sees all, user sees own
            List<Ticket> tickets;
            if ("ADMIN".equals(user.getRole())) {
                tickets = ticketDAO.getAllTickets();
            } else {
                tickets = ticketDAO.getTicketsByUser(user.getId());
            }
            payload.put("tickets", tickets);

        } catch (SQLException e) {
            e.printStackTrace();
            res.setStatus(HttpServletResponse.SC_INTERNAL_SERVER_ERROR);
            return;
        }

        res.setContentType("application/json;charset=UTF-8");
        res.setHeader("Cache-Control", "no-store");
        PrintWriter out = res.getWriter();
        out.print(GSON.toJson(payload));
        out.flush();
    }

    // ── Helpers ───────────────────────────────────────────────

    private User sessionUser(HttpServletRequest req) {
        HttpSession session = req.getSession(false);
        return session == null ? null : (User) session.getAttribute("SESSION_USER");
    }

    private void handleAdd(HttpServletRequest req, HttpServletResponse res, User user)
            throws IOException {

        String title = req.getParameter("title");
        String body  = req.getParameter("body");

        if (title == null || title.trim().isEmpty() ||
                body  == null || body.trim().isEmpty()) {
            res.sendRedirect(req.getContextPath() + "/admin-dashboard.jsp?error=empty");
            return;
        }

        Announcement a = new Announcement();
        a.setTitle(title.trim());
        a.setBody(body.trim());
        a.setAuthorId(user.getId());

        try {
            announcementDAO.create(a);
        } catch (SQLException e) {
            e.printStackTrace();
        }

        res.sendRedirect(req.getContextPath() + "/admin-dashboard.jsp?notice=sent");
    }

    private void handleDelete(HttpServletRequest req, HttpServletResponse res)
            throws IOException {

        int id = -1;
        try { id = Integer.parseInt(req.getParameter("announcementId")); }
        catch (NumberFormatException ignored) {}

        if (id > 0) {
            try { announcementDAO.delete(id); }
            catch (SQLException e) { e.printStackTrace(); }
        }

        res.sendRedirect(req.getContextPath() + "/admin-dashboard.jsp");
    }
}