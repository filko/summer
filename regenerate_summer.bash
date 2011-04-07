#!/usr/bin/env bash

run_date=$(date -u +%Y-%m-%d_%H:%M)
RECIPIENTS="exherbo-job-logs@exherbo.org"
LOG="${HOME}/nightly-out/summer-${run_date}.log"
if [[ -n ${1} ]]; then
    ALWAYS_SENDMAIL=yesplease
fi

mail() {
    local subject="${1}" body="${2}"
    HOME="/tmp" LANG="en_GB.utf8" EMAIL="Statically Updated Metadata Manifestation for Exherbo Repositories <summer@git.exherbo.org>" \
        mutt -s '${subject}' -- ${RECIPIENTS}
}

die() {
    echo "${1}" >&2
    mail "Failure: Summer regeneration ${run_date}" "${LOG}"
    exit 1
}

cd ~/summer.git &>>"${LOG}" || die "Entering summer.git failed"
make clean &>>"${LOG}" || die "make clean failed"
ulimit -c unlimited && make &>>"${LOG}" || die "make failed"
make upload &>>"${LOG}" || die "make upload failed"

[[ -n ${ALWAYS_SENDMAIL} ]] && mail "Success: Summer regeneration ${run_date}" "${LOG}"

