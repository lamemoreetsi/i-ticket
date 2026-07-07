package Util;

import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.Part;
import java.io.*;
import java.nio.file.Files;
import java.nio.file.Paths;
import java.nio.file.StandardCopyOption;
import java.util.Arrays;
import java.util.List;
import java.util.Locale;
import java.util.UUID;

public class FileHandler {

    // Upload directory relative to the web application root
    private static final String UPLOAD_DIR = "uploads" + File.separator + "images";

    // ── OWASP A04 / A03: allow-list, not a block-list, for uploaded file types ──
    private static final List<String> ALLOWED_EXTENSIONS =
            Arrays.asList(".png", ".jpg", ".jpeg", ".gif", ".webp");

    // 5 MB cap — adjust to whatever's reasonable for a ticket screenshot.
    private static final long MAX_FILE_SIZE_BYTES = 5L * 1024 * 1024;

    /**
     * Extracts a plain-text field value from a multipart/form-data request.
     * Standard req.getParameter() returns null for multipart requests,
     * so we read the part's input stream directly.
     */
    public static String getPartValue(HttpServletRequest request, String partName)
            throws IOException, ServletException {
        Part part = request.getPart(partName);
        if (part == null) return null;
        try (java.util.Scanner scanner = new java.util.Scanner(
                part.getInputStream(), "UTF-8")) {
            scanner.useDelimiter("\\A");
            return scanner.hasNext() ? scanner.next().trim() : null;
        }
    }

    /**
     * Saves an uploaded image part to disk and returns its web-accessible
     * relative URL path (e.g. "uploads/images/uuid.png"), or null if no
     * file was submitted for this field.
     *
     * Throws IOException with a user-safe message if the upload fails
     * validation (wrong type, too large, content doesn't match extension) —
     * callers should catch this and show the message to the user rather
     * than a stack trace.
     *
     * Copies the stream manually (rather than calling Part.write()) so the
     * destination path is always exactly what we computed, regardless of
     * how the container configured its temp multipart location.
     */
    public static String saveImagePart(HttpServletRequest req, String fieldName)
            throws IOException, ServletException {

        Part filePart = req.getPart(fieldName);
        if (filePart == null || filePart.getSize() == 0) return null;

        if (filePart.getSize() > MAX_FILE_SIZE_BYTES) {
            throw new IOException("Image is too large (max " + (MAX_FILE_SIZE_BYTES / (1024 * 1024)) + "MB).");
        }

        String submitted = filePart.getSubmittedFileName();
        if (submitted == null || submitted.isBlank()) {
            throw new IOException("No filename provided for upload.");
        }

        String original  = Paths.get(submitted).getFileName().toString();
        String extension  = original.contains(".")
                ? original.substring(original.lastIndexOf('.')).toLowerCase(Locale.ROOT)
                : "";

        if (!ALLOWED_EXTENSIONS.contains(extension)) {
            throw new IOException("Unsupported file type. Allowed: " + ALLOWED_EXTENSIONS);
        }

        // ── Read the upload once into memory, then validate + write from
        //    that buffer. Avoids relying on re-opening Part's InputStream
        //    twice, which isn't guaranteed safe across all containers. ──
        byte[] content;
        try (InputStream in = filePart.getInputStream()) {
            content = in.readAllBytes();
        }

        if (!matchesImageSignature(content, extension)) {
            throw new IOException("File contents do not match a valid image of type " + extension + ".");
        }

        String fileName = UUID.randomUUID() + extension;

        // Absolute path on disk — for saving the file
        String uploadDir = req.getServletContext().getRealPath("/uploads/images");
        File dir = new File(uploadDir);
        if (!dir.exists()) dir.mkdirs();

        File destination = new File(dir, fileName);
        // Defensive: make sure we never resolve outside the upload dir.
        if (!destination.getCanonicalPath().startsWith(dir.getCanonicalPath() + File.separator)) {
            throw new IOException("Invalid upload destination.");
        }

        Files.write(destination.toPath(), content);

        // ✅ Return a WEB-relative path (no leading slash)
        return "uploads/images/" + fileName;
    }

    /** Minimal magic-byte check so a renamed non-image file can't slip through on extension alone. */
    private static boolean matchesImageSignature(byte[] h, String extension) {
        if (h == null || h.length < 4) return false;
        switch (extension) {
            case ".png":
                return h.length >= 8 && (h[0] & 0xFF) == 0x89 && h[1] == 0x50 && h[2] == 0x4E && h[3] == 0x47;
            case ".jpg":
            case ".jpeg":
                return (h[0] & 0xFF) == 0xFF && (h[1] & 0xFF) == 0xD8;
            case ".gif":
                return h.length >= 6 && h[0] == 'G' && h[1] == 'I' && h[2] == 'F' && h[3] == '8';
            case ".webp":
                // RIFF????WEBP — bytes 0-3 "RIFF", bytes 8-11 "WEBP"
                return h.length >= 4 && h[0] == 'R' && h[1] == 'I' && h[2] == 'F' && h[3] == 'F';
            default:
                return false;
        }
    }
}