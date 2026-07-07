package Controller;

import DAO.UserDAO;
import Model.User;
import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.*;
import java.io.IOException;
import java.sql.SQLException;
import java.util.List;

@WebServlet("/ProfileControllerServlet")
public class ProfileControllerServlet extends HttpServlet {

    private final UserDAO userDAO = new UserDAO();

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse res)
            throws ServletException, IOException {

        User user = sessionUser(req);
        if (user == null) { res.sendRedirect(req.getContextPath() + "/login.jsp"); return; }

        try {
            // Reload from DB so we always show the freshest data
            User fresh = userDAO.findById(user.getId());
            fresh.setPassword(null);
            req.setAttribute("profileUser", fresh);

            if ("ADMIN".equals(user.getRole())) {
                // Admin profile also gets the full user list
                List<User> allUsers = userDAO.getAllUsers();
                req.setAttribute("allUsers", allUsers);
                req.getRequestDispatcher("/admin-profile.jsp").forward(req, res);
            } else {
                // Regular user: show admin contact info
                // Find first ADMIN in the system to display contact block
                List<User> all = userDAO.getAllUsers();
                User adminContact = all.stream()
                        .filter(u -> "ADMIN".equals(u.getRole()))
                        .findFirst().orElse(null);
                req.setAttribute("adminContact", adminContact);
                req.getRequestDispatcher("/profile.jsp").forward(req, res);
            }
        } catch (SQLException e) {
            e.printStackTrace();
            res.sendRedirect(req.getContextPath() +
                    ("ADMIN".equals(user.getRole()) ? "/admin-dashboard.jsp" : "/dashboard.jsp"));
        }
    }

    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse res)
            throws ServletException, IOException {

        User user = sessionUser(req);
        if (user == null) { res.sendRedirect(req.getContextPath() + "/login.jsp"); return; }

        // ── Delete user (admin only) ───────────────────────────
        String actionParam = req.getParameter("action");
        if ("DELETE_USER".equals(actionParam)) {
            if (!"ADMIN".equals(user.getRole())) {
                res.sendRedirect(req.getContextPath() + "/login.jsp");
                return;
            }
            String targetIdStr = req.getParameter("targetUserId");
            try {
                int targetId = Integer.parseInt(targetIdStr);
                if (targetId == user.getId()) {
                    req.getSession().setAttribute("PROFILE_ERROR", "You cannot delete your own account.");
                } else {
                    User target = userDAO.findById(targetId);
                    String targetName = target != null ? target.getFullName() : "User";
                    boolean deleted = userDAO.deleteUser(targetId);
                    if (deleted) {
                        req.getSession().setAttribute("PROFILE_SUCCESS",
                                "Account for " + targetName + " has been permanently deleted.");
                    } else {
                        req.getSession().setAttribute("PROFILE_ERROR", "User not found or already deleted.");
                    }
                }
            } catch (NumberFormatException | SQLException e) {
                e.printStackTrace();
                req.getSession().setAttribute("PROFILE_ERROR", "A system error occurred while deleting the user.");
            }
            res.sendRedirect(req.getContextPath() + "/ProfileControllerServlet");
            return;
        }

        String firstName  = req.getParameter("firstName");
        String lastName   = req.getParameter("lastName");
        String email      = req.getParameter("email");
        String officeLine = req.getParameter("officeLine");

        if (firstName == null || firstName.trim().isEmpty() ||
                lastName  == null || lastName.trim().isEmpty()  ||
                email     == null || email.trim().isEmpty()) {
            req.getSession().setAttribute("PROFILE_ERROR", "First name, last name and email are required.");
            res.sendRedirect(req.getContextPath() + "/ProfileControllerServlet");
            return;
        }

        try {
            boolean ok = userDAO.updateProfile(user.getId(), firstName, lastName, email, officeLine);
            if (!ok) {
                req.getSession().setAttribute("PROFILE_ERROR", "That email address is already in use by another account.");
            } else {
                // Refresh the session user object so the topbar name updates immediately
                User refreshed = userDAO.findById(user.getId());
                refreshed.setPassword(null);
                req.getSession().setAttribute("SESSION_USER", refreshed);
                req.getSession().setAttribute("PROFILE_SUCCESS", "Your profile has been updated.");
            }
        } catch (SQLException e) {
            e.printStackTrace();
            req.getSession().setAttribute("PROFILE_ERROR", "A system error occurred. Please try again.");
        }

        res.sendRedirect(req.getContextPath() + "/ProfileControllerServlet");
    }

    private User sessionUser(HttpServletRequest req) {
        HttpSession s = req.getSession(false);
        return s == null ? null : (User) s.getAttribute("SESSION_USER");
    }
}