package Model;

import java.time.LocalDateTime;

public class Announcement {

    private int           id;
    private String        title;
    private String        body;
    private int           authorId;
    private String        authorName;   // first + last
    private LocalDateTime createdAt;

    public Announcement() {}

    // ── Getters ───────────────────────────────────────────────
    public int           getId()         { return id; }
    public String        getTitle()      { return title; }
    public String        getBody()       { return body; }
    public int           getAuthorId()   { return authorId; }
    public String        getAuthorName() { return authorName; }
    public LocalDateTime getCreatedAt()  { return createdAt; }

    // ── Setters ───────────────────────────────────────────────
    public void setId(int id)                      { this.id = id; }
    public void setTitle(String title)             { this.title = title; }
    public void setBody(String body)               { this.body = body; }
    public void setAuthorId(int authorId)          { this.authorId = authorId; }
    public void setAuthorName(String authorName)   { this.authorName = authorName; }
    public void setCreatedAt(LocalDateTime createdAt){ this.createdAt = createdAt; }
}