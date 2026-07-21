package com.epms.repository;

import com.epms.entity.Role;
import com.epms.entity.User;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface UserRepository extends JpaRepository<User, Long> {
    Optional<User> findByEmail(String email);
    long countByRole(Role role);
    List<User> findByRole(Role role);
    long countByManagerId(Long managerId);
    List<User> findByManagerIdAndRole(Long managerId, Role role);
    long countByEnabled(boolean enabled);

    @org.springframework.data.jpa.repository.Query("SELECT u FROM User u WHERE " +
           "(:search IS NULL OR LOWER(u.firstName) LIKE :search OR LOWER(u.lastName) LIKE :search OR LOWER(CONCAT(u.firstName, ' ', u.lastName)) LIKE :search OR LOWER(u.email) LIKE :search) AND " +
           "(:role IS NULL OR u.role = :role) AND " +
           "(:department IS NULL OR LOWER(u.department) = :department) AND " +
           "(:enabled IS NULL OR u.enabled = :enabled)")
    List<User> searchAndFilterUsers(
        @org.springframework.data.repository.query.Param("search") String search,
        @org.springframework.data.repository.query.Param("role") Role role,
        @org.springframework.data.repository.query.Param("department") String department,
        @org.springframework.data.repository.query.Param("enabled") Boolean enabled
    );
}
