package DAO;

import Model.User;
import org.mindrot.jbcrypt.BCrypt;
import java.sql.*;
import java.util.ArrayList;
import java.util.List;

public class UserDAO {

    private User map(ResultSet rs) throws SQLException {
        User u = new User();
        u.setId(rs.getInt("id"));
        u.setFirstName(rs.getString("first_name"));
        u.setLastName(rs.getString("last_name"));
        u.setUsername(rs.getString("username"));
        u.setEmail(rs.getString("email"));
        u.setPassword(rs.getString("password"));
        u.setRole(rs.getString("role"));
        u.setOfficeLine(rs.getString("office_line"));
        Timestamp ca = rs.getTimestamp("created_at");
        if (ca != null) u.setCreatedAt(ca.toLocalDateTime());
        return u;
    }

    // ── Authenticate ──────────────────────────────────────────
    public User authenticate(String username, String plainPassword) throws SQLException {
        String sql = "SELECT * FROM users WHERE username = ?";
        try (Connection con = DBConnection.getConnection();
             PreparedStatement ps = con.prepareStatement(sql)) {
            ps.setString(1, username);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) {
                    User u = map(rs);
                    try {
                        if (u.getPassword() != null && BCrypt.checkpw(plainPassword, u.getPassword())) {
                            u.setPassword(null);
                            return u;
                        }
                    } catch (IllegalArgumentException e) {
                        System.err.println("[AUTH WARNING] User '" + username
                                + "' has an invalid password hash format in the database.");
                    }
                }
            }
        }
        return null;
    }

    // ── Register (regular self-service signup — always USER role) ─────
    public boolean register(User u) throws SQLException {
        return register(u, "USER");
    }

    // ── Register with an explicit role (used by the admin "register admin" feature) ──
    public boolean register(User u, String role) throws SQLException {
        String check = "SELECT id FROM users WHERE username=? OR email=?";
        try (Connection con = DBConnection.getConnection();
             PreparedStatement ps = con.prepareStatement(check)) {
            ps.setString(1, u.getUsername());
            ps.setString(2, u.getEmail());
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) return false;
            }
        }
        String hashed = BCrypt.hashpw(u.getPassword(), BCrypt.gensalt(12));
        String sql = "INSERT INTO users (first_name,last_name,username,email,password,role) " +
                     "VALUES (?,?,?,?,?,?)";
        try (Connection con = DBConnection.getConnection();
             PreparedStatement ps = con.prepareStatement(sql)) {
            ps.setString(1, u.getFirstName());
            ps.setString(2, u.getLastName());
            ps.setString(3, u.getUsername());
            ps.setString(4, u.getEmail());
            ps.setString(5, hashed);
            ps.setString(6, role);
            ps.executeUpdate();
        }
        return true;
    }

    // ── Find by ID ────────────────────────────────────────────
    public User findById(int id) throws SQLException {
        String sql = "SELECT * FROM users WHERE id=?";
        try (Connection con = DBConnection.getConnection();
             PreparedStatement ps = con.prepareStatement(sql)) {
            ps.setInt(1, id);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) return map(rs);
            }
        }
        return null;
    }

    // ── Get all users (admin use) ─────────────────────────────
    public List<User> getAllUsers() throws SQLException {
        List<User> list = new ArrayList<>();
        String sql = "SELECT * FROM users ORDER BY role DESC, first_name ASC";
        try (Connection con = DBConnection.getConnection();
             PreparedStatement ps = con.prepareStatement(sql);
             ResultSet rs = ps.executeQuery()) {
            while (rs.next()) {
                User u = map(rs);
                u.setPassword(null); // never expose hashes
                list.add(u);
            }
        }
        return list;
    }

    // ── Delete user (cascades via FK to tickets, messages) ────
    public boolean deleteUser(int userId) throws SQLException {
        String sql = "DELETE FROM users WHERE id=?";
        try (Connection con = DBConnection.getConnection();
             PreparedStatement ps = con.prepareStatement(sql)) {
            ps.setInt(1, userId);
            return ps.executeUpdate() > 0;
        }
    }

    // ── Update profile (name, email, office line) ─────────────
    // Returns false if the new email conflicts with another account.
    public boolean updateProfile(int userId, String firstName, String lastName,
                                 String email, String officeLine) throws SQLException {
        // Check email uniqueness — allow keeping own email
        String check = "SELECT id FROM users WHERE email=? AND id<>?";
        try (Connection con = DBConnection.getConnection();
             PreparedStatement ps = con.prepareStatement(check)) {
            ps.setString(1, email);
            ps.setInt(2, userId);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) return false; // email taken by someone else
            }
        }
        String sql = "UPDATE users SET first_name=?, last_name=?, email=?, office_line=? WHERE id=?";
        try (Connection con = DBConnection.getConnection();
             PreparedStatement ps = con.prepareStatement(sql)) {
            ps.setString(1, firstName.trim());
            ps.setString(2, lastName.trim());
            ps.setString(3, email.trim());
            ps.setString(4, officeLine != null ? officeLine.trim() : null);
            ps.setInt(5, userId);
            ps.executeUpdate();
        }
        return true;
    }
}
