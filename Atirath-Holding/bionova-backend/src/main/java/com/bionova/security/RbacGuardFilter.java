package com.bionova.security;

import com.bionova.entity.RoleBasedAccessControl;
import com.bionova.entity.RoleBasedEmployeeMapping;
import com.bionova.entity.ScreenMaster;
import com.bionova.repository.RoleBasedAccessControlRepository;
import com.bionova.repository.RoleBasedEmployeeMappingRepository;
import com.bionova.repository.ScreenMasterRepository;
import com.fasterxml.jackson.databind.ObjectMapper;
import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.stereotype.Component;
import org.springframework.web.filter.OncePerRequestFilter;

import java.io.IOException;
import java.util.*;

/**
 * RBAC Guard Filter – runs AFTER JwtAuthFilter.
 *
 * For every authenticated API request:
 *   1. Resolves the API path → list of allowed screenCodes.
 *   2. If no mapping found, the request is passed through (un-guarded public/shared endpoint).
 *   3. If the employee has NO RBAC configured → full_access, request passes through.
 *   4. If the employee HAS RBAC → checks viewFlg for any of the allowed screenCodes.
 *      - viewFlg = true for at least one allowed screen → allow through.
 *      - Otherwise → 403 Forbidden.
 */
@Component
public class RbacGuardFilter extends OncePerRequestFilter {

    private final RoleBasedEmployeeMappingRepository employeeMappingRepository;
    private final RoleBasedAccessControlRepository rbacRepository;
    private final ScreenMasterRepository screenMasterRepository;
    private final ObjectMapper objectMapper;

    /**
     * Maps URL path prefixes (after /api/) → list of screen codes.
     */
    private static final Map<String, List<String>> PATH_TO_SCREEN_CODES = new LinkedHashMap<>();

    private static void mapPath(String path, String... codes) {
        PATH_TO_SCREEN_CODES.put(path, Arrays.asList(codes));
    }

    static {
        // ══════════════════════════════════════════════════════════════════
        // IMPORTANT: These screen_code values MUST exactly match the
        // screen_code column in the screen_master table in the database.
        // ══════════════════════════════════════════════════════════════════

        // ─── Company Master group ─────────────────────────────────────────
        mapPath("admin",                "ADMIN_DASHBOARD");
        mapPath("companies",            "COMPANY_CREATION");
        mapPath("plants",               "PLANT_CREATION");
        mapPath("landmasters",          "LAND_CREATION");
        mapPath("landmaster",           "LAND_CREATION");
        mapPath("departments",          "DEPARTMENT_CREATION");
        mapPath("designations",         "DEPARTMENT_CREATION");
        mapPath("dept-company-plant",   "DEPARTMENT_MAPPING");
        mapPath("dept-coy-plt",         "DEPARTMENT_MAPPING");

        // ─── User Management / Employee Creation ──────────────────────────
        mapPath("employees",            "EMPLOYEE_CREATION");
        mapPath("external-employees",   "EMPLOYEE_CREATION");

        // ─── Project group ────────────────────────────────────────────────
        // Draft Phase / Project Creation
        mapPath("project-drafts",       "PROJECT_CREATION");
        mapPath("milestone-drafts",     "PROJECT_CREATION");
        mapPath("task-drafts",          "PROJECT_CREATION");

        // Dashboards
        mapPath("dashboard",            "PROJECT_DASHBOARD");
        mapPath("user-dashboard",       "USER_DASHBOARD");

        // Project Live / Project List
        // (Shared endpoint: Managers use LIVE_PROJECT_LIST, regular users use MY_PROJECTS)
        mapPath("project-live",         "LIVE_PROJECT_LIST", "MY_PROJECTS");
        mapPath("project-forecasting",  "LIVE_PROJECT_LIST");

        // Live Milestones & Tasks / Gantt / Team Members
        // (Shared endpoints: Managers use TASK_BOARD, regular users use MY_TASK or USER_TASK_BOARD)
        mapPath("milestone-live",       "TASK_BOARD", "MY_TASK", "MY_PROJECTS", "USER_TASK_BOARD");
        mapPath("task-live",            "TASK_BOARD", "MY_TASK", "USER_TASK_BOARD");
        mapPath("gantt",                "TASK_BOARD", "MY_PROJECTS", "GANTT_CHART");
        mapPath("team-members",         "TASK_BOARD", "MY_TASK", "USER_TASK_BOARD");

        // ─── Role/Access Management ───────────────────────────────────────
        mapPath("rbac",                 "ASSIGN_ACCESS");

        // ─── Process / Checklist ─────────────────────────────────────────
        mapPath("process-config",       "PROJECT_CREATION", "MILESTONE_CREATION", "ASSIGN_ACCESS", "INDIVIDUAL_TASK");
        mapPath("process",              "TASK_BOARD", "MY_TASK", "USER_TASK_BOARD", "INDIVIDUAL_TASK");
        mapPath("checklists",           "TASK_BOARD", "MY_TASK", "USER_TASK_BOARD", "INDIVIDUAL_TASK", "MILESTONE_CREATION");

        // ─── Calendar ────────────────────────────────────────────────────
        mapPath("calendar",             "CALENDAR", "PUBLIC_HOLIDAYS");

        // ─── Project Access ───────────────────────────────────────────────
        mapPath("project-access-control", "PROJECT_ACCESS");
        mapPath("project-access",       "PROJECT_ACCESS");
    }

    /**
     * Paths that are completely public / not RBAC-guarded, even if authenticated.
     * Format: prefix of the path AFTER stripping "/api/".
     */
    private static final Set<String> PUBLIC_PATHS = new HashSet<>(Arrays.asList(
            "auth",                     // /api/auth/**
            "notifications",            // /api/notifications
            "attachments",              // /api/attachments
            "activity-logs",            // /api/activity-logs
            "settings",                 // /api/settings
            "storage",                  // /api/storage
            "reviewers",                // /api/reviewers
            "states",                   // /api/states
            "assignments",              // /api/assignments (Renamed from individual-tasks)
            "profile",                  // /api/profile (Every user must access their profile)
            "employees/fcm-token",       // /api/employees/fcm-token (Every user must register token)
            "employees/change-password", // /api/employees/change-password (Every user must be able to change password)
            "rbac/employees"            // /api/rbac/employees/** (Required for loading sidebar permissions for all logged-in employees)
    ));

    public RbacGuardFilter(RoleBasedEmployeeMappingRepository employeeMappingRepository,
                           RoleBasedAccessControlRepository rbacRepository,
                           ScreenMasterRepository screenMasterRepository) {
        this.employeeMappingRepository = employeeMappingRepository;
        this.rbacRepository = rbacRepository;
        this.screenMasterRepository = screenMasterRepository;
        this.objectMapper = new ObjectMapper();
    }

    @Override
    protected void doFilterInternal(HttpServletRequest request,
                                    HttpServletResponse response,
                                    FilterChain filterChain)
            throws ServletException, IOException {

        // Bypass GET requests for companies and plants so regular employees can load names and logos
        String requestPath = request.getRequestURI();
        String method = request.getMethod();
        if ("GET".equalsIgnoreCase(method)) {
            if (requestPath.contains("/api/companies") || requestPath.contains("/api/plants")) {
                filterChain.doFilter(request, response);
                return;
            }
        }

        // 1. Only guard authenticated requests
        if (SecurityContextHolder.getContext().getAuthentication() == null ||
                !SecurityContextHolder.getContext().getAuthentication().isAuthenticated()) {
            filterChain.doFilter(request, response);
            return;
        }

        // 2. Resolve the empId from the request attribute set by JwtAuthFilter
        Long empId = (Long) request.getAttribute("empId");
        if (empId == null) {
            // No empId in token (e.g., temp-token / legacy) → skip guard
            filterChain.doFilter(request, response);
            return;
        }

        // 3. Resolve the screen codes for this request path
        requestPath = request.getRequestURI(); // e.g. /api/employees/5
        List<String> screenCodes = resolveScreenCodes(requestPath);

        if (screenCodes == null || screenCodes.isEmpty()) {
            // No RBAC mapping for this path → let it through
            filterChain.doFilter(request, response);
            return;
        }

        // 4. Check if the employee has RBAC configured
        List<RoleBasedEmployeeMapping> mappings = employeeMappingRepository.findByEmpId(empId);
        if (mappings.isEmpty()) {
            // No RBAC configured → Access Denied
            response.setStatus(HttpServletResponse.SC_FORBIDDEN);
            response.setContentType("application/json");
            response.setCharacterEncoding("UTF-8");
            Map<String, Object> body = new LinkedHashMap<>();
            body.put("status", 403);
            body.put("error", "Access Denied");
            body.put("message", "You do not have any roles assigned. Please contact the administrator.");
            response.getWriter().write(objectMapper.writeValueAsString(body));
            return;
        }

        // 5. Find the screenIds for the allowed screenCodes
        Set<Integer> allowedScreenIds = new HashSet<>();
        for (String code : screenCodes) {
            screenMasterRepository.findByScreenCode(code)
                    .ifPresent(screen -> allowedScreenIds.add(screen.getScreenId()));
        }

        if (allowedScreenIds.isEmpty()) {
            // Screens not found in master → let it through (safety/migration fallback)
            filterChain.doFilter(request, response);
            return;
        }

        // 6. Check viewFlg across ALL role mappings for this employee (OR logic)
        boolean allowed = false;
        for (RoleBasedEmployeeMapping mapping : mappings) {
            List<RoleBasedAccessControl> rbacList = rbacRepository.findByRoleId(mapping.getRoleId());
            for (RoleBasedAccessControl rbac : rbacList) {
                if (allowedScreenIds.contains(rbac.getScreenId()) && Boolean.TRUE.equals(rbac.getViewFlg())) {
                    allowed = true;
                    break;
                }
            }
            if (allowed) break;
        }

        if (!allowed) {
            response.setStatus(HttpServletResponse.SC_FORBIDDEN);
            response.setContentType("application/json");
            response.setCharacterEncoding("UTF-8");
            Map<String, Object> body = new LinkedHashMap<>();
            body.put("status", 403);
            body.put("error", "Access Denied");
            body.put("message", "You do not have permission to access this module.");
            body.put("screens", screenCodes);
            response.getWriter().write(objectMapper.writeValueAsString(body));
            return;
        }

        filterChain.doFilter(request, response);
    }

    /**
     * Resolves the request URI to screen codes.
     */
    private List<String> resolveScreenCodes(String requestUri) {
        if (requestUri == null) return null;

        // Normalize: strip leading /api/
        String path = requestUri;
        if (path.startsWith("/api/")) {
            path = path.substring(5);
        } else if (path.startsWith("/api")) {
            path = path.substring(4);
        }

        // Check if this is a public (un-guarded) path
        for (String pub : PUBLIC_PATHS) {
            if (path.equals(pub) || path.startsWith(pub + "/")) {
                return null;
            }
        }

        // Find the longest matching prefix in PATH_TO_SCREEN_CODES
        String bestMatch = null;
        List<String> bestCodes = null;
        for (Map.Entry<String, List<String>> entry : PATH_TO_SCREEN_CODES.entrySet()) {
            String prefix = entry.getKey();
            if (path.equals(prefix) || path.startsWith(prefix + "/")) {
                if (bestMatch == null || prefix.length() > bestMatch.length()) {
                    bestMatch = prefix;
                    bestCodes = entry.getValue();
                }
            }
        }
        return bestCodes;
    }
}
