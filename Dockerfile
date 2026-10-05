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
