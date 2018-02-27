# Jirack

Jiraのステータスを更新しつつ、stackに通知をするコマンド.


## Installation

install it yourself as:

    $ gem install jirack
    or
    $ gem install specific_install
    $ gem specific_install https://github.com/rhythm191/jirack.git master


## Usage

認証情報などをセットアップをします。
認証情報は`~/.jirack`に保存されます。

    $ jirack config

自分の担当しているissueを確認する。

    $ jirack list
    
自分の担当しているissueの総ポイント数を確認する

    $ jirack list --sum-point
    

未割り当てのissueを確認する。

    $ jirack list --unassign
    
チケットをステータスを前に進める。(ex. チケット9999を次のステータスにする)
`-m message`でslackにメッセージを通知する。

    $ jirack forward 9999
    or
    $ jirack forward 9999 -m "release has been completed"
    
    
チケットのステータスを後ろに戻す。(ex. チケット9999を前のステータスにする)
`-m message`でslackにメッセージを通知する。
    
    $ jirack back 9999
    or
    $ jirack back 9999 -m "release has been completed"


slackにメッセージだけを送る。(ex. チケット9999についてのメッセージを送る)

    $ jirack notify 9999 -m "something message"


チケットのページをブラウザで開く

    $ jirack open 9999


チケットを自分にアサインしたい

    $ jirack assign 9999


分からなくなったら、

    $ jirack help
    $ jirack help list


## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/rhythm191/jirack. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](http://contributor-covenant.org) code of conduct.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the Jirack project’s codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/rhythm191/jirack/blob/master/CODE_OF_CONDUCT.md).
