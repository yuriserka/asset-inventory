defmodule AssetTracker do
  defstruct assets: %{}

  @doc """
  Create a new asset tracker.
  """
  @spec new() :: map
  def new do
    %__MODULE__{
      assets: %{}
    }
  end

  @doc """
  Add a purchase to the asset tracker.
  """
  @spec add_purchase(
          asset_tracker :: %__MODULE__{},
          purchase :: %Domain.Operations.Purchase{}
        ) :: %__MODULE__{}
  def add_purchase(asset_tracker, purchase) do
    symbol_purchases = asset_tracker.assets |> Map.get(purchase.symbol, :queue.new())

    %__MODULE__{
      assets:
        asset_tracker.assets |> Map.put(purchase.symbol, :queue.in(purchase, symbol_purchases))
    }
  end

  @doc """
  Add a sale to the asset tracker.
  """
  @spec add_sale(
          asset_tracker :: %__MODULE__{},
          sale :: %Domain.Operations.Sale{}
        ) :: {%__MODULE__{}, Decimal.t()}
  def add_sale(asset_tracker, sale) do
    {new_asset_tracker, total_invested} =
      sell_symbol(
        asset_tracker.assets,
        sale,
        sale.quantity |> Decimal.to_integer(),
        Decimal.new(0)
      )

    {
      %__MODULE__{
        assets: new_asset_tracker
      },
      Decimal.sub(total_invested, sale.total_sold)
    }
  end

  def unrealized_gain_or_loss(asset_tracker, symbol, market_price) do
    calc_cost = fn quantity, unit_price ->
      Decimal.mult(quantity, unit_price)
    end

    asset_tracker.assets
    |> Map.get(symbol)
    |> :queue.to_list()
    |> Enum.reduce(
      Decimal.new(0),
      &Decimal.add(
        &2,
        Decimal.sub(
          calc_cost.(&1.quantity, &1.unit_price),
          calc_cost.(&1.quantity, market_price)
        )
      )
    )
  end

  defp sell_symbol(assets, sale, quantity_left, accumulated_acquisition_cost)
       when quantity_left > 0 do
    case can_sell_symbol(assets, sale, quantity_left) do
      {:ok, oldest_purchase} ->
        max_quantity_to_sell = Decimal.min(oldest_purchase.quantity, quantity_left)
        new_purchase = Domain.Operations.Purchase.sell(oldest_purchase, max_quantity_to_sell)
        new_quantity_left = Decimal.sub(quantity_left, max_quantity_to_sell)

        new_symbol_purchases =
          assets
          |> Map.get(sale.symbol)
          |> :queue.drop()
          |> then(
            &if(Decimal.compare(new_purchase.quantity, 0) == :gt,
              do: :queue.cons(new_purchase, &1),
              else: &1
            )
          )

        new_accumulated_acquisition_cost =
          Decimal.add(
            accumulated_acquisition_cost,
            Decimal.mult(max_quantity_to_sell, oldest_purchase.unit_price)
          )

        new_symbol_purchases
        |> :queue.is_empty()
        |> case do
          true ->
            assets |> Map.delete(sale.symbol)

          false ->
            assets |> Map.replace(sale.symbol, new_symbol_purchases)
        end
        |> sell_symbol(
          sale,
          Decimal.to_integer(new_quantity_left),
          new_accumulated_acquisition_cost
        )

      {:error, error_message} ->
        IO.puts(error_message)
        {assets, accumulated_acquisition_cost}
    end
  end

  defp sell_symbol(assets, _, _, accumulated_acquisition_cost) do
    {assets, accumulated_acquisition_cost}
  end

  defp get_last_purchase(assets, symbol) do
    assets
    |> Map.get(symbol)
    |> :queue.peek()
    |> case do
      {:value, purchase} -> purchase
      _ -> :empty
    end
  end

  defp total_quantity_of_symbols_available(assets, symbol) do
    assets
    |> Map.get(symbol, :queue.new())
    |> :queue.to_list()
    |> Enum.reduce(Decimal.new(0), &Decimal.add(&2, &1.quantity))
  end

  defp can_sell_symbol(assets, sale, quantity_left) do
    with total_quantity when total_quantity >= quantity_left <-
           total_quantity_of_symbols_available(assets, sale.symbol) |> Decimal.to_integer(),
         oldest_purchase when oldest_purchase != :empty <-
           get_last_purchase(assets, sale.symbol) do
      {:ok, oldest_purchase}
    else
      :empty ->
        {:error, "You don't have any #{sale.symbol} to sell"}

      total_quantity when is_integer(total_quantity) ->
        {:error,
         "You don't have enough quantity of #{sale.symbol} to sell #{total_quantity}/#{quantity_left}"}
    end
  end
end
