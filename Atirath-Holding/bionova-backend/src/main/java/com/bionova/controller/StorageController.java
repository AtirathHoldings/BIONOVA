package com.bionova.controller;

import com.bionova.service.SupabaseStorageService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;

import java.util.Map;

/**
 * Storage Controller — handles file uploads to Supabase Storage buckets.
 *
 * ── IMAGES bucket (public) ─────────────────────────────────────────────────
 *   POST /api/storage/upload/company-logo          → logos/company/
 *   POST /api/storage/upload/plant-logo            → logos/plantmaster/
 *   POST /api/storage/upload/land-logo             → logos/landmaster/
 *   POST /api/storage/upload/employee-photo        → photos/employees/
 *   POST /api/storage/upload/external-employee-photo → photos/external-employees/
 *   POST /api/storage/upload/project-logo          → projects/
 *
 * ── DOCUMENTS bucket ───────────────────────────────────────────────────────
 *   POST /api/storage/upload/attachment/milestone  → attachments/milestones/
 *   POST /api/storage/upload/attachment/task       → attachments/tasks/
 *   POST /api/storage/upload/attachment/project    → attachments/projects/
 *
 * ── COMMON ─────────────────────────────────────────────────────────────────
 *   DELETE /api/storage/delete                     → delete file by URL
 */
@RestController
@RequestMapping("/api/storage")
public class StorageController {

    @Autowired
    private SupabaseStorageService storageService;

    // ── IMAGES ──────────────────────────────────────────────────────────────

    /**
     * Upload a company logo.
     * Stored in: images/logos/company/<uuid>.<ext>
     * Returns: { "url": "https://..." }
     */
    @PostMapping("/upload/company-logo")
    public ResponseEntity<?> uploadCompanyLogo(@RequestParam("file") MultipartFile file) {
        return uploadImage(SupabaseStorageService.FOLDER_COMPANY_LOGOS, file);
    }

    /**
     * Upload a plant master logo/image.
     * Stored in: images/logos/plantmaster/<uuid>.<ext>
     */
    @PostMapping("/upload/plant-logo")
    public ResponseEntity<?> uploadPlantLogo(@RequestParam("file") MultipartFile file) {
        return uploadImage(SupabaseStorageService.FOLDER_PLANT_LOGOS, file);
    }

    /**
     * Upload a land master logo/image.
     * Stored in: images/logos/landmaster/<uuid>.<ext>
     */
    @PostMapping("/upload/land-logo")
    public ResponseEntity<?> uploadLandLogo(@RequestParam("file") MultipartFile file) {
        return uploadImage(SupabaseStorageService.FOLDER_LAND_LOGOS, file);
    }

    /**
     * Upload an employee profile photo.
     * Stored in: images/photos/employees/<uuid>.<ext>
     */
    @PostMapping("/upload/employee-photo")
    public ResponseEntity<?> uploadEmployeePhoto(@RequestParam("file") MultipartFile file) {
        return uploadImage(SupabaseStorageService.FOLDER_EMPLOYEE_PHOTOS, file);
    }

    /**
     * Upload an external employee profile photo.
     * Stored in: images/photos/external-employees/<uuid>.<ext>
     */
    @PostMapping("/upload/external-employee-photo")
    public ResponseEntity<?> uploadExternalEmployeePhoto(@RequestParam("file") MultipartFile file) {
        return uploadImage(SupabaseStorageService.FOLDER_EXT_EMPLOYEE_PHOTOS, file);
    }

    /**
     * Upload a project logo.
     * Stored in: images/projects/<uuid>.<ext>
     */
    @PostMapping("/upload/project-logo")
    public ResponseEntity<?> uploadProjectLogo(@RequestParam("file") MultipartFile file) {
        return uploadImage(SupabaseStorageService.FOLDER_PROJECT_LOGOS, file);
    }

    // ── DOCUMENTS ───────────────────────────────────────────────────────────

    /**
     * Upload a milestone attachment document.
     * Stored in: documents/attachments/milestones/<uuid>.<ext>
     */
    @PostMapping("/upload/attachment/milestone")
    public ResponseEntity<?> uploadMilestoneAttachment(@RequestParam("file") MultipartFile file) {
        return uploadDocument(SupabaseStorageService.FOLDER_ATTACHMENT_MILESTONES, file);
    }

    /**
     * Upload a task attachment document (draft or live).
     * Stored in: documents/attachments/tasks/<uuid>.<ext>
     */
    @PostMapping({"/upload/attachment/task", "/upload/attachment/assignment"})
    public ResponseEntity<?> uploadTaskAttachment(@RequestParam("file") MultipartFile file) {
        return uploadDocument(SupabaseStorageService.FOLDER_ATTACHMENT_TASKS, file);
    }

    /**
     * Upload a project attachment document.
     * Stored in: documents/attachments/projects/<uuid>.<ext>
     */
    @PostMapping("/upload/attachment/project")
    public ResponseEntity<?> uploadProjectAttachment(@RequestParam("file") MultipartFile file) {
        return uploadDocument(SupabaseStorageService.FOLDER_ATTACHMENT_PROJECTS, file);
    }

    // ── DELETE ───────────────────────────────────────────────────────────────

    /**
     * Delete a file by its public URL.
     * Body: { "url": "https://daaoeapbouspxcuprsqx.supabase.co/storage/v1/object/public/..." }
     */
    @DeleteMapping("/delete")
    public ResponseEntity<?> deleteFile(@RequestBody Map<String, String> body) {
        String url = body.get("url");
        if (url == null || url.isBlank()) {
            return ResponseEntity.badRequest().body(Map.of("message", "File URL is required."));
        }
        storageService.deleteFileByUrl(url);
        return ResponseEntity.ok(Map.of("message", "File deleted successfully."));
    }

    // ── Helpers ──────────────────────────────────────────────────────────────

    @org.springframework.beans.factory.annotation.Value("${supabase.url}")
    private String supabaseUrl;

    @org.springframework.beans.factory.annotation.Value("${supabase.service-key}")
    private String serviceKey;

    private final org.springframework.web.client.RestTemplate restTemplate = new org.springframework.web.client.RestTemplate();

    /**
     * Proxy endpoint to view/stream files from Supabase Storage securely using serviceKey.
     * Prevents 404 Bucket Not Found / Private Bucket errors when viewing files.
     */
    @GetMapping("/view")
    public ResponseEntity<byte[]> viewFile(@RequestParam("url") String fileUrl) {
        try {
            if (fileUrl == null || fileUrl.isBlank()) {
                return ResponseEntity.badRequest().build();
            }

            String targetUrl = fileUrl.trim();
            if (targetUrl.contains("/storage/v1/object/public/")) {
                targetUrl = targetUrl.replace("/storage/v1/object/public/", "/storage/v1/object/authenticated/");
            } else if (!targetUrl.startsWith("http")) {
                targetUrl = supabaseUrl + "/storage/v1/object/authenticated/" + targetUrl;
            }

            org.springframework.http.HttpHeaders headers = new org.springframework.http.HttpHeaders();
            headers.set("Authorization", "Bearer " + serviceKey);
            org.springframework.http.HttpEntity<Void> requestEntity = new org.springframework.http.HttpEntity<>(headers);

            ResponseEntity<byte[]> response = restTemplate.exchange(
                    targetUrl, org.springframework.http.HttpMethod.GET, requestEntity, byte[].class);

            if (response.getStatusCode().is2xxSuccessful() && response.getBody() != null) {
                org.springframework.http.HttpHeaders respHeaders = new org.springframework.http.HttpHeaders();
                if (response.getHeaders().getContentType() != null) {
                    respHeaders.setContentType(response.getHeaders().getContentType());
                } else if (fileUrl.toLowerCase().contains(".jpg") || fileUrl.toLowerCase().contains(".jpeg")) {
                    respHeaders.setContentType(org.springframework.http.MediaType.IMAGE_JPEG);
                } else if (fileUrl.toLowerCase().contains(".png")) {
                    respHeaders.setContentType(org.springframework.http.MediaType.IMAGE_PNG);
                } else if (fileUrl.toLowerCase().contains(".pdf")) {
                    respHeaders.setContentType(org.springframework.http.MediaType.APPLICATION_PDF);
                }
                respHeaders.setCacheControl("max-age=3600");
                return new ResponseEntity<>(response.getBody(), respHeaders, org.springframework.http.HttpStatus.OK);
            }
        } catch (Exception e) {
            System.err.println("[StorageController] Proxy view file failed: " + e.getMessage());
        }
        return ResponseEntity.notFound().build();
    }

    /**
     * Download endpoint — forces browser to save file directly to disk with proper filename.
     */
    @GetMapping("/download")
    public ResponseEntity<byte[]> downloadFile(
            @RequestParam("url") String fileUrl,
            @RequestParam(value = "name", required = false) String fileName) {
        try {
            if (fileUrl == null || fileUrl.isBlank()) {
                return ResponseEntity.badRequest().build();
            }

            String targetUrl = fileUrl.trim();
            if (targetUrl.contains("/storage/v1/object/public/")) {
                targetUrl = targetUrl.replace("/storage/v1/object/public/", "/storage/v1/object/authenticated/");
            } else if (!targetUrl.startsWith("http")) {
                targetUrl = supabaseUrl + "/storage/v1/object/authenticated/" + targetUrl;
            }

            org.springframework.http.HttpHeaders headers = new org.springframework.http.HttpHeaders();
            headers.set("Authorization", "Bearer " + serviceKey);
            org.springframework.http.HttpEntity<Void> requestEntity = new org.springframework.http.HttpEntity<>(headers);

            ResponseEntity<byte[]> response = restTemplate.exchange(
                    targetUrl, org.springframework.http.HttpMethod.GET, requestEntity, byte[].class);

            if (response.getStatusCode().is2xxSuccessful() && response.getBody() != null) {
                org.springframework.http.HttpHeaders respHeaders = new org.springframework.http.HttpHeaders();
                
                String downloadName = (fileName != null && !fileName.isBlank()) 
                        ? fileName 
                        : targetUrl.substring(targetUrl.lastIndexOf('/') + 1);

                respHeaders.setContentType(org.springframework.http.MediaType.APPLICATION_OCTET_STREAM);
                respHeaders.setContentDisposition(
                        org.springframework.http.ContentDisposition.attachment()
                                .filename(downloadName)
                                .build()
                );

                return new ResponseEntity<>(response.getBody(), respHeaders, org.springframework.http.HttpStatus.OK);
            }
        } catch (Exception e) {
            System.err.println("[StorageController] Proxy download file failed: " + e.getMessage());
        }
        return ResponseEntity.notFound().build();
    }

    private ResponseEntity<?> uploadImage(String folder, MultipartFile file) {
        return upload(SupabaseStorageService.BUCKET_IMAGES, folder, file);
    }

    private ResponseEntity<?> uploadDocument(String folder, MultipartFile file) {
        return upload(SupabaseStorageService.BUCKET_DOCUMENTS, folder, file);
    }

    private static final java.util.Set<String> DISALLOWED_EXTENSIONS = java.util.Set.of(
        "zip", "rar", "7z", "tar", "gz", "iso",
        "mp3", "wav", "aac", "m4a", "ogg", "flac", "wma",
        "mp4", "avi", "mov", "mkv", "webm", "flv", "wmv", "3gp", "m4v"
    );

    private ResponseEntity<?> upload(String bucket, String folder, MultipartFile file) {
        if (file == null || file.isEmpty()) {
            return ResponseEntity.badRequest().body(Map.of("message", "File is required and must not be empty."));
        }
        String originalFilename = file.getOriginalFilename();
        if (originalFilename != null && originalFilename.contains(".")) {
            String ext = originalFilename.substring(originalFilename.lastIndexOf(".") + 1).toLowerCase();
            if (DISALLOWED_EXTENSIONS.contains(ext)) {
                return ResponseEntity.badRequest().body(Map.of("message", "ZIP, Audio, and Video files are not allowed. Please upload Documents or Images only."));
            }
        }
        try {
            String url = storageService.uploadFile(bucket, folder, file);
            return ResponseEntity.ok(Map.of("url", url));
        } catch (Exception e) {
            return ResponseEntity.internalServerError()
                    .body(Map.of("message", "Upload failed: " + e.getMessage()));
        }
    }
}
