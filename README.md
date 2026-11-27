# lamp — ortak PHP geliştirme ortamı

`~/projeler` altındaki tüm PHP projelerine hizmet eden Docker tabanlı Apache + PHP + MariaDB + phpMyAdmin ortamı.

```
~/projeler/
├── lamp/                          ← bu repo
├── mezuniyetfotografcisi.com.tr/  → http://mezuniyetfotografcisi.test
└── madalya.com.tr/                → http://madalya.test  (make site-ekle ile)
```

| Servis | Konteyner | Adres | Varsayılan |
|---|---|---|---|
| PHP 8.4 + Apache | `php84_server` | `:80` · 192.168.10.20 | açık |
| PHP 7.4 + Apache | `php74_server` | `:81` · 192.168.10.10 | profil `eski` |
| PHP 8.5 + Apache | `php85_server` | `:82` · 192.168.10.30 | profil `yeni` |
| MariaDB 10.3 | `mariadb_103` | `:3306` · iç ad `db103` | açık |
| MariaDB latest | `mariadb_latest` | `:3307` · iç ad `db_latest` | profil `dblatest` |
| phpMyAdmin | `pma_panel` | http://pma.test veya `:9000` | açık |
| Mailpit (sahte SMTP) | `mailpit` | http://mail.test veya `:8025` · SMTP `mailpit:1025` | açık |

## E-posta: Mailpit
Geliştirmede gerçek müşterilere e-posta gitmemesi için tüm e-postalar Mailpit'te yakalanır ve http://mail.test adresinde görüntülenir.
- Projelerde SMTP ayarı: host `mailpit`, port `1025`, kimlik doğrulama ve TLS yok.
- Mezuniyet projesi bunu kendisi yapar: `APP_ENV=local` iken veritabanındaki SMTP ayarlarını yok sayar ve sadece Mailpit'e gönderir. SMS ise hiç gönderilmez.
- Yeni bir projede de aynı kural uygulanmalı: yerelde gerçek SMTP veya SMS servisine asla bağlanılmamalı.

Konteyner adları, IP'ler ve `lamp_app_network` ağ adı sabittir. Projelerin test betikleri bunlara güvenir, değiştirmeyin.

## Kurulum (Ubuntu)
```bash
cd ~/projeler
git clone git@github.com:doremedya/lamp-docker.git lamp
cd lamp
make build      # .env yoksa .env.example'dan oluşturur
make up
```
- Kullanıcınız `docker` grubunda olmalı: `sudo usermod -aG docker $USER`, ardından oturumu yeniden açın.
- `.env` içinde `UID`/`GID` değerleri `id -u` / `id -g` ile aynı olmalı. Apache bu kimlikle çalıştığı için `uploads/` gibi klasörlerde izin sorunu çıkmaz, `chmod 777` gerekmez.
- `MYSQL_ROOT_PASSWORD` sadece veritabanı volume'ü ilk oluşurken uygulanır.

Projenin kendi `.env` dosyasında veritabanı ayarı:
```
DB_HOST=db103
DB_USER=root
DB_PASS=root
```

## Günlük kullanım
```bash
make up | down | ps | restart
make up-hepsi            # 7.4, 8.5 ve MariaDB latest dahil
make logs ver=84         # PHP hataları ve Apache günlüğü
make shell ver=74
make mysql
```

## Veritabanı
```bash
make db-olustur DB=mezuniyetfotografcisi
make db-import  DB=mezuniyetfotografcisi FILE=~/indirilenler/yedek.sql.gz   # .sql de olur
make db-export  DB=mezuniyetfotografcisi                                    # yedekler/ klasörüne
make db-listesi
```
Veriler `mariadb_db103_data` adlı Docker volume'ünde durur ve `make down` ile silinmez.

## Yeni proje ekleme
```bash
# ~/projeler/madalya.com.tr klasörü hazırken:
make site-ekle AD=madalya KLASOR=madalya.com.tr
```
Komut `sites/madalya.conf` dosyasını oluşturur ve Apache'yi yeniden yükler. Site `madalya.test`, `www.madalya.test` ve `test.madalya.test` adreslerinden açılır. Elle düzenleme yaptıysanız `make reload` çalıştırın.

## Alan adları (DNS)
Tercih edilen yöntem, `*.test` kaydını ağdaki DNS'e bir kez eklemek. Böylece her yeni proje için hosts dosyası düzenlemek gerekmez.

**OPNsense (Unbound DNS)**
1. Services → Unbound DNS → Overrides → Host: `*`, Domain: `test`, IP: bu makinenin LAN IP'si (ör. `192.168.20.101`).
   Wildcard kaydı kabul edilmezse Advanced / Custom options alanına şunu yazın:
   ```
   local-zone: "test." redirect
   local-data: "test. A 192.168.20.101"
   ```
2. Access Lists bölümünde Tailscale aralığına (`100.64.0.0/10`) izin verin.

**Tailscale (OPNsense subnet router olarak `192.168.20.0/24` ağını duyuruyor)**
1. Admin → DNS → Nameservers → Add nameserver → `192.168.20.1` → *Restrict to domain*: `test`.
   Bu adım yapılmazsa uzaktaki cihazlar sorguyu MagicDNS'e sorar ve `.test` adları çözülmez.
2. Linux istemcilerde rotaları kabul edin: `sudo tailscale up --accept-routes`. Windows ve Mac rotaları kendiliğinden kabul eder.
3. Uzaktaki cihazın kendi yerel ağı `192.168.20.0/24` ile çakışmamalı.

**DNS yoksa (yedek yöntem):** `make hosts` komutu `sites/*.conf` içindeki tüm alan adlarını `127.0.0.1` olarak `/etc/hosts` dosyasına ekler (sudo ister).

## Güvenlik
- DB (3306) ve phpMyAdmin (9000) varsayılan olarak tüm arayüzlerde, yani LAN ve tailnet'te dinler.
- Docker, `ufw` kurallarını atlar. Bu portları kısıtlamak için `.env` içinde `DB_BIND=127.0.0.1` / `PMA_BIND=127.0.0.1` yapın ya da OPNsense'te tailscale arayüzü için kural yazın.
- Ortam başka cihazlardan erişilebiliyorsa varsayılan `root` şifresini değiştirin.

## Notlar
- `php:7.4.33` imajı Debian bullseye tabanlı olduğu için paketler `archive.debian.org` adresinden alınır.
- Tüm konteynerlerde `tr_TR.UTF-8` locale'i ve opcache bulunur. Opcache dosya değişikliklerini anında algılar.
- Ortak PHP ayarları `config/php.ini` dosyasındadır. Değişiklikten sonra `make restart` çalıştırın.
