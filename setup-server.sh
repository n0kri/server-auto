cat > setup-server.sh << 'EOF'
#!/bin/bash

# 1. Обновление системы
sudo apt update && sudo apt upgrade -y

# 2. Установка необходимых компонентов
sudo apt install -y git docker.io openjdk-17-jdk nano

# 3. Включение и запуск Docker
sudo systemctl enable --now docker

# 4. Создание рабочей директории
mkdir minecraft-server
cd minecraft-server

# 5. Создание Dockerfile
cat > Dockerfile <<EOL
FROM openjdk:17-jdk

# Установка необходимых утилит
RUN apt-get update && apt-get install -y nano

# Создание директории для сервера
RUN mkdir /app
WORKDIR /app

# Копирование файлов сервера
COPY . .

# Разрешение на выполнение скриптов
RUN chmod +x start.sh

# Открытие порта Minecraft
EXPOSE 25565

# Команда запуска
CMD ["./start.sh"]
EOL

# 6. Создание docker-compose.yml
cat > docker-compose.yml <<EOL
version: '3.8'
services:
  minecraft:
    build: .
    container_name: minecraft-server
    restart: unless-stopped
    ports:
      - "25565:25565"
    volumes:
      - ./data:/app
    tty: true
    stdin_open: true
    environment:
      TZ: Europe/Moscow
    mem_limit: 4g
    mem_reservation: 3g
EOL

# 7. Создание директории данных
mkdir data

# 8. Скачивание Paper 1.21.4
wget https://api.papermc.io/v2/projects/paper/versions/1.21.4/builds/378/downloads/paper-1.21.4-378.jar -O paper.jar

# 9. Создание скрипта запуска start.sh
cat > start.sh <<'EOL'
#!/bin/bash

# Оптимальные флаги Aikar для Java 17+
JVM_FLAGS="-Xms3G -Xmx3G -XX:+UseG1GC -XX:+ParallelRefProcEnabled -XX:MaxGCPauseMillis=200 -XX:+UnlockExperimentalVMOptions -XX:+DisableExplicitGC -XX:+AlwaysPreTouch -XX:G1NewSizePercent=30 -XX:G1MaxNewSizePercent=40 -XX:G1HeapRegionSize=8M -XX:G1ReservePercent=20 -XX:G1HeapWastePercent=5 -XX:G1MixedGCCountTarget=4 -XX:InitiatingHeapOccupancyPercent=15 -XX:G1MixedGCLiveThresholdPercent=90 -XX:G1RSetUpdatingPauseTimePercent=5 -XX:SurvivorRatio=32 -XX:+PerfDisableSharedMem -XX:MaxTenuringThreshold=1 -Dusing.aikars.flags=https://mcflags.emc.gs -Daikars.new.flags=true"

# Автоперезапуск при падении
while true; do
  echo "Starting Minecraft server..."
  java ${JVM_FLAGS} -jar paper.jar nogui
  
  # Проверка кода выхода для плановой остановки
  if [ $? -eq 0 ]; then
    echo "Server stopped intentionally."
    exit 0
  fi
  
  echo "Server crashed! Restarting in 10 seconds..."
  sleep 10
done
EOL

# 10. Настройка server.properties
cat > server.properties <<EOL
#Minecraft server properties
spawn-protection=16
max-tick-time=30000
server-port=25565
server-ip=
view-distance=6
simulation-distance=4
EOL

# 11. Настройка paper.yml
cat > paper.yml <<EOL
world-settings:
  default:
    entity-tracking-range:
      players: 48
    ticks-per:
      trident-riptide-check: 1
    mob-spawning:
      max-entity-per-chunk: 25
    entity:
      max-entity-collisions: 2
    chunks:
      max-auto-save-chunks-per-tick: 20
      delay-chunk-unloads-by: 10s
EOL

# 12. Создание скрипта управления
cat > manage.sh <<EOL
#!/bin/bash

case "\$1" in
  start)
    docker-compose up -d
    ;;
  stop)
    docker exec minecraft-server rcon-cli stop
    ;;
  restart)
    docker-compose restart
    ;;
  console)
    docker attach minecraft-server
    ;;
  backup)
    docker exec minecraft-server rcon-cli save-off
    docker exec minecraft-server rcon-cli save-all
    tar -czvf backup-\$(date +%Y-%m-%d-%H-%M-%S).tar.gz data/
    docker exec minecraft-server rcon-cli save-on
    ;;
  *)
    echo "Usage: ./manage.sh {start|stop|restart|console|backup}"
    exit 1
esac
EOL

# 13. Установка прав
chmod +x start.sh manage.sh

# 14. Сборка и запуск контейнера
docker-compose up -d --build

# 15. Установка RCON (для удаленного управления)
docker exec minecraft-server wget https://github.com/itzg/rcon-cli/releases/download/1.6.1/rcon-cli_1.6.1_linux_amd64.tar.gz
docker exec minecraft-server tar -xzf rcon-cli_1.6.1_linux_amd64.tar.gz
docker exec minecraft-server mv rcon-cli /usr/local/bin/

# 16. Настройка RCON в server.properties
echo "enable-rcon=true" >> data/server.properties
echo "rcon.password=\$(openssl rand -base64 12)" >> data/server.properties
echo "rcon.port=25575" >> data/server.properties

# 17. Перезапуск сервера для применения настроек
docker-compose restart

# 18. Инструкция
echo -e "\n\033[1;32mНастройка завершена!\033[0m"
echo "Сервер запущен на порту 25565"
echo "Для управления используйте:"
echo "  ./manage.sh start    - запустить сервер"
echo "  ./manage.sh stop     - остановить сервер"
echo "  ./manage.sh restart  - перезапустить сервер"
echo "  ./manage.sh console  - войти в консоль сервера"
echo "  ./manage.sh backup   - создать резервную копию"
echo ""
echo "Пароль RCON: \033[1;33m\$(grep 'rcon.password' data/server.properties | cut -d= -f2)\033[0m"
echo "RCON порт: 25575"
EOF

# Делаем скрипт исполняемым
chmod +x setup-server.sh