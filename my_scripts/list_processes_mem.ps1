# Processes by memory
get-process | Group-Object -Property ProcessName | Format-Table Name, @{n='Mem (KB)';e={'{0:N0}' -f (($_.Group|Measure-Object WorkingSet64 -Sum).Sum / 1KB)};a='right'} -AutoSize

