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

# 9. Создание скрипта запуска start.sh (без авто-перезапуска)
cat > start.sh <<'EOL'
#!/bin/bash

# Оптимальные флаги Aikar для Java 17+
JVM_FLAGS="-Xms3G -Xmx3G -XX:+UseG1GC -XX:+ParallelRefProcEnabled -XX:MaxGCPauseMillis=200 -XX:+UnlockExperimentalVMOptions -XX:+DisableExplicitGC -XX:+AlwaysPreTouch -XX:G1NewSizePercent=30 -XX:G1MaxNewSizePercent=40 -XX:G1HeapRegionSize=8M -XX:G1ReservePercent=20 -XX:G1HeapWastePercent=5 -XX:G1MixedGCCountTarget=4 -XX:InitiatingHeapOccupancyPercent=15 -XX:G1MixedGCLiveThresholdPercent=90 -XX:G1RSetUpdatingPauseTimePercent=5 -XX:SurvivorRatio=32 -XX:+PerfDisableSharedMem -XX:MaxTenuringThreshold=1 -Dusing.aikars.flags=https://mcflags.emc.gs -Daikars.new.flags=true"

# Запуск сервера (без цикла перезапуска)
echo "Starting Minecraft server..."
exec java ${JVM_FLAGS} -jar paper.jar nogui
EOL

# 10. Настройка server.properties (без RCON)
cat > server.properties <<EOL
#Minecraft server properties
spawn-protection=16
max-tick-time=30000
server-port=25565
server-ip=
view-distance=6
simulation-distance=4
enable-rcon=false
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

# 12. Создание скрипта управления (упрощенного)
cat > manage.sh <<EOL
#!/bin/bash

case "\$1" in
  start)
    docker-compose up -d
    ;;
  stop)
    docker-compose down
    ;;
  restart)
    docker-compose restart
    ;;
  console)
    docker attach minecraft-server
    ;;
  *)
    echo "Usage: ./manage.sh {start|stop|restart|console}"
    exit 1
esac
EOL

# 13. Установка прав
chmod +x start.sh manage.sh

# 14. Сборка и запуск контейнера
docker-compose up -d --build

# 15. Инструкция
echo -e "\n\033[1;32mНастройка завершена!\033[0m"
echo "Сервер запущен на порту 25565"
echo "Для управления используйте:"
echo "  ./manage.sh start    - запустить сервер"
echo "  ./manage.sh stop     - остановить сервер"
echo "  ./manage.sh restart  - перезапустить сервер"
echo "  ./manage.sh console  - войти в консоль сервера"
EOF

# Делаем скрипт исполняемым
chmod +x setup-server.sh