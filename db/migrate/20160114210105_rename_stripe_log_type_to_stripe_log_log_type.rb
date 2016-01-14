class RenameStripeLogTypeToStripeLogLogType < ActiveRecord::Migration
  def change
    rename_column :stripe_logs, :type, :log_type
  end
end
