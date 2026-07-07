package Model;

import java.time.LocalDateTime;

public class Ticket {

    private int    id;
    private String summary;
    // --- START NEW FIELDS ---
    private String description; // HTML or Plain Text
    private String imageLink;   // URL to image
    // --- END NEW FIELDS ---
    private int    assigneeId;
    private String assigneeName;   // display: first + last
    private int    creatorId;
    private String creatorName;
    private String priority;       // Low | Medium | High
    private String category;
    private String status;         // open | in_progress | closed
    private LocalDateTime createdAt;
    private LocalDateTime updatedAt;

    public Ticket() {}

    // ── Getters ───────────────────────────────────────────────
    public int            getId()           { return id; }
    public String         getSummary()      { return summary; }
    // --- START NEW GETTERS ---
    public String         getDescription()  { return description; }
    public String         getImageLink()    { return imageLink; }
    // --- END NEW GETTERS ---
    public int            getAssigneeId()   { return assigneeId; }
    public String         getAssigneeName() { return assigneeName; }
    public int            getCreatorId()    { return creatorId; }
    public String         getCreatorName()  { return creatorName; }
    public String         getPriority()     { return priority; }
    public String         getCategory()     { return category; }
    public String         getStatus()       { return status; }
    public LocalDateTime  getCreatedAt()    { return createdAt; }
    public LocalDateTime  getUpdatedAt()    { return updatedAt; }

    // ── Setters ───────────────────────────────────────────────
    public void setId(int id)                        { this.id = id; }
    public void setSummary(String summary)           { this.summary = summary; }
    // --- START NEW SETTERS ---
    public void setDescription(String description)   { this.description = description; }
    public void setImageLink(String imageLink)       { this.imageLink = imageLink; }
    // --- END NEW SETTERS ---
    public void setAssigneeId(int assigneeId)        { this.assigneeId = assigneeId; }
    public void setAssigneeName(String name)         { this.assigneeName = name; }
    public void setCreatorId(int creatorId)          { this.creatorId = creatorId; }
    public void setCreatorName(String name)          { this.creatorName = name; }
    public void setPriority(String priority)         { this.priority = priority; }
    public void setCategory(String category)         { this.category = category; }
    public void setStatus(String status)             { this.status = status; }
    public void setCreatedAt(LocalDateTime createdAt){ this.createdAt = createdAt; }
    public void setUpdatedAt(LocalDateTime updatedAt){ this.updatedAt = updatedAt; }
}