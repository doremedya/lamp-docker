# Ortak LAMP ortamı - kısayollar
# Kullanım: make help

ver ?= 84
WEB  = php$(ver)_server
DBC ?= mariadb_103
COMPOSE = docker compose
WEB_KONTEYNERLER = php84_server php74_server php85_server

# Root şifresi .env'den okunur (yoksa root)
ROOT_PASS := $(shell grep -s '^MYSQL_ROOT_PASSWORD=' .env | cut -d= -f2-)
ROOT_PASS := $(if $(ROOT_PASS),$(ROOT_PASS),root)
MYSQL = docker exec -i -e MYSQL_PWD='$(ROOT_PASS)' $(DBC)

.DEFAULT_GOAL := help
.PHONY: help env up up-hepsi down build restart reload ps logs shell mysql \
        db-listesi db-olustur db-import db-export hosts site-ekle

help:
	@echo "Ortam"
	@echo "  make up                 web84 + db103 + phpMyAdmin başlatır"
	@echo "  make up-hepsi           PHP 7.4 / 8.5 ve MariaDB latest dahil hepsini başlatır"
	@echo "  make down | restart | ps | build"
	@echo "  make reload             vhost değişikliklerini yükler (apachectl graceful)"
	@echo "  make logs [ver=84]      PHP/Apache günlüklerini izler"
	@echo "  make shell [ver=84]     web konteynerine bash ile girer"
	@echo "Veritabanı"
	@echo "  make mysql                              mysql istemcisi"
	@echo "  make db-listesi"
	@echo "  make db-olustur DB=ad"
	@echo "  make db-import  DB=ad FILE=yedek.sql[.gz]"
	@echo "  make db-export  DB=ad                   -> yedekler/ad_TARIH.sql.gz"
	@echo "Siteler"
	@echo "  make site-ekle AD=madalya KLASOR=madalya.com.tr"
	@echo "  make hosts              sites/*.conf alan adlarını /etc/hosts'a ekler (sudo; DNS yoksa)"

env:
	@test -f .env || (cp .env.example .env && echo ".env oluşturuldu (.env.example'dan)")

up: env
	$(COMPOSE) up -d

up-hepsi: env
	$(COMPOSE) --profile eski --profile yeni --profile dblatest up -d

down:
	$(COMPOSE) --profile eski --profile yeni --profile dblatest down

build: env
	$(COMPOSE) --profile eski --profile yeni build

restart:
	$(COMPOSE) restart

ps:
	$(COMPOSE) ps

reload:
	@for c in $(WEB_KONTEYNERLER); do \
	  if docker ps --format '{{.Names}}' | grep -qx $$c; then docker exec $$c apachectl graceful && echo "$$c yeniden yüklendi"; fi; \
	done

logs:
	docker logs -f --tail 100 $(WEB)

shell:
	docker exec -it $(WEB) bash

mysql:
	docker exec -it -e MYSQL_PWD='$(ROOT_PASS)' $(DBC) mysql -uroot

db-listesi:
	@$(MYSQL) mysql -uroot -N -e "SHOW DATABASES" | grep -vE '^(information_schema|performance_schema|mysql|sys)$$'

db-olustur:
	@test -n "$(DB)" || (echo "Kullanım: make db-olustur DB=ad" && exit 1)
	@$(MYSQL) mysql -uroot -e "CREATE DATABASE IF NOT EXISTS \`$(DB)\` CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci"
	@echo "Veritabanı hazır: $(DB)"

db-import:
	@test -n "$(DB)" -a -n "$(FILE)" || (echo "Kullanım: make db-import DB=ad FILE=yedek.sql[.gz]" && exit 1)
	@test -f "$(FILE)" || (echo "Dosya bulunamadı: $(FILE)" && exit 1)
	@$(MAKE) --no-print-directory db-olustur DB=$(DB)
	@echo "İçe aktarılıyor: $(FILE) -> $(DB)"
	@case "$(FILE)" in \
	  *.gz) gunzip -c "$(FILE)" | $(MYSQL) mysql -uroot "$(DB)" ;; \
	  *)    $(MYSQL) mysql -uroot "$(DB)" < "$(FILE)" ;; \
	esac
	@echo "Tamam. Tablo sayısı: $$($(MYSQL) mysql -uroot -N -e "SELECT COUNT(*) FROM information_schema.tables WHERE table_schema='$(DB)'")"

db-export:
	@test -n "$(DB)" || (echo "Kullanım: make db-export DB=ad" && exit 1)
	@mkdir -p yedekler
	$(MYSQL) mysqldump -uroot --single-transaction --routines --triggers "$(DB)" | gzip > yedekler/$(DB)_$$(date +%Y%m%d_%H%M).sql.gz
	@ls -lh yedekler/$(DB)_*.sql.gz | tail -1

site-ekle:
	@test -n "$(AD)" -a -n "$(KLASOR)" || (echo "Kullanım: make site-ekle AD=madalya KLASOR=madalya.com.tr" && exit 1)
	@test -d "../$(KLASOR)" || (echo "Klasör yok: ~/projeler/$(KLASOR)" && exit 1)
	@test ! -f "sites/$(AD).conf" || (echo "Zaten var: sites/$(AD).conf" && exit 1)
	sed -e 's/__AD__/$(AD)/g' -e 's/__KLASOR__/$(KLASOR)/g' sites/_sablon.conf.tpl > sites/$(AD).conf
	@$(MAKE) --no-print-directory reload
	@echo "Hazır: http://$(AD).test  (OPNsense *.test kaydı yoksa: make hosts)"

hosts:
	@ADLAR="$$(grep -hE '^\s*Server(Name|Alias)' sites/*.conf | awk '{for(i=2;i<=NF;i++) print $$i}' | grep -v '^localhost$$' | sort -u)"; \
	EKLENECEK=""; for a in $$ADLAR; do grep -qE "[[:space:]]$$a([[:space:]]|$$)" /etc/hosts || EKLENECEK="$$EKLENECEK $$a"; done; \
	if [ -z "$$EKLENECEK" ]; then echo "/etc/hosts zaten güncel"; else \
	  echo "127.0.0.1$$EKLENECEK" | sudo tee -a /etc/hosts >/dev/null && echo "Eklendi:$$EKLENECEK"; fi
