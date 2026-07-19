package com.epms.analytics.service;

import com.epms.analytics.dto.AnalyticsDTOs.*;
import com.epms.entity.Evaluation;
import com.epms.entity.Role;
import com.epms.entity.User;
import com.epms.repository.EvaluationRepository;
import com.epms.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.*;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
@Transactional(readOnly = true)
public class PerformanceStandardizationService {

    private final EvaluationRepository evaluationRepository;
    private final UserRepository userRepository;

    public CompanySummaryResponse getCompanySummary() {
        List<Evaluation> evaluations = evaluationRepository.findAll();
        long totalManagers = userRepository.countByRole(Role.MANAGER);
        long totalEmployees = userRepository.countByRole(Role.EMPLOYEE);

        if (evaluations.isEmpty()) {
            return CompanySummaryResponse.builder()
                    .companyAveragePerformance(0.0)
                    .companyAveragePotential(0.0)
                    .totalManagers(totalManagers)
                    .managersRequiringCalibration(0L)
                    .evaluationCompletionRate(0.0)
                    .overallStandardizationScore(100.0)
                    .build();
        }

        double companyAveragePerformance = evaluations.stream()
                .mapToInt(Evaluation::getPerformanceRating)
                .average()
                .orElse(0.0);

        double companyAveragePotential = evaluations.stream()
                .mapToInt(Evaluation::getPotentialRating)
                .average()
                .orElse(0.0);

        // Completion Rate: count of unique employees evaluated / total employees
        long uniqueEvaluatedCount = evaluations.stream()
                .map(e -> e.getEmployee().getId())
                .distinct()
                .count();

        double completionRate = totalEmployees > 0 
                ? ((double) uniqueEvaluatedCount / totalEmployees) * 100.0 
                : 0.0;
        completionRate = Math.min(100.0, Math.round(completionRate * 10.0) / 10.0);

        // Calculate manager scores to get "Requiring Calibration" count and overall score
        List<ManagerCalibrationResponse> managerCalibrations = getManagerCalibration();
        long reqCalibration = managerCalibrations.stream()
                .filter(m -> !"Balanced".equalsIgnoreCase(m.getCalibrationStatus()))
                .count();

        double overallStandardization = managerCalibrations.stream()
                .mapToInt(ManagerCalibrationResponse::getStandardizationScore)
                .average()
                .orElse(100.0);

        return CompanySummaryResponse.builder()
                .companyAveragePerformance(Math.round(companyAveragePerformance * 100.0) / 100.0)
                .companyAveragePotential(Math.round(companyAveragePotential * 100.0) / 100.0)
                .totalManagers(totalManagers)
                .managersRequiringCalibration(reqCalibration)
                .evaluationCompletionRate(completionRate)
                .overallStandardizationScore(Math.round(overallStandardization * 10.0) / 10.0)
                .build();
    }

    public List<ManagerCalibrationResponse> getManagerCalibration() {
        List<Evaluation> allEvaluations = evaluationRepository.findAll();
        List<User> managers = userRepository.findByRole(Role.MANAGER);

        if (allEvaluations.isEmpty()) {
            return managers.stream().map(m -> {
                String name = m.getFirstName() + " " + m.getLastName();
                return ManagerCalibrationResponse.builder()
                        .managerName(name)
                        .department(m.getDepartment())
                        .employeesEvaluated(0L)
                        .averagePerformanceRating(0.0)
                        .averagePotentialRating(0.0)
                        .differenceFromCompanyAverage(0.0)
                        .calibrationStatus("Balanced")
                        .consistencyStatus("Healthy Distribution")
                        .standardizationScore(100)
                        .scoreStatus("Excellent")
                        .ratingDistribution(createEmptyDistribution())
                        .build();
            }).collect(Collectors.toList());
        }

        double companyAveragePerformance = allEvaluations.stream()
                .mapToInt(Evaluation::getPerformanceRating)
                .average()
                .orElse(0.0);

        Map<User, List<Evaluation>> evaluationsByManager = allEvaluations.stream()
                .collect(Collectors.groupingBy(Evaluation::getManager));

        List<ManagerCalibrationResponse> result = new ArrayList<>();

        for (User manager : managers) {
            String name = manager.getFirstName() + " " + manager.getLastName();
            List<Evaluation> managerEvals = evaluationsByManager.getOrDefault(manager, Collections.emptyList());

            if (managerEvals.isEmpty()) {
                result.add(ManagerCalibrationResponse.builder()
                        .managerName(name)
                        .department(manager.getDepartment())
                        .employeesEvaluated(0L)
                        .averagePerformanceRating(0.0)
                        .averagePotentialRating(0.0)
                        .differenceFromCompanyAverage(0.0)
                        .calibrationStatus("Balanced")
                        .consistencyStatus("Healthy Distribution")
                        .standardizationScore(100)
                        .scoreStatus("Excellent")
                        .ratingDistribution(createEmptyDistribution())
                        .build());
                continue;
            }

            double avgPerformance = managerEvals.stream()
                    .mapToInt(Evaluation::getPerformanceRating)
                    .average()
                    .orElse(0.0);

            double avgPotential = managerEvals.stream()
                    .mapToInt(Evaluation::getPotentialRating)
                    .average()
                    .orElse(0.0);

            double diff = avgPerformance - companyAveragePerformance;
            String calibrationStatus = "Balanced";
            if (diff > 0.5) {
                calibrationStatus = "Generous";
            } else if (diff < -0.5) {
                calibrationStatus = "Strict";
            }

            // Consistency analysis (Low Rating Diversity vs Healthy Distribution)
            String consistencyStatus = "Healthy Distribution";
            double variance = 0.0;
            if (managerEvals.size() >= 2) {
                double mean = avgPerformance;
                double tempSum = 0.0;
                for (Evaluation e : managerEvals) {
                    tempSum += Math.pow(e.getPerformanceRating() - mean, 2);
                }
                variance = tempSum / managerEvals.size();
                if (variance < 0.2) {
                    consistencyStatus = "Low Rating Diversity";
                }
            }

            // Standardization Score calculation
            double score = 100.0;
            score -= Math.abs(diff) * 30.0; // Penalty for deviation
            if ("Low Rating Diversity".equals(consistencyStatus)) {
                score -= 20.0; // Penalty for lack of diversity
            }
            int finalScore = (int) Math.max(0, Math.min(100, Math.round(score)));

            String scoreStatus = "Excellent";
            if (finalScore < 70) {
                scoreStatus = "Calibration Recommended";
            } else if (finalScore < 90) {
                scoreStatus = "Needs Review";
            }

            // Rating distribution mapping
            Map<Integer, Double> distribution = calculateDistribution(managerEvals);

            result.add(ManagerCalibrationResponse.builder()
                    .managerName(name)
                    .department(manager.getDepartment())
                    .employeesEvaluated((long) managerEvals.size())
                    .averagePerformanceRating(Math.round(avgPerformance * 100.0) / 100.0)
                    .averagePotentialRating(Math.round(avgPotential * 100.0) / 100.0)
                    .differenceFromCompanyAverage(Math.round(diff * 100.0) / 100.0)
                    .calibrationStatus(calibrationStatus)
                    .consistencyStatus(consistencyStatus)
                    .standardizationScore(finalScore)
                    .scoreStatus(scoreStatus)
                    .ratingDistribution(distribution)
                    .build());
        }

        return result;
    }

    public List<DepartmentSummaryResponse> getDepartmentSummary() {
        List<Evaluation> evaluations = evaluationRepository.findAll();
        List<User> allEmployees = userRepository.findByRole(Role.EMPLOYEE);

        Map<String, List<User>> employeesByDept = allEmployees.stream()
                .filter(u -> u.getDepartment() != null)
                .collect(Collectors.groupingBy(User::getDepartment));

        Map<String, List<Evaluation>> evaluationsByDept = evaluations.stream()
                .filter(e -> e.getEmployee().getDepartment() != null)
                .collect(Collectors.groupingBy(e -> e.getEmployee().getDepartment()));

        Set<String> departments = new HashSet<>();
        departments.addAll(employeesByDept.keySet());
        departments.addAll(evaluationsByDept.keySet());

        List<DepartmentSummaryResponse> result = new ArrayList<>();

        for (String dept : departments) {
            List<Evaluation> deptEvals = evaluationsByDept.getOrDefault(dept, Collections.emptyList());
            List<User> deptEmps = employeesByDept.getOrDefault(dept, Collections.emptyList());

            if (deptEvals.isEmpty()) {
                result.add(DepartmentSummaryResponse.builder()
                        .departmentName(dept)
                        .averagePerformance(0.0)
                        .averagePotential(0.0)
                        .completionRate(0.0)
                        .employeesEvaluated(0L)
                        .build());
                continue;
            }

            double avgPerformance = deptEvals.stream()
                    .mapToInt(Evaluation::getPerformanceRating)
                    .average()
                    .orElse(0.0);

            double avgPotential = deptEvals.stream()
                    .mapToInt(Evaluation::getPotentialRating)
                    .average()
                    .orElse(0.0);

            // Completion rate within department
            long uniqueEvaluated = deptEvals.stream()
                    .map(e -> e.getEmployee().getId())
                    .distinct()
                    .count();

            double completionRate = deptEmps.isEmpty() ? 0.0 : ((double) uniqueEvaluated / deptEmps.size()) * 100.0;
            completionRate = Math.min(100.0, Math.round(completionRate * 10.0) / 10.0);

            result.add(DepartmentSummaryResponse.builder()
                    .departmentName(dept)
                    .averagePerformance(Math.round(avgPerformance * 100.0) / 100.0)
                    .averagePotential(Math.round(avgPotential * 100.0) / 100.0)
                    .completionRate(completionRate)
                    .employeesEvaluated((long) deptEvals.size())
                    .build());
        }

        return result;
    }

    public List<String> getExecutiveInsights() {
        List<Evaluation> evaluations = evaluationRepository.findAll();
        if (evaluations.isEmpty()) {
            return List.of("Not enough evaluation data is available to generate executive insights.");
        }

        List<String> insights = new ArrayList<>();
        List<DepartmentSummaryResponse> depts = getDepartmentSummary();
        List<ManagerCalibrationResponse> managers = getManagerCalibration();
        CompanySummaryResponse company = getCompanySummary();

        // 1. Highest average performance department
        depts.stream()
                .filter(d -> d.getEmployeesEvaluated() > 0)
                .max(Comparator.comparingDouble(DepartmentSummaryResponse::getAveragePerformance))
                .ifPresent(topDept -> insights.add(
                        String.format("%s has the highest average performance rating of %.1f.", 
                                topDept.getDepartmentName(), topDept.getAveragePerformance())
                ));

        // 2. Department scoring below company average
        double companyAvg = company.getCompanyAveragePerformance();
        List<DepartmentSummaryResponse> belowAvgDepts = depts.stream()
                .filter(d -> d.getEmployeesEvaluated() > 0 && d.getAveragePerformance() < (companyAvg - 0.2))
                .collect(Collectors.toList());

        if (!belowAvgDepts.isEmpty()) {
            String deptNames = belowAvgDepts.stream()
                    .map(DepartmentSummaryResponse::getDepartmentName)
                    .collect(Collectors.joining(", "));
            insights.add(String.format("%s managers tend to score employees below the company average.", deptNames));
        } else {
            insights.add("All major department score averages are aligned closely with the company average.");
        }

        // 3. Managers requiring calibration
        long calibrationNeededCount = company.getManagersRequiringCalibration();
        if (calibrationNeededCount > 0) {
            insights.add(String.format("%d manager%s require%s calibration due to rating deviations.", 
                    calibrationNeededCount, 
                    calibrationNeededCount == 1 ? "" : "s", 
                    calibrationNeededCount == 1 ? "s" : ""));
        } else {
            insights.add("Zero managers currently fall outside the standard calibration thresholds.");
        }

        // 4. Most balanced department distribution (closest to company average)
        depts.stream()
                .filter(d -> d.getEmployeesEvaluated() > 0)
                .min(Comparator.comparingDouble(d -> Math.abs(d.getAveragePerformance() - companyAvg)))
                .ifPresent(balancedDept -> insights.add(
                        String.format("%s demonstrates the most balanced evaluation distribution.", 
                                balancedDept.getDepartmentName())
                ));

        return insights;
    }

    private Map<Integer, Double> createEmptyDistribution() {
        Map<Integer, Double> dist = new HashMap<>();
        for (int i = 1; i <= 5; i++) {
            dist.put(i, 0.0);
        }
        return dist;
    }

    private Map<Integer, Double> calculateDistribution(List<Evaluation> evals) {
        Map<Integer, Double> dist = createEmptyDistribution();
        if (evals.isEmpty()) return dist;

        Map<Integer, Long> counts = evals.stream()
                .collect(Collectors.groupingBy(Evaluation::getPerformanceRating, Collectors.counting()));

        for (int i = 1; i <= 5; i++) {
            long count = counts.getOrDefault(i, 0L);
            double percentage = ((double) count / evals.size()) * 100.0;
            dist.put(i, Math.round(percentage * 10.0) / 10.0);
        }

        return dist;
    }
}
