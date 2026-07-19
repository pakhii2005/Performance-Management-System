# Enterprise Performance Management System (EPMS) MVP

An enterprise-grade performance management application designed to digitize, manage, and review employee annual performance and potential evaluations. Built on a clean, decoupled architecture utilizing a Spring Boot backend, a Supabase PostgreSQL database, and a Flutter cross-platform frontend.

---

## Project Overview

The EPMS is a structured, one-sided employee performance review system designed for three distinct corporate roles:
1. **CEO (Super Admin)**: Monitors the organization, views employee and manager directories, and prepares/registers review cycles.
2. **Manager**: Evaluates direct reports on both performance and potential indicators.
3. **Employee**: Reviews their own personal profile and completed evaluations read-only.

*Note: Self-assessments are not performed by employees. Managers are the sole submitters of evaluations, and they cannot review employees outside of their designated team reports.*

---

## Technology Stack

### Backend
- **Core Framework**: Java 17 / Spring Boot 3.x
- **ORM & Data**: Spring Data JPA & Hibernate
- **Database**: PostgreSQL (hosted on Supabase)
- **Validation**: Jakarta Bean Validation (`spring-boot-starter-validation`)
- **JSON Processing & Boilerplate**: Jackson, Lombok 1.18.46 (with JDK 25 compiler compatibility)
- **Build Tool**: Maven

### Frontend
- **Framework**: Flutter (Dart)
- **UI Design**: Modern Material 3 Theme with curated corporate Slate/Indigo colors
- **HTTP Client**: `http` package with timeout handlers
- **Formatters**: `intl` package for calendar dates formatting

---

## System Architecture

The application implements a strict **layered architecture** to separate concerns:

```
[ FRONTEND: Flutter ]
        ↓ (HTTP REST Calls over CORS)
[ BACKEND: Spring Boot Controllers ]
        ↓ (Data Transfer Objects - DTOs)
[ BACKEND: Spring Boot Services ] (Injects Business Rule Checks)
        ↓
[ BACKEND: Spring Boot Repositories ] (Spring Data JPA)
        ↓ (SQL Queries / JDBC)
[ DATABASE: Supabase PostgreSQL ]
```

---

## Folder Structure

### Backend
```
backend/
├── src/main/java/com/epms/
│   ├── controller/      # REST API Endpoints (CORS Enabled)
│   ├── dto/             # Data Transfer Objects for REST Request/Response payloads
│   ├── entity/          # JPA Hibernate Database Model definitions
│   ├── exception/       # ResourceNotFoundException & GlobalExceptionHandler
│   ├── repository/      # Spring Data JPA repositories interfacing with PostgreSQL
│   ├── service/         # Business validation logic and DTO mapping layers
│   └── DataInitializer  # Database seeder populating CEO, Managers, Employees, and active cycle
└── pom.xml              # Maven dependencies and compilation constraints
```

### Frontend
```
frontend/
├── lib/
│   ├── core/
│   │   ├── constants/   # API Connection constants and URLs
│   │   ├── network/     # ApiClient making HTTP requests
│   │   └── theme/       # Centralized Brand Colors (Slate, Indigo) and Material 3 ThemeData
│   ├── features/
│   │   ├── auth/        # Login Form UI
│   │   ├── dashboard/   # Dashboard widgets for CEO, Managers, Employees and Evaluation Forms
│   │   └── models/      # Client-side Dart models mapping JSON responses
│   └── main.dart        # Flutter entry point
└── pubspec.yaml         # Dart dependencies and assets configurations
```

---

## Database Entities

### 1. User
Represents corporate personnel.
- `id` (BigInt, PK)
- `firstName` (String)
- `lastName` (String)
- `email` (String, Unique)
- `password` (String, plain-text comparison)
- `role` (Enum: `CEO`, `MANAGER`, `EMPLOYEE`)
- `department` (String)
- `manager_id` (Self-referential FK to User, maps Employee -> Manager)

### 2. ReviewCycle
Represents annual evaluation cycles.
- `id` (BigInt, PK)
- `title` (String, Not Null)
- `description` (String)
- `startDate` (LocalDate, Not Null)
- `endDate` (LocalDate, Not Null)
- `status` (Enum: `ACTIVE`, `COMPLETED`, `ARCHIVED`)

### 3. Evaluation
Represents a submitted performance/potential review.
- `id` (BigInt, PK)
- `employee_id` (FK to User, Not Null)
- `manager_id` (FK to User, Not Null)
- `review_cycle_id` (FK to ReviewCycle, Not Null)
- `performanceRating` (Integer, 1 to 5, Not Null)
- `potentialRating` (Integer, 1 to 5, Not Null)
- `managerComments` (Text, Not Null)
- `submittedDate` (LocalDateTime, Not Null)

---

## API Endpoints

### 1. General & Auth
- `GET /api/health`: Health status.
- `POST /api/auth/login`: Plain credentials validation (returns `UserResponse` on success, `401 Unauthorized` on mismatch).

### 2. CEO Module
- `GET /api/ceo/metrics`: Count counters for total employees, managers, active cycles, and submitted reviews.
- `GET /api/users/employees`: List of all employee roles in the organization (including department and manager name).
- `GET /api/users/managers`: List of manager roles (including direct reports count).
- `POST /api/review-cycles`: Create a new review cycle (end date must not precede start date).
- `GET /api/review-cycles/{id}`: Fetch cycle details by ID.
- `GET /api/evaluations`: List of all evaluations (read-only logs).

### 3. Manager Module
- `GET /api/manager/{managerId}/metrics`: Returns direct assigned reports counts, pending reviews, completed reviews, and the active cycle title.
- `GET /api/manager/{managerId}/employees`: List of direct reports and their status (`PENDING` or `COMPLETED`) for the active cycle.
- `GET /api/manager/{managerId}/evaluations`: List of evaluations submitted by this manager.
- `POST /api/evaluations`: Submit employee evaluations. Injects validations:
  1. Employee must report directly to the manager.
  2. Employee can only have one evaluation filed per review cycle. Duplicate submissions throw `400 Bad Request` with message "Employee Already Evaluated".

### 4. Employee Module
- `GET /api/employees/{employeeId}/profile`: Fetch employee details (First/Last name, email, department, manager name).
- `GET /api/employees/{employeeId}/evaluations`: Fetch evaluations received by this employee (restricted strictly to their own ID).

---

## Instructions to Run

### Prerequisite Setup
1. Verify Java 17+ / JDK is installed and mapped in environment PATH.
2. Verify Flutter SDK is installed and `flutter doctor` runs cleanly.

### Running Backend (Spring Boot)
1. Navigate to the `backend/` directory:
   ```bash
   cd backend
   ```
2. Start the database seeder and backend server:
   ```bash
   ./mvnw spring-boot:run
   ```
3. The backend will seed the initial databases and start listening at `http://localhost:8080`.

### Running Frontend (Flutter)
1. Navigate to the `frontend/` directory:
   ```bash
   cd frontend
   ```
2. Fetch dependencies:
   ```bash
   flutter pub get
   ```
3. Run the development server (supports Web, Desktop, or Emulator):
   ```bash
   flutter run -d chrome  # or other target device
   ```

### Default Sample Credentials
- **CEO**: `sarah.ceo@epms.com` (Password: `password`)
- **Manager**: `marcus.manager@epms.com` (Password: `password`)
- **Employee**: `alice.employee@epms.com` (Password: `password`)
