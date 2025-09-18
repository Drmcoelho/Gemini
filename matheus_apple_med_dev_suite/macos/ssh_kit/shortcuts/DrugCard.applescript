-- DrugCard.applescript — gera um card Markdown e copia para o clipboard
-- Requer "med" (pipx) disponível no PATH do shell do Automator/Script Editor.
on run argv
  if (count of argv) < 1 then
    display dialog "Uso: DrugCard <drug name>"
    return
  end if
  set drugName to item 1 of argv
  set tmpFile to POSIX path of (do shell script "mktemp /tmp/drugcard.XXXXXX.md")
  do shell script "med card drug " & quoted form of drugName & " --out " & quoted form of tmpFile
  set md to do shell script "cat " & quoted form of tmpFile
  set the clipboard to md
  display notification "Drug card gerado e copiado para o clipboard" with title "medcli"
end run
