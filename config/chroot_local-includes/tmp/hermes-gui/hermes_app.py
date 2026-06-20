#!/usr/bin/env python3
"""
Hermes GTK4 Desktop App for Tails OS
A native, lightweight AI assistant interface.
"""

import sys
import os
import subprocess
import threading
import json
import time

import gi
gi.require_version("Gtk", "4.0")
gi.require_version("Adw", "1")
from gi.repository import Gtk, Adw, GLib, Gio, Pango, Gdk

# --- Style ---
CSS = """
@define-color bg_color #1a1a2e;
@define-color surface_color #16213e;
@define-color accent_color #00d4aa;
@define-color text_color #e0e0e0;
@define-color dim_color #888888;

window {
    background-color: @bg_color;
}

.chat-view {
    background-color: @bg_color;
    padding: 12px;
}

.message-user {
    background-color: @surface_color;
    border-radius: 12px 12px 4px 12px;
    padding: 10px 14px;
    margin: 4px 0px 4px 40px;
}

.message-ai {
    background-color: alpha(@accent_color, 0.12);
    border-radius: 12px 12px 12px 4px;
    padding: 10px 14px;
    margin: 4px 40px 4px 0px;
    border-left: 3px solid @accent_color;
}

.message-system {
    color: @dim_color;
    font-size: 0.85em;
    padding: 6px 14px;
    margin: 2px 20px;
    font-style: italic;
}

.input-bar {
    background-color: @surface_color;
    padding: 10px 14px;
    border-top: 1px solid alpha(@accent_color, 0.2);
}

.send-button {
    background-color: @accent_color;
    color: #000;
    border-radius: 20px;
    padding: 8px 20px;
    font-weight: bold;
}

.send-button:hover {
    background-color: #00f0c0;
}

.status-bar {
    background-color: @surface_color;
    padding: 4px 14px;
    border-top: 1px solid alpha(@accent_color, 0.15);
    font-size: 0.8em;
    color: @dim_color;
}

.sidebar-row {
    padding: 8px 16px;
    border-radius: 8px;
}

.sidebar-row:hover {
    background-color: alpha(@accent_color, 0.08);
}

.sidebar-row-selected {
    background-color: alpha(@accent_color, 0.15);
    border-left: 3px solid @accent_color;
}
"""


class ChatView(Gtk.Box):
    """Scrollable chat message area."""

    def __init__(self):
        super().__init__(orientation=Gtk.Orientation.VERTICAL)
        self.set_css_classes(["chat-view"])

        self.scrolled = Gtk.ScrolledWindow()
        self.scrolled.set_vexpand(True)
        self.scrolled.set_policy(Gtk.PolicyType.NEVER, Gtk.PolicyType.AUTOMATIC)

        self.messages_box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=4)
        self.messages_box.set_margin_start(8)
        self.messages_box.set_margin_end(8)
        self.messages_box.set_margin_top(8)
        self.messages_box.set_margin_bottom(8)

        self.scrolled.set_child(self.messages_box)
        self.append(self.scrolled)

        # Auto-scroll handler
        self._setup_autoscroll()

    def _setup_autoscroll(self):
        self.vadj = self.scrolled.get_vadjustment()
        self.vadj.connect("changed", self._on_scroll_changed)
        self.vadj.connect("value-changed", self._on_scroll_changed)

    def _on_scroll_changed(self, adj):
        adj.set_value(adj.get_upper() - adj.get_page_size())

    def add_message(self, text: str, role: str = "ai"):
        label = Gtk.Label()
        label.set_text(text)
        label.set_wrap(True)
        label.set_wrap_mode(Pango.WrapMode.WORD_CHAR)
        label.set_xalign(0.0)
        label.set_selectable(True)
        label.set_css_classes([f"message-{role}"])

        frame = Gtk.Frame()
        frame.set_child(label)

        if role == "user":
            frame.set_halign(Gtk.Align.END)
        elif role == "ai":
            frame.set_halign(Gtk.Align.START)

        self.messages_box.append(frame)
        return frame

    def add_system_message(self, text: str):
        label = Gtk.Label()
        label.set_text(text)
        label.set_css_classes(["message-system"])
        label.set_xalign(0.5)
        self.messages_box.append(label)

    def clear(self):
        child = self.messages_box.get_first_child()
        while child:
            next_child = child.get_next_sibling()
            self.messages_box.remove(child)
            child = next_child


class HermesApp(Adw.Application):
    """Main Hermes GTK4 Application."""

    def __init__(self):
        super().__init__(
            application_id="org.tails.hermes",
            flags=Gio.ApplicationFlags.DEFAULT_FLAGS,
        )
        self.ollama_running = False
        self.hermes_config_path = "/etc/hermes/config.yaml"
        self.conversation_history = []

    def do_activate(self):
        self._apply_css()
        self.window = self._build_window()
        self.window.set_application(self)
        self.window.present()
        self._check_status()

    def _apply_css(self):
        provider = Gtk.CssProvider()
        provider.load_from_data(CSS.encode())
        Gtk.StyleContext.add_provider_for_display(
            Gdk.Display.get_default(),
            provider,
            Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION,
        )

    def _build_window(self):
        win = Adw.ApplicationWindow(title="Hermes AI")
        win.set_default_size(900, 650)

        # Main layout
        main_box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL)
        win.set_content(main_box)

        # Header bar
        header = Adw.HeaderBar()
        header.set_title_widget(
            Adw.WindowTitle(title="Hermes AI", subtitle="Tails OS Assistant")
        )

        # Menu button
        menu_button = Gtk.MenuButton()
        menu_button.set_icon_name("open-menu-symbolic")

        menu = Gio.Menu()
        menu.append("New Chat", "app.new_chat")
        menu.append("Settings", "app.settings")
        menu.append("About", "app.about")
        menu_button.set_menu_model(menu)

        header.pack_end(menu_button)
        main_box.append(header)

        # Toast overlay for notifications
        self.toast_overlay = Adw.ToastOverlay()
        main_box.append(self.toast_overlay)

        # Content area
        content = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL)
        content.set_vexpand(True)
        self.toast_overlay.set_child(content)

        # Sidebar
        sidebar = self._build_sidebar()
        content.append(sidebar)

        # Chat area
        chat_area = Gtk.Box(orientation=Gtk.Orientation.VERTICAL)
        chat_area.set_hexpand(True)
        content.append(chat_area)

        # Chat view
        self.chat_view = ChatView()
        chat_area.append(self.chat_view)

        # Input bar
        input_bar = self._build_input_bar()
        chat_area.append(input_bar)

        # Status bar
        self.status_label = Gtk.Label()
        self.status_label.set_css_classes(["status-bar"])
        self.status_label.set_xalign(0.0)
        main_box.append(self.status_label)

        # Actions
        self._setup_actions()

        return win

    def _build_sidebar(self):
        sidebar = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=4)
        sidebar.set_size_request(200, -1)
        sidebar.set_css_classes(["sidebar"])

        # Sidebar header
        header_label = Gtk.Label(label="Chats")
        header_label.set_margin_top(12)
        header_label.set_margin_bottom(8)
        header_label.set_margin_start(16)
        header_label.set_xalign(0.0)
        header_label.set_css_classes(["title-4"])
        sidebar.append(header_label)

        # Chat list
        self.chat_list = Gtk.ListBox()
        self.chat_list.set_selection_mode(Gtk.SelectionMode.SINGLE)
        self.chat_list.set_css_classes(["sidebar"])

        row = Gtk.ListBoxRow()
        box = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=8)
        box.set_margin_start(16)
        box.set_margin_end(8)
        box.set_margin_top(8)
        box.set_margin_bottom(8)
        icon = Gtk.Image.new_from_icon_name("user-available-symbolic")
        label = Gtk.Label(label="Current Chat")
        label.set_xalign(0.0)
        box.append(icon)
        box.append(label)
        row.set_child(box)
        row.set_css_classes(["sidebar-row", "sidebar-row-selected"])
        self.chat_list.append(row)

        sidebar.append(self.chat_list)

        # Spacer
        spacer = Gtk.Box()
        spacer.set_vexpand(True)
        sidebar.append(spacer)

        # Ollama status indicator
        self.ollama_indicator = Gtk.Label()
        self.ollama_indicator.set_margin_start(16)
        self.ollama_indicator.set_margin_bottom(12)
        self.ollama_indicator.set_xalign(0.0)
        sidebar.append(self.ollama_indicator)

        return sidebar

    def _build_input_bar(self):
        box = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=8)
        box.set_css_classes(["input-bar"])

        self.text_input = Gtk.Entry()
        self.text_input.set_placeholder_text("Ask Hermes anything...")
        self.text_input.set_hexpand(True)
        self.text_input.connect("activate", self._on_send)
        box.append(self.text_input)

        send_btn = Gtk.Button(label="Send")
        send_btn.set_css_classes(["send-button"])
        send_btn.connect("clicked", self._on_send)
        box.append(send_btn)

        return box

    def _setup_actions(self):
        actions = [
            ("new_chat", self._on_new_chat),
            ("settings", self._on_settings),
            ("about", self._on_about),
        ]
        for name, callback in actions:
            action = Gio.SimpleAction.new(name, None)
            action.connect("activate", callback)
            self.add_action(action)

    def _on_send(self, btn):
        text = self.text_input.get_text().strip()
        if not text:
            return

        self.text_input.set_text("")
        self.chat_view.add_message(text, "user")
        self.conversation_history.append({"role": "user", "content": text})

        self.status_label.set_text("Hermes is thinking...")

        # Run AI query in background thread
        thread = threading.Thread(target=self._query_hermes, args=(text,))
        thread.daemon = True
        thread.start()

    def _query_hermes(self, prompt: str):
        """Query Hermes/Ollama in background."""
        try:
            # Try Ollama directly first
            result = subprocess.run(
                [
                    "curl", "-s", "http://127.0.0.1:11434/api/generate",
                    "-d", json.dumps({
                        "model": "qwen2.5:7b",
                        "prompt": prompt,
                        "stream": False,
                    }),
                ],
                capture_output=True, text=True, timeout=120,
            )

            if result.returncode == 0 and result.stdout.strip():
                try:
                    data = json.loads(result.stdout)
                    response = data.get("response", "No response from model.")
                except json.JSONDecodeError:
                    response = result.stdout.strip() or "Model returned empty response."
            else:
                # Fallback: try hermes CLI
                result = subprocess.run(
                    ["hermes", "ask", prompt],
                    capture_output=True, text=True, timeout=60,
                )
                response = result.stdout.strip() or "Hermes CLI not available."

        except subprocess.TimeoutExpired:
            response = "Request timed out. The model may still be loading."
        except FileNotFoundError:
            response = (
                "Ollama is not running.\n\n"
                "To start: ollama serve &\n"
                "To pull a model: ollama pull qwen2.5:7b"
            )
        except Exception as e:
            response = f"Error: {e}"

        # Update UI on main thread
        GLib.idle_add(self._on_response, response)

    def _on_response(self, response: str):
        self.chat_view.add_message(response, "ai")
        self.conversation_history.append({"role": "assistant", "content": response})
        self.status_label.set_text("Ready")
        return False  # Remove idle source

    def _on_new_chat(self, action, param):
        self.chat_view.clear()
        self.conversation_history.clear()
        self.chat_view.add_system_message("New conversation started.")

    def _on_settings(self, action, param):
        dialog = Adw.MessageDialog(
            transient_for=self.window,
            heading="Hermes Settings",
            body="Configuration is managed in /etc/hermes/config.yaml\n\n"
                 "Ollama models: /var/lib/ollama/\n"
                 "Hermes memory: /var/lib/hermes/memory/",
        )
        dialog.add_response("ok", "OK")
        dialog.present()

    def _on_about(self, action, param):
        dialog = Adw.AboutWindow(
            transient_for=self.window,
            application_name="Hermes AI",
            version="1.0.0",
            developer_name="Tails Hermes Project",
            license_type=Gtk.License.GPL_3_0,
            website="https://github.com/chillybean/tails",
            issue_url="https://github.com/chillybean/tails/issues",
        )
        dialog.set_developers(["Tails Hermes Contributors"])
        dialog.set_copyright("© 2026 Tails Hermes Project")
        dialog.present()

    def _check_status(self):
        """Check Ollama and Hermes status on startup."""
        # Check Ollama
        try:
            result = subprocess.run(
                ["curl", "-s", "http://127.0.0.1:11434/"],
                capture_output=True, text=True, timeout=5,
            )
            if result.returncode == 0:
                self.ollama_running = True
                self.ollama_indicator.set_text("🟢 Ollama running")
                self.status_label.set_text("Ready — Ollama is running")
            else:
                raise Exception("not running")
        except Exception:
            self.ollama_running = False
            self.ollama_indicator.set_text("🔴 Ollama not running")
            self.status_label.set_text(
                "Ollama not detected. Start with: ollama serve"
            )
            self.chat_view.add_system_message(
                "⚠️ Ollama is not running. Start it with:\n"
                "  ollama serve &\n"
                "Then pull a model:\n"
                "  ollama pull qwen2.5:7b"
            )

        # Check Hermes CLI
        try:
            result = subprocess.run(
                ["hermes", "--version"],
                capture_output=True, text=True, timeout=5,
            )
            if result.returncode == 0:
                self.chat_view.add_system_message(
                    f"✅ Hermes Agent installed: {result.stdout.strip()}"
                )
        except Exception:
            self.chat_view.add_system_message(
                "ℹ️ Hermes CLI not found in PATH. Using Ollama directly."
            )


def main():
    app = HermesApp()
    return app.run(sys.argv)


if __name__ == "__main__":
    sys.exit(main())
