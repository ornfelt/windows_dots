# List largest files in current dir:
gci . -r | sort Length -desc | select fullname -f 10