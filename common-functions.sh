# $1 = NAME, $2 = EXECUTABLE
function checkExecutable() {
	if [ "$2" == "" ] ; then
		echo "$1 variable for executable not set."
		exit 1
	fi
	if [ ! -x "$2" ] ; then
		echo "$1 not found at: $2"
		exit 1
	fi
}

# $1 = NAME, $2 = FILE
function checkFile() {
	if [ "$2" == "" ] ; then
		echo "$1 variable for file not set."
		exit 1
	fi
	if [ ! -f "$2" ] ; then
		echo "$1 not found at: $2"
		exit 1
	fi
}

# $1 = NAME, $2 = FILE
function checkDirectory() {
	if [ "$2" == "" ] ; then
		echo "$1 directory variable not set."
		exit 1
	fi
	if [ ! -d "$2" ] ; then
		echo "$1: Data directory $2 does not exist."
		exit 1
	fi
}
