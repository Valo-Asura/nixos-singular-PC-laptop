{ pkgs, ... }:

pkgs.writeShellScriptBin "mysql-local-info" ''
  cat <<'EOF'
  MySQL local service
    service: systemctl status mysql
    cli:     mysql -u asura asura_dev
    shell:   mysqlsh --sql asura@localhost:3306
    gui:     mysql-workbench

  Paths
    config:  /etc/my.cnf
    data:    /var/lib/mysql
    socket:  /run/mysqld/mysqld.sock
    binary:  /run/current-system/sw/bin/mysql
  EOF
''
