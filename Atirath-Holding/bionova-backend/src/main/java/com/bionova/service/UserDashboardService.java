package com.bionova.service;

import com.bionova.config.CacheConfig;
import jakarta.persistence.EntityManager;
import jakarta.persistence.PersistenceContext;
import org.springframework.cache.annotation.CacheEvict;
import org.springframework.cache.annotation.Cacheable;
import org.springframework.stereotype.Service;

@Service
public class UserDashboardService {

    @PersistenceContext
    private EntityManager entityManager;

    @Cacheable(value = CacheConfig.CACHE_USER_DASHBOARD, key = "#empId")
    public String getRawUserDashboard(Long empId) {
        Object result = entityManager
                .createNativeQuery("SELECT get_user_dashboard(:empId)")
                .setParameter("empId", empId)
                .getSingleResult();
        return result != null ? result.toString() : "{}";
    }

    @Cacheable(value = "userMyTasks", key = "#empId")
    public String getRawMyTasks(Long empId) {
        Object result = entityManager
                .createNativeQuery("SELECT get_my_tasks_data(:empId)")
                .setParameter("empId", empId)
                .getSingleResult();
        return result != null ? result.toString() : "{}";
    }

    @CacheEvict(value = {CacheConfig.CACHE_USER_DASHBOARD, "userMyTasks"}, key = "#empId")
    public void evictUserDashboard(Long empId) {
    }

    @CacheEvict(value = {CacheConfig.CACHE_USER_DASHBOARD, "userMyTasks"}, allEntries = true)
    public void evictAllUserDashboards() {
    }
}

