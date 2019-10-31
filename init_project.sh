#!/bin/bash
#NO DEPENDENCY <= EXECUTED BEFORE GIT SUBMODULE

echo "================================================================================";
echo "> INIT PROJECT...";
echo "--------------------------------------------------------------------------------";
BEFORE_DATE=$(date +%D-%X);
BEFORE_DATE_SEC=$(date +%s);

SRC_DIRECTORY_PATH="../base-project-gradle";
echo "> Source directory: '$SRC_DIRECTORY_PATH'";

if ! [[ -d "$SRC_DIRECTORY_PATH" ]]; then
	echo "> Directory '$SRC_DIRECTORY_PATH' does NOT exist!";
	exit 1;
fi

CURRENT_PATH=$(pwd);
CURRENT_DIRECTORY=$(basename ${CURRENT_PATH});
echo "> Target directory: '$CURRENT_PATH'";

declare -a EXCLUDE=("init_project.sh" "README.md" ".git");

function shouldSkeep() {
    d=$1;
    for e in "${EXCLUDE[@]}"; do
        if [ "$e" = "$d" ] ; then
            return 0; # SKEEP
        fi
    done
    return 1; # NOT SKEEP
}

for SRC_FILE_PATH in $SRC_DIRECTORY_PATH/* $SRC_DIRECTORY_PATH/.[^.]* ; do
	echo "--------------------------------------------------------------------------------";
	FILENAME=$(basename ${SRC_FILE_PATH});
	if shouldSkeep $FILENAME; then
        echo "> SKIP excluded '$SRC_FILE_PATH'";
        echo "--------------------------------------------------------------------------------";
        continue;
    fi
	if [[ -f $SRC_FILE_PATH ]]; then
		DEST_PATH=$CURRENT_PATH;
		DEST_FILE_PATH="$DEST_PATH/$FILENAME"
		ACTION="";
		if [[ -f "$DEST_FILE_PATH" ]]; then
			diff -q ${SRC_FILE_PATH} $DEST_FILE_PATH &> /dev/null;
			RESULT=$?;
			if [[ ${RESULT} -eq 0 ]]; then
				echo "> SKIP unchanged file '$SRC_FILE_PATH' ($DEST_FILE_PATH)";
				echo "--------------------------------------------------------------------------------";
				continue;
			fi
			ACTION="UPDATING";
		else
			ACTION="INITIALIZING";
		fi
		echo "> $ACTION file '$SRC_FILE_PATH' in '$DEST_PATH'...";
		cp $SRC_FILE_PATH $DEST_FILE_PATH;
		RESULT=$?;
		echo "> $ACTION file '$SRC_FILE_PATH' in '$DEST_PATH'... DONE";
		if [[ ${RESULT} -ne 0 ]]; then
			echo "> Error while $ACTION file'$SRC_FILE_PATH' to '$DEST_PATH'!";
			exit ${RESULT};
		fi
		echo "--------------------------------------------------------------------------------";
	elif [[ -d "$SRC_FILE_PATH" ]]; then
		DEST_PATH=$CURRENT_PATH;
		DEST_FILE_PATH="$DEST_PATH/$FILENAME"
		if [[ -d "$DEST_FILE_PATH" ]]; then
			diff -q -r $SRC_FILE_PATH $DEST_FILE_PATH &> /dev/null;
			RESULT=$?;
			if [[ ${RESULT} -eq 0 ]]; then
				echo "> SKIP unchanged directory '$SRC_FILE_PATH' ($DEST_FILE_PATH)";
				continue
			fi

			ACTION="UPDATING";
		else
			ACTION="INITIALIZING";
		fi
		echo "> $ACTION directory '$SRC_FILE_PATH' in '$DEST_PATH/'...";
		cp -R $SRC_FILE_PATH $DEST_PATH/;
		RESULT=$?;
		echo "> $ACTION directory '$SRC_FILE_PATH' in '$DEST_PATH/'... DONE";
		if [[ ${RESULT} -ne 0 ]]; then
			echo "> Error while $ACTION directory '$SRC_FILE_PATH' to '$FILENAME'!";
			exit ${RESULT};
		fi
		echo "--------------------------------------------------------------------------------";
	else #WTF
		echo "> File to deploy '$FILENAME' ($SRC_FILE_PATH) is neither a directory or a file!";
		ls -l $FILENAME;
		exit 1;
	fi
done 

# GIT SUBMODULEs
if [[ -f "$CURRENT_PATH/.gitmodules" ]]; then
	echo "> SKIP GIT submodule initialization in '$CURRENT_PATH/'";
else # NEED TO INIT GIT SUBMODULES
	GIT_BRANCH=$(git rev-parse --abbrev-ref HEAD);
	declare -a SUBMODULES=(
		"commons"
		"commons-android"
		"app-android"
	);
	PROJECT_NAME="${CURRENT_DIRECTORY:0:$((${#CURRENT_DIRECTORY} - 7))}"
	declare -a SUBMODULES_REPO=(
		"commons"
		"commons-android"
		"$PROJECT_NAME-android"
	);
	if [[ $PROJECT_NAME == "mtransit-for-android" ]]; then
		echo "> Main android app: '$PROJECT_NAME' > parser NOT required";
	elif [[ $PROJECT_NAME == *bike ]]; then
		echo "> Bike android app: '$PROJECT_NAME' > parser NOT required";
	else
		echo "> Bus/Train/... android app: '$PROJECT_NAME' > parser required";
		SUBMODULES+=('parser');
		SUBMODULES_REPO+=('parser');
		SUBMODULES+=('agency-parser');
		SUBMODULES_REPO+=("${PROJECT_NAME}-parser");
	fi
	echo "> Submodules:";
	printf '> - "%s"\n' "${SUBMODULES[@]}";
	for S in "${!SUBMODULES[@]}"; do
		SUBMODULE=${SUBMODULES[$S]}
		SUBMODULE_REPO=${SUBMODULES_REPO[$S]}
		echo "--------------------------------------------------------------------------------";
		if [[ -d "$CURRENT_PATH/$SUBMODULE" ]]; then
			echo "> Cannot override '$CURRENT_PATH/$SUBMODULE'!";
			exit 1;
		fi
		if [[ -z "${SUBMODULE_REPO}" ]]; then
			echo "SUBMODULE_REPO not found!";
			exit 1;
		fi
		echo "> Adding submodule '$SUBMODULE_REPO' in '$SUBMODULE'...";
		git submodule add git://github.com/mtransitapps/$SUBMODULE_REPO.git $SUBMODULE;
		RESULT=$?;
		if [[ ${RESULT} -ne 0 ]]; then
			echo "> Error while cloning '$SUBMODULE_REPO' submodule in '$SUBMODULE'!";
			exit ${RESULT};
		fi
		git remote set-url origin git@github.com:mtransitapps/$SUBMODULE_REPO.git;
		RESULT=$?;
		if [[ ${RESULT} -ne 0 ]]; then
			echo "> Error while seting remote URL for '$SUBMODULE_REPO' submodule in '$SUBMODULE'!";
			exit ${RESULT};
		fi
		cd $CURRENT_PATH/$SUBMODULE || exit;
		git checkout $GIT_BRANCH;
		RESULT=$?;
		if [[ ${RESULT} -ne 0 ]]; then
			echo "> Error while checkint out $GIT_BRANCH in '$SUBMODULE_REPO' submodule in '$SUBMODULE'!";
			exit ${RESULT};
		fi
		echo "> Adding submodule '$SUBMODULE_REPO' in '$SUBMODULE'... DONE";
		cd $CURRENT_PATH || exit;
		echo "--------------------------------------------------------------------------------";
	done
fi

echo "--------------------------------------------------------------------------------";
AFTER_DATE=$(date +%D-%X);
AFTER_DATE_SEC=$(date +%s);
DURATION_SEC=$(($AFTER_DATE_SEC-$BEFORE_DATE_SEC));
echo "> $DURATION_SEC secs FROM $BEFORE_DATE TO $AFTER_DATE";
echo "> INIT PROJECT... DONE";
echo "================================================================================";
