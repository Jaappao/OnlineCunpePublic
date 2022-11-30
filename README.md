# OnlineCunpePublic



https://user-images.githubusercontent.com/53894906/204744032-8f80a5f1-f10b-4acc-837d-594abbeae873.mp4



## 概要

オンライン上で「カンペ」を実現する「OnlineCunpe」

オンライン化の流れの中、運営陣が分散してオンラインイベントを開催する際に、情報共有をより容易にするアプリ。Commanderが入力した文字列を、リアルタイムでリモート端末に表示させる。テレビ番組収録現場でADがスケッチブックに文字を書いて演者に指示するのを、オンライン上で模倣できないか、ということにチャレンジした。

## 作業期間

2週間

## 関係者の人数

1人

## 担当役割

要件定義〜実装

## 開発言語・技術

Swift、Firebase（主にFirestore）

## 参考URL

[https://www.dropbox.com/sh/46gso2juhdwt0um/AACTW8Bh8TrSu0ZU3s8RnOD-a?dl=0](https://www.dropbox.com/sh/46gso2juhdwt0um/AACTW8Bh8TrSu0ZU3s8RnOD-a?dl=0)

## きっかけ

私が所属しているバイト先の株式会社ライフイズテックではIT教育を展開しており、プログラミングスクール、ハッカソンなどのイベントを頻繁にZoomで開催している。運営に関わる人は全国各地の自宅から参加しているため、何か運営に支障が生じたり状況を確認したりする際、直接話しかけたり手で合図をしたりして意思疎通することが容易ではない。Slackなどのチャットツールを通じて合図をするのも良いが、チャットツールはリアルタイムイベント開催のためには設計されておらず、今現在なんの情報を伝えるべきなのか、という点にフォーカスされていない。今伝えたいメッセージだけをはっきりと見ることができるアプリケーションを作成する必要があると感じ、作成に至った。

## アピールポイント

FirestoreのSnapshot Listenerを使用して、リモートにおけるリアルタイムな文字列の反映を実現している。

また、文字の視認性が本アプリケーションの重要な点であるため、Commanderが入力した文字列の長さに応じて、画面いっぱいに文字が表示されるように自動的にフォントサイズを調整する機能が備えられている。

さらに工夫した点として、このアプリを使用する人にとってイベント運営の方が本質的に重要であり、このアプリの使用に思考コストをかけてはいけない。例えば、Commanderが文字列を入力したものの送信ボタンを押し忘れる、ということが発生しうる。本アプリでは入力した文字列は文字列入力終了後3秒後には自動的に送信されるようにしており、可能な限り本アプリケーションの使用にコストをかけないように注意している。

## Future Work
- Firestoreは真にリアルタイムに強いDBではないので、ユーザー数が増加した際のリアルタイムさに疑義が残る
- あえてユーザ認証をつけなかった（気軽な利用をするため）が、認証をつけることでRoomの管理を容易にできる
- Commanderが送信した情報に対するReceriverのACKがない。既読機能やTwitterの質問機能のようなものをつけたい。
