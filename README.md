## Заметка: Как сделать несколько репозиториев в одной папке

#git init
#mv .git .(имя папки)
Заменить имя алиаса и пути git-dir и work-tree
#git config --global --replace-all alias.speedrun "!git --git-dir=\".sr\" --work-tree=\"./\""

## Использование
Для работы с этим репо
#git speedrun ...
Вывести статус но без "untracked files" (Можно тоже сделать алиас)
#git speedrun status -uno