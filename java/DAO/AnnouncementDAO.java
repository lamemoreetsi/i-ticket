package DAO;

import Model.Announcement;
import java.sql.*;
import java.util.ArrayList;
import java.util.List;

public class AnnouncementDAO {

    private Announcement map(ResultSet rs) throws SQLException {
        Announcement a = new Announcement();
        a.setId(rs.getInt("id"));
        a.setTitle(rs.getString("title"));
        a.setBody(rs.getString("body"));
        a.setAuthorId(rs.getInt("author_id"));
        a.setAuthorName(rs.getString("author_name"));
        Timestamp ca = rs.getTimestamp("created_at");
        if (ca != null) a.setCreatedAt(ca.toLocalDateTime());
        return a;
    }

    // ── Get all announcements, newest first ───────────────────
    public List<Announcement> getAll() throws SQLException {
        List<Announcement> list = new ArrayList<>();
        String sql = "SELECT a.id, a.title, a.body, a.author_id, a.created_at, " +
                "       CONCAT(u.first_name,' ',u.last_name) AS author_name " +
                "FROM announcements a " +
                "JOIN users u ON a.author_id = u.id " +
                "ORDER BY a.created_at DESC";
        try (Connection con = DBConnection.getConnection();
             PreparedStatement ps = con.prepareStatement(sql);
             ResultSet rs = ps.executeQuery()) {
            while (rs.next()) list.add(map(rs));
        }
        return list;
    }

    // ── Get only announcements newer than a given timestamp ───
    // Used by the polling endpoint to return only new items
    public List<Announcement> getNewerThan(long epochMilli) throws SQLException {
        List<Announcement> list = new ArrayList<>();
        String sql = "SELECT a.id, a.title, a.body, a.author_id, a.created_at, " +
                "       CONCAT(u.first_name,' ',u.last_name) AS author_name " +
                "FROM announcements a " +
                "JOIN users u ON a.author_id = u.id " +
                "WHERE a.created_at > ? " +
                "ORDER BY a.created_at ASC";
        try (Connection con = DBConnection.getConnection();
             PreparedStatement ps = con.prepareStatement(sql)) {
            ps.setTimestamp(1, new Timestamp(epochMilli));
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) list.add(map(rs));
            }
        }
        return list;
    }

    // ── Create announcement ───────────────────────────────────
    public void create(Announcement a) throws SQLException {
        String sql = "INSERT INTO announcements (title, body, author_id) VALUES (?, ?, ?)";
        try (Connection con = DBConnection.getConnection();
             PreparedStatement ps = con.prepareStatement(sql)) {
            ps.setString(1, a.getTitle());
            ps.setString(2, a.getBody());
            ps.setInt(3,    a.getAuthorId());
            ps.executeUpdate();
        }
    }

    // ── Delete announcement ───────────────────────────────────
    public void delete(int id) throws SQLException {
        String sql = "DELETE FROM announcements WHERE id = ?";
        try (Connection con = DBConnection.getConnection();
             PreparedStatement ps = con.prepareStatement(sql)) {
            ps.setInt(1, id);
            ps.executeUpdate();
        }
    }
}