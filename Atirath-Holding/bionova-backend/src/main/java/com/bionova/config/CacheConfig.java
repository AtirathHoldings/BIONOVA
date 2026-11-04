package com.bionova.config;

import com.github.benmanes.caffeine.cache.Caffeine;
import org.springframework.cache.CacheManager;
import org.springframework.cache.annotation.EnableCaching;
import org.springframework.cache.caffeine.CaffeineCacheManager;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

import java.util.concurrent.TimeUnit;

@Configuration
@EnableCaching
public class CacheConfig {

    public static final String CACHE_COMPANIES = "companies";
    public static final String CACHE_PLANTS = "plants";
    public static final String CACHE_DEPARTMENTS = "departments";
    public static final String CACHE_DESIGNATIONS = "designations";
    public static final String CACHE_EMPLOYEES = "employees";
    public static final String CACHE_EXTERNAL_EMPLOYEES = "externalEmployees";
    public static final String CACHE_RBAC_PERMS = "rbacPermissions";
    public static final String CACHE_ADMIN_DASHBOARD = "adminDashboard";
    public static final String CACHE_USER_DASHBOARD = "userDashboard";
    public static final String CACHE_PM_DASHBOARD = "pmDashboard";
    public static final String CACHE_APP_INIT = "appInitData";

    @Bean
    public CacheManager cacheManager() {
        CaffeineCacheManager cacheManager = new CaffeineCacheManager();

        // Default: 5 minutes TTL, max 2000 entries
        cacheManager.setCaffeine(Caffeine.newBuilder()
                .expireAfterWrite(5, TimeUnit.MINUTES)
                .maximumSize(2000)
                .recordStats());

        // Custom TTL for fast-moving Dashboard metrics: 45 seconds TTL
        cacheManager.registerCustomCache(CACHE_ADMIN_DASHBOARD,
                Caffeine.newBuilder().expireAfterWrite(45, TimeUnit.SECONDS).maximumSize(20).build());
        cacheManager.registerCustomCache(CACHE_USER_DASHBOARD,
                Caffeine.newBuilder().expireAfterWrite(45, TimeUnit.SECONDS).maximumSize(1000).build());
        cacheManager.registerCustomCache(CACHE_PM_DASHBOARD,
                Caffeine.newBuilder().expireAfterWrite(45, TimeUnit.SECONDS).maximumSize(100).build());

        // Master data: 15 minutes TTL
        cacheManager.registerCustomCache(CACHE_COMPANIES,
                Caffeine.newBuilder().expireAfterWrite(15, TimeUnit.MINUTES).maximumSize(500).build());
        cacheManager.registerCustomCache(CACHE_PLANTS,
                Caffeine.newBuilder().expireAfterWrite(15, TimeUnit.MINUTES).maximumSize(500).build());
        cacheManager.registerCustomCache(CACHE_DEPARTMENTS,
                Caffeine.newBuilder().expireAfterWrite(15, TimeUnit.MINUTES).maximumSize(500).build());
        cacheManager.registerCustomCache(CACHE_DESIGNATIONS,
                Caffeine.newBuilder().expireAfterWrite(15, TimeUnit.MINUTES).maximumSize(500).build());
        cacheManager.registerCustomCache(CACHE_RBAC_PERMS,
                Caffeine.newBuilder().expireAfterWrite(10, TimeUnit.MINUTES).maximumSize(1000).build());

        return cacheManager;
    }
}

