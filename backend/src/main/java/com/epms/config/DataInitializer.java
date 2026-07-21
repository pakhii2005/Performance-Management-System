package com.epms.config;

import com.epms.entity.ReviewCycle;
import com.epms.entity.ReviewCycleStatus;
import com.epms.entity.Role;
import com.epms.entity.User;
import com.epms.repository.ReviewCycleRepository;
import com.epms.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.boot.CommandLineRunner;
import org.springframework.stereotype.Component;

import org.springframework.security.crypto.password.PasswordEncoder;

import java.time.LocalDate;
import java.util.List;

// @Component
@RequiredArgsConstructor
@Slf4j
public class DataInitializer implements CommandLineRunner {

    private final UserRepository userRepository;
    private final ReviewCycleRepository reviewCycleRepository;
    private final PasswordEncoder passwordEncoder;
    private final org.springframework.jdbc.core.JdbcTemplate jdbcTemplate;

    @Override
    public void run(String... args) throws Exception {
        // Ensure existing users have default values for the new columns
        try {
            jdbcTemplate.execute("UPDATE users SET enabled = true WHERE enabled IS NULL");
            jdbcTemplate.execute("UPDATE users SET password_reset_required = false WHERE password_reset_required IS NULL");
            jdbcTemplate.execute("UPDATE users SET failed_login_attempts = 0 WHERE failed_login_attempts IS NULL");
            log.info("Database migration completed: Default values populated for enabled, password_reset_required, and failed_login_attempts columns.");
        } catch (Exception e) {
            log.warn("Non-critical database migration skipped or already applied: {}", e.getMessage());
        }

        if (userRepository.count() == 0) {
            log.info("Database is empty. Populating sample data for Phase 2...");

            // 1. Create CEO
            User ceo = User.builder()
                    .firstName("Sarah")
                    .lastName("Jenkins")
                    .email("sarah.ceo@epms.com")
                    .password(passwordEncoder.encode("securePassword123"))
                    .role(Role.CEO)
                    .department("Executive Office")
                    .build();
            userRepository.save(ceo);
            log.info("CEO Sarah Jenkins seeded.");

            // 2. Create Manager
            User manager = User.builder()
                    .firstName("Marcus")
                    .lastName("Vance")
                    .email("marcus.manager@epms.com")
                    .password(passwordEncoder.encode("managerPassword456"))
                    .role(Role.MANAGER)
                    .department("Engineering Management")
                    .build();
            User savedManager = userRepository.save(manager);
            log.info("Manager Marcus Vance seeded.");

            // 3. Create 3 Employees assigned to the Manager
            User emp1 = User.builder()
                    .firstName("Alice")
                    .lastName("Smith")
                    .email("alice.emp@epms.com")
                    .password(passwordEncoder.encode("emp1Password"))
                    .role(Role.EMPLOYEE)
                    .department("Engineering")
                    .manager(savedManager)
                    .build();

            User emp2 = User.builder()
                    .firstName("Bob")
                    .lastName("Jones")
                    .email("bob.emp@epms.com")
                    .password(passwordEncoder.encode("emp2Password"))
                    .role(Role.EMPLOYEE)
                    .department("Engineering")
                    .manager(savedManager)
                    .build();

            User emp3 = User.builder()
                    .firstName("Charlie")
                    .lastName("Brown")
                    .email("charlie.emp@epms.com")
                    .password(passwordEncoder.encode("emp3Password"))
                    .role(Role.EMPLOYEE)
                    .department("Quality Assurance")
                    .manager(savedManager)
                    .build();

            userRepository.saveAll(List.of(emp1, emp2, emp3));
            log.info("Three employees (Alice, Bob, Charlie) assigned to Manager Marcus Vance seeded.");
        } else {
            log.info("Users exist in database. Skipping user seeding.");
        }

        if (reviewCycleRepository.count() == 0) {
            // 4. Create 1 Active Review Cycle
            ReviewCycle activeCycle = ReviewCycle.builder()
                    .title("Q3 Performance Review Cycle 2026")
                    .description("Standard mid-year performance reviews.")
                    .startDate(LocalDate.now().minusDays(15))
                    .endDate(LocalDate.now().plusDays(30))
                    .status(ReviewCycleStatus.ACTIVE)
                    .build();
            reviewCycleRepository.save(activeCycle);
            log.info("Active Review Cycle seeded.");
        } else {
            log.info("Review cycles exist in database. Skipping review cycle seeding.");
        }
    }
}
