package Model;

import java.time.LocalDateTime;

public class TicketMessage {

    private int           id;
    private int           ticketId;
    private int           senderId;
    private String        senderName;   // first + last
    private String        senderRole;   // ADMIN | USER
    private String        message;
    // --- START NEW FIELD ---
    private String        imageLink;   // Optional image in reply
    // --- END NEW FIELD ---
    private LocalDateTime sentAt;

    public TicketMessage() {}

    // ── Getters ───────────────────────────────────────────────
    public int           getId()         { return id; }
    public int           getTicketId()   { return ticketId; }
    public int           getSenderId()   { return senderId; }
    public String        getSenderName() { return senderName; }
    public String        getSenderRole() { return senderRole; }
    public String        getMessage()    { return message; }
    // --- START NEW GETTER ---
    public String        getImageLink()  { return imageLink; }
    // --- END NEW GETTER ---
    public LocalDateTime getSentAt()     { return sentAt; }

    // ── Setters ───────────────────────────────────────────────
    public void setId(int id)                      { this.id = id; }
    public void setTicketId(int ticketId)          { this.ticketId = ticketId; }
    public void setSenderId(int senderId)          { this.senderId = senderId; }
    public void setSenderName(String senderName)   { this.senderName = senderName; }
    public void setSenderRole(String senderRole)   { this.senderRole = senderRole; }
    public void setMessage(String message)         { this.message = message; }
    // --- START NEW SETTER ---
    public void setImageLink(String imageLink)     { this.imageLink = imageLink; }
    // --- END NEW SETTER ---
    public void setSentAt(LocalDateTime sentAt)    { this.sentAt = sentAt; }
}