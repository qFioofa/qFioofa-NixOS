# Расширения PostgreSQL для проекта "PG1 Pangolin ID" (School 21).
# Воспроизводит стек Pangolin SE на ванильном postgresql_17:
#   timescaledb  — временные ряды (ex01, ex04)
#   pg_cron      — планировщик + динамический SQL (ex01, ex03)
#   pgsql-http   — HTTP-запросы к open-meteo.com (ex01)
#   pgaudit      — аудит чтения/изменений (ex05)
# Мёрджится с базовым db.nix (сервис/пользователь/аутентификация там).
{ ... }:
{
  services.postgresql = {
    extensions = ps: with ps; [
      timescaledb
      pg_cron
      pgsql-http
      pgaudit
    ];

    settings = {
      # timescaledb, pg_cron и pgaudit обязаны грузиться через preload.
      shared_preload_libraries = "timescaledb,pg_cron,pgaudit";

      # pg_cron живёт в одной БД — совпадает с ensureDatabases в db.nix.
      # ponytail: захардкожено под текущую БД; вынести в let если БД сменится.
      "cron.database_name" = "qFioofa";
    };
  };
}
