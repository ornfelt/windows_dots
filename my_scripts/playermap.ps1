$server = $args[0]

if ($server -eq "tcore")
{
	echo "Launching tcore playermap: php -S 127.0.0.1:8000"
	if (Test-Path "C:\Users\jonas\Code2\tcore_map\playermap") {
		$path = "C:\Users\jonas\Code2\tcore_map\playermap"
	} elseif (Test-Path "D:\My files\svea_laptop\tcore_map\playermap") {
		$path = "D:\My files\svea_laptop\tcore_map\playermap"
	} elseif (Test-Path "x") {
		$path = "x"
	} else {
		$path = "~/"
	}
}
else
{
	echo "Launching acore playermap: php -S 127.0.0.1:8000"
		if (Test-Path "C:\Users\jonas\Code2\\acore_map\playermap") {
		$path = "C:\Users\jonas\Code2\\acore_map\playermap"
	} elseif (Test-Path "D:\My files\svea_laptop\acore_map\playermap") {
		$path = "D:\My files\svea_laptop\acore_map\playermap"
	} elseif (Test-Path "x") {
		$path = "x"
	} else {
		$path = "~/"
	}
}

#cd $path
cd $path; php -S 127.0.0.1:8000