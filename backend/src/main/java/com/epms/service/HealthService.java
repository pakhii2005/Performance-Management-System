package com.epms.service;

import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Service;

@Service
@RequiredArgsConstructor
@Slf4j
public class HealthService {

    private final JdbcTemplate jdbcTemplate;

    public boolean isDatabaseConnected() {
        try {
            log.info("Verifying database connection via SQL check...");
            Integer result = jdbcTemplate.queryForObject("SELECT 1", Integer.class);
            boolean isConnected = result != null && result == 1;
            if (isConnected) {
                log.info("Database connection successfully verified.");
            }
            return isConnected;
        } catch (Exception e) {
            log.error("Database connection check failed: {}", e.getMessage());
            return false;
        }
    }
}
