defmodule CafeWeb.CoreComponents do
  @moduledoc """
  Shared function components used across CafeOps.
  """

  use Phoenix.Component
  use Gettext, backend: CafeWeb.Gettext

  alias Phoenix.LiveView.JS

  attr :flash, :map, required: true
  attr :id, :string, default: "flash-group"

  def flash_group(assigns) do
    ~H"""
    <div id={@id} aria-live="polite">
      <.flash kind={:info} flash={@flash} />
      <.flash kind={:error} flash={@flash} />
    </div>
    """
  end

  attr :kind, :atom, values: [:info, :error], required: true
  attr :flash, :map, required: true

  def flash(assigns) do
    assigns = assign_new(assigns, :message, fn -> Phoenix.Flash.get(assigns.flash, assigns.kind) end)

    ~H"""
    <div
      :if={@message}
      id={"flash-#{@kind}"}
      class={[
        "fixed right-4 top-4 z-50 rounded-md px-4 py-3 text-sm shadow-lg",
        @kind == :info && "bg-emerald-50 text-emerald-900 ring-1 ring-emerald-200",
        @kind == :error && "bg-rose-50 text-rose-900 ring-1 ring-rose-200"
      ]}
      phx-click={JS.push("lv:clear-flash", value: %{key: @kind}) |> hide("##{@id}")}
      role="alert"
    >
      <%= @message %>
    </div>
    """
  end

  attr :navigate, :string, default: nil
  attr :href, :string, default: nil
  attr :class, :string, default: nil
  slot :inner_block, required: true

  def link(assigns) do
    ~H"""
    <Phoenix.Component.link navigate={@navigate} href={@href} class={@class}>
      <%= render_slot(@inner_block) %>
    </Phoenix.Component.link>
    """
  end

  def hide(js \\ %JS{}, selector) do
    JS.hide(js,
      to: selector,
      transition:
        {"transition-all transform ease-in duration-200", "opacity-100 translate-y-0",
         "opacity-0 translate-y-2"}
    )
  end
end
