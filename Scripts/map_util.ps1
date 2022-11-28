#http://woshub.com/how-to-refresh-ad-groups-membership-without-user-logoff/
# Update GPO: gpupdate /force (update GPO)
# gpupdate /force (update GPO)

# Map network drive in Windows / Mappa en nätverksenhet i Windows
# cmd: net use (to see all mapped drive locations. These can later be added to an "enhet")
#https://support.microsoft.com/sv-se/windows/mappa-en-n%C3%A4tverksenhet-i-windows-29ce55d1-34e3-a7e2-4801-131475f9557d

# Find gpresults. (Klicka på "Visa" / "Show" under Medlemskap i säkerhetsgrupp för att se "user groups")
gpresult /h filename.html 

# Git clone without sslverification:
# git -c http.sslVerify=false clone https://github.com/sveawebpay/dotnet-integration