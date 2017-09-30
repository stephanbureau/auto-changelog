#!/bin/bash
# USAGE:
# sh auto-changelog.sh [changelog_filename]

CHANGELOG_FILENAME="Changelog.md"
[[ $1 ]] && CHANGELOG_FILENAME=$1;

# check if repo contains any tag
! [[ $(git tag --list | egrep -q "^$1$") ]] && {
    echo -e "\033[33;31mNo tag found in git repository!\033[0m"
    exit 1
}

CURRENT_TAG=$(git describe --tags $(git rev-list --tags --max-count=1))
CURRENT_TAG_DATE=$(git log --tags --simplify-by-decoration --pretty="format:%ai %d" | grep "$CURRENT_TAG")
PREVIOUS_TAG=$(git describe --abbrev=0 --tags ${CURRENT_TAG}^)
echo "### Update CHANGELOG with ${CURRENT_TAG}"
logsContent="## [$CURRENT_TAG] - ${CURRENT_TAG_DATE%% *}\n\n"
declare -A changelogs=([feat]="" [fix]="" [clean]="" [chore]="" [docs]="" [test]="" [style]="" [hotfix]="" [refactor]="")
IFS=$'\n'; logs=( $(git log ${PREVIOUS_TAG}..${CURRENT_TAG} --no-merges --pretty=format:"%s") ); IFS=$' ';
for log in "${logs[@]}"; do
    logPrefix=${log%:*}
    if [ -n "${changelogs[$logPrefix] + 1}" ]; then
        logSubject=${log##*:}
        changelogs[$logPrefix]="${changelogs[$logPrefix]}-$logSubject\n"
    fi
done
for logType in "${!changelogs[@]}"; do
    if [ "${#changelogs[$logType][@]}" != "0" ]; then
        logsContent="${logsContent}### ${logType}:\n\n"
        for log in "${changelogs[$logType][@]}"; do
            logsContent="${logsContent}$log"
        done
        logsContent="${logsContent}\n"
    fi
done
sed -i "1i$logsContent" $CHANGELOG_FILENAME
echo -e "\033[0;32mChangelog correctly added\033[0m"
exit $?
