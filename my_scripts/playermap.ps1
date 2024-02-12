$server = $args[0]

if ($server -eq "tcore")
{
	echo "Launching tcore playermap: php -S localhost:8000"
	if (Test-Path "C:\Users\jonas\Code2\Python\wander_nodes_util\tcore_map\playermap") {
		$path = "C:\Users\jonas\Code2\Python\wander_nodes_util\tcore_map\playermap"
	} elseif (Test-Path "D:\My files\svea_laptop\code_hdd\repos\Code2\Python\wander_nodes_util\tcore_map\playermap") {
		$path = "D:\My files\svea_laptop\code_hdd\repos\Code2\Python\wander_nodes_util\tcore_map\playermap"
	} elseif (Test-Path "C:\Users\jonas\OneDrive\Documents\Code2\Python\wander_nodes_util\tcore_map\playermap") {
		$path = "C:\Users\jonas\OneDrive\Documents\Code2\Python\wander_nodes_util\tcore_map\playermap"
	} else {
		$path = "~/"
	}
}
else
{
	echo "Launching acore playermap: php -S localhost:8000"
	if (Test-Path "C:\Users\jonas\Code2\Python\wander_nodes_util\acore_map\playermap") {
		$path = "C:\Users\jonas\Code2\Python\wander_nodes_util\acore_map\playermap"
	} elseif (Test-Path "D:\My files\svea_laptop\code_hdd\repos\Code2\Python\wander_nodes_util\acore_map\playermap") {
		$path = "D:\My files\svea_laptop\code_hdd\repos\Code2\Python\wander_nodes_util\acore_map\playermap"
	} elseif (Test-Path "C:\Users\jonas\OneDrive\Documents\Code2\Python\wander_nodes_util\acore_map\playermap") {
		$path = "C:\Users\jonas\OneDrive\Documents\Code2\Python\wander_nodes_util\acore_map\playermap"
	} else {
		$path = "~/"
	}
}

#cd $path
#cd $path; php -S 127.0.0.1:8000
cd $path; php -S localhost:8000