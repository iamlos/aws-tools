#!/bin/bash

function displayUsage()
{
    local scriptName="$(basename ${0})"

    echo -e "\033[1;33m"
    echo    "SYNOPSIS :"
    echo    "    ${scriptName}"
    echo    "         --help"
    echo    "         --region <REGION> --bucket <BUCKET_NAME> --file <FILE_PATH>"
    echo    "         --aws-access-key-id <AWS_ACCESS_KEY_ID> --aws-secret-access-key <AWS_SECRET_ACCESS_KEY>"
    echo -e "\033[1;35m"
    echo    "DESCRIPTION :"
    echo    "    --help                     Help page"
    echo    "    --region                   Region (optional, defaults to \$AWS_DEFAULT_REGION)"
    echo    "    --bucket                   Bucket name (require)"
    echo    "    --file-path                File path (require)"
    echo    "    --aws-access-key-id        AWS Access Key ID (optional, defaults to \$AWS_ACCESS_KEY_ID)"
    echo    "    --aws-secret-access-key    AWS Secret Access Key (optional, defaults to \$AWS_SECRET_ACCESS_KEY)"
    echo -e "\033[1;36m"
    echo    "EXAMPLES :"
    echo    "    ./${scriptName} --help"
    echo    "    ./${scriptName} --bucket 'my_bucket_name' --file-path 'my_path/my_file.txt'"
    echo    "    ./${scriptName}"
    echo    "        --region 'us-west-1' --bucket 'my_bucket_name' --file-path 'my_path/my_file.txt'"
    echo    "        --aws-access-key-id '5KI6IA4AXMA39FV7O4E0' --aws-secret-access-key '5N2j9gJlw9azyLEVpbIOn/tZ2u3sVjjHM03qJfIA'"
    echo -e "\033[0m"

    exit ${1}
}

function generateSignURL()
{
    local region="${1}"
    local bucket="${2}"
    local filePath="${3}"
    local awsAccessKeyID="${4}"
    local awsSecretAccessKey="${5}"

    local endPoint="$("$(isEmptyString ${region})" = 'true' && echo 's3.amazonaws.com' || echo "s3-${region}.amazonaws.com")"
    local expire="$(($(date +%s) + 900))"
    local signature="$(echo -en "GET\n\n\n${expire}\n/${bucket}/${filePath}" | openssl dgst -sha1 -binary -hmac "${awsSecretAccessKey}" | openssl base64)"
    local query="AWSAccessKeyId=$(encodeURL "${awsAccessKeyID}")&Expires=${expire}&Signature=$(encodeURL "${signature}")"

    echo "http://${endPoint}/${bucket}/${filePath}?${query}"
}

function main()
{
    appPath="$(cd "$(dirname "${0}")" && pwd)"
    source "${appPath}/lib/util.bash" || exit 1

    local optCount=${#}

    local awsAccessKeyID="${AWS_ACCESS_KEY_ID}"
    local awsSecretAccessKey="${AWS_SECRET_ACCESS_KEY}"
    local region="${AWS_DEFAULT_REGION}"

    while [[ ${#} -gt 0 ]]
    do
        case "${1}" in
            --help)
                displayUsage 0
                ;;
            --region)
                shift

                if [[ ${#} -gt 0 ]]
                then
                    local region="$(trimString "${1}")"
                fi

                ;;
            --bucket)
                shift

                if [[ ${#} -gt 0 ]]
                then
                    local bucket="$(trimString "${1}")"
                fi

                ;;
            --file-path)
                shift

                if [[ ${#} -gt 0 ]]
                then
                    local filePath="$(trimString "${1}")"
                fi

                ;;
            --aws-access-key-id)
                shift

                if [[ ${#} -gt 0 ]]
                then
                    local awsAccessKeyID="$(trimString "${1}")"
                fi

                ;;
            --aws-secret-access-key)
                shift

                if [[ ${#} -gt 0 ]]
                then
                    local awsSecretAccessKey="$(trimString "${1}")"
                fi

                ;;
            *)
                shift
                ;;
        esac
    done

    if [[ "$(isEmptyString ${bucket})" = 'true' || "$(isEmptyString ${filePath})" = 'true' ||
          "$(isEmptyString ${awsAccessKeyID})" = 'true' || "$(isEmptyString ${awsSecretAccessKey})" = 'true' ]]
    then
        if [[ ${optCount} -gt 0 ]]
        then
            error '\nERROR: bucket, filePath, awsAccessKeyID or awsSecretAccessKey not found!'
            displayUsage 1
        fi

        displayUsage 0
    fi

    generateSignURL "${region}" "${bucket}" "${filePath}" "${awsAccessKeyID}" "${awsSecretAccessKey}"
}

main "$@"