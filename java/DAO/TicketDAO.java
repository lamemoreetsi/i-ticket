package DAO;

import Model.Ticket;
import Model.TicketMessage;

import java.sql.*;
import java.util.ArrayList;
import java.util.List;

public class TicketDAO {

    // ── Map a ResultSet row to a Ticket ──────────────────────
    private Ticket map(ResultSet rs) throws SQLException {
        Ticket t = new Ticket();
        t.setId(rs.getInt("id"));
        t.setSummary(rs.getString("summary"));
        // --- START NEW MAPS ---
        t.setDescription(rs.getString("description"));
        t.setImageLink(rs.getString("image_link"));
        // --- END NEW MAPS ---
        t.setAssigneeId(rs.getInt("assignee_id"));
        t.setAssigneeName(rs.getString("assignee_name"));
        t.setCreatorId(rs.getInt("creator_id"));
        t.setCreatorName(rs.getString("creator_name"));
        t.setPriority(rs.getString("priority"));
        t.setCategory(rs.getString("category"));
        t.setStatus(rs.getString("status"));
        Timestamp ca = rs.getTimestamp("created_at");
        Timestamp ua = rs.getTimestamp("updated_at");
        if (ca != null) t.setCreatedAt(ca.toLocalDateTime());
        if (ua != null) t.setUpdatedAt(ua.toLocalDateTime());
        return t;
    }

    private static final String BASE_SELECT =
            // --- UPDATED SELECT FIELDS ---
            "SELECT t.id, t.summary, t.description, t.assignee_id, t.creator_id, " +
                    "       t.priority, t.category, t.image_link, t.status, t.created_at, t.updated_at, " +
                    "       CONCAT(a.first_name,' ',a.last_name) AS assignee_name, " +
                    "       CONCAT(c.first_name,' ',c.last_name) AS creator_name " +
                    "FROM tickets t " +
                    "LEFT JOIN users a ON t.assignee_id = a.id " +
                    "JOIN  users c ON t.creator_id  = c.id ";

    // ── Get all tickets for a specific user (creator) ─────────
    public List<Ticket> getTicketsByUser(int userId) throws SQLException {
        List<Ticket> list = new ArrayList<>();
        String sql = BASE_SELECT + "WHERE t.creator_id = ? ORDER BY t.created_at DESC";
        try (Connection con = DBConnection.getConnection();
             PreparedStatement ps = con.prepareStatement(sql)) {
            ps.setInt(1, userId);
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) list.add(map(rs));
            }
        }
        return list;
    }

    // ── Get all tickets (admin view) ──────────────────────────
    public List<Ticket> getAllTickets() throws SQLException {
        List<Ticket> list = new ArrayList<>();
        String sql = BASE_SELECT + "ORDER BY t.created_at DESC";
        try (Connection con = DBConnection.getConnection();
             PreparedStatement ps = con.prepareStatement(sql);
             ResultSet rs = ps.executeQuery()) {
            while (rs.next()) list.add(map(rs));
        }
        return list;
    }

    // ── Get single ticket by ID ───────────────────────────────
    public Ticket getTicketById(int id) throws SQLException {
        String sql = BASE_SELECT + "WHERE t.id = ?";
        try (Connection con = DBConnection.getConnection();
             PreparedStatement ps = con.prepareStatement(sql)) {
            ps.setInt(1, id);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) return map(rs);
            }
        }
        return null;
    }

    // ── Create ticket ─────────────────────────────────────────
    public void createTicket(Ticket t) throws SQLException {
        // --- UPDATED INSERT FIELDS ---
        String sql = "INSERT INTO tickets (summary, description, image_link, creator_id, priority, category, status) " +
                "VALUES (?, ?, ?, ?, ?, ?, 'open')";
        try (Connection con = DBConnection.getConnection();
             PreparedStatement ps = con.prepareStatement(sql)) {
            ps.setString(1, t.getSummary());
            // --- NEW PS SETTERS ---
            ps.setString(2, t.getDescription());
            ps.setString(3, t.getImageLink());
            // --- SHIFTED OLD SETTERS ---
            ps.setInt(4,    t.getCreatorId());
            ps.setString(5, t.getPriority());
            ps.setString(6, t.getCategory());
            ps.executeUpdate();
        }
    }

    // ── Update ticket (User editing configuration) ───────────────
    public void updateTicket(Ticket t) throws SQLException {
        // --- UPDATED UPDATE FIELDS ---
        String sql = "UPDATE tickets SET summary=?, description=?, image_link=?, priority=?, category=?, status=?, updated_at=NOW() " +
                "WHERE id=?";
        try (Connection con = DBConnection.getConnection();
             PreparedStatement ps = con.prepareStatement(sql)) {
            ps.setString(1, t.getSummary());
            // --- NEW PS SETTERS ---
            ps.setString(2, t.getDescription());
            ps.setString(3, t.getImageLink());
            // --- OLD SETTERS ---
            ps.setString(4, t.getPriority());
            ps.setString(5, t.getCategory());
            ps.setString(6, t.getStatus());
            ps.setInt(7,    t.getId());
            ps.executeUpdate();
        }
    }

    // ── Delete ticket ─────────────────────────────────────────
    public void deleteTicket(int id) throws SQLException {
        String sql = "DELETE FROM tickets WHERE id=?";
        try (Connection con = DBConnection.getConnection();
             PreparedStatement ps = con.prepareStatement(sql)) {
            ps.setInt(1, id);
            ps.executeUpdate();
        }
    }

    // ── Messages ──────────────────────────────────────────────

    public List<TicketMessage> getMessages(int ticketId) throws SQLException {
        List<TicketMessage> list = new ArrayList<>();
        // --- UPDATED SELECT FIELD ---
        String sql = "SELECT m.id, m.ticket_id, m.sender_id, m.message, m.image_link, m.sent_at, " +
                "       CONCAT(u.first_name,' ',u.last_name) AS sender_name, u.role AS sender_role " +
                "FROM ticket_messages m " +
                "JOIN users u ON m.sender_id = u.id " +
                "WHERE m.ticket_id = ? ORDER BY m.sent_at ASC";
        try (Connection con = DBConnection.getConnection();
             PreparedStatement ps = con.prepareStatement(sql)) {
            ps.setInt(1, ticketId);
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    TicketMessage msg = new TicketMessage();
                    msg.setId(rs.getInt("id"));
                    msg.setTicketId(rs.getInt("ticket_id"));
                    msg.setSenderId(rs.getInt("sender_id"));
                    msg.setSenderName(rs.getString("sender_name"));
                    msg.setSenderRole(rs.getString("sender_role"));
                    msg.setMessage(rs.getString("message"));
                    // --- NEW MESSAGE MAP ---
                    msg.setImageLink(rs.getString("image_link"));
                    Timestamp st = rs.getTimestamp("sent_at");
                    if (st != null) msg.setSentAt(st.toLocalDateTime());
                    list.add(msg);
                }
            }
        }
        return list;
    }

    // --- UPDATED ADD MESSAGE FUNCTION ---
    public void addMessage(int ticketId, int senderId, String message, String imageLink) throws SQLException {
        String sql = "INSERT INTO ticket_messages (ticket_id, sender_id, message, image_link) VALUES (?,?,?,?)";
        try (Connection con = DBConnection.getConnection();
             PreparedStatement ps = con.prepareStatement(sql)) {
            ps.setInt(1, ticketId);
            ps.setInt(2, senderId);
            ps.setString(3, message);
            ps.setString(4, imageLink);
            ps.executeUpdate();
        }
    }
}