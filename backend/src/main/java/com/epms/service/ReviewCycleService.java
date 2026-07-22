package com.epms.service;

import com.epms.dto.ReviewCycleRequest;
import com.epms.dto.ReviewCycleResponse;
import com.epms.dto.ReviewCycleDetailsResponse;
import com.epms.entity.ReviewCycle;
import com.epms.entity.User;
import com.epms.exception.ResourceNotFoundException;
import com.epms.repository.ReviewCycleRepository;
import com.epms.repository.UserRepository;
import com.epms.repository.EvaluationRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
@Transactional(readOnly = true)
public class ReviewCycleService {

    private final ReviewCycleRepository reviewCycleRepository;
    private final UserRepository userRepository;
    private final EvaluationRepository evaluationRepository;

    @Transactional
    public ReviewCycleResponse save(ReviewCycleRequest request) {
        if (request.getEndDate().isBefore(request.getStartDate())) {
            throw new IllegalArgumentException("End date cannot be before start date");
        }

        User manager = null;
        if (request.getManagerId() != null) {
            manager = userRepository.findById(request.getManagerId())
                    .orElseThrow(() -> new ResourceNotFoundException("Manager not found with ID: " + request.getManagerId()));
        }

        ReviewCycle cycle = ReviewCycle.builder()
                .title(request.getTitle())
                .description(request.getDescription())
                .startDate(request.getStartDate())
                .endDate(request.getEndDate())
                .status(request.getStatus())
                .manager(manager)
                .build();

        ReviewCycle savedCycle = reviewCycleRepository.save(cycle);
        return mapToResponse(savedCycle);
    }

    @Transactional
    public ReviewCycleResponse update(Long id, ReviewCycleRequest request) {
        ReviewCycle cycle = reviewCycleRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Review cycle not found with ID: " + id));

        if (request.getEndDate().isBefore(request.getStartDate())) {
            throw new IllegalArgumentException("End date cannot be before start date");
        }

        User manager = null;
        if (request.getManagerId() != null) {
            manager = userRepository.findById(request.getManagerId())
                    .orElseThrow(() -> new ResourceNotFoundException("Manager not found with ID: " + request.getManagerId()));
        }

        cycle.setTitle(request.getTitle());
        cycle.setDescription(request.getDescription());
        cycle.setStartDate(request.getStartDate());
        cycle.setEndDate(request.getEndDate());
        cycle.setStatus(request.getStatus());
        cycle.setManager(manager);

        ReviewCycle savedCycle = reviewCycleRepository.save(cycle);
        return mapToResponse(savedCycle);
    }

    public List<ReviewCycleResponse> findAll() {
        String email = org.springframework.security.core.context.SecurityContextHolder.getContext().getAuthentication().getName();
        User currentUser = userRepository.findByEmail(email)
                .orElseThrow(() -> new ResourceNotFoundException("User not found: " + email));

        List<ReviewCycle> cycles;
        if (currentUser.getRole() == com.epms.entity.Role.CEO) {
            cycles = reviewCycleRepository.findAll();
        } else if (currentUser.getRole() == com.epms.entity.Role.MANAGER) {
            cycles = reviewCycleRepository.findAll().stream()
                    .filter(c -> c.getManager() != null && c.getManager().getId().equals(currentUser.getId()))
                    .collect(Collectors.toList());
        } else {
            cycles = List.of();
        }

        return cycles.stream()
                .map(this::mapToResponse)
                .collect(Collectors.toList());
    }

    public ReviewCycleResponse findById(Long id) {
        ReviewCycle cycle = reviewCycleRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Review cycle not found with ID: " + id));

        String email = org.springframework.security.core.context.SecurityContextHolder.getContext().getAuthentication().getName();
        User currentUser = userRepository.findByEmail(email)
                .orElseThrow(() -> new ResourceNotFoundException("User not found: " + email));

        if (currentUser.getRole() == com.epms.entity.Role.MANAGER) {
            if (cycle.getManager() == null || !cycle.getManager().getId().equals(currentUser.getId())) {
                throw new org.springframework.security.access.AccessDeniedException("You do not have access to this review cycle");
            }
        } else if (currentUser.getRole() != com.epms.entity.Role.CEO) {
            throw new org.springframework.security.access.AccessDeniedException("Access denied");
        }

        return mapToResponse(cycle);
    }

    public ReviewCycleDetailsResponse getDetails(Long id) {
        ReviewCycle cycle = reviewCycleRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Review cycle not found with ID: " + id));

        String email = org.springframework.security.core.context.SecurityContextHolder.getContext().getAuthentication().getName();
        User currentUser = userRepository.findByEmail(email)
                .orElseThrow(() -> new ResourceNotFoundException("User not found: " + email));

        if (currentUser.getRole() == com.epms.entity.Role.MANAGER) {
            if (cycle.getManager() == null || !cycle.getManager().getId().equals(currentUser.getId())) {
                throw new org.springframework.security.access.AccessDeniedException("You do not have access to this review cycle");
            }
        } else if (currentUser.getRole() != com.epms.entity.Role.CEO) {
            throw new org.springframework.security.access.AccessDeniedException("Access denied");
        }

        User manager = cycle.getManager();
        List<User> employees = List.of();
        if (manager != null) {
            employees = userRepository.findByManagerIdAndRole(manager.getId(), com.epms.entity.Role.EMPLOYEE);
        }

        List<ReviewCycleDetailsResponse.EmployeeStatus> employeeStatusList = new java.util.ArrayList<>();
        int reviewsCompleted = 0;
        int reviewsPending = 0;
        int selfAssessmentsPending = 0;

        for (User emp : employees) {
            boolean evaluated = evaluationRepository.existsByEmployeeIdAndReviewCycleId(emp.getId(), cycle.getId());
            String status = "Not Started";
            if (evaluated) {
                status = "Completed";
                reviewsCompleted++;
            } else {
                reviewsPending++;
                // Deterministic simulation for demo/self-assessment status:
                if (emp.getId() % 3 == 0) {
                    status = "Self Assessment Completed";
                } else if (emp.getId() % 3 == 1) {
                    status = "Manager Review Pending";
                } else {
                    status = "Not Started";
                    selfAssessmentsPending++;
                }
            }

            employeeStatusList.add(new ReviewCycleDetailsResponse.EmployeeStatus(
                    emp.getId(),
                    emp.getFirstName(),
                    emp.getLastName(),
                    emp.getEmail(),
                    emp.getDepartment(),
                    status
            ));
        }

        int totalEmployees = employees.size();
        double completionPercentage = totalEmployees > 0 ? ((double) reviewsCompleted / totalEmployees) * 100 : 0.0;

        return ReviewCycleDetailsResponse.builder()
                .id(cycle.getId())
                .title(cycle.getTitle())
                .description(cycle.getDescription())
                .startDate(cycle.getStartDate())
                .endDate(cycle.getEndDate())
                .status(cycle.getStatus())
                .createdAt(cycle.getCreatedAt())
                .managerId(manager != null ? manager.getId() : null)
                .managerName(manager != null ? (manager.getFirstName() + " " + manager.getLastName()) : "Unassigned")
                .totalEmployees(totalEmployees)
                .reviewsCompleted(reviewsCompleted)
                .reviewsPending(reviewsPending)
                .selfAssessmentsPending(selfAssessmentsPending)
                .completionPercentage(completionPercentage)
                .employees(employeeStatusList)
                .build();
    }

    public ReviewCycleResponse mapToResponse(ReviewCycle cycle) {
        return ReviewCycleResponse.builder()
                .id(cycle.getId())
                .title(cycle.getTitle())
                .description(cycle.getDescription())
                .startDate(cycle.getStartDate())
                .endDate(cycle.getEndDate())
                .status(cycle.getStatus())
                .createdAt(cycle.getCreatedAt())
                .managerId(cycle.getManager() != null ? cycle.getManager().getId() : null)
                .managerName(cycle.getManager() != null ? (cycle.getManager().getFirstName() + " " + cycle.getManager().getLastName()) : "Unassigned")
                .build();
    }
}
