defmodule DienerHansBot.CommandReceiver.Parser do

  def parse_update(%Nadia.Model.Update{} = update) do
    if bot_mentioned?(update) do
      request_type = request_type(update.message.text)
      metadata = build_metadata(request_type, update)

      {:ok, request_type, metadata}
    else 
      {:error, :noop}
    end
  end

  defp request_type(text) do
    if String.contains?(text, "remind") do
      :schedule_reminder
    else
      :unknown
    end
  end

  defp build_metadata(:schedule_reminder, %{message: %{text: text}} = update) do
    {:ok, date} = extract_datetime(text) 
    message = extract_message(text)

    %DienerHansBot.Reminder{chat_id: update.message.chat.id, message: message, date: date}
  end

  defp build_metadata(type, update), do: nil

  defp bot_mentioned?(%{message: %{text: text}} = _update) do
    ~r/^@DienerHansBot/
    |> Regex.match?(text)
  end

  defp extract_message(text) do
    ~r/@[A-z0-9\-\_]+ remind ([0-9]+\.[0-9]+\.[0-9]+)?(\s+)?([0-9]+:[0-9]+)?\s+/
    |> Regex.replace(text, "")
  end

  # TODO: rather use command structure instead of parsing messages
  # TODO: look into reply_markup

  defp extract_datetime(text) do
    default_date_str = Timex.format!(DateTime.utc_now, "%d.%m.%Y", :strftime)
    default_time_str = "08:00"
    # TODO: how to handle time zones?? how to get users timezone?
    default_timezone = "+0100"

    time_str = ~r/([0-1]?[0-9]|[2][0-3]):([0-5][0-9])(:[0-5][0-9])?/
    |> Regex.run(text)
    |> case do
      [time_str | _] -> time_str
      nil -> nil
    end

    date_str = ~r/(3[01]|[12][0-9]|0?[1-9])\.(1[012]|0?[1-9])\.((?:19|20)\d{2})*/
    |> Regex.run(text)
    |> case do
      [date_str | _] -> date_str
      nil -> nil
    end

    if !date_str && !time_str do
      {:error, "neither date nor time found"}
    else
      Timex.parse("#{date_str || default_date_str} #{time_str || default_time_str} #{default_timezone}", "%d.%m.%Y %H:%M %z", :strftime)
      |> case do
        {:ok, datetime} -> {:ok, datetime}
        {:error, _} -> {:error, "unable to parse datetime"}
      end
    end

  end
end
