##
# INSTALL

# target install-mysql-database-%: Import %.mysql.gz to database %
# on local host
## it creates database %
## it creates user % with password % and all privileges on database %
## it imports %.mysql.gz file in database %
.PHONY: install-mysql-database-%
install-mysql-database-%: myos-base
	$(call exec,mysql -h mysql -u root -proot $* -e "use $*" >/dev/null 2>&1 || mysql -h mysql -u root -proot mysql -e "create database $* character set utf8 collate utf8_unicode_ci;")
	$(call exec,mysql -h mysql -u $* -p$* $* -e "use $*" >/dev/null 2>&1 || mysql -h mysql -u root -proot mysql -e "grant all privileges on $*.* to '\''$*'\''@'\''%'\'' identified by '\''$*'\''; flush privileges;")
	$(call exec,[ $$(mysql -h mysql -u $* -p$* $* -e "show tables" 2>/dev/null |wc -l) -eq 0 ] && [ -f "${APP_DIR}/$*.mysql.gz" ] && gzip -cd "${APP_DIR}/$*.mysql.gz" |mysql -h mysql -u root -proot $* || true)

# target install-pgsql-database-%: Import %.pgsql.gz to database %
# on local host
## it creates database %
## it creates user % with password % and all privileges on database %
## it imports %.pgsql.gz file in database %
.PHONY: install-pgsql-database-%
install-pgsql-database-%: myos-base
	$(call exec,PGPASSWORD=$* psql -h postgres -U $* template1 -c "\q" >/dev/null 2>&1 || PGPASSWORD=postgres psql -h postgres -U postgres -c "create user $* with createdb password '\''$*'\'';")
	$(call exec,PGPASSWORD=$* psql -h postgres -U $* -d $* -c "" >/dev/null 2>&1 || PGPASSWORD=postgres psql -h postgres -U postgres -c "create database $* owner $* ;")
	$(call exec,[ $$(PGPASSWORD=$* psql -h postgres -U $* -d $* -c "\d" 2>/dev/null |wc -l) -eq 0 ] && [ -f "${APP_DIR}/$*.pgsql.gz" ] && gzip -cd "${APP_DIR}/$*.pgsql.gz" |PGPASSWORD="postgres" psql -h postgres -U postgres -d $* || true)
	$(call exec,[ $$(PGPASSWORD=$* psql -h postgres -U $* -d $* -c "\d" 2>/dev/null |wc -l) -eq 0 ] && [ -f "${APP_DIR}/$*.pgsql" ] && PGPASSWORD="postgres" psql -h postgres -U postgres -c "ALTER ROLE $* WITH SUPERUSER" && PGPASSWORD="postgres" pg_restore -h postgres --no-owner --role=$* -U postgres -d $* ${APP_DIR}/$*.pgsql && PGPASSWORD="postgres" psql -h postgres -U postgres -c "ALTER ROLE $* WITH NOSUPERUSER" || true)

# target install-build-parameters: Call install-parameters with file * and dest build
.PHONY: install-build-parameters
install-build-parameters:
	$(call install-parameters,,*,build)

# target install-parameters: Call install-parameters
.PHONY: install-parameters
install-parameters:
	$(call install-parameters)

# target install-parameters-%: Call install-parameters with app %
.PHONY: install-parameters-%
install-parameters-%:
	$(call install-parameters,$*)
