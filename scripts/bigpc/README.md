# bigPC Bootstrap — Structurizr (on-prem, local-режим) в LAN через WSL + portproxy

Поднимает архитектурный портал [Structurizr](https://docs.structurizr.com/onpremises) (on-prem, local-режим) на bigPC, доступный по `http://bigPC:8080` из локальной сети. После настройки всё восстанавливается автоматически после перезагрузки.

Соответствует **варианту Б** из [`docs/_planning/05-rebuild-plan.md`](../../docs/_planning/05-rebuild-plan.md) раздел 4.1.

## Состав

| Скрипт | Где запускать | Что делает |
|---|---|---|
| [`setup-wsl.sh`](./setup-wsl.sh) | **WSL** на bigPC (любой пользователь, sudo для `apt`/Docker) | Ставит Docker (если нет), клонирует/обновляет репо, запускает контейнер `azimuth-arch` со Structurizr (on-prem, local-режим) в режиме `--restart=unless-stopped` |
| [`setup-windows.ps1`](./setup-windows.ps1) | **Windows PowerShell от админа** на bigPC | Создаёт `C:\scripts\wsl-portproxy.ps1`, firewall rule на TCP 8080, Scheduled Task «WSL Portproxy 8080» (запуск при логоне), запускает task сразу |
| [`wsl-portproxy.ps1`](./wsl-portproxy.ps1) | Вызывается Scheduled Task'ом, **руками запускать не надо** | Получает текущий WSL IP, переустанавливает `netsh portproxy` 8080 → WSL:8080 |

## Предусловия

- **Windows 10 или 11** на bigPC. (Для Win11 22H2+ есть более простой вариант — `networkingMode=mirrored` в `.wslconfig` — см. в конце README.)
- **WSL 2** установлен и хотя бы один дистрибутив (Ubuntu рекомендуется).
- **SSH-доступ к GitHub** настроен в WSL (`git@github.com:hleserg/azimut.git`). Если работаешь по HTTPS — запусти `setup-wsl.sh` с переменной `REPO_URL=https://github.com/hleserg/azimut.git`.
- На роутере или в `C:\Windows\System32\drivers\etc\hosts` других машин — резолвится `bigPC`. Альтернатива — использовать IP вместо имени.

## Порядок запуска

### 1. В WSL на bigPC

```bash
# Если репо ещё не склонирован — setup-wsl.sh сделает это сам.
# Если хочется клонировать заранее:
git clone git@github.com:hleserg/azimut.git ~/azimut
cd ~/azimut
git checkout master

bash scripts/bigpc/setup-wsl.sh
```

Если Docker не был установлен — скрипт его поставит, добавит твоего юзера в группу `docker` и попросит перелогиниться в WSL:

```bash
exit                                       # выйти из WSL
wsl                                        # войти снова (или newgrp docker в текущей сессии)
bash ~/azimut/scripts/bigpc/setup-wsl.sh   # запустить скрипт ещё раз
```

После успешного запуска проверь:

```bash
docker ps --filter name=azimuth-arch
curl -I http://localhost:8080
```

### 2. В Windows PowerShell на bigPC (от АДМИНИСТРАТОРА)

Самый простой способ скопировать `.ps1`-скрипты из WSL в Windows — через файловую систему WSL:

```
\\wsl.localhost\Ubuntu\home\<твой-юзер>\azimut\scripts\bigpc\
```

Открой эту папку в PowerShell-окне (от админа) и выполни:

```powershell
cd \\wsl.localhost\Ubuntu\home\<твой-юзер>\azimut\scripts\bigpc\
# Если PowerShell отказывается работать из UNC-пути — скопируй папку
# куда-нибудь локально (например, C:\Users\<юзер>\Desktop\bigpc-setup\)
# и запусти оттуда.

.\setup-windows.ps1
```

Скрипт:

1. Создаст `C:\scripts\wsl-portproxy.ps1`.
2. Добавит inbound firewall rule «Structurizr 8080» (TCP 8080, профили Private+Domain).
3. Зарегистрирует Scheduled Task «WSL Portproxy 8080» (триггер — At Logon, RunLevel Highest).
4. Запустит task сразу.
5. Покажет вывод `netsh interface portproxy show all`.

### 3. Проверка из LAN

С другой машины:

```powershell
Test-NetConnection bigPC -Port 8080
# или просто открой в браузере:
# http://bigPC:8080
```

Должна открыться страница Structurizr (on-prem, local-режим) с моделью из `workspace.dsl` (если он уже в репо — Фаза 1 / HLE-499 плана).

## Жизненный цикл

### Что происходит после перезагрузки bigPC

1. Windows стартует.
2. Scheduled Task «WSL Portproxy 8080» срабатывает **при первом логоне пользователя**.
3. Task ждёт до 90 секунд пока WSL сообщит IP, переустанавливает portproxy.
4. WSL стартует — Docker daemon запускается — контейнер `azimuth-arch` с `--restart=unless-stopped` поднимается.
5. Firewall rule уже действует постоянно.
6. `http://bigPC:8080` доступен из LAN.

### Обновление модели `workspace.dsl`

Structurizr (on-prem, local-режим) watch'ит volume и подхватывает изменения без рестарта:

```bash
cd ~/azimut
git pull
# Перейди в браузер, нажми Refresh — модель обновлена.
```

(Автоматический `git pull` по cron или GitHub webhook — отдельная инициатива, см. Фазу 8a плана.)

### Диагностика

| Проблема | Где смотреть |
|---|---|
| Контейнер не работает | WSL: `docker ps -a \| grep azimuth-arch`; `docker logs azimuth-arch` |
| Portproxy не работает | Windows: `netsh interface portproxy show all` |
| WSL IP сменился, доступ потерян | Windows (от админа): `Start-ScheduledTask -TaskName "WSL Portproxy 8080"` |
| Firewall блокирует | Windows: `Get-NetFirewallRule -DisplayName "Structurizr 8080"` |
| Из LAN не открывается | С другой машины: `Test-NetConnection bigPC -Port 8080` |
| Task падает с exit 1 | Windows: `Get-ScheduledTaskInfo -TaskName "WSL Portproxy 8080"` — посмотри `LastTaskResult` |

### Удаление

В WSL (из корня репо `~/azimut`):

```bash
docker compose --profile diagrams down
```

В Windows (от админа):

```powershell
Unregister-ScheduledTask -TaskName "WSL Portproxy 8080" -Confirm:$false
Remove-NetFirewallRule -DisplayName "Structurizr 8080"
Remove-Item C:\scripts\wsl-portproxy.ps1
netsh interface portproxy delete v4tov4 listenport=8080 listenaddress=0.0.0.0
```

## Альтернатива для Windows 11 22H2+ (mirrored networking)

Если bigPC обновится до Windows 11 22H2 или новее с WSL 2.0+, всю эту схему можно заменить одной строкой в `%USERPROFILE%\.wslconfig`:

```ini
[wsl2]
networkingMode=mirrored
firewall=true
```

После `wsl --shutdown` и следующего старта WSL делит сетевой стек с Windows: порт 8080 в WSL = порт 8080 в Windows напрямую, без portproxy. Firewall-rule из шага 2 всё равно нужно создать.

В этом случае Scheduled Task с `wsl-portproxy.ps1` можно удалить (см. блок «Удаление» выше).
