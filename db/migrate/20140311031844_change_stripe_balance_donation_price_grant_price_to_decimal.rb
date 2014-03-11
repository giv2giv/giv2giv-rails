class ChangeStripeBalanceDonationPriceGrantPriceToDecimal < ActiveRecord::Migration
  def up

    add_column :shares, :stripe_balance2, :decimal, :precision => 10, :scale => 2
    execute "UPDATE shares SET stripe_balance2 = stripe_balance"
    remove_column :shares, :stripe_balance
    rename_column :shares, :stripe_balance2, :stripe_balance

    add_column :shares, :etrade_balance2, :decimal, :precision => 10, :scale => 2
    execute "UPDATE shares SET etrade_balance2 = etrade_balance"
    remove_column :shares, :etrade_balance
    rename_column :shares, :etrade_balance2, :etrade_balance

    add_column :shares, :donation_price2, :decimal, :precision => 10, :scale => 2
    execute "UPDATE shares SET donation_price2 = donation_price"
    remove_column :shares, :donation_price
    rename_column :shares, :donation_price2, :donation_price

    add_column :shares, :grant_price2, :decimal, :precision => 10, :scale => 2
    execute "UPDATE shares SET grant_price2 = grant_price"
    remove_column :shares, :grant_price
    rename_column :shares, :grant_price2, :grant_price

  end

  def down

    add_column :shares, :stripe_balance2, :float
    execute "UPDATE shares SET stripe_balance2 = stripe_balance"
    remove_column :shares, :stripe_balance
    rename_column :shares, :stripe_balance2, :stripe_balance

    add_column :shares, :etrade_balance2, :decimal, :precision => 30, :scale => 20
    execute "UPDATE shares SET etrade_balance2 = etrade_balance"
    remove_column :shares, :etrade_balance
    rename_column :shares, :etrade_balance2, :etrade_balance

    add_column :shares, :donation_price2, :float
    execute "UPDATE shares SET donation_price2 = donation_price"
    remove_column :shares, :donation_price
    rename_column :shares, :donation_price2, :donation_price

    add_column :shares, :grant_price2, :float
    execute "UPDATE shares SET grant_price2 = grant_price"
    remove_column :shares, :grant_price
    rename_column :shares, :grant_price2, :grant_price

  end
end
