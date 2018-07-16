#!/bin/bash
# usage: create_sftp_user <username> <password> <ssh_key> <super_flag> <bucket> <region> <override>
function create_sftp_user() {
    csu_user=$1
    csu_password=$2
    csu_ssh_key=$3
    csu_super_flag=$4
    csu_bucket=$5
    csu_region=$6
    csu_override=$7

    # create user
    adduser --disabled-password --gecos "" --force-badname $csu_user

    # prevent ssh login & assign SFTP group
    if [ "$csu_super_flag" == "1" ]; then
      usermod -g sftpsuperusers $csu_user
    else
      usermod -g sftpusers $csu_user
    fi
    usermod -s /bin/nologin $csu_user

    # get user ids
    usruid=`id -u $csu_user`
    usrgid=`id -g $csu_user`

    # set user password
    if [ "$csu_password" != "" ]; then
      echo "$csu_user:$csu_password" | chpasswd
    fi

    # set ssh key if supplied
    if [ "$csu_ssh_key" != "" ]; then
      mkdir -p /home/$csu_user/.ssh
      echo $csu_ssh_key > /home/$csu_user/.ssh/authorized_keys
      chmod 600 /home/$csu_user/.ssh/authorized_keys
      chown $csu_user:$csu_user -R /home/$csu_user/.ssh
    fi

    # chroot user (so they only see their directory after login)
    chown root:$csu_user /home/$csu_user
    chmod 755 /home/$csu_user

    # change s3 location if override flag set
    if [ $override -ne 0 ]; then
      userkey=`echo $csu_user | sed -e 's/dev//'`
    else
      userkey=$csu_user
    fi

    # set up upload directory tied to s3
    mkdir /home/$csu_user/uploads
    chown $csu_user:$csu_user /home/$csu_user/uploads
    chmod 755 /home/$csu_user/uploads
    # create matching folder in s3
    aws s3api put-object --bucket $csu_bucket --key $userkey/

    # link upload dir to s3
    cat <<EOT >> /etc/fstab
$csu_bucket:/$userkey /home/$csu_user/uploads fuse.s3fs _netdev,allow_other,endpoint=$csu_region,iam_role=auto,uid=$usruid,gid=$usrgid 0 0
EOT
}

# usage: process_users <userfile> <bucket> <region>
function process_users() {
  while IFS=, read username pw ssh_key super override_bucket
  do
    if [ "$override_bucket" == "" ]; then
      bucket=$2
      override=0
    else
      bucket=$override_bucket
      override=1
    fi
    create_sftp_user $username $pw "$ssh_key" $super $bucket $3 $override
  done < $1

  mount -a
}
