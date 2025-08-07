$server = $args[0]

if ($server -eq "tcore")
{
	echo "Launching tcore playermap: php -S localhost:8000"
	$basePath = Join-Path -Path $env:code_root_dir -ChildPath "Code2\Python\wander_nodes_util\tcore_map\playermap"

	if (Test-Path $basePath) {
		$path = $basePath
	} else {
		$path = "~/"
	}
}
else
{
	echo "Launching acore playermap: php -S localhost:8000"
	$basePath = Join-Path -Path $env:code_root_dir -ChildPath "Code2\Python\wander_nodes_util\acore_map\playermap"

	if (Test-Path $basePath) {
		$path = $basePath
	} else {
		$path = "~/"
	}
}

#cd $path
#cd $path; php -S 127.0.0.1:8000
cd $path; php -S localhost:8000

