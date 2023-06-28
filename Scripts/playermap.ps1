$server = $args[0]

if ($server -eq "tcore")
{
	echo "Launching tcore playermap: php -S 127.0.0.1:8000"
	$path = "C:\Users\jonas\Code2\tcore_map\playermap"
}
else
{
	echo "Launching acore playermap: php -S 127.0.0.1:8000"
	$path = "C:\Users\jonas\Code2\\acore_map\playermap"
}

#cd $path
cd $path; php -S 127.0.0.1:8000