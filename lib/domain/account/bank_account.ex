defmodule Domain.Account.BankAccount do
  defstruct inventory: AssetTracker.new(), current_balance: Decimal.new(0)

  def new(
        inventory,
        current_balance
      ) do
    %__MODULE__{
      inventory: inventory,
      current_balance: current_balance
    }
  end

  def buy_symbol(bank_account, symbol, settle_date, quantity, unit_price) do
    purchase = Domain.Operations.Purchase.new(symbol, settle_date, quantity, unit_price)
    inventory = AssetTracker.add_purchase(bank_account.inventory, purchase)

    %__MODULE__{
      inventory: inventory,
      current_balance: bank_account.current_balance
    }
  end

  def sell_symbol(bank_account, symbol, sell_date, quantity, unit_price) do
    sale = Domain.Operations.Sale.new(symbol, sell_date, quantity, unit_price)
    {inventory, realized_gain_loss} = AssetTracker.add_sale(bank_account.inventory, sale)
    current_balance = Decimal.add(bank_account.current_balance, realized_gain_loss)

    %__MODULE__{
      inventory: inventory,
      current_balance: current_balance
    }
  end
end
