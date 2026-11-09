# BÁO CÁO THỰC HÀNH SESSION 02

**Chủ đề:** Docker Engine, PostgreSQL và ứng dụng Spring Boot  
**Sinh viên:** ........................................  
**Ngày thực hiện:** ..................................  
**Môi trường thực nghiệm:** Ubuntu/WSL2 + Docker Engine, JDK 17/21

> **Lưu ý về minh chứng:** Báo cáo chứa lệnh thực hiện và tiêu chí đối chiếu theo đề. Không điền kết quả "đạt" hoặc dùng ảnh giả khi chưa thực chạy trên máy. Hãy lưu 9 ảnh chụp vào các đường dẫn bên dưới và cập nhật trạng thái kiểm chứng.

## I. Mục tiêu

- Xác thực Docker Engine trên hệ điều hành Linux.
- Khởi chạy PostgreSQL `15-alpine`, cấu hình container, port, mật khẩu.
- Kết nối Java Spring Boot chạy trên host vào PostgreSQL trong Docker.
- Thực hành `docker exec`, `psql`, xem log, mount JAR vào JRE container.
- Tự động hóa việc reset database staging, fail-fast kiểm tra port và smoke test.

## II. Công cụ và cấu hình

| Thành phần | Cấu hình |
| --- | --- |
| OS | Ubuntu/WSL2 |
| Image database | `postgres:15-alpine` |
| Container database | `quickbite-db` |
| DB host port / container port | `5432:5432` |
| Database mặc định | `postgres` |
| DB user | `postgres` |
| Password bài 1–4, bài 6 | `12345678` |
| Password bài 5, bài tổng hợp | `secret` |
| Runtime container Java | `eclipse-temurin:17-jre-alpine` |
| Container ứng dụng | `quickbite-user`, `8081:8081` |
| JDBC khi chạy trên host | `jdbc:postgresql://localhost:5432/postgres` |
| JDBC khi chạy trong JRE container | `jdbc:postgresql://host.docker.internal:5432/postgres` |

Hai yêu cầu sử dụng hai mật khẩu khác nhau. Do đó phải tái tạo DB hoặc cấu hình lại mật khẩu cho trùng trước khi chạy.

## III. Bài tập 1 – Khởi chạy PostgreSQL

Lệnh thực hiện:

```bash
docker run -d --name quickbite-db -p 5432:5432 \
  -e POSTGRES_PASSWORD=12345678 postgres:15-alpine
docker ps
docker images
```

Tương đương script `exercise_01/start_db.sh` (an toàn hơn khi container đã tồn tại).

**Kết quả mong đợi:** container `quickbite-db` có trạng thái Up, mapping `0.0.0.0:5432->5432/tcp` và image `postgres:15-alpine`.

**Minh chứng 1:** `exercise_01/db_status.png` – ảnh terminal hiển thị `docker ps`.  
**Kết quả thực tế:** Chưa ghi nhận / Chưa chụp.

## IV. Bài tập 2 – Kết nối host → database trong container

```bash
export SPRING_DATASOURCE_URL=jdbc:postgresql://localhost:5432/postgres
export SPRING_DATASOURCE_USERNAME=postgres
export SPRING_DATASOURCE_PASSWORD=12345678
cd user-service
./gradlew bootRun
```

Hoặc chạy từ root: `./homework/session_02/exercise_02/run_user_service_host.sh`.

**Kết quả mong đợi:** log Spring Boot khởi động thành công, pool Hikari kết nối PostgreSQL, `http://localhost:8081/actuator/health` có `status: UP` và `/api/v1/users/db-info` trả thông tin database.

**Minh chứng 2:** `exercise_02/user_service_db_connect.png` – log khởi động thành công.  
**Kết quả thực tế:** Chưa ghi nhận / Chưa chụp.

## V. Bài tập 3 – Kiểm tra danh sách database

```bash
docker exec -it quickbite-db sh
psql -U postgres
\l
\q
exit
docker ps
```

Hoặc script `exercise_03/inspect_db.sh`.

**Kết quả mong đợi:** `postgres`, `template0`, `template1` xuất hiện trong bảng danh sách DB, container vẫn Up.

**Minh chứng 3:** `exercise_03/psql_inspect.png` – chụp danh sách DB.  
**Kết quả thực tế:** Chưa ghi nhận / Chưa chụp.

## VI. Bài tập 4 – Giám sát log database

```bash
docker logs -f quickbite-db
```

Ở terminal khác, khởi chạy ứng dụng hoặc gọi API để kích hoạt truy vấn DB. Có thể gọi `curl http://localhost:8081/api/v1/users/db-info`.

**Kết quả mong đợi:** log có sự kiện database sẵn sàng (`database system is ready to accept connections`). Lưu ý: thông điệp `connection received` có thể **không xuất hiện** theo cấu hình log mặc định của PostgreSQL; đừng coi đó là lỗi.

**Minh chứng 4:** `exercise_04/postgres_logs.png` – log khi giám sát.  
**Kết quả thực tế:** Chưa ghi nhận / Chưa chụp.

## VII. Bài tập 5 – Triển khai Java bằng bind mount

```bash
cd user-service
./gradlew clean bootJar
cd ..
# Đảm bảo PostgreSQL thực sự có password 'secret'
./homework/session_02/exercise_05/run_user_service.sh
docker logs quickbite-user
curl -fsS http://localhost:8081/actuator/health
```

Script dùng `eclipse-temurin:17-jre-alpine`, `--name quickbite-user`, `-p 8081:8081`, bind mount thư mục `build/libs` vào `/app`, `-w /app`, `--add-host=host.docker.internal:host-gateway` và `SPRING_DATASOURCE_*`.

**Kết quả mong đợi:** `quickbite-user` Up, kết nối DB thành công; Actuator trả `UP`.

**Minh chứng 5:** `exercise_05/user_service_container.png` – log từ container ứng dụng.  
**File script:** `exercise_05/run_user_service.sh`.  
**Kết quả thực tế:** Chưa ghi nhận / Chưa chụp.

## VIII. Bài tập 6 – Tự động hóa staging

```bash
./homework/session_02/exercise_06/init-staging.sh
```

Quy trình: (1) stop/rm `quickbite-db` cũ nếu có; (2) fail-fast khi cổng 5432 bị chiếm; (3) khởi chạy image `postgres:15-alpine`, pass `12345678`; (4) kiểm tra `pg_isready -U postgres` tối đa 5 lần, mỗi lần cách 5 giây; (5) thành công in thông báo xanh, thất bại hiển thị 20 dòng log gần nhất và exit 1.

**Minh chứng 6:** `exercise_06/staging_success.png` – terminal chạy script thành công.  
**Kiểm thử thất bại bắt buộc:** Ghi lại việc script từ chối chạy khi cổng 5432 đang bận.  
**Kết quả thực tế:** Chưa ghi nhận / Chưa chụp.

## IX. Bài thực hành tổng hợp

**Nhiệm vụ 1 – Docker Engine:**

```bash
sudo apt-get update
sudo apt-get install -y docker.io
docker --version
sudo docker info
```

Chỉ thực hiện phần cài đặt khi cần; nếu dùng Docker Desktop WSL integration thì xem `docker info` trong WSL.

**Nhiệm vụ 2 – PostgreSQL:**

```bash
docker run -d --name quickbite-db -p 5432:5432 \
  -e POSTGRES_PASSWORD=secret postgres:15-alpine
docker ps
```

Trước khi chạy `docker run`, xóa container cũ `docker rm -f quickbite-db` **chỉ khi đó là dữ liệu thực hành có thể mất**.

**Nhiệm vụ 3 – Mã nguồn và biên dịch:**

```bash
mkdir -p ~/workspace
# Mã nguồn bài này nằm sẵn trong user-service/ của repository
cd user-service
./gradlew clean bootJar
ls -lh build/libs/user-service.jar
```

Đề tổng hợp dẫn repo mẫu `https://github.com/backend-fullskill-devops/quickbite-user`. Gói hiện tại sử dụng app Spring Boot độc lập, không tự nhận là code repo mẫu.

**Nhiệm vụ 4 – Kết nối ứng dụng trên host:**

```bash
export SPRING_DATASOURCE_URL=jdbc:postgresql://localhost:5432/postgres
export SPRING_DATASOURCE_USERNAME=postgres
export SPRING_DATASOURCE_PASSWORD=secret
java -jar user-service/build/libs/user-service.jar
```

**Kết quả mong đợi:** Spring Boot start thành công, health `UP`, JdbcTemplate query tới database `postgres`.

**Ảnh tổng hợp 1:** `exercise_total/docker_engine.png` – `docker --version`, `docker info`.  
**Ảnh tổng hợp 2:** `exercise_total/docker_ps.png` – `quickbite-db` Up trên `5432`.  
**Ảnh tổng hợp 3:** `exercise_total/spring_boot_connected.png` – build JAR thành công + ứng dụng chạy kết nối PostgreSQL.  
**Kết quả thực tế:** Chưa ghi nhận / Chưa chụp.

## X. Kết luận và đối chiếu tiêu chí

| Tiêu chí | Trạng thái |
| --- | --- |
| Docker Engine chạy được trên Linux | Chưa kiểm chứng |
| PostgreSQL container Up tại 5432 | Chưa kiểm chứng |
| Spring Boot trên host kết nối DB Docker | Chưa kiểm chứng |
| psql liệt kê database | Chưa kiểm chứng |
| Log PostgreSQL được theo dõi | Chưa kiểm chứng |
| JRE container dùng bind mount JAR thành công | Chưa kiểm chứng |
| Staging script chạy và kiểm tra fail-fast | Chưa kiểm chứng |

**Đánh giá cuối cùng:** Điền sau khi chạy trên hệ thống thực và gắn ảnh bằng Markdown như `![Docker PS](exercise_01/db_status.png)`.
