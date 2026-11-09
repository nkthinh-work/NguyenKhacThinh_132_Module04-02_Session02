# QuickBite – Docker & PostgreSQL | Session 02

Bài thực hành Docker/PostgreSQL/Spring Boot theo **6 bài tập** và **1 bài tổng hợp**. Toàn bộ bài được gom trong một repository, đúng đường dẫn nộp `homework/session_02`.

## 1. Yêu cầu

- Ubuntu / WSL2 Ubuntu có Docker Engine đang chạy, hoặc Docker Desktop tích hợp WSL2.
- JDK **17 hoặc 21** để biên dịch; service biên dịch target **Java 17** để chạy trên `eclipse-temurin:17-jre-alpine`.
- Internet ở lần chạy đầu để tải PostgreSQL image, image JRE và phụ thuộc Gradle.
- `curl`, `unzip` và `git` là những tiện ích được khuyến nghị.

Kiểm tra Docker:

```bash
docker --version
docker info
```

Nếu chưa có Docker trên Ubuntu, có thể dùng lệnh trong đề:

```bash
sudo apt-get update
sudo apt-get install -y docker.io
sudo systemctl enable --now docker
```

Với WSL2 không bật systemd, nên dùng Docker Desktop + WSL integration (không tự động chạy `systemctl` nếu hệ thống không hỗ trợ).

## 2. Cấu trúc

```text
.
├── README.md
├── .gitignore
├── user-service/                       # Spring Boot tối giản, dùng Gradle
│   ├── build.gradle
│   ├── settings.gradle
│   ├── gradlew                         # trình khởi chạy Gradle (xem ghi chú)
│   └── src/
├── homework/
│   └── session_02/
│       ├── exercise_01/start_db.sh
│       ├── exercise_02/run_user_service_host.sh
│       ├── exercise_03/inspect_db.sh
│       ├── exercise_04/follow_db_logs.sh
│       ├── exercise_05/run_user_service.sh
│       ├── exercise_06/init-staging.sh
│       ├── verify_docker.sh
│       ├── smoke_test.sh
│       └── report_session02.md
├── tests/test_scripts.sh
└── publish_github.sh
```

**Mỗi bài có đúng chỗ lưu ảnh minh chứng** theo đề. Trong bản tải về chưa có ảnh thành công vì không có Docker daemon để chạy và chụp màn hình thật. Cần tự chạy và chụp trước khi nộp.

## 3. Thực hiện bài 1–4 (mật khẩu `12345678`)

Từ thư mục gốc repository:

```bash
# Bài 1: tạo PostgreSQL 15-alpine ở 5432, user postgres
./homework/session_02/exercise_01/start_db.sh

# Kiểm tra PostgreSQL sẵn sàng
docker exec quickbite-db pg_isready -U postgres

# Bài 2: chạy user-service trên host, kết nối tới localhost:5432
./homework/session_02/exercise_02/run_user_service_host.sh

# Ở terminal khác: smoke test
./homework/session_02/smoke_test.sh

# Bài 3: xem danh sách database qua psql
./homework/session_02/exercise_03/inspect_db.sh

# Bài 4: theo dõi log (Ctrl+C để dừng xem log, không dừng DB)
./homework/session_02/exercise_04/follow_db_logs.sh
```

Đối với bài 3, có thể làm đúng quy trình tương tác đề nêu:

```bash
docker exec -it quickbite-db sh
psql -U postgres
\l
\q
exit
```

Tại thời điểm chụp bài 4, mở terminal còn lại để chạy user-service hoặc gọi API `curl -i http://localhost:8081/api/v1/users/db-info`.

## 4. Bài 5: mount JAR vào container JRE

Đề bài 5 yêu cầu `SPRING_DATASOURCE_PASSWORD=secret`, **khác bài 1–4**. Để khớp nguyên văn bài 5, bạn có thể tạo lại DB với mật khẩu `secret` (sẽ mất dữ liệu DB thử nghiệm cũ):

```bash
docker rm -f quickbite-db
docker run -d --name quickbite-db -p 5432:5432 \
  -e POSTGRES_PASSWORD=secret postgres:15-alpine
```

Sau đó:

```bash
cd user-service
./gradlew clean bootJar
cd ..
./homework/session_02/exercise_05/run_user_service.sh
./homework/session_02/smoke_test.sh
```

Script chạy `eclipse-temurin:17-jre-alpine`, cờ `-d`, tên `quickbite-user`, port `8081:8081`, `-v <thư_mục_build/libs>:/app:ro`, `-w /app`, `--add-host=host.docker.internal:host-gateway`, các biến `SPRING_DATASOURCE_*`, rồi `java -jar user-service.jar`.

Nếu bạn muốn **giữ nguyên DB bài 1 với `12345678`** thay vì tạo lại, chạy:

```bash
DB_PASSWORD=12345678 ./homework/session_02/exercise_05/run_user_service.sh
```

Lưu ý: truyền biến môi trường vào ứng dụng **không tự thay mật khẩu trong PostgreSQL**. Hai phía phải trùng khớp.

## 5. Bài 6: tự động hóa staging (mật khẩu `12345678`)

**Cảnh báo:** Script sẽ xóa container tên `quickbite-db` nếu tồn tại. Bất kỳ dữ liệu không gắn volume trong container sẽ mất. Đây là mục đích của bài thực hành staging, không dùng với database production.

```bash
./homework/session_02/exercise_06/init-staging.sh
```

Script thực hiện lần lượt: dừng/xóa container cũ, kiểm tra cổng host 5432 trước khi chạy, tạo lại PostgreSQL 15-alpine với `12345678`, chờ 5 lần (mỗi lần 5 giây) dùng `pg_isready`, thông báo màu xanh khi thành công, hoặc in 20 dòng log và exit code 1 khi thất bại.

Thử nghiệm fail-fast: tạo một tiến trình khác chiếm cổng `5432` (cẩn thận: không đụng PostgreSQL quan trọng) rồi chạy lại và kiểm tra script **dừng trước `docker run`**.

## 6. Bài tổng hợp

Bài tổng hợp yêu cầu mật khẩu **`secret`**. Thực hiện lại bước tạo database mật khẩu `secret` trong phần 4, rồi:

```bash
./homework/session_02/verify_docker.sh
cd user-service
./gradlew clean bootJar
cd ..
SPRING_DATASOURCE_PASSWORD=secret java -jar user-service/build/libs/user-service.jar
```

Mở terminal khác để kiểm tra:

```bash
curl -fsS http://localhost:8081/actuator/health
curl -fsS http://localhost:8081/api/v1/users/db-info
```

Chụp 3 ảnh theo hướng dẫn `homework/session_02/report_session02.md` và điền kết quả thực tế vào đó.

## 7. Về `user-service` trong gói

Các đề dẫn đến mã nguồn QuickBite bên ngoài. Để gói thực hành vẫn dùng được độc lập, repository này chứa **một ứng dụng Spring Boot tối giản tự xây dựng** làm `user-service`: một endpoint kiểm tra JDBC và actuator health. Đây **không phải bản sao** của repository QuickBite gốc. Nếu giảng viên yêu cầu đúng code mẫu, có thể thay `user-service/` bằng code mẫu, giữ cùng cổng, cấu hình môi trường và đường dẫn JAR trong các script.

`user-service/gradlew` là **launcher Gradle dạng shell**: dùng `gradle` đã cài nếu có, nếu chưa thì tải bản Gradle được cố định. Đây không phải wrapper JAR chính thức; cần `curl` + `unzip` và Internet ở lần chạy đầu. Với Windows hãy chạy từ WSL/Ubuntu.

## 8. Kiểm tra & đẩy GitHub

```bash
bash tests/test_scripts.sh
./publish_github.sh
```

`publish_github.sh` yêu cầu GitHub CLI `gh` đã đăng nhập, mặc định tạo repository **private**. Có thể dùng `./publish_github.sh public` để tạo repository public. Không lưu GitHub token vào repository.

**Trạng thái bàn giao:** source và shell scripts đã viết và kiểm tra cú pháp; chưa được kiểm chứng tích hợp Docker, Gradle hoặc kết nối DB trong môi trường tạo gói.
