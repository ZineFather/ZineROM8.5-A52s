# Validate a pinned Samsung FUS version in AP/CSC/CP/BL order.
# The CP component may be model-prefixed or use Samsung's CP######## format.
VALIDATE_FIRMWARE_VERSION()
{
    local MODEL="$1"
    local VERSION="$2"
    local MODEL_CODE="${MODEL#SM-}"
    local -a VERSION_PARTS=()

    [ "$MODEL_CODE" ] && [ "$VERSION" ] || return 1

    local IFS='/'
    read -r -a VERSION_PARTS <<< "$VERSION"
    [ "${#VERSION_PARTS[@]}" -eq 4 ] || return 1

    [[ "${VERSION_PARTS[0]}" == "$MODEL_CODE"* ]] || return 1
    [[ "${VERSION_PARTS[1]}" == "$MODEL_CODE"* ]] || return 1
    [[ "${VERSION_PARTS[2]}" == "$MODEL_CODE"* || "${VERSION_PARTS[2]}" =~ ^CP[[:alnum:]]+$ ]] || return 1
    [[ "${VERSION_PARTS[3]}" == "$MODEL_CODE"* ]] || return 1

    return 0
}
