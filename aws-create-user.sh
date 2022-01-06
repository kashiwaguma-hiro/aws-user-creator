#/bin/sh
set -eu

function usage(){
    printf "使い方: %s -g group_name [-f path] [-aph] args\n" $0
    echo   "  -g group_name: ユーザの所属グループを指定します. 必須パラメータです."
    echo   "  -f filepath  : ユーザを記載したファイルのパスを指定します.デフォルトは ./users.txt ."
    echo   "  -p           : ログイン用のパスワードを生成します. 生成したパスワードは ./[AWS_ACCOUNT_ID]_[AWS_ACCOUNT_ALIAS]_ユーザ名_password.txt に出力されます."
    echo   "  -a           : APIアクセス用のアクセスキーを生成します. 生成したアクセスキーは ./[AWS_ACCOUNT_ID]_[AWS_ACCOUNT_ALIAS]_ユーザ名_accesskey.txt に出力されます."
    echo   "  -d           : デバッグログを出力."
    echo   "  -h           : 本メッセージを出力します."
    echo   ""
}

function awscmd (){
    # AWS_DEFAULT_REGIONについて、本スクリプト上のAPI操作では リージョンを意識しないため us-west-2 で固定.
    docker run --rm -e AWS_ACCESS_KEY_ID=$AWS_ACCESS_KEY_ID \
                    -e AWS_SECRET_ACCESS_KEY=$AWS_SECRET_ACCESS_KEY \
                    -e AWS_DEFAULT_REGION=us-west-2 \
                    -e AWS_PAGER="" \
                    amazon/aws-cli \
                    "$@" ${DEBUG}
}

GROUP=
CREATE_PASSWORD=false
CREATE_ACCESS_KEY=false
USERS_FILE=./users.txt
DEBUG=

while getopts g:f:padh OPT
do
  case $OPT in
     g ) GROUP=$OPTARG;;
     f ) USERS_FILE=$OPTARG;;
     p ) CREATE_PASSWORD=true;;
     a ) CREATE_ACCESS_KEY=true;;
     d ) DEBUG=" --debug";; # AWSコマンドのデバッグ設定
     ? | h) usage; exit 2;;
  esac
done

if [ -z "$GROUP" ]; then
  echo "-g is required args."
  exit 3

fi
awscmd iam get-group --group-name ${GROUP} > /dev/null # if group not exist, error happen.

if [ ! -e $USERS_FILE ];then
  echo "${USERS_FILE} is not exists file."
  exit 4
fi

cat $USERS_FILE | while read USER_NAME || [ -n "${USER_NAME}" ]; do
    printf "Creating IAM user ${USER_NAME}..."
    awscmd iam create-user --user-name ${USER_NAME} > /dev/null
    awscmd iam wait user-exists --user-name ${USER_NAME}
    awscmd iam add-user-to-group --user-name ${USER_NAME} --group-name ${GROUP}

    if "${CREATE_PASSWORD}" ; then
        PASSWORD=$(openssl rand -base64 32)
        awscmd iam create-login-profile --user-name ${USER_NAME} --password ${PASSWORD} --password-reset-required > /dev/null

        AWS_ACCOUNT_ID=$(awscmd sts get-caller-identity --query 'Account' --output text)
        AWS_ACCOUNT_ALIAS=$(awscmd iam list-account-aliases --query 'AccountAliases[0]' --output text)
        echo "https://"${AWS_ACCOUNT_ID}".signin.aws.amazon.com/console" "${USER_NAME}" "${PASSWORD}" > ${AWS_ACCOUNT_ID}_${AWS_ACCOUNT_ALIAS}_${USER_NAME}_password.txt
    fi

    if "${CREATE_ACCESS_KEY}" ; then
        RESULT=$(awscmd iam create-access-key --user-name ${USER_NAME} --output text --query '[AccessKey.AccessKeyId, AccessKey.SecretAccessKey]')
        echo $RESULT > ${AWS_ACCOUNT_ID}_${AWS_ACCOUNT_ALIAS}_${USER_NAME}_accesskey.txt
    fi
    echo "Successed!"
done
