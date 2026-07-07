package Controller;

import DAO.TicketDAO;
import Model.Ticket;
import Model.TicketMessage;
import Model.User;
import Util.FileHandler; // --- IMPORT THE NEW UTIL ---
import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.MultipartConfig; // --- IMPORT THIS ---
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.*;
import java.io.IOException;
import java.sql.SQLException;
import java.util.List;

@WebServlet("/TicketControllerServlet")
// --- ADD THIS ANNOTATION TO ENABLE FILE UPLOAD HANDLING ---
@MultipartConfig(
        fileSizeThreshold = 1024 * 1024 * 1, // 1 MB buffer before saving to disk
        maxFileSize = 1024 * 1024 * 10,      // 10 MB Max individual file size
        maxRequestSize = 1024 * 1024 * 15     // 15 MB Max request size (total)
)
public class TicketControllerServlet extends HttpServlet {

    private final TicketDAO ticketDAO = new TicketDAO();

    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse res)
            throws ServletException, IOException {

        User user = sessionUser(req);
        if (user == null) { res.sendRedirect(req.getContextPath() + "/login.jsp"); return; }

        String command = req.getParameter("command");

        // --- MULTIPART CHECK ---
        // If the form is multipart, req.getParameter("command") will return NULL.
        // We must check standard req first, then try multipart parsing.
        if (command == null) {
            command = FileHandler.getPartValue(req, "command");
        }

        if (command == null) command = "";

        switch (command) {
            case "CREATE_TICKET"      -> handleCreate(req, res, user);
            case "DELETE_TICKET"      -> handleDelete(req, res, user);
            // Updated cases to ensure correct function linking
            case "SEND_MESSAGE"       -> handleSendMessage(req, res, user, false);
            case "ADMIN_SEND_MESSAGE" -> handleSendMessage(req, res, user, true);
            // Choice A: Handling User Edit Submission
            case "UPDATE_TICKET"      -> handleUpdateTicket(req, res, user);
            // CHOICE B: Admin update (status/priority)
            case "UPDATE_STATUS"      -> handleUpdateStatus(req, res, user);
            default -> res.sendRedirect(req.getContextPath() + "/dashboard.jsp");
        }
    }

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse res)
            throws ServletException, IOException {

        User user = sessionUser(req);
        if (user == null) { res.sendRedirect(req.getContextPath() + "/login.jsp"); return; }

        String command = req.getParameter("command");
        if (command == null) command = "";

        switch (command) {
            case "VIEW_TICKET"       -> handleViewTicket(req, res, user, false);
            case "ADMIN_VIEW_TICKET" -> handleViewTicket(req, res, user, true);
            case "POLL_MESSAGES"     -> handlePollMessages(req, res, user);
            default -> res.sendRedirect(req.getContextPath() + "/dashboard.jsp");
        }
    }

    private User sessionUser(HttpServletRequest req) {
        HttpSession s = req.getSession(false);
        return s == null ? null : (User) s.getAttribute("SESSION_USER");
    }

    // multipart request needs special parsing, so we override parseId
    private int parseId(HttpServletRequest req, String param) {
        String val = req.getParameter(param);
        if (val == null) {
            try {
                // Try parsing via multipart util if standard fails
                val = FileHandler.getPartValue(req, param);
            } catch (Exception e) { return -1; }
        }
        try { return Integer.parseInt(val); }
        catch (NumberFormatException e) { return -1; }
    }

    // --- UPDATED HANDLE CREATE (Multipart aware) ---
    private void handleCreate(HttpServletRequest req, HttpServletResponse res, User user)
            throws IOException, ServletException {

        // Use FileHandler utility to extract text fields from multipart request
        String summary     = FileHandler.getPartValue(req, "summary");
        String description = FileHandler.getPartValue(req, "description");
        String priority    = FileHandler.getPartValue(req, "priority");
        String category    = FileHandler.getPartValue(req, "category");

        if (summary == null || summary.trim().isEmpty()) {
            req.getSession().setAttribute("TOAST_ERROR", "Summary field cannot be left blank.");
            res.sendRedirect(req.getContextPath() + "/dashboard.jsp");
            return;
        }

        // Process file upload part
        String savedImagePath = FileHandler.saveImagePart(req, "image");

        Ticket t = new Ticket();
        t.setSummary(summary.trim());
        // --- NEW FIELD SETTERS ---
        t.setDescription(description != null ? description.trim() : null);
        t.setImageLink(savedImagePath); // Save URL path from utility
        // --- OLD SETTERS ---
        t.setPriority(priority != null && !priority.isEmpty() ? priority : "Medium");
        t.setCategory(category != null && !category.isEmpty() ? category : "Other");
        t.setCreatorId(user.getId());

        try {
            ticketDAO.createTicket(t);
            req.getSession().setAttribute("TOAST_SUCCESS", "Your ticket has been logged successfully.");
        } catch (SQLException e) {
            e.printStackTrace();
            req.getSession().setAttribute("TOAST_ERROR", "Database tracking allocation failure.");
        }

        res.sendRedirect(req.getContextPath() + "/dashboard.jsp");
    }

    // CHOICE A: Handling the User Edit form Submission (Multipart aware)
    private void handleUpdateTicket(HttpServletRequest req, HttpServletResponse res, User user)
            throws IOException, ServletException {

        int ticketId       = parseId(req, "ticketId");
        String summary     = FileHandler.getPartValue(req, "summary");
        String description = FileHandler.getPartValue(req, "description");
        String priority    = FileHandler.getPartValue(req, "priority");
        String category    = FileHandler.getPartValue(req, "category");

        if (ticketId < 0 || summary == null || summary.trim().isEmpty()) {
            res.sendRedirect(req.getContextPath() + "/dashboard.jsp");
            return;
        }

        // Handle standard Tabler icons image replacement trigger
        String savedImagePath = FileHandler.saveImagePart(req, "image");
        String removeImageFlag = FileHandler.getPartValue(req, "removeImage");

        try {
            Ticket t = ticketDAO.getTicketById(ticketId);
            // Security: Verify creator owns the ticket
            if (t == null || t.getCreatorId() != user.getId()) {
                res.sendRedirect(req.getContextPath() + "/dashboard.jsp");
                return;
            }

            // Update configuration settings
            t.setSummary(summary.trim());
            t.setDescription(description != null ? description.trim() : null);
            t.setPriority(priority);
            t.setCategory(category);

            // Image Logic: 1. Remove requested? 2. New upload?
            if ("true".equals(removeImageFlag)) {
                t.setImageLink(null);
            } else if (savedImagePath != null) {
                t.setImageLink(savedImagePath);
            }

            ticketDAO.updateTicket(t);
            req.getSession().setAttribute("TOAST_SUCCESS", "Ticket parameters successfully updated.");
        } catch (SQLException e) {
            e.printStackTrace();
            req.getSession().setAttribute("TOAST_ERROR", "Tracking modification failure.");
        }
        res.sendRedirect(req.getContextPath() + "/dashboard.jsp");
    }

    private void handleViewTicket(HttpServletRequest req, HttpServletResponse res, User user, boolean isAdmin)
            throws ServletException, IOException {

        int ticketId = parseId(req, "ticketId");
        String fallback = isAdmin ? "/admin-dashboard.jsp" : "/dashboard.jsp";

        if (ticketId < 0) { res.sendRedirect(req.getContextPath() + fallback); return; }

        try {
            Ticket ticket = ticketDAO.getTicketById(ticketId);

            if (ticket == null || (!isAdmin && ticket.getCreatorId() != user.getId())) {
                res.sendRedirect(req.getContextPath() + fallback);
                return;
            }

            List<TicketMessage> messages = ticketDAO.getMessages(ticketId);
            req.setAttribute("ticket",   ticket);
            req.setAttribute("messages", messages);

            String view = isAdmin ? "/admin-view-ticket.jsp" : "/viewTicket.jsp";
            req.getRequestDispatcher(view).forward(req, res);

        } catch (SQLException e) {
            e.printStackTrace();
            res.sendRedirect(req.getContextPath() + fallback);
        }
    }

    // ── Poll message count (lightweight JSON endpoint for push notifs) ──
    private void handlePollMessages(HttpServletRequest req, HttpServletResponse res, User user)
            throws IOException {
        int ticketId = parseId(req, "ticketId");
        res.setContentType("application/json");
        res.setCharacterEncoding("UTF-8");
        // No-cache so the browser always hits the server
        res.setHeader("Cache-Control", "no-store");
        if (ticketId < 0) { res.getWriter().write("{\"count\":0}"); return; }
        try {
            Ticket ticket = ticketDAO.getTicketById(ticketId);
            boolean isAdmin = "ADMIN".equals(user.getRole());
            if (ticket == null || (!isAdmin && ticket.getCreatorId() != user.getId())) {
                res.getWriter().write("{\"count\":0}");
                return;
            }
            List<TicketMessage> msgs = ticketDAO.getMessages(ticketId);
            res.getWriter().write("{\"count\":" + msgs.size() + "}");
        } catch (SQLException e) {
            e.printStackTrace();
            res.getWriter().write("{\"count\":0}");
        }
    }

    private void handleDelete(HttpServletRequest req, HttpServletResponse res, User user)
            throws IOException {

        int      ticketId   = parseId(req, "ticketId");
        boolean  isAdmin    = "ADMIN".equals(user.getRole());
        String   redirectTo = req.getParameter("redirectTo");

        if (ticketId < 0) {
            res.sendRedirect(req.getContextPath() + "/dashboard.jsp");
            return;
        }

        try {
            Ticket ticket = ticketDAO.getTicketById(ticketId);
            if (ticket != null && (isAdmin || ticket.getCreatorId() == user.getId())) {
                ticketDAO.deleteTicket(ticketId);
                req.getSession().setAttribute("TOAST_SUCCESS", "Ticket successfully deleted.");
            } else {
                req.getSession().setAttribute("TOAST_ERROR", "Unauthorized delete action request.");
            }
        } catch (SQLException e) {
            e.printStackTrace();
            req.getSession().setAttribute("TOAST_ERROR", "Purge request processing failure.");
        }

        if ("admin".equals(redirectTo) || isAdmin) {
            res.sendRedirect(req.getContextPath() + "/admin-dashboard.jsp");
        } else {
            res.sendRedirect(req.getContextPath() + "/dashboard.jsp");
        }
    }

    // --- UPDATED HANDLE SEND MESSAGE (Multipart aware for standard tabler icon attachment trigger) ---
    private void handleSendMessage(HttpServletRequest req, HttpServletResponse res, User user, boolean isAdmin)
            throws IOException, ServletException {

        int    ticketId = parseId(req, "ticketId");
        // Extract text message part
        String message  = FileHandler.getPartValue(req, "message");
        String fallback = isAdmin ? "/admin-dashboard.jsp" : "/dashboard.jsp";

        if (ticketId < 0 || message == null || message.trim().isEmpty()) {
            res.sendRedirect(req.getContextPath() + fallback);
            return;
        }

        // Process standard image attachment via utility
        String savedImagePath = FileHandler.saveImagePart(req, "image");

        try {
            Ticket ticket = ticketDAO.getTicketById(ticketId);
            if (ticket == null || (!isAdmin && ticket.getCreatorId() != user.getId())) {
                res.sendRedirect(req.getContextPath() + fallback);
                return;
            }
            // Pass the image link to DAO
            ticketDAO.addMessage(ticketId, user.getId(), message.trim(), savedImagePath);
        } catch (SQLException e) {
            e.printStackTrace();
        }

        // CHOICE B Redirect Handling logic
        if (isAdmin) {
            res.sendRedirect(req.getContextPath() + "/TicketControllerServlet?command=ADMIN_VIEW_TICKET&ticketId=" + ticketId);
        } else {
            res.sendRedirect(req.getContextPath() + "/TicketControllerServlet?command=VIEW_TICKET&ticketId=" + ticketId);
        }
    }

    private void handleUpdateStatus(HttpServletRequest req, HttpServletResponse res, User user)
            throws IOException, ServletException {

        if (!"ADMIN".equals(user.getRole())) {
            res.sendRedirect(req.getContextPath() + "/dashboard.jsp");
            return;
        }

        int    ticketId = parseId(req, "ticketId");
        String status   = req.getParameter("status");
        String priority = req.getParameter("priority");

        if (ticketId < 0) { res.sendRedirect(req.getContextPath() + "/admin-dashboard.jsp"); return; }

        try {
            Ticket ticket = ticketDAO.getTicketById(ticketId);
            if (ticket != null) {
                if (status   != null && !status.isEmpty())   ticket.setStatus(status);
                if (priority != null && !priority.isEmpty()) ticket.setPriority(priority);
                ticketDAO.updateTicket(ticket);
                req.getSession().setAttribute("TOAST_SUCCESS", "Ticket metrics saved.");
            }
        } catch (SQLException e) {
            e.printStackTrace();
            req.getSession().setAttribute("TOAST_ERROR", "System updates failed.");
        }
        res.sendRedirect(req.getContextPath() + "/TicketControllerServlet?command=ADMIN_VIEW_TICKET&ticketId=" + ticketId);
    }
}