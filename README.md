# LKPD 5 - Docker Compose

## Petunjuk Awal
Instance/mesin yang digunakan adalah Ubuntu/Debian.

## Pengantar
Docker Compose adalah alat untuk menjalankan banyak container sekaligus (misalnya webserver + database) dengan satu file konfigurasi, sehingga tidak perlu mengetik perintah `docker run` satu per satu seperti pada LKPD 2 dan LKPD 3.

## Langkah Kerja

### A. Instal Paket Docker Compose (Jika Belum Ada)

#### 1. Install Docker Compose
```bash
sudo apt update
sudo apt install -y docker-compose
```

Atau jika menggunakan Docker Compose v2 (plugin resmi):
```bash
sudo apt update
sudo apt install -y docker-compose-plugin
```

**Catatan:** Jika `docker-compose-plugin` tidak tersedia di repository, gunakan `docker-compose` (standalone) yang sudah terinstall.

#### 2. Cek versi
```bash
docker-compose --version
# atau untuk v2
docker compose version
```

#### 3. Setup Permission Docker (PENTING)
Jika mengalami error "permission denied while trying to connect to the docker API":
```bash
# Tambahkan user ke group docker
sudo usermod -aG docker $USER
sudo newgrp docker

# Verifikasi docker bisa diakses tanpa sudo
docker --version
docker ps
```

**Catatan Penting:**
- Setelah menjalankan `sudo newgrp docker`, shell akan berubah ke root (prompt berubah dari `$` ke `#`)
- Lanjutkan dengan perintah docker tanpa sudo
- Jika masih error permission denied, gunakan `sudo` di depan perintah docker
- Error ini sering terjadi jika user belum ditambahkan ke group docker

---

### B. Konsep Dasar

Daripada menggunakan perintah manual seperti berikut:
```bash
docker network create mynet
docker run -d --name dbserver --network mynet -e MYSQL_ROOT_PASSWORD=pass123 mariadb:11-jammy
docker run -d --name webserver --network mynet -p 8088:80 -v /var/mywww:/var/www/html ubuntu:v2 apache2ctl -D FOREGROUND
```

Semua perintah tersebut cukup ditulis ke dalam satu file `docker-compose.yml`, lalu jalankan dengan satu perintah saja:
```bash
docker-compose up -d
```

**Catatan:** Pastikan sudah ada Dockerfile di folder yang sama sebelum menjalankan compose, karena service webserver pada contoh ini menggunakan `build: .` (build dari Dockerfile lokal).

---

### C. Buat File docker-compose.yml

**⚠️ PENTING:** Disarankan untuk clone repository ini agar file docker-compose.yml dan Dockerfile otomatis terisi tanpa perlu input manual. Lihat opsi 1 di bawah.

#### 1. Buat direktori kerja
```bash
mkdir ~/compose
cd ~/compose
```

#### 2. Clone repository (Opsi 1 - Rekomendasi)
Clone repository ini untuk mendapatkan file docker-compose.yml dan Dockerfile secara otomatis:
```bash
git clone https://github.com/Deri-Nugroho/docker-5.git .
```

Dengan cara ini, file-file yang dibutuhkan (docker-compose.yml, Dockerfile, README.md) akan otomatis terisi tanpa perlu input manual.

**Lanjut ke langkah D. Menjalankan Docker Compose**

---

#### 3. Buat file docker-compose.yml manual (Opsi 2)
Jika ingin membuat file secara manual:
```bash
nano docker-compose.yml
```

Isi dengan:
```yaml
version: "3.9"

services:
  dbserver:
    image: mariadb:11-jammy
    environment:
      MYSQL_ROOT_PASSWORD: pass123
    networks:
      - mynet
    volumes:
      - db-data:/var/lib/mysql

  webserver:
    build: .            # pakai Dockerfile di folder ini (seperti LKPD 3)
    container_name: webserver
    ports:
      - "8088:80"
    volumes:
      - /var/mywww:/var/www/html
    depends_on:
      - dbserver
    networks:
      - mynet
    restart: unless-stopped

networks:
  mynet:

volumes:
  db-data:
```

#### 3. Buat Dockerfile (untuk service webserver)
Jika belum ada Dockerfile di folder yang sama, buat seperti di LKPD 3:
```bash
nano Dockerfile
```

Isi dengan:
```dockerfile
FROM ubuntu:24.04

# Supaya apt install tidak nanya interaktif
ENV DEBIAN_FRONTEND=noninteractive

# Install Apache, PHP, dan modul yang dibutuhkan aplikasi
RUN apt update && apt install -y \
	nano \
	apache2 \
	php \
	php-mysqli \
	php-mysql \
	libapache2-mod-php \
	mysql-client \
	curl \
	&& apt clean && rm -rf /var/lib/apt/lists/*

# Expose port HTTP
EXPOSE 80

# Jalankan Apache sebagai proses utama (foreground)
CMD ["apache2ctl", "-D", "FOREGROUND"]
```

---

### D. Menjalankan Docker Compose

#### 4. Siapkan folder aplikasi
```bash
sudo mkdir -p /var/mywww
sudo git clone https://github.com/Deri-Nugroho/docker-2.git /var/mywww
sudo chown -R $USER:$USER /var/mywww
sudo mkdir -p /var/mywww/uploads
sudo chown -R www-data:www-data /var/mywww/uploads
```

**Catatan Penting:**
- Jika mengalami error "read-only file system" saat mount volume di langkah 5, gunakan lokasi di home directory:
  ```bash
  mkdir -p ~/mywww
  git clone https://github.com/Deri-Nugroho/docker-2.git ~/mywww
  mkdir -p ~/mywww/uploads
  sudo chown -R www-data:www-data ~/mywww/uploads
  ```
  Lalu ubah volume di docker-compose.yml dari `/var/mywww:/var/www/html` menjadi `~/mywww:/var/www/html`

#### 5. Jalankan semua service dengan docker-compose
```bash
docker-compose up -d
```

Perintah ini akan:
- Membuat network `compose_mynet` secara otomatis (nama network akan memiliki prefix nama folder)
- Build image dari Dockerfile (jika belum ada)
- Menjalankan container `dbserver` dan `webserver`
- Menghubungkan keduanya ke network yang sama
- Membuat volume `compose_db-data` untuk persistensi database

**Catatan:**
- Proses ini akan memakan waktu beberapa menit karena perlu pull image mariadb dan build image webserver
- Container name akan memiliki prefix: `compose_dbserver_1` dan `compose_webserver_1` (nama folder + nama service)
- Network name akan menjadi `compose_mynet` (nama folder + nama network)

#### 6. Cek status container
```bash
docker-compose ps
```

Pastikan kedua service berstatus `Up`.

**Error yang mungkin terjadi:**
- Jika salah satu container status `Exited`, cek log dengan `docker-compose logs <nama-service>`
- Jika webserver exited karena error, biasanya karena issue dengan volume mount atau Dockerfile

#### 7. Lihat log service
```bash
# Lihat log semua service
docker-compose logs -f

# Lihat log webserver saja
docker-compose logs -f webserver

# Lihat log dbserver saja
docker-compose logs -f dbserver
```

#### 8. Buat database yang dibutuhkan aplikasi
```bash
docker-compose exec dbserver mariadb -u root -ppass123 -e "CREATE DATABASE toko_db;"
```

#### 9. Restart webserver agar connect ke database
```bash
docker-compose restart webserver
```

#### 10. Verifikasi koneksi webserver ke dbserver
```bash
docker-compose exec webserver bash -c "mysql -h dbserver -u root -ppass123 -e 'SHOW DATABASES;'"
```

#### 11. Akses web server
```bash
curl http://localhost:8088
```

Atau buka lewat browser: `http://<IP-server>:8088`

---

### E. Referensi Perintah-Perintah Utama

| Perintah | Fungsi |
|----------|--------|
| `docker-compose up -d` | Membuat network, build image (jika ada build:), lalu menjalankan semua service di background |
| `docker-compose ps` | Lihat status container yang dikelola compose |
| `docker-compose logs -f webserver` | Lihat log salah satu service |
| `docker-compose exec webserver bash` | Masuk ke shell container |
| `docker-compose down` | Hentikan & hapus container + network (volume tetap ada) |
| `docker-compose down -v` | Hentikan & hapus termasuk volume (data database ikut hilang) |
| `docker-compose build` | Build ulang image dari Dockerfile jika ada perubahan |
| `docker-compose restart` | Restart semua service |
| `docker-compose stop` | Hentikan semua service tanpa menghapus container |
| `docker-compose start` | Jalankan ulang service yang sudah dihentikan |

---

### F. Perintah Alternatif (Docker Compose v2)

Jika menggunakan Docker Compose plugin resmi (v2), perintah yang sama dapat ditulis tanpa tanda strip:

| Perintah v1 (standalone) | Perintah v2 (plugin) |
|-------------------------|---------------------|
| `docker-compose up -d` | `docker compose up -d` |
| `docker-compose ps` | `docker compose ps` |
| `docker-compose logs -f` | `docker compose logs -f` |
| `docker-compose down` | `docker compose down` |
| `docker-compose build` | `docker compose build` |

**Catatan:** Kedua gaya perintah di atas bisa digunakan tergantung versi Docker Compose yang terinstall di sistem Anda.

---

### G. Perintah Bantuan (Troubleshooting)

| Kebutuhan | Command |
|-----------|---------|
| Lihat log error | `docker-compose logs` |
| Lihat log real-time | `docker-compose logs -f` |
| Masuk ke shell container | `docker-compose exec webserver bash` |
| Masuk ke shell dbserver | `docker-compose exec dbserver mariadb -u root -ppass123` |
| Restart satu service | `docker-compose restart webserver` |
| Hapus semua container & network | `docker-compose down` |
| Hapus semua termasuk volume | `docker-compose down -v` |
| Build ulang image | `docker-compose build --no-cache` |
| Lihat konfigurasi compose | `docker-compose config` |

---

### H. Error yang Sering Terjadi dan Solusinya

#### 1. Permission Denied saat menjalankan docker-compose

**Error:**
```
permission denied while trying to connect to the docker API at unix:///var/run/docker.sock
```

**Solusi:**
```bash
# Tambahkan user ke group docker
sudo usermod -aG docker $USER
sudo newgrp docker

# Lanjutkan dengan perintah docker-compose
docker-compose up -d
```

**Catatan:** Setelah `sudo newgrp docker`, shell akan berubah ke root. Lanjutkan tanpa sudo.

#### 2. Dockerfile tidak ditemukan

**Error:**
```
ERROR: Cannot build: Dockerfile not found
```

**Solusi:**
Pastikan Dockerfile ada di folder yang sama dengan docker-compose.yml:
```bash
ls -la Dockerfile
# Jika belum ada, buat Dockerfile seperti di langkah C.3
```

#### 3. Port sudah digunakan

**Error:**
```
ERROR: for webserver  Cannot start service webserver: driver failed programming external connectivity...
bind: address already in use
```

**Solusi:**
```bash
# Cek apa yang menggunakan port 8088
sudo lsof -i :8088

# Atau ubah port di docker-compose.yml
ports:
  - "8089:80"  # ganti ke port lain
```

#### 4. Volume mount permission denied

**Error:**
```
ERROR: for webserver  Cannot start service webserver: error while creating mount source path...
```

**Solusi:**
Gunakan lokasi di home directory seperti di LKPD 4:
```yaml
# Di docker-compose.yml, ubah:
volumes:
  - ~/mywww:/var/www/html  # gunakan ~/mywww bukan /var/mywww
```

Lalu:
```bash
mkdir -p ~/mywww
git clone https://github.com/Deri-Nugroho/docker-2.git ~/mywww
mkdir -p ~/mywww/uploads
sudo chown -R www-data:www-data ~/mywww/uploads
```

#### 5. Database connection failed

**Error:**
Web server error 500 atau koneksi database gagal.

**Solusi:**
```bash
# Pastikan dbserver sudah berjalan
docker-compose ps

# Buat database
docker-compose exec dbserver mariadb -u root -ppass123 -e "CREATE DATABASE toko_db;"

# Restart webserver
docker-compose restart webserver

# Verifikasi koneksi
docker-compose exec webserver bash -c "mysql -h dbserver -u root -ppass123 -e 'SHOW DATABASES;'"
```

#### 6. curl tidak menampilkan output (HTTP 302 Redirect)

**Error:**
```bash
curl http://localhost:8088
# Tidak menampilkan output apa-apa
```

**Penjelasan:**
Ini bukan error. Web server mengembalikan HTTP 302 redirect ke `login.php`, yang mana curl tidak menampilkan output untuk redirect.

**Solusi:**
```bash
# Coba akses dengan verbose untuk melihat redirect
curl -v http://localhost:8088

# Atau akses login.php langsung
curl http://localhost:8088/login.php

# Atau akses via browser
# http://<IP-server>:8088
# http://<IP-server>:8088/login.php
```

**Contoh output yang normal:**
```
< HTTP/1.1 302 Found
< Location: login.php
```

Ini menunjukkan aplikasi berjalan dengan benar dan redirect ke halaman login.

#### 8. Container name berbeda dari yang diharapkan

**Problem:**
Container name tidak sesuai dengan yang ada di dokumentasi (misal: `compose_dbserver_1` bukan `dbserver`).

**Penjelasan:**
Docker Compose otomatis menambahkan prefix nama folder ke container name dan network name.

**Contoh:**
- Folder: `~/compose`
- Container dbserver: `compose_dbserver_1`
- Container webserver: `compose_webserver_1` atau `webserver` (jika ada `container_name` di docker-compose.yml)
- Network: `compose_mynet`

**Solusi:**
Gunakan perintah docker-compose untuk mengelola container, jangan gunakan perintah docker biasa:
```bash
# ✅ Benar
docker-compose exec dbserver mariadb -u root -ppass123
docker-compose logs webserver

# ❌ Salah (container name tidak sesuai)
docker exec dbserver mariadb -u root -ppass123
docker logs dbserver
```

#### 9. Error "Can't find a suitable configuration file"

**Error:**
```
ERROR:
        Can't find a suitable configuration file in this directory or any
        parent. Are you in the right directory?
```

**Solusi:**
Pastikan berada di folder yang berisi file `docker-compose.yml`:
```bash
# Cek posisi folder saat ini
pwd

# Pindah ke folder yang berisi docker-compose.yml
cd ~/compose

# Cek file ada
ls -la docker-compose.yml

# Jalankan docker-compose
docker-compose up -d
```

#### 10. Advanced: Menambah Healthcheck untuk Database (Opsional)

**Problem:**
Webserver mulai sebelum database siap, menyebabkan error koneksi saat pertama kali dijalankan.

**Solusi Tambah healthcheck:**
```yaml
services:
  dbserver:
    image: mariadb:11-jammy
    environment:
      MYSQL_ROOT_PASSWORD: pass123
    healthcheck:
      test: ["CMD", "mysqladmin", "ping", "-h", "localhost", "-u", "root", "-ppass123"]
      interval: 10s
      timeout: 5s
      retries: 5

  webserver:
    build: .
    depends_on:
      dbserver:
        condition: service_healthy
```

**Catatan:** Solusi ini opsional. Cara yang lebih sederhana adalah dengan menjalankan:
```bash
docker-compose up -d
docker-compose exec dbserver mariadb -u root -ppass123 -e "CREATE DATABASE toko_db;"
docker-compose restart webserver
```

---

### I. Catatan Penting

- **Volume persisten:** Volume `db-data` akan menyimpan data database meskipun container dihapus (kecuali jika menggunakan `docker-compose down -v`)
- **Network otomatis:** Docker Compose akan membuat network secara otomatis dengan prefix nama folder (misal: `compose_mynet`)
- **Nama container:** Container yang dikelola compose akan memiliki prefix nama folder (misal: `compose_dbserver_1`), kecuali jika menggunakan `container_name` di docker-compose.yml
- **File changes:** Jika ada perubahan di Dockerfile, jalankan `docker-compose build` sebelum `docker-compose up -d`
- **Rebuild image:** Gunakan `docker-compose build --no-cache` untuk build ulang tanpa cache
- **Environment variables:** Gunakan file `.env` untuk menyimpan password dan konfigurasi sensitif, jangan hardcode di docker-compose.yml
- **Permission docker:** SELALU jalankan `sudo usermod -aG docker $USER` dan `sudo newgrp docker` sebelum menggunakan docker-compose untuk menghindari permission denied
- **Folder positioning:** SELALU pastikan berada di folder yang berisi `docker-compose.yml` sebelum menjalankan perintah docker-compose
- **Volume mount:** Jika mengalami error "read-only file system", gunakan lokasi di home directory (`~/mywww`) bukan `/var/mywww`
- **Restart setelah database:** SELALU restart webserver setelah membuat database agar koneksi terjalin dengan benar
- **HTTP 302 normal:** `curl http://localhost:8088` tidak menampilkan output adalah normal karena redirect ke login.php. Gunakan `curl http://localhost:8088/login.php` atau akses via browser

- **Volume persisten:** Volume `db-data` akan menyimpan data database meskipun container dihapus (kecuali jika menggunakan `docker-compose down -v`)
- **Network otomatis:** Docker Compose akan membuat network secara otomatis, tidak perlu membuat network manual
- **Nama container:** Container yang dikelola compose akan memiliki prefix nama folder (misal: `compose_webserver_1`)
- **File changes:** Jika ada perubahan di Dockerfile, jalankan `docker-compose build` sebelum `docker-compose up -d`
- **Rebuild image:** Gunakan `docker-compose build --no-cache` untuk build ulang tanpa cache
- **Environment variables:** Gunakan file `.env` untuk menyimpan password dan konfigurasi sensitif, jangan hardcode di docker-compose.yml

---

### J. Best Practices

1. **Gunakan .env file untuk konfigurasi sensitif:**
   ```yaml
   environment:
     MYSQL_ROOT_PASSWORD: ${MYSQL_ROOT_PASSWORD}
   ```

2. **Gunakan version yang tepat:**
   - `version: "3.8"` untuk Docker Engine 19.03+
   - `version: "3.9"` untuk Docker Engine 20.10+

3. **Tentukan restart policy:**
   ```yaml
   restart: unless-stopped  # restart otomatis kecuali di-stop manual
   restart: always         # restart selalu
   restart: on-failure     # restart hanya jika gagal
   ```

4. **Limit resource (opsional):**
   ```yaml
   deploy:
     resources:
       limits:
         cpus: '0.50'
         memory: 512M
   ```

5. **Gunakan named volume untuk persistensi data:**
   ```yaml
   volumes:
     db-data:
       driver: local
   ```
