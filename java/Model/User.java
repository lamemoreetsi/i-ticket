package Model;

import java.time.LocalDateTime;

public class User {

    private int           id;
    private String        firstName;
    private String        lastName;
    private String        username;
    private String        email;
    private String        password;     // bcrypt hash — never expose to JSP
    private String        role;         // ADMIN | USER
    private String        officeLine;   // optional office/extension number
    private LocalDateTime createdAt;

    public User() {}

    // ── Getters ───────────────────────────────────────────────
    public int           getId()         { return id; }
    public String        getFirstName()  { return firstName; }
    public String        getLastName()   { return lastName; }
    public String        getUsername()   { return username; }
    public String        getEmail()      { return email; }
    public String        getPassword()   { return password; }
    public String        getRole()       { return role; }
    public String        getOfficeLine() { return officeLine; }
    public LocalDateTime getCreatedAt()  { return createdAt; }

    // ── Convenience ───────────────────────────────────────────
    public String getFullName() { return firstName + " " + lastName; }

    // ── Setters ───────────────────────────────────────────────
    public void setId(int id)                        { this.id = id; }
    public void setFirstName(String firstName)       { this.firstName = firstName; }
    public void setLastName(String lastName)         { this.lastName = lastName; }
    public void setUsername(String username)         { this.username = username; }
    public void setEmail(String email)               { this.email = email; }
    public void setPassword(String password)         { this.password = password; }
    public void setRole(String role)                 { this.role = role; }
    public void setOfficeLine(String officeLine)     { this.officeLine = officeLine; }
    public void setCreatedAt(LocalDateTime createdAt){ this.createdAt = createdAt; }
}
