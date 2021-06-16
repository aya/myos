##
# INSTALL

# target install-mysql-database-%: Import %.mysql.gz to database %
# on local host
## it creates database %
## it creates user % with password % and all privileges on database %
## it imports %.mysql.gz file in database %
.PHONY: install-mysql-database-%
install-mysql-database-%: $(if $(DOCKER_RUN),myos-base)
	$(call exec,mysql -h mysql -u root -proot $* -e "use $*" >/dev/null 2>&1) \
		|| $(call exec,$(RUN) mysql -h mysql -u root -proot mysql -e "create database $* character set utf8 collate utf8_unicode_ci;")
	$(call exec,mysql -h mysql -u $* -p$* $* -e "use $*" >/dev/null 2>&1) \
		|| $(call exec,$(RUN) mysql -h mysql -u root -proot mysql -e "grant all privileges on $*.* to '$*'@'%' identified by '$*'; flush privileges;")
	$(call exec,sh -c '[ $$(mysql -h mysql -u $* -p$* $* -e "show tables" 2>/dev/null |wc -l) -eq 0 ] && [ -f "${APP_DIR}/$*.mysql.gz" ]') \
		&& $(call exec,$(RUN) sh -c 'gzip -cd "${APP_DIR}/$*.mysql.gz" |mysql -h mysql -u root -proot $*') \
		||:

# target install-pgsql-database-%: Import %.pgsql.gz to database %
# on local host
## it creates database %
## it creates user % with password % and all privileges on database %
## it imports %.pgsql.gz file in database %
.PHONY: install-pgsql-database-%
install-pgsql-database-%: myos-base
	$(call exec,PGPASSWORD=$* psql -h postgres -U $* template1 -c "\q" >/dev/null 2>&1) \
		|| $(call exec,$(RUN) PGPASSWORD=postgres psql -h postgres -U postgres -c "create user $* with createdb password '$*';")
	$(call exec,PGPASSWORD=$* psql -h postgres -U $* -d $* -c "" >/dev/null 2>&1) \
		|| $(call exec,$(RUN) PGPASSWORD=postgres psql -h postgres -U postgres -c "create database $* owner $* ;")
	$(call exec,[ $$(PGPASSWORD=$* psql -h postgres -U $* -d $* -c "\d" 2>/dev/null |wc -l) -eq 0 ] && [ -f "${APP_DIR}/$*.pgsql.gz" ]) \
		&& $(call exec,$(RUN) sh -c 'gzip -cd "${APP_DIR}/$*.pgsql.gz" |PGPASSWORD="postgres" psql -h postgres -U postgres -d $*') \
		||:
	$(call exec,[ $$(PGPASSWORD=$* psql -h postgres -U $* -d $* -c "\d" 2>/dev/null |wc -l) -eq 0 ] && [ -f "${APP_DIR}/$*.pgsql" ]) \
		&& $(call exec,$(RUN) sh -c 'PGPASSWORD="postgres" psql -h postgres -U postgres -c "ALTER ROLE $* WITH SUPERUSER" && PGPASSWORD="postgres" pg_restore -h postgres --no-owner --role=$* -U postgres -d $* ${APP_DIR}/$*.pgsql && PGPASSWORD="postgres" psql -h postgres -U postgres -c "ALTER ROLE $* WITH NOSUPERUSER"') \
		||:

# target install-build-config: Call install-config with file * and dest build
.PHONY: install-build-config
install-build-config:
	$(call install-config,,*,build)

# target install-config: Call install-config
.PHONY: install-config
install-config:
	$(call install-config)

# target install-config-%: Call install-config with app %
.PHONY: install-config-%
install-config-%:
	$(call install-config,$*)
