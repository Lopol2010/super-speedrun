Заметка: Как сделать несколько репозиториев в одной папке

Заменить имя алиаса и пути git-dir и work-tree
#git config --global --replace-all alias.speedrun "!git --git-dir=\".sr\" --work-tree=\"./\""

Использование
Вывести статус но без "untracked files" (Можно тоже сделать алиас)
#git speedrun status -uno