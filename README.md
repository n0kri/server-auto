# server-auto v3.

    Устанавливает все зависимости (Docker, Java 17)

    Создает структуру папок

    Настраивает Docker-окружение

    Скачивает PaperMC 1.21.4

    Настраивает оптимизированный сервер

    Запускает сервер в Docker-контейнере
    
    Удален RCON и его настройки

    Удален цикл авто-перезапуска в start.sh

    Упрощен manage.sh (удалена команда backup)

    Добавлен явный enable-rcon=false в server.properties

этот скрипт предназначен для установки на vds/vps, он был сделан на Ubuntu 22.04 и был протестирован на 2v cpu и 4gb ram.

  #установка

вот что нужно сделать для его установки на чистый сервер Ubuntu/Debian

обновить систему командой sudo apt install -y wget curl

Скачайте скрипт: wget https://github.com/n0kri/server-auto.git -O setup-server.sh

Дайте права на выполнение: chmod +x setup-server.sh

Запустите установку: sudo ./setup-server.sh

или так: sudo apt update && sudo apt install -y wget && wget https://github.com/n0kri/server-auto.git -O setup-server.sh && chmod +x setup-server.sh && ./setup-server.sh

  #Где найти файлы после установки?

Все файлы будут в папке:

~/minecraft-server/

  #Управление сервером

Команды:

./manage.sh start    # Запустить сервер
./manage.sh stop     # Остановить
./manage.sh restart  # Перезапустить
./manage.sh console  # Открыть консоль

  #Подключение игроков

узнайте ip сервера командой: curl ifconfig.me

Игроки подключаются по адресу:
ваш-ip:25565

  #Дополнительные настройки

Как изменить параметры:

редактируйте файлы 

nano ~/minecraft-server/server.properties   Основные настройки
nano ~/minecraft-server/paper.yml        Оптимизация Paper

Перезапустите сервер:

./manage.sh restart

  #Важные параметры:
  можно изменять
  
server.properties
view-distance=6             # Дистанция загрузки чанков
max-players=20              # Лимит игроков
difficulty=normal           # Сложность

  #Обновление сервера

Остановите сервер:

./manage.sh stop

Скачайте новую версию PaperMC:

wget (ссылка на скачивание ядра)

Запустите:

./manage.sh start

Для мониторинга используйте:

docker stats minecraft-server
