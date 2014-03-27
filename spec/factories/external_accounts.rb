# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :external_account, :class => 'ExternalAccounts' do
    provider "MyString"
    uid "MyString"
    name "MyString"
    oauth_token "MyString"
    oauth_expires_at "2014-03-26 23:57:57"
  end
end
