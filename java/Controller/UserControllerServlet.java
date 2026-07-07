package Controller;

import Model.User;
import DAO.UserDAO;
import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.*;
import java.io.IOException;
import java.util.regex.Pattern;

@WebServlet("/UserControllerServlet")
public class UserControllerServlet extends HttpServlet {

    private final UserDAO userDAO = new UserDAO();

    // Regex for: Min 8 chars, at least 1 number, and at least 1 special character
    private static final Pattern PASSWORD_PATTERN =
            Pattern.compile("^(?=.*[0-9])(?=.*[!@#$%^&*()_+\\-=\\[\\]{};':\",.<>/?\\\\|]).{8,}$");

    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse res)
            throws ServletException, IOException {

        String command = req.getParameter("command");
        if (command == null) command = "";

        switch (command) {
            case "LOGIN"          -> handleLogin(req, res);
            case "REGISTER"       -> handleRegister(req, res);
            case "REGISTER_ADMIN" -> handleRegisterAdmin(req, res);
            default               -> res.sendRedirect(req.getContextPath() + "/login.jsp");
        }
    }

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse res)
            throws IOException {

        String command = req.getParameter("command");
        if ("LOGOUT".equals(command)) {
            HttpSession session = req.getSession(false);
            if (session != null) {
                session.invalidate();
            }
        }
        res.sendRedirect(req.getContextPath() + "/login.jsp");
    }

    // ── Login ─────────────────────────────────────────────────
    private void handleLogin(HttpServletRequest req, HttpServletResponse res)
            throws ServletException, IOException {

        String username = req.getParameter("username");
        String password = req.getParameter("password");

        if (username == null || username.trim().isEmpty() ||
                password == null || password.trim().isEmpty()) {
            req.setAttribute("LOGIN_ERROR", "Username and password are required.");
            req.getRequestDispatcher("/login.jsp").forward(req, res);
            return;
        }

        try {
            System.out.println("[LOGIN DEBUG] Attempting login for: " + username.trim());

            User user = userDAO.authenticate(username.trim(), password);

            if (user == null) {
                req.setAttribute("LOGIN_ERROR", "Invalid username or password.");
                req.getRequestDispatcher("/login.jsp").forward(req, res);
                return;
            }

            // ── Successful login — store user in session ───────
            HttpSession session = req.getSession(true);
            session.setAttribute("SESSION_USER", user);

            System.out.println("[LOGIN DEBUG] SUCCESS for user: " + username.trim()
                    + " (ID: " + user.getId() + ", ROLE: " + user.getRole() + ")");

            // ── Route by role ──────────────────────────────────
            if ("ADMIN".equals(user.getRole())) {
                res.sendRedirect(req.getContextPath() + "/admin-dashboard.jsp");
            } else {
                res.sendRedirect(req.getContextPath() + "/dashboard.jsp");
            }

        } catch (Exception e) {
            e.printStackTrace();
            System.err.println("[LOGIN CRITICAL ERROR] Username: " + username
                    + " | Error: " + e.getClass().getSimpleName());

            req.setAttribute("LOGIN_ERROR", "A system error occurred. Please try again.");
            req.getRequestDispatcher("/login.jsp").forward(req, res);
        }
    }

    // ── Register ──────────────────────────────────────────────
    private void handleRegister(HttpServletRequest req, HttpServletResponse res)
            throws ServletException, IOException {

        String firstName      = req.getParameter("firstName");
        String lastName       = req.getParameter("lastName");
        String username       = req.getParameter("username");
        String email          = req.getParameter("email");
        String password       = req.getParameter("password");
        String confirmPassword= req.getParameter("confirmPassword");

        // 1. Password match check
        if (password == null || !password.equals(confirmPassword)) {
            req.setAttribute("REGISTER_ERROR", "Passwords do not match.");
            req.getRequestDispatcher("/register.jsp").forward(req, res);
            return;
        }

        // 2. Complexity check: min 8 chars, 1 number, 1 special character
        if (!PASSWORD_PATTERN.matcher(password).matches()) {
            req.setAttribute("REGISTER_ERROR",
                    "Password must be at least 8 characters long, contain at least 1 number, and 1 special character.");
            req.getRequestDispatcher("/register.jsp").forward(req, res);
            return;
        }

        User u = new User();
        u.setFirstName(firstName);
        u.setLastName(lastName);
        u.setUsername(username);
        u.setEmail(email);
        u.setPassword(password);

        try {
            boolean ok = userDAO.register(u);
            if (!ok) {
                req.setAttribute("REGISTER_ERROR", "Username or email already in use.");
                req.getRequestDispatcher("/register.jsp").forward(req, res);
                return;
            }

            req.setAttribute("REGISTER_SUCCESS", "Account created! You can now sign in.");
            req.getRequestDispatcher("/login.jsp").forward(req, res);

        } catch (Exception e) {
            e.printStackTrace();
            req.setAttribute("REGISTER_ERROR", "A system error occurred. Please try again.");
            req.getRequestDispatcher("/register.jsp").forward(req, res);
        }
    }

    // ── Register another admin (admin-only) ────────────────────
    private void handleRegisterAdmin(HttpServletRequest req, HttpServletResponse res)
            throws IOException {

        HttpSession session = req.getSession(false);
        User currentUser = session == null ? null : (User) session.getAttribute("SESSION_USER");

        // Only a logged-in admin may create another admin account.
        if (currentUser == null || !"ADMIN".equals(currentUser.getRole())) {
            res.sendRedirect(req.getContextPath() + "/login.jsp");
            return;
        }

        String firstName       = req.getParameter("firstName");
        String lastName        = req.getParameter("lastName");
        String username        = req.getParameter("username");
        String email           = req.getParameter("email");
        String password        = req.getParameter("password");
        String confirmPassword = req.getParameter("confirmPassword");

        if (firstName == null || firstName.trim().isEmpty() ||
                lastName  == null || lastName.trim().isEmpty()  ||
                username  == null || username.trim().isEmpty()  ||
                email     == null || email.trim().isEmpty()     ||
                password  == null || password.isEmpty()) {
            session.setAttribute("PROFILE_ERROR", "All fields are required to register a new admin.");
            res.sendRedirect(req.getContextPath() + "/admin-profile.jsp");
            return;
        }

        if (!password.equals(confirmPassword)) {
            session.setAttribute("PROFILE_ERROR", "Passwords do not match.");
            res.sendRedirect(req.getContextPath() + "/admin-profile.jsp");
            return;
        }

        if (!PASSWORD_PATTERN.matcher(password).matches()) {
            session.setAttribute("PROFILE_ERROR",
                    "Password must be at least 8 characters long, contain at least 1 number, and 1 special character.");
            res.sendRedirect(req.getContextPath() + "/admin-profile.jsp");
            return;
        }

        User u = new User();
        u.setFirstName(firstName.trim());
        u.setLastName(lastName.trim());
        u.setUsername(username.trim());
        u.setEmail(email.trim());
        u.setPassword(password);

        try {
            boolean ok = userDAO.register(u, "ADMIN");
            if (!ok) {
                session.setAttribute("PROFILE_ERROR", "Username or email already in use.");
            } else {
                session.setAttribute("PROFILE_SUCCESS",
                        "New admin account for " + firstName.trim() + " " + lastName.trim() + " has been created.");
            }
        } catch (Exception e) {
            e.printStackTrace();
            session.setAttribute("PROFILE_ERROR", "A system error occurred while creating the admin account.");
        }

        res.sendRedirect(req.getContextPath() + "/admin-profile.jsp");
    }
}