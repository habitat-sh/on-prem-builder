mkdir -p /etc/systemd/system
cat <<EOT > /etc/systemd/system/hab-sup.service
[Unit]
Description=Habitat Supervisor

[Service]
ExecStartPre=/bin/bash -c "/bin/systemctl set-environment SSL_CERT_FILE=$(hab pkg path core/cacerts)/ssl/cert.pem"
ExecStart=/bin/hab run

[Install]
WantedBy=default.target
EOT

systemctl daemon-reload
systemctl start hab-sup