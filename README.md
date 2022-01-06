# aws-user-creater
AWSのIAMユーザーを一括で作成するだけのプロダクト

## 動作環境
- Mac OS Big Sur version 11.4
- Docker version 20.10.8

## 使い方
```
% ./aws-create-user.sh -h
使い方: ./aws-create-user.sh -g group_name [-f path] [-aph] args
  -g group_name: ユーザの所属グループを指定します. 必須パラメータです.
  -f filepath  : ユーザを記載したファイルのパスを指定します.デフォルトは ./users.txt .
  -p           : ログイン用のパスワードを生成します. 生成したパスワードは ./[AWS_ACCOUNT_ID]_[AWS_ACCOUNT_ALIAS]_ユーザ名_password.txt に出力されます.
  -a           : APIアクセス用のアクセスキーを生成します. 生成したアクセスキーは ./[AWS_ACCOUNT_ID]_[AWS_ACCOUNT_ALIAS]_ユーザ名_accesskey.txt に出力されます.
  -d           : デバッグログを出力.
  -h           : 本メッセージを出力します.
```

## ユーザ作成までの流れ

1. ユーザファイルを用意する.ファイル名は users.txt または -f にて任意のファイルを利用可能.  
   (例) Bob, Aliceのアカウントを作りたい場合 
   ```
   $ cat users.txt
   Bob
   Alice
   ```

1. 対象のAWS環境にて IAMユーザーグループを作成する. すでにユーザーグループが作成されている場合、本手順は不要.  
   (参考) IAMユーザーグループの作成 https://docs.aws.amazon.com/ja_jp/IAM/latest/UserGuide/id_groups_create.html  

1. 対象のAWS環境にて IAMユーザを作成しておく. すでに管理ユーザなどが作成されている場合、本手順は不要.  
   作成する際は「Programmatic access (プログラムによるアクセス) 」を有効にして AWS_ACCESS_KEY_ID, AWS_SECRET_ACCESS_KEY を生成してください.  
   (参考) IAMユーザーの作成 https://docs.aws.amazon.com/ja_jp/IAM/latest/UserGuide/id_users_create.html#id_users_create_console  

1. 本プログラムを実行し、ユーザを作成する  
   (例) IAMユーザとともに、ログイン用のパスワード、アクセスキーも生成する  
   ```
   $ AWS_ACCESS_KEY_ID=[3のAWS_ACCESS_KEY_IDを指定] AWS_SECRET_ACCESS_KEY=[3のAWS_SECRET_ACCESS_KEYを指定] \
     sh aws-create-user.sh -g [2のIAMユーザーグループ名を指定] -p -a
   Creating IAM user Bob... Successed!
   Creating IAM user Alice... Successed!
   
   $ ls | grep .txt
   123456789012_ACCOUNT-ALIAS_Alice_accesskey.txt
   123456789012_ACCOUNT-ALIAS_Alice_password.txt
   123456789012_ACCOUNT-ALIAS_Bob_accesskey.txt
   123456789012_ACCOUNT-ALIAS_Bob_password.txt
   users.txt
   
   $ cat 123456789012_ACCOUNT-ALIAS_Alice_accesskey.txt
   GENERATED_AWS_ACCESSKEY_ID_HERE GENERATED_AWS_SECRET_ACCESS_KEY_HERE
   
   $ cat 123456789012_ACCOUNT-ALIAS_Alice_password.txt
   https://123456789012.signin.aws.amazon.com/console kashiwaguma-hiro GENERATED_PASSWORD_HERE
   ```

## 参考にさせていただいたサイト
- https://docs.aws.amazon.com/ja_jp/IAM/latest/UserGuide/id_users_create.html
- https://dev.classmethod.jp/articles/aws-cli-iamuser-bulk-create/ 
