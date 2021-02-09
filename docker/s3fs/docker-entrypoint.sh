#!/usr/bin/env ash
set -euo pipefail
set -o errexit

trap 'kill -SIGQUIT $PID' INT

# For each user (default to $USER:$AWS_ACCESS_KEY_ID:$AWS_SECRET_ACCESS_KEY:$AWS_S3_BUCKET)
echo "${USERS:-${USER}:${AWS_ACCESS_KEY_ID}:${AWS_SECRET_ACCESS_KEY}:${AWS_S3_BUCKETS:-${AWS_S3_BUCKET:-}}}" |sed 's/ /\n/g' | while read -r line; do
  [ -n "${line}" ] && echo "${line//:/ }" | while read -r user aws_access_key_id aws_secret_access_key aws_s3_buckets; do

    # Skip user if no AWS credentials
    [ -n "${aws_access_key_id:-$AWS_ACCESS_KEY_ID}" ] && [ -n "${aws_secret_access_key:-$AWS_SECRET_ACCESS_KEY}" ] || continue

    # Create user if not exists
    id "${user:-root}" >/dev/null 2>&1 || adduser -h "/home/${user:-root}" -s /sbin/nologin -D "${user:-root}"

    # Configure s3fs
    passwd_file="$(eval echo ~"${user:-root}")/.passwd-s3fs"
    echo "${aws_access_key_id:-$AWS_ACCESS_KEY_ID}:${aws_secret_access_key:-$AWS_SECRET_ACCESS_KEY}" > "${passwd_file}"
    chmod 0400 "${passwd_file}"

    # Find all buckets readable with our credentials
    if [ -z "${aws_s3_buckets}" ]; then
        date="$(date -R)"
        string="GET\n\n\n${date}\n/"
        authorization="AWS ${aws_access_key_id:-$AWS_ACCESS_KEY_ID}:$(echo -ne "${string}" | openssl sha1 -hmac "${aws_secret_access_key:-$AWS_SECRET_ACCESS_KEY}" -binary | openssl base64)"
# posix
        aws_s3_buckets=$(curl -s -H "Date: $date" -H "Authorization: $authorization" https://s3.amazonaws.com/ | awk -F"<|>" 'BEGIN {RS="<"} /Name/ {print $2}')
# bash only
#        aws_s3_buckets=$(curl -s -H "Date: $date" -H "Authorization: $authorization" https://s3.amazonaws.com/ \
#          | while IFS='>' read -rd '<' element value; do
#            case "${element}" in
#              'Name')
#                echo "${value}"
#                ;;
#              *)
#                ;;
#            esac
#        done)
    fi

    # For each bucket (default to all buckets readable by AWS_ACCESS_KEY_ID)
    echo "${aws_s3_buckets}" |sed 's/,/\n/g' |while read -r aws_s3_bucket; do

        # Skip empty values
        [ -n "${aws_s3_bucket}" ] || continue

        # Create s3fs mountpoint
        s3fs_bucket_dir="${S3FS_DIR:-/srv/s3}/${aws_s3_bucket}"
        mkdir -p "${s3fs_bucket_dir}"

        # Mount s3fs
        /usr/local/bin/s3fs "${aws_s3_bucket}" "${s3fs_bucket_dir}" -o nosuid,nonempty,nodev,allow_other,complement_stat,mp_umask=027,uid=$(id -u "${user:-root}"),gid=$(id -g "${user:-root}"),passwd_file="${passwd_file}",default_acl="${AWS_S3_ACL:-private}",retries=5

        # Exit docker if the s3 filesystem is not reachable anymore
        ( crontab -l && echo "* * * * * timeout 3 touch '${s3fs_bucket_dir}/.s3fs_watchdog' >/dev/null 2>&1 || kill -KILL -1" ) | crontab -

    done
  done
done

# Keep container running
[ $# -eq 0 ] && tail -f /dev/null || exec "$@" &
PID=$! && wait
