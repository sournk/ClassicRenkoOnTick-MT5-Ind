## Expert Adviser & Indicator Installation for MetaTrader 5 | Установка Тоговых Советников и Индикаторов в MetaTrader 5


* Created by Denis Kislitsyn | denis@kislitsyn.me | [kislitsyn.me](https://kislitsyn.me/personal/algo)

### EN: Installation

**1. Update MetaTrader 5 Terminal:** Ensure that your MetaTrader 5 terminal is updated to the latest version. For testing Expert Advisors, it is recommended to use the latest beta version. To update, go to `Help->Check For Updates->Latest Beta Version`. If your terminal is outdated, the Expert Advisor may not run, and you will see relevant messages in the `Journal` tab.
**2. Copy Indicator Files:** Move the `*.ex5` indicator files to the terminal’s data directory `MQL5\Indicators`.
**3. Copy the Expert Advisor File:** Move the `*.ex5` bot file to `MQL5\Experts`.
**4. Copy the Script File:** Move the `*.ex5` script file to `MQL5\Scripts`.
**5. Open the Symbol Chart:** Open the chart for the desired trading instrument.
**6. Attach the Expert Advisor to the Chart:** Drag the Expert Advisor from the Navigator window onto the chart.
**7. Enable Auto Trading in the Expert Advisor Settings:** In the Expert Advisor settings, check `Allow Auto Trading`.
**8. Allow DLL and WebRequests:**: If your Expert Advisor uses external DLL and makes network requests, enable the `Allow DLLs imports` and `Allow WebRequests for listed URLs` param in the terminal `Tools->Options` settings. Add the required ones to the list of external network addresses.
**9. Activate Auto Trading in the Terminal:** Click the `Algo Trading` button on the main toolbar to enable automated trading.
**10. Load the Preset Configuration:** Click the `Load` button and select the appropriate set-file to apply the predefined settings, if provided.

### RU: Установка
**1. Обновите терминал MetaTrader 5:** Убедитесь, что ваш терминал MetaTrader 5 обновлен до последней версии. Для тестирования Expert Advisors рекомендуется использовать последнюю бета-версию. Чтобы обновить, пройдите по ссылке `Help->Check For Updates->Latest Beta Version`. Если ваш терминал устарел, бот может не работать, и вы увидите соответствующие сообщения в вкладке `Journal`.
**2. Скопируйте файлы индикаторов:** Переместить файлы индикаторов `*.ex5` в директорию данных терминала `MQL5\Indicators`.
**3. Скопируйте файл советника:** Переместите файл `*.ex5` бота в `MQL5\Experts`.
**4. Скопируйте файлы скриптов:** Переместить файлы скриптов `*.ex5` в `MQL5\Scripts`.
**5. Откройте график символа:** Откройте график нужного торгового инструмента.
**6. Прикрепите эксперта к графику:** Перетащите эксперта в окно графика.
**7. Включите автоторговлю у советника:** В настройках бота выберите пункт `Allow Auto Trading`.
**8. Разрешите DLL и WebRequests:** Если ваш эксперт использует внешние DLL и выполняет сетевые запросы, то в настройках терминала `Tools->Options` включите настройки `Allow DLLs imports` и `Allow WebRequests for listed URL`. В список внешних сетевых адресов добавьте нужные.
**9. Включите автоторговлю в терминале:** Нажмите кнопку `Algo Trading` на главной панели инструментов.
**10. Загрузите сеты:** Нажмите кнопку `Load` и выберите соответствующий файл для применения предопределенных параметров, если они предусмотрены.

## Build From Source | Компиляция исходников

### EN: Build From Source 

1. Start the IDE in MetaTrader 5. Select `Tools\Meta Quotes Language Editor` in the menu.
2. Go to the `Experts\<Expert's Catalogue>` folder.
3. Open the `*.mqproj` file.
4. Select the `Build\Compile` menu item.
5. The terminal will compile a new file `*.ex5` in the same directory.

### RU: Компиляция исходников

1. Запустите IDE в MetaTrader 5. Выберите в меню `Tools\Meta Quotes Language Editor`.
2. Перейдите в папку `Experts\<Expert's Catalogue>`.
3. Открыть файл `*.mqproj`.
4. Выберите пункт меню `Build\Compile`.
5. Терминал будет компилировать новый файл `*.ex5` в том же самом каталоге.