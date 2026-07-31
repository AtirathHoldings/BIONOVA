package com.bionova.service;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.*;
import org.springframework.stereotype.Service;
import org.springframework.web.client.RestTemplate;
import org.springframework.web.multipart.MultipartFile;

import java.io.IOException;
import java.util.UUID;

/**
 * Supabase Storage Service
 *
 * Handles file uploads to Supabase Storage buckets with organised folder structures.
 *
 * ── IMAGES bucket (public) ─────────────────────────────────────────────────
 *   logos/company/          → Company logos
 *   logos/plantmaster/      → Plant master logos/images
 *   logos/landmaster/       → Land master documents/images
 *   photos/employees/       → Employee profile photos
 *   photos/external-employees/ → External employee profile photos
 *   projects/               → Project logos
 *
 * ── DOCUMENTS bucket ───────────────────────────────────────────────────────
 *   attachments/milestones/ → Milestone attachments
 *   attachments/tasks/      → Task attachments (draft & live)
 *   attachments/projects/   → Project attachments
 */
@Service
public class SupabaseStorageService {

    @Value("${supabase.url}")
    private String supabaseUrl;

    @Value("${supabase.service-key}")
    private String serviceKey;

    private final RestTemplate restTemplate = new RestTemplate();

    // ── Bucket constants ────────────────────────────────────────────────────

    public static final String BUCKET_IMAGES    = "images";
    public static final String BUCKET_DOCUMENTS = "documents";

    // ── Folder constants (images) ───────────────────────────────────────────

    public static final String FOLDER_COMPANY_LOGOS       = "logos/company";
    public static final String FOLDER_PLANT_LOGOS         = "logos/plantmaster";
    public static final String FOLDER_LAND_LOGOS          = "logos/landmaster";
    public static final String FOLDER_EMPLOYEE_PHOTOS     = "photos/employees";
    public static final String FOLDER_EXT_EMPLOYEE_PHOTOS = "photos/external-employees";
    public static final String FOLDER_PROJECT_LOGOS       = "projects";

    // ── Folder constants (documents) ────────────────────────────────────────

    public static final String FOLDER_ATTACHMENT_MILESTONES = "attachments/milestones";
    public static final String FOLDER_ATTACHMENT_TASKS      = "attachments/tasks";
    public static final String FOLDER_ATTACHMENT_PROJECTS   = "attachments/projects";

    // ────────────────────────────────────────────────────────────────────────

    /**
     * Uploads a file to a specific Supabase Storage bucket and folder.
     *
     * @param bucket      Target bucket name ("images" or "documents")
     * @param folder      Sub-folder path inside the bucket (e.g. "logos/company")
     * @param file        The multipart file to upload
     * @return            The full public URL of the uploaded file
     */
    public String uploadFile(String bucket, String folder, MultipartFile file) throws IOException {
        String originalName = file.getOriginalFilename();
        String extension    = "";
        if (originalName != null && originalName.contains(".")) {
            extension = originalName.substring(originalName.lastIndexOf("."));
        }
        String uniqueName = UUID.randomUUID().toString() + extension;
        String filePath   = folder + "/" + uniqueName;

        String uploadUrl = supabaseUrl + "/storage/v1/object/" + bucket + "/" + filePath;

        HttpHeaders headers = new HttpHeaders();
        headers.set("Authorization", "Bearer " + serviceKey);
        headers.setContentType(MediaType.valueOf(
                file.getContentType() != null ? file.getContentType() : "application/octet-stream"
        ));
        headers.set("x-upsert", "false");

        HttpEntity<byte[]> requestEntity = new HttpEntity<>(file.getBytes(), headers);

        ResponseEntity<String> response = restTemplate.exchange(
                uploadUrl, HttpMethod.POST, requestEntity, String.class);

        if (!response.getStatusCode().is2xxSuccessful()) {
            throw new RuntimeException("Supabase upload failed: " + response.getBody());
        }

        return buildPublicUrl(bucket, filePath);
    }

    /**
     * Deletes a file from Supabase Storage by its full URL.
     * Extracts the bucket and file path from the URL automatically.
     *
     * @param publicUrl The full public URL previously returned by uploadFile()
     */
    public void deleteFileByUrl(String publicUrl) {
        if (publicUrl == null || publicUrl.isBlank()) return;

        // URL format: https://<project>.supabase.co/storage/v1/object/public/<bucket>/<path>
        String marker = "/object/public/";
        int idx = publicUrl.indexOf(marker);
        if (idx == -1) return;

        String bucketAndPath = publicUrl.substring(idx + marker.length());
        int slashIdx = bucketAndPath.indexOf('/');
        if (slashIdx == -1) return;

        String bucket   = bucketAndPath.substring(0, slashIdx);
        String filePath = bucketAndPath.substring(slashIdx + 1);

        deleteFile(bucket, filePath);
    }

    /**
     * Deletes a file from Supabase Storage.
     *
     * @param bucket   Bucket name
     * @param filePath Path inside the bucket (e.g. "logos/company/uuid.png")
     */
    public void deleteFile(String bucket, String filePath) {
        String deleteUrl = supabaseUrl + "/storage/v1/object/" + bucket + "/" + filePath;

        HttpHeaders headers = new HttpHeaders();
        headers.set("Authorization", "Bearer " + serviceKey);

        HttpEntity<Void> requestEntity = new HttpEntity<>(headers);
        try {
            restTemplate.exchange(deleteUrl, HttpMethod.DELETE, requestEntity, String.class);
        } catch (Exception e) {
            // Log but don't throw — deletion is best-effort
            System.err.println("[SupabaseStorage] Failed to delete file: " + filePath + " — " + e.getMessage());
        }
    }

    /**
     * Builds the public URL for a file stored in Supabase Storage.
     *
     * @param bucket   Bucket name
     * @param filePath Full path inside the bucket
     * @return         The public URL
     */
    public String buildPublicUrl(String bucket, String filePath) {
        return supabaseUrl + "/storage/v1/object/public/" + bucket + "/" + filePath;
    }
}
