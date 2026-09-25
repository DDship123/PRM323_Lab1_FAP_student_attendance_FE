# 📚 FE Project Documentation — Attendly (FAP Student Attendance)

> **Tài liệu dành cho lập trình viên mới** tham gia dự án Frontend Flutter.  
> Cập nhật lần cuối: 2026-09-25

---

## 1. Tổng quan dự án

### 1.1. Mô tả

**Attendly** là hệ thống điểm danh sinh viên FPT University dựa trên mã QR động (TOTP) và xác thực mạng Wi-Fi đa tầng.
Ứng dụng Frontend được xây dựng bằng **Flutter** (hỗ trợ Web, Windows, Android/iOS Mobile), kết nối với Backend Spring Boot qua REST API và SSE (Server-Sent Events).

### 1.2. Tech Stack

| Thành phần | Công nghệ | Phiên bản |
|---|---|---|
| Framework | Flutter | SDK ≥ 3.13.3 |
| Ngôn ngữ | Dart | (đi kèm Flutter SDK) |
| Routing | `go_router` | 15.1.2 |
| HTTP Client | `http` | 1.2.2 |
| QR Code | `qr_flutter` | 4.1.0 |
| Font | `google_fonts` (Inter) | 6.2.1 |
| Local Storage | `shared_preferences` | 2.3.2 |
| State Management | `ChangeNotifier` (built-in) | — |

### 1.3. Backend

- **Framework**: Spring Boot (Java 21, MySQL)
- **Base URL**: `http://localhost:8080`
- **Swagger**: `http://localhost:8080/swagger-ui.html`
- **Tài liệu API chi tiết**: xem file [`BE_API_ENDPOINTS.md`](BE_API_ENDPOINTS.md)
- **Tổng quan Backend**: xem file [`BE_PROJECT_OVERVIEW.md`](BE_PROJECT_OVERVIEW.md)
- **Hướng dẫn Tích hợp Quét QR & Wi-Fi**: xem file [`FRONTEND_QR_ATTENDANCE_INTEGRATION_GUIDE.md`](FRONTEND_QR_ATTENDANCE_INTEGRATION_GUIDE.md)

### 1.4. Vai trò người dùng

| Role | Mô tả | Chức năng chính |
|---|---|---|
| `LECTURER` | Giảng viên | Đăng nhập / đăng ký, cập nhật thông tin tài khoản, tạo môn học & lớp học phần, **cập nhật môn học**, tạo phiên điểm danh (tùy chỉnh chu kỳ mã QR động `qrRefreshSeconds` từ 10s–60s, mặc định 20s; tự động nhận diện IP Wi-Fi), hiển thị mã QR động qua SSE/Polling với thanh đếm ngược, xem kết quả điểm danh thời gian thực, quản lý danh sách sinh viên & import sinh viên từ Excel |
| `STUDENT` | Sinh viên | Đăng nhập / đăng ký, cập nhật thông tin tài khoản, **giao diện Mobile chuyên dụng với Bottom Navigation Bar** (4 tab: Buổi học, Tìm môn, Quét QR, Lịch sử), quét mã QR động TOTP qua camera hoặc nhập mã PIN 6 số, tự động lọc BSSID Wi-Fi ảo, nhận diện lỗi an ninh mạng thân thiện, tìm kiếm & đăng ký khóa học, **xem nhật ký chuyên cần cá nhân (lọc Từ ngày - Đến ngày, theo môn, theo trạng thái; thống kê tỷ lệ % chuyên cần và danh sách dạng Card Mobile)** |
| `ADMIN` | Quản trị viên | Toàn quyền (xử lý như LECTURER trên FE) |

---

## 2. Kiến trúc dự án

### 2.1. Pattern: Feature-First MVVM

Dự án áp dụng kiến trúc **Feature-First** kết hợp **MVVM** (Model-View-ViewModel):

```
lib/
├── main.dart                    # Entry point
├── app.dart                     # Root widget (MaterialApp.router)
├── core/                        # Thư viện dùng chung toàn app
│   ├── constants/               # Hằng số, endpoint API
│   ├── network/                 # HTTP client (ApiClient, ApiResponse, ApiException)
│   ├── storage/                 # Lưu trữ cục bộ (JWT token, user data)
│   └── theme/                   # Design system (Colors, TextStyles, Theme)
├── features/                    # Các feature module
│   ├── auth/                    # Xác thực (Login, Register)
│   ├── courses/                 # Quản lý khóa học
│   ├── schedule/                # Lịch học & phiên điểm danh
│   ├── attendance/              # Điểm danh (QR, kết quả, quản lý)
│   └── student/                 # Màn hình dành riêng Sinh viên
├── routing/                     # Cấu hình GoRouter
└── shared/                      # Widget & layout dùng chung
    ├── layouts/                 # DesktopScaffold (sidebar + content)
    └── widgets/                 # CustomTextField, PrimaryButton, ...
```

### 2.2. Cấu trúc mỗi Feature Module

Mỗi feature tuân theo cấu trúc:

```
features/<feature_name>/
├── data/
│   ├── models/                  # Data classes (fromJson/toJson)
│   └── repositories/            # Giao tiếp API (singleton pattern)
└── presentation/
    ├── controllers/             # ChangeNotifier (ViewModel / State)
    └── screens/                 # Widget UI (StatefulWidget)
```

### 2.3. Flow dữ liệu

```
Screen (UI) → Controller (ChangeNotifier) → Repository (Singleton) → ApiClient → Backend REST API
                    ↕                              ↕
              notifyListeners()              Model.fromJson()
```

---

## 3. Các module chi tiết

### 3.1. `core/` — Thư viện dùng chung

#### `core/constants/api_endpoints.dart`
Chứa tất cả URL endpoint REST API. Khi thêm endpoint mới, **bắt buộc** khai báo ở đây.
Tự động xác định `baseUrl` linh hoạt theo môi trường:
- Nếu chạy trên Web / Mobile Browser: Trích xuất `Uri.base.host` để tự động trỏ đến IP máy chủ backend (ví dụ `http://192.168.1.101:8080`).
- Mặc định: `http://localhost:8080`.

Bổ sung các endpoint mới:
- `lecturerDashboardStats`: `/api/lecturer/dashboard-stats` (lấy toàn bộ thống kê 3 thẻ KPI cho Giảng viên).
- `lecturerStatsAlias`: `/api/lecturer/stats` (alias dự phòng).

#### `core/constants/app_constants.dart`
Hằng số ứng dụng (tên app, version, branding text).

#### `core/utils/network_info.dart`
Tiện ích phát hiện địa chỉ mạng đa nền tảng (Cross-platform IP Detection):
- `network_info_io.dart` (Windows / Mobile Native): Sử dụng `NetworkInterface.list()` để tự động tìm địa chỉ IPv4 trong mạng LAN (ví dụ `192.168.1.101`) và gán cổng mặc định `5000`.
- `network_info_web.dart` (Web Browser): Sử dụng `Uri.base.host` và `Uri.base.port` để xác định địa chỉ máy chủ web hiện tại.
- Hàm chính: `NetworkInfo.getLocalHost({int port = 5000})` trả về chuỗi `<IP_LAN>:<PORT>`.

#### `core/network/api_client.dart`
HTTP client singleton xử lý toàn bộ request. Các phương thức:

| Method | Mô tả |
|---|---|
| `get(url, {queryParams, requiresAuth})` | GET request |
| `post(url, {body, requiresAuth})` | POST request |
| `put(url, {body, requiresAuth})` | PUT request |

**Đặc điểm quan trọng:**
- Tự động gắn `Authorization: Bearer <token>` khi `requiresAuth = true`
- Response luôn được parse thành `ApiResponse<dynamic>`
- Lỗi được throw dưới dạng `ApiException` (chứa `statusCode` và `message`)
- Timeout: 15 giây

#### `core/storage/token_storage.dart`
Quản lý JWT token và user data bằng `SharedPreferences`.

| Method | Mô tả |
|---|---|
| `saveToken(token)` | Lưu JWT |
| `getToken()` | Đọc JWT |
| `saveUser(json)` | Lưu user info |
| `getUser()` | Đọc user info |
| `isLoggedIn()` | Kiểm tra đăng nhập |
| `clear()` | Xóa tất cả (logout) |

#### `core/theme/`
Design system gồm 3 file:

| File | Nội dung |
|---|---|
| `app_colors.dart` | Bảng màu (primary, accent, status, sidebar, FPT brand) |
| `app_text_styles.dart` | Typography (h1-h4, body, label, caption, button, stat) |
| `app_theme.dart` | ThemeData tổng hợp cho Material 3 |

---

### 3.2. `features/auth/` — Xác thực

#### Models
| Class | File | Mô tả |
|---|---|---|
| `UserModel` | `user_model.dart` | Thông tin user (userId, username, fapCode, fullName, email, roleId) |
| `LoginRequest` | `auth_models.dart` | DTO đăng nhập |
| `RegisterRequest` | `auth_models.dart` | DTO đăng ký |
| `AuthResponseModel` | `auth_models.dart` | Response đăng nhập (token + user) |

**`UserModel` helpers:**
- `isLecturer`, `isStudent`, `isAdmin` — kiểm tra role
- `roleDisplay` — tên role hiển thị tiếng Việt

#### Repository — `AuthRepository` (Singleton)
| Method | API | Mô tả |
|---|---|---|
| `login(LoginRequest)` | POST `/api/auth/login` | Đăng nhập + lưu token |
| `register(RegisterRequest)` | POST `/api/auth/register` | Đăng ký |
| `updateProfile({username, fullName, phoneNumber, gender})` | PUT `/api/users/profile` | Cập nhật thông tin cá nhân (Tên đăng nhập, họ tên, số điện thoại, giới tính) |
| `changePassword({oldPassword, newPassword})` | PUT `/api/users/change-password` | Đổi mật khẩu tài khoản |
| `getCurrentUser()` | (Local) | Đọc user từ SharedPreferences |
| `logout()` | (Local) | Xóa token + user |

#### Controller — `AuthController` (Singleton, ChangeNotifier)
| Property | Mô tả |
|---|---|
| `currentUser` | User đang đăng nhập (null = chưa login) |
| `isLoading` | Đang xử lý request |
| `errorMessage` | Lỗi hiện tại |
| `successMessage` | Thông báo thành công |

| Method | Mô tả |
|---|---|
| `init()` | Khôi phục phiên từ storage (gọi ở `main.dart`) |
| `login({username, password})` | Đăng nhập |
| `register(RegisterRequest)` | Đăng ký |
| `updateProfile({username, fullName, phoneNumber, gender})` | Cập nhật tên đăng nhập (Username), họ tên, số điện thoại, giới tính |
| `changePassword({oldPassword, newPassword})` | Đổi mật khẩu |
| `logout()` | Đăng xuất |

#### Screens & Dialogs
- `AuthDesktopScreen`: Màn hình Login/Register cho Desktop & Mobile. Có 2 tab: Đăng nhập & Đăng ký.
- `UserProfileDialog`: Hộp thoại modal cập nhật thông tin tài khoản (cho phép sửa **Tên đăng nhập/Username**, Họ và tên, Số điện thoại, Giới tính) và Đổi mật khẩu tài khoản.

---

### 3.3. `features/courses/` — Quản lý khóa học

#### Model — `CourseModel`
```dart
CourseModel {
  courseId, subjectCode, className, semester, lecturerId, lecturerName, createdAt
}
```
- `displayName` → `"PRM392 · SE1701"`
- `lecturerDisplay` → tên GV hoặc `"Chưa phân công"`

Các DTO:
- `CourseCreateRequest`: DTO tạo khóa học mới (`subjectCode`, `className`, `semester`, `password`, `lecturerId`).
- `CourseUpdateRequest`: DTO cập nhật khóa học (`subjectCode`, `className`, `semester`, `password`, `lecturerId`).
- `CourseRegisterRequest`: DTO sinh viên đăng ký khóa học (`courseId`, `userId`, `password`).
- `LecturerDashboardStatsModel`: DTO thống kê tổng quan của Giảng viên (`totalCourses`, `totalRegisteredStudents`, `activeSemestersCount`, `activeSemesters`, `totalSessions`, `recentCourses`).
- `LecturerRecentCourseModel`: Model khóa học gần đây kèm sĩ số sinh viên (`studentCount`).

#### Repository — `CourseRepository` (Singleton)

| Method | API | Mô tả |
|---|---|---|
| `getLecturerDashboardStats({lecturerId?})` | GET `/api/lecturer/dashboard-stats` (alias `/stats`) | Lấy số liệu thống kê Dashboard GV (Role: `LECTURER`, `ADMIN`) |
| `getMyCourses({...})` | GET `/api/courses/my-courses` | Lấy danh sách khóa học của người dùng (Hỗ trợ cả `STUDENT` và `LECTURER`) |
| `getCourses({lecturerId?})` | GET `/api/courses` | Lấy DS khóa học (lọc theo GV) |
| `getCourseById(id)` | GET `/api/courses/{id}` | Chi tiết khóa học |
| `createCourse(request)` | POST `/api/courses` | Tạo mới khóa học |
| `updateCourse(courseId, request)` | PUT `/api/courses/{id}` | Cập nhật thông tin khóa học (Mục 2.4) |
| `deleteCourse(courseId)` | DELETE `/api/courses/{id}` | Xóa khóa học (Mục 2.5) |
| `searchCourses({...})` | GET `/api/courses/search` | Tìm kiếm (fallback client-side nếu 404) |
| `registerCourse(request)` | POST `/api/courses/register` | SV đăng ký (fallback `/enroll` → `/enrollments`) |

#### Controller — `CourseController` (ChangeNotifier, Singleton)
Quản lý danh sách khóa học cho Giảng viên:
- `loadCourses()`: Tải danh sách khóa học của giảng viên hiện tại.
- `createCourse(...)`: Tạo môn học mới.
- `updateCourse(...)`: Cập nhật thông tin môn học (`PUT /api/courses/{id}`) và tự động cập nhật danh sách local.
- `searchQuery`, `filterSemester`: Tìm kiếm và lọc theo học kỳ.

#### Screens & Widgets
| Screen / Widget | File | Route | Mô tả |
|---|---|---|---|
| `LecturerDashboardScreen` | `lecturer_dashboard_screen.dart` | `/dashboard` | Trang tổng quan chính của Giảng viên: Hiển thị 3 chỉ số then chốt (*Lớp học phần phụ trách*, *Tổng sinh viên đã đăng ký*, *Học kỳ hoạt động*, kèm *Buổi điểm danh*), các lối tắt tác vụ nhanh và bảng tóm tắt danh sách lớp học phần |
| `LecturerCoursesScreen` | `lecturer_courses_screen.dart` | `/courses` | DS khóa học GV: Thẻ môn học trực quan, nút "Sửa" nổi bật, menu 3 chấm (`⋮`), nút Tạo QR, nút xem danh sách SV & import Excel |
| `CreateCourseScreen` | `create_course_screen.dart` | `/courses/create` | Form tạo môn học và lớp học phần |
| `ImportStudentsScreen` | `import_students_screen.dart` | `/courses/import` | Upload file Excel danh sách sinh viên vào lớp; tích hợp thẻ thông báo tài khoản mặc định nổi bật (**MSSV làm Tên đăng nhập & Mật khẩu mặc định là `A123456`** kèm nút copy) và hiển thị kết quả import |
| `EditCourseDialog` | `widgets/edit_course_dialog.dart` | Modal Dialog | Hộp thoại cập nhật thông tin môn học (Mã môn, Lớp, Học kỳ, Đổi mật khẩu) |
| `CourseStudentsDialog` | `widgets/course_students_dialog.dart` | Modal Dialog | Hộp thoại xem DS sinh viên đã đăng ký trong lớp, tìm kiếm, reload và nút Cập nhật môn học trực tiếp |

---

### 3.4. `features/schedule/` — Lịch học & Phiên điểm danh

#### Model — `AttendanceSessionModel`
```dart
AttendanceSessionModel {
  sessionId, courseId, slotNumber, sessionCode, qrCodeSecret, qrCodeBase64,
  roomNetworkIp, hostPublicIp, roomBssid, currentQrToken,
  tokenRemainingSeconds, tokenIntervalSeconds, qrRefreshSeconds,
  expiredAt, status, createdAt
}
```
- `isOpen`, `isClosed` — trạng thái phiên
- `hasExpired` — kiểm tra buổi học đã quá hạn kết thúc chưa
- `expireAt`, `sessionDate` — datetime helpers tiện ích
- `tokenIntervalSeconds`, `qrRefreshSeconds` — chu kỳ làm mới mã QR động TOTP (mặc định 20 giây per Section 4.1)

#### DTOs
- `SessionCreateRequest`: DTO gửi lên khi tạo phiên (`courseId`, `slotNumber`, `expiredAt`, `qrRefreshSeconds`, `roomNetworkIp`, `roomBssid`, `sessionDate`, `durationMinutes`).
- `DynamicQrTokenModel`: DTO tiếp nhận dữ liệu QR động từ SSE `/api/sessions/{sessionId}/qr-stream` hoặc Polling `/api/sessions/{sessionId}/current-token` (`sessionId`, `currentQrToken`, `tokenRemainingSeconds`, `tokenIntervalSeconds`, `qrRefreshSeconds`, `qrCodeBase64`, `status`).

#### Repository — `SessionRepository` (Singleton)

| Method | API | Mô tả |
|---|---|---|
| `createSession(request)` | POST `/api/sessions` | Tạo phiên + sinh mã TOTP bí mật |
| `getSessionById(id)` | GET `/api/sessions/{id}` | Chi tiết phiên điểm danh |
| `getSessionsByCourse(courseId)` | GET `/api/sessions/course/{courseId}` | DS phiên theo khóa học |
| `getCurrentToken(sessionId)` | GET `/api/sessions/{id}/current-token` | Polling mã QR động và số giây đếm ngược |
| `streamQrTokens(sessionId)` | GET `/api/sessions/{id}/qr-stream` | Stream realtime qua SSE (`text/event-stream`) |
| `closeSession(id)` | PUT `/api/sessions/{id}/close` | Đóng phiên điểm danh |

#### Controller — `SessionController` (ChangeNotifier, Singleton)
- Quản lý toàn bộ vòng đời phiên điểm danh của Giảng viên.
- `createSession(...)`: Tạo phiên mới, hỗ trợ tùy chỉnh `qrRefreshSeconds` (mặc định 20s) và tự động nhận diện IP Wi-Fi.
- `startLiveAttendance(...)`: Tự động kích hoạt timer đếm ngược ca học, timer đếm ngược chu kỳ mã QR (20s về 0s), đăng ký SSE stream và tự động fallback sang polling định kỳ nếu mạng mất kết nối SSE.

#### Screen
| Screen | Route | Mô tả |
|---|---|---|
| `CreateSessionScreen` | `/schedule/create` | Form tạo phiên: Chọn môn học, ca học (Slot 1–6), thời lượng điểm danh, **chọn chu kỳ đổi mã QR (`qrRefreshSeconds`: 10s, 20s, 30s, 60s - mặc định 20s)**; tích hợp cơ chế Adaptive Wi-Fi tự động ghi nhận dải mạng |

---

### 3.5. `features/attendance/` — Điểm danh & An ninh Đa tầng

#### Models — `attendance_models.dart`

| Class | Mô tả |
|---|---|
| `AttendanceRecordModel` | Bản ghi 1 lượt điểm danh (recordId, sessionId, studentId, studentFapCode, studentName, status, checkedAt) |
| `CheckInRequest` | DTO sinh viên gửi khi điểm danh (`sessionId`, `qrToken`, `sessionCode`, `deviceId`, `bssid`). Tự động phát hiện và loại bỏ BSSID giả (`02:00:00:00:00:00` hoặc `unknown`) để Backend fallback kiểm tra IP |
| `EnrollmentModel` | Thông tin sinh viên đã ghi danh vào môn học (enrollmentId, courseId, courseTitle, studentName, fapCode) |

#### Error Helper — `AttendanceErrorHelper`
Tiện ích ánh xạ mã lỗi từ Backend (`ApiException` / HTTP 400, 403) thành thông báo thân thiện và gợi ý xử lý trên giao diện người dùng theo chuẩn **Mục 6 trong `FRONTEND_QR_ATTENDANCE_INTEGRATION_GUIDE.md`**:
- Mã QR hết hạn: *"Mã QR đã chuyển sang chu kỳ mới. Vui lòng hướng camera quét lại mã trên màn hình!"*
- Sai Wi-Fi phòng học: *"Bạn chưa kết nối đúng Wi-Fi phòng học. Vui lòng kết nối vào Wi-Fi lớp học để điểm danh!"*
- Lệch dải IP mạng: *"Địa chỉ mạng không khớp. Vui lòng tắt 4G/VPN và kết nối cùng mạng Wi-Fi với giảng viên!"*
- Khóa thiết bị (Device ID): *"Điểm danh thất bại! Thiết bị này đã được dùng để điểm danh cho sinh viên khác trong buổi học."*
- Chưa đăng ký học phần: *"Bạn không có tên trong danh sách đăng ký của khóa học này."*
- Buổi học đã đóng: *"Buổi điểm danh đã kết thúc."*

#### Repository — `AttendanceRepository` (Singleton)

| Method | API | Mô tả |
|---|---|---|
| `checkIn(request)` | POST `/api/attendance/check-in` | SV điểm danh (xác thực TOTP + Thiết bị + Wi-Fi) |
| `getSessionRecords(sessionId)` | GET `/api/attendance/session/{id}` | DS đã điểm danh trong phiên |
| `getMyEnrollments()` | GET `/api/enrollments/my-courses` | Khóa học SV đã đăng ký |
| `enrollCourse(courseId)` | POST `/api/enrollments` | SV ghi danh học phần |
| `getStudentsByCourse(courseId)` | GET `/api/enrollments/course/{id}` | DS SV trong lớp học phần |

#### Controllers

| Controller | Vai trò | Mô tả |
|---|---|---|
| `StudentAttendanceController` | STUDENT | Quản lý điểm danh QR/PIN, tìm kiếm học phần, đăng ký môn học, tải lịch sử chuyên cần |
| `LecturerAttendanceController` | LECTURER | Quản lý luồng Courses → Sessions → Danh sách sinh viên có mặt / vắng mặt |

#### Screens

| Screen | Route | Role | Mô tả |
|---|---|---|---|
| `LecturerAttendanceManagementScreen` | `/attendance/manage` | LECTURER | Xem courses → sessions → DS SV đã/chưa điểm danh |
| `AttendanceLiveScreen` | `/attendance/live` | LECTURER | Hiển thị mã QR động realtime qua SSE/Polling, thanh countdown đếm ngược 20s đổi màu theo thời gian, tự nhận diện LAN IP:5000, hỗ trợ nút sửa nhanh IP/Port (✏️) |
| `AttendanceResultsScreen` | `/attendance/results` | LECTURER | Kết quả điểm danh một phiên dành cho Giảng viên |
| `StudentCheckInScreen` | `/student/check-in` | STUDENT | **Màn hình xác nhận điểm danh**: Hiển thị môn học, lớp, giảng viên, slot, IP Wi-Fi, đếm ngược thời hạn và nút "Điểm danh ngay" |
| `AttendanceResultScreen` | `/student/result` | STUDENT | **Màn hình kết quả điểm danh**: Hiển thị Thành công (thẻ chi tiết buổi học) hoặc Thất bại (lý do lỗi cụ thể & nút thử lại) |
| `QrScannerScreen` | `/student/scan` | STUDENT | Màn hình điểm danh 2 trong 1: Quét/Dán mã QR động (8 ký tự Hex / URL) hoặc Nhập mã PIN 6 số với ô nhập co giãn theo màn hình |

---

### 3.6. `features/student/` — Màn hình Sinh viên (Tối ưu hóa Mobile)

#### Screens

| Screen | Route | Mô tả |
|---|---|---|
| `StudentDashboardScreen` | `/student/dashboard` | Trang chính SV: Card hồ sơ sinh viên, nút điểm danh nhanh, danh sách buổi học hôm nay và danh sách các môn đã ghi danh (tối ưu thẻ 1 cột cuộn mượt trên Mobile) |
| `StudentCoursesSearchScreen` | `/student/courses` | Tìm kiếm & đăng ký môn học mới: Bộ lọc xếp dọc responsive trên điện thoại, danh sách thẻ học phần trực quan, modal đăng ký nhập mật khẩu co giãn |
| `StudentAttendanceHistoryScreen` | `/student/history` | Xem nhật ký chuyên cần cá nhân: Thống kê tỷ lệ chuyên cần qua lưới 2x2 trên mobile, bộ lọc ngày From/To và Môn học xếp dọc, hiển thị danh sách thẻ Card List chuyên biệt cho điện thoại thay vì bảng DataTable dàn ngang |

---

### 3.7. `shared/` — Widget & Layout dùng chung

#### `DesktopScaffold`
Layout thích ứng đa nền tảng cho cả Desktop lẫn Mobile:

- **Desktop (`width >= 800px`)**: Thanh bên Sidebar (220px) + Nội dung chính (`body`).
- **Mobile (`width < 800px`)**:
  - **Sinh viên (`role: student`)**: Tự động kích hoạt **Bottom Navigation Bar** gồm 4 chức năng cốt lõi (Buổi học, Tìm môn, Quét QR, Lịch sử).
  - **Giảng viên (`role: lecturer`)**: AppBar tích hợp nút Menu mở ngăn kéo (`Drawer`) đầy đủ danh mục.
  - AppBar Mobile hiển thị Avatar người dùng kèm mã số FAP (`fapCode`) rõ ràng.

**Sidebar & Bottom Nav STUDENT:**
| Index | Label | Route | Icon |
|---|---|---|---|
| 0 | Buổi học | `/student/dashboard` | `calendar_today` |
| 1 | Tìm môn | `/student/courses` | `search` |
| 2 | Quét QR | `/student/scan` | `qr_code_scanner` |
| 3 | Lịch sử | `/student/history` | `history` |

**Sidebar LECTURER:**
| Index | Label | Route |
|---|---|---|
| 0 | Tổng quan | `/courses` |
| 1 | Môn học | `/courses` |
| 2 | Lịch học | `/schedule/create` |
| 3 | Điểm danh | `/attendance/manage` |

#### Shared Widgets
| Widget | Mô tả |
|---|---|
| `CustomTextField` | Text input có label, validation, prefix icon, hỗ trợ `onSubmitted` |
| `PrimaryButton` | Button chính (accent color, trạng thái loading xoay tròn) |
| `SecondaryButton` | Button outlined viền xám tinh tế |
| `DangerButton` | Button đỏ dùng cho hành động nguy hiểm / hủy |

---

## 4. Routing

File: `lib/routing/app_router.dart`

| Path | Screen | Role | Ghi chú |
|---|---|---|---|
| `/login` | `AuthDesktopScreen` | Tất cả | Đăng nhập / Đăng ký (responsive full-height) |
| `/courses` | `LecturerCoursesScreen` | LECTURER | Quản lý danh sách môn học của giảng viên |
| `/courses/create` | `CreateCourseScreen` | LECTURER | Tạo môn học mới |
| `/courses/import` | `ImportStudentsScreen` | LECTURER | Import sinh viên từ Excel |
| `/schedule/create` | `CreateSessionScreen` | LECTURER | Khởi tạo phiên điểm danh (chọn `qrRefreshSeconds`) |
| `/attendance/manage` | `LecturerAttendanceManagementScreen` | LECTURER | Quản lý danh sách điểm danh theo lớp & phiên |
| `/attendance/live` | `AttendanceLiveScreen` | LECTURER | Chiếu mã QR TOTP động realtime |
| `/attendance/results` | `AttendanceResultsScreen` | LECTURER | Kết quả điểm danh một phiên |
| `/student/dashboard` | `StudentDashboardScreen` | STUDENT | Tab 0: Cổng sinh viên & Buổi học |
| `/student/courses` | `StudentCoursesSearchScreen` | STUDENT | Tab 1: Tìm kiếm & Đăng ký môn học |
| `/student/scan` | `QrScannerScreen` | STUDENT | Tab 2: Quét mã QR / Nhập mã PIN phiên học |
| `/student/history` | `StudentAttendanceHistoryScreen` | STUDENT | Tab 3: Nhật ký chuyên cần cá nhân |
| `/student/check-in` | `StudentCheckInScreen` | STUDENT | Màn hình xác nhận điểm danh từ liên kết QR |
| `/student/result` | `AttendanceResultScreen` | STUDENT | Màn hình hiển thị kết quả (Thành công / Thất bại) |
| `/student/success` | `AttendanceResultScreen` | STUDENT | Alias kết quả điểm danh thành công |

---

## 5. Quy ước code

### 5.1. Naming

| Loại | Convention | Ví dụ |
|---|---|---|
| File | `snake_case.dart` | `course_model.dart` |
| Class | `PascalCase` | `CourseRepository` |
| Variable/Method | `camelCase` | `getCourses()` |
| Constants | `camelCase` | `static const String baseUrl` |
| Enum | `PascalCase` / `camelCase` values | `UserRole.lecturer` |

### 5.2. Singleton Pattern

Tất cả Repository và một số Controller dùng singleton:

```dart
class SomeRepository {
  static final SomeRepository _instance = SomeRepository._internal();
  factory SomeRepository() => _instance;
  SomeRepository._internal();
}
```

### 5.3. State Management

- Dùng `ChangeNotifier` + `notifyListeners()`
- Controller giữ state (`_isLoading`, `_error`, data list)
- Screen lắng nghe qua `addListener()` → `setState()`

### 5.4. Error Handling

- Repository throw `ApiException` cho lỗi API
- Controller catch và lưu vào `_error`
- Screen hiển thị error banner nếu `error != null`

### 5.5. API Communication

- **Luôn** khai báo endpoint mới trong `api_endpoints.dart`
- Request body dùng `toJson()` method từ DTO
- Response parse qua `Model.fromJson()`
- `requiresAuth: true` (mặc định) → tự gắn JWT token

---

## 6. Cách chạy dự án

> 📖 **Xem hướng dẫn chi tiết từng bước & Kịch bản thực hiện Full Chức Năng**: xem file [`RUN_GUIDE.md`](./RUN_GUIDE.md).

### 6.1. Yêu cầu môi trường
- Flutter SDK ≥ 3.13.3
- Node.js & npm (để chạy `npx serve`)
- Visual Studio 2022 (có workload *Desktop development with C++* nếu chạy app Windows Desktop)
- Backend Spring Boot đang chạy tại `http://localhost:8080`

### 6.2. Cài đặt ban đầu
```bash
flutter pub get
```

### 6.3. Chạy trên Website (Khuyên dùng)
```bash
# Cách 1: Chạy build production mượt mà trên cổng 5000 (khuyên dùng khi thuyết trình/demo)
flutter build web
npx serve -s build/web -p 5000

# Cách 2: Chạy trực tiếp qua Chrome (Debug)
flutter run -d chrome

# Cách 3: Chạy web server cho toàn mạng LAN
flutter run -d web-server --web-port 5000 --web-hostname 0.0.0.0
```
Truy cập: `http://localhost:5000` hoặc `http://<IP_LAN>:5000` (ví dụ: `http://192.168.1.101:5000`).

### 6.4. Chạy trên Desktop (Windows)
```bash
# Debug Mode
flutter run -d windows

# Đóng gói file chạy .exe độc lập (Release)
flutter build windows
# File .exe xuất tại: build\windows\x64\runner\Release\fap_student_attendance_fe.exe
```

> 💡 **Lưu ý điểm danh đa thiết bị:** Khi Giảng viên mở app Windows Desktop chiếu mã QR, chỉ cần chạy thêm `npx serve -s build/web -p 5000` ở một terminal ngầm để điện thoại của sinh viên (cùng Wi-Fi) có thể quét và mở trang check-in.

```bash
flutter test
```

**Test files hiện có (32/32 tests passed):**
| File | Nội dung |
|---|---|
| `test/auth_test.dart` | Test auth models, repository, UI toggle form đăng nhập/đăng ký |
| `test/attendance_features_test.dart` | Test attendance models, TOTP TOTP intervals (20s), BSSID sanitization, error helper, session & controller |
| `test/student_courses_search_test.dart` | Test API endpoints, search & register courses, course aliases |
| `test/student_mobile_navigation_test.dart` | Test giao diện Mobile: BottomNavigationBar 4 tabs và Desktop Sidebar |
| `test/widget_test.dart` | Smoke test khởi động toàn bộ ứng dụng Attendly |

---

## 7. Luồng hoạt động chính

### 7.1. Giảng viên — Tạo lớp & Điểm danh

```
Login → /courses → Tạo khóa học → /schedule/create → Tạo phiên → /attendance/live → QR Code
                                                                             ↓
                                         /attendance/manage → Chọn course → Chọn session → Xem DS SV
```

### 7.2. Sinh viên — Đăng ký & Điểm danh qua mã QR

```
Quét mã QR từ GV (hoặc truy cập URL)
          ↓
Chưa đăng nhập? ──[Có]──→ /login?redirect=/student/check-in... ──[Đăng nhập xong]──┐
          ↓ [Không]                                                                │
          └────────────────────────────────────────────────────────────────────────┘
          ↓
Trang xác nhận: /student/check-in
(Hiển thị: Môn học, Lớp, Giảng viên, Slot, Thời hạn phiên, Thông tin SV)
          ↓
Nhấn nút [ĐIỂM DANH NGAY] ──→ Gửi POST /api/attendance/check-in
          ↓
Chuyển qua màn hình kết quả: /student/result
├── [Thành công] → Badge xanh lá, thông tin chi tiết lượt điểm danh, nút về Dashboard
└── [Thất bại]   → Badge đỏ, thông báo nguyên nhân lỗi cụ thể từ Server, nút Thử lại
```

---

## 8. Danh sách tất cả files

```
lib/
├── main.dart                                                    # Entry point, GoogleFonts config
├── app.dart                                                     # MaterialApp.router + theme
│
├── core/
│   ├── constants/
│   │   ├── api_endpoints.dart                                   # Tất cả REST API endpoints (dynamic baseUrl)
│   │   └── app_constants.dart                                   # App name, version, branding
│   ├── network/
│   │   └── api_client.dart                                      # HTTP client (GET, POST, PUT)
│   ├── storage/
│   │   └── token_storage.dart                                   # JWT + User persistence
│   ├── theme/
│   │   ├── app_colors.dart                                      # Bảng màu
│   │   ├── app_text_styles.dart                                 # Typography
│   │   └── app_theme.dart                                       # ThemeData Material 3
│   └── utils/
│       ├── network_info.dart                                    # Conditional export IP detector
│       ├── network_info_io.dart                                 # Native IO: NetworkInterface LAN IP & port 5000
│       └── network_info_web.dart                                # Web browser: Uri.base.host/port
│
├── features/
│   ├── auth/
│   │   ├── data/
│   │   │   ├── models/
│   │   │   │   ├── auth_models.dart                             # LoginRequest, RegisterRequest, AuthResponse
│   │   │   │   └── user_model.dart                              # UserModel (role helpers)
│   │   │   └── repositories/
│   │   │       └── auth_repository.dart                         # Login, Register, Logout, UpdateProfile (username)
│   │   └── presentation/
│   │       ├── controllers/
│   │       │   └── auth_controller.dart                         # Auth state (singleton)
│   │       ├── screens/
│   │       │   └── auth_desktop.dart                            # Login/Register UI
│   │       └── widgets/
│   │           └── user_profile_dialog.dart                     # Modal cập nhật thông tin cá nhân & đổi MK
│   │
│   ├── courses/
│   │   ├── data/
│   │   │   ├── models/
│   │   │   │   ├── course_model.dart                            # CourseModel, CourseCreateRequest, CourseUpdateRequest
│   │   │   │   └── lecturer_dashboard_stats_model.dart          # Thống kê Dashboard GV (totalCourses, totalRegisteredStudents...)
│   │   │   └── repositories/
│   │   │       └── course_repository.dart                       # CRUD courses, search, register, update, stats
│   │   └── presentation/
│   │       ├── controllers/
│   │       │   └── course_controller.dart                       # Course list state & updateCourse
│   │       ├── screens/
│   │       │   ├── lecturer_dashboard_screen.dart               # Trang tổng quan GV (3 thẻ KPI, thao tác nhanh, tóm tắt lớp)
│   │       │   ├── lecturer_courses_screen.dart                 # DS môn học GV, bộ lọc học kỳ, tìm kiếm, sửa môn
│   │       │   ├── create_course_screen.dart                    # Form tạo khóa học
│   │       │   └── import_students_screen.dart                  # Upload Excel sinh viên (mật khẩu mặc định A123456)
│   │       └── widgets/
│   │           ├── edit_course_dialog.dart                      # Modal cập nhật môn học
│   │           └── course_students_dialog.dart                  # Modal xem danh sách sinh viên & nút sửa môn
│   │
│   ├── schedule/
│   │   ├── data/
│   │   │   ├── models/
│   │   │   │   └── session_model.dart                           # AttendanceSessionModel
│   │   │   └── repositories/
│   │   │       └── session_repository.dart                      # CRUD sessions
│   │   └── presentation/
│   │       ├── controllers/
│   │       │   └── session_controller.dart                      # Session creation state
│   │       └── screens/
│   │           └── create_session_screen.dart                   # Form tạo phiên
│   │
│   ├── attendance/
│   │   ├── data/
│   │   │   ├── models/
│   │   │   │   └── attendance_models.dart                       # AttendanceRecord, CheckIn, Enrollment
│   │   │   └── repositories/
│   │   │       └── attendance_repository.dart                   # Check-in, records, enrollments
│   │   └── presentation/
│   │       ├── controllers/
│   │       │   ├── student_attendance_controller.dart            # SV check-in state
│   │       │   └── lecturer_attendance_controller.dart           # GV attendance management state
│   │       └── screens/
│   │           ├── lecturer_attendance_management_screen.dart    # GV: Courses → Sessions → DS SV
│   │           ├── attendance_live_screen.dart                   # GV: QR Code live (tự nhận diện LAN IP:5000, nút sửa ✏️)
│   │           ├── attendance_results_screen.dart                # GV: Kết quả phiên
│   │           ├── student_check_in_screen.dart                  # SV: Màn hình xác nhận phiên & nút Điểm danh ngay
│   │           ├── attendance_result_screen.dart                 # SV: Màn hình hiển thị kết quả (Thành công / Thất bại)
│   │           └── qr_scanner_screen.dart                        # SV: Nhập mã PIN thủ công
│   │
│   └── student/
│       └── presentation/
│           └── screens/
│               ├── student_dashboard_screen.dart                 # Trang chính SV (môn đã đăng ký, lọc theo kỳ/GV)
│               ├── student_courses_search_screen.dart            # SV tìm & đăng ký môn
│               └── student_attendance_history_screen.dart        # Xem lịch sử điểm danh (lọc ngày from/to, môn, tỷ lệ chuyên cần)
│
├── routing/
│   └── app_router.dart                                           # GoRouter config (15 routes)
│
└── shared/
    ├── layouts/
    │   └── desktop_scaffold.dart                                 # Sidebar + Content layout (Role-based nav)
    └── widgets/
        ├── custom_text_field.dart                                # Reusable high-contrast text input
        └── primary_button.dart                                   # Primary, Secondary, Danger buttons
```

---

## 9. Thiết kế Giao diện Mobile (Mobile Responsive UI)

Dự án hỗ trợ trải nghiệm tối ưu trên thiết bị di động (màn hình `< 800px`):

### 9.1. Khung giao diện chung & Điều hướng Mobile (`DesktopScaffold`)
- **Tự động chuyển đổi layout (`width < 800px`)**: Thanh bên cố định (sidebar) tự động ẩn đi, thay thế bằng thanh `AppBar` tinh gọn tích hợp nút Menu mở ngăn kéo (`Drawer`), logo Attendly và Avatar tài khoản.
- **Thanh điều hướng dưới đáy (Bottom Navigation Bar) cho Sinh viên (`STUDENT`)**:
  - Khi người dùng đăng nhập với vai trò `STUDENT`, hệ thống tự động hiển thị thanh `BottomNavigationBar` cố định dưới cùng màn hình với **4 Tab thao tác nhanh**:
    1. **Buổi học** (`/student/dashboard` — `Icons.dashboard_rounded`): Xem danh sách các môn đã đăng ký và ca học hiện tại.
    2. **Tìm môn** (`/student/courses` — `Icons.manage_search_rounded`): Tìm kiếm và đăng ký thêm các môn học mở mới.
    3. **Quét QR** (`/student/scan` — `Icons.qr_code_scanner_rounded`): Mở camera quét QR hoặc nhập mã PIN 6 số.
    4. **Lịch sử** (`/student/history` — `Icons.history_rounded`): Tra cứu nhật ký chuyên cần cá nhân.
  - **Tối ưu thao tác ngón tay cái (Thumb-friendly)**: Màu sắc tab được đồng bộ theo `AppColors.primary`, có phản hồi xúc giác nhẹ và hiệu ứng đổi icon khi được chọn.
  - Giảng viên (`LECTURER`) sử dụng thanh `AppBar` và `Drawer` chuyên dụng, giữ không gian tối đa để hiển thị mã QR và bảng quản lý.

### 9.2. Cổng Sinh viên Mobile (`StudentDashboardScreen`)
- **Bố cục 1 cột (single-column)**: Tự động co giãn theo chiều rộng màn hình thiết bị mà không bị co cụm nội dung.
- **Bộ lọc linh hoạt**: Thanh chọn Học kỳ (Semester) và Giảng viên (Teacher) tự động mở rộng 100% bề ngang.
- **Banner chào mừng tích hợp**: Hiển thị tên sinh viên kèm nút tắt **"Quét QR Điểm Danh"** màu cam nổi bật, cho phép điểm danh ngay lập tức khi vừa bước vào lớp.
- **Thẻ môn học di động**: Mỗi học phần hiển thị dưới dạng Thẻ (Card) bo góc mềm mại, hiển thị rõ Mã môn, Tên môn, Giảng viên, Học kỳ và nút "Vào điểm danh" full-width.

### 9.3. Màn hình Tìm & Đăng ký Môn học Mobile (`StudentCoursesSearchScreen`)
- **Bộ điều khiển xếp chồng (Stacked Controls)**: Ô tìm kiếm từ khóa và Dropdown lọc kỳ học được xếp theo chiều dọc giúp bàn phím ảo không che khuất các nút thao tác.
- **Danh sách thẻ học phần**: Hiển thị thông tin lớp học, số lượng sinh viên, giảng viên kèm chip trạng thái "Đã đăng ký" (màu xanh lá) hoặc nút "Đăng ký môn" một chạm.
- **Hộp thoại xác nhận co giãn an toàn**: Hộp thoại `AlertDialog` khi đăng ký / hủy môn được bọc trong `ConstrainedBox(maxWidth: 420)`, đảm bảo vừa vặn trên mọi kích thước màn hình smartphone (iPhone, Android).

### 9.4. Màn hình Quét QR & Nhập mã PIN Mobile (`QrScannerScreen`)
- **Thiết kế 2 Tab tiện dụng**:
  - **Tab [ Quét mã QR ]**: Hướng dẫn sinh viên quét QR trực tiếp từ màn hình máy chiếu của giảng viên hoặc sử dụng ứng dụng camera mặc định hỗ trợ deep link.
  - **Tab [ Nhập mã PIN ]**: Ô nhập mã 6 số to rõ (`letterSpacing: 8`, font `monospace`), tự động giới hạn độ rộng tối đa và căn giữa giúp thao tác bấm phím số nhanh chóng và chính xác.
- **Khung hướng dẫn điểm danh nhanh**: Các bước chuẩn bị (kết nối đúng Wi-Fi phòng học, giữ mã QR trong khung ngắm, nhập mã PIN dự phòng khi camera lỗi) được minh họa bằng các icon trực quan.

### 9.5. Màn hình Nhật ký Chuyên cần Mobile (`StudentAttendanceHistoryScreen`)
- **Lưới thống kê 2x2 (Metric Grid)**: Trên màn hình nhỏ, 4 chỉ số tổng hợp được bố trí thành lưới 2 cột x 2 hàng:
  - `Tổng số buổi`
  - `Có mặt` (màu xanh lá)
  - `Vắng mặt` (màu đỏ)
  - `Tỷ lệ chuyên cần (%)` (tự động đổi màu cảnh báo: xanh nếu ≥ 80%, đỏ nếu < 80%).
- **Bộ lọc thời gian xếp dọc**: 2 nút chọn "Từ ngày" và "Đến ngày" được bố trí dạng cột kèm biểu tượng lịch to rõ, hỗ trợ chọn khoảng ngày nhanh chóng.
- **Danh sách bản ghi dạng Thẻ Mobile (Card List View)**:
  - Thay thế hoàn toàn bảng dữ liệu ngang (`DataTable`) để loại bỏ tình trạng tràn viền (overflow).
  - Mỗi bản ghi điểm danh được hiển thị dưới dạng một Thẻ riêng biệt:
    - **Header**: Mã môn, Tên môn học, Chip trạng thái điểm danh (Có mặt / Vắng mặt / Muộn).
    - **Chi tiết**: Ngày học, Giờ ghi nhận, Giảng viên phụ trách, Ca học (Slot), và Phương thức xác thực (`QR_CODE` / `MANUAL_PIN`).

### 9.6. Màn hình Xác nhận & Kết quả Điểm danh (`StudentCheckInScreen` & `AttendanceResultScreen`)
- **Xác nhận Điểm danh (`StudentCheckInScreen`)**:
  - Tự động nhận diện tham số deep link từ mã QR động (`sessionId`, `qrCodeSecret`, `courseId`).
  - Banner đếm ngược thời gian hiệu lực phiên dạng `monospace`.
  - Thẻ thông tin môn học, mã lớp, ca học (Slot), giảng viên và IP Wi-Fi được sắp xếp gọn gàng theo chiều dọc.
  - Nút **"ĐIỂM DANH NGAY"** kích thước lớn (chiều cao 52px, full width), tự động hiển thị vòng xoay loading khi đang xác thực.
- **Kết quả Điểm danh (`AttendanceResultScreen`)**:
  - **Thành công**: Icon checkmark xanh lớn, thẻ tóm tắt chi tiết phiên và các nút điều hướng "Về trang sinh viên" & "Xem lịch sử điểm danh" xếp dọc full-width.
  - **Thất bại**: Icon cảnh báo màu đỏ, hộp hiển thị lý do chi tiết từ Ứng dụng theo mã lỗi chuẩn (IP không hợp lệ, Token hết hạn, thiết bị trùng lặp,...), danh sách gợi ý khắc phục và các nút hành động ("Thử lại", "Nhập mã PIN", "Về trang chính").

### 9.7. Trang Đăng nhập & Đăng ký Mobile (`AuthDesktopScreen`)
- Bố cục 1 cột (single-column) cuộn toàn màn hình (`SingleChildScrollView`), đảm bảo hiển thị trọn vẹn và không bị tràn bàn phím.
- Header thương hiệu FPT Education & Attendly nền xanh đậm cao cấp.
- Tab chuyển đổi chế độ (`[ Đăng nhập ]` / `[ Tạo tài khoản mới ]`) nhanh chóng.
- Nút bật/tắt ẩn hiện mật khẩu trên các ô nhập liệu.
- Nút hành động chính kích thước lớn (chiều cao 50px, bo góc 10px).

---

## 10. Checklist cho Lập trình viên mới

- [ ] Đọc file `BE_API_ENDPOINTS.md` để hiểu toàn bộ API Backend
- [ ] Đọc file `BE_PROJECT_OVERVIEW.md` để hiểu kiến trúc Backend
- [ ] Chạy `flutter pub get` để cài dependencies
- [ ] Đảm bảo Backend đang chạy ở `http://localhost:8080`
- [ ] Chạy `flutter run -d chrome` để test trên web
- [ ] Chạy `flutter test` để xác nhận tests pass
- [ ] Nắm flow: `Screen → Controller → Repository → ApiClient → Backend`
- [ ] Khi thêm feature mới: tạo đủ `model/`, `repository/`, `controller/`, `screen/`
- [ ] Khi thêm API mới: khai báo trong `api_endpoints.dart`
- [ ] Khi thêm route mới: khai báo trong `app_router.dart`
- [ ] Khi thêm sidebar item: cập nhật `desktop_scaffold.dart`

---

> **Ghi chú**: Tài liệu này được tạo tự động từ source code. Nếu có thay đổi kiến trúc, hãy cập nhật lại file này.
