package com.epms.service;

import com.epms.dto.EvaluationRequest;
import com.epms.dto.EvaluationResponse;
import com.epms.entity.Evaluation;
import com.epms.entity.ReviewCycle;
import com.epms.entity.User;
import com.epms.exception.ResourceNotFoundException;
import com.epms.repository.EvaluationRepository;
import com.epms.repository.ReviewCycleRepository;
import com.epms.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
@Transactional(readOnly = true)
public class EvaluationService {

    private final EvaluationRepository evaluationRepository;
    private final UserRepository userRepository;
    private final ReviewCycleRepository reviewCycleRepository;

    @Transactional
    public EvaluationResponse save(EvaluationRequest request) {
        User employee = userRepository.findById(request.getEmployeeId())
                .orElseThrow(() -> new ResourceNotFoundException("Employee not found with ID: " + request.getEmployeeId()));

        User manager = userRepository.findById(request.getManagerId())
                .orElseThrow(() -> new ResourceNotFoundException("Manager not found with ID: " + request.getManagerId()));

        ReviewCycle reviewCycle = reviewCycleRepository.findById(request.getReviewCycleId())
                .orElseThrow(() -> new ResourceNotFoundException("Review cycle not found with ID: " + request.getReviewCycleId()));

        // Business Rule 1: A manager may evaluate only employees assigned to them
        if (employee.getManager() == null || !employee.getManager().getId().equals(manager.getId())) {
            throw new IllegalArgumentException("You can only evaluate employees assigned to you");
        }

        // Business Rule 2: Only one evaluation is allowed per employee per review cycle
        if (evaluationRepository.existsByEmployeeIdAndReviewCycleId(employee.getId(), reviewCycle.getId())) {
            throw new IllegalArgumentException("Employee Already Evaluated");
        }

        Evaluation evaluation = Evaluation.builder()
                .employee(employee)
                .manager(manager)
                .reviewCycle(reviewCycle)
                .performanceRating(request.getPerformanceRating())
                .potentialRating(request.getPotentialRating())
                .communicationScore(request.getCommunicationScore())
                .technicalSkillScore(request.getTechnicalSkillScore())
                .problemSolvingScore(request.getProblemSolvingScore())
                .leadershipScore(request.getLeadershipScore())
                .teamworkScore(request.getTeamworkScore())
                .adaptabilityScore(request.getAdaptabilityScore())
                .customerFocusScore(request.getCustomerFocusScore())
                .innovationScore(request.getInnovationScore())
                .managerComments(request.getManagerComments())
                .build();

        Evaluation savedEvaluation = evaluationRepository.save(evaluation);
        return mapToResponse(savedEvaluation);
    }

    public List<EvaluationResponse> findAll() {
        return evaluationRepository.findAll().stream()
                .map(this::mapToResponse)
                .collect(Collectors.toList());
    }

    public EvaluationResponse findById(Long id) {
        Evaluation evaluation = evaluationRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Evaluation not found with ID: " + id));
        return mapToResponse(evaluation);
    }

    public EvaluationResponse mapToResponse(Evaluation evaluation) {
        String empName = evaluation.getEmployee().getFirstName() + " " + evaluation.getEmployee().getLastName();
        String mgrName = evaluation.getManager().getFirstName() + " " + evaluation.getManager().getLastName();

        return EvaluationResponse.builder()
                .id(evaluation.getId())
                .employeeId(evaluation.getEmployee().getId())
                .employeeName(empName)
                .managerId(evaluation.getManager().getId())
                .managerName(mgrName)
                .reviewCycleId(evaluation.getReviewCycle().getId())
                .reviewCycleTitle(evaluation.getReviewCycle().getTitle())
                .performanceRating(evaluation.getPerformanceRating())
                .potentialRating(evaluation.getPotentialRating())
                .communicationScore(evaluation.getCommunicationScore())
                .technicalSkillScore(evaluation.getTechnicalSkillScore())
                .problemSolvingScore(evaluation.getProblemSolvingScore())
                .leadershipScore(evaluation.getLeadershipScore())
                .teamworkScore(evaluation.getTeamworkScore())
                .adaptabilityScore(evaluation.getAdaptabilityScore())
                .customerFocusScore(evaluation.getCustomerFocusScore())
                .innovationScore(evaluation.getInnovationScore())
                .managerComments(evaluation.getManagerComments())
                .submittedDate(evaluation.getSubmittedDate())
                .build();
    }
}
