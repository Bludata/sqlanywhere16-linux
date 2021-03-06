// ***************************************************************************
// Copyright (c) 2013 SAP AG or an SAP affiliate company. All rights reserved.
// ***************************************************************************
// サンプルコードは「現状有姿(as is)」の条件で提供されるものであり、
// お客様に対しいかなる保証責任も賠償責任も負わないものとします。
//
// お客様は、当該サンプルコードを使用、複製および配布することができます。
// ただし、アイエニウェアの原コードに関する著作権表示およびにこれに対する
// 免責表示をすることを条件とします。
// 
// *********************************************************************


                       Tracetime Perl スクリプト


目的
----

Tracetime Perl スクリプトの主な目的は、ログ出力要求を使用して各文の実
行時間を判定し、最も高コストな文を特定することです。これは、挿入や更新
などの「実行される」文については比較的簡単です。クエリについては、文の
準備から削除までの時間を計算することになります。これには、文を記述し、
カーソルを開き、ローをフェッチし、カーソルを閉じる時間が含まれます。ほ
とんどのクエリについては、この方法で実行にかかる時間を正確に反映するこ
とができます。他のアクションの実行中にカーソルが開いたままの場合、文の
実行時間は大きな値として表示されますが、この値はクエリが高コストである
かどうかを正しく示すものではありません。

必要条件
--------

このスクリプトでは、要求ログを作成するために以下のコマンドラインオプショ
ンを使用してサーバーを起動する必要があります。

     -zr sql -zo request-log-filename

"-zr sql" オプションは、要求ロギングを有効化し、要求のサブセットのみが
書き込まれるように指定します。"-zo request-log-filename" オプションは、
書き込みロケーションを指定します。sa_server_option ストアドプロシー
ジャーを使用して要求ログを作成することもできます。このプロシージャーの
詳細については、以下のパラメーター値の説明に関する資料を参照してください。
    RequestLogging
    RequestLogFile
    RequestLogMaxSize
    RequestLogNumFiles

処理手順
--------

スクリプトを実行するには、以下のコマンドラインを使用します。

     perl tracetime.pl request-log-filename [format={fixed|sql}] [conn=nnn]

最も高コストな文を見つけるには、スクリプトを "format=fixed" パラメーター
で実行し、"sort/R" (Windows の場合) を通して出力をパイプして、最も長い
文が最初に来るように並べ替えます。

例：
    perl tracetime.pl myreqlog.txt format=fixed | sort /rec 65535 /R >sorted.txt

